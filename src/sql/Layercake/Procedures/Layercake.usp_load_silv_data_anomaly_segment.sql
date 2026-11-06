/*====================================================================
    Layercake.usp_load_silv_data_anomaly_segment
    Silver layer - silv_member_year_attributes, brnz_subs_invoice,
    brnz_subs_invoice_line, brnz_corporate_subscription,
    silv_payment_events and silv_ref_concession_type
    -> Layercake.silv_data_anomaly (segment anomaly types only)
    Derives, for contact-years from 2022 with a segment invoice:
      CORPORATE_FLAG_NO_SCHEME       year's payment method Corporate, no live
                                     corporate subscription that year (RULE-025)
      DOUBLE_PAYMENT                 segment invoice settled by Corporate and by
                                     another method (RULE-026)
      CONCESSION_NOT_IN_REFERENCE    one row per concession item code ('CON%')
                                     on the segment invoice not in the reference
                                     (RULE-052)
      FULL_CONCESSION_NO_CONCESSION  Phase 1 'Full Concession' position, year's
                                     concession type not full-rate (RULE-053)
    and reconciles them with silv_data_anomaly: new cases inserted, cases no
    longer raised deleted, a case whose detail changed gets the new detail,
    the rest untouched. Rows of other anomaly types are never touched. Logged.
    anomaly_nk = '<type>:<contact_no>:<campaign_year>[:<item_code>]'.
    Choices made here (not fixed by the design):
      an unknown concession code is raised even when another, recognised
      code on the same invoice sets the year's concession; a year with a
      Full Concession position but no segment invoice raises nothing.
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_silv_data_anomaly_segment
    @run_id uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @run_id IS NULL SET @run_id = NEWID();

    -- Seeded reference ids (MOD-003) and fixed rule values, as in the attributes load.
    DECLARE @first_invoice_year int           = 2022,   -- RULE-080, Q-011
            @pm_corporate       int           = 5,
            @active_status      nvarchar(350) = N'Active',          -- Q-027
            @full_concession    nvarchar(64)  = N'Full Concession';

    DECLARE @log_id bigint,
            @ins    int,
            @upd    int,
            @del    int,
            @now    datetime2(3),
            @err    nvarchar(4000);

    BEGIN TRY
        EXEC Layercake.usp_etl_log_start @run_id, 'silver', 'silv_data_anomaly_segment', @log_id OUTPUT;

        SET @now = SYSDATETIME();

        -- Contact-years from 2022 with their live segment invoice.
        CREATE TABLE #segment_year
        (
            contact_no         nvarchar(200) COLLATE DATABASE_DEFAULT NOT NULL,
            campaign_year      int           NOT NULL,
            payment_method_id  int           NOT NULL,
            concession_type_id int           NOT NULL,
            rec_id             bigint        NOT NULL,
            account_num        nvarchar(20)  COLLATE DATABASE_DEFAULT NOT NULL,
            voucher            nvarchar(20)  COLLATE DATABASE_DEFAULT NULL,
            invoice_text       nvarchar(120) COLLATE DATABASE_DEFAULT NOT NULL,
            PRIMARY KEY CLUSTERED (contact_no, campaign_year)
        );

        INSERT INTO #segment_year
            (contact_no, campaign_year, payment_method_id, concession_type_id, rec_id, account_num, voucher, invoice_text)
        SELECT a.contact_no,
               a.campaign_year,
               a.payment_method_id,
               a.concession_type_id,
               i.rec_id,
               i.account_num,
               i.voucher,
               CONCAT(N'Campaign Year ', a.campaign_year, N': segment invoice ',
                      COALESCE(i.invoice, N'(no number)'), N' (rec_id ', i.rec_id, N')')
        FROM Layercake.silv_member_year_attributes AS a
        INNER JOIN Layercake.brnz_subs_invoice AS i
            ON  i.rec_id = a.segment_invoice_rec_id
            AND i._is_deleted = 0
        WHERE a.campaign_year >= @first_invoice_year
          AND i.account_num IS NOT NULL;

        CREATE TABLE #case
        (
            anomaly_nk   nvarchar(240) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY CLUSTERED,
            anomaly_type varchar(40)   COLLATE DATABASE_DEFAULT NOT NULL,
            contact_no   nvarchar(200) COLLATE DATABASE_DEFAULT NOT NULL,
            detail       nvarchar(400) COLLATE DATABASE_DEFAULT NOT NULL
        );

        -- RULE-025: the live-subscription test is the one the attributes load uses.
        INSERT INTO #case (anomaly_nk, anomaly_type, contact_no, detail)
        SELECT CONCAT(N'CORPORATE_FLAG_NO_SCHEME:', s.contact_no, N':', s.campaign_year),
               'CORPORATE_FLAG_NO_SCHEME',
               s.contact_no,
               CONCAT(s.invoice_text, N' has payment method Corporate, but the contact has no live corporate subscription that year.')
        FROM #segment_year AS s
        WHERE s.payment_method_id = @pm_corporate
          AND NOT EXISTS (SELECT 1
                          FROM Layercake.brnz_corporate_subscription AS cs
                          WHERE cs.contact_no = s.contact_no
                            AND cs.sub_campaign_year = s.campaign_year
                            AND cs._is_deleted = 0
                            AND cs.sub_status = @active_status
                            AND cs.sub_user_status = @active_status);

        -- RULE-026: payment lines as in the attributes load (RULE-013, RULE-077): live
        -- lines settling the invoice on its own account with a non-blank mode, not the
        -- invoice's own lines. An unrecognised mode counts as another method.
        INSERT INTO #case (anomaly_nk, anomaly_type, contact_no, detail)
        SELECT CONCAT(N'DOUBLE_PAYMENT:', s.contact_no, N':', s.campaign_year),
               'DOUBLE_PAYMENT',
               s.contact_no,
               CONCAT(s.invoice_text, N' is settled both by Corporate and by another payment method.')
        FROM #segment_year AS s
        CROSS APPLY (SELECT MAX(CASE WHEN p.payment_method_id = @pm_corporate THEN 1 ELSE 0 END) AS has_corporate,
                            MAX(CASE WHEN p.payment_method_id <> @pm_corporate THEN 1 ELSE 0 END) AS has_other
                     FROM (SELECT Layercake.fn_map_payment_method(l.paymmode) AS payment_method_id
                           FROM Layercake.brnz_subs_invoice_line AS l
                           WHERE l.lastsettlevoucher = s.voucher
                             AND l.accountnum = s.account_num
                             AND l._is_deleted = 0
                             AND (l.voucher <> s.voucher OR l.voucher IS NULL)
                             AND LTRIM(RTRIM(l.paymmode)) <> N'') AS p) AS m
        WHERE m.has_corporate = 1
          AND m.has_other = 1;

        -- RULE-052: codes group as the collation compares them (case and trailing
        -- spaces ignored), so two spellings of one code are one case.
        INSERT INTO #case (anomaly_nk, anomaly_type, contact_no, detail)
        SELECT CONCAT(N'CONCESSION_NOT_IN_REFERENCE:', s.contact_no, N':', s.campaign_year, N':', u.item_code),
               'CONCESSION_NOT_IN_REFERENCE',
               s.contact_no,
               CONCAT(s.invoice_text, N' has concession item code ', u.item_code,
                      N', which is not in Layercake.silv_ref_concession_type.')
        FROM #segment_year AS s
        CROSS APPLY (SELECT MIN(l.productcode) AS item_code
                     FROM Layercake.brnz_subs_invoice_line AS l
                     WHERE l.accountnum = s.account_num
                       AND l.voucher = s.voucher
                       AND l._is_deleted = 0
                       AND l.productcode LIKE N'CON%'
                       AND NOT EXISTS (SELECT 1
                                       FROM Layercake.silv_ref_concession_type AS r
                                       WHERE r.item_code = l.productcode
                                         AND r.concession_type_bk IS NOT NULL)
                     GROUP BY l.productcode) AS u;

        -- RULE-053: the Full Concession position is the Phase 1 paid position.
        INSERT INTO #case (anomaly_nk, anomaly_type, contact_no, detail)
        SELECT CONCAT(N'FULL_CONCESSION_NO_CONCESSION:', s.contact_no, N':', s.campaign_year),
               'FULL_CONCESSION_NO_CONCESSION',
               s.contact_no,
               CONCAT(s.invoice_text, N' has no full-rate concession type, but the contact has a Full Concession position that year.')
        FROM #segment_year AS s
        WHERE EXISTS (SELECT 1
                      FROM Layercake.silv_payment_events AS pe
                      WHERE pe.contact_no = s.contact_no
                        AND pe.campaign_year = s.campaign_year
                        AND pe.invoice_position = @full_concession)
          AND NOT EXISTS (SELECT 1
                          FROM Layercake.silv_ref_concession_type AS r
                          WHERE r.id = s.concession_type_id
                            AND r.is_full_concession = 1);

        BEGIN TRANSACTION;

        DELETE t
        FROM Layercake.silv_data_anomaly AS t
        WHERE t.anomaly_type IN ('CORPORATE_FLAG_NO_SCHEME', 'DOUBLE_PAYMENT',
                                 'CONCESSION_NOT_IN_REFERENCE', 'FULL_CONCESSION_NO_CONCESSION')
          AND NOT EXISTS (SELECT 1 FROM #case AS c WHERE c.anomaly_nk = t.anomaly_nk);
        SET @del = @@ROWCOUNT;

        -- A still-raised case keeps its row; only a changed detail (for example a new
        -- segment invoice for the same contact-year) is written, compared as bytes.
        UPDATE t
        SET detail = c.detail
        FROM Layercake.silv_data_anomaly AS t
        INNER JOIN #case AS c
            ON  c.anomaly_nk = t.anomaly_nk
            AND c.anomaly_type = t.anomaly_type
        WHERE NOT EXISTS (SELECT CAST(c.detail AS varbinary(800))
                          INTERSECT
                          SELECT CAST(t.detail AS varbinary(800)));
        SET @upd = @@ROWCOUNT;

        INSERT INTO Layercake.silv_data_anomaly
            (anomaly_nk, anomaly_type, contact_no, source_enr_id, detail, first_detected_at, last_seen_at)
        SELECT c.anomaly_nk, c.anomaly_type, c.contact_no, NULL, c.detail, @now, @now
        FROM #case AS c
        WHERE NOT EXISTS (SELECT 1 FROM Layercake.silv_data_anomaly AS t WHERE t.anomaly_nk = c.anomaly_nk);
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
