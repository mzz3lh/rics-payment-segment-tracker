/*====================================================================
    Layercake.usp_load_silv_member_year_attributes
    Silver layer - silv_membership_events, vw_silv_eligible_invoice,
    brnz_subs_invoice_line, brnz_corporate_subscription, silv_payment_events
    and the reference lists -> Layercake.silv_member_year_attributes
    One row per contact per Campaign Year, from the contact's first event
    year (MIN(campaign_year) in silv_membership_events) to the current
    Campaign Year (the ref_campaign_year_config row covering @as_of_date;
    none covering it fails the load). Every contact-year is recomputed and
    only differences are written: new rows inserted, changed rows updated
    (created_at kept), rows no longer derived deleted. Logged.
      before 2022            -2 Not applicable for every segment (RULE-080)
      segment invoice        values from the latest eligible invoice
      no eligible invoice    carried from the latest earlier year from 2022
                             that has one; concession only when perpetual;
                             otherwise 0 Unknown, flag 0 (Q-006)
    Tie-breaks chosen here (not fixed by the design):
      payment lines  a method whose lines all lack a transdate sorts after
                     any dated one on the earliest-payment tie
      concession     a recognised code beats an unrecognised one; among
                     recognised, highest apuk_discount then lowest line recid
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_silv_member_year_attributes
    @run_id     uniqueidentifier = NULL,
    @as_of_date date = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @run_id IS NULL SET @run_id = NEWID();
    IF @as_of_date IS NULL SET @as_of_date = CAST(SYSDATETIME() AS date);

    -- Seeded reference ids (MOD-003, MOD-004, MOD-006) and fixed rule values.
    DECLARE @first_invoice_year  int            = 2022,   -- RULE-080, Q-011
            @pm_corporate        int            = 5,
            @pt_individual       int            = 1,
            @pt_corporate        int            = 2,
            @ct_no_concession    int            = 1,
            @active_status       nvarchar(350)  = N'Active';  -- Q-027

    DECLARE @log_id       bigint,
            @current_year int,
            @ins          int,
            @upd          int,
            @del          int,
            @now          datetime2(3),
            @msg          nvarchar(2048),
            @err          nvarchar(4000);

    BEGIN TRY
        EXEC Layercake.usp_etl_log_start @run_id, 'silver', 'silv_member_year_attributes', @log_id OUTPUT;

        SELECT @current_year = c.campaign_year
        FROM Layercake.ref_campaign_year_config AS c
        WHERE @as_of_date BETWEEN c.campaign_year_start AND c.campaign_year_end;

        IF @current_year IS NULL
        BEGIN
            SET @msg = CONCAT(N'No Campaign Year in Layercake.ref_campaign_year_config covers the as-of date ',
                              CONVERT(nvarchar(10), @as_of_date, 23), N'.');
            THROW 50001, @msg, 1;
        END;

        SET @now = SYSDATETIME();

        -- Contact-years (RULE-011, Q-030).
        CREATE TABLE #contact_year
        (
            contact_no    nvarchar(200) COLLATE DATABASE_DEFAULT NOT NULL,
            campaign_year int           NOT NULL,
            PRIMARY KEY CLUSTERED (contact_no, campaign_year)
        );

        INSERT INTO #contact_year (contact_no, campaign_year)
        SELECT f.contact_no, c.campaign_year
        FROM (SELECT e.contact_no, MIN(e.campaign_year) AS first_year
              FROM Layercake.silv_membership_events AS e
              GROUP BY e.contact_no) AS f
        INNER JOIN Layercake.ref_campaign_year_config AS c
            ON c.campaign_year BETWEEN f.first_year AND @current_year;

        -- Segment invoices of these contacts from 2022 (RULE-079).
        CREATE TABLE #segment_invoice
        (
            rec_id             bigint        NOT NULL PRIMARY KEY CLUSTERED,
            contact_no         nvarchar(200) COLLATE DATABASE_DEFAULT NOT NULL,
            campaign_year      int           NOT NULL,
            voucher            nvarchar(20)  COLLATE DATABASE_DEFAULT NULL,
            inv_payment_method nvarchar(20)  COLLATE DATABASE_DEFAULT NULL,
            payment_method_id  int           NULL,
            is_double_payment  bit           NOT NULL DEFAULT 0,
            payer_type_id      int           NULL,
            corporate_account_ref nvarchar(100) COLLATE DATABASE_DEFAULT NULL,
            concession_type_id int           NULL,
            concession_is_perpetual bit      NOT NULL DEFAULT 0
        );

        INSERT INTO #segment_invoice (rec_id, contact_no, campaign_year, voucher, inv_payment_method)
        SELECT v.rec_id, v.contact_no, v.campaign_year, v.voucher, v.inv_payment_method
        FROM Layercake.vw_silv_eligible_invoice AS v
        WHERE v.is_segment_invoice = 1
          AND v.campaign_year >= @first_invoice_year
          AND EXISTS (SELECT 1 FROM #contact_year AS cy WHERE cy.contact_no = v.contact_no);

        -- Payment lines (RULE-013, RULE-077): live lines settling the invoice on its own
        -- account with a non-blank mode; the invoice's own lines are not payment lines.
        CREATE TABLE #payment_method_total
        (
            rec_id            bigint       NOT NULL,
            payment_method_id int          NOT NULL,
            settled_amount    numeric(38, 6) NOT NULL,
            first_transdate   datetime2(3) NULL,
            first_recid       bigint       NOT NULL,
            PRIMARY KEY CLUSTERED (rec_id, payment_method_id)
        );

        INSERT INTO #payment_method_total (rec_id, payment_method_id, settled_amount, first_transdate, first_recid)
        SELECT p.rec_id, p.payment_method_id, SUM(p.settled_amount), MIN(p.transdate), MIN(p.recid)
        FROM (SELECT s.rec_id,
                     Layercake.fn_map_payment_method(l.paymmode) AS payment_method_id,
                     ABS(ISNULL(l.settleamountcur, 0)) AS settled_amount,
                     l.transdate,
                     l.recid
              FROM #segment_invoice AS s
              INNER JOIN Layercake.brnz_subs_invoice_line AS l
                  ON  l.lastsettlevoucher = s.voucher
                  AND l.accountnum = s.contact_no
                  AND l._is_deleted = 0
              WHERE (l.voucher <> s.voucher OR l.voucher IS NULL)
                AND LTRIM(RTRIM(l.paymmode)) <> N'') AS p
        GROUP BY p.rec_id, p.payment_method_id;

        -- Payment method: the invoice's own mode when not blank, else the payment line
        -- method with the largest settled sum, then earliest payment, then lowest recid.
        UPDATE s
        SET payment_method_id =
                CASE WHEN LTRIM(RTRIM(s.inv_payment_method)) <> N''
                     THEN Layercake.fn_map_payment_method(s.inv_payment_method)
                     ELSE COALESCE(w.payment_method_id, 0)
                END,
            is_double_payment =
                CASE WHEN EXISTS (SELECT 1 FROM #payment_method_total AS t
                                  WHERE t.rec_id = s.rec_id AND t.payment_method_id = @pm_corporate)
                      AND EXISTS (SELECT 1 FROM #payment_method_total AS t
                                  WHERE t.rec_id = s.rec_id AND t.payment_method_id <> @pm_corporate)
                     THEN 1 ELSE 0
                END
        FROM #segment_invoice AS s
        OUTER APPLY (SELECT TOP (1) t.payment_method_id
                     FROM #payment_method_total AS t
                     WHERE t.rec_id = s.rec_id
                     ORDER BY t.settled_amount DESC,
                              CASE WHEN t.first_transdate IS NULL THEN 1 ELSE 0 END,
                              t.first_transdate,
                              t.first_recid) AS w;

        -- Payer type (RULE-021, RULE-026, RULE-082, RULE-023): Corporate with a live
        -- subscription (lowest scheme_no); a double payment without one is Individual;
        -- otherwise Individual with a Phase 1 paid position that year, else Unknown.
        UPDATE s
        SET payer_type_id =
                CASE WHEN (s.payment_method_id = @pm_corporate OR s.is_double_payment = 1)
                          AND sub.scheme_no IS NOT NULL THEN @pt_corporate
                     WHEN s.is_double_payment = 1 THEN @pt_individual
                     WHEN EXISTS (SELECT 1 FROM Layercake.silv_payment_events AS pe
                                  WHERE pe.contact_no = s.contact_no
                                    AND pe.campaign_year = s.campaign_year) THEN @pt_individual
                     ELSE 0
                END,
            corporate_account_ref =
                CASE WHEN s.payment_method_id = @pm_corporate OR s.is_double_payment = 1
                     THEN sub.scheme_no
                END
        FROM #segment_invoice AS s
        OUTER APPLY (SELECT MIN(cs.scheme_no) AS scheme_no
                     FROM Layercake.brnz_corporate_subscription AS cs
                     WHERE cs.contact_no = s.contact_no
                       AND cs.sub_campaign_year = s.campaign_year
                       AND cs._is_deleted = 0
                       AND cs.sub_status = @active_status
                       AND cs.sub_user_status = @active_status) AS sub;

        -- Concession (RULE-049 to RULE-052, Q-021): live own lines with a code starting
        -- 'CON'; no such line is No concession, a code not in the reference Unrecognised.
        UPDATE s
        SET concession_type_id = COALESCE(c.concession_type_id, @ct_no_concession),
            concession_is_perpetual = COALESCE(c.is_perpetual, 0)
        FROM #segment_invoice AS s
        OUTER APPLY (SELECT TOP (1) COALESCE(r.id, -1) AS concession_type_id, r.is_perpetual
                     FROM Layercake.brnz_subs_invoice_line AS l
                     LEFT JOIN Layercake.silv_ref_concession_type AS r
                         ON  r.item_code = l.productcode
                         AND r.concession_type_bk IS NOT NULL
                     LEFT JOIN Layercake.brnz_concession AS bc
                         ON bc.apuk_concessiontypeid = r.concession_type_bk
                     WHERE l.accountnum = s.contact_no
                       AND l.voucher = s.voucher
                       AND l._is_deleted = 0
                       AND l.productcode LIKE N'CON%'
                     ORDER BY CASE WHEN r.id IS NULL THEN 1 ELSE 0 END,
                              bc.apuk_discount DESC,
                              l.recid) AS c;

        -- Every contact-year with its own or carried values.
        CREATE TABLE #derived
        (
            contact_no              nvarchar(200) COLLATE DATABASE_DEFAULT NOT NULL,
            campaign_year           int           NOT NULL,
            payment_method_id       int           NOT NULL,
            payment_method_carried  bit           NOT NULL,
            payer_type_id           int           NOT NULL,
            payer_type_carried      bit           NOT NULL,
            corporate_account_ref   nvarchar(100) COLLATE DATABASE_DEFAULT NULL,
            concession_type_id      int           NOT NULL,
            concession_type_carried bit           NOT NULL,
            segment_invoice_rec_id  bigint        NULL,
            PRIMARY KEY CLUSTERED (contact_no, campaign_year)
        );

        INSERT INTO #derived
            (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
             corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id)
        SELECT cy.contact_no,
               cy.campaign_year,
               CASE WHEN cy.campaign_year < @first_invoice_year THEN -2
                    WHEN own.rec_id IS NOT NULL THEN own.payment_method_id
                    WHEN prev.rec_id IS NOT NULL THEN prev.payment_method_id
                    ELSE 0
               END,
               CASE WHEN cy.campaign_year >= @first_invoice_year AND own.rec_id IS NULL AND prev.rec_id IS NOT NULL
                    THEN 1 ELSE 0
               END,
               CASE WHEN cy.campaign_year < @first_invoice_year THEN -2
                    WHEN own.rec_id IS NOT NULL THEN own.payer_type_id
                    WHEN prev.rec_id IS NOT NULL THEN prev.payer_type_id
                    ELSE 0
               END,
               CASE WHEN cy.campaign_year >= @first_invoice_year AND own.rec_id IS NULL AND prev.rec_id IS NOT NULL
                    THEN 1 ELSE 0
               END,
               CASE WHEN cy.campaign_year < @first_invoice_year THEN NULL
                    WHEN own.rec_id IS NOT NULL THEN own.corporate_account_ref
                    ELSE prev.corporate_account_ref
               END,
               CASE WHEN cy.campaign_year < @first_invoice_year THEN -2
                    WHEN own.rec_id IS NOT NULL THEN own.concession_type_id
                    WHEN prev.concession_is_perpetual = 1 THEN prev.concession_type_id
                    ELSE 0
               END,
               CASE WHEN cy.campaign_year >= @first_invoice_year AND own.rec_id IS NULL AND prev.concession_is_perpetual = 1
                    THEN 1 ELSE 0
               END,
               CASE WHEN cy.campaign_year >= @first_invoice_year THEN own.rec_id END
        FROM #contact_year AS cy
        LEFT JOIN #segment_invoice AS own
            ON  own.contact_no = cy.contact_no
            AND own.campaign_year = cy.campaign_year
        OUTER APPLY (SELECT TOP (1) p.rec_id, p.payment_method_id, p.payer_type_id, p.corporate_account_ref,
                            p.concession_type_id, p.concession_is_perpetual
                     FROM #segment_invoice AS p
                     WHERE p.contact_no = cy.contact_no
                       AND p.campaign_year < cy.campaign_year
                     ORDER BY p.campaign_year DESC) AS prev;

        BEGIN TRANSACTION;

        DELETE t
        FROM Layercake.silv_member_year_attributes AS t
        WHERE NOT EXISTS (SELECT 1 FROM #derived AS d
                          WHERE d.contact_no = t.contact_no
                            AND d.campaign_year = t.campaign_year);
        SET @del = @@ROWCOUNT;

        -- The scheme number compares as bytes, so a case-only change still lands.
        UPDATE t
        SET payment_method_id       = d.payment_method_id,
            payment_method_carried  = d.payment_method_carried,
            payer_type_id           = d.payer_type_id,
            payer_type_carried      = d.payer_type_carried,
            corporate_account_ref   = d.corporate_account_ref,
            concession_type_id      = d.concession_type_id,
            concession_type_carried = d.concession_type_carried,
            segment_invoice_rec_id  = d.segment_invoice_rec_id,
            load_id                 = @log_id,
            updated_at              = @now
        FROM Layercake.silv_member_year_attributes AS t
        INNER JOIN #derived AS d
            ON  d.contact_no = t.contact_no
            AND d.campaign_year = t.campaign_year
        WHERE EXISTS (SELECT d.payment_method_id, d.payment_method_carried, d.payer_type_id, d.payer_type_carried,
                             CAST(d.corporate_account_ref AS varbinary(200)), d.concession_type_id,
                             d.concession_type_carried, d.segment_invoice_rec_id
                      EXCEPT
                      SELECT t.payment_method_id, t.payment_method_carried, t.payer_type_id, t.payer_type_carried,
                             CAST(t.corporate_account_ref AS varbinary(200)), t.concession_type_id,
                             t.concession_type_carried, t.segment_invoice_rec_id);
        SET @upd = @@ROWCOUNT;

        INSERT INTO Layercake.silv_member_year_attributes
            (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
             corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id,
             load_id, created_at, updated_at)
        SELECT d.contact_no, d.campaign_year, d.payment_method_id, d.payment_method_carried, d.payer_type_id,
               d.payer_type_carried, d.corporate_account_ref, d.concession_type_id, d.concession_type_carried,
               d.segment_invoice_rec_id, @log_id, @now, @now
        FROM #derived AS d
        WHERE NOT EXISTS (SELECT 1 FROM Layercake.silv_member_year_attributes AS t
                          WHERE t.contact_no = d.contact_no
                            AND t.campaign_year = d.campaign_year);
        SET @ins = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC Layercake.usp_etl_log_end @log_id, 'Success', @ins, @upd, @del;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @err = CONCAT(ERROR_MESSAGE(), ' (error ', ERROR_NUMBER(), ', line ', ERROR_LINE(), ')');
        IF @log_id IS NOT NULL
            EXEC Layercake.usp_etl_log_end @log_id, 'Failed', @ins, @upd, @del, @err;
        THROW;
    END CATCH;
END;
