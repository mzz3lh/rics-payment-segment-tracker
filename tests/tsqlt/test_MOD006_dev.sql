EXEC tSQLt.NewTestClass 'test_MOD006_dev';
GO

/* ===================== usp_load_brnz_concession ===================== */

-- Choice: a repeated source key fails at staging with 2627 (answers 2026-10-27), before bronze is touched.
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD006_dev.[test duplicate source key fails the concession bronze load with 2627 and changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_concession
        (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('B0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2020-01-01', '2020-01-01', 0, NULL);

    INSERT INTO CE.vwConcessionType (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('C0000000-0000-0000-0000-000000000001', 'B0000000-0000-0000-0000-000000000001', N'Retired Member', 100.00, N'rcsCONRETIRED', 0, 200000000),
           ('C0000000-0000-0000-0000-000000000002', 'B0000000-0000-0000-0000-000000000002', N'Hardship', 50.00, N'rcsCONHARDSHIP', 0, 200000001),
           ('C0000000-0000-0000-0000-000000000003', 'B0000000-0000-0000-0000-000000000002', N'Hardship Relief', 50.00, N'rcsCONHARDSHIP', 0, 200000001);

    SELECT * INTO #Before FROM Layercake.brnz_concession;

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_concession;
        EXEC tSQLt.Fail 'usp_load_brnz_concession should have raised the duplicate key error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 2627 THROW;
    END CATCH;

    SELECT * INTO #After FROM Layercake.brnz_concession;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'brnz_concession must be unchanged after a failed load';

    SELECT l.status, CASE WHEN l.error_message LIKE N'%error 2627%' THEN 1 ELSE 0 END AS has_2627
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.has_2627
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_2627);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

-- Choice: a NULL source key fails at staging with 515 (answers 2026-10-27), even when the target allows it.
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD006_dev.[test null source key fails the concession bronze load with 515 and changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_concession
        (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('B0000000-0000-0000-0000-000000000011', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2020-01-01', '2020-01-01', 0, NULL);

    INSERT INTO CE.vwConcessionType (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('C0000000-0000-0000-0000-000000000011', 'B0000000-0000-0000-0000-000000000011', N'Retired Member', 100.00, N'rcsCONRETIRED', 0, 200000000),
           ('C0000000-0000-0000-0000-000000000012', NULL, N'Orphan Type', 10.00, N'rcsCONORPHAN', 0, NULL);

    SELECT * INTO #Before FROM Layercake.brnz_concession;

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_concession;
        EXEC tSQLt.Fail 'usp_load_brnz_concession should have raised the NULL key error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515 THROW;
    END CATCH;

    SELECT * INTO #After FROM Layercake.brnz_concession;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'brnz_concession must be unchanged after a failed load';

    SELECT l.status, CASE WHEN l.error_message LIKE N'%error 515%' THEN 1 ELSE 0 END AS has_515
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.has_515
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_515);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

-- Choice: a trailing-space-only name change is landed (byte compare) and counted as one update;
-- restoring a soft-deleted row is also one update and clears _deleted_at.
CREATE PROCEDURE test_MOD006_dev.[test trailing space change and restore are each one update in bronze]
AS
BEGIN
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_concession
        (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('B0000000-0000-0000-0000-000000000021', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2020-01-01', '2020-01-01', 0, NULL),
           ('B0000000-0000-0000-0000-000000000022', N'Hardship', 50.00, N'rcsCONHARDSHIP', 0, 200000001, '2020-01-01', '2020-06-01', 1, '2020-06-01');

    INSERT INTO CE.vwConcessionType (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('C0000000-0000-0000-0000-000000000021', 'B0000000-0000-0000-0000-000000000021', N'Retired ', 100.00, N'rcsCONRETIRED', 0, 200000000),
           ('C0000000-0000-0000-0000-000000000022', 'B0000000-0000-0000-0000-000000000022', N'Hardship', 50.00, N'rcsCONHARDSHIP', 0, 200000001);

    EXEC Layercake.usp_load_brnz_concession;

    SELECT b.apuk_concessiontypeid, CAST(b.apuk_name AS varbinary(200)) AS name_bytes, b._is_deleted, b._deleted_at,
           b._loaded_at, CASE WHEN b._updated_at > '2020-06-01' THEN 1 ELSE 0 END AS updated_later
    INTO #Actual
    FROM Layercake.brnz_concession AS b;

    SELECT CAST(v.id AS uniqueidentifier) AS apuk_concessiontypeid, v.name_bytes, v._is_deleted,
           CAST(v._deleted_at AS datetime2(3)) AS _deleted_at, CAST(v._loaded_at AS datetime2(3)) AS _loaded_at, v.updated_later
    INTO #Expected
    FROM (VALUES ('B0000000-0000-0000-0000-000000000021', CAST(N'Retired ' AS varbinary(200)), 0, NULL, '2020-01-01', 1),
                 ('B0000000-0000-0000-0000-000000000022', CAST(N'Hardship' AS varbinary(200)), 0, NULL, '2020-01-01', 1))
         AS v(id, name_bytes, _is_deleted, _deleted_at, _loaded_at, updated_later);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 2, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

/* ===================== usp_load_silv_ref_concession_type ===================== */

-- Choice: an item code longer than the designed nvarchar(100) fails the load (truncation error)
-- rather than being cut; the list, including a pending rename, is left unchanged.
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD006_dev.[test over long item code fails the concession type load and changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    SET IDENTITY_INSERT Layercake.silv_ref_concession_type ON;
    INSERT INTO Layercake.silv_ref_concession_type
        (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (2, 'B0000000-0000-0000-0000-000000000031', N'Hardship', N'CONHARDSHIP', 0, 0, 5, '2026-01-01', '2026-01-01');
    SET IDENTITY_INSERT Layercake.silv_ref_concession_type OFF;

    INSERT INTO Layercake.brnz_concession
        (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('B0000000-0000-0000-0000-000000000031', N'Hardship Relief', 50.00, N'rcsCONHARDSHIP', 0, 200000001, '2020-01-01', '2020-01-01', 0, NULL),
           ('B0000000-0000-0000-0000-000000000032', N'Long Code', 10.00, N'rcs' + REPLICATE(N'X', 101), 0, NULL, '2020-01-01', '2020-01-01', 0, NULL);

    SELECT * INTO #Before FROM Layercake.silv_ref_concession_type;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_ref_concession_type;
        EXEC tSQLt.Fail 'usp_load_silv_ref_concession_type should have raised the truncation error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2628, 8152) THROW;
    END CATCH;

    SELECT * INTO #After FROM Layercake.silv_ref_concession_type;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'silv_ref_concession_type must be unchanged after a failed load';

    SELECT l.status, CASE WHEN l.error_message IS NOT NULL THEN 1 ELSE 0 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

-- Choice: the 'rcs' prefix is matched as the collation compares (case-insensitive) and only at the start.
CREATE PROCEDURE test_MOD006_dev.[test rcs prefix is removed in any case and only at the start]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_concession
        (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('B0000000-0000-0000-0000-000000000041', N'Upper', 10.00, N'RCSCONUPPER', 0, NULL, '2020-01-01', '2020-01-01', 0, NULL),
           ('B0000000-0000-0000-0000-000000000042', N'Middle', 10.00, N'CONrcsMIDDLE', 0, NULL, '2020-01-01', '2020-01-01', 0, NULL),
           ('B0000000-0000-0000-0000-000000000043', N'Spaced', 10.00, N' rcsCONSPACED', 0, NULL, '2020-01-01', '2020-01-01', 0, NULL);

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT t.concession_type_bk, CAST(t.item_code AS varbinary(200)) AS item_code_bytes
    INTO #Actual
    FROM Layercake.silv_ref_concession_type AS t;

    SELECT CAST(v.bk AS uniqueidentifier) AS concession_type_bk, v.item_code_bytes
    INTO #Expected
    FROM (VALUES ('B0000000-0000-0000-0000-000000000041', CAST(N'CONUPPER' AS varbinary(200))),
                 ('B0000000-0000-0000-0000-000000000042', CAST(N'CONrcsMIDDLE' AS varbinary(200))),
                 ('B0000000-0000-0000-0000-000000000043', CAST(N' rcsCONSPACED' AS varbinary(200)))) AS v(bk, item_code_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

-- Choice: a type that left bronze (soft-deleted) keeps its row, values and load_id; the seeded
-- rows are never touched; a case-only rename is an update stamped with the run's log_id.
CREATE PROCEDURE test_MOD006_dev.[test soft deleted type and seeded rows are kept and a case only rename is stamped with the log id]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    SET IDENTITY_INSERT Layercake.silv_ref_concession_type ON;
    INSERT INTO Layercake.silv_ref_concession_type
        (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (1, NULL, N'No concession', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (2, 'B0000000-0000-0000-0000-000000000051', N'Retired', N'CONRETIRED', 1, 1, 5, '2026-01-01', '2026-01-01'),
           (3, 'B0000000-0000-0000-0000-000000000052', N'Withdrawn', N'CONWITHDRAWN', 0, 0, 5, '2026-01-01', '2026-01-01');
    SET IDENTITY_INSERT Layercake.silv_ref_concession_type OFF;

    INSERT INTO Layercake.brnz_concession
        (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('B0000000-0000-0000-0000-000000000051', N'RETIRED', 100.00, N'rcsCONRETIRED', 0, 200000000, '2020-01-01', '2020-01-01', 0, NULL),
           ('B0000000-0000-0000-0000-000000000052', N'Withdrawn Renamed', 0.00, N'rcsCONOTHER', 0, NULL, '2020-01-01', '2020-01-01', 1, '2020-06-01');

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT t.id, CAST(t.concession_type_name AS varbinary(200)) AS name_bytes,
           CASE WHEN t.load_id = l.log_id THEN -1 ELSE t.load_id END AS load_id_or_log
    INTO #Actual
    FROM Layercake.silv_ref_concession_type AS t
    CROSS JOIN Layercake.etl_run_log AS l;

    SELECT v.id, v.name_bytes, v.load_id_or_log
    INTO #Expected
    FROM (VALUES (1, CAST(N'No concession' AS varbinary(200)), NULL),
                 (2, CAST(N'RETIRED' AS varbinary(200)), -1),
                 (3, CAST(N'Withdrawn' AS varbinary(200)), 5)) AS v(id, name_bytes, load_id_or_log);

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

/* ===================== usp_load_dim_concession_type ===================== */

-- Choice: the dimension never deletes an id that left silver, and a flag-only change is one update.
CREATE PROCEDURE test_MOD006_dev.[test dimension keeps an id no longer in silver and counts a flag only change as one update]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type';
    EXEC tSQLt.FakeTable 'Layercake.dim_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_concession_type
        (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (5, 'B0000000-0000-0000-0000-000000000061', N'Retired', N'CONRETIRED', 1, 1, NULL, '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.dim_concession_type (id, concession_type_name, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (5, N'Retired', 1, 0, 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
           (9, N'Gone type', 0, 0, 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00');

    EXEC Layercake.usp_load_dim_concession_type;

    SELECT d.id, d.concession_type_name, d.is_full_concession, d.is_perpetual,
           CASE WHEN d.load_id = l.log_id THEN -1 ELSE d.load_id END AS load_id_or_log
    INTO #Actual
    FROM Layercake.dim_concession_type AS d
    CROSS JOIN Layercake.etl_run_log AS l;

    SELECT v.id, v.concession_type_name, CAST(v.is_full_concession AS bit) AS is_full_concession,
           CAST(v.is_perpetual AS bit) AS is_perpetual, CAST(v.load_id_or_log AS bigint) AS load_id_or_log
    INTO #Expected
    FROM (VALUES (5, N'Retired', 1, 1, -1),
                 (9, N'Gone type', 0, 0, 7)) AS v(id, concession_type_name, is_full_concession, is_perpetual, load_id_or_log);

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
