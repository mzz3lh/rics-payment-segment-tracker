EXEC tSQLt.NewTestClass 'test_MOD019';
GO
CREATE PROCEDURE test_MOD019.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';
    EXEC tSQLt.FakeTable 'Subs.tblSubsInvoices';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Subs.tblSubsInvoices (Rec_ID, Account_Num, Voucher, Invoice, Campaign_Year)
    VALUES (1, N'A1', N'V1', N'INV-1', 2025),
           (2, N'A2', N'V2', N'INV-2', 2025);
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-001 split transaction lands one live row per ledger distribution and logs Success]
AS
BEGIN
    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', NULL, '2024-10-15', 2, 'SUB', N'MRICS', 300.00, 300.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', NULL, '2024-10-15', 2, 'SUB', N'MRICS', 150.00, 150.00, 500.00, N'GBP', 41, N'400100-CC20-UK-MRICS-2025', N'400100', N'CC20', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', NULL, '2024-10-15', 2, 'SUB', N'MRICS', 50.00, 50.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2026', N'400100', N'CC10', N'2026');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Line FROM Layercake.brnz_subs_invoice_line;

    SELECT recid, accountnum, voucher, transtype, productcode, postingtype, accountdisplayvalue, mainaccount, costcenter,
           ricscampaignyear, amountcur, settleamountcur, _is_deleted
    INTO #Actual
    FROM #Line;

    SELECT v.recid, v.accountnum, v.voucher, v.transtype, v.productcode, v.postingtype, v.accountdisplayvalue, v.mainaccount,
           v.costcenter, v.ricscampaignyear, CAST(v.amountcur AS numeric(34,6)) AS amountcur,
           CAST(v.settleamountcur AS numeric(34,6)) AS settleamountcur, CAST(v._is_deleted AS bit) AS _is_deleted
    INTO #Expected
    FROM (VALUES
        (CAST(7001 AS bigint), N'A1', N'V1', 2, N'MRICS', 41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025', 300.00, 500.00, 0),
        (CAST(7001 AS bigint), N'A1', N'V1', 2, N'MRICS', 41, N'400100-CC20-UK-MRICS-2025', N'400100', N'CC20', N'2025', 150.00, 500.00, 0),
        (CAST(7001 AS bigint), N'A1', N'V1', 2, N'MRICS', 41, N'400100-CC10-UK-MRICS-2026', N'400100', N'CC10', N'2026', 50.00, 500.00, 0)
    ) AS v(recid, accountnum, voucher, transtype, productcode, postingtype, accountdisplayvalue, mainaccount, costcenter,
           ricscampaignyear, amountcur, settleamountcur, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT layer, step_name, status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('bronze' AS varchar(12)) AS layer, CAST('brnz_subs_invoice_line' AS varchar(128)) AS step_name,
           CAST('Success' AS varchar(10)) AS status, 3 AS rows_inserted, 0 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-002 split transaction line amounts sum to the transaction amount and it stays one recid]
AS
BEGIN
    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 300.00, 300.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 150.00, 150.00, 500.00, N'GBP', 41, N'400100-CC20-UK-MRICS-2025', N'400100', N'CC20', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 50.00, 50.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2026', N'400100', N'CC10', N'2026');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT COUNT(*) AS live_rows,
           COUNT(DISTINCT recid) AS distinct_recids,
           SUM(amountcur) AS sum_amountcur,
           MIN(settleamountcur) AS min_settleamountcur,
           MAX(settleamountcur) AS max_settleamountcur
    INTO #Actual
    FROM Layercake.brnz_subs_invoice_line
    WHERE recid = 7001 AND _is_deleted = 0;

    SELECT 3 AS live_rows, 1 AS distinct_recids, CAST(500.00 AS numeric(38,6)) AS sum_amountcur,
           CAST(500.00 AS numeric(34,6)) AS min_settleamountcur, CAST(500.00 AS numeric(34,6)) AS max_settleamountcur
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-003 rerun on unchanged split lines logs 0 inserted 0 updated 0 deleted and changes nothing]
AS
BEGIN
    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 300.00, 300.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 150.00, 150.00, 500.00, N'GBP', 41, N'400100-CC20-UK-MRICS-2025', N'400100', N'CC20', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 50.00, 50.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2026', N'400100', N'CC10', N'2026');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Before FROM Layercake.brnz_subs_invoice_line;

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #After FROM Layercake.brnz_subs_invoice_line;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    DECLARE @live int = (SELECT COUNT(*) FROM Layercake.brnz_subs_invoice_line WHERE recid = 7001 AND _is_deleted = 0);
    EXEC tSQLt.AssertEquals 3, @live;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log
    WHERE log_id = (SELECT MAX(log_id) FROM Layercake.etl_run_log WHERE step_name = 'brnz_subs_invoice_line');

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 0 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-004 changed amount on one line of a split transaction updates that line only]
AS
BEGIN
    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 300.00, 300.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 150.00, 150.00, 500.00, N'GBP', 41, N'400100-CC20-UK-MRICS-2025', N'400100', N'CC20', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 50.00, 50.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2026', N'400100', N'CC10', N'2026');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Line1 FROM Layercake.brnz_subs_invoice_line;
    SELECT * INTO #BeforeOthers FROM #Line1 WHERE accountdisplayvalue <> N'400100-CC20-UK-MRICS-2025';
    SELECT line_id, _loaded_at INTO #BeforeChanged FROM #Line1 WHERE accountdisplayvalue = N'400100-CC20-UK-MRICS-2025';

    UPDATE synapse_fo.CUSTTRANS_RICS
    SET AMOUNTCUR = 160.00
    WHERE RECID = 7001 AND ACCOUNTDISPLAYVALUE = N'400100-CC20-UK-MRICS-2025';

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log
    WHERE log_id = (SELECT MAX(log_id) FROM Layercake.etl_run_log WHERE step_name = 'brnz_subs_invoice_line');

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 1 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT * INTO #Line2 FROM Layercake.brnz_subs_invoice_line;

    SELECT accountdisplayvalue, amountcur, _is_deleted
    INTO #Actual
    FROM #Line2
    WHERE recid = 7001;

    SELECT v.accountdisplayvalue, CAST(v.amountcur AS numeric(34,6)) AS amountcur, CAST(v._is_deleted AS bit) AS _is_deleted
    INTO #Expected
    FROM (VALUES
        (N'400100-CC10-UK-MRICS-2025', 300.00, 0),
        (N'400100-CC20-UK-MRICS-2025', 160.00, 0),
        (N'400100-CC10-UK-MRICS-2026', 50.00, 0)
    ) AS v(accountdisplayvalue, amountcur, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT * INTO #AfterOthers FROM #Line2 WHERE accountdisplayvalue <> N'400100-CC20-UK-MRICS-2025';
    EXEC tSQLt.AssertEqualsTable '#BeforeOthers', '#AfterOthers';

    SELECT line_id, _loaded_at INTO #AfterChanged FROM #Line2 WHERE accountdisplayvalue = N'400100-CC20-UK-MRICS-2025';
    EXEC tSQLt.AssertEqualsTable '#BeforeChanged', '#AfterChanged';
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-005 GEN line with all five ledger columns null lands as one live row with them null]
AS
BEGIN
    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7101, 7101, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'GEN', N'ADMIN', 20.00, 20.00, 20.00, N'GBP', NULL, NULL, NULL, NULL, NULL);

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Line FROM Layercake.brnz_subs_invoice_line;

    SELECT recid, ricinvoicetype, amountcur, postingtype, accountdisplayvalue, mainaccount, costcenter, ricscampaignyear, _is_deleted
    INTO #Actual
    FROM #Line;

    SELECT CAST(7101 AS bigint) AS recid, N'GEN' AS ricinvoicetype, CAST(20.00 AS numeric(34,6)) AS amountcur,
           CAST(NULL AS int) AS postingtype, CAST(NULL AS nvarchar(500)) AS accountdisplayvalue,
           CAST(NULL AS nvarchar(20)) AS mainaccount, CAST(NULL AS nvarchar(30)) AS costcenter,
           CAST(NULL AS nvarchar(10)) AS ricscampaignyear, CAST(0 AS bit) AS _is_deleted
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-006 rerun matches null postingtype and null accountdisplayvalue to their rows and changes nothing]
AS
BEGIN
    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7201, 7201, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'GEN', N'ADMIN', 10.00, 10.00, 10.00, N'GBP', NULL, NULL, NULL, NULL, NULL),
        (7202, 7202, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 11.00, 11.00, 23.00, N'GBP', NULL, N'ADV-1', NULL, NULL, NULL),
        (7202, 7202, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 12.00, 12.00, 23.00, N'GBP', 41, N'ADV-1', NULL, NULL, NULL),
        (7203, 7203, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 13.00, 13.00, 13.00, N'GBP', 41, NULL, NULL, NULL, NULL);

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Before FROM Layercake.brnz_subs_invoice_line;

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #After FROM Layercake.brnz_subs_invoice_line;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT recid, postingtype, accountdisplayvalue, amountcur, _is_deleted
    INTO #Actual
    FROM #After;

    SELECT CAST(v.recid AS bigint) AS recid, v.postingtype, v.accountdisplayvalue, CAST(v.amountcur AS numeric(34,6)) AS amountcur,
           CAST(v._is_deleted AS bit) AS _is_deleted
    INTO #Expected
    FROM (VALUES
        (7201, CAST(NULL AS int), CAST(NULL AS nvarchar(500)), 10.00, 0),
        (7202, CAST(NULL AS int), N'ADV-1', 11.00, 0),
        (7202, 41, N'ADV-1', 12.00, 0),
        (7203, 41, CAST(NULL AS nvarchar(500)), 13.00, 0)
    ) AS v(recid, postingtype, accountdisplayvalue, amountcur, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log
    WHERE log_id = (SELECT MAX(log_id) FROM Layercake.etl_run_log WHERE step_name = 'brnz_subs_invoice_line');

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 0 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-007 live rows equal the in-scope source rows with no duplicate identity and more rows than recids]
AS
BEGIN
    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, PAYMMODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        -- in scope: invoice V1 split into 3 distributions
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', NULL, '2024-10-15', 2, 'SUB', N'MRICS', 300.00, 300.00, 500.00, N'GBP', NULL, 41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', NULL, '2024-10-15', 2, 'SUB', N'MRICS', 150.00, 150.00, 500.00, N'GBP', NULL, 41, N'400100-CC20-UK-MRICS-2025', N'400100', N'CC20', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', NULL, '2024-10-15', 2, 'SUB', N'MRICS', 50.00, 50.00, 500.00, N'GBP', NULL, 41, N'400100-CC10-UK-MRICS-2026', N'400100', N'CC10', N'2026'),
        -- in scope: GEN line of V1 with null ledger columns
        (7101, 7101, N'rics', N'A1', N'INV-1', N'V1', NULL, '2024-10-15', 2, 'GEN', N'ADMIN', 20.00, 20.00, 20.00, N'GBP', NULL, NULL, NULL, NULL, NULL, NULL),
        -- in scope: payment on A1 settling V1, split over 2 Campaign Years
        (9001, 9001, N'rics', N'A1', NULL, N'PV1', N'V1', '2024-11-01', 8, 'SUB', NULL, -300.00, -300.00, -520.00, N'GBP', N'Card', 14, N'120000-CC10-UK--2025', N'120000', N'CC10', N'2025'),
        (9001, 9001, N'rics', N'A1', NULL, N'PV1', N'V1', '2024-11-01', 8, 'SUB', NULL, -220.00, -220.00, -520.00, N'GBP', N'Card', 14, N'120000-CC10-UK--2026', N'120000', N'CC10', N'2026'),
        -- in scope: invoice V2 on account A2
        (7301, 7301, N'rics', N'A2', N'INV-2', N'V2', NULL, '2024-10-20', 2, 'SUB', N'FRICS', 600.00, 600.00, 600.00, N'GBP', NULL, 41, N'400100-CC10-UK-FRICS-2025', N'400100', N'CC10', N'2025'),
        -- out of scope: voucher V9 is not an invoice
        (8001, 8001, N'rics', N'A1', N'INV-9', N'V9', NULL, '2024-10-15', 2, 'SUB', N'MRICS', 70.00, 70.00, 100.00, N'GBP', NULL, 41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025'),
        (8001, 8001, N'rics', N'A1', N'INV-9', N'V9', NULL, '2024-10-15', 2, 'SUB', N'MRICS', 30.00, 30.00, 100.00, N'GBP', NULL, 41, N'400100-CC20-UK-MRICS-2025', N'400100', N'CC20', N'2025'),
        -- out of scope: settles V1 but posted on another account
        (8101, 8101, N'rics', N'A3', NULL, N'PV3', N'V1', '2024-11-02', 8, 'SUB', NULL, -50.00, -50.00, -50.00, N'GBP', N'Card', 14, N'120000-CC10-UK--2025', N'120000', N'CC10', N'2025');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Line FROM Layercake.brnz_subs_invoice_line;

    SELECT recid, postingtype, accountdisplayvalue
    INTO #Actual
    FROM #Line
    WHERE _is_deleted = 0;

    SELECT CAST(v.recid AS bigint) AS recid, v.postingtype, v.accountdisplayvalue
    INTO #Expected
    FROM (VALUES
        (7001, 41, N'400100-CC10-UK-MRICS-2025'),
        (7001, 41, N'400100-CC20-UK-MRICS-2025'),
        (7001, 41, N'400100-CC10-UK-MRICS-2026'),
        (7101, CAST(NULL AS int), CAST(NULL AS nvarchar(500))),
        (9001, 14, N'120000-CC10-UK--2025'),
        (9001, 14, N'120000-CC10-UK--2026'),
        (7301, 41, N'400100-CC10-UK-FRICS-2025')
    ) AS v(recid, postingtype, accountdisplayvalue);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT recid, postingtype, accountdisplayvalue, COUNT(*) AS n
    INTO #Duplicates
    FROM #Line
    WHERE _is_deleted = 0
    GROUP BY recid, postingtype, accountdisplayvalue
    HAVING COUNT(*) > 1;

    EXEC tSQLt.AssertEmptyTable '#Duplicates';

    SELECT COUNT(*) AS live_rows, COUNT(DISTINCT recid) AS distinct_recids
    INTO #ActualCounts
    FROM #Line
    WHERE _is_deleted = 0;

    SELECT 7 AS live_rows, 4 AS distinct_recids
    INTO #ExpectedCounts;

    EXEC tSQLt.AssertEqualsTable '#ExpectedCounts', '#ActualCounts';
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-008 500 character accountdisplayvalue lands at full width and the last character tells two rows apart]
AS
BEGIN
    DECLARE @adv1 nvarchar(500) = REPLICATE(CAST(N'A' AS nvarchar(500)), 499) + N'1';
    DECLARE @adv2 nvarchar(500) = REPLICATE(CAST(N'A' AS nvarchar(500)), 499) + N'2';

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE)
    VALUES
        (7401, 7401, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 60.00, 60.00, 100.00, N'GBP', 41, @adv1),
        (7401, 7401, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 40.00, 40.00, 100.00, N'GBP', 41, @adv2);

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Line FROM Layercake.brnz_subs_invoice_line;

    SELECT CAST(accountdisplayvalue AS varbinary(1000)) AS adv_bytes, DATALENGTH(accountdisplayvalue) AS adv_bytes_len, amountcur, _is_deleted
    INTO #Actual
    FROM #Line
    WHERE recid = 7401;

    SELECT v.adv_bytes, v.adv_bytes_len, CAST(v.amountcur AS numeric(34,6)) AS amountcur, CAST(v._is_deleted AS bit) AS _is_deleted
    INTO #Expected
    FROM (VALUES
        (CAST(@adv1 AS varbinary(1000)), 1000, 60.00, 0),
        (CAST(@adv2 AS varbinary(1000)), 1000, 40.00, 0)
    ) AS v(adv_bytes, adv_bytes_len, amountcur, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD019.[test TC-019-009 duplicate source identity fails the load logs Failed and leaves the target unchanged]
AS
BEGIN
    DECLARE @raised bit = 0, @errno int, @errmsg nvarchar(4000);

    EXEC (N'INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, transdate, transtype, ricinvoicetype, productcode, amountcur, amountmst, settleamountcur,
         currencycode, postingtype, accountdisplayvalue, mainaccount, costcenter, ricscampaignyear, _is_deleted, _deleted_at)
    VALUES
        (6001, N''A1'', N''INV-1'', N''V1'', ''2024-10-15'', 2, N''SUB'', N''TAX'', 10.00, 10.00, 10.00, N''GBP'', 41,
         N''220000-CC10-UK-TAX'', N''220000'', N''CC10'', NULL, 0, NULL);');

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (6001, 6001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'TAX', 20.00, 20.00, 20.00, N'GBP', 41, N'220000-CC10-UK-TAX', N'220000', N'CC10', NULL),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 300.00, 300.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 200.00, 200.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025');

    SELECT * INTO #Before FROM Layercake.brnz_subs_invoice_line;

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_subs_invoice_line;
    END TRY
    BEGIN CATCH
        SELECT @raised = 1, @errno = ERROR_NUMBER(), @errmsg = ERROR_MESSAGE();
    END CATCH;

    IF @raised = 0
        EXEC tSQLt.Fail 'The load did not raise an error for two source rows with the same (recid, postingtype, accountdisplayvalue).';
    IF @errno IN (201, 207, 208, 2812)
        EXEC tSQLt.Fail 'The load raised an unexpected error: ', @errmsg;

    SELECT * INTO #After FROM Layercake.brnz_subs_invoice_line;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT status, CASE WHEN error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log
    WHERE step_name = 'brnz_subs_invoice_line';

    SELECT CAST('Failed' AS varchar(10)) AS status, 1 AS has_error_message
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD019.[test TC-019-010 two source rows of one recid with null postingtype and null accountdisplayvalue fail the load]
AS
BEGIN
    DECLARE @raised bit = 0, @errno int, @errmsg nvarchar(4000);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7201, 7201, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'GEN', N'ADMIN', 10.00, 10.00, 25.00, N'GBP', NULL, NULL, N'410000', NULL, NULL),
        (7201, 7201, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'GEN', N'ADMIN', 15.00, 15.00, 25.00, N'GBP', NULL, NULL, N'420000', NULL, NULL);

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_subs_invoice_line;
    END TRY
    BEGIN CATCH
        SELECT @raised = 1, @errno = ERROR_NUMBER(), @errmsg = ERROR_MESSAGE();
    END CATCH;

    IF @raised = 0
        EXEC tSQLt.Fail 'The load did not raise an error for two source rows of recid 7201 with null postingtype and null accountdisplayvalue.';
    IF @errno IN (201, 207, 208, 2812)
        EXEC tSQLt.Fail 'The load raised an unexpected error: ', @errmsg;

    SELECT recid INTO #Actual FROM Layercake.brnz_subs_invoice_line;
    EXEC tSQLt.AssertEmptyTable '#Actual';

    SELECT status, CASE WHEN error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log
    WHERE step_name = 'brnz_subs_invoice_line';

    SELECT CAST('Failed' AS varchar(10)) AS status, 1 AS has_error_message
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD019.[test TC-019-011 two source rows whose accountdisplayvalue differs only in case are one identity and fail the load]
AS
BEGIN
    DECLARE @raised bit = 0, @errno int, @errmsg nvarchar(4000);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 300.00, 300.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 200.00, 200.00, 500.00, N'GBP', 41, N'400100-cc10-uk-mrics-2025', N'400100', N'cc10', N'2025');

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_subs_invoice_line;
    END TRY
    BEGIN CATCH
        SELECT @raised = 1, @errno = ERROR_NUMBER(), @errmsg = ERROR_MESSAGE();
    END CATCH;

    IF @raised = 0
        EXEC tSQLt.Fail 'The load did not raise an error for two rows whose accountdisplayvalue differs only in case.';
    IF @errno IN (201, 207, 208, 2812)
        EXEC tSQLt.Fail 'The load raised an unexpected error: ', @errmsg;

    SELECT recid INTO #Actual FROM Layercake.brnz_subs_invoice_line;
    EXEC tSQLt.AssertEmptyTable '#Actual';

    SELECT status, CASE WHEN error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log
    WHERE step_name = 'brnz_subs_invoice_line';

    SELECT CAST('Failed' AS varchar(10)) AS status, 1 AS has_error_message
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-012 case-only change in accountdisplayvalue matches the existing row and lands the new bytes in place]
AS
BEGIN
    EXEC (N'INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode, amountcur, amountmst,
         settleamountcur, currencycode, paymmode, paymreference, ordernum, postingtype, accountdisplayvalue, mainaccount, costcenter,
         ricscampaignyear, _is_deleted, _deleted_at)
    VALUES
        (7001, N''A1'', N''INV-1'', N''V1'', NULL, ''2024-10-15'', 2, N''SUB'', N''MRICS'', 300.00, 300.00, 500.00, N''GBP'', NULL, NULL, NULL,
         41, N''400100-CC10-UK-MRICS-2025'', N''400100'', N''CC10'', N''2025'', 0, NULL);');

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, PAYMMODE, PAYMREFERENCE, ORDERNUM, POSTINGTYPE, ACCOUNTDISPLAYVALUE,
         MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', NULL, '2024-10-15', 2, 'SUB', N'MRICS', 300.00, 300.00, 500.00, N'GBP', NULL, NULL, NULL,
         41, N'400100-cc10-UK-MRICS-2025', N'400100', N'CC10', N'2025');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Line FROM Layercake.brnz_subs_invoice_line;

    SELECT recid, CAST(accountdisplayvalue AS varbinary(1000)) AS adv_bytes, _is_deleted
    INTO #Actual
    FROM #Line;

    SELECT CAST(7001 AS bigint) AS recid, CAST(N'400100-cc10-UK-MRICS-2025' AS varbinary(1000)) AS adv_bytes, CAST(0 AS bit) AS _is_deleted
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log
    WHERE step_name = 'brnz_subs_invoice_line';

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 1 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-013 first run after the change soft-deletes the old recid-grain row and inserts the split rows]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, transdate, transtype, ricinvoicetype, productcode, amountcur, amountmst, settleamountcur,
         currencycode, _is_deleted, _deleted_at)
    VALUES
        (7001, N'A1', N'INV-1', N'V1', '2024-10-15', 2, N'SUB', N'MRICS', 500.00, 500.00, 500.00, N'GBP', 0, NULL);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 300.00, 300.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 150.00, 150.00, 500.00, N'GBP', 41, N'400100-CC20-UK-MRICS-2025', N'400100', N'CC20', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 50.00, 50.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2026', N'400100', N'CC10', N'2026');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Line FROM Layercake.brnz_subs_invoice_line;

    SELECT postingtype, accountdisplayvalue, amountcur, _is_deleted,
           CASE WHEN _deleted_at IS NULL THEN 0 ELSE 1 END AS has_deleted_at
    INTO #Actual
    FROM #Line
    WHERE recid = 7001;

    SELECT v.postingtype, v.accountdisplayvalue, CAST(v.amountcur AS numeric(34,6)) AS amountcur, CAST(v._is_deleted AS bit) AS _is_deleted,
           v.has_deleted_at
    INTO #Expected
    FROM (VALUES
        (CAST(NULL AS int), CAST(NULL AS nvarchar(500)), 500.00, 1, 1),
        (41, N'400100-CC10-UK-MRICS-2025', 300.00, 0, 0),
        (41, N'400100-CC20-UK-MRICS-2025', 150.00, 0, 0),
        (41, N'400100-CC10-UK-MRICS-2026', 50.00, 0, 0)
    ) AS v(postingtype, accountdisplayvalue, amountcur, _is_deleted, has_deleted_at);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log
    WHERE step_name = 'brnz_subs_invoice_line';

    SELECT CAST('Success' AS varchar(10)) AS status, 3 AS rows_inserted, 0 AS rows_updated, 1 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-014 first run after the change updates an old row whose source row has null postingtype and accountdisplayvalue]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, transdate, transtype, ricinvoicetype, productcode, amountcur, amountmst, settleamountcur,
         currencycode, _is_deleted, _deleted_at)
    VALUES
        (7101, N'A1', N'INV-1', N'V1', '2024-10-15', 2, N'GEN', N'ADMIN', 20.00, 20.00, 20.00, N'GBP', 0, NULL);

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7101, 7101, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'GEN', N'ADMIN', 20.00, 20.00, 20.00, N'GBP', NULL, NULL, N'410000', N'CC10', NULL);

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Line FROM Layercake.brnz_subs_invoice_line;

    SELECT recid, postingtype, accountdisplayvalue, mainaccount, costcenter, ricscampaignyear, amountcur, _is_deleted
    INTO #Actual
    FROM #Line;

    SELECT CAST(7101 AS bigint) AS recid, CAST(NULL AS int) AS postingtype, CAST(NULL AS nvarchar(500)) AS accountdisplayvalue,
           N'410000' AS mainaccount, N'CC10' AS costcenter, CAST(NULL AS nvarchar(10)) AS ricscampaignyear,
           CAST(20.00 AS numeric(34,6)) AS amountcur, CAST(0 AS bit) AS _is_deleted
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log
    WHERE step_name = 'brnz_subs_invoice_line';

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 1 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-015 one line gone from a split transaction is soft-deleted and the other lines are untouched]
AS
BEGIN
    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 300.00, 300.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 150.00, 150.00, 500.00, N'GBP', 41, N'400100-CC20-UK-MRICS-2025', N'400100', N'CC20', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 50.00, 50.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2026', N'400100', N'CC10', N'2026');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Line1 FROM Layercake.brnz_subs_invoice_line;
    SELECT * INTO #BeforeOthers FROM #Line1 WHERE accountdisplayvalue <> N'400100-CC10-UK-MRICS-2026';

    DELETE FROM synapse_fo.CUSTTRANS_RICS
    WHERE RECID = 7001 AND ACCOUNTDISPLAYVALUE = N'400100-CC10-UK-MRICS-2026';

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Line2 FROM Layercake.brnz_subs_invoice_line;

    SELECT accountdisplayvalue, _is_deleted, CASE WHEN _deleted_at IS NULL THEN 0 ELSE 1 END AS has_deleted_at
    INTO #Actual
    FROM #Line2
    WHERE recid = 7001;

    SELECT v.accountdisplayvalue, CAST(v._is_deleted AS bit) AS _is_deleted, v.has_deleted_at
    INTO #Expected
    FROM (VALUES
        (N'400100-CC10-UK-MRICS-2025', 0, 0),
        (N'400100-CC20-UK-MRICS-2025', 0, 0),
        (N'400100-CC10-UK-MRICS-2026', 1, 1)
    ) AS v(accountdisplayvalue, _is_deleted, has_deleted_at);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT * INTO #AfterOthers FROM #Line2 WHERE accountdisplayvalue <> N'400100-CC10-UK-MRICS-2026';
    EXEC tSQLt.AssertEqualsTable '#BeforeOthers', '#AfterOthers';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log
    WHERE log_id = (SELECT MAX(log_id) FROM Layercake.etl_run_log WHERE step_name = 'brnz_subs_invoice_line');

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 0 AS rows_updated, 1 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-016 a soft-deleted line that reappears is restored in place on its identity]
AS
BEGIN
    EXEC (N'INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode, amountcur, amountmst,
         settleamountcur, currencycode, paymmode, paymreference, ordernum, postingtype, accountdisplayvalue, mainaccount, costcenter,
         ricscampaignyear, _is_deleted, _deleted_at)
    VALUES
        (7001, N''A1'', N''INV-1'', N''V1'', NULL, ''2024-10-15'', 2, N''SUB'', N''MRICS'', 300.00, 300.00, 500.00, N''GBP'', NULL, NULL, NULL,
         41, N''400100-CC10-UK-MRICS-2025'', N''400100'', N''CC10'', N''2025'', 0, NULL),
        (7001, N''A1'', N''INV-1'', N''V1'', NULL, ''2024-10-15'', 2, N''SUB'', N''MRICS'', 50.00, 50.00, 500.00, N''GBP'', NULL, NULL, NULL,
         41, N''400100-CC10-UK-MRICS-2026'', N''400100'', N''CC10'', N''2026'', 1, ''2026-11-01T06:00:00'');');

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, DATAAREAID, ACCOUNTNUM, INVOICE, VOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 300.00, 300.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025'),
        (7001, 7001, N'rics', N'A1', N'INV-1', N'V1', '2024-10-15', 2, 'SUB', N'MRICS', 50.00, 50.00, 500.00, N'GBP', 41, N'400100-CC10-UK-MRICS-2026', N'400100', N'CC10', N'2026');

    EXEC Layercake.usp_load_brnz_subs_invoice_line;

    SELECT * INTO #Line FROM Layercake.brnz_subs_invoice_line;

    SELECT accountdisplayvalue, amountcur, _is_deleted, CASE WHEN _deleted_at IS NULL THEN 0 ELSE 1 END AS has_deleted_at
    INTO #Actual
    FROM #Line
    WHERE recid = 7001;

    SELECT v.accountdisplayvalue, CAST(v.amountcur AS numeric(34,6)) AS amountcur, CAST(v._is_deleted AS bit) AS _is_deleted, v.has_deleted_at
    INTO #Expected
    FROM (VALUES
        (N'400100-CC10-UK-MRICS-2025', 300.00, 0, 0),
        (N'400100-CC10-UK-MRICS-2026', 50.00, 0, 0)
    ) AS v(accountdisplayvalue, amountcur, _is_deleted, has_deleted_at);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @inserted int = (SELECT rows_inserted FROM Layercake.etl_run_log WHERE step_name = 'brnz_subs_invoice_line');
    EXEC tSQLt.AssertEquals 0, @inserted;
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-017 table has line_id and the five ledger columns at source width and nullability]
AS
BEGIN
    DECLARE @oid int;

    SELECT TOP (1) @oid = l.ObjectId
    FROM tSQLt.Private_RenamedObjectLog AS l
    WHERE OBJECT_SCHEMA_NAME(l.ObjectId) = N'Layercake'
      AND REPLACE(REPLACE(l.OriginalName, N'[', N''), N']', N'') = N'brnz_subs_invoice_line';

    IF @oid IS NULL SET @oid = OBJECT_ID(N'Layercake.brnz_subs_invoice_line');

    SELECT c.name AS column_name, TYPE_NAME(c.user_type_id) AS type_name, CAST(c.max_length AS int) AS max_length,
           CAST(c.is_nullable AS int) AS is_nullable, CAST(c.is_identity AS int) AS is_identity
    INTO #Actual
    FROM sys.columns AS c
    WHERE c.object_id = @oid
      AND c.name IN (N'line_id', N'recid', N'postingtype', N'accountdisplayvalue', N'mainaccount', N'costcenter', N'ricscampaignyear');

    SELECT v.column_name, v.type_name, v.max_length, v.is_nullable, v.is_identity
    INTO #Expected
    FROM (VALUES
        (N'line_id', N'bigint', 8, 0, 1),
        (N'recid', N'bigint', 8, 0, 0),
        (N'postingtype', N'int', 4, 1, 0),
        (N'accountdisplayvalue', N'nvarchar', 1000, 1, 0),
        (N'mainaccount', N'nvarchar', 40, 1, 0),
        (N'costcenter', N'nvarchar', 60, 1, 0),
        (N'ricscampaignyear', N'nvarchar', 20, 1, 0)
    ) AS v(column_name, type_name, max_length, is_nullable, is_identity);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD019.[test TC-019-018 primary key is line_id and the only other unique key is unfiltered on recid postingtype and accountdisplayvalue]
AS
BEGIN
    DECLARE @oid int;

    SELECT TOP (1) @oid = l.ObjectId
    FROM tSQLt.Private_RenamedObjectLog AS l
    WHERE OBJECT_SCHEMA_NAME(l.ObjectId) = N'Layercake'
      AND REPLACE(REPLACE(l.OriginalName, N'[', N''), N']', N'') = N'brnz_subs_invoice_line';

    IF @oid IS NULL SET @oid = OBJECT_ID(N'Layercake.brnz_subs_invoice_line');

    SELECT CASE WHEN i.is_primary_key = 1 THEN 'pk' ELSE 'unique' END AS key_kind,
           CAST(STRING_AGG(CAST(c.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY c.name) AS nvarchar(400)) AS key_columns
    INTO #Actual
    FROM sys.indexes AS i
    INNER JOIN sys.index_columns AS ic
        ON ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
    INNER JOIN sys.columns AS c
        ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = @oid
      AND i.is_unique = 1
      AND i.has_filter = 0
    GROUP BY i.index_id, i.is_primary_key;

    SELECT v.key_kind, CAST(v.key_columns AS nvarchar(400)) AS key_columns
    INTO #Expected
    FROM (VALUES
        ('pk', N'line_id'),
        ('unique', N'accountdisplayvalue,postingtype,recid')
    ) AS v(key_kind, key_columns);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
