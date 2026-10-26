EXEC tSQLt.NewTestClass 'test_MOD002_dev';
GO

CREATE PROCEDURE test_MOD002_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.tblSubsInvoices';
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
END;
GO

/* usp_load_brnz_subs_invoice */

CREATE PROCEDURE test_MOD002_dev.[test invoice case-only and trailing-space changes are landed and counted as updates]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, inv_payment_method, payment_status,
         _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (9001, N'A9001', 2025, N'INV-9001', N'V9001', N'dd', N'Paid', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL),
           (9002, N'A9002', 2025, N'INV-9002', N'V9002', N'DD', N'Paid', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL),
           (9003, N'A9003', 2025, N'INV-9003', N'V9003', N'DD', N'Paid', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Inv_Payment_Method, Payment_Status)
    VALUES (9001, N'A9001', 2025, N'INV-9001', N'V9001', N'DD',  N'Paid'),
           (9002, N'A9002', 2025, N'INV-9002', N'V9002', N'DD ', N'Paid'),
           (9003, N'A9003', 2025, N'INV-9003', N'V9003', N'DD',  N'Paid');

    EXEC Layercake.usp_load_brnz_subs_invoice;

    SELECT rec_id,
           CAST(inv_payment_method AS varbinary(40)) AS payment_method_bytes,
           CASE WHEN _updated_at > '2020-01-01T00:00:00' THEN 1 ELSE 0 END AS updated_at_refreshed
    INTO #Actual
    FROM Layercake.brnz_subs_invoice;

    SELECT rec_id, payment_method_bytes, updated_at_refreshed
    INTO #Expected
    FROM (VALUES (CAST(9001 AS bigint), CAST(N'DD' AS varbinary(40)), 1),
                 (CAST(9002 AS bigint), CAST(N'DD ' AS varbinary(40)), 1),
                 (CAST(9003 AS bigint), CAST(N'DD' AS varbinary(40)), 0)) AS v(rec_id, payment_method_bytes, updated_at_refreshed);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'brnz_subs_invoice after the load';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 2, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO

CREATE PROCEDURE test_MOD002_dev.[test invoice restored row clears _deleted_at keeps _loaded_at and counts as one update]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, payment_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (9101, N'A9101', 2025, N'INV-9101', N'V9101', N'Paid', '2020-01-01T00:00:00', '2020-06-01T00:00:00', 1, '2020-06-01T00:00:00');

    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Payment_Status)
    VALUES (9101, N'A9101', 2025, N'INV-9101', N'V9101', N'Paid');

    EXEC Layercake.usp_load_brnz_subs_invoice;

    SELECT rec_id, _loaded_at, _is_deleted,
           CASE WHEN _deleted_at IS NULL THEN 1 ELSE 0 END AS deleted_at_cleared,
           CASE WHEN _updated_at > '2020-06-01T00:00:00' THEN 1 ELSE 0 END AS updated_at_refreshed
    INTO #Actual
    FROM Layercake.brnz_subs_invoice;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected (rec_id, _loaded_at, _is_deleted, deleted_at_cleared, updated_at_refreshed)
    VALUES (9101, '2020-01-01T00:00:00', 0, 1, 1);

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

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD002_dev.[test invoice load fails on a Fully_Credited value longer than the target instead of truncating it]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, fully_credited, payment_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (9201, N'A9201', 2025, N'INV-9201', N'V9201', N'N', N'Unpaid', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    SELECT * INTO #Before FROM Layercake.brnz_subs_invoice;

    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Fully_Credited, Payment_Status)
    VALUES (9201, N'A9201', 2025, N'INV-9201', N'V9201', 'N',   N'Paid'),
           (9202, N'A9202', 2025, N'INV-9202', N'V9202', 'N/A', N'Paid');

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_subs_invoice;
        EXEC tSQLt.Fail 'usp_load_brnz_subs_invoice did not raise an error for Fully_Credited ''N/A'' into nvarchar(1)';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2628, 8152) THROW;
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

/* usp_load_brnz_subs_invoice_line */

CREATE PROCEDURE test_MOD002_dev.[test line settling the invoice voucher from another account is not landed]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher)
    VALUES (9301, N'A1', 2025, N'INV-1', N'V1');

    INSERT INTO synapse_fo.CUSTTRANS_RICS (RECID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, RICINVOICETYPE, AMOUNTCUR)
    VALUES (931, N'A1', NULL, N'PAY1', N'V1', 'PAY', -450.000000),
           (932, N'A2', NULL, N'PAY2', N'V1', 'PAY', -450.000000);

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT recid, accountnum
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected (recid, accountnum)
    VALUES (931, N'A1');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD002_dev.[test line matching two invoices lands once and logs one insert]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher)
    VALUES (9401, N'A1', 2025, N'INV-1', N'V1'),
           (9402, N'A1', 2026, N'INV-2', N'V2');

    INSERT INTO synapse_fo.CUSTTRANS_RICS (RECID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, RICINVOICETYPE, AMOUNTCUR)
    VALUES (941, N'A1', N'INV-1', N'V1', N'V2', 'SUB', 450.000000);

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT recid, _is_deleted
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected (recid, _is_deleted)
    VALUES (941, 0);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'brnz_subs_invoice_line after the load';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 1, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO

CREATE PROCEDURE test_MOD002_dev.[test line transdate with milliseconds rounds to the second and a rerun updates nothing]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher)
    VALUES (9501, N'A1', 2025, N'INV-1', N'V1');

    INSERT INTO synapse_fo.CUSTTRANS_RICS (RECID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, RICINVOICETYPE, AMOUNTCUR)
    VALUES (951, N'A1', N'INV-1', N'V1', '2024-10-20T10:00:00.500', 'SUB', 450.000000);

    EXEC Layercake.usp_load_brnz_subs_invoice_line;
    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT recid, transdate
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT TOP (0) * INTO #Expected FROM #Actual;
    INSERT INTO #Expected (recid, transdate)
    VALUES (951, '2024-10-20T10:00:01');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'brnz_subs_invoice_line after two loads';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 1, 0, 0),
                 (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log rows';
END;
GO

CREATE PROCEDURE test_MOD002_dev.[test line case-only paymmode change is landed as an update]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher)
    VALUES (9601, N'A1', 2025, N'INV-1', N'V1');

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, ricinvoicetype, amountcur, paymmode,
         _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (961, N'A1', NULL, N'PAY1', N'V1', N'PAY', -450.000000, N'dd', '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    INSERT INTO synapse_fo.CUSTTRANS_RICS (RECID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, RICINVOICETYPE, AMOUNTCUR, PAYMMODE)
    VALUES (961, N'A1', NULL, N'PAY1', N'V1', 'PAY', -450.000000, N'DD');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT recid, CAST(paymmode AS varbinary(40)) AS paymmode_bytes,
           CASE WHEN _updated_at > '2020-01-01T00:00:00' THEN 1 ELSE 0 END AS updated_at_refreshed
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT recid, paymmode_bytes, updated_at_refreshed
    INTO #Expected
    FROM (VALUES (CAST(961 AS bigint), CAST(N'DD' AS varbinary(40)), 1)) AS v(recid, paymmode_bytes, updated_at_refreshed);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'brnz_subs_invoice_line after the load';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD002_dev.[test line load fails on a duplicate RECID in the source and leaves the target unchanged]
AS
BEGIN
    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher)
    VALUES (9701, N'A1', 2025, N'INV-1', N'V1');

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, ricinvoicetype, amountcur, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (971, N'A1', N'INV-1', N'V1', N'SUB', 400.000000, '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    SELECT * INTO #Before FROM Layercake.brnz_subs_invoice_line;

    INSERT INTO synapse_fo.CUSTTRANS_RICS (RECID, ACCOUNTNUM, INVOICE, VOUCHER, RICINVOICETYPE, AMOUNTCUR)
    VALUES (971, N'A1', N'INV-1', N'V1', 'SUB', 450.000000),
           (972, N'A1', N'INV-1', N'V1', 'TAX',  90.000000),
           (972, N'A1', N'INV-1', N'V1', 'TAX',  91.000000);

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_subs_invoice_line;
        EXEC tSQLt.Fail 'usp_load_brnz_subs_invoice_line did not raise an error for a duplicate RECID';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 2627 THROW;
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
