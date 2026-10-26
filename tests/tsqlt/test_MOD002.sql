EXEC tSQLt.NewTestClass 'test_MOD002';
GO

CREATE PROCEDURE test_MOD002.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.tblSubsInvoices';
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
END;
GO

/* ---------------------------------------------------------------
   usp_load_brnz_subs_invoice
--------------------------------------------------------------- */

CREATE PROCEDURE test_MOD002.[test TC-002-001 first invoice load lands 5 source rows 1:1 and live]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency, Exchange_Rate,
         Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR, Inv_Credit_Amount_GBP,
         Fully_Credited, Payment_Status, Has_Concession, [100%_Concession])
    VALUES
        (1001, N'A1001', 2025, N'INV-1001', N'V1001', '2024-10-15', N'DD',        N'GBP', 1.0000000000000000,  450.000000,  450.000000,  450.000000,    0.000000,   0.000000, 'N', N'Paid',           'N', 'N'),
        (1002, N'A1002', 2025, N'INV-1002', N'V1002', '2024-11-01', N'Card',      N'EUR', 0.8600000000000000,  500.000000,  500.000000,  430.000000,  100.000000,  86.000000, 'N', N'Partially Paid', 'Y', 'N'),
        (1003, N'A1003', 2024, N'INV-1003', N'V1003', '2023-10-20', N'Bank',      N'HKD', 0.1025000000000000, 4000.000000, 4000.000000,  410.000000, 4000.000000, 410.000000, 'Y', N'Fully Credited', 'N', 'N'),
        (1004, N'A1004', 2023, N'CRE-0001', N'V1004', '2023-01-05', N'Cheque',    N'GBP', 1.0000000000000000, -450.000000, -450.000000, -450.000000,    0.000000,   0.000000, 'N', N'Unpaid',         'N', 'N'),
        (1005, N'A1005', 2022, N'INV-1005', N'V1005', '2021-10-10', N'Corporate', N'GBP', 1.0000000000000000,  450.000000,    0.000000,    0.000000,    0.000000,   0.000000, 'N', N'Paid',           'Y', 'Y');

    EXEC Layercake.usp_load_brnz_subs_invoice;

    SELECT rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, exchange_rate,
           full_invoice_amount_cur, invoice_amount_cur, invoice_amount_gbp, inv_credit_amount_cur, inv_credit_amount_gbp,
           fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted
    INTO #Actual
    FROM Layercake.brnz_subs_invoice;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, exchange_rate,
         full_invoice_amount_cur, invoice_amount_cur, invoice_amount_gbp, inv_credit_amount_cur, inv_credit_amount_gbp,
         fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES
        (1001, N'A1001', 2025, N'INV-1001', N'V1001', '2024-10-15', N'DD',        N'GBP', 1.0000000000000000,  450.000000,  450.000000,  450.000000,    0.000000,   0.000000, N'N', N'Paid',           N'N', N'N', 0),
        (1002, N'A1002', 2025, N'INV-1002', N'V1002', '2024-11-01', N'Card',      N'EUR', 0.8600000000000000,  500.000000,  500.000000,  430.000000,  100.000000,  86.000000, N'N', N'Partially Paid', N'Y', N'N', 0),
        (1003, N'A1003', 2024, N'INV-1003', N'V1003', '2023-10-20', N'Bank',      N'HKD', 0.1025000000000000, 4000.000000, 4000.000000,  410.000000, 4000.000000, 410.000000, N'Y', N'Fully Credited', N'N', N'N', 0),
        (1004, N'A1004', 2023, N'CRE-0001', N'V1004', '2023-01-05', N'Cheque',    N'GBP', 1.0000000000000000, -450.000000, -450.000000, -450.000000,    0.000000,   0.000000, N'N', N'Unpaid',         N'N', N'N', 0),
        (1005, N'A1005', 2022, N'INV-1005', N'V1005', '2021-10-10', N'Corporate', N'GBP', 1.0000000000000000,  450.000000,    0.000000,    0.000000,    0.000000,   0.000000, N'N', N'Paid',           N'Y', N'Y', 0);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-002 null Inv_Payment_Method lands as null]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency, Exchange_Rate,
         Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR, Inv_Credit_Amount_GBP,
         Fully_Credited, Payment_Status, Has_Concession, [100%_Concession])
    VALUES
        (1101, N'A1101', 2025, N'INV-1101', N'V1101', '2024-10-15', NULL,  N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Unpaid', 'N', 'N'),
        (1102, N'A1102', 2025, N'INV-1102', N'V1102', '2024-10-16', N'DD', N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Paid',   'N', 'N');

    EXEC Layercake.usp_load_brnz_subs_invoice;

    SELECT rec_id,
           CASE WHEN inv_payment_method IS NULL THEN 1 ELSE 0 END AS payment_method_is_null,
           _is_deleted
    INTO #Actual
    FROM Layercake.brnz_subs_invoice;

    SELECT rec_id, payment_method_is_null, _is_deleted
    INTO #Expected
    FROM (VALUES (CAST(1101 AS bigint), 1, CAST(0 AS bit)),
                 (CAST(1102 AS bigint), 0, CAST(0 AS bit))) AS v(rec_id, payment_method_is_null, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-003 blank and untrimmed payment methods land byte for byte]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency, Exchange_Rate,
         Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR, Inv_Credit_Amount_GBP,
         Fully_Credited, Payment_Status, Has_Concession, [100%_Concession])
    VALUES
        (1201, N'A1201', 2025, N'INV-1201', N'V1201', '2024-10-15', N'',     N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Unpaid', 'N', 'N'),
        (1202, N'A1202', 2025, N'INV-1202', N'V1202', '2024-10-16', N' dd ', N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Paid',   'N', 'N');

    EXEC Layercake.usp_load_brnz_subs_invoice;

    SELECT rec_id,
           CASE WHEN inv_payment_method IS NULL THEN 1 ELSE 0 END AS payment_method_is_null,
           CAST(inv_payment_method AS varbinary(40)) AS payment_method_bytes
    INTO #Actual
    FROM Layercake.brnz_subs_invoice;

    SELECT rec_id, payment_method_is_null, payment_method_bytes
    INTO #Expected
    FROM (VALUES (CAST(1201 AS bigint), 0, CAST(N'' AS varbinary(40))),
                 (CAST(1202 AS bigint), 0, CAST(N' dd ' AS varbinary(40)))) AS v(rec_id, payment_method_is_null, payment_method_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-004 first invoice load logs Success with 5 rows inserted]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency, Exchange_Rate,
         Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR, Inv_Credit_Amount_GBP,
         Fully_Credited, Payment_Status, Has_Concession, [100%_Concession])
    VALUES
        (1301, N'A1301', 2025, N'INV-1301', N'V1301', '2024-10-15', N'DD',        N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Paid',   'N', 'N'),
        (1302, N'A1302', 2025, N'INV-1302', N'V1302', '2024-10-16', N'Card',      N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Paid',   'N', 'N'),
        (1303, N'A1303', 2024, N'INV-1303', N'V1303', '2023-10-17', N'Bank',      N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Paid',   'N', 'N'),
        (1304, N'A1304', 2023, N'INV-1304', N'V1304', '2022-10-18', N'Cheque',    N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Unpaid', 'N', 'N'),
        (1305, N'A1305', 2022, N'INV-1305', N'V1305', '2021-10-19', N'Corporate', N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Paid',   'N', 'N');

    EXEC Layercake.usp_load_brnz_subs_invoice;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #Actual
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #Expected
    FROM (VALUES (CAST('Success' AS varchar(10)), 5, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-005 second invoice load on unchanged source changes nothing and logs 0 inserted 0 updated]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency, Exchange_Rate,
         Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR, Inv_Credit_Amount_GBP,
         Fully_Credited, Payment_Status, Has_Concession, [100%_Concession])
    VALUES
        (1401, N'A1401', 2025, N'INV-1401', N'V1401', '2024-10-15', N'DD',        N'GBP', 1.0000000000000000,  450.000000,  450.000000,  450.000000,   0.000000,  0.000000, 'N', N'Paid',           'N', 'N'),
        (1402, N'A1402', 2025, N'INV-1402', N'V1402', '2024-11-01', N'Card',      N'EUR', 0.8600000000000000,  500.000000,  500.000000,  430.000000, 100.000000, 86.000000, 'N', N'Partially Paid', 'Y', 'N'),
        (1403, N'A1403', 2024, N'INV-1403', N'V1403', '2023-10-20', NULL,         N'GBP', 1.0000000000000000,  300.000000,  300.000000,  300.000000, 300.000000, 300.000000, 'Y', N'Fully Credited', 'N', 'N'),
        (1404, N'A1404', 2023, N'CRE-0004', N'V1404', '2023-01-05', N'Cheque',    N'GBP', 1.0000000000000000, -450.000000, -450.000000, -450.000000,   0.000000,  0.000000, 'N', NULL,              'N', 'N'),
        (1405, N'A1405', 2022, N'INV-1405', N'V1405', '2021-10-10', N'Corporate', N'GBP', 1.0000000000000000,  450.000000,    0.000000,    0.000000,   0.000000,  0.000000, 'N', N'Paid',           'Y', 'Y');

    EXEC Layercake.usp_load_brnz_subs_invoice;

    SELECT * INTO #Before FROM Layercake.brnz_subs_invoice;

    EXEC Layercake.usp_load_brnz_subs_invoice;

    SELECT * INTO #After FROM Layercake.brnz_subs_invoice;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'Second load changed brnz_subs_invoice';

    DECLARE @live int = (SELECT COUNT(*) FROM Layercake.brnz_subs_invoice WHERE _is_deleted = 0);
    EXEC tSQLt.AssertEquals 5, @live, 'Live row count after second load';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 5, 0, 0),
                 (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log rows for the two loads';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-006 every landed invoice row has _loaded_at and _updated_at]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency, Exchange_Rate,
         Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR, Inv_Credit_Amount_GBP,
         Fully_Credited, Payment_Status, Has_Concession, [100%_Concession])
    VALUES
        (1501, N'A1501', 2025, N'INV-1501', N'V1501', '2024-10-15', N'DD', N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Paid', 'N', 'N'),
        (1502, N'A1502', 2025, N'INV-1502', N'V1502', '2024-10-16', NULL,  NULL,   NULL, NULL,       NULL,       NULL,       NULL,     NULL,     'N', NULL,    'N', NULL);

    EXEC Layercake.usp_load_brnz_subs_invoice;

    SELECT rec_id,
           CASE WHEN _loaded_at IS NOT NULL THEN 1 ELSE 0 END AS loaded_at_set,
           CASE WHEN _updated_at IS NOT NULL THEN 1 ELSE 0 END AS updated_at_set
    INTO #Actual
    FROM Layercake.brnz_subs_invoice;

    SELECT rec_id, loaded_at_set, updated_at_set
    INTO #Expected
    FROM (VALUES (CAST(1501 AS bigint), 1, 1),
                 (CAST(1502 AS bigint), 1, 1)) AS v(rec_id, loaded_at_set, updated_at_set);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-007 changed source invoice row is updated and only it gets a new _updated_at]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, exchange_rate,
         full_invoice_amount_cur, invoice_amount_cur, invoice_amount_gbp, inv_credit_amount_cur, inv_credit_amount_gbp,
         fully_credited, payment_status, has_concession, full_concession_flag, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES
        (2001, N'A2001', 2025, N'INV-2001', N'V2001', '2024-10-15', N'DD',   N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, N'N', N'Unpaid', N'N', N'N', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL),
        (2002, N'A2002', 2025, N'INV-2002', N'V2002', '2024-10-16', N'Card', N'GBP', 1.0, 300.000000, 300.000000, 300.000000, 0.000000, 0.000000, N'N', N'Paid',   N'N', N'N', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency, Exchange_Rate,
         Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR, Inv_Credit_Amount_GBP,
         Fully_Credited, Payment_Status, Has_Concession, [100%_Concession])
    VALUES
        (2001, N'A2001', 2025, N'INV-2001', N'V2001', '2024-10-15', N'DD',   N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Paid', 'N', 'N'),
        (2002, N'A2002', 2025, N'INV-2002', N'V2002', '2024-10-16', N'Card', N'GBP', 1.0, 300.000000, 300.000000, 300.000000, 0.000000, 0.000000, 'N', N'Paid', 'N', 'N');

    EXEC Layercake.usp_load_brnz_subs_invoice;

    SELECT rec_id, payment_status, _loaded_at,
           CASE WHEN _updated_at > '2020-01-01T00:00:00' THEN 1 ELSE 0 END AS updated_at_refreshed,
           _is_deleted
    INTO #Actual
    FROM Layercake.brnz_subs_invoice;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected (rec_id, payment_status, _loaded_at, updated_at_refreshed, _is_deleted)
    VALUES (2001, N'Paid', '2020-01-01T00:00:00', 1, 0),
           (2002, N'Paid', '2020-01-01T00:00:00', 0, 0);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'brnz_subs_invoice after the load';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-008 invoice row gone from source is soft deleted not removed]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, exchange_rate,
         full_invoice_amount_cur, invoice_amount_cur, invoice_amount_gbp, inv_credit_amount_cur, inv_credit_amount_gbp,
         fully_credited, payment_status, has_concession, full_concession_flag, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES
        (3001, N'A3001', 2025, N'INV-3001', N'V3001', '2024-10-15', N'DD',   N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, N'N', N'Paid', N'N', N'N', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL),
        (3002, N'A3002', 2025, N'INV-3002', N'V3002', '2024-10-16', N'Card', N'GBP', 1.0, 300.000000, 300.000000, 300.000000, 0.000000, 0.000000, N'N', N'Paid', N'N', N'N', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency, Exchange_Rate,
         Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR, Inv_Credit_Amount_GBP,
         Fully_Credited, Payment_Status, Has_Concession, [100%_Concession])
    VALUES
        (3001, N'A3001', 2025, N'INV-3001', N'V3001', '2024-10-15', N'DD', N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Paid', 'N', 'N');

    EXEC Layercake.usp_load_brnz_subs_invoice;

    SELECT rec_id, payment_status, _is_deleted,
           CASE WHEN _deleted_at IS NOT NULL THEN 1 ELSE 0 END AS deleted_at_set
    INTO #Actual
    FROM Layercake.brnz_subs_invoice;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected (rec_id, payment_status, _is_deleted, deleted_at_set)
    VALUES (3001, N'Paid', 0, 0),
           (3002, N'Paid', 1, 1);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'brnz_subs_invoice after the load';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 0, 1)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-009 soft deleted invoice row that reappears unchanged is restored]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, exchange_rate,
         full_invoice_amount_cur, invoice_amount_cur, invoice_amount_gbp, inv_credit_amount_cur, inv_credit_amount_gbp,
         fully_credited, payment_status, has_concession, full_concession_flag, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES
        (4001, N'A4001', 2025, N'INV-4001', N'V4001', '2024-10-15', N'DD', N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, N'N', N'Paid', N'N', N'N', '2020-01-01T00:00:00', '2020-06-01T00:00:00', 1, '2020-06-01T00:00:00');

    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency, Exchange_Rate,
         Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR, Inv_Credit_Amount_GBP,
         Fully_Credited, Payment_Status, Has_Concession, [100%_Concession])
    VALUES
        (4001, N'A4001', 2025, N'INV-4001', N'V4001', '2024-10-15', N'DD', N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Paid', 'N', 'N');

    EXEC Layercake.usp_load_brnz_subs_invoice;

    SELECT rec_id, account_num, payment_status, _is_deleted
    INTO #Actual
    FROM Layercake.brnz_subs_invoice;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected (rec_id, account_num, payment_status, _is_deleted)
    VALUES (4001, N'A4001', N'Paid', 0);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD002.[test TC-002-010 invoice load failing on an overflowing amount re-raises logs Failed and leaves the target unchanged]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, exchange_rate,
         full_invoice_amount_cur, invoice_amount_cur, invoice_amount_gbp, inv_credit_amount_cur, inv_credit_amount_gbp,
         fully_credited, payment_status, has_concession, full_concession_flag, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES
        (5001, N'A5001', 2025, N'INV-5001', N'V5001', '2024-10-15', N'DD', N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, N'N', N'Unpaid', N'N', N'N', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    SELECT * INTO #Before FROM Layercake.brnz_subs_invoice;

    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency, Exchange_Rate,
         Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR, Inv_Credit_Amount_GBP,
         Fully_Credited, Payment_Status, Has_Concession, [100%_Concession])
    VALUES
        (5001, N'A5001', 2025, N'INV-5001', N'V5001', '2024-10-15', N'DD', N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Paid', 'N', 'N'),
        (5002, N'A5002', 2025, N'INV-5002', N'V5002', '2024-10-16', N'DD', N'GBP', 1.0, 450.000000, 1000000000000000000000000000.000000, 450.000000, 0.000000, 0.000000, 'N', N'Paid', 'N', 'N');

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_subs_invoice;
        EXEC tSQLt.Fail 'usp_load_brnz_subs_invoice did not raise an error for an Invoice_Amount_CUR that overflows numeric(32,6)';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 8115 THROW;
    END CATCH;

    SELECT * INTO #After FROM Layercake.brnz_subs_invoice;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'brnz_subs_invoice changed by a failed load';

    SELECT status,
           CASE WHEN error_message IS NOT NULL THEN 1 ELSE 0 END AS error_recorded
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, error_recorded
    INTO #ExpectedLog
    FROM (VALUES (CAST('Failed' AS varchar(10)), 1)) AS v(status, error_recorded);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row for the failed load';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-019 live invoice rows reconcile to the source row count after inserts and a soft delete]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, exchange_rate,
         full_invoice_amount_cur, invoice_amount_cur, invoice_amount_gbp, inv_credit_amount_cur, inv_credit_amount_gbp,
         fully_credited, payment_status, has_concession, full_concession_flag, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES
        (7001, N'A7001', 2025, N'INV-7001', N'V7001', '2024-10-15', N'DD',   N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, N'N', N'Paid', N'N', N'N', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL),
        (7002, N'A7002', 2025, N'INV-7002', N'V7002', '2024-10-16', N'Card', N'GBP', 1.0, 300.000000, 300.000000, 300.000000, 0.000000, 0.000000, N'N', N'Paid', N'N', N'N', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency, Exchange_Rate,
         Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR, Inv_Credit_Amount_GBP,
         Fully_Credited, Payment_Status, Has_Concession, [100%_Concession])
    VALUES
        (7001, N'A7001', 2025, N'INV-7001', N'V7001', '2024-10-15', N'DD',   N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Paid',   'N', 'N'),
        (7003, N'A7003', 2025, N'INV-7003', N'V7003', '2024-10-17', N'Bank', N'GBP', 1.0, 450.000000, 450.000000, 450.000000, 0.000000, 0.000000, 'N', N'Unpaid', 'N', 'N'),
        (7004, N'A7004', 2026, N'INV-7004', N'V7004', '2025-10-18', N'DD',   N'GBP', 1.0, 460.000000, 460.000000, 460.000000, 0.000000, 0.000000, 'N', N'Unpaid', 'N', 'N');

    EXEC Layercake.usp_load_brnz_subs_invoice;

    SELECT rec_id, _is_deleted
    INTO #Actual
    FROM Layercake.brnz_subs_invoice;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected (rec_id, _is_deleted)
    VALUES (7001, 0), (7002, 1), (7003, 0), (7004, 0);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'brnz_subs_invoice after the load';

    DECLARE @live int = (SELECT COUNT(*) FROM Layercake.brnz_subs_invoice WHERE _is_deleted = 0);
    DECLARE @source int = (SELECT COUNT(*) FROM Subs.tblSubsInvoices);
    EXEC tSQLt.AssertEquals @source, @live, 'Live rows must equal source rows';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 2, 0, 1)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO

/* ---------------------------------------------------------------
   usp_load_brnz_subs_invoice_line
--------------------------------------------------------------- */

CREATE PROCEDURE test_MOD002.[test TC-002-011 first line load lands 12 in-scope rows 1:1 and live]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher)
    VALUES (8001, N'A1', 2025, N'INV-1', N'V1'),
           (8002, N'A2', 2025, N'INV-2', N'V2');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, _loaded_at, _updated_at, _is_deleted)
    VALUES (8001, N'A1', 2025, N'INV-1', N'V1', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0),
           (8002, N'A2', 2025, N'INV-2', N'V2', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, PAYMMODE, PAYMREFERENCE, ORDERNUM)
    VALUES
        (101, N'A1', N'INV-1', N'V1',   NULL,   '2024-10-20T00:00:00',  8, 'SUB', N'MEMSUB',      450.000000,  450.000000,    0.000000, N'GBP', NULL,    NULL,             N'ORD-1'),
        (102, N'A1', N'INV-1', N'V1',   N'PAY1','2024-10-20T00:00:00',  8, 'FEE', N'ENRFEE',       50.000000,   50.000000,   50.000000, N'GBP', NULL,    NULL,             N'ORD-1'),
        (103, N'A1', N'INV-1', N'V1',   N'PAY1','2024-10-20T00:00:00',  8, 'TAX', N'VAT',          90.000000,   90.000000,   90.000000, N'GBP', NULL,    NULL,             N'ORD-1'),
        (104, N'A1', N'INV-1', N'V1',   NULL,   '2024-10-20T00:00:00',  8, 'CON', N'CONRETIRED', -100.000000, -100.000000,    0.000000, N'GBP', NULL,    NULL,             N'ORD-1'),
        (105, N'A1', NULL,     N'CN1',  N'V1',  '2024-11-05T09:30:15',  8, 'CRN', N'MEMSUB',      -50.000000,  -50.000000,  -50.000000, N'GBP', NULL,    NULL,             N'ORD-1'),
        (106, N'A1', NULL,     N'PAY1', N'V1',  '2024-11-10T00:00:00', 15, 'PAY', NULL,          -440.000000, -440.000000, -440.000000, N'GBP', N'DD',   N'DDREF-106',     NULL),
        (107, N'A2', N'INV-2', N'V2',   NULL,   '2024-11-01T00:00:00',  8, 'SUB', N'MEMSUB',      500.000000,  430.000000,    0.000000, N'EUR', NULL,    NULL,             N'ORD-2'),
        (108, N'A2', N'INV-2', N'V2',   NULL,   '2024-11-01T00:00:00',  8, 'FEE', N'READFEE',     100.000000,   86.000000,    0.000000, N'EUR', NULL,    NULL,             N'ORD-2'),
        (109, N'A2', N'INV-2', N'V2',   NULL,   '2024-11-01T00:00:00',  8, 'TAX', N'VAT',           0.000000,    0.000000,    0.000000, N'EUR', NULL,    NULL,             N'ORD-2'),
        (110, N'A2', N'INV-2', N'V2',   NULL,   '2024-11-01T00:00:00',  8, 'SUB', N'NEWFEE',       25.000000,   21.500000,    0.000000, N'EUR', NULL,    NULL,             N'ORD-2'),
        (111, N'A2', NULL,     N'CN2',  N'V2',  '2024-12-01T00:00:00',  8, 'CRN', N'MEMSUB',     -100.000000,  -86.000000, -100.000000, N'EUR', NULL,    NULL,             N'ORD-2'),
        (112, N'A2', NULL,     N'PAY2', N'V2',  '2024-12-15T00:00:00', 15, 'PAY', NULL,          -525.000000, -451.500000, -525.000000, N'EUR', N'Card', N'CARDREF-112',   NULL);

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
           amountcur, amountmst, settleamountcur, currencycode, paymmode, paymreference, ordernum, _is_deleted
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, paymreference, ordernum, _is_deleted)
    VALUES
        (101, N'A1', N'INV-1', N'V1',   NULL,   '2024-10-20T00:00:00',  8, N'SUB', N'MEMSUB',      450.000000,  450.000000,    0.000000, N'GBP', NULL,    NULL,           N'ORD-1', 0),
        (102, N'A1', N'INV-1', N'V1',   N'PAY1','2024-10-20T00:00:00',  8, N'FEE', N'ENRFEE',       50.000000,   50.000000,   50.000000, N'GBP', NULL,    NULL,           N'ORD-1', 0),
        (103, N'A1', N'INV-1', N'V1',   N'PAY1','2024-10-20T00:00:00',  8, N'TAX', N'VAT',          90.000000,   90.000000,   90.000000, N'GBP', NULL,    NULL,           N'ORD-1', 0),
        (104, N'A1', N'INV-1', N'V1',   NULL,   '2024-10-20T00:00:00',  8, N'CON', N'CONRETIRED', -100.000000, -100.000000,    0.000000, N'GBP', NULL,    NULL,           N'ORD-1', 0),
        (105, N'A1', NULL,     N'CN1',  N'V1',  '2024-11-05T09:30:15',  8, N'CRN', N'MEMSUB',      -50.000000,  -50.000000,  -50.000000, N'GBP', NULL,    NULL,           N'ORD-1', 0),
        (106, N'A1', NULL,     N'PAY1', N'V1',  '2024-11-10T00:00:00', 15, N'PAY', NULL,          -440.000000, -440.000000, -440.000000, N'GBP', N'DD',   N'DDREF-106',   NULL,     0),
        (107, N'A2', N'INV-2', N'V2',   NULL,   '2024-11-01T00:00:00',  8, N'SUB', N'MEMSUB',      500.000000,  430.000000,    0.000000, N'EUR', NULL,    NULL,           N'ORD-2', 0),
        (108, N'A2', N'INV-2', N'V2',   NULL,   '2024-11-01T00:00:00',  8, N'FEE', N'READFEE',     100.000000,   86.000000,    0.000000, N'EUR', NULL,    NULL,           N'ORD-2', 0),
        (109, N'A2', N'INV-2', N'V2',   NULL,   '2024-11-01T00:00:00',  8, N'TAX', N'VAT',           0.000000,    0.000000,    0.000000, N'EUR', NULL,    NULL,           N'ORD-2', 0),
        (110, N'A2', N'INV-2', N'V2',   NULL,   '2024-11-01T00:00:00',  8, N'SUB', N'NEWFEE',       25.000000,   21.500000,    0.000000, N'EUR', NULL,    NULL,           N'ORD-2', 0),
        (111, N'A2', NULL,     N'CN2',  N'V2',  '2024-12-01T00:00:00',  8, N'CRN', N'MEMSUB',     -100.000000,  -86.000000, -100.000000, N'EUR', NULL,    NULL,           N'ORD-2', 0),
        (112, N'A2', NULL,     N'PAY2', N'V2',  '2024-12-15T00:00:00', 15, N'PAY', NULL,          -525.000000, -451.500000, -525.000000, N'EUR', N'Card', N'CARDREF-112', NULL,     0);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-012 line load keeps the 3 V1 lines and the V1 credit and excludes the 2 V9 rows]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher)
    VALUES (8101, N'A1', 2025, N'INV-1', N'V1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, _loaded_at, _updated_at, _is_deleted)
    VALUES (8101, N'A1', 2025, N'INV-1', N'V1', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, PAYMMODE, PAYMREFERENCE, ORDERNUM)
    VALUES
        (201, N'A1', N'INV-1', N'V1',  NULL,  '2024-10-20T00:00:00', 8, 'SUB', N'MEMSUB',  450.000000,  450.000000, 0.000000, N'GBP', NULL, NULL, N'ORD-1'),
        (202, N'A1', N'INV-1', N'V1',  NULL,  '2024-10-20T00:00:00', 8, 'FEE', N'READFEE', 100.000000,  100.000000, 0.000000, N'GBP', NULL, NULL, N'ORD-1'),
        (203, N'A1', N'INV-1', N'V1',  NULL,  '2024-10-20T00:00:00', 8, 'TAX', N'VAT',      90.000000,   90.000000, 0.000000, N'GBP', NULL, NULL, N'ORD-1'),
        (204, N'A1', NULL,     N'CN1', N'V1', '2024-11-05T00:00:00', 8, 'CRN', N'MEMSUB',  -50.000000,  -50.000000, -50.000000, N'GBP', NULL, NULL, N'ORD-1'),
        (205, N'A1', N'INV-9', N'V9',  NULL,  '2024-10-21T00:00:00', 8, 'SUB', N'BOOK',     30.000000,   30.000000, 0.000000, N'GBP', NULL, NULL, N'ORD-9'),
        (206, N'A1', N'INV-9', N'V9',  NULL,  '2024-10-21T00:00:00', 8, 'TAX', N'VAT',       6.000000,    6.000000, 0.000000, N'GBP', NULL, NULL, N'ORD-9');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT recid, _is_deleted
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected (recid, _is_deleted)
    VALUES (201, 0), (202, 0), (203, 0), (204, 0);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-013 line with the invoice voucher but another account is not landed]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher)
    VALUES (8201, N'A1', 2025, N'INV-1', N'V1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, _loaded_at, _updated_at, _is_deleted)
    VALUES (8201, N'A1', 2025, N'INV-1', N'V1', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, PAYMMODE, PAYMREFERENCE, ORDERNUM)
    VALUES
        (301, N'A1', N'INV-1', N'V1', NULL, '2024-10-20T00:00:00', 8, 'SUB', N'MEMSUB', 450.000000, 450.000000, 0.000000, N'GBP', NULL, NULL, N'ORD-1'),
        (302, N'A2', N'INV-1', N'V1', NULL, '2024-10-20T00:00:00', 8, 'SUB', N'MEMSUB', 450.000000, 450.000000, 0.000000, N'GBP', NULL, NULL, N'ORD-2');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT recid, accountnum
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected (recid, accountnum)
    VALUES (301, N'A1');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-014 line matching on both voucher and last settle voucher lands once]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher)
    VALUES (8301, N'A1', 2025, N'INV-1', N'V1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, _loaded_at, _updated_at, _is_deleted)
    VALUES (8301, N'A1', 2025, N'INV-1', N'V1', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, PAYMMODE, PAYMREFERENCE, ORDERNUM)
    VALUES
        (401, N'A1', N'INV-1', N'V1', N'V1', '2024-10-20T00:00:00', 8, 'SUB', N'MEMSUB', 450.000000, 450.000000, 450.000000, N'GBP', NULL, NULL, N'ORD-1'),
        (402, N'A1', N'INV-1', N'V1', NULL,  '2024-10-20T00:00:00', 8, 'TAX', N'VAT',     90.000000,  90.000000,   0.000000, N'GBP', NULL, NULL, N'ORD-1');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT recid, _is_deleted
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected (recid, _is_deleted)
    VALUES (401, 0), (402, 0);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-015 line whose invoice leaves Subs.tblSubsInvoices is soft deleted]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher)
    VALUES (8401, N'A1', 2025, N'INV-1', N'V1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (8401, N'A1', 2025, N'INV-1', N'V1', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL),
           (8402, N'A2', 2025, N'INV-2', N'V2', '2020-01-01T00:00:00', '2020-06-01T00:00:00', 1, '2020-06-01T00:00:00');

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, paymreference, ordernum,
         _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES
        (501, N'A1', N'INV-1', N'V1', NULL, '2024-10-20T00:00:00', 8, N'SUB', N'MEMSUB', 450.000000, 450.000000, 0.000000, N'GBP', NULL, NULL, N'ORD-1', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL),
        (502, N'A2', N'INV-2', N'V2', NULL, '2024-10-21T00:00:00', 8, N'SUB', N'MEMSUB', 450.000000, 450.000000, 0.000000, N'GBP', NULL, NULL, N'ORD-2', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, PAYMMODE, PAYMREFERENCE, ORDERNUM)
    VALUES
        (501, N'A1', N'INV-1', N'V1', NULL, '2024-10-20T00:00:00', 8, 'SUB', N'MEMSUB', 450.000000, 450.000000, 0.000000, N'GBP', NULL, NULL, N'ORD-1'),
        (502, N'A2', N'INV-2', N'V2', NULL, '2024-10-21T00:00:00', 8, 'SUB', N'MEMSUB', 450.000000, 450.000000, 0.000000, N'GBP', NULL, NULL, N'ORD-2');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT recid, _is_deleted,
           CASE WHEN _deleted_at IS NOT NULL THEN 1 ELSE 0 END AS deleted_at_set
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected (recid, _is_deleted, deleted_at_set)
    VALUES (501, 0, 0), (502, 1, 1);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-016 second line load on unchanged source changes nothing and both loads log Success]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher)
    VALUES (8501, N'A1', 2025, N'INV-1', N'V1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, _loaded_at, _updated_at, _is_deleted)
    VALUES (8501, N'A1', 2025, N'INV-1', N'V1', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, PAYMMODE, PAYMREFERENCE, ORDERNUM)
    VALUES
        (601, N'A1', N'INV-1', N'V1',   NULL,  '2024-10-20T00:00:00',  8, 'SUB', N'MEMSUB',  450.000000,  450.000000,    0.000000, N'GBP', NULL,  NULL,         N'ORD-1'),
        (602, N'A1', N'INV-1', N'V1',   NULL,  '2024-10-20T00:00:00',  8, 'TAX', N'VAT',      90.000000,   90.000000,    0.000000, N'GBP', NULL,  NULL,         N'ORD-1'),
        (603, N'A1', NULL,     N'PAY1', N'V1', '2024-11-10T00:00:00', 15, 'PAY', NULL,      -540.000000, -540.000000, -540.000000, N'GBP', N'DD', N'DDREF-603', NULL);

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Before FROM Layercake.brnz_subs_invoice_line;

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #After FROM Layercake.brnz_subs_invoice_line;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'Second load changed brnz_subs_invoice_line';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 3, 0, 0),
                 (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log rows for the two loads';
END;
GO

CREATE PROCEDURE test_MOD002.[test TC-002-017 every landed line row has _loaded_at and _updated_at]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher)
    VALUES (8601, N'A1', 2025, N'INV-1', N'V1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, _loaded_at, _updated_at, _is_deleted)
    VALUES (8601, N'A1', 2025, N'INV-1', N'V1', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, PAYMMODE, PAYMREFERENCE, ORDERNUM)
    VALUES
        (701, N'A1', N'INV-1', N'V1',  NULL,  '2024-10-20T00:00:00', 8, 'SUB', N'MEMSUB', 450.000000, 450.000000,   0.000000, N'GBP', NULL, NULL, N'ORD-1'),
        (702, N'A1', NULL,     N'CN1', N'V1', NULL,                  NULL, 'CRN', NULL,   NULL,       NULL,       NULL,       NULL,   NULL, NULL, NULL);

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT recid,
           CASE WHEN _loaded_at IS NOT NULL THEN 1 ELSE 0 END AS loaded_at_set,
           CASE WHEN _updated_at IS NOT NULL THEN 1 ELSE 0 END AS updated_at_set
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT recid, loaded_at_set, updated_at_set
    INTO #Expected
    FROM (VALUES (CAST(701 AS bigint), 1, 1),
                 (CAST(702 AS bigint), 1, 1)) AS v(recid, loaded_at_set, updated_at_set);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD002.[test TC-002-018 line load failing on a row the target rejects re-raises logs Failed and leaves the target unchanged]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher)
    VALUES (8701, N'A1', 2025, N'INV-1', N'V1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, _loaded_at, _updated_at, _is_deleted)
    VALUES (8701, N'A1', 2025, N'INV-1', N'V1', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, paymreference, ordernum,
         _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES
        (801, N'A1', N'INV-1', N'V1', NULL, '2024-10-20T00:00:00', 8, N'SUB', N'MEMSUB', 400.000000, 400.000000, 0.000000, N'GBP', NULL, NULL, N'ORD-1', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    -- The faked target rejects one incoming row, so the load fails part-way through its writes. The constraint
    -- goes when tSQLt drops the fake; it does not depend on any column width.
    ALTER TABLE Layercake.brnz_subs_invoice_line
        ADD CONSTRAINT ck_test_TC_002_018_reject CHECK (ordernum IS NULL OR ordernum <> N'REJECT-802');

    SELECT * INTO #Before FROM Layercake.brnz_subs_invoice_line;

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, PAYMMODE, PAYMREFERENCE, ORDERNUM)
    VALUES
        (801, N'A1', N'INV-1', N'V1', NULL, '2024-10-20T00:00:00', 8, 'SUB', N'MEMSUB', 450.000000, 450.000000, 0.000000, N'GBP', NULL, NULL, N'ORD-1'),
        (802, N'A1', N'INV-1', N'V1', NULL, '2024-10-20T00:00:00', 8, 'TAX', N'VAT',     90.000000,  90.000000, 0.000000, N'GBP', NULL, NULL, N'REJECT-802');

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_subs_invoice_line;
        EXEC tSQLt.Fail 'usp_load_brnz_subs_invoice_line did not raise an error for a row the target rejects';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    SELECT * INTO #After FROM Layercake.brnz_subs_invoice_line;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'brnz_subs_invoice_line changed by a failed load';

    SELECT status,
           CASE WHEN error_message IS NOT NULL THEN 1 ELSE 0 END AS error_recorded
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, error_recorded
    INTO #ExpectedLog
    FROM (VALUES (CAST('Failed' AS varchar(10)), 1)) AS v(status, error_recorded);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row for the failed load';
END;
GO
