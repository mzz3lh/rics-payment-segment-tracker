EXEC tSQLt.NewTestClass 'test_MOD011_dev';
GO

CREATE PROCEDURE test_MOD011_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_event_amount';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_invoice_line_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2025, '2024-10-01', '2025-09-30', '2025-11-30'),
           (2026, '2025-10-01', '2026-09-30', '2026-11-30');

    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id)
    VALUES (N'SUBMRICS', N'SUB', 'subscription', NULL),
           (N'RAFEE_MRICS', N'SUB', 'readmission fee', NULL);
END;
GO

CREATE PROCEDURE test_MOD011_dev.[test Readmission in a Campaign Year with no config row is READMISSION_NO_FEE]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (970001, N'W1', 2027, N'INV-W1-27', N'V970001', '2027-01-05', N'Card', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'W1', N'INV-W1-27', N'V970001', NULL, '2027-01-05', N'SUB', N'SUBMRICS', 450.00, 450.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RD:W1:2027', 801, N'W1', 'Readmission', '2027-01-15', 2027, 970001, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.anomaly_nk, a.anomaly_type, a.contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.anomaly_nk, v.anomaly_type, v.contact_no
    INTO #Expected
    FROM (VALUES (N'READMISSION_NO_FEE:RD:W1:2027', 'READMISSION_NO_FEE', N'W1')) AS v(anomaly_nk, anomaly_type, contact_no);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011_dev.[test fee line with NULL ricinvoicetype mapped on empty string counts as a fee]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id)
    VALUES (N'RAFEE_NOTYPE', N'', 'readmission fee', NULL);

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (970011, N'W2', 2025, N'INV-W2-25', N'V970011', '2025-08-01', N'Card', N'GBP', 550.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'W2', N'INV-W2-25', N'V970011', NULL, '2025-08-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (2, N'W2', N'INV-W2-25', N'V970011', NULL, '2025-08-01', NULL, N'RAFEE_NOTYPE', 100.00, 100.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RD:W2:2025', 802, N'W2', 'Readmission', '2025-08-12', 2025, 970011, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_data_anomaly';
END;
GO

CREATE PROCEDURE test_MOD011_dev.[test changed invoice number updates the detail in place and logs one update]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (970021, N'W3', 2025, N'INV-W3-OLD', N'V970021', '2024-10-15', N'DD', N'GBP', 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    UPDATE Layercake.silv_data_anomaly SET first_detected_at = '2026-01-01', last_seen_at = '2026-01-01';

    UPDATE Layercake.brnz_subs_invoice SET invoice = N'INV-W3-NEW' WHERE rec_id = 970021;

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.anomaly_id, a.anomaly_nk, a.anomaly_type, a.first_detected_at, a.last_seen_at,
           CASE WHEN CHARINDEX(N'INV-W3-NEW', a.detail) > 0 THEN 1 ELSE 0 END AS names_new_number
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.anomaly_id, v.anomaly_nk, v.anomaly_type, v.first_detected_at, v.last_seen_at, v.names_new_number
    INTO #Expected
    FROM (VALUES (1, N'INVOICE_NO_EVENT:970021', 'INVOICE_NO_EVENT',
                  CAST('2026-01-01' AS datetime2), CAST('2026-01-01' AS datetime2), 1))
         AS v(anomaly_id, anomaly_nk, anomaly_type, first_detected_at, last_seen_at, names_new_number);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.log_id = (SELECT MAX(x.log_id) FROM Layercake.etl_run_log AS x);

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD011_dev.[test one run counts an insert an update and a delete]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_data_anomaly
        (anomaly_nk, anomaly_type, contact_no, source_enr_id, detail, first_detected_at, last_seen_at, resolved_at)
    VALUES (N'EVENT_NO_INVOICE:RN:Z9:2025', 'EVENT_NO_INVOICE', N'Z9', NULL, N'stale', '2026-01-01', '2026-01-01', NULL),
           (N'INVOICE_NO_EVENT:970031', 'INVOICE_NO_EVENT', N'W4', NULL, N'old detail', '2026-01-01', '2026-01-01', NULL);

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (970031, N'W4', 2025, N'INV-W4-25', N'V970031', '2024-10-15', N'DD', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:W5:2025', 803, N'W5', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice',
            NULL, NULL, 'No invoice', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.anomaly_id, a.anomaly_nk, a.anomaly_type, a.contact_no, a.detail
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.anomaly_id, v.anomaly_nk, v.anomaly_type, v.contact_no, v.detail
    INTO #Expected
    FROM (VALUES (2, N'INVOICE_NO_EVENT:970031', 'INVOICE_NO_EVENT', N'W4',
                  N'Campaign Year 2025: eligible invoice INV-W4-25 (rec_id 970031) dated 2024-10-15 has no Join, Renewal or Readmission taking its amounts from that year.'),
                 (3, N'EVENT_NO_INVOICE:RN:W5:2025', 'EVENT_NO_INVOICE', N'W5',
                  N'Campaign Year 2025: Renewal RN:W5:2025 on 2024-11-05 has no eligible invoice for the contact that year.'))
         AS v(anomaly_id, anomaly_nk, anomaly_type, contact_no, detail);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1, 1, 1)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD011_dev.[test event_nk too long for anomaly_nk fails the load and changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_data_anomaly
        (anomaly_nk, anomaly_type, contact_no, source_enr_id, detail, first_detected_at, last_seen_at, resolved_at)
    VALUES (N'EVENT_NO_INVOICE:RN:Z9:2025', 'EVENT_NO_INVOICE', N'Z9', NULL, N'stale', '2026-01-01', '2026-01-01', NULL);

    -- 'INVOICE_MATCHES_MULTIPLE_EVENTS:' plus a 220-character event_nk exceeds anomaly_nk nvarchar(240).
    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (CONCAT(N'RN:', REPLICATE(N'L', 212), N':2025'), 804, N'W6', 'Renewal', '2024-11-05', 2025, NULL, 'Invoice shortfall',
            NULL, NULL, 'Counted on another event', 1, '2026-11-01', '2026-11-01');

    SELECT anomaly_id, anomaly_nk, anomaly_type, contact_no, detail, first_detected_at, last_seen_at, resolved_at
    INTO #Before
    FROM Layercake.silv_data_anomaly;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_data_anomaly_invoice;
        EXEC tSQLt.Fail 'Expected usp_load_silv_data_anomaly_invoice to fail with error 2628.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 2628 THROW;
    END CATCH;

    SELECT l.status, CASE WHEN l.error_message LIKE N'%(error 2628,%' THEN 1 ELSE 0 END AS logs_error
    INTO #Actual
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.logs_error
    INTO #Expected
    FROM (VALUES ('Failed', 1)) AS v(status, logs_error);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT anomaly_id, anomaly_nk, anomaly_type, contact_no, detail, first_detected_at, last_seen_at, resolved_at
    INTO #After
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';
END;
GO
