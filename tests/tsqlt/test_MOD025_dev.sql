EXEC tSQLt.NewTestClass 'test_MOD025_dev';
GO

CREATE PROCEDURE test_MOD025_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
END;
GO

CREATE PROCEDURE test_MOD025_dev.[test undated rows are counted one by one and only dated rows count as repeats]
AS
BEGIN
    -- Three identical undated copies of E1's key and two dated copies of it.
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES (N'E1', N'SCH-E', N'Scheme E', NULL, N'Active', N'Active',   '2025-01-01', N'Round 9'),
           (N'E1', N'SCH-E', N'Scheme E', NULL, N'Active', N'Active',   '2025-01-01', N'Round 9'),
           (N'E1', N'SCH-E', N'Scheme E', NULL, N'Active', N'Active',   '2025-01-01', N'Round 9'),
           (N'E1', N'SCH-E', N'Scheme E', 2025, N'Active', N'Inactive', '2024-10-01', N'Round 1'),
           (N'E1', N'SCH-E', N'Scheme E', 2025, N'Active', N'Inactive', '2024-11-01', N'Round 2');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT r.status, r.rows_inserted, r.rows_updated, r.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS r;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT p.substep, p.rows_affected
    INTO #ActualSteps
    FROM Layercake.etl_progress_log AS p;

    SELECT v.substep, v.rows_affected
    INTO #ExpectedSteps
    FROM (VALUES (N'repeated_key_rows_not_landed', 1),
                 (N'no_campaign_year_rows_not_landed', 3))
         AS v(substep, rows_affected);

    EXEC tSQLt.AssertEqualsTable '#ExpectedSteps', '#ActualSteps';

    SELECT t.contact_no, t.sub_campaign_year, CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t;

    SELECT v.contact_no, v.sub_campaign_year, CAST(v.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (N'E1', 2025, N'Inactive')) AS v(contact_no, sub_campaign_year, sub_user_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD025_dev.[test a key soft deleted when its year went missing is restored when the year comes back]
AS
BEGIN
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES (N'E2', N'SCH-E', N'Scheme E', 2026, N'Active', N'Active', '2025-10-01', N'Round 1');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    UPDATE Subs.vwCorpSubscriptions SET [Sub Campaign Year] = NULL;
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    UPDATE Subs.vwCorpSubscriptions SET [Sub Campaign Year] = 2026;
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT r.log_id, r.status, r.rows_inserted, r.rows_updated, r.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS r;

    SELECT v.log_id, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST(1 AS bigint), 'Success', 1, 0, 0),
                 (CAST(2 AS bigint), 'Success', 0, 0, 1),
                 (CAST(3 AS bigint), 'Success', 0, 1, 0))
         AS v(log_id, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT p.log_id, p.rows_affected
    INTO #ActualSteps
    FROM Layercake.etl_progress_log AS p
    WHERE p.substep = N'no_campaign_year_rows_not_landed';

    SELECT v.log_id, v.rows_affected
    INTO #ExpectedSteps
    FROM (VALUES (CAST(1 AS bigint), 0), (CAST(2 AS bigint), 1), (CAST(3 AS bigint), 0)) AS v(log_id, rows_affected);

    EXEC tSQLt.AssertEqualsTable '#ExpectedSteps', '#ActualSteps';

    SELECT t.contact_no, t.sub_campaign_year, t._is_deleted,
           CAST(CASE WHEN t._deleted_at IS NULL THEN 0 ELSE 1 END AS bit) AS has_deleted_at
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t;

    SELECT v.contact_no, v.sub_campaign_year, CAST(0 AS bit) AS _is_deleted, CAST(0 AS bit) AS has_deleted_at
    INTO #Expected
    FROM (VALUES (N'E2', 2026)) AS v(contact_no, sub_campaign_year);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD025_dev.[test a NULL Scheme No on an undated row fails with 515 logs Failed writes neither sub-step and leaves bronze unchanged]
AS
BEGIN
    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status)
    VALUES (N'E3', N'SCH-E', N'Scheme E', 2025, N'Active', N'Active');

    -- The dated row would soft-delete nothing and insert E4 if the load went on.
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES (N'E3', N'SCH-E', N'Scheme E', 2025, N'Active', N'Active', '2024-10-01', N'Round 1'),
           (N'E4', N'SCH-E', N'Scheme E', 2025, N'Active', N'Active', '2024-10-01', N'Round 1'),
           (N'E5', NULL,     N'Scheme E', NULL, N'Active', N'Active', '2025-10-01', N'Round 1');

    SELECT t.contact_no, t.scheme_no, t.scheme_name, t.sub_campaign_year, t.sub_status, t.sub_user_status,
           t._is_deleted, t._deleted_at, t._loaded_at, t._updated_at
    INTO #Before
    FROM Layercake.brnz_corporate_subscription AS t;

    DECLARE @err int = NULL;
    BEGIN TRY
        EXEC Layercake.usp_load_brnz_corporate_subscription;
        EXEC tSQLt.Fail 'Expected error 515 from usp_load_brnz_corporate_subscription, but no error was raised.';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_NUMBER();
        IF @err <> 515 THROW;
    END CATCH;

    EXEC tSQLt.AssertEquals 515, @err;

    SELECT r.status, CASE WHEN r.error_message LIKE N'%error 515%' THEN 1 ELSE 0 END AS has_515
    INTO #ActualLog
    FROM Layercake.etl_run_log AS r
    WHERE r.step_name = 'brnz_corporate_subscription';

    SELECT v.status, v.has_515
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_515);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    DECLARE @substeps int =
        (SELECT COUNT(*)
         FROM Layercake.etl_progress_log AS p
         WHERE p.substep IN (N'repeated_key_rows_not_landed', N'no_campaign_year_rows_not_landed'));
    EXEC tSQLt.AssertEquals 0, @substeps;

    SELECT t.contact_no, t.scheme_no, t.scheme_name, t.sub_campaign_year, t.sub_status, t.sub_user_status,
           t._is_deleted, t._deleted_at, t._loaded_at, t._updated_at
    INTO #After
    FROM Layercake.brnz_corporate_subscription AS t;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';
END;
GO
