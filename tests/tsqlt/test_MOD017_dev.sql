EXEC tSQLt.NewTestClass 'test_MOD017_dev';
GO

CREATE PROCEDURE test_MOD017_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwSubsMemberStatuses';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
END;
GO

CREATE PROCEDURE test_MOD017_dev.[test a case-only or trailing-space change in Retired Concession is landed byte for byte]
AS
BEGIN
    EXEC (N'INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], inv_total_amount, retired_concession, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N''A1'', 2025, ''Fully Paid'', ''2024-10-15'', ''2024-10-15'', 10.000000, ''No Conc.'',      ''2020-01-01'', ''2020-01-01'', 0, NULL),
           (N''A2'', 2025, ''Fully Paid'', ''2024-10-15'', ''2024-10-15'', 20.000000, ''Retired Conc.'', ''2020-01-01'', ''2020-01-01'', 0, NULL),
           (N''A3'', 2025, ''Fully Paid'', ''2024-10-15'', ''2024-10-15'', 30.000000, ''No Conc.'',      ''2020-01-01'', ''2020-01-01'', 0, NULL);');

    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], [Inv Total Amount], [Retired Concession])
    VALUES (N'A1', 2025, 'Fully Paid', '2024-10-15', '2024-10-15', 10.000000, 'NO CONC.'),
           (N'A2', 2025, 'Fully Paid', '2024-10-15', '2024-10-15', 20.000000, 'Retired Conc. '),
           (N'A3', 2025, 'Fully Paid', '2024-10-15', '2024-10-15', 30.000000, 'No Conc.');

    EXEC Layercake.usp_load_brnz_subs_status;

    SELECT * INTO #Raw FROM Layercake.brnz_subs_status;

    SELECT [Contact No.] AS contact_no, CAST(retired_concession AS varbinary(17)) AS retired_concession_bytes,
           CASE WHEN _updated_at = '2020-01-01' THEN 0 ELSE 1 END AS updated_at_refreshed
    INTO #Actual
    FROM #Raw;

    SELECT v.contact_no, v.retired_concession_bytes, v.updated_at_refreshed
    INTO #Expected
    FROM (VALUES (N'A1', CAST(CAST('NO CONC.' AS varchar(17)) AS varbinary(17)),       1),
                 (N'A2', CAST(CAST('Retired Conc. ' AS varchar(17)) AS varbinary(17)), 1),
                 (N'A3', CAST(CAST('No Conc.' AS varchar(17)) AS varbinary(17)),       0))
         AS v(contact_no, retired_concession_bytes, updated_at_refreshed);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 2 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD017_dev.[test a duplicate source key keeps the row with the latest Renewal Date Adj and its new columns]
AS
BEGIN
    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], [Inv Total Amount], [Retired Concession])
    VALUES (N'B1', 2025, 'Partially Paid', '2024-10-15', '2024-10-15', 100.000000, 'No Conc.'),
           (N'B1', 2025, 'Fully Paid',     '2024-10-15', '2024-12-01', 250.000000, 'Retired Conc.');

    EXEC Layercake.usp_load_brnz_subs_status;

    SELECT * INTO #Raw FROM Layercake.brnz_subs_status;

    SELECT [Contact No.] AS contact_no, [Member Invoice Position] AS member_invoice_position, inv_total_amount, retired_concession
    INTO #Actual
    FROM #Raw;

    SELECT v.contact_no, CAST(v.member_invoice_position AS varchar(18)) AS member_invoice_position,
           CAST(v.inv_total_amount AS numeric(38,6)) AS inv_total_amount, CAST(v.retired_concession AS varchar(17)) AS retired_concession
    INTO #Expected
    FROM (VALUES (N'B1', 'Fully Paid', 250.000000, 'Retired Conc.'))
         AS v(contact_no, member_invoice_position, inv_total_amount, retired_concession);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('Success' AS varchar(10)) AS status, 1 AS rows_inserted, 0 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD017_dev.[test a soft deleted row restored with unchanged values counts as one update and a gone row as one delete]
AS
BEGIN
    EXEC (N'INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], inv_total_amount, retired_concession, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N''C1'', 2025, ''Fully Paid'', ''2024-10-15'', ''2024-10-15'', 75.000000, ''No Conc.'', ''2020-01-01'', ''2020-01-01'', 1, ''2020-06-01''),
           (N''C2'', 2025, ''Fully Paid'', ''2024-10-15'', ''2024-10-15'', 80.000000, ''No Conc.'', ''2020-01-01'', ''2020-01-01'', 0, NULL);');

    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], [Inv Total Amount], [Retired Concession])
    VALUES (N'C1', 2025, 'Fully Paid', '2024-10-15', '2024-10-15', 75.000000, 'No Conc.');

    EXEC Layercake.usp_load_brnz_subs_status;

    SELECT * INTO #Raw FROM Layercake.brnz_subs_status;

    SELECT [Contact No.] AS contact_no, inv_total_amount, retired_concession, _is_deleted,
           CASE WHEN _deleted_at IS NULL THEN 0 ELSE 1 END AS has_deleted_at
    INTO #Actual
    FROM #Raw;

    SELECT v.contact_no, CAST(v.inv_total_amount AS numeric(38,6)) AS inv_total_amount,
           CAST(v.retired_concession AS varchar(17)) AS retired_concession, CAST(v._is_deleted AS bit) AS _is_deleted, v.has_deleted_at
    INTO #Expected
    FROM (VALUES (N'C1', 75.000000, 'No Conc.', 0, 0),
                 (N'C2', 80.000000, 'No Conc.', 1, 1))
         AS v(contact_no, inv_total_amount, retired_concession, _is_deleted, has_deleted_at);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 1 AS rows_updated, 1 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD017_dev.[test a Retired Concession the target rejects on update rolls back the whole load and logs Failed]
AS
BEGIN
    EXEC (N'ALTER TABLE Layercake.brnz_subs_status
        ADD CONSTRAINT ck_test_MOD017_dev_reject_conc CHECK (retired_concession IS NULL OR retired_concession <> ''Rejected'');');

    EXEC (N'INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], inv_total_amount, retired_concession, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N''D1'', 2025, ''Fully Paid'', ''2024-10-15'', ''2024-10-15'', 10.000000, ''No Conc.'', ''2020-01-01'', ''2020-01-01'', 0, NULL);');

    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], [Inv Total Amount], [Retired Concession])
    VALUES (N'D1', 2025, 'Fully Paid', '2024-10-15', '2024-10-15', 10.000000, 'Rejected'),
           (N'D2', 2025, 'Fully Paid', '2024-10-16', '2024-10-16', 20.000000, 'No Conc.');

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

    SELECT status, CASE WHEN error_message LIKE '%error 547%' THEN 1 ELSE 0 END AS error_547_logged
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST('Failed' AS varchar(10)) AS status, 1 AS error_547_logged
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
