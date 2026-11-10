EXEC tSQLt.NewTestClass 'test_MOD011';
GO

CREATE PROCEDURE test_MOD011.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_event_amount';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_invoice_line_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2021, '2020-10-01', '2021-09-30', '2021-11-30'),
           (2022, '2021-10-01', '2022-09-30', '2022-11-30'),
           (2023, '2022-10-01', '2023-09-30', '2023-11-30'),
           (2024, '2023-10-01', '2024-09-30', '2024-11-30'),
           (2025, '2024-10-01', '2025-09-30', '2025-11-30'),
           (2026, '2025-10-01', '2026-09-30', '2026-11-30');

    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id)
    VALUES (N'SUBMRICS', N'SUB', 'subscription', NULL),
           (N'RAFEE_MRICS', N'SUB', 'readmission fee', NULL),
           (N'APPFEE', N'APP', 'enrolment or application fee', NULL);
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-001 Renewal with no eligible invoice gives one EVENT_NO_INVOICE row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:E1:2025', 101, N'E1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice',
            NULL, NULL, 'No invoice', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'RN:E1:2025', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_event
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.names_event
    INTO #Expected
    FROM (VALUES (N'E1', 'EVENT_NO_INVOICE', 1)) AS v(contact_no, anomaly_type, names_event);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-002 successful load logs Success with one row inserted]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:E1:2025', 101, N'E1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice',
            NULL, NULL, 'No invoice', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #Actual
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #Expected
    FROM (VALUES ('Success', 1, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-003 Renewal in 2022 with no eligible invoice gives EVENT_NO_INVOICE]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:E2:2022', 102, N'E2', 'Renewal', '2021-11-10', 2022, NULL, 'No eligible invoice',
            NULL, NULL, 'No invoice', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'RN:E2:2022', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_event
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.names_event
    INTO #Expected
    FROM (VALUES (N'E2', 'EVENT_NO_INVOICE', 1)) AS v(contact_no, anomaly_type, names_event);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-004 corrected invoice deletes the EVENT_NO_INVOICE row on the next load]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:E1:2025', 101, N'E1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice',
            NULL, NULL, 'No invoice', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (911001, N'E1', 2025, N'INV-E1-25', N'V911001', '2024-10-20', N'DD', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'E1', N'INV-E1-25', N'V911001', NULL, '2024-10-20', N'SUB', N'SUBMRICS', 450.00, 450.00, 0);

    UPDATE Layercake.silv_event_amount
    SET invoice_rec_id = 911001, match_outcome = 'Matched',
        subs_amount_gbp = 450.00, invoiced_subtotal_gbp = 450.00, amount_status = 'Invoiced'
    WHERE event_nk = N'RN:E1:2025';

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_data_anomaly';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #Actual
    FROM Layercake.etl_run_log AS l
    WHERE l.log_id = (SELECT MAX(x.log_id) FROM Layercake.etl_run_log AS x);

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #Expected
    FROM (VALUES ('Success', 0, 0, 1)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-005 eligible 2025 invoice with no event gives one INVOICE_NO_EVENT row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (920001, N'N1', 2025, N'INV-N1-25', N'V920001', '2024-10-15', N'DD', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'N1', N'INV-N1-25', N'V920001', NULL, '2024-10-15', N'SUB', N'SUBMRICS', 450.00, 450.00, 0);

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'920001', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_invoice
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.names_invoice
    INTO #Expected
    FROM (VALUES (N'N1', 'INVOICE_NO_EVENT', 1)) AS v(contact_no, anomaly_type, names_invoice);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-006 invoice year with no event taking amounts from it gives INVOICE_NO_EVENT though a Join falls in it]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (920011, N'N2', 2024, N'INV-N2-24', N'V920011', '2023-11-01', N'DD', N'GBP', 400.00, N'N', 0),
           (920012, N'N2', 2025, N'INV-N2-25', N'V920012', '2024-10-15', N'DD', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'N2', N'INV-N2-24', N'V920011', NULL, '2023-11-01', N'SUB', N'SUBMRICS', 400.00, 400.00, 0),
           (2, N'N2', N'INV-N2-25', N'V920012', NULL, '2024-10-15', N'SUB', N'SUBMRICS', 450.00, 450.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'JN:N2', 121, N'N2', 'Join', '2024-06-01', 2025, 920012, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'920011', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_2024_invoice,
           CASE WHEN CHARINDEX(N'920012', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_2025_invoice
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.names_2024_invoice, v.names_2025_invoice
    INTO #Expected
    FROM (VALUES (N'N2', 'INVOICE_NO_EVENT', 1, 0)) AS v(contact_no, anomaly_type, names_2024_invoice, names_2025_invoice);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-007 two eligible invoices in a year with no event give one INVOICE_NO_EVENT row each]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (920041, N'N4', 2025, N'INV-N4-A', N'V920041', '2024-10-10', N'DD', N'GBP', 400.00, N'N', 0),
           (920042, N'N4', 2025, N'INV-N4-B', N'V920042', '2025-01-10', N'DD', N'GBP', 420.00, N'N', 0);

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'920041', a.anomaly_nk) > 0 THEN 'INV-N4-A'
                WHEN CHARINDEX(N'920042', a.anomaly_nk) > 0 THEN 'INV-N4-B'
           END AS invoice_named
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.invoice_named
    INTO #Expected
    FROM (VALUES (N'N4', 'INVOICE_NO_EVENT', 'INV-N4-A'),
                 (N'N4', 'INVOICE_NO_EVENT', 'INV-N4-B')) AS v(contact_no, anomaly_type, invoice_named);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-008 credit note, deleted and fee-only invoices raise no INVOICE_NO_EVENT]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (920031, N'N3', 2025, N'CRE-0031', N'V920031', '2024-11-01', N'DD', N'GBP', -100.00, N'N', 0),
           (920032, N'N3', 2025, N'INV-N3-DEL', N'V920032', '2024-11-02', N'DD', N'GBP', 450.00, N'N', 1),
           (920033, N'N3', 2025, N'INV-N3-APP', N'V920033', '2024-11-03', N'DD', N'GBP', 50.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'N3', N'INV-N3-APP', N'V920033', NULL, '2024-11-03', N'APP', N'APPFEE', 50.00, 50.00, 0);

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_data_anomaly';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-009 invoice with no event raises INVOICE_NO_EVENT in 2022 but not in 2021]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (920051, N'N5', 2021, N'INV-N5-21', N'V920051', '2020-10-15', N'DD', N'GBP', 400.00, N'N', 0),
           (920061, N'N6', 2022, N'INV-N6-22', N'V920061', '2021-10-15', N'DD', N'GBP', 400.00, N'N', 0);

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'920061', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_invoice
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.names_invoice
    INTO #Expected
    FROM (VALUES (N'N6', 'INVOICE_NO_EVENT', 1)) AS v(contact_no, anomaly_type, names_invoice);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-010 Readmission on 2025-08-12 with no fee line gives one READMISSION_NO_FEE row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (930001, N'D1', 2025, N'INV-D1-25', N'V930001', '2025-08-01', N'Card', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'D1', N'INV-D1-25', N'V930001', NULL, '2025-08-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RD:D1:2025', 411, N'D1', 'Readmission', '2025-08-12', 2025, 930001, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'RD:D1:2025', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_event
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.names_event
    INTO #Expected
    FROM (VALUES (N'D1', 'READMISSION_NO_FEE', 1)) AS v(contact_no, anomaly_type, names_event);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-011 each Readmission without invoice or fee line has exactly one explaining row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (930031, N'D3', 2025, N'INV-D3-25', N'V930031', '2025-04-20', N'Card', N'GBP', 550.00, N'N', 0),
           (930041, N'D4', 2025, N'INV-D4-25', N'V930041', '2025-02-01', N'Card', N'GBP', 450.00, N'N', 0),
           (930051, N'D5', 2025, N'INV-D5-25', N'V930051', '2025-05-01', N'Card', N'GBP', 450.00, N'N', 0),
           (930061, N'D6', 2025, N'INV-D6-25', N'V930061', '2025-06-20', N'Card', N'GBP', 550.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'D3', N'INV-D3-25', N'V930031', NULL, '2025-04-20', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (2, N'D3', N'INV-D3-25', N'V930031', NULL, '2025-04-20', N'SUB', N'RAFEE_MRICS', 100.00, 100.00, 0),
           (3, N'D4', N'INV-D4-25', N'V930041', NULL, '2025-02-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (4, N'D5', N'INV-D5-25', N'V930051', NULL, '2025-05-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (5, N'D6', N'INV-D6-25', N'V930061', NULL, '2025-06-20', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (6, N'D6', N'INV-D6-25', N'V930061', NULL, '2025-06-20', N'SUB', N'RAFEE_MRICS', 100.00, 100.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RD:D2:2025', 421, N'D2', 'Readmission', '2025-05-20', 2025, NULL, 'No eligible invoice',
            NULL, NULL, 'No invoice', 1, '2026-11-01', '2026-11-01'),
           (N'RDA:D3:2025', 431, N'D3', 'Readmission', '2025-05-01', 2025, 930031, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01'),
           (N'RDB:D3:2025', 432, N'D3', 'Readmission', '2025-06-01', 2025, NULL, 'Invoice shortfall',
            NULL, NULL, 'Counted on another event', 1, '2026-11-01', '2026-11-01'),
           (N'RD:D4:2025', 441, N'D4', 'Readmission', '2025-02-14', 2025, 930041, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01'),
           (N'RD:D5:2025', 451, N'D5', 'Readmission', '2025-05-20', 2025, 930051, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01'),
           (N'RD:D6:2025', 461, N'D6', 'Readmission', '2025-07-01', 2025, 930061, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type, e.event_nk
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a
    LEFT JOIN Layercake.silv_event_amount AS e
        ON CHARINDEX(e.event_nk, a.anomaly_nk) > 0;

    SELECT v.contact_no, v.anomaly_type, v.event_nk
    INTO #Expected
    FROM (VALUES (N'D2', 'EVENT_NO_INVOICE', N'RD:D2:2025'),
                 (N'D3', 'INVOICE_MATCHES_MULTIPLE_EVENTS', N'RDB:D3:2025'),
                 (N'D4', 'READMISSION_FREE', N'RD:D4:2025'),
                 (N'D5', 'READMISSION_NO_FEE', N'RD:D5:2025')) AS v(contact_no, anomaly_type, event_nk);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-012 deleted readmission fee line does not count as a fee]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (930071, N'D7', 2025, N'INV-D7-25', N'V930071', '2025-08-01', N'Card', N'GBP', 550.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'D7', N'INV-D7-25', N'V930071', NULL, '2025-08-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (2, N'D7', N'INV-D7-25', N'V930071', NULL, '2025-08-01', N'SUB', N'RAFEE_MRICS', 100.00, 100.00, 1);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RD:D7:2025', 471, N'D7', 'Readmission', '2025-08-12', 2025, 930071, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'RD:D7:2025', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_event
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.names_event
    INTO #Expected
    FROM (VALUES (N'D7', 'READMISSION_NO_FEE', 1)) AS v(contact_no, anomaly_type, names_event);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-013 readmission fee is recognised by its mapped line type not its item code]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id)
    VALUES (N'XREADMIT', N'SUB', 'readmission fee', NULL);

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (930081, N'D8', 2025, N'INV-D8-25', N'V930081', '2025-08-01', N'Card', N'GBP', 550.00, N'N', 0),
           (930091, N'D9', 2025, N'INV-D9-25', N'V930091', '2025-08-01', N'Card', N'GBP', 550.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'D8', N'INV-D8-25', N'V930081', NULL, '2025-08-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (2, N'D8', N'INV-D8-25', N'V930081', NULL, '2025-08-01', N'SUB', N'RAFEE_ZZZ', 100.00, 100.00, 0),
           (3, N'D9', N'INV-D9-25', N'V930091', NULL, '2025-08-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (4, N'D9', N'INV-D9-25', N'V930091', NULL, '2025-08-01', N'SUB', N'XREADMIT', 100.00, 100.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RD:D8:2025', 481, N'D8', 'Readmission', '2025-08-12', 2025, 930081, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01'),
           (N'RD:D9:2025', 491, N'D9', 'Readmission', '2025-08-12', 2025, 930091, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'RD:D8:2025', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_event
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.names_event
    INTO #Expected
    FROM (VALUES (N'D8', 'READMISSION_NO_FEE', 1)) AS v(contact_no, anomaly_type, names_event);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-014 fee lines on another account or on a settling voucher are not the invoice own lines]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (930101, N'D10', 2025, N'INV-D10-25', N'V930101', '2025-08-01', N'Card', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'D10', N'INV-D10-25', N'V930101', NULL, '2025-08-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (2, N'OTHER1', N'INV-D10-25', N'V930101', NULL, '2025-08-01', N'SUB', N'RAFEE_MRICS', 100.00, 100.00, 0),
           (3, N'D10', N'PAY-D10', N'PAY930101', N'V930101', '2025-08-05', N'SUB', N'RAFEE_MRICS', 100.00, 100.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RD:D10:2025', 4101, N'D10', 'Readmission', '2025-08-12', 2025, 930101, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'RD:D10:2025', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_event
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.names_event
    INTO #Expected
    FROM (VALUES (N'D10', 'READMISSION_NO_FEE', 1)) AS v(contact_no, anomaly_type, names_event);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-015 Renewal matched to an invoice with no fee line raises no readmission row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (930111, N'F1', 2025, N'INV-F1-25', N'V930111', '2024-10-20', N'DD', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'F1', N'INV-F1-25', N'V930111', NULL, '2024-10-20', N'SUB', N'SUBMRICS', 450.00, 450.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:F1:2025', 501, N'F1', 'Renewal', '2025-02-14', 2025, 930111, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_data_anomaly';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-016 second load on unchanged data leaves every anomaly row unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (920001, N'N1', 2025, N'INV-N1-25', N'V920001', '2024-10-15', N'DD', N'GBP', 450.00, N'N', 0),
           (950003, N'R2', 2025, N'INV-3', N'V950003', '2024-10-25', N'DD', N'GBP', 550.00, N'N', 0),
           (950004, N'R3', 2025, N'INV-4', N'V950004', '2024-10-01', N'DD', N'GBP', 400.00, N'N', 0),
           (950005, N'R3', 2025, N'INV-5', N'V950005', '2024-12-01', N'DD', N'GBP', 420.00, N'N', 0),
           (930041, N'D4', 2025, N'INV-D4-25', N'V930041', '2025-02-01', N'Card', N'GBP', 450.00, N'N', 0),
           (930001, N'D1', 2025, N'INV-D1-25', N'V930001', '2025-08-01', N'Card', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'N1', N'INV-N1-25', N'V920001', NULL, '2024-10-15', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (2, N'R2', N'INV-3', N'V950003', NULL, '2024-10-25', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (3, N'R2', N'INV-3', N'V950003', NULL, '2024-10-25', N'SUB', N'RAFEE_MRICS', 100.00, 100.00, 0),
           (4, N'R3', N'INV-4', N'V950004', NULL, '2024-10-01', N'SUB', N'SUBMRICS', 400.00, 400.00, 0),
           (5, N'R3', N'INV-5', N'V950005', NULL, '2024-12-01', N'SUB', N'SUBMRICS', 420.00, 420.00, 0),
           (6, N'D4', N'INV-D4-25', N'V930041', NULL, '2025-02-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (7, N'D1', N'INV-D1-25', N'V930001', NULL, '2025-08-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:E1:2025', 101, N'E1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice',
            NULL, NULL, 'No invoice', 1, '2026-11-01', '2026-11-01'),
           (N'RN:R2:2025', 201, N'R2', 'Renewal', '2024-11-05', 2025, NULL, 'Invoice shortfall',
            NULL, NULL, 'Counted on another event', 1, '2026-11-01', '2026-11-01'),
           (N'RD:R2:2025', 202, N'R2', 'Readmission', '2025-03-10', 2025, 950003, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01'),
           (N'RN:R3:2025', 301, N'R3', 'Renewal', '2024-11-05', 2025, 950005, 'Matched',
            820.00, 820.00, 'Invoiced', 1, '2026-11-01', '2026-11-01'),
           (N'RD:D4:2025', 441, N'D4', 'Readmission', '2025-02-14', 2025, 930041, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01'),
           (N'RD:D1:2025', 411, N'D1', 'Readmission', '2025-08-12', 2025, 930001, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT * INTO #Before FROM Layercake.silv_data_anomaly;

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT * INTO #After FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT a.anomaly_type, COUNT(*) AS row_count
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a
    GROUP BY a.anomaly_type;

    SELECT v.anomaly_type, v.row_count
    INTO #Expected
    FROM (VALUES ('EVENT_NO_INVOICE', 1),
                 ('INVOICE_NO_EVENT', 1),
                 ('INVOICE_MATCHES_MULTIPLE_EVENTS', 1),
                 ('EVENT_MATCHES_MULTIPLE_INVOICES', 1),
                 ('READMISSION_FREE', 1),
                 ('READMISSION_NO_FEE', 1)) AS v(anomaly_type, row_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-017 second load on unchanged data logs 0 inserted 0 updated 0 deleted]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (920001, N'N1', 2025, N'INV-N1-25', N'V920001', '2024-10-15', N'DD', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:E1:2025', 101, N'E1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice',
            NULL, NULL, 'No invoice', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;
    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #Actual
    FROM Layercake.etl_run_log AS l
    WHERE l.log_id = (SELECT MAX(x.log_id) FROM Layercake.etl_run_log AS x);

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #Expected
    FROM (VALUES ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-018 rows of other anomaly types are left untouched]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_data_anomaly
        (anomaly_nk, anomaly_type, contact_no, source_enr_id, detail, first_detected_at, last_seen_at, resolved_at)
    VALUES (N'DOUBLE_PAYMENT:E1:2025', 'DOUBLE_PAYMENT', N'E1', NULL, N'Campaign Year 2025: segment invoice X', '2026-01-05', '2026-01-05', NULL),
           (N'NO_RICS_RECORD:E1', 'NO_RICS_RECORD', N'E1', NULL, N'No RICS record', '2025-06-01', '2026-02-01', NULL),
           (N'JOIN_NO_PAYMENT:Z2', 'JOIN_NO_PAYMENT', N'Z2', NULL, N'Join without payment', '2025-06-01', '2025-07-01', '2025-08-01');

    SELECT * INTO #Before FROM Layercake.silv_data_anomaly;

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:E1:2025', 101, N'E1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice',
            NULL, NULL, 'No invoice', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT * INTO #After
    FROM Layercake.silv_data_anomaly
    WHERE anomaly_type NOT IN ('EVENT_NO_INVOICE', 'INVOICE_NO_EVENT', 'INVOICE_MATCHES_MULTIPLE_EVENTS',
                               'EVENT_MATCHES_MULTIPLE_INVOICES', 'READMISSION_FREE', 'READMISSION_NO_FEE');

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-019 own-type rows no longer raised are deleted]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_data_anomaly
        (anomaly_nk, anomaly_type, contact_no, source_enr_id, detail, first_detected_at, last_seen_at, resolved_at)
    VALUES (N'EVENT_NO_INVOICE:RN:Z9:2025', 'EVENT_NO_INVOICE', N'Z9', NULL, N'stale', '2026-01-01', '2026-01-01', NULL),
           (N'INVOICE_NO_EVENT:990001', 'INVOICE_NO_EVENT', N'Z9', NULL, N'stale', '2026-01-01', '2026-01-01', NULL),
           (N'INVOICE_MATCHES_MULTIPLE_EVENTS:RN:Z9:2024', 'INVOICE_MATCHES_MULTIPLE_EVENTS', N'Z9', NULL, N'stale', '2026-01-01', '2026-01-01', NULL),
           (N'EVENT_MATCHES_MULTIPLE_INVOICES:990002', 'EVENT_MATCHES_MULTIPLE_INVOICES', N'Z9', NULL, N'stale', '2026-01-01', '2026-01-01', NULL),
           (N'READMISSION_FREE:RD:Z9:2023', 'READMISSION_FREE', N'Z9', NULL, N'stale', '2026-01-01', '2026-01-01', NULL),
           (N'READMISSION_NO_FEE:RD:Z9:2022', 'READMISSION_NO_FEE', N'Z9', NULL, N'stale', '2026-01-01', '2026-01-01', NULL);

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_data_anomaly';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD011.[test TC-011-020 failed load logs Failed re-raises and leaves silv_data_anomaly unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Defaults = 1;
    EXEC tSQLt.ApplyConstraint 'Layercake.silv_data_anomaly', 'pk_silv_data_anomaly';

    INSERT INTO Layercake.silv_data_anomaly
        (anomaly_id, anomaly_nk, anomaly_type, contact_no, source_enr_id, detail, first_detected_at, last_seen_at, resolved_at)
    VALUES (1, N'EVENT_NO_INVOICE:RN:Z9:2025', 'EVENT_NO_INVOICE', N'Z9', NULL, N'stale', '2026-01-01', '2026-01-01', NULL);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:E1:2025', 101, N'E1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice',
            NULL, NULL, 'No invoice', 1, '2026-11-01', '2026-11-01');

    SELECT * INTO #Before FROM Layercake.silv_data_anomaly;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_data_anomaly_invoice;
        EXEC tSQLt.Fail 'Expected usp_load_silv_data_anomaly_invoice to fail with error 515.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515 THROW;
    END CATCH;

    SELECT l.status, CASE WHEN l.error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #Actual
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.has_error_message
    INTO #Expected
    FROM (VALUES ('Failed', 1)) AS v(status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT * INTO #After FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-021 Readmission on 2025-02-14 with no fee line gives one READMISSION_FREE row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (930041, N'D4', 2025, N'INV-D4-25', N'V930041', '2025-02-01', N'Card', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'D4', N'INV-D4-25', N'V930041', NULL, '2025-02-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RD:D4:2025', 441, N'D4', 'Readmission', '2025-02-14', 2025, 930041, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'RD:D4:2025', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_event
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.names_event
    INTO #Expected
    FROM (VALUES (N'D4', 'READMISSION_FREE', 1)) AS v(contact_no, anomaly_type, names_event);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-022 free window runs 1 January to 31 March inclusive for a Campaign Year starting 1 October]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (960001, N'G1', 2025, N'INV-G1-25', N'V960001', '2024-12-20', N'Card', N'GBP', 450.00, N'N', 0),
           (960002, N'G2', 2025, N'INV-G2-25', N'V960002', '2025-03-20', N'Card', N'GBP', 450.00, N'N', 0),
           (960003, N'G3', 2025, N'INV-G3-25', N'V960003', '2024-12-20', N'Card', N'GBP', 450.00, N'N', 0),
           (960004, N'G4', 2025, N'INV-G4-25', N'V960004', '2025-03-25', N'Card', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'G1', N'INV-G1-25', N'V960001', NULL, '2024-12-20', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (2, N'G2', N'INV-G2-25', N'V960002', NULL, '2025-03-20', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (3, N'G3', N'INV-G3-25', N'V960003', NULL, '2024-12-20', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (4, N'G4', N'INV-G4-25', N'V960004', NULL, '2025-03-25', N'SUB', N'SUBMRICS', 450.00, 450.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RD:G1:2025', 601, N'G1', 'Readmission', '2025-01-01', 2025, 960001, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01'),
           (N'RD:G2:2025', 602, N'G2', 'Readmission', '2025-03-31', 2025, 960002, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01'),
           (N'RD:G3:2025', 603, N'G3', 'Readmission', '2024-12-31', 2025, 960003, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01'),
           (N'RD:G4:2025', 604, N'G4', 'Readmission', '2025-04-01', 2025, 960004, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type
    INTO #Expected
    FROM (VALUES (N'G1', 'READMISSION_FREE'),
                 (N'G2', 'READMISSION_FREE'),
                 (N'G3', 'READMISSION_NO_FEE'),
                 (N'G4', 'READMISSION_NO_FEE')) AS v(contact_no, anomaly_type);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-023 free window is months four to six counted from campaign_year_start]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    UPDATE Layercake.ref_campaign_year_config
    SET campaign_year_start = '2025-11-01', campaign_year_end = '2026-10-31'
    WHERE campaign_year = 2026;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (960011, N'H1', 2026, N'INV-H1-26', N'V960011', '2026-04-01', N'Card', N'GBP', 450.00, N'N', 0),
           (960012, N'H2', 2026, N'INV-H2-26', N'V960012', '2026-01-05', N'Card', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'H1', N'INV-H1-26', N'V960011', NULL, '2026-04-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (2, N'H2', N'INV-H2-26', N'V960012', NULL, '2026-01-05', N'SUB', N'SUBMRICS', 450.00, 450.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RD:H1:2026', 611, N'H1', 'Readmission', '2026-04-15', 2026, 960011, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01'),
           (N'RD:H2:2026', 612, N'H2', 'Readmission', '2026-01-15', 2026, 960012, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type
    INTO #Expected
    FROM (VALUES (N'H1', 'READMISSION_FREE'),
                 (N'H2', 'READMISSION_NO_FEE')) AS v(contact_no, anomaly_type);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-024 contact R1 with two events and two invoices has no invoice anomaly]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (950001, N'R1', 2025, N'INV-1', N'V950001', '2024-10-20', N'DD', N'GBP', 450.00, N'N', 0),
           (950002, N'R1', 2025, N'INV-2', N'V950002', '2025-03-01', N'Card', N'GBP', 550.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'R1', N'INV-1', N'V950001', NULL, '2024-10-20', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (2, N'R1', N'INV-2', N'V950002', NULL, '2025-03-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (3, N'R1', N'INV-2', N'V950002', NULL, '2025-03-01', N'SUB', N'RAFEE_MRICS', 100.00, 100.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:R1:2025', 101, N'R1', 'Renewal', '2024-11-05', 2025, 950001, 'Matched',
            NULL, NULL, 'Counted on another event', 1, '2026-11-01', '2026-11-01'),
           (N'RD:R1:2025', 102, N'R1', 'Readmission', '2025-03-10', 2025, 950002, 'Matched',
            900.00, 900.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_data_anomaly';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-025 contact R2 has one INVOICE_MATCHES_MULTIPLE_EVENTS row for its Renewal]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (950003, N'R2', 2025, N'INV-3', N'V950003', '2024-10-25', N'DD', N'GBP', 550.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'R2', N'INV-3', N'V950003', NULL, '2024-10-25', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (2, N'R2', N'INV-3', N'V950003', NULL, '2024-10-25', N'SUB', N'RAFEE_MRICS', 100.00, 100.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:R2:2025', 201, N'R2', 'Renewal', '2024-11-05', 2025, NULL, 'Invoice shortfall',
            NULL, NULL, 'Counted on another event', 1, '2026-11-01', '2026-11-01'),
           (N'RD:R2:2025', 202, N'R2', 'Readmission', '2025-03-10', 2025, 950003, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'RN:R2:2025', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_renewal
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.names_renewal
    INTO #Expected
    FROM (VALUES (N'R2', 'INVOICE_MATCHES_MULTIPLE_EVENTS', 1)) AS v(contact_no, anomaly_type, names_renewal);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-026 contact R3 has one EVENT_MATCHES_MULTIPLE_INVOICES row for INV-4]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (950004, N'R3', 2025, N'INV-4', N'V950004', '2024-10-01', N'DD', N'GBP', 400.00, N'N', 0),
           (950005, N'R3', 2025, N'INV-5', N'V950005', '2024-12-01', N'DD', N'GBP', 420.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'R3', N'INV-4', N'V950004', NULL, '2024-10-01', N'SUB', N'SUBMRICS', 400.00, 400.00, 0),
           (2, N'R3', N'INV-5', N'V950005', NULL, '2024-12-01', N'SUB', N'SUBMRICS', 420.00, 420.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:R3:2025', 301, N'R3', 'Renewal', '2024-11-05', 2025, 950005, 'Matched',
            820.00, 820.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'950004', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_inv_4,
           CASE WHEN CHARINDEX(N'950005', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_inv_5
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.names_inv_4, v.names_inv_5
    INTO #Expected
    FROM (VALUES (N'R3', 'EVENT_MATCHES_MULTIPLE_INVOICES', 1, 0)) AS v(contact_no, anomaly_type, names_inv_4, names_inv_5);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-027 Renewal and Readmission in Campaign Year 2021 with no invoice raise nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:K9:2021', 701, N'K9', 'Renewal', '2020-11-05', 2021, NULL, 'Before invoice data',
            NULL, NULL, 'Before invoice data', 1, '2026-11-01', '2026-11-01'),
           (N'RD:K9:2021', 702, N'K9', 'Readmission', '2021-02-10', 2021, NULL, 'Before invoice data',
            NULL, NULL, 'Before invoice data', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_data_anomaly';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-028 the amount Campaign Year not the event year decides whether a Join is checked]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'JN:J1', 711, N'J1', 'Join', '2021-05-01', 2022, NULL, 'No eligible invoice',
            NULL, NULL, 'No invoice', 1, '2026-11-01', '2026-11-01'),
           (N'JN:J2', 712, N'J2', 'Join', '2022-03-01', 2021, NULL, 'Before invoice data',
            NULL, NULL, 'Before invoice data', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'JN:J1', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_event
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.contact_no, v.anomaly_type, v.names_event
    INTO #Expected
    FROM (VALUES (N'J1', 'EVENT_NO_INVOICE', 1)) AS v(contact_no, anomaly_type, names_event);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD011.[test TC-011-029 readmission fee check reads the invoice lines not the event amount]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (950003, N'R2', 2025, N'INV-3', N'V950003', '2024-10-25', N'DD', N'GBP', 550.00, N'N', 0),
           (950013, N'R2B', 2025, N'INV-R2B', N'V950013', '2025-05-01', N'Card', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (1, N'R2', N'INV-3', N'V950003', NULL, '2024-10-25', N'SUB', N'SUBMRICS', 450.00, 450.00, 0),
           (2, N'R2', N'INV-3', N'V950003', NULL, '2024-10-25', N'SUB', N'RAFEE_MRICS', 100.00, 100.00, 0),
           (3, N'R2B', N'INV-R2B', N'V950013', NULL, '2025-05-01', N'SUB', N'SUBMRICS', 450.00, 450.00, 0);

    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:R2:2025', 201, N'R2', 'Renewal', '2024-11-05', 2025, NULL, 'Invoice shortfall',
            NULL, NULL, 'Counted on another event', 1, '2026-11-01', '2026-11-01'),
           (N'RD:R2:2025', 202, N'R2', 'Readmission', '2025-03-10', 2025, 950003, 'Matched',
            450.00, 450.00, 'Invoiced', 1, '2026-11-01', '2026-11-01'),
           (N'RD:R2B:2025', 221, N'R2B', 'Readmission', '2025-05-20', 2025, 950013, 'Matched',
            550.00, 550.00, 'Invoiced', 1, '2026-11-01', '2026-11-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT a.contact_no, a.anomaly_type,
           CASE WHEN CHARINDEX(N'RD:R2B:2025', a.anomaly_nk) > 0 THEN 1 ELSE 0 END AS names_event
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a
    WHERE a.anomaly_type IN ('READMISSION_FREE', 'READMISSION_NO_FEE');

    SELECT v.contact_no, v.anomaly_type, v.names_event
    INTO #Expected
    FROM (VALUES (N'R2B', 'READMISSION_NO_FEE', 1)) AS v(contact_no, anomaly_type, names_event);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
