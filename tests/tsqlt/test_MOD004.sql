EXEC tSQLt.NewTestClass 'test_MOD004';
GO

/* ===================== silv_ref_payer_type (seeded) ===================== */

CREATE PROCEDURE test_MOD004.[test TC-004-001 seeded payer type list holds the three reserved rows and Individual and Corporate]
AS
BEGIN
    SELECT CASE WHEN r.id <= 0 THEN r.id END AS reserved_id,
           CAST(r.payer_type_name AS varbinary(60)) AS name_bytes
    INTO #Actual
    FROM Layercake.silv_ref_payer_type AS r;

    SELECT v.reserved_id, v.name_bytes
    INTO #Expected
    FROM (VALUES (0,    CAST('Unknown' AS varbinary(60))),
                 (-1,   CAST('Unrecognised' AS varbinary(60))),
                 (-2,   CAST('Not applicable' AS varbinary(60))),
                 (NULL, CAST('Individual' AS varbinary(60))),
                 (NULL, CAST('Corporate' AS varbinary(60)))) AS v(reserved_id, name_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'silv_ref_payer_type must hold exactly the 5 seeded rows with byte-exact labels';

    SELECT r.id
    INTO #ActualPositiveIds
    FROM Layercake.silv_ref_payer_type AS r
    WHERE r.id > 0;

    SELECT v.id
    INTO #ExpectedPositiveIds
    FROM (VALUES (1), (2)) AS v(id);

    EXEC tSQLt.AssertEqualsTable '#ExpectedPositiveIds', '#ActualPositiveIds', 'Individual and Corporate must take identity ids 1 and 2';
END;
GO

/* ===================== usp_load_dim_payer_type ===================== */

CREATE PROCEDURE test_MOD004.[test TC-004-002 first dimension load copies all five ids and names and logs Success]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type';
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name, created_at, updated_at)
    VALUES (0, 'Unknown', '2026-01-01', '2026-01-01'),
           (-1, 'Unrecognised', '2026-01-01', '2026-01-01'),
           (-2, 'Not applicable', '2026-01-01', '2026-01-01'),
           (1, 'Individual', '2026-01-01', '2026-01-01'),
           (2, 'Corporate', '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_dim_payer_type;

    SELECT d.id, CAST(d.payer_type_name AS varbinary(60)) AS name_bytes
    INTO #Actual
    FROM Layercake.dim_payer_type AS d;

    SELECT v.id, v.name_bytes
    INTO #Expected
    FROM (VALUES (0,  CAST('Unknown' AS varbinary(60))),
                 (-1, CAST('Unrecognised' AS varbinary(60))),
                 (-2, CAST('Not applicable' AS varbinary(60))),
                 (1,  CAST('Individual' AS varbinary(60))),
                 (2,  CAST('Corporate' AS varbinary(60)))) AS v(id, name_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 5, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-003 second dimension load keeps every id and changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type';
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name, created_at, updated_at)
    VALUES (0, 'Unknown', '2026-01-01', '2026-01-01'),
           (-1, 'Unrecognised', '2026-01-01', '2026-01-01'),
           (-2, 'Not applicable', '2026-01-01', '2026-01-01'),
           (1, 'Individual', '2026-01-01', '2026-01-01'),
           (2, 'Corporate', '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_dim_payer_type;

    SELECT * INTO #AfterFirst FROM Layercake.dim_payer_type;

    EXEC Layercake.usp_load_dim_payer_type;

    SELECT * INTO #AfterSecond FROM Layercake.dim_payer_type;

    EXEC tSQLt.AssertEqualsTable '#AfterFirst', '#AfterSecond', 'the second load must change nothing';

    SELECT d.id, CAST(d.payer_type_name AS varbinary(60)) AS name_bytes
    INTO #Actual
    FROM Layercake.dim_payer_type AS d;

    SELECT v.id, v.name_bytes
    INTO #Expected
    FROM (VALUES (0,  CAST('Unknown' AS varbinary(60))),
                 (-1, CAST('Unrecognised' AS varbinary(60))),
                 (-2, CAST('Not applicable' AS varbinary(60))),
                 (1,  CAST('Individual' AS varbinary(60))),
                 (2,  CAST('Corporate' AS varbinary(60)))) AS v(id, name_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 5, 0, 0),
                 ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-004 dimension load inserts a missing id updates a changed name and leaves unchanged rows untouched]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type';
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name, created_at, updated_at)
    VALUES (0, 'Unknown', '2026-01-01', '2026-01-01'),
           (-1, 'Unrecognised', '2026-01-01', '2026-01-01'),
           (-2, 'Not applicable', '2026-01-01', '2026-01-01'),
           (1, 'Individual', '2026-01-01', '2026-01-01'),
           (2, 'Corporate', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.dim_payer_type (id, payer_type_name, load_id, created_at, updated_at)
    VALUES (0, 'Unknown', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
           (-1, 'Unrecognised', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
           (1, 'Individual', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
           (2, 'Corporate scheme', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00');

    EXEC Layercake.usp_load_dim_payer_type;

    SELECT d.id, CAST(d.payer_type_name AS varbinary(60)) AS name_bytes
    INTO #Actual
    FROM Layercake.dim_payer_type AS d;

    SELECT v.id, v.name_bytes
    INTO #Expected
    FROM (VALUES (0,  CAST('Unknown' AS varbinary(60))),
                 (-1, CAST('Unrecognised' AS varbinary(60))),
                 (-2, CAST('Not applicable' AS varbinary(60))),
                 (1,  CAST('Individual' AS varbinary(60))),
                 (2,  CAST('Corporate' AS varbinary(60)))) AS v(id, name_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT d.id, d.load_id, d.created_at, d.updated_at
    INTO #ActualUntouched
    FROM Layercake.dim_payer_type AS d
    WHERE d.id IN (0, -1, 1);

    SELECT v.id, v.load_id, CAST(v.created_at AS datetime2(3)) AS created_at, CAST(v.updated_at AS datetime2(3)) AS updated_at
    INTO #ExpectedUntouched
    FROM (VALUES (0,  7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
                 (-1, 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
                 (1,  7, '2026-02-01 10:00:00', '2026-02-01 10:00:00')) AS v(id, load_id, created_at, updated_at);

    EXEC tSQLt.AssertEqualsTable '#ExpectedUntouched', '#ActualUntouched', 'unchanged rows must not be rewritten';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-005 dimension load corrects a name that differs only in case]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type';
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name, created_at, updated_at)
    VALUES (0, 'Unknown', '2026-01-01', '2026-01-01'),
           (2, 'Corporate', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.dim_payer_type (id, payer_type_name, load_id, created_at, updated_at)
    VALUES (0, 'Unknown', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
           (2, 'CORPORATE', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00');

    EXEC Layercake.usp_load_dim_payer_type;

    SELECT d.id, CAST(d.payer_type_name AS varbinary(60)) AS name_bytes
    INTO #Actual
    FROM Layercake.dim_payer_type AS d;

    SELECT v.id, v.name_bytes
    INTO #Expected
    FROM (VALUES (0, CAST('Unknown' AS varbinary(60))),
                 (2, CAST('Corporate' AS varbinary(60)))) AS v(id, name_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD004.[test TC-004-006 failed dimension load re-raises logs Failed and leaves the target unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type';
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name, created_at, updated_at)
    VALUES (0, 'Unknown', '2026-01-01', '2026-01-01'),
           (1, 'Individual', '2026-01-01', '2026-01-01'),
           (9, 'Rejected type', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.dim_payer_type (id, payer_type_name, load_id, created_at, updated_at)
    VALUES (1, 'Private', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00');

    ALTER TABLE Layercake.dim_payer_type
        ADD CONSTRAINT CK_test_MOD004_dim_payer_type_reject CHECK (payer_type_name <> 'Rejected type');

    SELECT * INTO #Before FROM Layercake.dim_payer_type;

    BEGIN TRY
        EXEC Layercake.usp_load_dim_payer_type;
        EXEC tSQLt.Fail 'usp_load_dim_payer_type should have raised the check constraint error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    SELECT * INTO #After FROM Layercake.dim_payer_type;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'dim_payer_type must be unchanged after a failed load';

    SELECT l.status, CASE WHEN l.error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-007 dimension loaded from the seeded list has the same five ids and names as the list]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    EXEC Layercake.usp_load_dim_payer_type;

    SELECT CASE WHEN d.id <= 0 THEN d.id END AS reserved_id,
           CAST(d.payer_type_name AS varbinary(60)) AS name_bytes
    INTO #Actual
    FROM Layercake.dim_payer_type AS d;

    SELECT v.reserved_id, v.name_bytes
    INTO #Expected
    FROM (VALUES (0,    CAST('Unknown' AS varbinary(60))),
                 (-1,   CAST('Unrecognised' AS varbinary(60))),
                 (-2,   CAST('Not applicable' AS varbinary(60))),
                 (NULL, CAST('Individual' AS varbinary(60))),
                 (NULL, CAST('Corporate' AS varbinary(60)))) AS v(reserved_id, name_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'dim_payer_type must hold the 5 payer types';

    SELECT d.id, CAST(d.payer_type_name AS varbinary(60)) AS name_bytes
    INTO #DimPairs
    FROM Layercake.dim_payer_type AS d;

    SELECT r.id, CAST(r.payer_type_name AS varbinary(60)) AS name_bytes
    INTO #SilverPairs
    FROM Layercake.silv_ref_payer_type AS r;

    EXEC tSQLt.AssertEqualsTable '#SilverPairs', '#DimPairs', 'dim_payer_type must have the same (id, name) pairs as silv_ref_payer_type';
END;
GO

/* ===================== usp_load_brnz_corporate_subscription ===================== */

CREATE PROCEDURE test_MOD004.[test TC-004-008 first corporate subscription load lands 4 source rows 1:1 live and logs Success]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'1000001', N'SCH-001', N'Alpha Surveyors LLP', 2025, N'Active', N'Active', N'Round 1'),
           (N'1000002', N'SCH-001', N'Alpha Surveyors LLP', 2025, N'Active', N'Inactive', N'Round 2'),
           (N'1000003', N'SCH-002', N'Beta Property Ltd', 2024, N'Cancelled', N'Active', N'Round 1'),
           (N'1000003', N'SCH-002', N'Beta Property Ltd', 2025, N'Active', N'Active', NULL);

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT b.contact_no, b.scheme_no, b.scheme_name, b.sub_campaign_year, b.sub_status, b.sub_user_status,
           b._is_deleted, b._deleted_at
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.contact_no, v.scheme_no, v.scheme_name, v.sub_campaign_year, v.sub_status, v.sub_user_status,
           v._is_deleted, CAST(v._deleted_at AS datetime2(3)) AS _deleted_at
    INTO #Expected
    FROM (VALUES (N'1000001', N'SCH-001', N'Alpha Surveyors LLP', 2025, N'Active', N'Active', 0, NULL),
                 (N'1000002', N'SCH-001', N'Alpha Surveyors LLP', 2025, N'Active', N'Inactive', 0, NULL),
                 (N'1000003', N'SCH-002', N'Beta Property Ltd', 2024, N'Cancelled', N'Active', 0, NULL),
                 (N'1000003', N'SCH-002', N'Beta Property Ltd', 2025, N'Active', N'Active', 0, NULL))
         AS v(contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted, _deleted_at);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT b.contact_no
    INTO #MissingAuditTimes
    FROM Layercake.brnz_corporate_subscription AS b
    WHERE b._loaded_at IS NULL OR b._updated_at IS NULL;

    EXEC tSQLt.AssertEmptyTable '#MissingAuditTimes', 'every landed row must have _loaded_at and _updated_at';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 4, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-009 brnz_corporate_subscription has no Round column]
AS
BEGIN
    EXEC tSQLt.AssertObjectExists 'Layercake.brnz_corporate_subscription';

    SELECT c.name
    INTO #RoundColumns
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(N'Layercake.brnz_corporate_subscription')
      AND c.name LIKE N'%round%';

    EXEC tSQLt.AssertEmptyTable '#RoundColumns', 'Round must not be landed';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-010 a change only in Round does not update the landed row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'1000101', N'SCH-101', N'Kappa Valuers', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL);

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'1000101', N'SCH-101', N'Kappa Valuers', 2025, N'Active', N'Active', N'Round 2');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT b.contact_no, b.scheme_no, b.scheme_name, b.sub_campaign_year, b.sub_status, b.sub_user_status,
           b._loaded_at, b._updated_at, b._is_deleted
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.contact_no, v.scheme_no, v.scheme_name, v.sub_campaign_year, v.sub_status, v.sub_user_status,
           CAST(v._loaded_at AS datetime2(3)) AS _loaded_at, CAST(v._updated_at AS datetime2(3)) AS _updated_at, v._is_deleted
    INTO #Expected
    FROM (VALUES (N'1000101', N'SCH-101', N'Kappa Valuers', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0))
         AS v(contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-011 null scheme name and statuses land as null]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'1000011', N'SCH-011', NULL, 2025, NULL, NULL, NULL),
           (N'1000012', N'SCH-011', N'Gamma Estates', 2025, N'Active', NULL, N'Round 1');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT b.contact_no, b.scheme_no, b.scheme_name, b.sub_campaign_year, b.sub_status, b.sub_user_status, b._is_deleted
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.contact_no, v.scheme_no, v.scheme_name, v.sub_campaign_year, v.sub_status, v.sub_user_status, v._is_deleted
    INTO #Expected
    FROM (VALUES (N'1000011', N'SCH-011', CAST(NULL AS nvarchar(4000)), 2025, CAST(NULL AS nvarchar(350)), CAST(NULL AS nvarchar(350)), 0),
                 (N'1000012', N'SCH-011', N'Gamma Estates', 2025, N'Active', CAST(NULL AS nvarchar(350)), 0))
         AS v(contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-012 blank and untrimmed mixed case values land byte for byte]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'1000021', N'SCH-021', N'', 2025, N' active ', N'ACTIVE', NULL);

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT CASE WHEN b.scheme_name IS NULL THEN -1 ELSE DATALENGTH(b.scheme_name) END AS scheme_name_length,
           CAST(b.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(b.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b
    WHERE b.contact_no = N'1000021';

    SELECT v.scheme_name_length, v.sub_status_bytes, v.sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (0, CAST(N' active ' AS varbinary(700)), CAST(N'ACTIVE' AS varbinary(700))))
         AS v(scheme_name_length, sub_status_bytes, sub_user_status_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-013 second corporate subscription load on unchanged source changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'1000031', N'SCH-031', N'Delta Partners', 2025, N'Active', N'Active', N'Round 1'),
           (N'1000032', N'SCH-031', NULL, 2025, NULL, NULL, NULL),
           (N'1000033', N'SCH-032', N'Epsilon Group', 2024, N'Active', N'Inactive', N'Round 2');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #AfterFirst FROM Layercake.brnz_corporate_subscription;

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #AfterSecond FROM Layercake.brnz_corporate_subscription;

    EXEC tSQLt.AssertEqualsTable '#AfterFirst', '#AfterSecond', 'the second load must change nothing';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 3, 0, 0),
                 ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-014 changed corporate subscription row is updated and only it gets a new _updated_at]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'1000041', N'SCH-041', N'Theta Surveying', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL),
           (N'1000042', N'SCH-041', N'Theta Surveying', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL);

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'1000041', N'SCH-041', N'Theta Surveying', 2025, N'Active', N'Inactive', N'Round 1'),
           (N'1000042', N'SCH-041', N'Theta Surveying', 2025, N'Active', N'Active', N'Round 1');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT b.contact_no, b.sub_user_status, b._loaded_at,
           CASE WHEN b._updated_at > '2020-01-01' THEN 1 ELSE 0 END AS updated_later,
           b._is_deleted
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.contact_no, v.sub_user_status, CAST(v._loaded_at AS datetime2(3)) AS _loaded_at, v.updated_later, v._is_deleted
    INTO #Expected
    FROM (VALUES (N'1000041', N'Inactive', '2020-01-01', 1, 0),
                 (N'1000042', N'Active', '2020-01-01', 0, 0))
         AS v(contact_no, sub_user_status, _loaded_at, updated_later, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-015 a status change only in case is landed as a change]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'1000051', N'SCH-051', N'Iota Chartered', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL);

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'1000051', N'SCH-051', N'Iota Chartered', 2025, N'ACTIVE', N'Active', NULL);

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT CAST(b.sub_status AS varbinary(700)) AS sub_status_bytes,
           CASE WHEN b._updated_at > '2020-01-01' THEN 1 ELSE 0 END AS updated_later
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.sub_status_bytes, v.updated_later
    INTO #Expected
    FROM (VALUES (CAST(N'ACTIVE' AS varbinary(700)), 1)) AS v(sub_status_bytes, updated_later);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-016 corporate subscription row gone from source is soft deleted not removed]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'1000061', N'SCH-061', N'Lambda Land', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL),
           (N'1000062', N'SCH-061', N'Lambda Land', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL);

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'1000061', N'SCH-061', N'Lambda Land', 2025, N'Active', N'Active', N'Round 1');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT b.contact_no, b.sub_status, b._is_deleted,
           CASE WHEN b._deleted_at IS NULL THEN 0 ELSE 1 END AS has_deleted_at
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.contact_no, v.sub_status, v._is_deleted, v.has_deleted_at
    INTO #Expected
    FROM (VALUES (N'1000061', N'Active', 0, 0),
                 (N'1000062', N'Active', 1, 1)) AS v(contact_no, sub_status, _is_deleted, has_deleted_at);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 0, 1)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-017 soft deleted corporate subscription row that reappears unchanged is restored]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'1000071', N'SCH-071', N'Mu Holdings', 2025, N'Active', N'Active', '2020-01-01', '2020-06-01', 1, '2020-06-01');

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'1000071', N'SCH-071', N'Mu Holdings', 2025, N'Active', N'Active', N'Round 1');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT b.contact_no, b.scheme_no, b.scheme_name, b.sub_campaign_year, b.sub_status, b.sub_user_status, b._is_deleted
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.contact_no, v.scheme_no, v.scheme_name, v.sub_campaign_year, v.sub_status, v.sub_user_status, v._is_deleted
    INTO #Expected
    FROM (VALUES (N'1000071', N'SCH-071', N'Mu Holdings', 2025, N'Active', N'Active', 0))
         AS v(contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-018 rows are matched on contact scheme and year so a name change updates and a new year or scheme inserts]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'1000081', N'SCH-081', N'Zeta Old Name', 2024, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL);

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'1000081', N'SCH-081', N'Zeta New Name', 2024, N'Active', N'Active', N'Round 1'),
           (N'1000081', N'SCH-081', N'Zeta New Name', 2025, N'Active', N'Active', N'Round 1'),
           (N'1000081', N'SCH-082', N'Eta Associates', 2024, N'Active', N'Active', N'Round 1');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT b.contact_no, b.scheme_no, b.sub_campaign_year, b.scheme_name, b._is_deleted
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.contact_no, v.scheme_no, v.sub_campaign_year, v.scheme_name, v._is_deleted
    INTO #Expected
    FROM (VALUES (N'1000081', N'SCH-081', 2024, N'Zeta New Name', 0),
                 (N'1000081', N'SCH-081', 2025, N'Zeta New Name', 0),
                 (N'1000081', N'SCH-082', 2024, N'Eta Associates', 0))
         AS v(contact_no, scheme_no, sub_campaign_year, scheme_name, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT b._loaded_at
    INTO #ActualLoadedAt
    FROM Layercake.brnz_corporate_subscription AS b
    WHERE b.contact_no = N'1000081' AND b.scheme_no = N'SCH-081' AND b.sub_campaign_year = 2024;

    SELECT CAST(v._loaded_at AS datetime2(3)) AS _loaded_at
    INTO #ExpectedLoadedAt
    FROM (VALUES ('2020-01-01')) AS v(_loaded_at);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLoadedAt', '#ActualLoadedAt', 'the existing key must be updated in place, not re-inserted';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 2, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD004.[test TC-004-019 live corporate subscription rows reconcile to the source row count after inserts and a soft delete]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'1000091', N'SCH-091', N'Nu Realty', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL),
           (N'1000092', N'SCH-091', N'Nu Realty', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL);

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'1000091', N'SCH-091', N'Nu Realty', 2025, N'Active', N'Active', N'Round 1'),
           (N'1000093', N'SCH-091', N'Nu Realty', 2025, N'Active', N'Active', N'Round 1'),
           (N'1000094', N'SCH-092', N'Xi Planning', 2025, N'Active', N'Inactive', N'Round 2');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT b.contact_no, b._is_deleted
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.contact_no, v._is_deleted
    INTO #Expected
    FROM (VALUES (N'1000091', 0),
                 (N'1000092', 1),
                 (N'1000093', 0),
                 (N'1000094', 0)) AS v(contact_no, _is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @live int, @source int;
    SELECT @live = COUNT(*) FROM Layercake.brnz_corporate_subscription WHERE _is_deleted = 0;
    SELECT @source = COUNT(*) FROM Subs.vwCorpSubscriptions;
    EXEC tSQLt.AssertEquals 3, @live, 'live bronze rows';
    EXEC tSQLt.AssertEquals @source, @live, 'live bronze rows must equal the source row count';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 2, 0, 1)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD004.[test TC-004-020 failed corporate subscription load re-raises logs Failed and leaves the target unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'1000111', N'SCH-111', N'Omicron Advisory', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL);

    ALTER TABLE Layercake.brnz_corporate_subscription
        ADD CONSTRAINT CK_test_MOD004_brnz_corporate_subscription_reject CHECK (scheme_no <> N'REJECT-112');

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'1000111', N'SCH-111', N'Omicron Advisory', 2025, N'Cancelled', N'Active', N'Round 1'),
           (N'1000112', N'REJECT-112', N'Pi Partners', 2025, N'Active', N'Active', N'Round 1');

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_corporate_subscription;
        EXEC tSQLt.Fail 'usp_load_brnz_corporate_subscription should have raised the check constraint error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'brnz_corporate_subscription must be unchanged after a failed load';

    SELECT l.status, CASE WHEN l.error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

/* Mike, 2026-10-26 (docs/answers.md "MOD-004 NULL matching key"): a source row with a NULL
   matching key fails the whole load with error 515; no row is skipped. FakeTable makes every
   column nullable, so the helper puts NOT NULL back on the three key columns of the fake,
   keeping each column's type and collation. Not a test itself (name does not start with "test"). */
CREATE PROCEDURE test_MOD004.[assert a null key row fails the corporate subscription load]
    @contact_no nvarchar(100),
    @scheme_no nvarchar(100),
    @sub_campaign_year int
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    DECLARE @sql nvarchar(max) = N'';
    SELECT @sql += N'ALTER TABLE Layercake.brnz_corporate_subscription ALTER COLUMN ' + QUOTENAME(c.name) + N' '
                 + TYPE_NAME(c.user_type_id)
                 + CASE WHEN c.collation_name IS NOT NULL
                        THEN N'(' + CAST(c.max_length / 2 AS nvarchar(10)) + N') COLLATE ' + c.collation_name
                        ELSE N'' END
                 + N' NOT NULL; '
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(N'Layercake.brnz_corporate_subscription')
      AND c.name IN (N'contact_no', N'scheme_no', N'sub_campaign_year');
    EXEC sys.sp_executesql @sql;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'1000201', N'SCH-201', N'Rho Surveyors', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL),
           (N'1000202', N'SCH-201', N'Rho Surveyors', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL);

    -- 1000201 changed (update pending), 1000202 gone (soft delete pending), 1000203 new (insert pending),
    -- plus the row with a NULL key.
    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'1000201', N'SCH-201', N'Rho Surveyors', 2025, N'Cancelled', N'Active', N'Round 1'),
           (N'1000203', N'SCH-201', N'Rho Surveyors', 2025, N'Active', N'Active', N'Round 1'),
           (@contact_no, @scheme_no, N'Sigma Partners', @sub_campaign_year, N'Active', N'Active', N'Round 1');

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;

    DECLARE @error int = NULL;
    BEGIN TRY
        EXEC Layercake.usp_load_brnz_corporate_subscription;
    END TRY
    BEGIN CATCH
        SET @error = ERROR_NUMBER();
    END CATCH;

    EXEC tSQLt.AssertEquals 515, @error, 'a NULL matching key must fail the load with error 515 reaching the caller';

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'brnz_corporate_subscription must be unchanged: no row skipped, nothing partly applied';

    SELECT l.status, CASE WHEN l.error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD004.[test TC-004-021 a source row with null Contact No fails the load with 515 and changes nothing]
AS
BEGIN
    EXEC test_MOD004.[assert a null key row fails the corporate subscription load] NULL, N'SCH-202', 2025;
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD004.[test TC-004-022 a source row with null Scheme No fails the load with 515 and changes nothing]
AS
BEGIN
    EXEC test_MOD004.[assert a null key row fails the corporate subscription load] N'1000204', NULL, 2025;
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD004.[test TC-004-023 a source row with null Sub Campaign Year fails the load with 515 and changes nothing]
AS
BEGIN
    EXEC test_MOD004.[assert a null key row fails the corporate subscription load] N'1000205', N'SCH-202', NULL;
END;
GO
