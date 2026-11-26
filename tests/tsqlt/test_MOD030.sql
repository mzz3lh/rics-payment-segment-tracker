EXEC tSQLt.NewTestClass 'test_MOD030';
GO
CREATE PROCEDURE test_MOD030.[Insert countries]
AS
BEGIN
    INSERT INTO Layercake.silv_ref_country (id, country_id, country_name, region_name, market_reporting_region)
    VALUES (1, 'C0000000-0000-0000-0000-000000000001', N'United Kingdom', N'UK&I', 'UK&I'),
           (2, 'C0000000-0000-0000-0000-000000000002', N'United Arab Emirates', N'MEA', 'MEA'),
           (3, 'C0000000-0000-0000-0000-000000000003', N'India', N'APAC', 'APAC');
END;
GO
CREATE PROCEDURE test_MOD030.[Insert local group source]
AS
BEGIN
    INSERT INTO CE.vwLocalGroup (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, Market_reporting_region, statecode)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Gulf', N'GULF', 'C0000000-0000-0000-0000-000000000002', N'MEA', 'MEA', 0),
           ('A0000000-0000-0000-0000-000000000002', N'London', N'LON', 'C0000000-0000-0000-0000-000000000001', N'UK&I', 'UK&I', 0),
           ('A0000000-0000-0000-0000-000000000003', N'Gulf India', N'GIND', 'C0000000-0000-0000-0000-000000000003', N'MEA', 'MEA', 0),
           ('A0000000-0000-0000-0000-000000000004', N'No Country', N'NOC', NULL, N'MEA', 'MEA', 0),
           ('A0000000-0000-0000-0000-000000000005', N'No Region', N'NOR', 'C0000000-0000-0000-0000-000000000002', NULL, NULL, 0),
           ('A0000000-0000-0000-0000-000000000006', N'Closed Gulf', N'CGULF', 'C0000000-0000-0000-0000-000000000002', N'MEA', 'MEA', 1),
           ('A0000000-0000-0000-0000-000000000007', N'Half Region', N'HALF', 'C0000000-0000-0000-0000-000000000002', N'MEA', ' ', 0);
END;
GO
CREATE PROCEDURE test_MOD030.[Insert reference lists]
AS
BEGIN
    EXEC test_MOD030.[Insert countries];
    INSERT INTO Layercake.brnz_local_group_detail (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, market_reporting_region, statecode, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Gulf', N'GULF', 'C0000000-0000-0000-0000-000000000002', N'MEA', 'MEA', 0, 0, NULL),
           ('A0000000-0000-0000-0000-000000000002', N'London', N'LON', 'C0000000-0000-0000-0000-000000000001', N'UK&I', 'UK&I', 0, 0, NULL),
           ('A0000000-0000-0000-0000-000000000003', N'Gulf India', N'GIND', 'C0000000-0000-0000-0000-000000000003', N'MEA', 'MEA', 0, 0, NULL),
           ('A0000000-0000-0000-0000-000000000004', N'No Country', N'NOC', NULL, N'MEA', 'MEA', 0, 0, NULL),
           ('A0000000-0000-0000-0000-000000000005', N'No Region', N'NOR', 'C0000000-0000-0000-0000-000000000002', NULL, NULL, 0, 0, NULL),
           ('A0000000-0000-0000-0000-000000000006', N'Closed Gulf', N'CGULF', 'C0000000-0000-0000-0000-000000000002', N'MEA', 'MEA', 1, 0, NULL),
           ('A0000000-0000-0000-0000-000000000007', N'Half Region', N'HALF', 'C0000000-0000-0000-0000-000000000002', N'MEA', ' ', 0, 0, NULL);
    SET IDENTITY_INSERT Layercake.silv_ref_local_group ON;
    INSERT INTO Layercake.silv_ref_local_group (id, local_group_bk, local_group_name, is_reportable, load_id, created_at, updated_at)
    VALUES (-2, NULL, N'Not applicable', 0, NULL, '2026-01-01', '2026-01-01'),
           (0, NULL, N'Unknown', 0, NULL, '2026-01-01', '2026-01-01');
    SET IDENTITY_INSERT Layercake.silv_ref_local_group OFF;
END;
GO
CREATE PROCEDURE test_MOD030.[Insert contacts]
AS
BEGIN
    -- rics_localgroupid is added by this module, so the insert is dynamic to compile before the build
    EXEC sp_executesql N'
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, rics_countryid, rics_localgroupid, _is_deleted)
    VALUES (''B0000000-0000-0000-0000-000000000001'', N''G1'', ''C0000000-0000-0000-0000-000000000001'', ''A0000000-0000-0000-0000-000000000001'', 0),
           (''B0000000-0000-0000-0000-000000000002'', N''G2'', ''C0000000-0000-0000-0000-000000000003'', ''A0000000-0000-0000-0000-000000000003'', 0),
           (''B0000000-0000-0000-0000-000000000003'', N''N1'', ''C0000000-0000-0000-0000-000000000003'', NULL, 0),
           (''B0000000-0000-0000-0000-000000000004'', N''N2'', ''C0000000-0000-0000-0000-000000000003'', ''A0000000-0000-0000-0000-000000000099'', 0),
           (''B0000000-0000-0000-0000-000000000005'', N''N3'', ''C0000000-0000-0000-0000-000000000001'', ''A0000000-0000-0000-0000-000000000004'', 0),
           (''B0000000-0000-0000-0000-000000000006'', N''N4'', ''C0000000-0000-0000-0000-000000000001'', ''A0000000-0000-0000-0000-000000000005'', 0),
           (''B0000000-0000-0000-0000-000000000007'', N''N5'', ''C0000000-0000-0000-0000-000000000001'', ''A0000000-0000-0000-0000-000000000006'', 0),
           (''B0000000-0000-0000-0000-000000000008'', N''N6'', ''C0000000-0000-0000-0000-000000000001'', ''A0000000-0000-0000-0000-000000000007'', 0),
           (''B0000000-0000-0000-0000-000000000009'', N''L1'', ''C0000000-0000-0000-0000-000000000001'', ''A0000000-0000-0000-0000-000000000002'', 0),
           (''B0000000-0000-0000-0000-000000000010'', N''D1'', ''C0000000-0000-0000-0000-000000000001'', ''A0000000-0000-0000-0000-000000000001'', 1);';
END;
GO
CREATE PROCEDURE test_MOD030.[Insert dim country inputs]
AS
BEGIN
    EXEC test_MOD030.[Insert countries];
    INSERT INTO Layercake.silv_ref_country_region (id, country_ref_id, region_name, market_reporting_region, load_id, created_at)
    VALUES (1000001, 3, N'MEA', 'MEA', NULL, '2026-01-01');
    INSERT INTO Layercake.dim_country (id, country_id, country_name, region_name, market_reporting_region)
    VALUES (1, 'C0000000-0000-0000-0000-000000000001', N'United Kingdom', N'UK&I', 'UK&I'),
           (2, 'C0000000-0000-0000-0000-000000000002', N'United Arab Emirates', N'MEA', 'MEA'),
           (3, 'C0000000-0000-0000-0000-000000000003', N'India', N'APAC', 'APAC');
END;
GO
CREATE PROCEDURE test_MOD030.[Insert local group list]
AS
BEGIN
    INSERT INTO Layercake.silv_ref_local_group (id, local_group_bk, local_group_name, is_reportable, created_at, updated_at)
    VALUES (-2, NULL, N'Not applicable', 0, '2026-01-01', '2026-01-01'),
           (0, NULL, N'Unknown', 0, '2026-01-01', '2026-01-01'),
           (1, 'A0000000-0000-0000-0000-000000000001', N'Gulf', 1, '2026-01-01', '2026-01-01'),
           (2, 'A0000000-0000-0000-0000-000000000002', N'London', 1, '2026-01-01', '2026-01-01'),
           (3, 'A0000000-0000-0000-0000-000000000003', N'Gulf India', 1, '2026-01-01', '2026-01-01'),
           (4, 'A0000000-0000-0000-0000-000000000004', N'No Country', 0, '2026-01-01', '2026-01-01'),
           (5, 'A0000000-0000-0000-0000-000000000005', N'No Region', 0, '2026-01-01', '2026-01-01'),
           (6, 'A0000000-0000-0000-0000-000000000006', N'Closed Gulf', 0, '2026-01-01', '2026-01-01'),
           (7, 'A0000000-0000-0000-0000-000000000007', N'Half Region', 0, '2026-01-01', '2026-01-01');
END;
GO
CREATE PROCEDURE test_MOD030.[Spy and record] @proc_name sysname
AS
BEGIN
    DECLARE @full nvarchar(400) = N'Layercake.' + @proc_name;
    DECLARE @cmd nvarchar(max) = N'INSERT INTO #calls (proc_name, run_id) VALUES (N''' + @proc_name + N''', @run_id);';
    EXEC tSQLt.SpyProcedure @ProcedureName = @full, @CommandToExecute = @cmd;
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-001 gold facts and dim_country keep every earlier column with its name and type]
AS
BEGIN
    SELECT v.table_name, v.column_name, v.type_name, v.max_length, v.[precision], v.scale
    INTO #Expected
    FROM (VALUES
        (N'fact_daily_member_count_detail', N'id', N'bigint', 8, 19, 0),
        (N'fact_daily_member_count_detail', N'date_id', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'country_id', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'gender_id', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'membership_grade_id', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'membership_status_id', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'ActiveMembers', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'PaidMembers', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'PaidMembersEvent', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'JoinEvents', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'RenewalEvents', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'ReadmissionEvents', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'LapseEvents', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'payment_method_id', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'payer_type_id', N'int', 4, 10, 0),
        (N'fact_daily_member_count_detail', N'concession_type_id', N'int', 4, 10, 0),
        (N'fact_membership_events', N'event_id', N'int', 4, 10, 0),
        (N'fact_membership_events', N'event_type', N'varchar', 20, 0, 0),
        (N'fact_membership_events', N'event_subtype', N'varchar', 20, 0, 0),
        (N'fact_membership_events', N'event_date', N'date', 3, 10, 0),
        (N'fact_membership_events', N'date_id', N'int', 4, 10, 0),
        (N'fact_membership_events', N'contact_no', N'nvarchar', 400, 0, 0),
        (N'fact_membership_events', N'grade_id', N'int', 4, 10, 0),
        (N'fact_membership_events', N'assessment_route_id', N'int', 4, 10, 0),
        (N'fact_membership_events', N'rpq_variant_id', N'int', 4, 10, 0),
        (N'fact_membership_events', N'hpb_id', N'int', 4, 10, 0),
        (N'fact_membership_events', N'country_id', N'int', 4, 10, 0),
        (N'fact_membership_events', N'gender_id', N'int', 4, 10, 0),
        (N'fact_membership_events', N'membership_status_id', N'int', 4, 10, 0),
        (N'fact_membership_events', N'campaign_year', N'int', 4, 10, 0),
        (N'fact_membership_events', N'campaign_quarter', N'char', 2, 0, 0),
        (N'fact_membership_events', N'payment_method_id', N'int', 4, 10, 0),
        (N'fact_membership_events', N'payment_method_carried', N'bit', 1, 1, 0),
        (N'fact_membership_events', N'payer_type_id', N'int', 4, 10, 0),
        (N'fact_membership_events', N'payer_type_carried', N'bit', 1, 1, 0),
        (N'fact_membership_events', N'concession_type_id', N'int', 4, 10, 0),
        (N'fact_membership_events', N'concession_type_carried', N'bit', 1, 1, 0),
        (N'fact_membership_events', N'subs_amount_gbp', N'decimal', 9, 19, 4),
        (N'fact_membership_events', N'invoiced_subtotal_gbp', N'decimal', 9, 19, 4),
        (N'fact_membership_events', N'amount_status', N'varchar', 30, 0, 0),
        (N'fact_annual_rate_base', N'id', N'int', 4, 10, 0),
        (N'fact_annual_rate_base', N'campaign_year', N'int', 4, 10, 0),
        (N'fact_annual_rate_base', N'grade_id', N'int', 4, 10, 0),
        (N'fact_annual_rate_base', N'membership_status_id', N'int', 4, 10, 0),
        (N'fact_annual_rate_base', N'country_id', N'int', 4, 10, 0),
        (N'fact_annual_rate_base', N'gender_id', N'int', 4, 10, 0),
        (N'fact_annual_rate_base', N'members_start', N'int', 4, 10, 0),
        (N'fact_annual_rate_base', N'members_end', N'int', 4, 10, 0),
        (N'fact_annual_rate_base', N'members_joined', N'int', 4, 10, 0),
        (N'fact_annual_rate_base', N'members_readmitted', N'int', 4, 10, 0),
        (N'fact_annual_rate_base', N'members_lapsed', N'int', 4, 10, 0),
        (N'fact_annual_rate_base', N'members_renewed', N'int', 4, 10, 0),
        (N'dim_country', N'id', N'int', 4, 10, 0),
        (N'dim_country', N'country_id', N'uniqueidentifier', 16, 0, 0),
        (N'dim_country', N'country_name', N'nvarchar', 400, 0, 0),
        (N'dim_country', N'region_name', N'nvarchar', 400, 0, 0),
        (N'dim_country', N'market_reporting_region', N'varchar', 15, 0, 0)
    ) AS v(table_name, column_name, type_name, max_length, [precision], scale);

    SELECT e.table_name, e.column_name,
           CAST(TYPE_NAME(c.user_type_id) AS nvarchar(128)) AS type_name,
           CAST(c.max_length AS int) AS max_length,
           CAST(c.[precision] AS int) AS [precision],
           CAST(c.scale AS int) AS scale
    INTO #Actual
    FROM #Expected AS e
    JOIN sys.columns AS c
      ON c.object_id = OBJECT_ID(N'Layercake.' + e.table_name)
     AND c.name COLLATE Latin1_General_BIN2 = e.column_name COLLATE Latin1_General_BIN2;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-002 dim_country has exactly its five Phase 1 columns]
AS
BEGIN
    DECLARE @columns int = (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N'Layercake.dim_country'));
    EXEC tSQLt.AssertEquals 5, @columns, 'dim_country must gain no column';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-003 dim_country load keeps the country rows and adds the combination row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region';
    EXEC tSQLt.FakeTable 'Layercake.dim_country';
    EXEC test_MOD030.[Insert dim country inputs];

    EXEC Layercake.usp_load_dim_country;

    SELECT v.id, v.country_id, v.country_name, v.region_name, v.market_reporting_region
    INTO #Expected
    FROM (VALUES
        (1, CAST('C0000000-0000-0000-0000-000000000001' AS uniqueidentifier), N'United Kingdom', N'UK&I', 'UK&I'),
        (2, CAST('C0000000-0000-0000-0000-000000000002' AS uniqueidentifier), N'United Arab Emirates', N'MEA', 'MEA'),
        (3, CAST('C0000000-0000-0000-0000-000000000003' AS uniqueidentifier), N'India', N'APAC', 'APAC'),
        (1000001, CAST('C0000000-0000-0000-0000-000000000003' AS uniqueidentifier), N'India', N'MEA', 'MEA')
    ) AS v(id, country_id, country_name, region_name, market_reporting_region);

    SELECT id, country_id, country_name, region_name, market_reporting_region
    INTO #Actual
    FROM Layercake.dim_country;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @status varchar(10) = (SELECT TOP (1) status FROM Layercake.etl_run_log ORDER BY log_id DESC);
    EXEC tSQLt.AssertEqualsString 'Success', @status;
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-004 dim_country rerun on unchanged silver changes nothing and logs 0 0 0]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region';
    EXEC tSQLt.FakeTable 'Layercake.dim_country';
    EXEC test_MOD030.[Insert dim country inputs];

    EXEC Layercake.usp_load_dim_country;
    SELECT * INTO #Before FROM Layercake.dim_country;
    EXEC Layercake.usp_load_dim_country;
    SELECT * INTO #After FROM Layercake.dim_country;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT TOP (1) status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log
    ORDER BY log_id DESC;
    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-005 a country renamed in silver is renamed on its own row and its combination row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region';
    EXEC tSQLt.FakeTable 'Layercake.dim_country';
    EXEC test_MOD030.[Insert dim country inputs];

    EXEC Layercake.usp_load_dim_country;
    UPDATE Layercake.silv_ref_country SET country_name = N'Republic of India' WHERE id = 3;
    EXEC Layercake.usp_load_dim_country;

    SELECT v.id, v.country_name, v.region_name, v.market_reporting_region
    INTO #Expected
    FROM (VALUES
        (1, N'United Kingdom', N'UK&I', 'UK&I'),
        (2, N'United Arab Emirates', N'MEA', 'MEA'),
        (3, N'Republic of India', N'APAC', 'APAC'),
        (1000001, N'Republic of India', N'MEA', 'MEA')
    ) AS v(id, country_name, region_name, market_reporting_region);

    SELECT id, country_name, region_name, market_reporting_region
    INTO #Actual
    FROM Layercake.dim_country;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-006 the seven source local groups land 1:1 in brnz_local_group_detail]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'CE.vwLocalGroup';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC test_MOD030.[Insert local group source];

    EXEC Layercake.usp_load_brnz_local_group_detail;

    SELECT v.apuk_localgroupid, v.apuk_name, v.apuk_code, v.apuk_countryid, v.apuk_worldregionid_name, v.market_reporting_region, v.statecode, v._is_deleted, v.deleted_at_is_null
    INTO #Expected
    FROM (VALUES
        (CAST('A0000000-0000-0000-0000-000000000001' AS uniqueidentifier), N'Gulf', N'GULF', CAST('C0000000-0000-0000-0000-000000000002' AS uniqueidentifier), N'MEA', CAST('MEA' AS varchar(15)), 0, 0, 1),
        (CAST('A0000000-0000-0000-0000-000000000002' AS uniqueidentifier), N'London', N'LON', CAST('C0000000-0000-0000-0000-000000000001' AS uniqueidentifier), N'UK&I', CAST('UK&I' AS varchar(15)), 0, 0, 1),
        (CAST('A0000000-0000-0000-0000-000000000003' AS uniqueidentifier), N'Gulf India', N'GIND', CAST('C0000000-0000-0000-0000-000000000003' AS uniqueidentifier), N'MEA', CAST('MEA' AS varchar(15)), 0, 0, 1),
        (CAST('A0000000-0000-0000-0000-000000000004' AS uniqueidentifier), N'No Country', N'NOC', NULL, N'MEA', CAST('MEA' AS varchar(15)), 0, 0, 1),
        (CAST('A0000000-0000-0000-0000-000000000005' AS uniqueidentifier), N'No Region', N'NOR', CAST('C0000000-0000-0000-0000-000000000002' AS uniqueidentifier), NULL, NULL, 0, 0, 1),
        (CAST('A0000000-0000-0000-0000-000000000006' AS uniqueidentifier), N'Closed Gulf', N'CGULF', CAST('C0000000-0000-0000-0000-000000000002' AS uniqueidentifier), N'MEA', CAST('MEA' AS varchar(15)), 1, 0, 1),
        (CAST('A0000000-0000-0000-0000-000000000007' AS uniqueidentifier), N'Half Region', N'HALF', CAST('C0000000-0000-0000-0000-000000000002' AS uniqueidentifier), N'MEA', CAST(' ' AS varchar(15)), 0, 0, 1)
    ) AS v(apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, market_reporting_region, statecode, _is_deleted, deleted_at_is_null);

    SELECT apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, market_reporting_region, statecode,
           CAST(_is_deleted AS int) AS _is_deleted,
           CASE WHEN _deleted_at IS NULL THEN 1 ELSE 0 END AS deleted_at_is_null
    INTO #Actual
    FROM Layercake.brnz_local_group_detail;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @blank_length int = (SELECT DATALENGTH(market_reporting_region) FROM Layercake.brnz_local_group_detail
                                 WHERE apuk_localgroupid = 'A0000000-0000-0000-0000-000000000007');
    EXEC tSQLt.AssertEquals 1, @blank_length, 'the blank Market_reporting_region lands as one space, untransformed';

    SELECT status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log;
    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 7, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-007 a bronze local group rerun on unchanged source logs 0 0 0 and changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'CE.vwLocalGroup';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC test_MOD030.[Insert local group source];

    EXEC Layercake.usp_load_brnz_local_group_detail;
    SELECT * INTO #Before FROM Layercake.brnz_local_group_detail;
    EXEC Layercake.usp_load_brnz_local_group_detail;
    SELECT * INTO #After FROM Layercake.brnz_local_group_detail;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT TOP (1) status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log ORDER BY log_id DESC;
    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-008 bronze local groups are updated soft deleted and restored and unchanged rows are untouched]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'CE.vwLocalGroup';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC test_MOD030.[Insert local group source];

    EXEC Layercake.usp_load_brnz_local_group_detail;
    UPDATE Layercake.brnz_local_group_detail SET _loaded_at = '2026-01-01', _updated_at = '2026-01-01';

    DELETE FROM CE.vwLocalGroup WHERE apuk_localgroupid = 'A0000000-0000-0000-0000-000000000003';
    EXEC Layercake.usp_load_brnz_local_group_detail;

    INSERT INTO CE.vwLocalGroup (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, Market_reporting_region, statecode)
    VALUES ('A0000000-0000-0000-0000-000000000003', N'Gulf India', N'GIND', 'C0000000-0000-0000-0000-000000000003', N'MEA', 'MEA', 0);
    UPDATE CE.vwLocalGroup SET apuk_name = N'Gulf Region' WHERE apuk_localgroupid = 'A0000000-0000-0000-0000-000000000001';
    DELETE FROM CE.vwLocalGroup WHERE apuk_localgroupid = 'A0000000-0000-0000-0000-000000000002';
    EXEC Layercake.usp_load_brnz_local_group_detail;

    SELECT v.apuk_name, v._is_deleted, v.deleted_at_is_null, v.updated_at_untouched
    INTO #Expected
    FROM (VALUES
        (N'Gulf Region', 0, 1, 0),
        (N'London', 1, 0, 0),
        (N'Gulf India', 0, 1, 0),
        (N'No Country', 0, 1, 1),
        (N'No Region', 0, 1, 1),
        (N'Closed Gulf', 0, 1, 1),
        (N'Half Region', 0, 1, 1)
    ) AS v(apuk_name, _is_deleted, deleted_at_is_null, updated_at_untouched);

    SELECT apuk_name,
           CAST(_is_deleted AS int) AS _is_deleted,
           CASE WHEN _deleted_at IS NULL THEN 1 ELSE 0 END AS deleted_at_is_null,
           CASE WHEN _updated_at = '2026-01-01' THEN 1 ELSE 0 END AS updated_at_untouched
    INTO #Actual
    FROM Layercake.brnz_local_group_detail;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT TOP (1) status, rows_inserted, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log ORDER BY log_id DESC;
    SELECT v.status, v.rows_inserted, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1)) AS v(status, rows_inserted, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD030.[test TC-030-009 a source local group with a null key fails the bronze load and changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'CE.vwLocalGroup';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    ALTER TABLE Layercake.brnz_local_group_detail ALTER COLUMN apuk_localgroupid uniqueidentifier NOT NULL;
    ALTER TABLE Layercake.brnz_local_group_detail ADD CONSTRAINT PK_test_MOD030_009_lgd PRIMARY KEY (apuk_localgroupid);
    EXEC test_MOD030.[Insert local group source];

    INSERT INTO Layercake.brnz_local_group_detail (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, market_reporting_region, statecode, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Gulf (old)', N'GULF', 'C0000000-0000-0000-0000-000000000002', N'MEA', 'MEA', 0, '2026-01-01', '2026-01-01', 0, NULL),
           ('A0000000-0000-0000-0000-000000000008', N'Gone Group', N'GONE', 'C0000000-0000-0000-0000-000000000001', N'UK&I', 'UK&I', 0, '2026-01-01', '2026-01-01', 0, NULL);
    INSERT INTO CE.vwLocalGroup (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, Market_reporting_region, statecode)
    VALUES (NULL, N'Orphan Group', N'ORPH', 'C0000000-0000-0000-0000-000000000001', N'UK&I', 'UK&I', 0);

    SELECT * INTO #Before FROM Layercake.brnz_local_group_detail;

    DECLARE @raised bit = 0;
    BEGIN TRY
        EXEC Layercake.usp_load_brnz_local_group_detail;
    END TRY
    BEGIN CATCH
        SET @raised = 1;
    END CATCH;
    IF @raised = 0
        EXEC tSQLt.Fail 'A source row with a NULL apuk_localgroupid must fail the load and re-raise';

    SELECT * INTO #After FROM Layercake.brnz_local_group_detail;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT status, CASE WHEN error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log;
    SELECT v.status, v.has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_error_message);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD030.[test TC-030-010 two source rows with the same local group key fail the bronze load and change nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'CE.vwLocalGroup';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    ALTER TABLE Layercake.brnz_local_group_detail ALTER COLUMN apuk_localgroupid uniqueidentifier NOT NULL;
    ALTER TABLE Layercake.brnz_local_group_detail ADD CONSTRAINT PK_test_MOD030_010_lgd PRIMARY KEY (apuk_localgroupid);
    EXEC test_MOD030.[Insert local group source];

    INSERT INTO Layercake.brnz_local_group_detail (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, market_reporting_region, statecode, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Gulf (old)', N'GULF', 'C0000000-0000-0000-0000-000000000002', N'MEA', 'MEA', 0, '2026-01-01', '2026-01-01', 0, NULL),
           ('A0000000-0000-0000-0000-000000000008', N'Gone Group', N'GONE', 'C0000000-0000-0000-0000-000000000001', N'UK&I', 'UK&I', 0, '2026-01-01', '2026-01-01', 0, NULL);
    INSERT INTO CE.vwLocalGroup (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, Market_reporting_region, statecode)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Gulf Copy', N'GULF2', 'C0000000-0000-0000-0000-000000000002', N'MEA', 'MEA', 0);

    SELECT * INTO #Before FROM Layercake.brnz_local_group_detail;

    DECLARE @raised bit = 0;
    BEGIN TRY
        EXEC Layercake.usp_load_brnz_local_group_detail;
    END TRY
    BEGIN CATCH
        SET @raised = 1;
    END CATCH;
    IF @raised = 0
        EXEC tSQLt.Fail 'Two source rows with the same apuk_localgroupid must fail the load and re-raise';

    SELECT * INTO #After FROM Layercake.brnz_local_group_detail;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT status, CASE WHEN error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log;
    SELECT v.status, v.has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_error_message);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-011 brnz_contact lands rics_localgroupid and a change in it alone updates the row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'CE.vwContact';
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact', @Defaults = 1;

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, GenderCode, rics_countryid, rics_localgroupid, StateCode)
    VALUES ('B0000000-0000-0000-0000-000000000021', N'X1', 1, 'C0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000001', 0),
           ('B0000000-0000-0000-0000-000000000022', N'X2', 1, 'C0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000002', 0),
           ('B0000000-0000-0000-0000-000000000023', N'X3', 1, 'C0000000-0000-0000-0000-000000000003', NULL, 0);
    -- rics_localgroupid is added to brnz_contact by this module, so statements naming it are dynamic
    EXEC sp_executesql N'
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, GenderCode, rics_countryid, rics_localgroupid, StateCode, _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES (''B0000000-0000-0000-0000-000000000022'', N''X2'', 1, ''C0000000-0000-0000-0000-000000000001'', NULL, 0, ''2026-01-01'', ''2026-01-01'', 0, NULL),
           (''B0000000-0000-0000-0000-000000000023'', N''X3'', 1, ''C0000000-0000-0000-0000-000000000003'', NULL, 0, ''2026-01-01'', ''2026-01-01'', 0, NULL);';

    EXEC Layercake.usp_load_brnz_contact;

    SELECT v.ContactId, v.Rics_contactno, v.rics_countryid, v.rics_localgroupid, v._is_deleted, v.updated_at_untouched
    INTO #Expected
    FROM (VALUES
        (CAST('B0000000-0000-0000-0000-000000000021' AS uniqueidentifier), N'X1', CAST('C0000000-0000-0000-0000-000000000001' AS uniqueidentifier), CAST('A0000000-0000-0000-0000-000000000001' AS uniqueidentifier), 0, 0),
        (CAST('B0000000-0000-0000-0000-000000000022' AS uniqueidentifier), N'X2', CAST('C0000000-0000-0000-0000-000000000001' AS uniqueidentifier), CAST('A0000000-0000-0000-0000-000000000002' AS uniqueidentifier), 0, 0),
        (CAST('B0000000-0000-0000-0000-000000000023' AS uniqueidentifier), N'X3', CAST('C0000000-0000-0000-0000-000000000003' AS uniqueidentifier), NULL, 0, 1)
    ) AS v(ContactId, Rics_contactno, rics_countryid, rics_localgroupid, _is_deleted, updated_at_untouched);

    SELECT TOP (0) ContactId, Rics_contactno, rics_countryid, rics_localgroupid, _is_deleted, updated_at_untouched
    INTO #Actual
    FROM #Expected;
    INSERT INTO #Actual (ContactId, Rics_contactno, rics_countryid, rics_localgroupid, _is_deleted, updated_at_untouched)
    EXEC sp_executesql N'
    SELECT ContactId, Rics_contactno, rics_countryid, rics_localgroupid,
           CAST(_is_deleted AS int),
           CASE WHEN _updated_at = ''2026-01-01'' THEN 1 ELSE 0 END
    FROM Layercake.brnz_contact;';

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log;
    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-012 a brnz_contact rerun with rics_localgroupid on unchanged source logs 0 0 0]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'CE.vwContact';
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact', @Defaults = 1;

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, GenderCode, rics_countryid, rics_localgroupid, StateCode)
    VALUES ('B0000000-0000-0000-0000-000000000021', N'X1', 1, 'C0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000001', 0),
           ('B0000000-0000-0000-0000-000000000023', N'X3', 1, 'C0000000-0000-0000-0000-000000000003', NULL, 0);

    EXEC Layercake.usp_load_brnz_contact;
    SELECT * INTO #Before FROM Layercake.brnz_contact;
    EXEC Layercake.usp_load_brnz_contact;
    SELECT * INTO #After FROM Layercake.brnz_contact;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT TOP (1) status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log ORDER BY log_id DESC;
    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-013 the seven groups give nine list rows with the usable test and untouched reserved rows]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC test_MOD030.[Insert reference lists];

    EXEC Layercake.usp_load_silv_ref_local_group;

    SELECT v.local_group_bk, v.local_group_name, v.local_group_code, v.country_id, v.region_name, v.market_reporting_region, v.statecode, v.is_reportable
    INTO #Expected
    FROM (VALUES
        (CAST(NULL AS uniqueidentifier), N'Not applicable', CAST(NULL AS nvarchar(100)), CAST(NULL AS int), CAST(NULL AS nvarchar(100)), CAST(NULL AS varchar(15)), CAST(NULL AS int), 0),
        (CAST(NULL AS uniqueidentifier), N'Unknown', NULL, NULL, NULL, NULL, NULL, 0),
        (CAST('A0000000-0000-0000-0000-000000000001' AS uniqueidentifier), N'Gulf', N'GULF', 2, N'MEA', 'MEA', 0, 1),
        (CAST('A0000000-0000-0000-0000-000000000002' AS uniqueidentifier), N'London', N'LON', 1, N'UK&I', 'UK&I', 0, 1),
        (CAST('A0000000-0000-0000-0000-000000000003' AS uniqueidentifier), N'Gulf India', N'GIND', 3, N'MEA', 'MEA', 0, 1),
        (CAST('A0000000-0000-0000-0000-000000000004' AS uniqueidentifier), N'No Country', N'NOC', NULL, N'MEA', 'MEA', 0, 0),
        (CAST('A0000000-0000-0000-0000-000000000005' AS uniqueidentifier), N'No Region', N'NOR', 2, NULL, NULL, 0, 0),
        (CAST('A0000000-0000-0000-0000-000000000006' AS uniqueidentifier), N'Closed Gulf', N'CGULF', 2, N'MEA', 'MEA', 1, 0),
        (CAST('A0000000-0000-0000-0000-000000000007' AS uniqueidentifier), N'Half Region', N'HALF', 2, N'MEA', NULL, 0, 0)
    ) AS v(local_group_bk, local_group_name, local_group_code, country_id, region_name, market_reporting_region, statecode, is_reportable);

    SELECT local_group_bk, local_group_name, local_group_code, country_id, region_name, market_reporting_region, statecode,
           CAST(is_reportable AS int) AS is_reportable
    INTO #Actual
    FROM Layercake.silv_ref_local_group;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT v.id, v.local_group_name, v.is_reportable, v.load_id, v.created_at, v.updated_at
    INTO #ExpectedReserved
    FROM (VALUES
        (-2, N'Not applicable', 0, CAST(NULL AS bigint), CAST('2026-01-01' AS datetime2(3)), CAST('2026-01-01' AS datetime2(3))),
        (0, N'Unknown', 0, NULL, CAST('2026-01-01' AS datetime2(3)), CAST('2026-01-01' AS datetime2(3)))
    ) AS v(id, local_group_name, is_reportable, load_id, created_at, updated_at);
    SELECT id, local_group_name, CAST(is_reportable AS int) AS is_reportable, load_id, created_at, updated_at
    INTO #ActualReserved
    FROM Layercake.silv_ref_local_group
    WHERE local_group_bk IS NULL;
    EXEC tSQLt.AssertEqualsTable '#ExpectedReserved', '#ActualReserved';

    DECLARE @bad_group_ids int = (SELECT COUNT(*) FROM Layercake.silv_ref_local_group WHERE local_group_bk IS NOT NULL AND id < 1);
    EXEC tSQLt.AssertEquals 0, @bad_group_ids, 'group ids are identity values from 1';

    DECLARE @status varchar(10) = (SELECT TOP (1) status FROM Layercake.etl_run_log ORDER BY log_id DESC);
    EXEC tSQLt.AssertEqualsString 'Success', @status;
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-014 Gulf takes the UAE row London the UK row and Gulf India a combination row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC test_MOD030.[Insert reference lists];

    EXEC Layercake.usp_load_silv_ref_local_group;

    SELECT v.local_group_name, v.dim_country_id_is_null, v.own_country_id, v.combination_country_ref_id, v.combination_region_name, v.combination_market_reporting_region
    INTO #Expected
    FROM (VALUES
        (N'Not applicable', 1, CAST(NULL AS int), CAST(NULL AS int), CAST(NULL AS nvarchar(200)), CAST(NULL AS varchar(15))),
        (N'Unknown', 1, NULL, NULL, NULL, NULL),
        (N'Gulf', 0, 2, NULL, NULL, NULL),
        (N'London', 0, 1, NULL, NULL, NULL),
        (N'Gulf India', 0, NULL, 3, N'MEA', 'MEA'),
        (N'No Country', 1, NULL, NULL, NULL, NULL),
        (N'No Region', 1, NULL, NULL, NULL, NULL),
        (N'Closed Gulf', 1, NULL, NULL, NULL, NULL),
        (N'Half Region', 1, NULL, NULL, NULL, NULL)
    ) AS v(local_group_name, dim_country_id_is_null, own_country_id, combination_country_ref_id, combination_region_name, combination_market_reporting_region);

    SELECT lg.local_group_name,
           CASE WHEN lg.dim_country_id IS NULL THEN 1 ELSE 0 END AS dim_country_id_is_null,
           c.id AS own_country_id,
           r.country_ref_id AS combination_country_ref_id,
           r.region_name AS combination_region_name,
           r.market_reporting_region AS combination_market_reporting_region
    INTO #Actual
    FROM Layercake.silv_ref_local_group AS lg
    LEFT JOIN Layercake.silv_ref_country AS c ON c.id = lg.dim_country_id
    LEFT JOIN Layercake.silv_ref_country_region AS r ON r.id = lg.dim_country_id;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT v.country_ref_id, v.region_name, v.market_reporting_region
    INTO #ExpectedRegion
    FROM (VALUES (3, N'MEA', CAST('MEA' AS varchar(15)))) AS v(country_ref_id, region_name, market_reporting_region);
    SELECT country_ref_id, region_name, market_reporting_region
    INTO #ActualRegion
    FROM Layercake.silv_ref_country_region;
    EXEC tSQLt.AssertEqualsTable '#ExpectedRegion', '#ActualRegion';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-015 the local group load leaves silv_ref_country unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC test_MOD030.[Insert reference lists];

    SELECT * INTO #Before FROM Layercake.silv_ref_country;
    EXEC Layercake.usp_load_silv_ref_local_group;
    SELECT * INTO #After FROM Layercake.silv_ref_country;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-016 a local group list rerun on unchanged data keeps every row and id and logs 0 0 0]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC test_MOD030.[Insert reference lists];

    EXEC Layercake.usp_load_silv_ref_local_group;
    SELECT * INTO #BeforeList FROM Layercake.silv_ref_local_group;
    SELECT * INTO #BeforeRegion FROM Layercake.silv_ref_country_region;
    EXEC Layercake.usp_load_silv_ref_local_group;
    SELECT * INTO #AfterList FROM Layercake.silv_ref_local_group;
    SELECT * INTO #AfterRegion FROM Layercake.silv_ref_country_region;

    EXEC tSQLt.AssertEqualsTable '#BeforeList', '#AfterList';
    EXEC tSQLt.AssertEqualsTable '#BeforeRegion', '#AfterRegion';

    SELECT TOP (1) status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log ORDER BY log_id DESC;
    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-017 renaming Gulf in the source updates its name and keeps every id]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC test_MOD030.[Insert reference lists];

    EXEC Layercake.usp_load_silv_ref_local_group;
    SELECT id, local_group_bk INTO #BeforeIds FROM Layercake.silv_ref_local_group;

    UPDATE Layercake.brnz_local_group_detail SET apuk_name = N'Gulf Region', _updated_at = '2026-02-01'
    WHERE apuk_localgroupid = 'A0000000-0000-0000-0000-000000000001';
    EXEC Layercake.usp_load_silv_ref_local_group;

    SELECT id, local_group_bk INTO #AfterIds FROM Layercake.silv_ref_local_group;
    EXEC tSQLt.AssertEqualsTable '#BeforeIds', '#AfterIds';

    DECLARE @name nvarchar(100) = (SELECT local_group_name FROM Layercake.silv_ref_local_group
                                   WHERE local_group_bk = 'A0000000-0000-0000-0000-000000000001');
    EXEC tSQLt.AssertEqualsString N'Gulf Region', @name;
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-018 a country not in silv_ref_country a null statecode and an empty or spaces region make a group not usable]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC test_MOD030.[Insert reference lists];
    INSERT INTO Layercake.brnz_local_group_detail (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, market_reporting_region, statecode, _is_deleted, _deleted_at)
    VALUES ('A0000000-0000-0000-0000-000000000011', N'Unknown Country', N'UNC', 'C0000000-0000-0000-0000-000000000099', N'MEA', 'MEA', 0, 0, NULL),
           ('A0000000-0000-0000-0000-000000000012', N'Null State', N'NST', 'C0000000-0000-0000-0000-000000000002', N'MEA', 'MEA', NULL, 0, NULL),
           ('A0000000-0000-0000-0000-000000000013', N'Empty Region', N'EMP', 'C0000000-0000-0000-0000-000000000002', N'', 'MEA', 0, 0, NULL),
           ('A0000000-0000-0000-0000-000000000014', N'Spaced Region', N'SPC', 'C0000000-0000-0000-0000-000000000002', N'   ', 'MEA', 0, 0, NULL);

    EXEC Layercake.usp_load_silv_ref_local_group;

    SELECT v.local_group_name, v.country_id, v.region_name_is_null, v.market_reporting_region, v.is_reportable, v.dim_country_id_is_null
    INTO #Expected
    FROM (VALUES
        (N'Unknown Country', CAST(NULL AS int), 0, CAST('MEA' AS varchar(15)), 0, 1),
        (N'Null State', 2, 0, 'MEA', 0, 1),
        (N'Empty Region', 2, 1, 'MEA', 0, 1),
        (N'Spaced Region', 2, 1, 'MEA', 0, 1)
    ) AS v(local_group_name, country_id, region_name_is_null, market_reporting_region, is_reportable, dim_country_id_is_null);

    SELECT local_group_name, country_id,
           CASE WHEN region_name IS NULL THEN 1 ELSE 0 END AS region_name_is_null,
           market_reporting_region,
           CAST(is_reportable AS int) AS is_reportable,
           CASE WHEN dim_country_id IS NULL THEN 1 ELSE 0 END AS dim_country_id_is_null
    INTO #Actual
    FROM Layercake.silv_ref_local_group
    WHERE local_group_bk IN ('A0000000-0000-0000-0000-000000000011', 'A0000000-0000-0000-0000-000000000012',
                             'A0000000-0000-0000-0000-000000000013', 'A0000000-0000-0000-0000-000000000014');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-019 a group made inactive or gone from bronze stays in the list with its id but is not reportable]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC test_MOD030.[Insert reference lists];

    EXEC Layercake.usp_load_silv_ref_local_group;
    SELECT id, local_group_bk INTO #BeforeIds FROM Layercake.silv_ref_local_group;

    UPDATE Layercake.brnz_local_group_detail SET statecode = 1, _updated_at = '2026-02-01'
    WHERE apuk_localgroupid = 'A0000000-0000-0000-0000-000000000001';
    UPDATE Layercake.brnz_local_group_detail SET _is_deleted = 1, _deleted_at = '2026-02-01', _updated_at = '2026-02-01'
    WHERE apuk_localgroupid = 'A0000000-0000-0000-0000-000000000002';
    EXEC Layercake.usp_load_silv_ref_local_group;

    SELECT id, local_group_bk INTO #AfterIds FROM Layercake.silv_ref_local_group;
    EXEC tSQLt.AssertEqualsTable '#BeforeIds', '#AfterIds';

    SELECT v.local_group_name, v.statecode, v.is_reportable, v.dim_country_id_is_null
    INTO #Expected
    FROM (VALUES
        (N'Gulf', 1, 0, 1),
        (N'London', 0, 0, 1),
        (N'Gulf India', 0, 1, 0)
    ) AS v(local_group_name, statecode, is_reportable, dim_country_id_is_null);

    SELECT local_group_name, statecode, CAST(is_reportable AS int) AS is_reportable,
           CASE WHEN dim_country_id IS NULL THEN 1 ELSE 0 END AS dim_country_id_is_null
    INTO #Actual
    FROM Layercake.silv_ref_local_group
    WHERE local_group_bk IN ('A0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000002', 'A0000000-0000-0000-0000-000000000003');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-020 a change of the Gulf regions to GCC adds a combination row and keeps the old one]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC test_MOD030.[Insert reference lists];

    EXEC Layercake.usp_load_silv_ref_local_group;
    DECLARE @old_region_id int = (SELECT id FROM Layercake.silv_ref_country_region WHERE country_ref_id = 3);

    UPDATE Layercake.brnz_local_group_detail
    SET apuk_worldregionid_name = N'GCC', market_reporting_region = 'GCC', _updated_at = '2026-02-01'
    WHERE apuk_localgroupid = 'A0000000-0000-0000-0000-000000000001';
    EXEC Layercake.usp_load_silv_ref_local_group;

    SELECT v.country_ref_id, v.region_name, v.market_reporting_region
    INTO #ExpectedRegion
    FROM (VALUES (3, N'MEA', CAST('MEA' AS varchar(15))), (2, N'GCC', 'GCC')) AS v(country_ref_id, region_name, market_reporting_region);
    SELECT country_ref_id, region_name, market_reporting_region INTO #ActualRegion FROM Layercake.silv_ref_country_region;
    EXEC tSQLt.AssertEqualsTable '#ExpectedRegion', '#ActualRegion';

    DECLARE @kept_id int = (SELECT id FROM Layercake.silv_ref_country_region WHERE country_ref_id = 3);
    EXEC tSQLt.AssertEquals @old_region_id, @kept_id, 'the MEA combination row keeps its id';

    SELECT v.region_name, v.market_reporting_region, v.is_reportable, v.combination_country_ref_id, v.combination_region_name, v.combination_market_reporting_region
    INTO #Expected
    FROM (VALUES (N'GCC', CAST('GCC' AS varchar(15)), 1, 2, N'GCC', CAST('GCC' AS varchar(15))))
         AS v(region_name, market_reporting_region, is_reportable, combination_country_ref_id, combination_region_name, combination_market_reporting_region);
    SELECT lg.region_name, lg.market_reporting_region, CAST(lg.is_reportable AS int) AS is_reportable,
           r.country_ref_id AS combination_country_ref_id, r.region_name AS combination_region_name, r.market_reporting_region AS combination_market_reporting_region
    INTO #Actual
    FROM Layercake.silv_ref_local_group AS lg
    LEFT JOIN Layercake.silv_ref_country_region AS r ON r.id = lg.dim_country_id
    WHERE lg.local_group_bk = 'A0000000-0000-0000-0000-000000000001';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-021 every member gets all of a usable group values or local group 0 with all of its own country values]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact', @Defaults = 1;
    EXEC test_MOD030.[Insert reference lists];
    EXEC test_MOD030.[Insert contacts];

    EXEC Layercake.usp_load_silv_ref_local_group;

    SELECT v.contact_no, v.contact_country_id, v.local_group, v.country_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region
    INTO #Expected
    FROM (VALUES
        (N'G1', 1, N'Gulf', 2, N'MEA', CAST('MEA' AS varchar(15)), N'UK&I', CAST('UK&I' AS varchar(15))),
        (N'G2', 3, N'Gulf India', 3, N'MEA', 'MEA', N'APAC', 'APAC'),
        (N'N1', 3, N'0', 3, N'APAC', 'APAC', N'APAC', 'APAC'),
        (N'N2', 3, N'0', 3, N'APAC', 'APAC', N'APAC', 'APAC'),
        (N'N3', 1, N'0', 1, N'UK&I', 'UK&I', N'UK&I', 'UK&I'),
        (N'N4', 1, N'0', 1, N'UK&I', 'UK&I', N'UK&I', 'UK&I'),
        (N'N5', 1, N'0', 1, N'UK&I', 'UK&I', N'UK&I', 'UK&I'),
        (N'N6', 1, N'0', 1, N'UK&I', 'UK&I', N'UK&I', 'UK&I'),
        (N'L1', 1, N'London', 1, N'UK&I', 'UK&I', N'UK&I', 'UK&I')
    ) AS v(contact_no, contact_country_id, local_group, country_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region);

    SELECT v.contact_no, v.contact_country_id,
           CASE WHEN v.local_group_id IN (0, -2) THEN CAST(v.local_group_id AS nvarchar(100)) ELSE lg.local_group_name END AS local_group,
           v.country_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region
    INTO #Actual
    FROM Layercake.vw_silv_contact_local_group AS v
    LEFT JOIN Layercake.silv_ref_local_group AS lg ON lg.id = v.local_group_id;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-022 once Gulf is made inactive G1 takes local group 0 and all of its own country values]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.brnz_local_group_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact', @Defaults = 1;
    EXEC test_MOD030.[Insert reference lists];
    EXEC test_MOD030.[Insert contacts];

    EXEC Layercake.usp_load_silv_ref_local_group;
    UPDATE Layercake.brnz_local_group_detail SET statecode = 1, _updated_at = '2026-02-01'
    WHERE apuk_localgroupid = 'A0000000-0000-0000-0000-000000000001';
    EXEC Layercake.usp_load_silv_ref_local_group;

    SELECT v.contact_no, v.contact_country_id, v.local_group_id, v.country_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region
    INTO #Expected
    FROM (VALUES (N'G1', 1, 0, 1, N'UK&I', CAST('UK&I' AS varchar(15)), N'UK&I', CAST('UK&I' AS varchar(15))))
         AS v(contact_no, contact_country_id, local_group_id, country_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region);

    SELECT contact_no, contact_country_id, local_group_id, country_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region
    INTO #Actual
    FROM Layercake.vw_silv_contact_local_group
    WHERE contact_no = N'G1';

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-023 dim_local_group mirrors the nine list rows including both reserved rows]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group';
    EXEC tSQLt.FakeTable 'Layercake.dim_local_group', @Defaults = 1;
    EXEC test_MOD030.[Insert local group list];

    EXEC Layercake.usp_load_dim_local_group;

    SELECT v.id, v.local_group_name
    INTO #Expected
    FROM (VALUES
        (-2, N'Not applicable'), (0, N'Unknown'), (1, N'Gulf'), (2, N'London'), (3, N'Gulf India'),
        (4, N'No Country'), (5, N'No Region'), (6, N'Closed Gulf'), (7, N'Half Region')
    ) AS v(id, local_group_name);

    SELECT id, local_group_name INTO #Actual FROM Layercake.dim_local_group;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @status varchar(10) = (SELECT TOP (1) status FROM Layercake.etl_run_log ORDER BY log_id DESC);
    EXEC tSQLt.AssertEqualsString 'Success', @status;
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-024 dim_local_group updates a renamed group in place and leaves unchanged rows untouched]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group';
    EXEC tSQLt.FakeTable 'Layercake.dim_local_group', @Defaults = 1;
    EXEC test_MOD030.[Insert local group list];
    UPDATE Layercake.silv_ref_local_group SET local_group_name = N'Gulf Region', updated_at = '2026-02-01' WHERE id = 1;
    INSERT INTO Layercake.dim_local_group (id, local_group_name, load_id, created_at, updated_at)
    VALUES (-2, N'Not applicable', 11, '2026-01-01', '2026-01-01'), (0, N'Unknown', 11, '2026-01-01', '2026-01-01'),
           (1, N'Gulf', 11, '2026-01-01', '2026-01-01'), (2, N'London', 11, '2026-01-01', '2026-01-01'),
           (3, N'Gulf India', 11, '2026-01-01', '2026-01-01'), (4, N'No Country', 11, '2026-01-01', '2026-01-01'),
           (5, N'No Region', 11, '2026-01-01', '2026-01-01'), (6, N'Closed Gulf', 11, '2026-01-01', '2026-01-01'),
           (7, N'Half Region', 11, '2026-01-01', '2026-01-01');
    SELECT * INTO #BeforeUntouched FROM Layercake.dim_local_group WHERE id <> 1;

    EXEC Layercake.usp_load_dim_local_group;

    SELECT * INTO #AfterUntouched FROM Layercake.dim_local_group WHERE id <> 1;
    EXEC tSQLt.AssertEqualsTable '#BeforeUntouched', '#AfterUntouched';

    SELECT v.id, v.local_group_name INTO #Expected FROM (VALUES (1, N'Gulf Region')) AS v(id, local_group_name);
    SELECT id, local_group_name INTO #Actual FROM Layercake.dim_local_group WHERE id = 1;
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT * INTO #BeforeRerun FROM Layercake.dim_local_group;
    EXEC Layercake.usp_load_dim_local_group;
    SELECT * INTO #AfterRerun FROM Layercake.dim_local_group;
    EXEC tSQLt.AssertEqualsTable '#BeforeRerun', '#AfterRerun';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-025 the bronze step runs the local group landing once with the other bronze loads under its run_id]
AS
BEGIN
    CREATE TABLE #calls (call_no int IDENTITY(1, 1) NOT NULL, proc_name nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL, run_id uniqueidentifier NULL);
    EXEC test_MOD030.[Spy and record] N'usp_load_brnz_contact';
    EXEC test_MOD030.[Spy and record] N'usp_load_brnz_enrolment';
    EXEC test_MOD030.[Spy and record] N'usp_load_brnz_rics_record';
    EXEC test_MOD030.[Spy and record] N'usp_load_brnz_local_group';
    EXEC test_MOD030.[Spy and record] N'usp_load_brnz_local_group_detail';
    EXEC test_MOD030.[Spy and record] N'usp_load_brnz_cust_trans';
    EXEC test_MOD030.[Spy and record] N'usp_load_brnz_subs_status';
    EXEC test_MOD030.[Spy and record] N'usp_load_brnz_option_set';
    EXEC test_MOD030.[Spy and record] N'usp_load_brnz_route';
    EXEC test_MOD030.[Spy and record] N'usp_load_brnz_contact_test_record';

    DECLARE @run_id uniqueidentifier = 'E0000000-0000-0000-0000-000000000030';
    EXEC Layercake.usp_load_bronze @run_id = @run_id;

    SELECT v.proc_name, v.calls, v.calls_with_run_id
    INTO #Expected
    FROM (VALUES
        (N'usp_load_brnz_contact', 1, 1), (N'usp_load_brnz_enrolment', 1, 1), (N'usp_load_brnz_rics_record', 1, 1),
        (N'usp_load_brnz_local_group', 1, 1), (N'usp_load_brnz_local_group_detail', 1, 1), (N'usp_load_brnz_cust_trans', 1, 1),
        (N'usp_load_brnz_subs_status', 1, 1), (N'usp_load_brnz_option_set', 1, 1), (N'usp_load_brnz_route', 1, 1),
        (N'usp_load_brnz_contact_test_record', 1, 1)
    ) AS v(proc_name, calls, calls_with_run_id);

    SELECT proc_name, COUNT(*) AS calls, SUM(CASE WHEN run_id = @run_id THEN 1 ELSE 0 END) AS calls_with_run_id
    INTO #Actual
    FROM #calls
    GROUP BY proc_name;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-026 the silver step runs the local group list after the country list and before the member base]
AS
BEGIN
    CREATE TABLE #calls (call_no int IDENTITY(1, 1) NOT NULL, proc_name nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL, run_id uniqueidentifier NULL);
    EXEC test_MOD030.[Spy and record] N'usp_load_silv_ref_assessment_route';
    EXEC test_MOD030.[Spy and record] N'usp_load_silv_ref_rpq_variant';
    EXEC test_MOD030.[Spy and record] N'usp_load_silv_ref_country';
    EXEC test_MOD030.[Spy and record] N'usp_load_silv_ref_lapse_reason';
    EXEC test_MOD030.[Spy and record] N'usp_load_silv_ref_local_group';
    EXEC test_MOD030.[Spy and record] N'usp_load_ref_date_spine';
    EXEC test_MOD030.[Spy and record] N'usp_load_ref_campaign_year_config';
    EXEC test_MOD030.[Spy and record] N'usp_load_silv_payment_events';
    EXEC test_MOD030.[Spy and record] N'usp_load_ref_enrolment_exception';
    EXEC test_MOD030.[Spy and record] N'usp_load_silv_member_base';
    EXEC test_MOD030.[Spy and record] N'usp_load_silv_membership_events';
    EXEC test_MOD030.[Spy and record] N'usp_load_silv_data_anomaly';
    EXEC test_MOD030.[Spy and record] N'usp_load_silv_member_state_ranges';
    EXEC test_MOD030.[Spy and record] N'usp_load_silv_member_profile';
    EXEC test_MOD030.[Spy and record] N'usp_load_silv_daily_count';
    EXEC test_MOD030.[Spy and record] N'usp_load_silv_annual_rate_base';

    DECLARE @run_id uniqueidentifier = 'E0000000-0000-0000-0000-000000000031';
    EXEC Layercake.usp_load_silver @run_id = @run_id;

    DECLARE @lg_calls int = (SELECT COUNT(*) FROM #calls WHERE proc_name = N'usp_load_silv_ref_local_group' AND run_id = @run_id);
    EXEC tSQLt.AssertEquals 1, @lg_calls, 'usp_load_silv_ref_local_group runs once under the run_id';

    DECLARE @in_order int =
        (SELECT CASE WHEN MAX(CASE WHEN proc_name = N'usp_load_silv_ref_country' THEN call_no END)
                        < MAX(CASE WHEN proc_name = N'usp_load_silv_ref_local_group' THEN call_no END)
                      AND MAX(CASE WHEN proc_name = N'usp_load_silv_ref_local_group' THEN call_no END)
                        < MIN(CASE WHEN proc_name = N'usp_load_silv_member_base' THEN call_no END)
                     THEN 1 ELSE 0 END
         FROM #calls);
    EXEC tSQLt.AssertEquals 1, @in_order, 'the local group list runs after usp_load_silv_ref_country and before usp_load_silv_member_base';

    DECLARE @steps int = (SELECT COUNT(DISTINCT proc_name) FROM #calls);
    EXEC tSQLt.AssertEquals 16, @steps, 'every silver step still runs';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-027 the gold step runs dim_local_group and dim_country before every fact load]
AS
BEGIN
    CREATE TABLE #calls (call_no int IDENTITY(1, 1) NOT NULL, proc_name nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL, run_id uniqueidentifier NULL);
    EXEC test_MOD030.[Spy and record] N'usp_load_dim_membership_grade';
    EXEC test_MOD030.[Spy and record] N'usp_load_dim_assessment_route';
    EXEC test_MOD030.[Spy and record] N'usp_load_dim_rpq_variant';
    EXEC test_MOD030.[Spy and record] N'usp_load_dim_country';
    EXEC test_MOD030.[Spy and record] N'usp_load_dim_local_group';
    EXEC test_MOD030.[Spy and record] N'usp_load_dim_gender';
    EXEC test_MOD030.[Spy and record] N'usp_load_dim_membership_status';
    EXEC test_MOD030.[Spy and record] N'usp_load_dim_lapse_reason';
    EXEC test_MOD030.[Spy and record] N'usp_load_dim_campaign_year';
    EXEC test_MOD030.[Spy and record] N'usp_load_dim_date';
    EXEC test_MOD030.[Spy and record] N'usp_load_fact_membership_events';
    EXEC test_MOD030.[Spy and record] N'usp_load_fact_daily_member_count_detail';
    EXEC test_MOD030.[Spy and record] N'usp_load_fact_annual_rate_base';

    DECLARE @run_id uniqueidentifier = 'E0000000-0000-0000-0000-000000000032';
    EXEC Layercake.usp_load_gold @run_id = @run_id;

    DECLARE @lg_calls int = (SELECT COUNT(*) FROM #calls WHERE proc_name = N'usp_load_dim_local_group' AND run_id = @run_id);
    EXEC tSQLt.AssertEquals 1, @lg_calls, 'usp_load_dim_local_group runs once under the run_id';

    DECLARE @in_order int =
        (SELECT CASE WHEN MAX(CASE WHEN proc_name IN (N'usp_load_dim_local_group', N'usp_load_dim_country') THEN call_no END)
                        < MIN(CASE WHEN proc_name LIKE N'usp[_]load[_]fact[_]%' THEN call_no END)
                      AND COUNT(CASE WHEN proc_name = N'usp_load_dim_country' THEN 1 END) = 1
                     THEN 1 ELSE 0 END
         FROM #calls);
    EXEC tSQLt.AssertEquals 1, @in_order, 'dim_local_group and dim_country both run before the first fact load';

    DECLARE @steps int = (SELECT COUNT(DISTINCT proc_name) FROM #calls);
    EXEC tSQLt.AssertEquals 13, @steps, 'every gold step still runs';
END;
GO
CREATE PROCEDURE test_MOD030.[test TC-030-028 silv_ref_local_group holds the seeded reserved rows 0 Unknown and -2 Not applicable]
AS
BEGIN
    SELECT v.id, v.local_group_bk, v.local_group_name, v.is_reportable, v.dim_country_id
    INTO #Expected
    FROM (VALUES
        (-2, CAST(NULL AS uniqueidentifier), N'Not applicable', 0, CAST(NULL AS int)),
        (0, CAST(NULL AS uniqueidentifier), N'Unknown', 0, CAST(NULL AS int))
    ) AS v(id, local_group_bk, local_group_name, is_reportable, dim_country_id);

    SELECT id, local_group_bk, local_group_name, CAST(is_reportable AS int) AS is_reportable, dim_country_id
    INTO #Actual
    FROM Layercake.silv_ref_local_group
    WHERE id IN (0, -2);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
