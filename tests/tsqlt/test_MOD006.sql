EXEC tSQLt.NewTestClass 'test_MOD006';
GO

CREATE PROCEDURE test_MOD006.[fake and seed silv_ref_concession_type]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type', @Identity = 1, @Defaults = 1;
    DECLARE @sql nvarchar(max) = N'INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at) VALUES '
        + N'(0, NULL, N''Unknown'', NULL, 0, 0, NULL, ''2026-01-01T09:00:00'', ''2026-01-01T09:00:00''), '
        + N'(-1, NULL, N''Unrecognised'', NULL, 0, 0, NULL, ''2026-01-01T09:00:00'', ''2026-01-01T09:00:00''), '
        + N'(-2, NULL, N''Not applicable'', NULL, 0, 0, NULL, ''2026-01-01T09:00:00'', ''2026-01-01T09:00:00''), '
        + N'(1, NULL, N''No concession'', NULL, 0, 0, NULL, ''2026-01-01T09:00:00'', ''2026-01-01T09:00:00'');';
    IF COLUMNPROPERTY(OBJECT_ID(N'Layercake.silv_ref_concession_type'), N'id', 'IsIdentity') = 1
        SET @sql = N'SET IDENTITY_INSERT Layercake.silv_ref_concession_type ON; ' + @sql + N' SET IDENTITY_INSERT Layercake.silv_ref_concession_type OFF;';
    EXEC sys.sp_executesql @sql;
END;
GO

/* ===================== Bronze: usp_load_brnz_concession ===================== */

CREATE PROCEDURE test_MOD006.[test TC-006-001 first concession bronze load lands three source types 1:1 live and logs Success]
AS
BEGIN
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO CE.vwConcessionType (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('A0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000),
           ('A0000000-0000-0000-0000-000000000002', 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001),
           ('A0000000-0000-0000-0000-000000000003', 'A0000000-0000-0000-0000-000000000003', N'Life Member', 100.00, N'rcsCONLIFEMEMBER', 0, NULL);

    EXEC Layercake.usp_load_brnz_concession;

    SELECT apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _is_deleted,
           CASE WHEN _deleted_at IS NULL THEN 1 ELSE 0 END AS deleted_at_is_null,
           CASE WHEN _loaded_at IS NOT NULL AND _updated_at IS NOT NULL THEN 1 ELSE 0 END AS audit_times_set
    INTO #Actual
    FROM Layercake.brnz_concession;

    CREATE TABLE #Expected (apuk_concessiontypeid uniqueidentifier, apuk_name nvarchar(100), apuk_discount decimal(38,2), product_number nvarchar(4000), statecode int, apuk_perpetualnonperpetual int, _is_deleted bit, deleted_at_is_null int, audit_times_set int);
    INSERT INTO #Expected (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _is_deleted, deleted_at_is_null, audit_times_set)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, 0, 1, 1),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, 0, 1, 1),
           ('A0000000-0000-0000-0000-000000000003', N'Life Member', 100.00, N'rcsCONLIFEMEMBER', 0, NULL, 0, 1, 1);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), rows_inserted int, rows_updated int, rows_deleted int);
    INSERT INTO #ExpectedLog (status, rows_inserted, rows_updated, rows_deleted) VALUES ('Success', 3, 0, 0);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-002 null and untrimmed source values land byte for byte in bronze]
AS
BEGIN
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO CE.vwConcessionType (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('A0000000-0000-0000-0000-000000000031', 'A0000000-0000-0000-0000-000000000031', NULL, NULL, NULL, NULL, NULL),
           ('A0000000-0000-0000-0000-000000000032', 'A0000000-0000-0000-0000-000000000032', N' hardship ', 25.50, N'rcsCONhardship', 1, 200000001);

    EXEC Layercake.usp_load_brnz_concession;

    SELECT apuk_concessiontypeid,
           CAST(apuk_name AS varbinary(200)) AS apuk_name_bytes,
           apuk_discount,
           CAST(product_number AS varbinary(200)) AS product_number_bytes,
           statecode, apuk_perpetualnonperpetual, _is_deleted
    INTO #Actual
    FROM Layercake.brnz_concession;

    CREATE TABLE #Expected (apuk_concessiontypeid uniqueidentifier, apuk_name_bytes varbinary(200), apuk_discount decimal(38,2), product_number_bytes varbinary(200), statecode int, apuk_perpetualnonperpetual int, _is_deleted bit);
    INSERT INTO #Expected (apuk_concessiontypeid, apuk_name_bytes, apuk_discount, product_number_bytes, statecode, apuk_perpetualnonperpetual, _is_deleted)
    VALUES ('A0000000-0000-0000-0000-000000000031', NULL, NULL, NULL, NULL, NULL, 0),
           ('A0000000-0000-0000-0000-000000000032', CAST(N' hardship ' AS varbinary(200)), 25.50, CAST(N'rcsCONhardship' AS varbinary(200)), 1, 200000001, 0);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-003 second concession bronze load on unchanged source changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO CE.vwConcessionType (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('A0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000),
           ('A0000000-0000-0000-0000-000000000002', 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001),
           ('A0000000-0000-0000-0000-000000000031', 'A0000000-0000-0000-0000-000000000031', NULL, NULL, NULL, NULL, NULL);

    EXEC Layercake.usp_load_brnz_concession;
    SELECT * INTO #First FROM Layercake.brnz_concession;

    EXEC Layercake.usp_load_brnz_concession;
    SELECT * INTO #Second FROM Layercake.brnz_concession;

    EXEC tSQLt.AssertEqualsTable '#First', '#Second';

    SELECT status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), rows_inserted int, rows_updated int, rows_deleted int);
    INSERT INTO #ExpectedLog (status, rows_inserted, rows_updated, rows_deleted) VALUES ('Success', 3, 0, 0), ('Success', 0, 0, 0);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-004 renamed source type is updated in bronze and only it gets a new _updated_at]
AS
BEGIN
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    INSERT INTO CE.vwConcessionType (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('A0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000),
           ('A0000000-0000-0000-0000-000000000002', 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship Relief', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001);

    EXEC Layercake.usp_load_brnz_concession;

    SELECT apuk_concessiontypeid, apuk_name, _is_deleted, _loaded_at,
           CASE WHEN _updated_at > '2020-01-01T00:00:00' THEN 'later' WHEN _updated_at = '2020-01-01T00:00:00' THEN 'unchanged' ELSE 'other' END AS updated_at_state
    INTO #Actual
    FROM Layercake.brnz_concession;

    CREATE TABLE #Expected (apuk_concessiontypeid uniqueidentifier, apuk_name nvarchar(100), _is_deleted bit, _loaded_at datetime2(3), updated_at_state varchar(10));
    INSERT INTO #Expected (apuk_concessiontypeid, apuk_name, _is_deleted, _loaded_at, updated_at_state)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 0, '2020-01-01T00:00:00', 'unchanged'),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship Relief', 0, '2020-01-01T00:00:00', 'later');
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), rows_inserted int, rows_updated int, rows_deleted int);
    INSERT INTO #ExpectedLog (status, rows_inserted, rows_updated, rows_deleted) VALUES ('Success', 0, 1, 0);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-005 type gone from source is soft deleted and live bronze rows reconcile to the source count]
AS
BEGIN
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    INSERT INTO CE.vwConcessionType (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('A0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000),
           ('A0000000-0000-0000-0000-000000000003', 'A0000000-0000-0000-0000-000000000003', N'Life Member', 100.00, N'rcsCONLIFEMEMBER', 0, NULL);

    EXEC Layercake.usp_load_brnz_concession;

    SELECT apuk_concessiontypeid, apuk_name, _is_deleted,
           CASE WHEN _deleted_at IS NULL THEN 0 ELSE 1 END AS deleted_at_set
    INTO #Actual
    FROM Layercake.brnz_concession;

    CREATE TABLE #Expected (apuk_concessiontypeid uniqueidentifier, apuk_name nvarchar(100), _is_deleted bit, deleted_at_set int);
    INSERT INTO #Expected (apuk_concessiontypeid, apuk_name, _is_deleted, deleted_at_set)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 0, 0),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 1, 1),
           ('A0000000-0000-0000-0000-000000000003', N'Life Member', 0, 0);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @live int = (SELECT COUNT(*) FROM Layercake.brnz_concession WHERE _is_deleted = 0);
    EXEC tSQLt.AssertEquals 2, @live;

    SELECT status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), rows_inserted int, rows_updated int, rows_deleted int);
    INSERT INTO #ExpectedLog (status, rows_inserted, rows_updated, rows_deleted) VALUES ('Success', 1, 0, 1);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-006 soft deleted type that reappears unchanged is restored not inserted again]
AS
BEGIN
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, '2020-01-01T00:00:00', '2020-06-01T00:00:00', 1, '2020-06-01T00:00:00');

    INSERT INTO CE.vwConcessionType (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('A0000000-0000-0000-0000-000000000002', 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001);

    EXEC Layercake.usp_load_brnz_concession;

    SELECT apuk_concessiontypeid, apuk_name, apuk_discount, product_number, _is_deleted,
           CASE WHEN _deleted_at IS NULL THEN 1 ELSE 0 END AS deleted_at_is_null
    INTO #Actual
    FROM Layercake.brnz_concession;

    CREATE TABLE #Expected (apuk_concessiontypeid uniqueidentifier, apuk_name nvarchar(100), apuk_discount decimal(38,2), product_number nvarchar(4000), _is_deleted bit, deleted_at_is_null int);
    INSERT INTO #Expected (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, _is_deleted, deleted_at_is_null)
    VALUES ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 1);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @status varchar(10) = (SELECT MAX(status) FROM Layercake.etl_run_log);
    EXEC tSQLt.AssertEqualsString 'Success', @status;
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD006.[test TC-006-007 a source row with null apuk_concessiontypeid fails the bronze load and changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    ALTER TABLE Layercake.brnz_concession ALTER COLUMN apuk_concessiontypeid uniqueidentifier NOT NULL;

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    INSERT INTO CE.vwConcessionType (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('A0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000001', N'Retired Member', 100.00, N'rcsCONRETIRED', 0, 200000000),
           ('A0000000-0000-0000-0000-000000000003', 'A0000000-0000-0000-0000-000000000003', N'Life Member', 100.00, N'rcsCONLIFEMEMBER', 0, NULL),
           ('A0000000-0000-0000-0000-000000000099', NULL, N'Orphan Type', 25.00, N'rcsCONORPHAN', 0, 200000001);

    SELECT * INTO #Before FROM Layercake.brnz_concession;

    DECLARE @raised bit = 0;
    BEGIN TRY
        EXEC Layercake.usp_load_brnz_concession;
    END TRY
    BEGIN CATCH
        SET @raised = 1;
    END CATCH;
    IF @raised = 0
        EXEC tSQLt.Fail 'usp_load_brnz_concession did not raise an error for a source row with a NULL apuk_concessiontypeid';

    SELECT * INTO #After FROM Layercake.brnz_concession;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT status, CASE WHEN error_message IS NULL THEN 0 ELSE 1 END AS has_error_message INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), has_error_message int);
    INSERT INTO #ExpectedLog (status, has_error_message) VALUES ('Failed', 1);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD006.[test TC-006-008 two source rows with the same apuk_concessiontypeid fail the bronze load and change nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    ALTER TABLE Layercake.brnz_concession ALTER COLUMN apuk_concessiontypeid uniqueidentifier NOT NULL;
    ALTER TABLE Layercake.brnz_concession ADD CONSTRAINT test_MOD006_pk_brnz_concession PRIMARY KEY (apuk_concessiontypeid);

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2020-01-01T00:00:00', '2020-01-01T00:00:00', 0, NULL);

    INSERT INTO CE.vwConcessionType (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('A0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000001', N'Retired Member', 100.00, N'rcsCONRETIRED', 0, 200000000),
           ('A0000000-0000-0000-0000-000000000092', 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001),
           ('A0000000-0000-0000-0000-000000000093', 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship Relief', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001);

    SELECT * INTO #Before FROM Layercake.brnz_concession;

    DECLARE @raised bit = 0;
    BEGIN TRY
        EXEC Layercake.usp_load_brnz_concession;
    END TRY
    BEGIN CATCH
        SET @raised = 1;
    END CATCH;
    IF @raised = 0
        EXEC tSQLt.Fail 'usp_load_brnz_concession did not raise an error for two source rows with the same apuk_concessiontypeid';

    SELECT * INTO #After FROM Layercake.brnz_concession;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT status, CASE WHEN error_message IS NULL THEN 0 ELSE 1 END AS has_error_message INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), has_error_message int);
    INSERT INTO #ExpectedLog (status, has_error_message) VALUES ('Failed', 1);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-009 brnz_concession has no apuk_dualmembership column]
AS
BEGIN
    DECLARE @exists int = CASE WHEN OBJECT_ID(N'Layercake.brnz_concession', N'U') IS NULL THEN 0 ELSE 1 END;
    EXEC tSQLt.AssertEquals 1, @exists;

    DECLARE @dual int = (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N'Layercake.brnz_concession') AND name LIKE N'%dualmembership%');
    EXEC tSQLt.AssertEquals 0, @dual;
END;
GO

/* ===================== Silver: silv_ref_concession_type and its load ===================== */

CREATE PROCEDURE test_MOD006.[test TC-006-010 seeded concession type list holds the three reserved rows and No concession]
AS
BEGIN
    SELECT CASE WHEN id IN (0, -1, -2) THEN id END AS reserved_id,
           CAST(concession_type_name AS varbinary(200)) AS name_bytes,
           is_full_concession, is_perpetual
    INTO #Actual
    FROM Layercake.silv_ref_concession_type
    WHERE concession_type_bk IS NULL;

    CREATE TABLE #Expected (reserved_id int, name_bytes varbinary(200), is_full_concession bit, is_perpetual bit);
    INSERT INTO #Expected (reserved_id, name_bytes, is_full_concession, is_perpetual)
    VALUES (0, CAST(N'Unknown' AS varbinary(200)), 0, 0),
           (-1, CAST(N'Unrecognised' AS varbinary(200)), 0, 0),
           (-2, CAST(N'Not applicable' AS varbinary(200)), 0, 0),
           (NULL, CAST(N'No concession' AS varbinary(200)), 0, 0);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-011 three source types give seven rows with item codes and full concession flags]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000003', N'Life Member', 100.00, N'rcsCONLIFEMEMBER', 0, NULL, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL);

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT CASE WHEN concession_type_bk IS NULL THEN id END AS seeded_id,
           concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual
    INTO #Actual
    FROM Layercake.silv_ref_concession_type;

    CREATE TABLE #Expected (seeded_id int, concession_type_bk uniqueidentifier, concession_type_name nvarchar(100), item_code nvarchar(100), is_full_concession bit, is_perpetual bit);
    INSERT INTO #Expected (seeded_id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0),
           (-1, NULL, N'Unrecognised', NULL, 0, 0),
           (-2, NULL, N'Not applicable', NULL, 0, 0),
           (1, NULL, N'No concession', NULL, 0, 0),
           (NULL, 'A0000000-0000-0000-0000-000000000001', N'Retired', N'CONRETIRED', 1, 1),
           (NULL, 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', N'CONEXCEPTIONHP', 0, 0),
           (NULL, 'A0000000-0000-0000-0000-000000000003', N'Life Member', N'CONLIFEMEMBER', 1, 0);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @new_ids int = (SELECT COUNT(DISTINCT id) FROM Layercake.silv_ref_concession_type
                            WHERE concession_type_bk IS NOT NULL AND id IS NOT NULL AND id NOT IN (0, -1, -2, 1));
    EXEC tSQLt.AssertEquals 3, @new_ids;

    DECLARE @log_id bigint = (SELECT MAX(log_id) FROM Layercake.etl_run_log);
    DECLARE @wrong_load_id int = (SELECT COUNT(*) FROM Layercake.silv_ref_concession_type
                                  WHERE concession_type_bk IS NOT NULL AND (load_id IS NULL OR load_id <> @log_id));
    EXEC tSQLt.AssertEquals 0, @wrong_load_id;

    SELECT status, rows_inserted, rows_updated INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), rows_inserted int, rows_updated int);
    INSERT INTO #ExpectedLog (status, rows_inserted, rows_updated) VALUES ('Success', 3, 0);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-012 renamed type is updated in place on its existing id and other rows are untouched]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000003', N'Life Member', 100.00, N'rcsCONLIFEMEMBER', 0, NULL, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL);

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at
    INTO #Before
    FROM Layercake.silv_ref_concession_type;
    DECLARE @eh_id int = (SELECT id FROM #Before WHERE concession_type_bk = 'A0000000-0000-0000-0000-000000000002');
    DELETE FROM Layercake.etl_run_log;

    UPDATE Layercake.brnz_concession
    SET apuk_name = N'Exceptional Hardship Relief', _updated_at = '2026-02-01T00:00:00'
    WHERE apuk_concessiontypeid = 'A0000000-0000-0000-0000-000000000002';

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at
    INTO #ExpectedOthers
    FROM #Before
    WHERE concession_type_bk IS NULL OR concession_type_bk <> 'A0000000-0000-0000-0000-000000000002';
    SELECT id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at
    INTO #ActualOthers
    FROM Layercake.silv_ref_concession_type
    WHERE concession_type_bk IS NULL OR concession_type_bk <> 'A0000000-0000-0000-0000-000000000002';
    EXEC tSQLt.AssertEqualsTable '#ExpectedOthers', '#ActualOthers';

    SELECT id, concession_type_name, item_code, is_full_concession, is_perpetual
    INTO #ActualEH
    FROM Layercake.silv_ref_concession_type
    WHERE concession_type_bk = 'A0000000-0000-0000-0000-000000000002';
    CREATE TABLE #ExpectedEH (id int, concession_type_name nvarchar(100), item_code nvarchar(100), is_full_concession bit, is_perpetual bit);
    INSERT INTO #ExpectedEH (id, concession_type_name, item_code, is_full_concession, is_perpetual)
    VALUES (@eh_id, N'Exceptional Hardship Relief', N'CONEXCEPTIONHP', 0, 0);
    EXEC tSQLt.AssertEqualsTable '#ExpectedEH', '#ActualEH';

    SELECT status, rows_inserted, rows_updated INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), rows_inserted int, rows_updated int);
    INSERT INTO #ExpectedLog (status, rows_inserted, rows_updated) VALUES ('Success', 0, 1);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-013 a fourth source type adds one row with a new id and the seven existing ids are unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000003', N'Life Member', 100.00, N'rcsCONLIFEMEMBER', 0, NULL, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL);

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at
    INTO #Before
    FROM Layercake.silv_ref_concession_type;
    DELETE FROM Layercake.etl_run_log;

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000004', N'Maternity Leave', 75.00, N'rcsCONMATERNITY', 0, 200000001, '2026-02-01T00:00:00', '2026-02-01T00:00:00', 0, NULL);

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at
    INTO #ActualExisting
    FROM Layercake.silv_ref_concession_type
    WHERE concession_type_bk IS NULL OR concession_type_bk <> 'A0000000-0000-0000-0000-000000000004';
    EXEC tSQLt.AssertEqualsTable '#Before', '#ActualExisting';

    SELECT concession_type_name, item_code, is_full_concession, is_perpetual,
           CASE WHEN id IS NOT NULL AND id NOT IN (SELECT b.id FROM #Before AS b) THEN 1 ELSE 0 END AS has_new_id
    INTO #ActualNew
    FROM Layercake.silv_ref_concession_type
    WHERE concession_type_bk = 'A0000000-0000-0000-0000-000000000004';
    CREATE TABLE #ExpectedNew (concession_type_name nvarchar(100), item_code nvarchar(100), is_full_concession bit, is_perpetual bit, has_new_id int);
    INSERT INTO #ExpectedNew (concession_type_name, item_code, is_full_concession, is_perpetual, has_new_id)
    VALUES (N'Maternity Leave', N'CONMATERNITY', 0, 0, 1);
    EXEC tSQLt.AssertEqualsTable '#ExpectedNew', '#ActualNew';

    DECLARE @rows int = (SELECT COUNT(*) FROM Layercake.silv_ref_concession_type);
    EXEC tSQLt.AssertEquals 8, @rows;

    SELECT status, rows_inserted, rows_updated INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), rows_inserted int, rows_updated int);
    INSERT INTO #ExpectedLog (status, rows_inserted, rows_updated) VALUES ('Success', 1, 0);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-014 second concession type load on unchanged bronze changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000021', NULL, 30.00, NULL, 0, NULL, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL);

    EXEC Layercake.usp_load_silv_ref_concession_type;
    SELECT * INTO #First FROM Layercake.silv_ref_concession_type;

    EXEC Layercake.usp_load_silv_ref_concession_type;
    SELECT * INTO #Second FROM Layercake.silv_ref_concession_type;

    EXEC tSQLt.AssertEqualsTable '#First', '#Second';

    SELECT status, rows_inserted, rows_updated INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), rows_inserted int, rows_updated int);
    INSERT INTO #ExpectedLog (status, rows_inserted, rows_updated) VALUES ('Success', 3, 0), ('Success', 0, 0);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-015 item code is the product number with the rcs prefix removed]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000005', N'Staff Member', 100.00, N'CONSTAFFMEMBER', 0, 200000001, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL);

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT concession_type_bk, CAST(item_code AS varbinary(200)) AS item_code_bytes
    INTO #Actual
    FROM Layercake.silv_ref_concession_type
    WHERE concession_type_bk IS NOT NULL;

    CREATE TABLE #Expected (concession_type_bk uniqueidentifier, item_code_bytes varbinary(200));
    INSERT INTO #Expected (concession_type_bk, item_code_bytes)
    VALUES ('A0000000-0000-0000-0000-000000000001', CAST(N'CONRETIRED' AS varbinary(200))),
           ('A0000000-0000-0000-0000-000000000005', CAST(N'CONSTAFFMEMBER' AS varbinary(200)));
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-016 is_full_concession is 1 only for a discount of exactly 100]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000011', N'Full Rate Relief', 100.00, N'rcsCONFULL', 0, 200000001, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000012', N'Near Full Relief', 99.99, N'rcsCONNEARFULL', 0, 200000001, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000013', N'No Discount Recorded', NULL, N'rcsCONNODISC', 0, 200000001, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000014', N'Zero Discount', 0.00, N'rcsCONZERO', 0, 200000001, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL);

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT concession_type_bk, is_full_concession
    INTO #Actual
    FROM Layercake.silv_ref_concession_type
    WHERE concession_type_bk IS NOT NULL;

    CREATE TABLE #Expected (concession_type_bk uniqueidentifier, is_full_concession bit);
    INSERT INTO #Expected (concession_type_bk, is_full_concession)
    VALUES ('A0000000-0000-0000-0000-000000000011', 1),
           ('A0000000-0000-0000-0000-000000000012', 0),
           ('A0000000-0000-0000-0000-000000000013', 0),
           ('A0000000-0000-0000-0000-000000000014', 0);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-017 is_perpetual is 1 for 200000000 and 0 for 200000001 and null]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000003', N'Life Member', 100.00, N'rcsCONLIFEMEMBER', 0, NULL, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL);

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT concession_type_name, is_perpetual
    INTO #Actual
    FROM Layercake.silv_ref_concession_type;

    CREATE TABLE #Expected (concession_type_name nvarchar(100), is_perpetual bit);
    INSERT INTO #Expected (concession_type_name, is_perpetual)
    VALUES (N'Unknown', 0), (N'Unrecognised', 0), (N'Not applicable', 0), (N'No concession', 0),
           (N'Retired', 1), (N'Exceptional Hardship', 0), (N'Life Member', 0);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-018 a soft deleted bronze type is not added to the concession type list]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000006', N'Withdrawn Type', 40.00, N'rcsCONWITHDRAWN', 0, 200000001, '2026-01-01T00:00:00', '2026-03-01T00:00:00', 1, '2026-03-01T00:00:00');

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT concession_type_bk, concession_type_name
    INTO #Actual
    FROM Layercake.silv_ref_concession_type;

    CREATE TABLE #Expected (concession_type_bk uniqueidentifier, concession_type_name nvarchar(100));
    INSERT INTO #Expected (concession_type_bk, concession_type_name)
    VALUES (NULL, N'Unknown'), (NULL, N'Unrecognised'), (NULL, N'Not applicable'), (NULL, N'No concession'),
           ('A0000000-0000-0000-0000-000000000001', N'Retired');
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-019 a type with a null empty or blank name is added as Unnamed concession type]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000021', NULL, 100.00, N'rcsCONNONAME', 0, 200000000, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000022', N'', 50.00, N'rcsCONEMPTYNAME', 0, 200000001, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000023', N'   ', 20.00, N'CONBLANKNAME', 0, NULL, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL);

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT concession_type_bk, CAST(concession_type_name AS varbinary(200)) AS name_bytes, item_code, is_full_concession, is_perpetual,
           CASE WHEN id IS NULL THEN 0 ELSE 1 END AS has_id
    INTO #Actual
    FROM Layercake.silv_ref_concession_type
    WHERE concession_type_bk IS NOT NULL;

    CREATE TABLE #Expected (concession_type_bk uniqueidentifier, name_bytes varbinary(200), item_code nvarchar(100), is_full_concession bit, is_perpetual bit, has_id int);
    INSERT INTO #Expected (concession_type_bk, name_bytes, item_code, is_full_concession, is_perpetual, has_id)
    VALUES ('A0000000-0000-0000-0000-000000000021', CAST(N'Unnamed concession type' AS varbinary(200)), N'CONNONAME', 1, 1, 1),
           ('A0000000-0000-0000-0000-000000000022', CAST(N'Unnamed concession type' AS varbinary(200)), N'CONEMPTYNAME', 0, 0, 1),
           ('A0000000-0000-0000-0000-000000000023', CAST(N'Unnamed concession type' AS varbinary(200)), N'CONBLANKNAME', 0, 0, 1);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @status varchar(10) = (SELECT MAX(status) FROM Layercake.etl_run_log);
    EXEC tSQLt.AssertEqualsString 'Success', @status;
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-020 an unnamed type that later gets a name is renamed in place on its id]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000021', NULL, 100.00, N'rcsCONNONAME', 0, 200000000, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL);

    EXEC Layercake.usp_load_silv_ref_concession_type;
    DECLARE @id_before int = (SELECT id FROM Layercake.silv_ref_concession_type WHERE concession_type_bk = 'A0000000-0000-0000-0000-000000000021');
    DELETE FROM Layercake.etl_run_log;

    UPDATE Layercake.brnz_concession
    SET apuk_name = N'Armed Forces', _updated_at = '2026-02-01T00:00:00'
    WHERE apuk_concessiontypeid = 'A0000000-0000-0000-0000-000000000021';

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT id, concession_type_name, item_code, is_full_concession, is_perpetual
    INTO #Actual
    FROM Layercake.silv_ref_concession_type
    WHERE concession_type_bk = 'A0000000-0000-0000-0000-000000000021';

    CREATE TABLE #Expected (id int, concession_type_name nvarchar(100), item_code nvarchar(100), is_full_concession bit, is_perpetual bit);
    INSERT INTO #Expected (id, concession_type_name, item_code, is_full_concession, is_perpetual)
    VALUES (@id_before, N'Armed Forces', N'CONNONAME', 1, 1);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @rows int = (SELECT COUNT(*) FROM Layercake.silv_ref_concession_type);
    EXEC tSQLt.AssertEquals 5, @rows;

    SELECT status, rows_inserted, rows_updated INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), rows_inserted int, rows_updated int);
    INSERT INTO #ExpectedLog (status, rows_inserted, rows_updated) VALUES ('Success', 0, 1);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-021 a changed discount product number and perpetual value update item code and flags in place]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL);

    EXEC Layercake.usp_load_silv_ref_concession_type;
    DECLARE @id_before int = (SELECT id FROM Layercake.silv_ref_concession_type WHERE concession_type_bk = 'A0000000-0000-0000-0000-000000000002');
    DELETE FROM Layercake.etl_run_log;

    UPDATE Layercake.brnz_concession
    SET apuk_discount = 100.00, product_number = N'rcsCONEXCEPTIONFULL', apuk_perpetualnonperpetual = 200000000, _updated_at = '2026-02-01T00:00:00'
    WHERE apuk_concessiontypeid = 'A0000000-0000-0000-0000-000000000002';

    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT id, concession_type_name, item_code, is_full_concession, is_perpetual
    INTO #Actual
    FROM Layercake.silv_ref_concession_type
    WHERE concession_type_bk = 'A0000000-0000-0000-0000-000000000002';

    CREATE TABLE #Expected (id int, concession_type_name nvarchar(100), item_code nvarchar(100), is_full_concession bit, is_perpetual bit);
    INSERT INTO #Expected (id, concession_type_name, item_code, is_full_concession, is_perpetual)
    VALUES (@id_before, N'Exceptional Hardship', N'CONEXCEPTIONFULL', 1, 1);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), rows_inserted int, rows_updated int);
    INSERT INTO #ExpectedLog (status, rows_inserted, rows_updated) VALUES ('Success', 0, 1);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD006.[test TC-006-022 failed concession type load re-raises logs Failed and leaves the list unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, '2026-01-01T00:00:00', '2026-01-01T00:00:00', 0, NULL);

    EXEC Layercake.usp_load_silv_ref_concession_type;
    DELETE FROM Layercake.etl_run_log;

    ALTER TABLE Layercake.silv_ref_concession_type ADD CONSTRAINT test_MOD006_ck_silv_ref_concession_type CHECK (concession_type_name <> N'Rejected type');

    UPDATE Layercake.brnz_concession
    SET apuk_name = N'Exceptional Hardship Relief', _updated_at = '2026-02-01T00:00:00'
    WHERE apuk_concessiontypeid = 'A0000000-0000-0000-0000-000000000002';
    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000009', N'Rejected type', 10.00, N'rcsCONREJECT', 0, 200000001, '2026-02-01T00:00:00', '2026-02-01T00:00:00', 0, NULL);

    SELECT * INTO #Before FROM Layercake.silv_ref_concession_type;

    DECLARE @raised bit = 0, @error_number int;
    BEGIN TRY
        EXEC Layercake.usp_load_silv_ref_concession_type;
    END TRY
    BEGIN CATCH
        SET @raised = 1;
        SET @error_number = ERROR_NUMBER();
    END CATCH;
    IF @raised = 0
        EXEC tSQLt.Fail 'usp_load_silv_ref_concession_type did not raise the check constraint error';
    EXEC tSQLt.AssertEquals 547, @error_number;

    SELECT * INTO #After FROM Layercake.silv_ref_concession_type;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT status, CASE WHEN error_message IS NULL THEN 0 ELSE 1 END AS has_error_message INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), has_error_message int);
    INSERT INTO #ExpectedLog (status, has_error_message) VALUES ('Failed', 1);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

/* ===================== Gold: dim_concession_type and its load ===================== */

CREATE PROCEDURE test_MOD006.[test TC-006-023 first dimension load copies every concession type id name and flags and logs Success]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type';
    EXEC tSQLt.FakeTable 'Layercake.dim_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL, '2026-01-01T09:00:00', '2026-01-01T09:00:00'),
           (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL, '2026-01-01T09:00:00', '2026-01-01T09:00:00'),
           (-2, NULL, N'Not applicable', NULL, 0, 0, NULL, '2026-01-01T09:00:00', '2026-01-01T09:00:00'),
           (1, NULL, N'No concession', NULL, 0, 0, NULL, '2026-01-01T09:00:00', '2026-01-01T09:00:00'),
           (5, 'A0000000-0000-0000-0000-000000000001', N'Retired', N'CONRETIRED', 1, 1, 3, '2026-01-02T09:00:00', '2026-01-02T09:00:00'),
           (6, 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', N'CONEXCEPTIONHP', 0, 0, 3, '2026-01-02T09:00:00', '2026-01-02T09:00:00'),
           (7, 'A0000000-0000-0000-0000-000000000003', N'Life Member', N'CONLIFEMEMBER', 1, 0, 3, '2026-01-02T09:00:00', '2026-01-02T09:00:00');

    EXEC Layercake.usp_load_dim_concession_type;

    SELECT id, CAST(concession_type_name AS varbinary(200)) AS name_bytes, is_full_concession, is_perpetual,
           CASE WHEN load_id IS NULL THEN 0 ELSE 1 END AS has_load_id
    INTO #Actual
    FROM Layercake.dim_concession_type;

    CREATE TABLE #Expected (id int, name_bytes varbinary(200), is_full_concession bit, is_perpetual bit, has_load_id int);
    INSERT INTO #Expected (id, name_bytes, is_full_concession, is_perpetual, has_load_id)
    VALUES (0, CAST(N'Unknown' AS varbinary(200)), 0, 0, 1),
           (-1, CAST(N'Unrecognised' AS varbinary(200)), 0, 0, 1),
           (-2, CAST(N'Not applicable' AS varbinary(200)), 0, 0, 1),
           (1, CAST(N'No concession' AS varbinary(200)), 0, 0, 1),
           (5, CAST(N'Retired' AS varbinary(200)), 1, 1, 1),
           (6, CAST(N'Exceptional Hardship' AS varbinary(200)), 0, 0, 1),
           (7, CAST(N'Life Member' AS varbinary(200)), 1, 0, 1);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), rows_inserted int, rows_updated int);
    INSERT INTO #ExpectedLog (status, rows_inserted, rows_updated) VALUES ('Success', 7, 0);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-024 second dimension load on unchanged silver changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type';
    EXEC tSQLt.FakeTable 'Layercake.dim_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL, '2026-01-01T09:00:00', '2026-01-01T09:00:00'),
           (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL, '2026-01-01T09:00:00', '2026-01-01T09:00:00'),
           (-2, NULL, N'Not applicable', NULL, 0, 0, NULL, '2026-01-01T09:00:00', '2026-01-01T09:00:00'),
           (1, NULL, N'No concession', NULL, 0, 0, NULL, '2026-01-01T09:00:00', '2026-01-01T09:00:00'),
           (5, 'A0000000-0000-0000-0000-000000000001', N'Retired', N'CONRETIRED', 1, 1, 3, '2026-01-02T09:00:00', '2026-01-02T09:00:00'),
           (6, 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', N'CONEXCEPTIONHP', 0, 0, 3, '2026-01-02T09:00:00', '2026-01-02T09:00:00'),
           (7, 'A0000000-0000-0000-0000-000000000003', N'Life Member', N'CONLIFEMEMBER', 1, 0, 3, '2026-01-02T09:00:00', '2026-01-02T09:00:00');

    EXEC Layercake.usp_load_dim_concession_type;
    SELECT * INTO #First FROM Layercake.dim_concession_type;

    EXEC Layercake.usp_load_dim_concession_type;
    SELECT * INTO #Second FROM Layercake.dim_concession_type;

    EXEC tSQLt.AssertEqualsTable '#First', '#Second';

    SELECT status, rows_inserted, rows_updated INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), rows_inserted int, rows_updated int);
    INSERT INTO #ExpectedLog (status, rows_inserted, rows_updated) VALUES ('Success', 7, 0), ('Success', 0, 0);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-025 dimension load inserts a missing id corrects a changed name and flag and leaves unchanged rows untouched]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type';
    EXEC tSQLt.FakeTable 'Layercake.dim_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL, '2026-01-01T09:00:00', '2026-01-01T09:00:00'),
           (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL, '2026-01-01T09:00:00', '2026-01-01T09:00:00'),
           (-2, NULL, N'Not applicable', NULL, 0, 0, NULL, '2026-01-01T09:00:00', '2026-01-01T09:00:00'),
           (1, NULL, N'No concession', NULL, 0, 0, NULL, '2026-01-01T09:00:00', '2026-01-01T09:00:00'),
           (5, 'A0000000-0000-0000-0000-000000000001', N'Retired', N'CONRETIRED', 1, 1, 3, '2026-01-02T09:00:00', '2026-01-02T09:00:00'),
           (6, 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship Relief', N'CONEXCEPTIONHP', 0, 0, 4, '2026-01-02T09:00:00', '2026-02-02T09:00:00'),
           (7, 'A0000000-0000-0000-0000-000000000003', N'Life Member', N'CONLIFEMEMBER', 1, 0, 4, '2026-01-02T09:00:00', '2026-02-02T09:00:00');

    INSERT INTO Layercake.dim_concession_type (id, concession_type_name, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, N'Unknown', 0, 0, 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00'),
           (-1, N'Unrecognised', 0, 0, 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00'),
           (1, N'No concession', 0, 0, 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00'),
           (5, N'Retired', 1, 1, 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00'),
           (6, N'Exceptional Hardship', 0, 0, 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00'),
           (7, N'Life Member', 1, 1, 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    EXEC Layercake.usp_load_dim_concession_type;

    SELECT id, concession_type_name, is_full_concession, is_perpetual
    INTO #Actual
    FROM Layercake.dim_concession_type;

    CREATE TABLE #Expected (id int, concession_type_name nvarchar(100), is_full_concession bit, is_perpetual bit);
    INSERT INTO #Expected (id, concession_type_name, is_full_concession, is_perpetual)
    VALUES (0, N'Unknown', 0, 0), (-1, N'Unrecognised', 0, 0), (-2, N'Not applicable', 0, 0), (1, N'No concession', 0, 0),
           (5, N'Retired', 1, 1), (6, N'Exceptional Hardship Relief', 0, 0), (7, N'Life Member', 1, 0);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT id, load_id, created_at, updated_at
    INTO #ActualUntouched
    FROM Layercake.dim_concession_type
    WHERE id IN (0, -1, 1, 5);
    CREATE TABLE #ExpectedUntouched (id int, load_id bigint, created_at datetime2(3), updated_at datetime2(3));
    INSERT INTO #ExpectedUntouched (id, load_id, created_at, updated_at)
    VALUES (0, 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00'),
           (-1, 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00'),
           (1, 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00'),
           (5, 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');
    EXEC tSQLt.AssertEqualsTable '#ExpectedUntouched', '#ActualUntouched';

    SELECT status, rows_inserted, rows_updated INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), rows_inserted int, rows_updated int);
    INSERT INTO #ExpectedLog (status, rows_inserted, rows_updated) VALUES ('Success', 1, 2);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD006.[test TC-006-026 failed dimension load re-raises logs Failed and leaves the dimension unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type';
    EXEC tSQLt.FakeTable 'Layercake.dim_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    ALTER TABLE Layercake.dim_concession_type ADD CONSTRAINT test_MOD006_ck_dim_concession_type CHECK (concession_type_name <> N'Rejected type');

    INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL, '2026-01-01T09:00:00', '2026-01-01T09:00:00'),
           (6, 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', N'CONEXCEPTIONHP', 0, 0, 3, '2026-01-02T09:00:00', '2026-01-02T09:00:00'),
           (9, 'A0000000-0000-0000-0000-000000000009', N'Rejected type', N'CONREJECT', 0, 0, 3, '2026-01-02T09:00:00', '2026-01-02T09:00:00');

    INSERT INTO Layercake.dim_concession_type (id, concession_type_name, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (6, N'Hardship (old name)', 0, 0, 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    SELECT * INTO #Before FROM Layercake.dim_concession_type;

    DECLARE @raised bit = 0, @error_number int;
    BEGIN TRY
        EXEC Layercake.usp_load_dim_concession_type;
    END TRY
    BEGIN CATCH
        SET @raised = 1;
        SET @error_number = ERROR_NUMBER();
    END CATCH;
    IF @raised = 0
        EXEC tSQLt.Fail 'usp_load_dim_concession_type did not raise the check constraint error';
    EXEC tSQLt.AssertEquals 547, @error_number;

    SELECT * INTO #After FROM Layercake.dim_concession_type;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT status, CASE WHEN error_message IS NULL THEN 0 ELSE 1 END AS has_error_message INTO #ActualLog FROM Layercake.etl_run_log;
    CREATE TABLE #ExpectedLog (status varchar(10), has_error_message int);
    INSERT INTO #ExpectedLog (status, has_error_message) VALUES ('Failed', 1);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

/* ===================== End to end ===================== */

CREATE PROCEDURE test_MOD006.[test TC-006-027 renaming a type in the source and reloading bronze and silver updates its name and keeps every id]
AS
BEGIN
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO CE.vwConcessionType (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('A0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000),
           ('A0000000-0000-0000-0000-000000000002', 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001),
           ('A0000000-0000-0000-0000-000000000003', 'A0000000-0000-0000-0000-000000000003', N'Life Member', 100.00, N'rcsCONLIFEMEMBER', 0, NULL);

    EXEC Layercake.usp_load_brnz_concession;
    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT id, concession_type_bk INTO #IdsBefore FROM Layercake.silv_ref_concession_type;

    UPDATE CE.vwConcessionType
    SET apuk_name = N'Exceptional Hardship Relief'
    WHERE apuk_concessiontypeid = 'A0000000-0000-0000-0000-000000000002';

    EXEC Layercake.usp_load_brnz_concession;
    EXEC Layercake.usp_load_silv_ref_concession_type;

    SELECT id, concession_type_bk INTO #IdsAfter FROM Layercake.silv_ref_concession_type;
    EXEC tSQLt.AssertEqualsTable '#IdsBefore', '#IdsAfter';

    SELECT concession_type_bk, concession_type_name INTO #ActualNames FROM Layercake.silv_ref_concession_type;
    CREATE TABLE #ExpectedNames (concession_type_bk uniqueidentifier, concession_type_name nvarchar(100));
    INSERT INTO #ExpectedNames (concession_type_bk, concession_type_name)
    VALUES (NULL, N'Unknown'), (NULL, N'Unrecognised'), (NULL, N'Not applicable'), (NULL, N'No concession'),
           ('A0000000-0000-0000-0000-000000000001', N'Retired'),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship Relief'),
           ('A0000000-0000-0000-0000-000000000003', N'Life Member');
    EXEC tSQLt.AssertEqualsTable '#ExpectedNames', '#ActualNames';
END;
GO

CREATE PROCEDURE test_MOD006.[test TC-006-028 dimension loaded through bronze and silver has the same row count and id name pairs as silver]
AS
BEGIN
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC test_MOD006.[fake and seed silv_ref_concession_type];

    INSERT INTO CE.vwConcessionType (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('A0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000),
           ('A0000000-0000-0000-0000-000000000002', 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001),
           ('A0000000-0000-0000-0000-000000000003', 'A0000000-0000-0000-0000-000000000003', N'Life Member', 100.00, N'rcsCONLIFEMEMBER', 0, NULL);

    EXEC Layercake.usp_load_brnz_concession;
    EXEC Layercake.usp_load_silv_ref_concession_type;
    EXEC Layercake.usp_load_dim_concession_type;

    SELECT id, CAST(concession_type_name AS varbinary(200)) AS name_bytes INTO #SilverPairs FROM Layercake.silv_ref_concession_type;
    SELECT id, CAST(concession_type_name AS varbinary(200)) AS name_bytes INTO #DimPairs FROM Layercake.dim_concession_type;
    EXEC tSQLt.AssertEqualsTable '#SilverPairs', '#DimPairs';

    SELECT concession_type_name INTO #ActualNames FROM Layercake.dim_concession_type;
    CREATE TABLE #ExpectedNames (concession_type_name nvarchar(100));
    INSERT INTO #ExpectedNames (concession_type_name)
    VALUES (N'Unknown'), (N'Unrecognised'), (N'Not applicable'), (N'No concession'), (N'Retired'), (N'Exceptional Hardship'), (N'Life Member');
    EXEC tSQLt.AssertEqualsTable '#ExpectedNames', '#ActualNames';
END;
GO

/* ===================== Cross-segment reserved labels (AC-003-06) ===================== */

CREATE PROCEDURE test_MOD006.[test TC-006-029 reserved ids carry the same three labels in the payment method payer type and concession type lists]
AS
BEGIN
    CREATE TABLE #Actual (list_name varchar(30), id int, label_bytes varbinary(200));
    INSERT INTO #Actual (list_name, id, label_bytes)
    SELECT 'payment_method', id, CAST(CAST(payment_method_name AS nvarchar(100)) AS varbinary(200))
    FROM Layercake.silv_ref_payment_method WHERE id IN (0, -1, -2);
    INSERT INTO #Actual (list_name, id, label_bytes)
    SELECT 'payer_type', id, CAST(CAST(payer_type_name AS nvarchar(100)) AS varbinary(200))
    FROM Layercake.silv_ref_payer_type WHERE id IN (0, -1, -2);
    INSERT INTO #Actual (list_name, id, label_bytes)
    SELECT 'concession_type', id, CAST(CAST(concession_type_name AS nvarchar(100)) AS varbinary(200))
    FROM Layercake.silv_ref_concession_type WHERE id IN (0, -1, -2);

    CREATE TABLE #Expected (list_name varchar(30), id int, label_bytes varbinary(200));
    INSERT INTO #Expected (list_name, id, label_bytes)
    VALUES ('payment_method', 0, CAST(N'Unknown' AS varbinary(200))),
           ('payment_method', -1, CAST(N'Unrecognised' AS varbinary(200))),
           ('payment_method', -2, CAST(N'Not applicable' AS varbinary(200))),
           ('payer_type', 0, CAST(N'Unknown' AS varbinary(200))),
           ('payer_type', -1, CAST(N'Unrecognised' AS varbinary(200))),
           ('payer_type', -2, CAST(N'Not applicable' AS varbinary(200))),
           ('concession_type', 0, CAST(N'Unknown' AS varbinary(200))),
           ('concession_type', -1, CAST(N'Unrecognised' AS varbinary(200))),
           ('concession_type', -2, CAST(N'Not applicable' AS varbinary(200)));
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @label_differences int = (
        SELECT COUNT(*)
        FROM #Actual AS a
        JOIN #Actual AS b ON b.id = a.id AND b.list_name <> a.list_name
        WHERE a.label_bytes <> b.label_bytes);
    EXEC tSQLt.AssertEquals 0, @label_differences;
END;
GO
