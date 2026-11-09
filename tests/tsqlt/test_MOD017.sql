EXEC tSQLt.NewTestClass 'test_MOD017';
GO

CREATE PROCEDURE test_MOD017.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwSubsMemberStatuses';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
END;
GO

CREATE PROCEDURE test_MOD017.[test TC-017-001 four source rows land live with Inv Total Amount and Retired Concession 1:1]
AS
BEGIN
    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], [Inv Total Amount], [Retired Concession])
    VALUES (N'100001', 2024, 'Fully Paid',      '2023-10-20', '2023-10-20', 1234.560000, 'Retired Conc.'),
           (N'100001', 2025, 'Fully Paid',      '2024-10-15', '2024-10-15',  480.000000, 'Retired Conc.'),
           (N'100002', 2025, 'Full Concession', '2024-11-05', '2024-11-05',    0.000000, 'Non-Retired Conc.'),
           (N'100003', 2025, 'No Payment',      NULL,         NULL,              NULL,     'No Invoice');

    EXEC Layercake.usp_load_brnz_subs_status;

    SELECT * INTO #Raw FROM Layercake.brnz_subs_status;

    SELECT [Contact No.] AS contact_no, [Campaign Year] AS campaign_year, inv_total_amount, retired_concession, _is_deleted
    INTO #Actual
    FROM #Raw;

    SELECT v.contact_no, v.campaign_year, CAST(v.inv_total_amount AS numeric(38,6)) AS inv_total_amount,
           CAST(v.retired_concession AS varchar(17)) AS retired_concession, CAST(v._is_deleted AS bit) AS _is_deleted
    INTO #Expected
    FROM (VALUES (N'100001', 2024, 1234.560000, 'Retired Conc.',     0),
                 (N'100001', 2025,  480.000000, 'Retired Conc.',     0),
                 (N'100002', 2025,    0.000000, 'Non-Retired Conc.', 0),
                 (N'100003', 2025,        NULL, 'No Invoice',        0)) AS v(contact_no, campaign_year, inv_total_amount, retired_concession, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD017.[test TC-017-002 rows landed before the change keep their existing columns and row count and gain the new columns]
AS
BEGIN
    -- rows as Phase 1 left them: the two new columns are not named, so they hold NULL as after the change script
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'200001', 2024, 'Fully Paid',      '2023-10-20', '2023-10-20', '2020-01-01', '2020-01-01', 0, NULL),
           (N'200001', 2025, 'Partially Paid',  '2024-10-15', '2024-12-01', '2020-01-01', '2020-01-01', 0, NULL),
           (N'200002', 2025, 'Full Concession', '2024-11-05', '2024-11-05', '2020-01-01', '2020-01-01', 0, NULL),
           (N'200003', 2025, 'No Payment',      NULL,         NULL,         '2020-01-01', '2020-01-01', 0, NULL);

    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], [Inv Total Amount], [Retired Concession])
    VALUES (N'200001', 2024, 'Fully Paid',      '2023-10-20', '2023-10-20', 1234.560000, 'Retired Conc.'),
           (N'200001', 2025, 'Partially Paid',  '2024-10-15', '2024-12-01',  480.000000, 'Retired Conc.'),
           (N'200002', 2025, 'Full Concession', '2024-11-05', '2024-11-05',    0.000000, 'Non-Retired Conc.'),
           (N'200003', 2025, 'No Payment',      NULL,         NULL,              NULL,     'No Invoice');

    EXEC Layercake.usp_load_brnz_subs_status;

    SELECT * INTO #Raw FROM Layercake.brnz_subs_status;

    SELECT [Contact No.] AS contact_no, [Campaign Year] AS campaign_year, [Member Invoice Position] AS member_invoice_position,
           [Renewal Date] AS renewal_date, [Renewal Date Adj] AS renewal_date_adj, inv_total_amount, retired_concession,
           _loaded_at, _is_deleted
    INTO #Actual
    FROM #Raw;

    SELECT v.contact_no, v.campaign_year, CAST(v.member_invoice_position AS varchar(18)) AS member_invoice_position,
           CAST(v.renewal_date AS date) AS renewal_date, CAST(v.renewal_date_adj AS date) AS renewal_date_adj,
           CAST(v.inv_total_amount AS numeric(38,6)) AS inv_total_amount, CAST(v.retired_concession AS varchar(17)) AS retired_concession,
           CAST(v._loaded_at AS datetime2(3)) AS _loaded_at, CAST(v._is_deleted AS bit) AS _is_deleted
    INTO #Expected
    FROM (VALUES (N'200001', 2024, 'Fully Paid',      '2023-10-20', '2023-10-20', 1234.560000, 'Retired Conc.',     '2020-01-01', 0),
                 (N'200001', 2025, 'Partially Paid',  '2024-10-15', '2024-12-01',  480.000000, 'Retired Conc.',     '2020-01-01', 0),
                 (N'200002', 2025, 'Full Concession', '2024-11-05', '2024-11-05',    0.000000, 'Non-Retired Conc.', '2020-01-01', 0),
                 (N'200003', 2025, 'No Payment',      NULL,         NULL,              NULL,     'No Invoice',        '2020-01-01', 0))
         AS v(contact_no, campaign_year, member_invoice_position, renewal_date, renewal_date_adj, inv_total_amount, retired_concession, _loaded_at, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 4 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD017.[test TC-017-003 first load onto an empty table lands the existing columns 1:1 and one row per source row]
AS
BEGIN
    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], [Inv Total Amount], [Retired Concession])
    VALUES (N'300001', 2024, 'Fully Paid',      '2023-10-20', '2023-10-20', 1234.560000, 'Retired Conc.'),
           (N'300001', 2025, 'Partially Paid',  '2024-10-15', '2024-12-01',  480.000000, 'Retired Conc.'),
           (N'300002', 2025, 'Full Concession', '2024-11-05', '2024-11-05',    0.000000, 'Non-Retired Conc.'),
           (N'300003', 2025, 'No Payment',      NULL,         NULL,              NULL,     'No Invoice');

    EXEC Layercake.usp_load_brnz_subs_status;

    SELECT [Contact No.] AS contact_no, [Campaign Year] AS campaign_year, [Member Invoice Position] AS member_invoice_position,
           [Renewal Date] AS renewal_date, [Renewal Date Adj] AS renewal_date_adj, _is_deleted, _deleted_at
    INTO #Actual
    FROM Layercake.brnz_subs_status;

    SELECT v.contact_no, v.campaign_year, CAST(v.member_invoice_position AS varchar(18)) AS member_invoice_position,
           CAST(v.renewal_date AS date) AS renewal_date, CAST(v.renewal_date_adj AS date) AS renewal_date_adj,
           CAST(v._is_deleted AS bit) AS _is_deleted, CAST(v._deleted_at AS datetime2(3)) AS _deleted_at
    INTO #Expected
    FROM (VALUES (N'300001', 2024, 'Fully Paid',      '2023-10-20', '2023-10-20', 0, NULL),
                 (N'300001', 2025, 'Partially Paid',  '2024-10-15', '2024-12-01', 0, NULL),
                 (N'300002', 2025, 'Full Concession', '2024-11-05', '2024-11-05', 0, NULL),
                 (N'300003', 2025, 'No Payment',      NULL,         NULL,         0, NULL))
         AS v(contact_no, campaign_year, member_invoice_position, renewal_date, renewal_date_adj, _is_deleted, _deleted_at);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @missing_audit int = (SELECT COUNT(*) FROM Layercake.brnz_subs_status WHERE _loaded_at IS NULL OR _updated_at IS NULL);
    EXEC tSQLt.AssertEquals 0, @missing_audit, 'every landed row has _loaded_at and _updated_at';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('Success' AS varchar(10)) AS status, 4 AS rows_inserted, 0 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD017.[test TC-017-004 a change to or from a null Inv Total Amount is a change and an unchanged null row is untouched]
AS
BEGIN
    EXEC (N'INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], inv_total_amount, retired_concession, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N''400001'', 2025, ''Fully Paid'', ''2024-10-15'', ''2024-10-15'', 100.000000, ''No Conc.'',   ''2020-01-01'', ''2020-01-01'', 0, NULL),
           (N''400002'', 2025, ''Fully Paid'', ''2024-10-16'', ''2024-10-16'', NULL,       ''No Conc.'',   ''2020-01-01'', ''2020-01-01'', 0, NULL),
           (N''400003'', 2025, ''No Payment'', NULL,           NULL,           NULL,       ''No Invoice'', ''2020-01-01'', ''2020-01-01'', 0, NULL);');

    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], [Inv Total Amount], [Retired Concession])
    VALUES (N'400001', 2025, 'Fully Paid', '2024-10-15', '2024-10-15', NULL,       'No Conc.'),
           (N'400002', 2025, 'Fully Paid', '2024-10-16', '2024-10-16', 200.000000, 'No Conc.'),
           (N'400003', 2025, 'No Payment', NULL,         NULL,         NULL,       'No Invoice');

    EXEC Layercake.usp_load_brnz_subs_status;

    SELECT * INTO #Raw FROM Layercake.brnz_subs_status;

    SELECT [Contact No.] AS contact_no, inv_total_amount,
           CASE WHEN _updated_at = '2020-01-01' THEN 0 ELSE 1 END AS updated_at_refreshed,
           _loaded_at, _is_deleted
    INTO #Actual
    FROM #Raw;

    SELECT v.contact_no, CAST(v.inv_total_amount AS numeric(38,6)) AS inv_total_amount, v.updated_at_refreshed,
           CAST(v._loaded_at AS datetime2(3)) AS _loaded_at, CAST(v._is_deleted AS bit) AS _is_deleted
    INTO #Expected
    FROM (VALUES (N'400001', NULL,       1, '2020-01-01', 0),
                 (N'400002', 200.000000, 1, '2020-01-01', 0),
                 (N'400003', NULL,       0, '2020-01-01', 0))
         AS v(contact_no, inv_total_amount, updated_at_refreshed, _loaded_at, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 2 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD017.[test TC-017-005 a change in only Inv Total Amount or only Retired Concession updates that row in place]
AS
BEGIN
    EXEC (N'INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], inv_total_amount, retired_concession, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N''500001'', 2025, ''Fully Paid'', ''2024-10-15'', ''2024-10-15'', 450.000000, ''No Conc.'', ''2020-01-01'', ''2020-01-01'', 0, NULL),
           (N''500002'', 2025, ''Fully Paid'', ''2024-10-20'', ''2024-10-20'', 300.000000, ''No Conc.'', ''2020-01-01'', ''2020-01-01'', 0, NULL),
           (N''500003'', 2025, ''Fully Paid'', ''2024-10-25'', ''2024-10-25'', 600.000000, ''No Conc.'', ''2020-01-01'', ''2020-01-01'', 0, NULL);');

    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], [Inv Total Amount], [Retired Concession])
    VALUES (N'500001', 2025, 'Fully Paid', '2024-10-15', '2024-10-15', 500.500000, 'No Conc.'),
           (N'500002', 2025, 'Fully Paid', '2024-10-20', '2024-10-20', 300.000000, 'Retired Conc.'),
           (N'500003', 2025, 'Fully Paid', '2024-10-25', '2024-10-25', 600.000000, 'No Conc.');

    EXEC Layercake.usp_load_brnz_subs_status;

    SELECT * INTO #Raw FROM Layercake.brnz_subs_status;

    SELECT [Contact No.] AS contact_no, [Member Invoice Position] AS member_invoice_position, inv_total_amount, retired_concession,
           CASE WHEN _updated_at = '2020-01-01' THEN 0 ELSE 1 END AS updated_at_refreshed,
           _loaded_at, _is_deleted
    INTO #Actual
    FROM #Raw;

    SELECT v.contact_no, CAST(v.member_invoice_position AS varchar(18)) AS member_invoice_position,
           CAST(v.inv_total_amount AS numeric(38,6)) AS inv_total_amount, CAST(v.retired_concession AS varchar(17)) AS retired_concession,
           v.updated_at_refreshed, CAST(v._loaded_at AS datetime2(3)) AS _loaded_at, CAST(v._is_deleted AS bit) AS _is_deleted
    INTO #Expected
    FROM (VALUES (N'500001', 'Fully Paid', 500.500000, 'No Conc.',      1, '2020-01-01', 0),
                 (N'500002', 'Fully Paid', 300.000000, 'Retired Conc.', 1, '2020-01-01', 0),
                 (N'500003', 'Fully Paid', 600.000000, 'No Conc.',      0, '2020-01-01', 0))
         AS v(contact_no, member_invoice_position, inv_total_amount, retired_concession, updated_at_refreshed, _loaded_at, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 2 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD017.[test TC-017-006 a second load on unchanged source changes nothing and logs 0 0 0]
AS
BEGIN
    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], [Inv Total Amount], [Retired Concession])
    VALUES (N'600001', 2024, 'Fully Paid',      '2023-10-20', '2023-10-20', 1234.560000, 'Retired Conc.'),
           (N'600001', 2025, 'Partially Paid',  '2024-10-15', '2024-12-01',  480.000000, 'Retired Conc.'),
           (N'600002', 2025, 'Full Concession', '2024-11-05', '2024-11-05',    0.000000, 'Non-Retired Conc.'),
           (N'600003', 2025, 'No Payment',      NULL,         NULL,              NULL,     'No Invoice');

    EXEC Layercake.usp_load_brnz_subs_status;

    SELECT * INTO #Before FROM Layercake.brnz_subs_status;

    EXEC Layercake.usp_load_brnz_subs_status;

    SELECT * INTO #After FROM Layercake.brnz_subs_status;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 4, 0, 0),
                 (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD017.[test TC-017-007 the largest numeric 38 6 amount and the 17 character Retired Concession land exactly]
AS
BEGIN
    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], [Inv Total Amount], [Retired Concession])
    VALUES (N'700001', 2025, 'Fully Paid', '2024-10-15', '2024-10-15', 99999999999999999999999999999999.999999, 'Non-Retired Conc.'),
           (N'700002', 2025, 'Fully Paid', '2024-10-16', '2024-10-16', -0.000001,                                'Retired Conc.');

    EXEC Layercake.usp_load_brnz_subs_status;

    SELECT * INTO #Raw FROM Layercake.brnz_subs_status;

    SELECT [Contact No.] AS contact_no, inv_total_amount, CAST(retired_concession AS varbinary(34)) AS retired_concession_bytes
    INTO #Actual
    FROM #Raw;

    SELECT v.contact_no, CAST(v.inv_total_amount AS numeric(38,6)) AS inv_total_amount, v.retired_concession_bytes
    INTO #Expected
    FROM (VALUES (N'700001', CAST(99999999999999999999999999999999.999999 AS numeric(38,6)), CAST(CAST('Non-Retired Conc.' AS varchar(17)) AS varbinary(34))),
                 (N'700002', CAST(-0.000001 AS numeric(38,6)),                                CAST(CAST('Retired Conc.' AS varchar(17)) AS varbinary(34))))
         AS v(contact_no, inv_total_amount, retired_concession_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD017.[test TC-017-008 a row gone from the source is soft deleted and a deleted row that returns is restored with the new columns]
AS
BEGIN
    EXEC (N'INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], inv_total_amount, retired_concession, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N''800001'', 2025, ''Fully Paid'', ''2024-10-15'', ''2024-10-15'', 300.000000, ''No Conc.'', ''2020-01-01'', ''2020-01-01'', 0, NULL),
           (N''800002'', 2025, ''Fully Paid'', ''2024-10-20'', ''2024-10-20'', 250.000000, ''No Conc.'', ''2020-01-01'', ''2020-01-01'', 1, ''2020-06-01'');');

    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], [Inv Total Amount], [Retired Concession])
    VALUES (N'800002', 2025, 'Fully Paid', '2024-10-20', '2024-10-20', 275.000000, 'Retired Conc.');

    EXEC Layercake.usp_load_brnz_subs_status;

    SELECT * INTO #Raw FROM Layercake.brnz_subs_status;

    SELECT [Contact No.] AS contact_no, [Campaign Year] AS campaign_year, [Member Invoice Position] AS member_invoice_position,
           inv_total_amount, retired_concession, _is_deleted,
           CASE WHEN _deleted_at IS NULL THEN 0 ELSE 1 END AS has_deleted_at
    INTO #Actual
    FROM #Raw;

    SELECT v.contact_no, v.campaign_year, CAST(v.member_invoice_position AS varchar(18)) AS member_invoice_position,
           CAST(v.inv_total_amount AS numeric(38,6)) AS inv_total_amount, CAST(v.retired_concession AS varchar(17)) AS retired_concession,
           CAST(v._is_deleted AS bit) AS _is_deleted, v.has_deleted_at
    INTO #Expected
    FROM (VALUES (N'800001', 2025, 'Fully Paid', 300.000000, 'No Conc.',      1, 1),
                 (N'800002', 2025, 'Fully Paid', 275.000000, 'Retired Conc.', 0, 0))
         AS v(contact_no, campaign_year, member_invoice_position, inv_total_amount, retired_concession, _is_deleted, has_deleted_at);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @status varchar(10) = (SELECT status FROM Layercake.etl_run_log);
    EXEC tSQLt.AssertEqualsString 'Success', @status;
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD017.[test TC-017-009 a load the target rejects part-way re-raises logs Failed and leaves the table unchanged]
AS
BEGIN
    EXEC (N'ALTER TABLE Layercake.brnz_subs_status
        ADD CONSTRAINT ck_test_MOD017_reject_amount CHECK (inv_total_amount IS NULL OR inv_total_amount <> 777.770000);');

    EXEC (N'INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], inv_total_amount, retired_concession, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N''900001'', 2025, ''No Payment'', NULL, NULL, 100.000000, ''No Conc.'', ''2020-01-01'', ''2020-01-01'', 0, NULL);');

    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], [Inv Total Amount], [Retired Concession])
    VALUES (N'900001', 2025, 'Fully Paid', '2024-10-15', '2024-10-15', 100.000000, 'Retired Conc.'),
           (N'900002', 2025, 'Fully Paid', '2024-10-16', '2024-10-16', 777.770000, 'No Conc.');

    SELECT * INTO #Before FROM Layercake.brnz_subs_status;

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_subs_status;
        EXEC tSQLt.Fail 'usp_load_brnz_subs_status did not raise the check-constraint error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547
            THROW;
    END CATCH;

    SELECT * INTO #After FROM Layercake.brnz_subs_status;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT status, CASE WHEN error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('Failed' AS varchar(10)) AS status, 1 AS has_error_message
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
