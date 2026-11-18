EXEC tSQLt.NewTestClass 'test_MOD024_dev';
GO

CREATE PROCEDURE test_MOD024_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
END;
GO

CREATE PROCEDURE test_MOD024_dev.[test final tie-break puts a value before the same value with a trailing space]
AS
BEGIN
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES (N'D1', N'SCH-D', N'Scheme D', 2025, N'Inactive', N'Inactive ', '2024-10-01', N'Round 1'),
           (N'D1', N'SCH-D', N'Scheme D', 2025, N'Inactive', N'Inactive',  '2024-10-01', N'Round 1'),
           (N'D2', N'SCH-D', N'Scheme D ', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 1'),
           (N'D2', N'SCH-D', N'Scheme D',  2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 1');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT t.contact_no,
           CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes,
           CAST(t.scheme_name AS varbinary(8000)) AS scheme_name_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t;

    SELECT v.contact_no, v.sub_user_status_bytes, v.scheme_name_bytes
    INTO #Expected
    FROM (VALUES (N'D1', CAST(N'Inactive' AS varbinary(700)), CAST(N'Scheme D' AS varbinary(8000))),
                 (N'D2', CAST(N'Inactive' AS varbinary(700)), CAST(N'Scheme D' AS varbinary(8000))))
         AS v(contact_no, sub_user_status_bytes, scheme_name_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD024_dev.[test a key repeated only in letter case lands one row with the exactly first contact_no]
AS
BEGIN
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES (N'd3', N'sch-d', N'Scheme D', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 1'),
           (N'D3', N'sch-d', N'Scheme D', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 1'),
           (N'D3', N'SCH-D', N'Scheme D', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 1');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT CAST(t.contact_no AS varbinary(200)) AS contact_no_bytes,
           CAST(t.scheme_no AS varbinary(200)) AS scheme_no_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t;

    SELECT v.contact_no_bytes, v.scheme_no_bytes
    INTO #Expected
    FROM (VALUES (CAST(N'D3' AS varbinary(200)), CAST(N'SCH-D' AS varbinary(200)))) AS v(contact_no_bytes, scheme_no_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @not_landed int =
        (SELECT p.rows_affected FROM Layercake.etl_progress_log AS p WHERE p.substep = N'repeated_key_rows_not_landed');
    EXEC tSQLt.AssertEquals 2, @not_landed;
END;
GO

CREATE PROCEDURE test_MOD024_dev.[test the active value matches regardless of case as the readers compare it]
AS
BEGIN
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES (N'D4', N'SCH-D', N'Scheme D', 2025, N'ACTIVE',   N'active',   '2024-10-01', N'Round 1'),
           (N'D4', N'SCH-D', N'Scheme D', 2025, N'Inactive', N'Inactive', '2025-01-01', N'Round 5');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT CAST(t.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t;

    SELECT v.sub_status_bytes, v.sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (CAST(N'ACTIVE' AS varbinary(700)), CAST(N'active' AS varbinary(700)))) AS v(sub_status_bytes, sub_user_status_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD024_dev.[test a Round number beyond bigint still compares by value]
AS
BEGIN
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES (N'D5', N'SCH-D', N'Scheme D', 2025, N'Inactive', N'Active',   '2024-10-01', N'Round 9'),
           (N'D5', N'SCH-D', N'Scheme D', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 99999999999999999999');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t;

    SELECT v.sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (CAST(N'Inactive' AS varbinary(700)))) AS v(sub_user_status_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD024_dev.[test an empty source logs Success 0 0 0 and 0 rows not landed]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT r.status, r.rows_inserted, r.rows_updated, r.rows_deleted, p.rows_affected
    INTO #Actual
    FROM Layercake.etl_run_log AS r
    INNER JOIN Layercake.etl_progress_log AS p
        ON  p.log_id = r.log_id
        AND p.substep = N'repeated_key_rows_not_landed'
    WHERE r.step_name = 'brnz_corporate_subscription';

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted, v.rows_affected
    INTO #Expected
    FROM (VALUES ('Success', 0, 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted, rows_affected);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD024_dev.[test a NULL Contact No fails with 515 logs Failed writes no sub-step and leaves bronze unchanged]
AS
BEGIN
    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status)
    VALUES (N'D6', N'SCH-D', N'Scheme D', 2025, N'Active', N'Active');

    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES (N'D7', N'SCH-D', N'Scheme D', 2025, N'Active', N'Active', '2024-10-01', N'Round 1'),
           (N'D7', N'SCH-D', N'Scheme D', 2025, N'Active', N'Inactive', '2024-10-01', N'Round 2'),
           (NULL,  N'SCH-D', N'Scheme D', 2025, N'Active', N'Active', '2024-10-01', N'Round 1');

    SELECT t.contact_no, t.scheme_no, t.scheme_name, t.sub_campaign_year, t.sub_status, t.sub_user_status, t._is_deleted
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

    DECLARE @substeps int = (SELECT COUNT(*) FROM Layercake.etl_progress_log AS p WHERE p.substep = N'repeated_key_rows_not_landed');
    EXEC tSQLt.AssertEquals 0, @substeps;

    SELECT t.contact_no, t.scheme_no, t.scheme_name, t.sub_campaign_year, t.sub_status, t.sub_user_status, t._is_deleted
    INTO #After
    FROM Layercake.brnz_corporate_subscription AS t;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';
END;
GO
