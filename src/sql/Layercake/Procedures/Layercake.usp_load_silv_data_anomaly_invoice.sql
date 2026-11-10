/*====================================================================
    Layercake.usp_load_silv_data_anomaly_invoice
    Silver layer - silv_event_amount (the event-invoice match),
    vw_silv_eligible_invoice, brnz_subs_invoice, brnz_subs_invoice_line,
    silv_ref_invoice_line_type and ref_campaign_year_config
    -> Layercake.silv_data_anomaly (invoice anomaly types only)
    Derives, for amount Campaign Years from 2022 (RULE-093):
      EVENT_NO_INVOICE                 event whose contact-year has no eligible
                                       invoice (match 'No eligible invoice', RULE-042)
      INVOICE_MATCHES_MULTIPLE_EVENTS  event left without an invoice because the
                                       year has more events than invoices
                                       (match 'Invoice shortfall', RULE-090)
      INVOICE_NO_EVENT                 eligible invoice in a contact-year where no
                                       event takes its amounts from that year (RULE-043)
      EVENT_MATCHES_MULTIPLE_INVOICES  eligible invoice matched to no event in a
                                       contact-year that has events: the surplus
                                       (RULE-091)
      READMISSION_FREE                 matched Readmission whose invoice has no own
                                       'readmission fee' line, dated in Campaign Year
                                       quarter 2 (RULE-044, RULE-092, ADR-004)
      READMISSION_NO_FEE               the same outside that quarter
    and reconciles them with silv_data_anomaly as the segment anomaly load does:
    new cases inserted, cases no longer raised deleted, a case whose detail
    changed gets the new detail, the rest untouched. Rows of other anomaly
    types are never touched. The event amount plays no part (Q-042). Logged.
    anomaly_nk = '<type>:<event_nk>' for event types and '<type>:<rec_id>'
    for invoice types.
    Choices made here (not fixed by the design):
      the free window is looked up for the Readmission's amount Campaign
      Year (its own year); a year with no config row has no window, so its
      Readmission is READMISSION_NO_FEE. A matched invoice that is no longer
      live has no own lines, so its Readmission has no fee line.
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_silv_data_anomaly_invoice
    @run_id uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @run_id IS NULL SET @run_id = NEWID();

    DECLARE @first_invoice_year int         = 2022,   -- RULE-093, Q-011
            @readmission_fee    varchar(40) = 'readmission fee';

    DECLARE @log_id bigint,
            @ins    int,
            @upd    int,
            @del    int,
            @now    datetime2(3),
            @err    nvarchar(4000);

    BEGIN TRY
        EXEC Layercake.usp_etl_log_start @run_id, 'silver', 'silv_data_anomaly_invoice', @log_id OUTPUT;

        SET @now = SYSDATETIME();

        CREATE TABLE #case
        (
            anomaly_nk   nvarchar(240) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY CLUSTERED,
            anomaly_type varchar(40)   COLLATE DATABASE_DEFAULT NOT NULL,
            contact_no   nvarchar(200) COLLATE DATABASE_DEFAULT NOT NULL,
            detail       nvarchar(400) COLLATE DATABASE_DEFAULT NOT NULL
        );

        -- RULE-042, RULE-090: events with no invoice, told apart by the match outcome.
        INSERT INTO #case (anomaly_nk, anomaly_type, contact_no, detail)
        SELECT CONCAT(t.anomaly_type, N':', e.event_nk),
               t.anomaly_type,
               e.contact_no,
               LEFT(CONCAT(N'Campaign Year ', e.amount_campaign_year, N': ', e.event_type, N' ', e.event_nk,
                           N' on ', CONVERT(char(10), e.event_date, 23), t.reason), 400)
        FROM Layercake.silv_event_amount AS e
        INNER JOIN (VALUES ('No eligible invoice', 'EVENT_NO_INVOICE',
                            N' has no eligible invoice for the contact that year.'),
                           ('Invoice shortfall', 'INVOICE_MATCHES_MULTIPLE_EVENTS',
                            N' has no invoice: the contact has more events than eligible invoices that year.'))
                   AS t (match_outcome, anomaly_type, reason)
            ON t.match_outcome = e.match_outcome
        WHERE e.amount_campaign_year >= @first_invoice_year;

        -- RULE-043, RULE-091: eligible invoices matched to no event. Where the
        -- contact-year has events, the invoice is a surplus; otherwise it has no event.
        INSERT INTO #case (anomaly_nk, anomaly_type, contact_no, detail)
        SELECT CONCAT(t.anomaly_type, N':', i.rec_id),
               t.anomaly_type,
               i.contact_no,
               LEFT(CONCAT(N'Campaign Year ', i.campaign_year, N': eligible invoice ',
                           COALESCE(i.invoice, N'(no number)'), N' (rec_id ', i.rec_id, N') dated ',
                           COALESCE(CONVERT(char(10), i.trans_date, 23), N'(no date)'), t.reason), 400)
        FROM Layercake.vw_silv_eligible_invoice AS i
        CROSS APPLY (SELECT CASE WHEN EXISTS (SELECT 1
                                              FROM Layercake.silv_event_amount AS e
                                              WHERE e.contact_no = i.contact_no
                                                AND e.amount_campaign_year = i.campaign_year)
                                 THEN 1 ELSE 0
                            END AS has_event) AS h
        INNER JOIN (VALUES (0, 'INVOICE_NO_EVENT',
                            N' has no Join, Renewal or Readmission taking its amounts from that year.'),
                           (1, 'EVENT_MATCHES_MULTIPLE_INVOICES',
                            N' is matched to no event: the contact has more eligible invoices than events that year.'))
                   AS t (has_event, anomaly_type, reason)
            ON t.has_event = h.has_event
        WHERE i.campaign_year >= @first_invoice_year
          AND NOT EXISTS (SELECT 1
                          FROM Layercake.silv_event_amount AS m
                          WHERE m.invoice_rec_id = i.rec_id);

        -- RULE-044, RULE-092: a fee line is a live own line of the matched invoice
        -- (same account and voucher) whose mapped line type is 'readmission fee'.
        -- The free window is months four to six counted from campaign_year_start.
        INSERT INTO #case (anomaly_nk, anomaly_type, contact_no, detail)
        SELECT CONCAT(r.anomaly_type, N':', e.event_nk),
               r.anomaly_type,
               e.contact_no,
               LEFT(CONCAT(N'Campaign Year ', e.amount_campaign_year, N': Readmission ', e.event_nk,
                           N' on ', CONVERT(char(10), e.event_date, 23), N' is matched to invoice ',
                           COALESCE(inv.invoice, N'(no number)'), N' (rec_id ', e.invoice_rec_id,
                           N'), which has no readmission fee line', r.reason), 400)
        FROM Layercake.silv_event_amount AS e
        LEFT JOIN Layercake.brnz_subs_invoice AS inv
            ON  inv.rec_id = e.invoice_rec_id
            AND inv._is_deleted = 0
        LEFT JOIN Layercake.ref_campaign_year_config AS cy
            ON cy.campaign_year = e.amount_campaign_year
        CROSS APPLY (SELECT DATEADD(MONTH, 3, cy.campaign_year_start) AS free_from,
                            DATEADD(DAY, -1, DATEADD(MONTH, 6, cy.campaign_year_start)) AS free_to) AS w
        CROSS APPLY (SELECT CASE WHEN e.event_date BETWEEN w.free_from AND w.free_to
                                 THEN 'READMISSION_FREE'
                                 ELSE 'READMISSION_NO_FEE'
                            END AS anomaly_type,
                            CASE WHEN e.event_date BETWEEN w.free_from AND w.free_to
                                 THEN CONCAT(N'; its date falls in the free-readmission window (',
                                             CONVERT(char(10), w.free_from, 23), N' to ',
                                             CONVERT(char(10), w.free_to, 23), N').')
                                 ELSE N'.'
                            END AS reason) AS r
        WHERE e.event_type = 'Readmission'
          AND e.match_outcome = 'Matched'
          AND e.invoice_rec_id IS NOT NULL
          AND e.amount_campaign_year >= @first_invoice_year
          AND NOT EXISTS (SELECT 1
                          FROM Layercake.brnz_subs_invoice_line AS l
                          INNER JOIN Layercake.silv_ref_invoice_line_type AS lt
                              ON  lt.item_code = l.productcode
                              AND lt.ric_invoice_type = ISNULL(l.ricinvoicetype, N'')
                          WHERE l.accountnum = inv.account_num
                            AND l.voucher = inv.voucher
                            AND l._is_deleted = 0
                            AND lt.line_type = @readmission_fee);

        BEGIN TRANSACTION;

        DELETE t
        FROM Layercake.silv_data_anomaly AS t
        WHERE t.anomaly_type IN ('EVENT_NO_INVOICE', 'INVOICE_NO_EVENT', 'INVOICE_MATCHES_MULTIPLE_EVENTS',
                                 'EVENT_MATCHES_MULTIPLE_INVOICES', 'READMISSION_FREE', 'READMISSION_NO_FEE')
          AND NOT EXISTS (SELECT 1 FROM #case AS c WHERE c.anomaly_nk = t.anomaly_nk);
        SET @del = @@ROWCOUNT;

        -- A still-raised case keeps its row; only a changed detail (for example a
        -- corrected invoice number) is written, compared as bytes.
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
