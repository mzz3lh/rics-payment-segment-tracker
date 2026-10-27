EXEC tSQLt.NewTestClass 'test_MOD004_dev';
GO

/* ===================== usp_load_brnz_corporate_subscription ===================== */

-- Choice: a source key repeated (Q-033 assumes it is unique) fails the load with 2627 at
-- staging rather than landing one of the rows arbitrarily.
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD004_dev.[test duplicate source key fails the corporate subscription load with 2627 and changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'2000001', N'SCH-301', N'Tau Partners', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL);

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'2000001', N'SCH-301', N'Tau Partners', 2025, N'Cancelled', N'Active', N'Round 1'),
           (N'2000002', N'SCH-301', N'Tau Partners', 2025, N'Active', N'Active', N'Round 1'),
           (N'2000002', N'SCH-301', N'Tau Partners', 2025, N'Active', N'Inactive', N'Round 2');

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_corporate_subscription;
        EXEC tSQLt.Fail 'usp_load_brnz_corporate_subscription should have raised the duplicate key error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 2627 THROW;
    END CATCH;

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'brnz_corporate_subscription must be unchanged after a failed load';

    SELECT l.status, CASE WHEN l.error_message LIKE N'%error 2627%' THEN 1 ELSE 0 END AS has_2627
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.has_2627
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_2627);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

-- Choice: the key columns are also compared as bytes, so a case-only change in Scheme No
-- updates the existing row in place (no second row).
CREATE PROCEDURE test_MOD004_dev.[test case only change in scheme no updates the row in place]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'2000011', N'sch-311', N'Upsilon Ltd', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL);

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'2000011', N'SCH-311', N'Upsilon Ltd', 2025, N'Active', N'Active', NULL);

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT CAST(b.scheme_no AS varbinary(200)) AS scheme_no_bytes, b._loaded_at,
           CASE WHEN b._updated_at > '2020-01-01' THEN 1 ELSE 0 END AS updated_later
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.scheme_no_bytes, CAST(v._loaded_at AS datetime2(3)) AS _loaded_at, v.updated_later
    INTO #Expected
    FROM (VALUES (CAST(N'SCH-311' AS varbinary(200)), '2020-01-01', 1)) AS v(scheme_no_bytes, _loaded_at, updated_later);

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

CREATE PROCEDURE test_MOD004_dev.[test trailing space change in scheme name is landed]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'2000021', N'SCH-321', N'Phi Group', 2025, N'Active', N'Active', '2020-01-01', '2020-01-01', 0, NULL);

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'2000021', N'SCH-321', N'Phi Group ', 2025, N'Active', N'Active', NULL);

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT CAST(b.scheme_name AS varbinary(8000)) AS scheme_name_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.scheme_name_bytes
    INTO #Expected
    FROM (VALUES (CAST(N'Phi Group ' AS varbinary(8000)))) AS v(scheme_name_bytes);

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

-- Choice: restoring a soft-deleted row counts as an update and clears _deleted_at.
CREATE PROCEDURE test_MOD004_dev.[test restored soft deleted row clears deleted at and is logged as one update]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'2000031', N'SCH-331', N'Chi Holdings', 2025, N'Active', N'Active', '2020-01-01', '2020-06-01', 1, '2020-06-01');

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'2000031', N'SCH-331', N'Chi Holdings', 2025, N'Active', N'Active', N'Round 1');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT b._is_deleted, b._deleted_at, b._loaded_at,
           CASE WHEN b._updated_at > '2020-06-01' THEN 1 ELSE 0 END AS updated_later
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v._is_deleted, CAST(v._deleted_at AS datetime2(3)) AS _deleted_at, CAST(v._loaded_at AS datetime2(3)) AS _loaded_at, v.updated_later
    INTO #Expected
    FROM (VALUES (0, NULL, '2020-01-01', 1)) AS v(_is_deleted, _deleted_at, _loaded_at, updated_later);

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

-- Choice: an already soft-deleted row still absent from the source is left as it is
-- (not deleted again, not counted).
CREATE PROCEDURE test_MOD004_dev.[test already soft deleted row still absent is not touched or counted]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (N'2000041', N'SCH-341', N'Psi Realty', 2025, N'Active', N'Active', '2020-01-01', '2020-06-01', 1, '2020-06-01');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT b._is_deleted, b._deleted_at, b._updated_at
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v._is_deleted, CAST(v._deleted_at AS datetime2(3)) AS _deleted_at, CAST(v._updated_at AS datetime2(3)) AS _updated_at
    INTO #Expected
    FROM (VALUES (1, '2020-06-01', '2020-06-01')) AS v(_is_deleted, _deleted_at, _updated_at);

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

/* ===================== usp_load_dim_payer_type ===================== */

-- Choice: the dimension never deletes; an id that left silver stays for facts that point at it.
CREATE PROCEDURE test_MOD004_dev.[test dimension load keeps an id no longer in silver]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type';
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name, created_at, updated_at)
    VALUES (0, 'Unknown', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.dim_payer_type (id, payer_type_name, load_id, created_at, updated_at)
    VALUES (0, 'Unknown', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
           (5, 'Retired type', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00');

    EXEC Layercake.usp_load_dim_payer_type;

    SELECT d.id, d.payer_type_name, d.load_id, d.updated_at
    INTO #Actual
    FROM Layercake.dim_payer_type AS d;

    SELECT v.id, v.payer_type_name, v.load_id, CAST(v.updated_at AS datetime2(3)) AS updated_at
    INTO #Expected
    FROM (VALUES (0, 'Unknown', 7, '2026-02-01 10:00:00'),
                 (5, 'Retired type', 7, '2026-02-01 10:00:00')) AS v(id, payer_type_name, load_id, updated_at);

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

-- Choice: inserted and updated rows carry the etl_run_log.log_id of the load (answers 2026-10-26),
-- and a trailing-space-only name change is an update.
CREATE PROCEDURE test_MOD004_dev.[test dimension load stamps load_id with the log id and lands a trailing space change]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type';
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name, created_at, updated_at)
    VALUES (1, 'Individual', '2026-01-01', '2026-01-01'),
           (2, 'Corporate ', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.dim_payer_type (id, payer_type_name, load_id, created_at, updated_at)
    VALUES (2, 'Corporate', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00');

    EXEC Layercake.usp_load_dim_payer_type;

    SELECT d.id, CAST(d.payer_type_name AS varbinary(30)) AS name_bytes,
           CASE WHEN d.load_id = l.log_id THEN 1 ELSE 0 END AS load_id_is_log_id
    INTO #Actual
    FROM Layercake.dim_payer_type AS d
    CROSS JOIN Layercake.etl_run_log AS l;

    SELECT v.id, v.name_bytes, v.load_id_is_log_id
    INTO #Expected
    FROM (VALUES (1, CAST('Individual' AS varbinary(30)), 1),
                 (2, CAST('Corporate ' AS varbinary(30)), 1)) AS v(id, name_bytes, load_id_is_log_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
