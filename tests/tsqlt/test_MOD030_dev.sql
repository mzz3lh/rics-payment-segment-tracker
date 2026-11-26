EXEC tSQLt.NewTestClass 'test_MOD030_dev';
GO
CREATE PROCEDURE test_MOD030_dev.[Insert list inputs]
AS
BEGIN
    INSERT INTO Layercake.silv_ref_country (id, country_id, country_name, region_name, market_reporting_region)
    VALUES (0, '00000000-0000-0000-0000-000000000000', N'N/A', N'N/A', 'N/A'),
           (1, 'C0000000-0000-0000-0000-000000000001', N'United Kingdom', N'UK&I', 'UK&I'),
           (2, 'C0000000-0000-0000-0000-000000000002', N'United Arab Emirates', N'MEA', 'MEA'),
           (3, 'C0000000-0000-0000-0000-000000000003', N'India', N'APAC', 'APAC');

    SET IDENTITY_INSERT Layercake.silv_ref_local_group ON;
    INSERT INTO Layercake.silv_ref_local_group (id, local_group_bk, local_group_name, is_reportable, load_id, created_at, updated_at)
    VALUES (-2, NULL, N'Not applicable', 0, NULL, '2026-01-01', '2026-01-01'),
           (0, NULL, N'Unknown', 0, NULL, '2026-01-01', '2026-01-01');
    SET IDENTITY_INSERT Layercake.silv_ref_local_group OFF;
END;
GO
CREATE PROCEDURE test_MOD030_dev.[test bronze local group a case-only and a trailing-space change are each landed as one update]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'CE.vwLocalGroup';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;

    INSERT INTO CE.vwLocalGroup (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, Market_reporting_region, statecode)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Gulf', N'GULF', 'C0000000-0000-0000-0000-000000000002', N'MEA', 'MEA', 0),
           ('A0000000-0000-0000-0000-000000000002', N'London', N'LON', 'C0000000-0000-0000-0000-000000000001', N'UK&I', 'UK&I', 0),
           ('A0000000-0000-0000-0000-000000000003', N'Gulf India', N'GIND', 'C0000000-0000-0000-0000-000000000003', N'MEA', 'MEA', 0);
    EXEC Layercake.usp_load_brnz_local_group_detail;

    UPDATE CE.vwLocalGroup SET apuk_name = N'GULF' WHERE apuk_localgroupid = 'A0000000-0000-0000-0000-000000000001';
    UPDATE CE.vwLocalGroup SET apuk_code = N'LON ' WHERE apuk_localgroupid = 'A0000000-0000-0000-0000-000000000002';
    EXEC Layercake.usp_load_brnz_local_group_detail;

    SELECT v.apuk_localgroupid, v.name_bytes, v.code_bytes
    INTO #Expected
    FROM (VALUES
        (CAST('A0000000-0000-0000-0000-000000000001' AS uniqueidentifier), CAST(N'GULF' AS varbinary(200)), CAST(N'GULF' AS varbinary(200))),
        (CAST('A0000000-0000-0000-0000-000000000002' AS uniqueidentifier), CAST(N'London' AS varbinary(200)), CAST(N'LON ' AS varbinary(200))),
        (CAST('A0000000-0000-0000-0000-000000000003' AS uniqueidentifier), CAST(N'Gulf India' AS varbinary(200)), CAST(N'GIND' AS varbinary(200)))
    ) AS v(apuk_localgroupid, name_bytes, code_bytes);
    SELECT apuk_localgroupid, CAST(apuk_name AS varbinary(200)) AS name_bytes, CAST(apuk_code AS varbinary(200)) AS code_bytes
    INTO #Actual
    FROM Layercake.brnz_local_group_detail;
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT TOP (1) status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log ORDER BY log_id DESC;
    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 2, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD030_dev.[test silver local group regions differing from the country only in case use the country own row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC test_MOD030_dev.[Insert list inputs];
    INSERT INTO Layercake.brnz_local_group_detail (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, market_reporting_region, statecode, _is_deleted)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Gulf', N'GULF', 'C0000000-0000-0000-0000-000000000002', N'mea', 'mea', 0, 0);

    EXEC Layercake.usp_load_silv_ref_local_group;

    SELECT v.dim_country_id, v.region_bytes, v.is_reportable
    INTO #Expected
    FROM (VALUES (2, CAST(N'mea' AS varbinary(200)), 1)) AS v(dim_country_id, region_bytes, is_reportable);
    SELECT dim_country_id, CAST(region_name AS varbinary(200)) AS region_bytes, CAST(is_reportable AS int) AS is_reportable
    INTO #Actual
    FROM Layercake.silv_ref_local_group
    WHERE local_group_bk = 'A0000000-0000-0000-0000-000000000001';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @combinations int = (SELECT COUNT(*) FROM Layercake.silv_ref_country_region);
    EXEC tSQLt.AssertEquals 0, @combinations, 'no combination for a case-only difference';
END;
GO
CREATE PROCEDURE test_MOD030_dev.[test silver local group two groups with the same country and regions share one combination row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC test_MOD030_dev.[Insert list inputs];
    INSERT INTO Layercake.brnz_local_group_detail (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, market_reporting_region, statecode, _is_deleted)
    VALUES ('A0000000-0000-0000-0000-000000000003', N'Gulf India', N'GIND', 'C0000000-0000-0000-0000-000000000003', N'MEA', 'MEA', 0, 0),
           ('A0000000-0000-0000-0000-000000000009', N'Mumbai Gulf', N'MGUL', 'C0000000-0000-0000-0000-000000000003', N'MEA', 'MEA', 0, 0);

    EXEC Layercake.usp_load_silv_ref_local_group;

    SELECT v.id, v.country_ref_id, v.region_name, v.market_reporting_region
    INTO #ExpectedRegion
    FROM (VALUES (1000001, 3, N'MEA', CAST('MEA' AS varchar(15)))) AS v(id, country_ref_id, region_name, market_reporting_region);
    SELECT id, country_ref_id, region_name, market_reporting_region INTO #ActualRegion FROM Layercake.silv_ref_country_region;
    EXEC tSQLt.AssertEqualsTable '#ExpectedRegion', '#ActualRegion';

    SELECT v.local_group_name, v.dim_country_id
    INTO #Expected
    FROM (VALUES (N'Gulf India', 1000001), (N'Mumbai Gulf', 1000001)) AS v(local_group_name, dim_country_id);
    SELECT local_group_name, dim_country_id INTO #Actual FROM Layercake.silv_ref_local_group WHERE local_group_bk IS NOT NULL;
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @logged int = (SELECT rows_affected FROM Layercake.etl_progress_log WHERE substep = N'silv_ref_country_region combinations added');
    EXEC tSQLt.AssertEquals 1, @logged, 'the combination added is logged as a sub-step';
END;
GO
CREATE PROCEDURE test_MOD030_dev.[test silver local group logs its inserts and a group gone from bronze is kept not reportable as one update]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC test_MOD030_dev.[Insert list inputs];
    INSERT INTO Layercake.brnz_local_group_detail (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, market_reporting_region, statecode, _is_deleted)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Gulf', N'GULF', 'C0000000-0000-0000-0000-000000000002', N'MEA', 'MEA', 0, 0),
           ('A0000000-0000-0000-0000-000000000002', N'London', N'LON', 'C0000000-0000-0000-0000-000000000001', N'UK&I', 'UK&I', 0, 0);

    EXEC Layercake.usp_load_silv_ref_local_group;

    SELECT TOP (1) status, rows_inserted, rows_updated, rows_deleted INTO #ActualFirst FROM Layercake.etl_run_log ORDER BY log_id DESC;
    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedFirst
    FROM (VALUES ('Success', 2, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedFirst', '#ActualFirst';

    DECLARE @gulf_id int = (SELECT id FROM Layercake.silv_ref_local_group WHERE local_group_bk = 'A0000000-0000-0000-0000-000000000001');
    DELETE FROM Layercake.brnz_local_group_detail WHERE apuk_localgroupid = 'A0000000-0000-0000-0000-000000000001';
    EXEC Layercake.usp_load_silv_ref_local_group;

    SELECT v.id, v.local_group_name, v.is_reportable, v.dim_country_id
    INTO #Expected
    FROM (VALUES (@gulf_id, N'Gulf', 0, CAST(NULL AS int))) AS v(id, local_group_name, is_reportable, dim_country_id);
    SELECT id, local_group_name, CAST(is_reportable AS int) AS is_reportable, dim_country_id
    INTO #Actual
    FROM Layercake.silv_ref_local_group
    WHERE local_group_bk = 'A0000000-0000-0000-0000-000000000001';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT TOP (1) status, rows_inserted, rows_updated, rows_deleted INTO #ActualSecond FROM Layercake.etl_run_log ORDER BY log_id DESC;
    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedSecond
    FROM (VALUES ('Success', 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedSecond', '#ActualSecond';
END;
GO
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD030_dev.[test silver local group a repeated business key in bronze fails the load and leaves the list unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC test_MOD030_dev.[Insert list inputs];
    -- the faked bronze table has no primary key, so the data can repeat a key
    INSERT INTO Layercake.brnz_local_group_detail (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, market_reporting_region, statecode, _is_deleted)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Gulf', N'GULF', 'C0000000-0000-0000-0000-000000000002', N'MEA', 'MEA', 0, 0),
           ('A0000000-0000-0000-0000-000000000001', N'Gulf Copy', N'GULF2', 'C0000000-0000-0000-0000-000000000002', N'MEA', 'MEA', 0, 0);

    SELECT id, local_group_bk, local_group_name, is_reportable, load_id, created_at, updated_at INTO #Before FROM Layercake.silv_ref_local_group;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_ref_local_group;
        EXEC tSQLt.Fail 'A repeated local group key must fail the load and re-raise';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 2627 THROW;
    END CATCH;

    SELECT id, local_group_bk, local_group_name, is_reportable, load_id, created_at, updated_at INTO #After FROM Layercake.silv_ref_local_group;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    DECLARE @combinations int = (SELECT COUNT(*) FROM Layercake.silv_ref_country_region);
    EXEC tSQLt.AssertEquals 0, @combinations, 'no combination is written';

    SELECT status, CASE WHEN error_message LIKE N'%2627%' THEN 1 ELSE 0 END AS has_error
    INTO #ActualLog
    FROM Layercake.etl_run_log;
    SELECT v.status, v.has_error INTO #ExpectedLog FROM (VALUES ('Failed', 1)) AS v(status, has_error);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD030_dev.[test view a contact whose own country is not in silv_ref_country takes country 0 and its N/A regions]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact', @Defaults = 1;
    EXEC test_MOD030_dev.[Insert list inputs];
    INSERT INTO Layercake.brnz_local_group_detail (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, market_reporting_region, statecode, _is_deleted)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Gulf', N'GULF', 'C0000000-0000-0000-0000-000000000002', N'MEA', 'MEA', 0, 0);
    EXEC Layercake.usp_load_silv_ref_local_group;

    EXEC sp_executesql N'
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, rics_countryid, rics_localgroupid, _is_deleted)
    VALUES (''B0000000-0000-0000-0000-000000000031'', N''U1'', ''C0000000-0000-0000-0000-000000000099'', NULL, 0),
           (''B0000000-0000-0000-0000-000000000032'', N''U2'', NULL, ''A0000000-0000-0000-0000-000000000001'', 0);';

    SELECT v.contact_no, v.contact_country_id, v.is_group, v.country_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region
    INTO #Expected
    FROM (VALUES
        (N'U1', 0, 0, 0, N'N/A', CAST('N/A' AS varchar(15)), N'N/A', CAST('N/A' AS varchar(15))),
        (N'U2', 0, 1, 2, N'MEA', 'MEA', N'N/A', 'N/A')
    ) AS v(contact_no, contact_country_id, is_group, country_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region);

    SELECT contact_no, contact_country_id, CASE WHEN local_group_id > 0 THEN 1 ELSE 0 END AS is_group,
           country_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region
    INTO #Actual
    FROM Layercake.vw_silv_contact_local_group;
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD030_dev.[test dim local group a case-only rename is one update and a rerun logs 0 0 0]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group';
    EXEC tSQLt.FakeTable 'Layercake.dim_local_group', @Defaults = 1;
    INSERT INTO Layercake.silv_ref_local_group (id, local_group_bk, local_group_name, is_reportable, created_at, updated_at)
    VALUES (-2, NULL, N'Not applicable', 0, '2026-01-01', '2026-01-01'),
           (0, NULL, N'Unknown', 0, '2026-01-01', '2026-01-01'),
           (1, 'A0000000-0000-0000-0000-000000000001', N'GULF', 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.dim_local_group (id, local_group_name, load_id, created_at, updated_at)
    VALUES (-2, N'Not applicable', 11, '2026-01-01', '2026-01-01'), (0, N'Unknown', 11, '2026-01-01', '2026-01-01'),
           (1, N'Gulf', 11, '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_dim_local_group;
    EXEC Layercake.usp_load_dim_local_group;

    DECLARE @expected_bytes varbinary(200) = CAST(N'GULF' AS varbinary(200));
    DECLARE @name_bytes varbinary(200) = (SELECT CAST(local_group_name AS varbinary(200)) FROM Layercake.dim_local_group WHERE id = 1);
    EXEC tSQLt.AssertEquals @expected_bytes, @name_bytes, 'the name is updated to GULF byte for byte';

    SELECT status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log;
    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1, 0), ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD030_dev.[test dim country load logs the combination row as one insert]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region';
    EXEC tSQLt.FakeTable 'Layercake.dim_country';
    INSERT INTO Layercake.silv_ref_country (id, country_id, country_name, region_name, market_reporting_region)
    VALUES (2, 'C0000000-0000-0000-0000-000000000002', N'United Arab Emirates', N'MEA', 'MEA'),
           (3, 'C0000000-0000-0000-0000-000000000003', N'India', N'APAC', 'APAC');
    INSERT INTO Layercake.silv_ref_country_region (id, country_ref_id, region_name, market_reporting_region, load_id, created_at)
    VALUES (1000001, 3, N'MEA', 'MEA', NULL, '2026-01-01');
    INSERT INTO Layercake.dim_country (id, country_id, country_name, region_name, market_reporting_region)
    VALUES (2, 'C0000000-0000-0000-0000-000000000002', N'United Arab Emirates', N'MEA', 'MEA'),
           (3, 'C0000000-0000-0000-0000-000000000003', N'India', N'APAC', 'APAC');

    EXEC Layercake.usp_load_dim_country;

    SELECT status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log;
    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD030_dev.[test brnz contact a contact that reappears is restored with its rics_localgroupid as one update]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'CE.vwContact';
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact', @Defaults = 1;

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, GenderCode, rics_countryid, rics_localgroupid, StateCode)
    VALUES ('B0000000-0000-0000-0000-000000000041', N'R1', 1, 'C0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000002', 0);
    EXEC sp_executesql N'
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, GenderCode, rics_countryid, rics_localgroupid, StateCode, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (''B0000000-0000-0000-0000-000000000041'', N''R1'', 1, ''C0000000-0000-0000-0000-000000000001'', ''A0000000-0000-0000-0000-000000000001'', 0, ''2026-01-01'', ''2026-01-01'', 1, ''2026-01-01'');';

    EXEC Layercake.usp_load_brnz_contact;

    SELECT v.rics_localgroupid, v._is_deleted, v.deleted_at_is_null
    INTO #Expected
    FROM (VALUES (CAST('A0000000-0000-0000-0000-000000000002' AS uniqueidentifier), 0, 1)) AS v(rics_localgroupid, _is_deleted, deleted_at_is_null);
    SELECT TOP (0) rics_localgroupid, _is_deleted, deleted_at_is_null INTO #Actual FROM #Expected;
    INSERT INTO #Actual (rics_localgroupid, _is_deleted, deleted_at_is_null)
    EXEC sp_executesql N'
    SELECT rics_localgroupid, CAST(_is_deleted AS int), CASE WHEN _deleted_at IS NULL THEN 1 ELSE 0 END
    FROM Layercake.brnz_contact;';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log;
    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD030_dev.[Spy and record] @proc_name sysname
AS
BEGIN
    DECLARE @full nvarchar(400) = N'Layercake.' + @proc_name;
    DECLARE @cmd nvarchar(max) = N'INSERT INTO #calls (proc_name, run_id) VALUES (N''' + @proc_name + N''', @run_id);';
    EXEC tSQLt.SpyProcedure @ProcedureName = @full, @CommandToExecute = @cmd;
END;
GO
CREATE PROCEDURE test_MOD030_dev.[test bronze step with no run_id gives the local group landing the same generated run_id as every other load]
AS
BEGIN
    CREATE TABLE #calls (call_no int IDENTITY(1, 1) NOT NULL, proc_name nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL, run_id uniqueidentifier NULL);
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_brnz_contact';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_brnz_enrolment';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_brnz_rics_record';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_brnz_local_group';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_brnz_local_group_detail';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_brnz_cust_trans';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_brnz_subs_status';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_brnz_option_set';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_brnz_route';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_brnz_contact_test_record';

    EXEC Layercake.usp_load_bronze;

    SELECT COUNT(*) AS calls, COUNT(DISTINCT run_id) AS run_ids, SUM(CASE WHEN run_id IS NULL THEN 1 ELSE 0 END) AS null_run_ids
    INTO #Actual
    FROM #calls;
    SELECT v.calls, v.run_ids, v.null_run_ids INTO #Expected FROM (VALUES (10, 1, 0)) AS v(calls, run_ids, null_run_ids);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD030_dev.[test silver step with the daily count held back still runs the local group list before the member base]
AS
BEGIN
    CREATE TABLE #calls (call_no int IDENTITY(1, 1) NOT NULL, proc_name nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL, run_id uniqueidentifier NULL);
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_silv_ref_assessment_route';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_silv_ref_rpq_variant';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_silv_ref_country';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_silv_ref_lapse_reason';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_silv_ref_local_group';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_ref_date_spine';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_ref_campaign_year_config';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_silv_payment_events';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_ref_enrolment_exception';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_silv_member_base';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_silv_membership_events';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_silv_data_anomaly';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_silv_member_state_ranges';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_silv_member_profile';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_silv_daily_count';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_silv_annual_rate_base';

    EXEC Layercake.usp_load_silver @run_id = 'E0000000-0000-0000-0000-000000000041', @SkipDailyCount = 1;

    SELECT v.proc_name INTO #Expected
    FROM (VALUES (N'usp_load_silv_ref_assessment_route'), (N'usp_load_silv_ref_rpq_variant'), (N'usp_load_silv_ref_country'),
                 (N'usp_load_silv_ref_lapse_reason'), (N'usp_load_silv_ref_local_group'), (N'usp_load_ref_date_spine'),
                 (N'usp_load_ref_campaign_year_config'), (N'usp_load_silv_payment_events'), (N'usp_load_ref_enrolment_exception'),
                 (N'usp_load_silv_member_base')) AS v(proc_name);
    SELECT proc_name INTO #Actual FROM #calls
    WHERE call_no <= (SELECT call_no FROM #calls WHERE proc_name = N'usp_load_silv_member_base');
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @daily int = (SELECT COUNT(*) FROM #calls WHERE proc_name = N'usp_load_silv_daily_count');
    EXEC tSQLt.AssertEquals 0, @daily, 'the daily count stays held back';
END;
GO
CREATE PROCEDURE test_MOD030_dev.[test gold step with the daily fact held back runs dim_local_group straight after dim_country]
AS
BEGIN
    CREATE TABLE #calls (call_no int IDENTITY(1, 1) NOT NULL, proc_name nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL, run_id uniqueidentifier NULL);
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_dim_membership_grade';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_dim_assessment_route';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_dim_rpq_variant';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_dim_country';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_dim_local_group';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_dim_gender';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_dim_membership_status';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_dim_lapse_reason';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_dim_campaign_year';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_dim_date';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_fact_membership_events';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_fact_daily_member_count_detail';
    EXEC test_MOD030_dev.[Spy and record] N'usp_load_fact_annual_rate_base';

    EXEC Layercake.usp_load_gold @run_id = 'E0000000-0000-0000-0000-000000000042', @SkipDailyFact = 1;

    DECLARE @gap int = (SELECT MAX(CASE WHEN proc_name = N'usp_load_dim_local_group' THEN call_no END)
                             - MAX(CASE WHEN proc_name = N'usp_load_dim_country' THEN call_no END)
                        FROM #calls);
    EXEC tSQLt.AssertEquals 1, @gap, 'dim_local_group runs straight after dim_country';

    DECLARE @steps int = (SELECT COUNT(*) FROM #calls);
    EXEC tSQLt.AssertEquals 12, @steps, 'every gold step but the held-back daily fact runs once';
END;
GO
