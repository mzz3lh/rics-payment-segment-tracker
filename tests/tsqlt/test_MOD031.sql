EXEC tSQLt.NewTestClass 'test_MOD031';
GO

CREATE PROCEDURE test_MOD031.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_rics_record', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_cust_trans', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact_test_record', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_enrolment', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_route', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_enrolment_exception', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_rpq_variant';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_lapse_reason';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_gender';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_grade';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_status';
    EXEC tSQLt.FakeTable 'Layercake.ref_date_spine';
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_base', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_profile', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_state_ranges', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_loaded', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_pending_rebuild', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_input_basis', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_contact', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_state_range', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_event', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_payment', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_attribute', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_cell_contacts', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_daily_member_count_detail', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_date';
    EXEC tSQLt.FakeTable 'Layercake.dim_membership_grade';
    EXEC tSQLt.FakeTable 'Layercake.dim_country';

    INSERT INTO Layercake.silv_ref_country (id, country_id, country_name, region_name, market_reporting_region)
    VALUES (1, 'C0000000-0000-0000-0000-000000000001', N'United Kingdom', N'UK&I', 'UK&I'),
           (2, 'C0000000-0000-0000-0000-000000000002', N'United Arab Emirates', N'MEA', 'MEA'),
           (3, 'C0000000-0000-0000-0000-000000000003', N'India', N'APAC', 'APAC');

    INSERT INTO Layercake.dim_country (id, country_id, country_name, region_name, market_reporting_region)
    VALUES (1, 'C0000000-0000-0000-0000-000000000001', N'United Kingdom', N'UK&I', 'UK&I'),
           (2, 'C0000000-0000-0000-0000-000000000002', N'United Arab Emirates', N'MEA', 'MEA'),
           (3, 'C0000000-0000-0000-0000-000000000003', N'India', N'APAC', 'APAC'),
           (1000001, 'C0000000-0000-0000-0000-000000000003', N'India', N'MEA', 'MEA');

    INSERT INTO Layercake.silv_ref_local_group
        (id, local_group_bk, local_group_name, local_group_code, country_id, region_name, market_reporting_region,
         statecode, is_reportable, dim_country_id, load_id, created_at, updated_at)
    VALUES (-2, NULL, N'Not applicable', NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-01-01', '2026-01-01'),
           (0, NULL, N'Unknown', NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-01-01', '2026-01-01'),
           (1, 'A0000000-0000-0000-0000-000000000001', N'Gulf', N'GULF', 2, N'MEA', 'MEA', 0, 1, 2, 1, '2026-01-01', '2026-01-01'),
           (2, 'A0000000-0000-0000-0000-000000000002', N'London', N'LON', 1, N'UK&I', 'UK&I', 0, 1, 1, 1, '2026-01-01', '2026-01-01'),
           (3, 'A0000000-0000-0000-0000-000000000003', N'Gulf India', N'GIND', 3, N'MEA', 'MEA', 0, 1, 1000001, 1, '2026-01-01', '2026-01-01'),
           (4, 'A0000000-0000-0000-0000-000000000004', N'No Country', N'NOC', NULL, N'MEA', 'MEA', 0, 0, NULL, 1, '2026-01-01', '2026-01-01'),
           (5, 'A0000000-0000-0000-0000-000000000005', N'No Region', N'NOR', 2, NULL, NULL, 0, 0, NULL, 1, '2026-01-01', '2026-01-01'),
           (6, 'A0000000-0000-0000-0000-000000000006', N'Closed Gulf', N'CGULF', 2, N'MEA', 'MEA', 1, 0, NULL, 1, '2026-01-01', '2026-01-01'),
           (7, 'A0000000-0000-0000-0000-000000000007', N'Half Region', N'HALF', 2, N'MEA', NULL, 0, 0, NULL, 1, '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.silv_ref_gender (id, gender_code, gender_name)
    VALUES (1, 1, 'Male'), (2, 2, 'Female');

    INSERT INTO Layercake.silv_ref_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');

    INSERT INTO Layercake.dim_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');

    INSERT INTO Layercake.silv_ref_membership_status (id, status_name)
    VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2021, '2020-10-01', '2021-09-30', '2021-09-30'),
           (2022, '2021-10-01', '2022-09-30', '2022-09-30'),
           (2023, '2022-10-01', '2023-09-30', '2023-09-30'),
           (2024, '2023-10-01', '2024-09-30', '2024-09-30'),
           (2025, '2024-10-01', '2025-09-30', '2025-09-30'),
           (2026, '2025-10-01', '2026-09-30', '2026-09-30'),
           (2027, '2026-10-01', '2027-09-30', '2027-09-30');
END;
GO

CREATE PROCEDURE test_MOD031.[Add date]
    @date date,
    @date_id int,
    @campaign_year int,
    @campaign_quarter char(2)
AS
BEGIN
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES (@date, @campaign_year, @campaign_quarter);

    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (@date_id, @date, @campaign_year, @campaign_quarter);
END;
GO

CREATE PROCEDURE test_MOD031.[Add member]
    @contact_no nvarchar(100),
    @own_country_id int,
    @local_group_bk uniqueidentifier,
    @gender_id int = 1
AS
BEGIN
    DECLARE @contact_id uniqueidentifier = NEWID();
    DECLARE @country_guid uniqueidentifier = (SELECT c.country_id FROM Layercake.silv_ref_country AS c WHERE c.id = @own_country_id);
    DECLARE @recid bigint = (SELECT ISNULL(MAX(t.recid), 0) + 1 FROM Layercake.brnz_cust_trans AS t);

    INSERT INTO Layercake.brnz_contact
        (ContactId, Rics_contactno, GenderCode, rics_countryid, rics_localgroupid, StateCode, CreatedOn,
         _loaded_at, _updated_at, _is_deleted)
    VALUES (@contact_id, @contact_no, @gender_id, @country_guid, @local_group_bk, 0, '2014-01-01',
            '2026-01-01', '2026-01-01', 0);

    INSERT INTO Layercake.brnz_rics_record
        (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_membergrade, statecode, ModifiedOn,
         _loaded_at, _updated_at, _is_deleted)
    VALUES (NEWID(), @contact_id, @contact_no, NULL, 0, '2020-01-01', '2026-01-01', '2026-01-01', 0);

    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, transdate, amountcur, approved, _loaded_at, _updated_at, _is_deleted)
    VALUES (@recid, @contact_no, '2015-01-01', 100, 1, '2026-01-01', '2026-01-01', 0);

    INSERT INTO Layercake.silv_membership_events
        (event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (N'JR:' + @contact_no, 'Join', 'Direct Entry', '2015-01-01', @contact_no, 2, 0, 0, 0,
            @own_country_id, @gender_id, 1, 2015, 'Q2', -2, 0, -2, 0, -2, 0);
END;
GO

CREATE PROCEDURE test_MOD031.[Add renewal]
    @contact_no nvarchar(200),
    @event_date date,
    @campaign_year int,
    @campaign_quarter char(2),
    @own_country_id int
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events
        (event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (N'RN:' + @contact_no + N':' + CAST(@campaign_year AS nvarchar(4)), 'Renewal', 'Standard', @event_date, @contact_no, 2, 0, 0, 0,
            @own_country_id, 1, 1, @campaign_year, @campaign_quarter, 0, 0, 0, 0, 0, 0);
END;
GO

CREATE PROCEDURE test_MOD031.[Run members]
    @run_id uniqueidentifier
AS
BEGIN
    EXEC Layercake.usp_load_silv_member_base @run_id = @run_id;
    EXEC Layercake.usp_load_silv_member_state_ranges @run_id = @run_id;
    EXEC Layercake.usp_load_silv_member_profile @run_id = @run_id;
END;
GO

CREATE PROCEDURE test_MOD031.[Run chain]
    @run_id uniqueidentifier,
    @with_gold bit = 1
AS
BEGIN
    EXEC test_MOD031.[Run members] @run_id = @run_id;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @run_id;
    IF @with_gold = 1
        EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @run_id;
END;
GO

CREATE PROCEDURE test_MOD031.[Get path]
    @run_id uniqueidentifier,
    @contacts_recomputed int OUTPUT,
    @full_recompute_path int OUTPUT
AS
BEGIN
    SELECT @contacts_recomputed = MAX(CASE WHEN p.substep = N'contacts_recomputed' THEN p.rows_affected END),
           @full_recompute_path = MAX(CASE WHEN p.substep = N'full_recompute_path' THEN p.rows_affected END)
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l
        ON l.log_id = p.log_id
    WHERE l.run_id = @run_id;
END;
GO

CREATE PROCEDURE test_MOD031.[Simulate deployment]
    @marker_run_id uniqueidentifier,
    @both_markers bit = 0
AS
BEGIN
    EXEC (N'UPDATE Layercake.silv_daily_count_detail SET region = contact_region, country_id = contact_country_id, local_group_id = 0;
UPDATE Layercake.etl_daily_count_cell_contacts SET region = contact_region, country_id = contact_country_id, local_group_id = 0;
UPDATE Layercake.fact_daily_member_count_detail SET country_id = contact_country_id, local_group_id = 0;
UPDATE Layercake.silv_member_base SET country_id = contact_country_id, local_group_id = 0;
UPDATE Layercake.silv_member_profile SET country_id = contact_country_id, local_group_id = 0;
UPDATE Layercake.silv_member_state_ranges SET region = contact_region;');

    IF @both_markers = 1
    BEGIN
        UPDATE Layercake.silv_daily_count_detail SET payment_method_id = -2, payer_type_id = -2, concession_type_id = -2;
        UPDATE Layercake.etl_daily_count_cell_contacts SET payment_method_id = -2, payer_type_id = -2, concession_type_id = -2;
        UPDATE Layercake.fact_daily_member_count_detail SET payment_method_id = -2, payer_type_id = -2, concession_type_id = -2;
        INSERT INTO Layercake.etl_daily_count_input_basis (input_name, input_key, input_fingerprint, earliest_affected_date, run_id, updated_at)
        VALUES ('detail_grain_restatement', N'', 0x00, '2020-10-01', @marker_run_id, '2026-01-01');
    END;

    DELETE FROM Layercake.silv_daily_count;
    INSERT INTO Layercake.silv_daily_count
        ([date], campaign_year, campaign_quarter, region, grade, active_count, paid_count, paid_count_event,
         event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    SELECT d.[date], d.campaign_year, d.campaign_quarter, d.region, d.grade, SUM(d.active_count), SUM(d.paid_count), SUM(d.paid_count_event),
           SUM(d.event_join_count), SUM(d.event_renewal_count), SUM(d.event_readmission_count), SUM(d.event_lapse_count)
    FROM Layercake.silv_daily_count_detail AS d
    GROUP BY d.[date], d.campaign_year, d.campaign_quarter, d.region, d.grade;

    DELETE FROM Layercake.etl_daily_count_applied_contact;
    DELETE FROM Layercake.etl_daily_count_applied_state_range;
    DELETE FROM Layercake.etl_daily_count_applied_event;
    DELETE FROM Layercake.etl_daily_count_applied_payment;
    DELETE FROM Layercake.etl_daily_count_applied_attribute;

    INSERT INTO Layercake.etl_daily_count_input_basis (input_name, input_key, input_fingerprint, earliest_affected_date, run_id, updated_at)
    VALUES ('local_group_restatement', N'', 0x00, '2020-10-01', @marker_run_id, '2026-01-01');
END;
GO

CREATE PROCEDURE test_MOD031.[Assert members]
AS
BEGIN
    EXEC (N'SELECT contact_no, country_id, local_group_id, contact_country_id INTO #ActualBase FROM Layercake.silv_member_base;
EXEC tSQLt.AssertEqualsTable ''#ExpMembers'', ''#ActualBase'', ''silv_member_base'';
SELECT contact_no, country_id, local_group_id, contact_country_id INTO #ActualProfile FROM Layercake.silv_member_profile;
EXEC tSQLt.AssertEqualsTable ''#ExpMembers'', ''#ActualProfile'', ''silv_member_profile'';');
END;
GO

CREATE PROCEDURE test_MOD031.[Assert ranges]
AS
BEGIN
    EXEC (N'SELECT contact_no, valid_from, valid_to, grade, region, contact_region INTO #ActualRanges FROM Layercake.silv_member_state_ranges;
EXEC tSQLt.AssertEqualsTable ''#ExpRanges'', ''#ActualRanges'', ''silv_member_state_ranges'';');
END;
GO

CREATE PROCEDURE test_MOD031.[Assert detail]
AS
BEGIN
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
       local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
       event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
INTO #ActualDetail
FROM Layercake.silv_daily_count_detail;
EXEC tSQLt.AssertEqualsTable ''#ExpDetail'', ''#ActualDetail'', ''silv_daily_count_detail'';');
END;
GO

CREATE PROCEDURE test_MOD031.[Assert daily]
AS
BEGIN
    SELECT d.[date], d.region, d.grade, d.active_count, d.paid_count, d.paid_count_event,
           d.event_join_count, d.event_renewal_count, d.event_readmission_count, d.event_lapse_count
    INTO #ActualDaily
    FROM Layercake.silv_daily_count AS d;

    EXEC tSQLt.AssertEqualsTable '#ExpDaily', '#ActualDaily', 'silv_daily_count';
END;
GO

CREATE PROCEDURE test_MOD031.[Assert fact]
AS
BEGIN
    EXEC (N'SELECT f.date_id, f.local_group_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
       f.payment_method_id, f.payer_type_id, f.concession_type_id,
       gc.region_name, gc.market_reporting_region,
       cc.region_name AS contact_region_name, cc.market_reporting_region AS contact_market_reporting_region,
       f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents
INTO #ActualFact
FROM Layercake.fact_daily_member_count_detail AS f
LEFT JOIN Layercake.dim_country AS gc ON gc.id = f.country_id
LEFT JOIN Layercake.dim_country AS cc ON cc.id = f.contact_country_id;
EXEC tSQLt.AssertEqualsTable ''#ExpFact'', ''#ActualFact'', ''fact_daily_member_count_detail through dim_country'';');
END;
GO

CREATE PROCEDURE test_MOD031.[Assert run adjustments]
    @run_id uniqueidentifier
AS
BEGIN
    EXEC sp_executesql N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
       local_group_id, contact_country_id, contact_region, active_count_change, paid_count_change, paid_count_event_change,
       event_join_count_change, event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
INTO #ActualAdj
FROM Layercake.silv_daily_count_adjustment
WHERE run_id = @run_id;
EXEC tSQLt.AssertEqualsTable ''#ExpAdj'', ''#ActualAdj'', ''adjustment rows of the run'';',
        N'@run_id uniqueidentifier',
        @run_id = @run_id;
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-001 member and daily count tables gain local_group_id contact_country_id and contact_region]
AS
BEGIN
    SELECT v.table_name, v.column_name, v.type_name, v.max_length, v.is_nullable
    INTO #Expected
    FROM (VALUES ('silv_member_base', 'local_group_id', 'int', 4, 0),
                 ('silv_member_base', 'contact_country_id', 'int', 4, 0),
                 ('silv_member_profile', 'local_group_id', 'int', 4, 0),
                 ('silv_member_profile', 'contact_country_id', 'int', 4, 0),
                 ('etl_daily_count_applied_contact', 'local_group_id', 'int', 4, 1),
                 ('etl_daily_count_applied_contact', 'contact_country_id', 'int', 4, 1),
                 ('silv_member_state_ranges', 'contact_region', 'varchar', 12, 0),
                 ('etl_daily_count_applied_state_range', 'contact_region', 'varchar', 12, 0),
                 ('silv_daily_count_detail', 'local_group_id', 'int', 4, 0),
                 ('silv_daily_count_detail', 'contact_country_id', 'int', 4, 0),
                 ('silv_daily_count_detail', 'contact_region', 'varchar', 12, 0),
                 ('etl_daily_count_cell_contacts', 'local_group_id', 'int', 4, 0),
                 ('etl_daily_count_cell_contacts', 'contact_country_id', 'int', 4, 0),
                 ('etl_daily_count_cell_contacts', 'contact_region', 'varchar', 12, 0),
                 ('silv_daily_count_adjustment', 'local_group_id', 'int', 4, 0),
                 ('silv_daily_count_adjustment', 'contact_country_id', 'int', 4, 0),
                 ('silv_daily_count_adjustment', 'contact_region', 'varchar', 12, 0),
                 ('fact_daily_member_count_detail', 'local_group_id', 'int', 4, 0),
                 ('fact_daily_member_count_detail', 'contact_country_id', 'int', 4, 0)
         ) AS v (table_name, column_name, type_name, max_length, is_nullable);

    SELECT CAST(PARSENAME(r.OriginalName, 1) AS varchar(128)) AS table_name,
           CAST(c.name AS varchar(128)) AS column_name,
           CAST(TYPE_NAME(c.user_type_id) AS varchar(128)) AS type_name,
           CAST(c.max_length AS int) AS max_length,
           CAST(c.is_nullable AS int) AS is_nullable
    INTO #Actual
    FROM tSQLt.Private_RenamedObjectLog AS r
    JOIN sys.columns AS c
        ON c.object_id = r.ObjectId
    WHERE OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake'
      AND PARSENAME(r.OriginalName, 1) IN ('silv_member_base', 'silv_member_profile', 'etl_daily_count_applied_contact',
                                           'silv_member_state_ranges', 'etl_daily_count_applied_state_range',
                                           'silv_daily_count_detail', 'etl_daily_count_cell_contacts',
                                           'silv_daily_count_adjustment', 'fact_daily_member_count_detail', 'silv_daily_count')
      AND c.name IN ('local_group_id', 'contact_country_id', 'contact_region');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'new columns, types and nullability';

    SELECT v.table_name, v.column_count
    INTO #ExpectedCounts
    FROM (VALUES ('silv_member_base', 23),
                 ('silv_member_profile', 6),
                 ('etl_daily_count_applied_contact', 9),
                 ('silv_member_state_ranges', 9),
                 ('etl_daily_count_applied_state_range', 7),
                 ('silv_daily_count_detail', 21),
                 ('etl_daily_count_cell_contacts', 15),
                 ('silv_daily_count_adjustment', 23),
                 ('fact_daily_member_count_detail', 18),
                 ('silv_daily_count', 12)
         ) AS v (table_name, column_count);

    SELECT CAST(PARSENAME(r.OriginalName, 1) AS varchar(128)) AS table_name, COUNT(*) AS column_count
    INTO #ActualCounts
    FROM tSQLt.Private_RenamedObjectLog AS r
    JOIN sys.columns AS c
        ON c.object_id = r.ObjectId
    WHERE OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake'
      AND PARSENAME(r.OriginalName, 1) IN ('silv_member_base', 'silv_member_profile', 'etl_daily_count_applied_contact',
                                           'silv_member_state_ranges', 'etl_daily_count_applied_state_range',
                                           'silv_daily_count_detail', 'etl_daily_count_cell_contacts',
                                           'silv_daily_count_adjustment', 'fact_daily_member_count_detail', 'silv_daily_count')
    GROUP BY PARSENAME(r.OriginalName, 1);

    EXEC tSQLt.AssertEqualsTable '#ExpectedCounts', '#ActualCounts', 'column counts';
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-002 fact clustered key has the ten grain columns and the review objects gain three columns]
AS
BEGIN
    SELECT v.column_name
    INTO #ExpectedKey
    FROM (VALUES ('date_id'), ('country_id'), ('gender_id'), ('membership_grade_id'), ('membership_status_id'),
                 ('payment_method_id'), ('payer_type_id'), ('concession_type_id'), ('local_group_id'), ('contact_country_id')
         ) AS v (column_name);

    SELECT CAST(c.name AS varchar(128)) AS column_name
    INTO #ActualKey
    FROM tSQLt.Private_RenamedObjectLog AS r
    JOIN sys.indexes AS i
        ON i.object_id = r.ObjectId
       AND i.type = 1
       AND i.is_unique = 1
    JOIN sys.index_columns AS ic
        ON ic.object_id = i.object_id
       AND ic.index_id = i.index_id
       AND ic.key_ordinal > 0
    JOIN sys.columns AS c
        ON c.object_id = ic.object_id
       AND c.column_id = ic.column_id
    WHERE OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake'
      AND PARSENAME(r.OriginalName, 1) = 'fact_daily_member_count_detail';

    EXEC tSQLt.AssertEqualsTable '#ExpectedKey', '#ActualKey', 'unique clustered index key of the gold daily fact';

    SELECT v.object_name, v.column_name, v.type_name, v.max_length
    INTO #ExpectedObj
    FROM (VALUES ('fn_silv_daily_count_detail_as_known_at', 'local_group_id', 'int', 4),
                 ('fn_silv_daily_count_detail_as_known_at', 'contact_country_id', 'int', 4),
                 ('fn_silv_daily_count_detail_as_known_at', 'contact_region', 'varchar', 12),
                 ('vw_silv_daily_count_adjustment_review', 'local_group_id', 'int', 4),
                 ('vw_silv_daily_count_adjustment_review', 'contact_country_id', 'int', 4),
                 ('vw_silv_daily_count_adjustment_review', 'contact_region', 'varchar', 12)
         ) AS v (object_name, column_name, type_name, max_length);

    SELECT CAST(OBJECT_NAME(c.object_id) AS varchar(128)) AS object_name,
           CAST(c.name AS varchar(128)) AS column_name,
           CAST(TYPE_NAME(c.user_type_id) AS varchar(128)) AS type_name,
           CAST(c.max_length AS int) AS max_length
    INTO #ActualObj
    FROM sys.columns AS c
    WHERE c.object_id IN (OBJECT_ID('Layercake.fn_silv_daily_count_detail_as_known_at'),
                          OBJECT_ID('Layercake.vw_silv_daily_count_adjustment_review'))
      AND c.name IN ('local_group_id', 'contact_country_id', 'contact_region');

    EXEC tSQLt.AssertEqualsTable '#ExpectedObj', '#ActualObj', 'new columns of the detail function and the review view';

    DECLARE @fn_detail_columns int = (SELECT COUNT(*) FROM sys.columns AS c WHERE c.object_id = OBJECT_ID('Layercake.fn_silv_daily_count_detail_as_known_at'));
    DECLARE @view_columns int = (SELECT COUNT(*) FROM sys.columns AS c WHERE c.object_id = OBJECT_ID('Layercake.vw_silv_daily_count_adjustment_review'));
    DECLARE @fn_daily_columns int = (SELECT COUNT(*) FROM sys.columns AS c WHERE c.object_id = OBJECT_ID('Layercake.fn_silv_daily_count_as_known_at'));

    EXEC tSQLt.AssertEquals 19, @fn_detail_columns, 'fn_silv_daily_count_detail_as_known_at column count';
    EXEC tSQLt.AssertEquals 17, @view_columns, 'vw_silv_daily_count_adjustment_review column count';
    EXEC tSQLt.AssertEquals 10, @fn_daily_columns, 'fn_silv_daily_count_as_known_at column count';
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-003 G1 in Gulf and G2 in Gulf India take the group country and region and keep their own country]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @gold_status varchar(10);

    EXEC test_MOD031.[Add date] '2025-01-10', 1, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031.[Add member] N'G2', 3, 'A0000000-0000-0000-0000-000000000003', 1;

    EXEC test_MOD031.[Run chain] @run_id = @r1;

    SELECT v.contact_no, v.country_id, v.local_group_id, v.contact_country_id
    INTO #ExpMembers
    FROM (VALUES (N'G1', 2, 1, 1), (N'G2', 3, 3, 3)) AS v (contact_no, country_id, local_group_id, contact_country_id);
    EXEC test_MOD031.[Assert members];

    SELECT v.contact_no, CAST(v.valid_from AS date) AS valid_from, CAST(NULL AS date) AS valid_to, v.grade, v.region, v.contact_region
    INTO #ExpRanges
    FROM (VALUES (N'G1', '2015-01-01', 'election', 'MEA', 'UK&I'),
                 (N'G2', '2015-01-01', 'election', 'MEA', 'APAC')) AS v (contact_no, valid_from, grade, region, contact_region);
    EXEC test_MOD031.[Assert ranges];

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2025-01-10', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 3, 1, 'election', 1, 0, 0, 0, 3, 3, 'APAC', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];

    SELECT CAST(v.d AS date) AS [date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDaily
    FROM (VALUES ('2025-01-10', 'MEA', 'election', 2, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert daily];

    SELECT v.date_id, v.local_group_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpFact
    FROM (VALUES (1, 1, 1, 2, 1, 0, 0, 0, N'MEA', 'MEA', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 (1, 3, 1, 2, 1, 0, 0, 0, N'MEA', 'MEA', N'APAC', 'APAC', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (date_id, local_group_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
                 concession_type_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region,
                 ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);
    EXEC test_MOD031.[Assert fact];

    SELECT @gold_status = l.status FROM Layercake.etl_run_log AS l WHERE l.run_id = @r1 AND l.layer = 'gold';
    EXEC tSQLt.AssertEquals 'Success', @gold_status;
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-004 N1 with no local group and N2 with a group CE does not hold keep India and APAC]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @gold_status varchar(10);

    EXEC test_MOD031.[Add date] '2025-01-10', 1, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'N1', 3, NULL, 1;
    EXEC test_MOD031.[Add member] N'N2', 3, 'A0000000-0000-0000-0000-000000000099', 1;

    EXEC test_MOD031.[Run chain] @run_id = @r1;

    SELECT v.contact_no, v.country_id, v.local_group_id, v.contact_country_id
    INTO #ExpMembers
    FROM (VALUES (N'N1', 3, 0, 3), (N'N2', 3, 0, 3)) AS v (contact_no, country_id, local_group_id, contact_country_id);
    EXEC test_MOD031.[Assert members];

    SELECT v.contact_no, CAST(v.valid_from AS date) AS valid_from, CAST(NULL AS date) AS valid_to, v.grade, v.region, v.contact_region
    INTO #ExpRanges
    FROM (VALUES (N'N1', '2015-01-01', 'election', 'APAC', 'APAC'),
                 (N'N2', '2015-01-01', 'election', 'APAC', 'APAC')) AS v (contact_no, valid_from, grade, region, contact_region);
    EXEC test_MOD031.[Assert ranges];

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2025-01-10', 'APAC', 3, 1, 'election', 1, 0, 0, 0, 0, 3, 'APAC', 2, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];

    SELECT CAST(v.d AS date) AS [date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDaily
    FROM (VALUES ('2025-01-10', 'APAC', 'election', 2, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert daily];

    SELECT v.date_id, v.local_group_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpFact
    FROM (VALUES (1, 0, 1, 2, 1, 0, 0, 0, N'APAC', 'APAC', N'APAC', 'APAC', 2, 0, 0, 0, 0, 0, 0)
         ) AS v (date_id, local_group_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
                 concession_type_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region,
                 ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);
    EXEC test_MOD031.[Assert fact];

    SELECT @gold_status = l.status FROM Layercake.etl_run_log AS l WHERE l.run_id = @r1 AND l.layer = 'gold';
    EXEC tSQLt.AssertEquals 'Success', @gold_status;
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-005 N3 to N6 in unusable groups keep the United Kingdom and UK&I in every field]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @gold_status varchar(10);

    EXEC test_MOD031.[Add date] '2025-01-10', 1, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'N3', 1, 'A0000000-0000-0000-0000-000000000004', 1;
    EXEC test_MOD031.[Add member] N'N4', 1, 'A0000000-0000-0000-0000-000000000005', 1;
    EXEC test_MOD031.[Add member] N'N5', 1, 'A0000000-0000-0000-0000-000000000006', 1;
    EXEC test_MOD031.[Add member] N'N6', 1, 'A0000000-0000-0000-0000-000000000007', 1;

    EXEC test_MOD031.[Run chain] @run_id = @r1;

    SELECT v.contact_no, v.country_id, v.local_group_id, v.contact_country_id
    INTO #ExpMembers
    FROM (VALUES (N'N3', 1, 0, 1), (N'N4', 1, 0, 1), (N'N5', 1, 0, 1), (N'N6', 1, 0, 1)) AS v (contact_no, country_id, local_group_id, contact_country_id);
    EXEC test_MOD031.[Assert members];

    SELECT v.contact_no, CAST(v.valid_from AS date) AS valid_from, CAST(NULL AS date) AS valid_to, v.grade, v.region, v.contact_region
    INTO #ExpRanges
    FROM (VALUES (N'N3', '2015-01-01', 'election', 'UK&I', 'UK&I'),
                 (N'N4', '2015-01-01', 'election', 'UK&I', 'UK&I'),
                 (N'N5', '2015-01-01', 'election', 'UK&I', 'UK&I'),
                 (N'N6', '2015-01-01', 'election', 'UK&I', 'UK&I')) AS v (contact_no, valid_from, grade, region, contact_region);
    EXEC test_MOD031.[Assert ranges];

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2025-01-10', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK&I', 4, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];

    SELECT CAST(v.d AS date) AS [date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDaily
    FROM (VALUES ('2025-01-10', 'UK&I', 'election', 4, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert daily];

    SELECT v.date_id, v.local_group_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpFact
    FROM (VALUES (1, 0, 1, 2, 1, 0, 0, 0, N'UK&I', 'UK&I', N'UK&I', 'UK&I', 4, 0, 0, 0, 0, 0, 0)
         ) AS v (date_id, local_group_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
                 concession_type_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region,
                 ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);
    EXEC test_MOD031.[Assert fact];

    SELECT @gold_status = l.status FROM Layercake.etl_run_log AS l WHERE l.run_id = @r1 AND l.layer = 'gold';
    EXEC tSQLt.AssertEquals 'Success', @gold_status;
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-006 Gulf made inactive moves G1 wholly back to its own country on the normal path]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @contacts int, @full int;

    EXEC test_MOD031.[Add date] '2020-10-01', 1, 2021, 'Q1';
    EXEC test_MOD031.[Add date] '2025-01-10', 2, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1;

    UPDATE Layercake.silv_ref_local_group
    SET statecode = 1, is_reportable = 0, dim_country_id = NULL
    WHERE id = 1;

    EXEC test_MOD031.[Run chain] @run_id = @r2;

    EXEC test_MOD031.[Get path] @r2, @contacts OUTPUT, @full OUTPUT;
    EXEC tSQLt.AssertEquals 1, @contacts, 'contacts_recomputed';
    EXEC tSQLt.AssertEquals 0, @full, 'full_recompute_path';

    SELECT v.contact_no, v.country_id, v.local_group_id, v.contact_country_id
    INTO #ExpMembers
    FROM (VALUES (N'G1', 1, 0, 1)) AS v (contact_no, country_id, local_group_id, contact_country_id);
    EXEC test_MOD031.[Assert members];

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2020-10-01', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];

    SELECT CAST(v.d AS date) AS [date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDaily
    FROM (VALUES ('2020-10-01', 'UK&I', 'election', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK&I', 'election', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert daily];

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count_change, v.paid_count_change,
           v.paid_count_event_change, v.event_join_count_change, v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpAdj
    FROM (VALUES ('2020-10-01', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', -1, 0, 0, 0, 0, 0, 0),
                 ('2020-10-01', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count_change, paid_count_change, paid_count_event_change,
                 event_join_count_change, event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);
    EXEC test_MOD031.[Assert run adjustments] @r2;

    SELECT v.date_id, v.local_group_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpFact
    FROM (VALUES (1, 0, 1, 2, 1, 0, 0, 0, N'UK&I', 'UK&I', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 (2, 0, 1, 2, 1, 0, 0, 0, N'UK&I', 'UK&I', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (date_id, local_group_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
                 concession_type_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region,
                 ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);
    EXEC test_MOD031.[Assert fact];
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-007 a full rebuild keeps G1 under Gulf MEA on every loaded date including 2020-10-01]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @contacts int, @full int, @adj_rows int;

    EXEC test_MOD031.[Add date] '2020-10-01', 1, 2021, 'Q1';
    EXEC test_MOD031.[Add date] '2021-01-15', 2, 2021, 'Q2';
    EXEC test_MOD031.[Add date] '2025-01-10', 3, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @FullRebuild = 1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;

    EXEC test_MOD031.[Get path] @r2, @contacts OUTPUT, @full OUTPUT;
    EXEC tSQLt.AssertEquals 1, @full, 'full_recompute_path';
    SELECT @adj_rows = COUNT(*) FROM Layercake.silv_daily_count_adjustment AS a WHERE a.run_id = @r2;
    EXEC tSQLt.AssertEquals 0, @adj_rows, 'adjustment rows written by the full rebuild';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2020-10-01', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2021-01-15', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];

    SELECT CAST(v.d AS date) AS [date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDaily
    FROM (VALUES ('2020-10-01', 'MEA', 'election', 1, 0, 0, 0, 0, 0, 0),
                 ('2021-01-15', 'MEA', 'election', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 'election', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert daily];

    SELECT v.date_id, v.local_group_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpFact
    FROM (VALUES (1, 1, 1, 2, 1, 0, 0, 0, N'MEA', 'MEA', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 (2, 1, 1, 2, 1, 0, 0, 0, N'MEA', 'MEA', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 (3, 1, 1, 2, 1, 0, 0, 0, N'MEA', 'MEA', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (date_id, local_group_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
                 concession_type_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region,
                 ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);
    EXEC test_MOD031.[Assert fact];
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-008 a rebuild from 2021-01-01 moves G1 into Gulf on every loaded date including 2020-10-01]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @contacts int, @full int;

    EXEC test_MOD031.[Add date] '2020-10-01', 1, 2021, 'Q1';
    EXEC test_MOD031.[Add date] '2021-01-15', 2, 2021, 'Q2';
    EXEC test_MOD031.[Add date] '2025-01-10', 3, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, NULL, 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1;

    UPDATE Layercake.brnz_contact
    SET rics_localgroupid = 'A0000000-0000-0000-0000-000000000001'
    WHERE Rics_contactno = N'G1';

    EXEC test_MOD031.[Run members] @run_id = @r2;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @RebuildFrom = '2021-01-01';
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;

    EXEC test_MOD031.[Get path] @r2, @contacts OUTPUT, @full OUTPUT;
    EXEC tSQLt.AssertEquals 1, @full, 'full_recompute_path';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2020-10-01', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2021-01-15', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];

    SELECT CAST(v.d AS date) AS [date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDaily
    FROM (VALUES ('2020-10-01', 'MEA', 'election', 1, 0, 0, 0, 0, 0, 0),
                 ('2021-01-15', 'MEA', 'election', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 'election', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert daily];

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count_change, v.paid_count_change,
           v.paid_count_event_change, v.event_join_count_change, v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpAdj
    FROM (VALUES ('2020-10-01', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK&I', -1, 0, 0, 0, 0, 0, 0),
                 ('2020-10-01', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2021-01-15', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK&I', -1, 0, 0, 0, 0, 0, 0),
                 ('2021-01-15', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK&I', -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count_change, paid_count_change, paid_count_event_change,
                 event_join_count_change, event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);
    EXEC test_MOD031.[Assert run adjustments] @r2;

    SELECT v.date_id, v.local_group_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpFact
    FROM (VALUES (1, 1, 1, 2, 1, 0, 0, 0, N'MEA', 'MEA', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 (2, 1, 1, 2, 1, 0, 0, 0, N'MEA', 'MEA', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 (3, 1, 1, 2, 1, 0, 0, 0, N'MEA', 'MEA', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (date_id, local_group_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
                 concession_type_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region,
                 ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);
    EXEC test_MOD031.[Assert fact];
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-009 Gulf regions changed to GCC move G1 to GCC on the normal path and match a full rebuild]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(),
            @contacts int, @full int, @adj_rows int;

    EXEC test_MOD031.[Add date] '2020-10-01', 1, 2021, 'Q1';
    EXEC test_MOD031.[Add date] '2025-01-10', 2, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1;

    UPDATE Layercake.silv_ref_local_group
    SET region_name = N'GCC', market_reporting_region = 'GCC', dim_country_id = 1000002
    WHERE id = 1;
    INSERT INTO Layercake.dim_country (id, country_id, country_name, region_name, market_reporting_region)
    VALUES (1000002, 'C0000000-0000-0000-0000-000000000002', N'United Arab Emirates', N'GCC', 'GCC');

    EXEC test_MOD031.[Run chain] @run_id = @r2;

    EXEC test_MOD031.[Get path] @r2, @contacts OUTPUT, @full OUTPUT;
    EXEC tSQLt.AssertEquals 1, @contacts, 'contacts_recomputed';
    EXEC tSQLt.AssertEquals 0, @full, 'full_recompute_path';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2020-10-01', 'GCC', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'GCC', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];

    SELECT CAST(v.d AS date) AS [date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDaily
    FROM (VALUES ('2020-10-01', 'GCC', 'election', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'GCC', 'election', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert daily];

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count_change, v.paid_count_change,
           v.paid_count_event_change, v.event_join_count_change, v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpAdj
    FROM (VALUES ('2020-10-01', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', -1, 0, 0, 0, 0, 0, 0),
                 ('2020-10-01', 'GCC', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'GCC', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count_change, paid_count_change, paid_count_event_change,
                 event_join_count_change, event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);
    EXEC test_MOD031.[Assert run adjustments] @r2;

    SELECT v.date_id, v.local_group_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpFact
    FROM (VALUES (1, 1, 1, 2, 1, 0, 0, 0, N'GCC', 'GCC', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 (2, 1, 1, 2, 1, 0, 0, 0, N'GCC', 'GCC', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (date_id, local_group_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
                 concession_type_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region,
                 ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);
    EXEC test_MOD031.[Assert fact];

    SELECT * INTO #detail_r2 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r2 FROM Layercake.silv_daily_count;
    SELECT * INTO #fact_r2 FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r3;

    SELECT @adj_rows = COUNT(*) FROM Layercake.silv_daily_count_adjustment AS a WHERE a.run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @adj_rows, 'adjustment rows written by the full rebuild';

    SELECT * INTO #detail_r3 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r3 FROM Layercake.silv_daily_count;
    SELECT * INTO #fact_r3 FROM Layercake.fact_daily_member_count_detail;
    EXEC tSQLt.AssertEqualsTable '#detail_r2', '#detail_r3', 'detail after the normal run vs the full rebuild';
    EXEC tSQLt.AssertEqualsTable '#daily_r2', '#daily_r3', 'silv_daily_count after the normal run vs the full rebuild';
    EXEC tSQLt.AssertEqualsTable '#fact_r2', '#fact_r3', 'fact after the normal run vs the full rebuild';
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-010 G1 moving from Gulf to London alone is recomputed on the normal path and matches a full rebuild]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(),
            @contacts int, @full int, @adj_rows int;

    EXEC test_MOD031.[Add date] '2020-10-01', 1, 2021, 'Q1';
    EXEC test_MOD031.[Add date] '2025-01-10', 2, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1;

    UPDATE Layercake.brnz_contact
    SET rics_localgroupid = 'A0000000-0000-0000-0000-000000000002'
    WHERE Rics_contactno = N'G1';

    EXEC test_MOD031.[Run chain] @run_id = @r2;

    EXEC test_MOD031.[Get path] @r2, @contacts OUTPUT, @full OUTPUT;
    EXEC tSQLt.AssertEquals 1, @contacts, 'contacts_recomputed';
    EXEC tSQLt.AssertEquals 0, @full, 'full_recompute_path';

    SELECT v.contact_no, v.country_id, v.local_group_id, v.contact_country_id
    INTO #ExpMembers
    FROM (VALUES (N'G1', 1, 2, 1)) AS v (contact_no, country_id, local_group_id, contact_country_id);
    EXEC test_MOD031.[Assert members];

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2020-10-01', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 2, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 2, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count_change, v.paid_count_change,
           v.paid_count_event_change, v.event_join_count_change, v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpAdj
    FROM (VALUES ('2020-10-01', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', -1, 0, 0, 0, 0, 0, 0),
                 ('2020-10-01', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 2, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 2, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count_change, paid_count_change, paid_count_event_change,
                 event_join_count_change, event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);
    EXEC test_MOD031.[Assert run adjustments] @r2;

    SELECT * INTO #detail_r2 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r2 FROM Layercake.silv_daily_count;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;

    SELECT @adj_rows = COUNT(*) FROM Layercake.silv_daily_count_adjustment AS a WHERE a.run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @adj_rows, 'adjustment rows written by the full rebuild';

    SELECT * INTO #detail_r3 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r3 FROM Layercake.silv_daily_count;
    EXEC tSQLt.AssertEqualsTable '#detail_r2', '#detail_r3', 'detail after the normal run vs the full rebuild';
    EXEC tSQLt.AssertEqualsTable '#daily_r2', '#daily_r3', 'silv_daily_count after the normal run vs the full rebuild';
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-011 L1 leaving London changes only local_group_id and moves its cells to local group 0]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @contacts int, @full int;

    EXEC test_MOD031.[Add date] '2020-10-01', 1, 2021, 'Q1';
    EXEC test_MOD031.[Add date] '2025-01-10', 2, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'L1', 1, 'A0000000-0000-0000-0000-000000000002', 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1;

    UPDATE Layercake.brnz_contact
    SET rics_localgroupid = NULL
    WHERE Rics_contactno = N'L1';

    EXEC test_MOD031.[Run chain] @run_id = @r2;

    EXEC test_MOD031.[Get path] @r2, @contacts OUTPUT, @full OUTPUT;
    EXEC tSQLt.AssertEquals 1, @contacts, 'contacts_recomputed';
    EXEC tSQLt.AssertEquals 0, @full, 'full_recompute_path';

    SELECT v.contact_no, v.country_id, v.local_group_id, v.contact_country_id
    INTO #ExpMembers
    FROM (VALUES (N'L1', 1, 0, 1)) AS v (contact_no, country_id, local_group_id, contact_country_id);
    EXEC test_MOD031.[Assert members];

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2020-10-01', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count_change, v.paid_count_change,
           v.paid_count_event_change, v.event_join_count_change, v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpAdj
    FROM (VALUES ('2020-10-01', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 2, 1, 'UK&I', -1, 0, 0, 0, 0, 0, 0),
                 ('2020-10-01', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 2, 1, 'UK&I', -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count_change, paid_count_change, paid_count_event_change,
                 event_join_count_change, event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);
    EXEC test_MOD031.[Assert run adjustments] @r2;

    SELECT CAST(v.d AS date) AS [date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDaily
    FROM (VALUES ('2020-10-01', 'UK&I', 'election', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK&I', 'election', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert daily];
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-012 a change of own country alone moves contact_country_id and contact_region but not region]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @contacts int, @full int;

    EXEC test_MOD031.[Add date] '2020-10-01', 1, 2021, 'Q1';
    EXEC test_MOD031.[Add date] '2025-01-10', 2, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1;

    UPDATE Layercake.brnz_contact
    SET rics_countryid = 'C0000000-0000-0000-0000-000000000003'
    WHERE Rics_contactno = N'G1';

    EXEC test_MOD031.[Run chain] @run_id = @r2;

    EXEC test_MOD031.[Get path] @r2, @contacts OUTPUT, @full OUTPUT;
    EXEC tSQLt.AssertEquals 1, @contacts, 'contacts_recomputed';
    EXEC tSQLt.AssertEquals 0, @full, 'full_recompute_path';

    SELECT v.contact_no, v.country_id, v.local_group_id, v.contact_country_id
    INTO #ExpMembers
    FROM (VALUES (N'G1', 2, 1, 3)) AS v (contact_no, country_id, local_group_id, contact_country_id);
    EXEC test_MOD031.[Assert members];

    SELECT v.contact_no, CAST(v.valid_from AS date) AS valid_from, CAST(NULL AS date) AS valid_to, v.grade, v.region, v.contact_region
    INTO #ExpRanges
    FROM (VALUES (N'G1', '2015-01-01', 'election', 'MEA', 'APAC')) AS v (contact_no, valid_from, grade, region, contact_region);
    EXEC test_MOD031.[Assert ranges];

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2020-10-01', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 3, 'APAC', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 3, 'APAC', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count_change, v.paid_count_change,
           v.paid_count_event_change, v.event_join_count_change, v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpAdj
    FROM (VALUES ('2020-10-01', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', -1, 0, 0, 0, 0, 0, 0),
                 ('2020-10-01', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 3, 'APAC', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 3, 'APAC', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count_change, paid_count_change, paid_count_event_change,
                 event_join_count_change, event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);
    EXEC test_MOD031.[Assert run adjustments] @r2;

    SELECT CAST(v.d AS date) AS [date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDaily
    FROM (VALUES ('2020-10-01', 'MEA', 'election', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 'election', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert daily];

    SELECT v.date_id, v.local_group_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpFact
    FROM (VALUES (1, 1, 1, 2, 1, 0, 0, 0, N'MEA', 'MEA', N'APAC', 'APAC', 1, 0, 0, 0, 0, 0, 0),
                 (2, 1, 1, 2, 1, 0, 0, 0, N'MEA', 'MEA', N'APAC', 'APAC', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (date_id, local_group_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
                 concession_type_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region,
                 ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);
    EXEC test_MOD031.[Assert fact];
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-013 a rerun on unchanged data recomputes no contact and changes nothing]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @contacts int, @full int, @adj_rows int,
            @ins int, @upd int, @del int;

    EXEC test_MOD031.[Add date] '2025-01-10', 1, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031.[Add member] N'G2', 3, 'A0000000-0000-0000-0000-000000000003', 1;
    EXEC test_MOD031.[Add member] N'N1', 3, NULL, 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1;

    SELECT * INTO #profile_before FROM Layercake.silv_member_profile;
    SELECT * INTO #ranges_before FROM Layercake.silv_member_state_ranges;
    SELECT * INTO #detail_before FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_before FROM Layercake.silv_daily_count;
    SELECT * INTO #cells_before FROM Layercake.etl_daily_count_cell_contacts;
    SELECT * INTO #fact_before FROM Layercake.fact_daily_member_count_detail;

    EXEC test_MOD031.[Run chain] @run_id = @r2;

    EXEC test_MOD031.[Get path] @r2, @contacts OUTPUT, @full OUTPUT;
    EXEC tSQLt.AssertEquals 0, @contacts, 'contacts_recomputed';
    EXEC tSQLt.AssertEquals 0, @full, 'full_recompute_path';

    SELECT @adj_rows = COUNT(*) FROM Layercake.silv_daily_count_adjustment AS a WHERE a.run_id = @r2;
    EXEC tSQLt.AssertEquals 0, @adj_rows, 'adjustment rows written by the rerun';

    SELECT @ins = l.rows_inserted, @upd = l.rows_updated, @del = l.rows_deleted
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @r2 AND l.layer = 'gold';
    EXEC tSQLt.AssertEquals 0, @ins, 'gold rows_inserted';
    EXEC tSQLt.AssertEquals 0, @upd, 'gold rows_updated';
    EXEC tSQLt.AssertEquals 0, @del, 'gold rows_deleted';

    SELECT * INTO #profile_after FROM Layercake.silv_member_profile;
    SELECT * INTO #ranges_after FROM Layercake.silv_member_state_ranges;
    SELECT * INTO #detail_after FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_after FROM Layercake.silv_daily_count;
    SELECT * INTO #cells_after FROM Layercake.etl_daily_count_cell_contacts;
    SELECT * INTO #fact_after FROM Layercake.fact_daily_member_count_detail;

    EXEC tSQLt.AssertEqualsTable '#profile_before', '#profile_after', 'silv_member_profile';
    EXEC tSQLt.AssertEqualsTable '#ranges_before', '#ranges_after', 'silv_member_state_ranges';
    EXEC tSQLt.AssertEqualsTable '#detail_before', '#detail_after', 'silv_daily_count_detail';
    EXEC tSQLt.AssertEqualsTable '#daily_before', '#daily_after', 'silv_daily_count';
    EXEC tSQLt.AssertEqualsTable '#cells_before', '#cells_after', 'etl_daily_count_cell_contacts';
    EXEC tSQLt.AssertEqualsTable '#fact_before', '#fact_after', 'fact_daily_member_count_detail';
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-014 gold syncs on the ten-column key keeping ids and deleting a hand row that differs only in local group]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @status varchar(10), @ins int, @upd int, @del int;

    EXEC test_MOD031.[Add date] '2025-01-10', 1, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031.[Add member] N'L1', 1, 'A0000000-0000-0000-0000-000000000002', 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1;

    SELECT * INTO #fact_before FROM Layercake.fact_daily_member_count_detail;

    UPDATE Layercake.brnz_contact
    SET rics_localgroupid = 'A0000000-0000-0000-0000-000000000002'
    WHERE Rics_contactno = N'G1';

    EXEC test_MOD031.[Run members] @run_id = @r2;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    EXEC (N'INSERT INTO Layercake.fact_daily_member_count_detail
    (date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
     local_group_id, contact_country_id, ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
VALUES (1, 1, 1, 2, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0);');

    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;

    SELECT @status = l.status, @ins = l.rows_inserted, @upd = l.rows_updated, @del = l.rows_deleted
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @r2 AND l.layer = 'gold';
    EXEC tSQLt.AssertEquals 'Success', @status, 'gold status';
    EXEC tSQLt.AssertEquals 0, @ins, 'gold rows_inserted';
    EXEC tSQLt.AssertEquals 1, @upd, 'gold rows_updated';
    EXEC tSQLt.AssertEquals 2, @del, 'gold rows_deleted';

    EXEC (N'SELECT b.id, 1 AS date_id, 1 AS country_id, 1 AS gender_id, 2 AS membership_grade_id, 1 AS membership_status_id,
       0 AS payment_method_id, 0 AS payer_type_id, 0 AS concession_type_id, 2 AS local_group_id, 1 AS contact_country_id,
       2 AS ActiveMembers, 0 AS PaidMembers, 0 AS PaidMembersEvent, 0 AS JoinEvents, 0 AS RenewalEvents, 0 AS ReadmissionEvents, 0 AS LapseEvents
INTO #ExpectedFactIds
FROM #fact_before AS b
WHERE b.local_group_id = 2;
SELECT f.id, f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
       f.payment_method_id, f.payer_type_id, f.concession_type_id, f.local_group_id, f.contact_country_id,
       f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents
INTO #ActualFactIds
FROM Layercake.fact_daily_member_count_detail AS f;
EXEC tSQLt.AssertEqualsTable ''#ExpectedFactIds'', ''#ActualFactIds'', ''fact after the gold sync'';');
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-015 the first run after deployment restates to local group values writing no adjustment rows]
AS
BEGIN
    DECLARE @r0 uniqueidentifier = NEWID(), @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(),
            @contacts int, @full int, @markers int, @not_applicable int, @adj_rows int;

    EXEC test_MOD031.[Add date] '2020-10-01', 1, 2021, 'Q1';
    EXEC test_MOD031.[Add date] '2025-01-10', 2, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031.[Add member] N'N1', 3, NULL, 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1;

    EXEC test_MOD031.[Simulate deployment] @marker_run_id = @r0;

    EXEC (N'INSERT INTO Layercake.silv_daily_count_adjustment
    (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
     payment_method_id, payer_type_id, concession_type_id,
     active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
     event_renewal_count_change, event_readmission_count_change, event_lapse_count_change,
     local_group_id, contact_country_id, contact_region)
VALUES (''E0000000-0000-0000-0000-000000000001'', 7, ''2025-01-10 07:00:00.000'', ''2025-01-10'', ''UK&I'', 1, 1, ''election'', 1, 0, 0, 0,
        1, 0, 0, 0, 0, 0, 0, -2, 1, ''UK&I''),
       (''E0000000-0000-0000-0000-000000000002'', 8, ''2025-01-10 08:00:00.000'', ''2020-10-01'', ''APAC'', 3, 1, ''election'', 1, 0, 0, 0,
        0, 1, 0, 0, 0, 0, 0, -2, 3, ''APAC'');');

    SELECT * INTO #adj_before FROM Layercake.silv_daily_count_adjustment;

    EXEC test_MOD031.[Run chain] @run_id = @r2;

    EXEC test_MOD031.[Get path] @r2, @contacts OUTPUT, @full OUTPUT;
    EXEC tSQLt.AssertEquals 1, @full, 'full_recompute_path';

    SELECT @markers = COUNT(*) FROM Layercake.etl_daily_count_input_basis AS b WHERE b.input_name = 'local_group_restatement';
    EXEC tSQLt.AssertEquals 0, @markers, 'local_group_restatement marker rows left';

    SELECT * INTO #adj_after FROM Layercake.silv_daily_count_adjustment;
    EXEC tSQLt.AssertEqualsTable '#adj_before', '#adj_after', 'adjustment history across the restating run';

    EXEC sp_executesql N'SELECT @n = COUNT(*)
FROM Layercake.silv_daily_count_adjustment AS a
JOIN Layercake.silv_ref_local_group AS g ON g.id = a.local_group_id
WHERE a.local_group_id = -2 AND g.local_group_name = N''Not applicable'';',
        N'@n int OUTPUT', @n = @not_applicable OUTPUT;
    EXEC tSQLt.AssertEquals 2, @not_applicable, 'pre-deployment rows resolving to -2 Not applicable';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2020-10-01', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2020-10-01', 'APAC', 3, 1, 'election', 1, 0, 0, 0, 0, 3, 'APAC', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'APAC', 3, 1, 'election', 1, 0, 0, 0, 0, 3, 'APAC', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];

    SELECT CAST(v.d AS date) AS [date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDaily
    FROM (VALUES ('2020-10-01', 'MEA', 'election', 1, 0, 0, 0, 0, 0, 0),
                 ('2020-10-01', 'APAC', 'election', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 'election', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'APAC', 'election', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert daily];

    EXEC (N'SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
       v.payment_method_id, v.payer_type_id, v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.contact_count
INTO #ExpectedCells
FROM (VALUES (''2020-10-01'', ''MEA'', 2, 1, ''election'', 1, 0, 0, 0, 1, 1, ''UK&I'', 1),
             (''2020-10-01'', ''APAC'', 3, 1, ''election'', 1, 0, 0, 0, 0, 3, ''APAC'', 1),
             (''2025-01-10'', ''MEA'', 2, 1, ''election'', 1, 0, 0, 0, 1, 1, ''UK&I'', 1),
             (''2025-01-10'', ''APAC'', 3, 1, ''election'', 1, 0, 0, 0, 0, 3, ''APAC'', 1)
     ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
             local_group_id, contact_country_id, contact_region, contact_count);
SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
       local_group_id, contact_country_id, contact_region, contact_count
INTO #ActualCells
FROM Layercake.etl_daily_count_cell_contacts;
EXEC tSQLt.AssertEqualsTable ''#ExpectedCells'', ''#ActualCells'', ''etl_daily_count_cell_contacts'';');

    SELECT v.date_id, v.local_group_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpFact
    FROM (VALUES (1, 1, 1, 2, 1, 0, 0, 0, N'MEA', 'MEA', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 (1, 0, 1, 2, 1, 0, 0, 0, N'APAC', 'APAC', N'APAC', 'APAC', 1, 0, 0, 0, 0, 0, 0),
                 (2, 1, 1, 2, 1, 0, 0, 0, N'MEA', 'MEA', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 (2, 0, 1, 2, 1, 0, 0, 0, N'APAC', 'APAC', N'APAC', 'APAC', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (date_id, local_group_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
                 concession_type_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region,
                 ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);
    EXEC test_MOD031.[Assert fact];

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    SELECT @adj_rows = COUNT(*) FROM Layercake.silv_daily_count_adjustment AS a WHERE a.run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @adj_rows, 'adjustment rows written by a full rebuild after the restatement';
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-016 a real change found by the restating run is recorded at the own-country grain with local group -2]
AS
BEGIN
    DECLARE @r0 uniqueidentifier = NEWID(), @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @markers int;

    EXEC test_MOD031.[Add date] '2020-10-01', 1, 2021, 'Q1';
    EXEC test_MOD031.[Add date] '2025-01-10', 2, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031.[Add member] N'N1', 3, NULL, 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1;

    EXEC test_MOD031.[Simulate deployment] @marker_run_id = @r0;
    EXEC test_MOD031.[Add renewal] N'G1', '2025-01-10', 2025, 'Q2', 1;

    EXEC test_MOD031.[Run chain] @run_id = @r2;

    SELECT @markers = COUNT(*) FROM Layercake.etl_daily_count_input_basis AS b WHERE b.input_name = 'local_group_restatement';
    EXEC tSQLt.AssertEquals 0, @markers, 'local_group_restatement marker rows left';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count_change, v.paid_count_change,
           v.paid_count_event_change, v.event_join_count_change, v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpAdj
    FROM (VALUES ('2025-01-10', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, -2, 1, 'UK&I', 0, 0, 1, 0, 1, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count_change, paid_count_change, paid_count_event_change,
                 event_join_count_change, event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);
    EXEC test_MOD031.[Assert run adjustments] @r2;

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2020-10-01', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2020-10-01', 'APAC', 3, 1, 'election', 1, 0, 0, 0, 0, 3, 'APAC', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 1, 0, 1, 0, 0),
                 ('2025-01-10', 'APAC', 3, 1, 'election', 1, 0, 0, 0, 0, 3, 'APAC', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-017 both restatement markers together are removed by one run that writes only the real change]
AS
BEGIN
    DECLARE @r0 uniqueidentifier = NEWID(), @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @markers int;

    EXEC test_MOD031.[Add date] '2020-10-01', 1, 2021, 'Q1';
    EXEC test_MOD031.[Add date] '2025-01-10', 2, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1;

    EXEC test_MOD031.[Simulate deployment] @marker_run_id = @r0, @both_markers = 1;

    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'G1', 2025, 2, 0, 1, 0, NULL, 1, 0, NULL, 1, '2026-01-01', '2026-01-01');
    EXEC test_MOD031.[Add renewal] N'G1', '2025-01-10', 2025, 'Q2', 1;

    EXEC test_MOD031.[Run chain] @run_id = @r2;

    SELECT @markers = COUNT(*)
    FROM Layercake.etl_daily_count_input_basis AS b
    WHERE b.input_name IN ('local_group_restatement', 'detail_grain_restatement');
    EXEC tSQLt.AssertEquals 0, @markers, 'restatement marker rows left';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count_change, v.paid_count_change,
           v.paid_count_event_change, v.event_join_count_change, v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpAdj
    FROM (VALUES ('2025-01-10', 'UK&I', 1, 1, 'election', 1, -2, -2, -2, -2, 1, 'UK&I', 0, 0, 1, 0, 1, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count_change, paid_count_change, paid_count_event_change,
                 event_join_count_change, event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);
    EXEC test_MOD031.[Assert run adjustments] @r2;

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2020-10-01', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 2, 1, 'election', 1, 2, 1, 1, 1, 1, 'UK&I', 1, 0, 1, 0, 1, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];

    SELECT v.date_id, v.local_group_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpFact
    FROM (VALUES (1, 1, 1, 2, 1, 0, 0, 0, N'MEA', 'MEA', N'UK&I', 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 (2, 1, 1, 2, 1, 2, 1, 1, N'MEA', 'MEA', N'UK&I', 'UK&I', 1, 0, 1, 0, 1, 0, 0)
         ) AS v (date_id, local_group_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
                 concession_type_id, region_name, market_reporting_region, contact_region_name, contact_market_reporting_region,
                 ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);
    EXEC test_MOD031.[Assert fact];
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD031.[test TC-031-018 a restating run that fails part way keeps the marker and the next run finishes with no cleanup]
AS
BEGIN
    DECLARE @r0 uniqueidentifier = NEWID(), @r1 uniqueidentifier = NEWID(), @r2m uniqueidentifier = NEWID(),
            @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(),
            @status2 varchar(10), @status3 varchar(10), @markers int;

    EXEC test_MOD031.[Add date] '2020-10-01', 1, 2021, 'Q1';
    EXEC test_MOD031.[Add date] '2025-01-10', 2, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1, @with_gold = 0;

    EXEC test_MOD031.[Simulate deployment] @marker_run_id = @r0;
    EXEC test_MOD031.[Run members] @run_id = @r2m;

    EXEC (N'INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date, local_group_id, contact_country_id)
VALUES (N''D6'', 1, 1, NULL, 0, 1);
INSERT INTO Layercake.silv_member_state_ranges (contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq, contact_region)
VALUES (N''D6'', ''2025-01-10'', NULL, 2025, ''election'', NULL, 1, ''UK&I'');');

    ALTER TABLE Layercake.silv_daily_count_detail ALTER COLUMN region varchar(12) NOT NULL;
    ALTER TABLE Layercake.etl_daily_count_cell_contacts ALTER COLUMN region varchar(12) NOT NULL;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @DailyCountBatchDays = 1;
        EXEC tSQLt.Fail 'the restating run should fail with error 515 on the contact with no region';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515
            THROW;
    END CATCH;

    SELECT @status2 = l.status FROM Layercake.etl_run_log AS l WHERE l.run_id = @r2;
    EXEC tSQLt.AssertEquals 'Failed', @status2, 'failed run status';

    SELECT @markers = COUNT(*) FROM Layercake.etl_daily_count_input_basis AS b WHERE b.input_name = 'local_group_restatement';
    EXEC tSQLt.AssertEquals 1, @markers, 'marker kept after the failed run';

    UPDATE Layercake.silv_member_state_ranges SET region = 'UK&I' WHERE contact_no = N'D6';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3;

    SELECT @status3 = l.status FROM Layercake.etl_run_log AS l WHERE l.run_id = @r3;
    EXEC tSQLt.AssertEquals 'Success', @status3, 'next run status';

    SELECT @markers = COUNT(*) FROM Layercake.etl_daily_count_input_basis AS b WHERE b.input_name = 'local_group_restatement';
    EXEC tSQLt.AssertEquals 0, @markers, 'marker removed by the completed run';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count_change, v.paid_count_change,
           v.paid_count_event_change, v.event_join_count_change, v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpAdj
    FROM (VALUES ('2025-01-10', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, -2, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count_change, paid_count_change, paid_count_event_change,
                 event_join_count_change, event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);

    EXEC sp_executesql N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
       local_group_id, contact_country_id, contact_region,
       SUM(active_count_change) AS active_count_change, SUM(paid_count_change) AS paid_count_change,
       SUM(paid_count_event_change) AS paid_count_event_change, SUM(event_join_count_change) AS event_join_count_change,
       SUM(event_renewal_count_change) AS event_renewal_count_change, SUM(event_readmission_count_change) AS event_readmission_count_change,
       SUM(event_lapse_count_change) AS event_lapse_count_change
INTO #ActualAdjSum
FROM Layercake.silv_daily_count_adjustment
WHERE run_id IN (@r2, @r3)
GROUP BY [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
         local_group_id, contact_country_id, contact_region
HAVING SUM(active_count_change) <> 0 OR SUM(paid_count_change) <> 0 OR SUM(paid_count_event_change) <> 0
    OR SUM(event_join_count_change) <> 0 OR SUM(event_renewal_count_change) <> 0
    OR SUM(event_readmission_count_change) <> 0 OR SUM(event_lapse_count_change) <> 0;
EXEC tSQLt.AssertEqualsTable ''#ExpAdj'', ''#ActualAdjSum'', ''adjustments of the failed and the next run, summed per cell'';',
        N'@r2 uniqueidentifier, @r3 uniqueidentifier', @r2 = @r2, @r3 = @r3;

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.payment_method_id, v.payer_type_id,
           v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpDetail
    FROM (VALUES ('2020-10-01', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'MEA', 2, 1, 'election', 1, 0, 0, 0, 1, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK&I', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK&I', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
    EXEC test_MOD031.[Assert detail];
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-019 the review view carries the local group and own country of each adjustment with -2 before deployment]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @review_rows int;

    EXEC test_MOD031.[Add date] '2025-01-10', 1, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;

    EXEC (N'INSERT INTO Layercake.silv_daily_count_adjustment
    (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
     payment_method_id, payer_type_id, concession_type_id,
     active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
     event_renewal_count_change, event_readmission_count_change, event_lapse_count_change,
     local_group_id, contact_country_id, contact_region)
VALUES (''E0000000-0000-0000-0000-000000000001'', 7, ''2025-01-10 07:00:00.000'', ''2025-01-10'', ''UK&I'', 1, 1, ''election'', 1, 0, 0, 0,
        0, 1, 0, 0, 0, 0, 0, -2, 1, ''UK&I'');');

    EXEC test_MOD031.[Run chain] @run_id = @r1, @with_gold = 0;

    UPDATE Layercake.brnz_contact
    SET rics_localgroupid = 'A0000000-0000-0000-0000-000000000002'
    WHERE Rics_contactno = N'G1';

    EXEC test_MOD031.[Run chain] @run_id = @r2, @with_gold = 0;

    EXEC (N'SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
       v.payment_method_id, v.payer_type_id, v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region,
       v.measure_name, v.change_value
INTO #ExpectedReview
FROM (VALUES (''2025-01-10'', ''UK&I'', 1, 1, ''election'', 1, 0, 0, 0, -2, 1, ''UK&I'', ''paid_count'', 1),
             (''2025-01-10'', ''MEA'', 2, 1, ''election'', 1, 0, 0, 0, 1, 1, ''UK&I'', ''active_count'', -1),
             (''2025-01-10'', ''UK&I'', 1, 1, ''election'', 1, 0, 0, 0, 2, 1, ''UK&I'', ''active_count'', 1)
     ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
             local_group_id, contact_country_id, contact_region, measure_name, change_value);
SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
       local_group_id, contact_country_id, contact_region, measure_name, change_value
INTO #ActualReview
FROM Layercake.vw_silv_daily_count_adjustment_review;
EXEC tSQLt.AssertEqualsTable ''#ExpectedReview'', ''#ActualReview'', ''vw_silv_daily_count_adjustment_review'';');

    SELECT @review_rows = COUNT(*) FROM Layercake.vw_silv_daily_count_adjustment_review;
    EXEC tSQLt.AssertEquals 3, @review_rows, 'review rows';
END;
GO

CREATE PROCEDURE test_MOD031.[test TC-031-020 the as-known-at functions give G1 under MEA before and GCC after the Gulf region change]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @t1 datetime2(3), @t2 datetime2(3);

    EXEC test_MOD031.[Add date] '2025-01-10', 1, 2025, 'Q2';
    EXEC test_MOD031.[Add member] N'G1', 1, 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031.[Run chain] @run_id = @r1, @with_gold = 0;

    WAITFOR DELAY '00:00:00.050';
    SET @t1 = CAST(SYSDATETIME() AS datetime2(3));
    WAITFOR DELAY '00:00:00.050';

    UPDATE Layercake.silv_ref_local_group
    SET region_name = N'GCC', market_reporting_region = 'GCC', dim_country_id = 1000002
    WHERE id = 1;

    EXEC test_MOD031.[Run chain] @run_id = @r2, @with_gold = 0;

    WAITFOR DELAY '00:00:00.050';
    SET @t2 = CAST(SYSDATETIME() AS datetime2(3));

    EXEC sp_executesql N'SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
       v.payment_method_id, v.payer_type_id, v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region,
       v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
INTO #ExpectedT1
FROM (VALUES (''2025-01-10'', ''MEA'', 2, 1, ''election'', 1, 0, 0, 0, 1, 1, ''UK&I'', 1, 0, 0, 0, 0, 0, 0)
     ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
             local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
             event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
       v.payment_method_id, v.payer_type_id, v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region,
       v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
INTO #ExpectedT2
FROM (VALUES (''2025-01-10'', ''GCC'', 2, 1, ''election'', 1, 0, 0, 0, 1, 1, ''UK&I'', 1, 0, 0, 0, 0, 0, 0)
     ) AS v (d, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
             local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
             event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);
SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
       local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
       event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
INTO #ActualT1
FROM Layercake.fn_silv_daily_count_detail_as_known_at(''2020-10-01'', ''2025-12-31'', @t1)
WHERE active_count <> 0 OR paid_count <> 0 OR paid_count_event <> 0 OR event_join_count <> 0
   OR event_renewal_count <> 0 OR event_readmission_count <> 0 OR event_lapse_count <> 0;
SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
       local_group_id, contact_country_id, contact_region, active_count, paid_count, paid_count_event,
       event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
INTO #ActualT2
FROM Layercake.fn_silv_daily_count_detail_as_known_at(''2020-10-01'', ''2025-12-31'', @t2)
WHERE active_count <> 0 OR paid_count <> 0 OR paid_count_event <> 0 OR event_join_count <> 0
   OR event_renewal_count <> 0 OR event_readmission_count <> 0 OR event_lapse_count <> 0;
EXEC tSQLt.AssertEqualsTable ''#ExpectedT1'', ''#ActualT1'', ''detail as known at T1'';
EXEC tSQLt.AssertEqualsTable ''#ExpectedT2'', ''#ActualT2'', ''detail as known at T2'';',
        N'@t1 datetime2(3), @t2 datetime2(3)', @t1 = @t1, @t2 = @t2;

    SELECT CAST(v.d AS date) AS [date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpectedDailyT1
    FROM (VALUES ('2025-01-10', 'MEA', 'election', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT CAST(v.d AS date) AS [date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event,
           v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpectedDailyT2
    FROM (VALUES ('2025-01-10', 'GCC', 'election', 1, 0, 0, 0, 0, 0, 0)
         ) AS v (d, region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT f.[date], f.region, f.grade, f.active_count, f.paid_count, f.paid_count_event,
           f.event_join_count, f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #ActualDailyT1
    FROM Layercake.fn_silv_daily_count_as_known_at('2020-10-01', '2025-12-31', @t1) AS f
    WHERE f.active_count <> 0 OR f.paid_count <> 0 OR f.paid_count_event <> 0 OR f.event_join_count <> 0
       OR f.event_renewal_count <> 0 OR f.event_readmission_count <> 0 OR f.event_lapse_count <> 0;

    SELECT f.[date], f.region, f.grade, f.active_count, f.paid_count, f.paid_count_event,
           f.event_join_count, f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #ActualDailyT2
    FROM Layercake.fn_silv_daily_count_as_known_at('2020-10-01', '2025-12-31', @t2) AS f
    WHERE f.active_count <> 0 OR f.paid_count <> 0 OR f.paid_count_event <> 0 OR f.event_join_count <> 0
       OR f.event_renewal_count <> 0 OR f.event_readmission_count <> 0 OR f.event_lapse_count <> 0;

    EXEC tSQLt.AssertEqualsTable '#ExpectedDailyT1', '#ActualDailyT1', 'silv_daily_count grain as known at T1';
    EXEC tSQLt.AssertEqualsTable '#ExpectedDailyT2', '#ActualDailyT2', 'silv_daily_count grain as known at T2';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD031.[test TC-031-021 a group region too long for the state ranges fails the load naming the value]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @msg nvarchar(4000), @status varchar(10);

    INSERT INTO Layercake.silv_ref_local_group
        (id, local_group_bk, local_group_name, local_group_code, country_id, region_name, market_reporting_region,
         statecode, is_reportable, dim_country_id, load_id, created_at, updated_at)
    VALUES (8, 'A0000000-0000-0000-0000-000000000008', N'Long Region', N'LONG', 2, N'Middle East and Africa', 'MEA',
            0, 1, 2, 1, '2026-01-01', '2026-01-01');

    EXEC test_MOD031.[Add member] N'G9', 1, 'A0000000-0000-0000-0000-000000000008', 1;

    EXEC (N'INSERT INTO Layercake.silv_member_state_ranges (contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq, contact_region)
VALUES (N''G9'', ''2015-01-01'', NULL, 2015, ''election'', ''UK&I'', 1, ''UK&I'');');

    SELECT * INTO #ranges_before FROM Layercake.silv_member_state_ranges;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_member_state_ranges @run_id = @r1;
        EXEC tSQLt.Fail 'the state ranges load should fail on a region longer than its column';
    END TRY
    BEGIN CATCH
        SET @msg = ERROR_MESSAGE();
    END CATCH;

    IF @msg IS NULL OR @msg NOT LIKE N'%Middle East and Africa%'
        EXEC tSQLt.Fail 'expected an error naming the whole region value, got: ', @msg;

    SELECT * INTO #ranges_after FROM Layercake.silv_member_state_ranges;
    EXEC tSQLt.AssertEqualsTable '#ranges_before', '#ranges_after', 'silv_member_state_ranges unchanged';

    SELECT @status = l.status FROM Layercake.etl_run_log AS l WHERE l.run_id = @r1;
    EXEC tSQLt.AssertEquals 'Failed', @status, 'state ranges load status';
END;
GO
