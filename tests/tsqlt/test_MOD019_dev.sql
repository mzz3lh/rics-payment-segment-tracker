EXEC tSQLt.NewTestClass 'test_MOD019_dev';
GO
CREATE PROCEDURE test_MOD019_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';
    EXEC tSQLt.FakeTable 'Subs.tblSubsInvoices';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Voucher, Invoice, Campaign_Year)
    VALUES (1, N'A1', N'V1', N'INV-1', 2025);
END;
GO
CREATE PROCEDURE test_MOD019_dev.[test restoring a soft-deleted line counts as one update and no insert]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, transdate, transtype, ricinvoicetype, productcode, amountcur, amountmst,
         settleamountcur, currencycode, postingtype, accountdisplayvalue, mainaccount, costcenter, ricscampaignyear,
         _is_deleted, _deleted_at)
    VALUES
        (7001, N'A1', N'INV-1', N'V1', '2024-10-15', 2, N'SUB', N'MRICS', 50.00, 50.00, 50.00, N'GBP', 41, N'ADV-A',
         N'400100', N'CC10', N'2026', 1, '2026-11-01T06:00:00');

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 50.00, 50.00, 50.00, N'GBP', 41, N'ADV-A',
         N'400100', N'CC10', N'2026');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT recid, _is_deleted, _deleted_at
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT CAST(7001 AS bigint) AS recid, CAST(0 AS bit) AS _is_deleted, CAST(NULL AS datetime2(3)) AS _deleted_at
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 1 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD019_dev.[test trailing space added to accountdisplayvalue matches the row and lands the new bytes in place]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, transdate, transtype, ricinvoicetype, productcode, amountcur, amountmst,
         settleamountcur, currencycode, postingtype, accountdisplayvalue, mainaccount, costcenter, ricscampaignyear,
         _is_deleted, _deleted_at)
    VALUES
        (7001, N'A1', N'INV-1', N'V1', '2024-10-15', 2, N'SUB', N'MRICS', 50.00, 50.00, 50.00, N'GBP', 41, N'ADV-A',
         N'400100', N'CC10', N'2026', 0, NULL);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 50.00, 50.00, 50.00, N'GBP', 41, N'ADV-A ',
         N'400100', N'CC10', N'2026');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT recid, CAST(accountdisplayvalue AS varbinary(1000)) AS adv_bytes, _is_deleted
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT CAST(7001 AS bigint) AS recid, CAST(N'ADV-A ' AS varbinary(1000)) AS adv_bytes, CAST(0 AS bit) AS _is_deleted
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 1 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD019_dev.[test case-only change in costcenter is landed as an update]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, transdate, transtype, ricinvoicetype, productcode, amountcur, amountmst,
         settleamountcur, currencycode, postingtype, accountdisplayvalue, mainaccount, costcenter, ricscampaignyear,
         _is_deleted, _deleted_at)
    VALUES
        (7001, N'A1', N'INV-1', N'V1', '2024-10-15', 2, N'SUB', N'MRICS', 50.00, 50.00, 50.00, N'GBP', 41, N'ADV-A',
         N'400100', N'CC10', N'2026', 0, NULL);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 50.00, 50.00, 50.00, N'GBP', 41, N'ADV-A',
         N'400100', N'cc10', N'2026');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT CAST(costcenter AS varbinary(60)) AS costcenter_bytes
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT CAST(N'cc10' AS varbinary(60)) AS costcenter_bytes
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 1 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD019_dev.[test a line that both belongs to and settles the invoice lands once]
AS
BEGIN
    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE,
         productcode, AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE)
    VALUES
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 50.00, 50.00, 50.00, N'GBP', 41, N'ADV-A'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 30.00, 30.00, 50.00, N'GBP', 41, N'ADV-B');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT recid, accountdisplayvalue, amountcur
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT CAST(v.recid AS bigint) AS recid, v.accountdisplayvalue, CAST(v.amountcur AS numeric(34,6)) AS amountcur
    INTO #Expected
    FROM (VALUES (7001, N'ADV-A', 50.00), (7001, N'ADV-B', 30.00)) AS v(recid, accountdisplayvalue, amountcur);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('Success' AS varchar(10)) AS status, 2 AS rows_inserted, 0 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD019_dev.[test identities differing only in trailing spaces fail the load and leave the target unchanged]
AS
BEGIN
    DECLARE @errno int;

    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, transdate, transtype, ricinvoicetype, productcode, amountcur, amountmst,
         settleamountcur, currencycode, postingtype, accountdisplayvalue, _is_deleted, _deleted_at)
    VALUES
        (6001, N'A1', N'INV-1', N'V1', '2024-10-15', 2, N'SUB', N'TAX', 10.00, 10.00, 10.00, N'GBP', 41, N'ADV-T', 0, NULL);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE)
    VALUES
        (6001, 6001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'TAX', 20.00, 20.00, 20.00, N'GBP', 41, N'ADV-T'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 30.00, 30.00, 50.00, N'GBP', NULL, N'ADV-A'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 20.00, 20.00, 50.00, N'GBP', NULL, N'ADV-A  ');

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_subs_invoice_line;
        EXEC tSQLt.Fail 'The load did not fail on two source rows whose identity differs only in trailing spaces.';
    END TRY
    BEGIN CATCH
        SET @errno = ERROR_NUMBER();
        -- 2627: unique key violation in the staging table.
        IF @errno <> 2627
            THROW;
    END CATCH;

    SELECT recid, postingtype, accountdisplayvalue, amountcur, _is_deleted
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line;

    SELECT CAST(6001 AS bigint) AS recid, 41 AS postingtype, N'ADV-T' AS accountdisplayvalue,
           CAST(10.00 AS numeric(34,6)) AS amountcur, CAST(0 AS bit) AS _is_deleted
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT step_name, status, CASE WHEN error_message LIKE N'%(error 2627,%' THEN 1 ELSE 0 END AS has_error
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('brnz_subs_invoice_line' AS varchar(128)) AS step_name, CAST('Failed' AS varchar(10)) AS status, 1 AS has_error
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
