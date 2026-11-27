EXEC tSQLt.NewTestClass 'test_MOD032';
GO

CREATE PROCEDURE test_MOD032.[SetUp]
AS
BEGIN
    -- logging
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    -- bronze read by the events load (kept empty: no Join/Subscription cohort, no Readmission)
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_cust_trans', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_rics_record', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact_test_record', @Defaults = 1;
    -- silver reference lists
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_lapse_reason';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_gender';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_rpq_variant';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_assessment_route';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_grade';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_status';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country_region', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    -- member inputs and MOD-032 targets
    EXEC tSQLt.FakeTable 'Layercake.silv_member_base', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_annual_rate_base', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_annual_rate_base', @Identity = 1, @Defaults = 1;
    -- gold dimensions
    EXEC tSQLt.FakeTable 'Layercake.dim_date';
    EXEC tSQLt.FakeTable 'Layercake.dim_country';
    EXEC tSQLt.FakeTable 'Layercake.dim_local_group', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_membership_grade';
    -- daily count chain (used by the daily count tests)
    EXEC tSQLt.FakeTable 'Layercake.silv_member_profile', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_state_ranges', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_date_spine';
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

    INSERT INTO Layercake.silv_ref_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');
    INSERT INTO Layercake.dim_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');
    INSERT INTO Layercake.silv_ref_membership_status (id, status_name)
    VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');
    INSERT INTO Layercake.silv_ref_gender (id, gender_code, gender_name)
    VALUES (1, 1, 'Male'), (2, 2, 'Female');

    INSERT INTO Layercake.silv_ref_country (id, country_id, country_name, region_name, market_reporting_region)
    VALUES (1, 'C0000000-0000-0000-0000-000000000001', N'United Kingdom', N'UK&I', 'UK&I'),
           (2, 'C0000000-0000-0000-0000-000000000002', N'United Arab Emirates', N'MEA', 'MEA'),
           (3, 'C0000000-0000-0000-0000-000000000003', N'India', N'APAC', 'APAC');
    INSERT INTO Layercake.silv_ref_country_region (id, country_ref_id, region_name, market_reporting_region, load_id, created_at)
    VALUES (1000001, 3, N'MEA', 'MEA', NULL, '2026-01-01');
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
           (1, 'A0000000-0000-0000-0000-000000000001', N'Gulf', N'GULF', 2, N'MEA', 'MEA', 0, 1, 2, NULL, '2026-01-01', '2026-01-01'),
           (2, 'A0000000-0000-0000-0000-000000000002', N'London', N'LON', 1, N'UK&I', 'UK&I', 0, 1, 1, NULL, '2026-01-01', '2026-01-01'),
           (3, 'A0000000-0000-0000-0000-000000000003', N'Gulf India', N'GIND', 3, N'MEA', 'MEA', 0, 1, 1000001, NULL, '2026-01-01', '2026-01-01'),
           (4, 'A0000000-0000-0000-0000-000000000004', N'No Country', N'NOC', NULL, N'MEA', 'MEA', 0, 0, NULL, NULL, '2026-01-01', '2026-01-01'),
           (5, 'A0000000-0000-0000-0000-000000000005', N'No Region', N'NOR', 2, NULL, NULL, 0, 0, NULL, NULL, '2026-01-01', '2026-01-01'),
           (6, 'A0000000-0000-0000-0000-000000000006', N'Closed Gulf', N'CGULF', 2, N'MEA', 'MEA', 1, 0, NULL, NULL, '2026-01-01', '2026-01-01'),
           (7, 'A0000000-0000-0000-0000-000000000007', N'Half Region', N'HALF', 2, N'MEA', NULL, 0, 0, NULL, NULL, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.dim_local_group (id, local_group_name, load_id, created_at, updated_at)
    VALUES (-2, N'Not applicable', NULL, '2026-01-01', '2026-01-01'),
           (0, N'Unknown', NULL, '2026-01-01', '2026-01-01'),
           (1, N'Gulf', NULL, '2026-01-01', '2026-01-01'),
           (2, N'London', NULL, '2026-01-01', '2026-01-01'),
           (3, N'Gulf India', NULL, '2026-01-01', '2026-01-01'),
           (4, N'No Country', NULL, '2026-01-01', '2026-01-01'),
           (5, N'No Region', NULL, '2026-01-01', '2026-01-01'),
           (6, N'Closed Gulf', NULL, '2026-01-01', '2026-01-01'),
           (7, N'Half Region', NULL, '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2021, '2020-10-01', '2021-09-30', '2021-12-31'),
           (2022, '2021-10-01', '2022-09-30', '2022-12-31'),
           (2023, '2022-10-01', '2023-09-30', '2023-12-31'),
           (2024, '2023-10-01', '2024-09-30', '2024-12-31'),
           (2025, '2024-10-01', '2025-09-30', '2025-12-31'),
           (2026, '2025-10-01', '2026-09-30', '2026-12-31'),
           (2027, '2026-10-01', '2027-09-30', '2027-12-31');

    -- members as MOD-031's member base load leaves them (local group basis)
    INSERT INTO Layercake.silv_member_base
        (contact_id, contact_no, enrolment_date, election_date, is_rpq, election_enr_id,
         enrolment_from_exception, election_from_exception, recorded_enrolment_date, enrolment_from_subs_history,
         recorded_election_date, election_from_subs_history, contact_lapsed_date, lapsed_date,
         lapse_reason_id, lapse_reason_name, retirement_date, source_enr_id, rpq_variant_id,
         country_id, gender_id, local_group_id, contact_country_id)
    VALUES ('B0000000-0000-0000-0000-000000000001', N'G1', NULL, '2015-01-01', 0, NULL, 0, 0, NULL, 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, 2, 1, 1, 1),
           ('B0000000-0000-0000-0000-000000000002', N'G2', NULL, '2015-01-01', 0, NULL, 0, 0, NULL, 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, 3, 1, 3, 3),
           ('B0000000-0000-0000-0000-000000000003', N'N1', NULL, '2015-01-01', 0, NULL, 0, 0, NULL, 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, 3, 1, 0, 3);

    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'G1', 2021, '2020-10-20', '2020-10-20', N'Fully Paid'),
           (N'G1', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
           (N'G2', 2025, '2024-10-20', '2024-10-20', N'Fully Paid'),
           (N'N1', 2025, '2024-11-05', '2024-11-05', N'Fully Paid');
END;
GO

CREATE PROCEDURE test_MOD032.[Run event and annual loads]
    @run_id uniqueidentifier
AS
BEGIN
    EXEC Layercake.usp_load_silv_membership_events @run_id = @run_id;
    EXEC Layercake.usp_load_silv_annual_rate_base @run_id = @run_id;
    EXEC Layercake.usp_load_fact_membership_events @run_id = @run_id;
    EXEC Layercake.usp_load_fact_annual_rate_base @run_id = @run_id;
END;
GO

CREATE PROCEDURE test_MOD032.[Copy MOD-032 tables]
AS
BEGIN
    -- The caller creates #ev, #fev, #ar and #far. The new columns are read through
    -- dynamic SQL so the suite compiles before MOD-032 adds them.
    DELETE FROM #ev;
    DELETE FROM #fev;
    DELETE FROM #ar;
    DELETE FROM #far;
    EXEC (N'INSERT INTO #ev (event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id,
                             assessment_route_id, rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id,
                             campaign_year, campaign_quarter, local_group_id, contact_country_id)
            SELECT e.event_id, e.event_nk, e.event_type, e.event_subtype, e.event_date, e.source_enr_id, e.contact_no, e.grade_id,
                   e.assessment_route_id, e.rpq_variant_id, e.hpb_id, e.country_id, e.gender_id, e.membership_status_id,
                   e.campaign_year, e.campaign_quarter, e.local_group_id, e.contact_country_id
            FROM Layercake.silv_membership_events AS e;');
    EXEC (N'INSERT INTO #fev (event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id,
                              assessment_route_id, rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id,
                              campaign_year, campaign_quarter, local_group_id, contact_country_id)
            SELECT f.event_id, f.event_type, f.event_subtype, f.event_date, f.date_id, f.contact_no, f.grade_id,
                   f.assessment_route_id, f.rpq_variant_id, f.hpb_id, f.country_id, f.gender_id, f.membership_status_id,
                   f.campaign_year, f.campaign_quarter, f.local_group_id, f.contact_country_id
            FROM Layercake.fact_membership_events AS f;');
    EXEC (N'INSERT INTO #ar (campaign_year, grade_id, membership_status_id, country_id, gender_id, local_group_id, contact_country_id,
                             members_start, members_end, members_joined, members_readmitted, members_lapsed, members_renewed)
            SELECT a.campaign_year, a.grade_id, a.membership_status_id, a.country_id, a.gender_id, a.local_group_id, a.contact_country_id,
                   a.members_start, a.members_end, a.members_joined, a.members_readmitted, a.members_lapsed, a.members_renewed
            FROM Layercake.silv_annual_rate_base AS a;');
    EXEC (N'INSERT INTO #far (campaign_year, grade_id, membership_status_id, country_id, gender_id, local_group_id, contact_country_id,
                              members_start, members_end, members_joined, members_readmitted, members_lapsed, members_renewed)
            SELECT a.campaign_year, a.grade_id, a.membership_status_id, a.country_id, a.gender_id, a.local_group_id, a.contact_country_id,
                   a.members_start, a.members_end, a.members_joined, a.members_readmitted, a.members_lapsed, a.members_renewed
            FROM Layercake.fact_annual_rate_base AS a;');
END;
GO

CREATE PROCEDURE test_MOD032.[Arrange daily count]
AS
BEGIN
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2020-10-01', 2021, 'Q1'), ('2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2020-10-01', 2021, 'Q1'), (2, '2025-01-10', 2025, 'Q2');

    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date, local_group_id, contact_country_id)
    VALUES (N'G1', 2, 1, NULL, 1, 1), (N'G2', 3, 1, NULL, 3, 3), (N'N1', 3, 1, NULL, 0, 3);

    INSERT INTO Layercake.silv_member_state_ranges (contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq, contact_region)
    VALUES (N'G1', '2015-01-01', NULL, 2015, 'election', 'MEA', 1, 'UK&I'),
           (N'G2', '2015-01-01', NULL, 2015, 'election', 'MEA', 1, 'APAC'),
           (N'N1', '2015-01-01', NULL, 2015, 'election', 'APAC', 1, 'APAC');
END;
GO

CREATE PROCEDURE test_MOD032.[Run daily count]
    @run_id uniqueidentifier
AS
BEGIN
    EXEC Layercake.usp_load_silv_daily_count @run_id = @run_id;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @run_id;
END;
GO

CREATE PROCEDURE test_MOD032.[Use own country basis]
AS
BEGIN
    -- the member inputs as they stood before the change: own country, no local group
    UPDATE Layercake.silv_member_base SET country_id = contact_country_id, local_group_id = 0;
    UPDATE Layercake.silv_member_profile SET country_id = contact_country_id, local_group_id = 0;
    UPDATE Layercake.silv_member_state_ranges SET region = contact_region;
END;
GO

CREATE PROCEDURE test_MOD032.[Use local group basis]
AS
BEGIN
    -- the member inputs as MOD-031's loads give them
    UPDATE mb
    SET country_id = v.country_id, local_group_id = v.local_group_id
    FROM Layercake.silv_member_base AS mb
    INNER JOIN (VALUES (N'G1', 2, 1), (N'G2', 3, 3), (N'N1', 3, 0)) AS v(contact_no, country_id, local_group_id)
        ON v.contact_no = mb.contact_no;
    UPDATE pr
    SET country_id = v.country_id, local_group_id = v.local_group_id
    FROM Layercake.silv_member_profile AS pr
    INNER JOIN (VALUES (N'G1', 2, 1), (N'G2', 3, 3), (N'N1', 3, 0)) AS v(contact_no, country_id, local_group_id)
        ON v.contact_no = pr.contact_no;
    UPDATE sr
    SET region = v.region
    FROM Layercake.silv_member_state_ranges AS sr
    INNER JOIN (VALUES (N'G1', 'MEA'), (N'G2', 'MEA'), (N'N1', 'APAC')) AS v(contact_no, region)
        ON v.contact_no = sr.contact_no;
END;
GO

CREATE PROCEDURE test_MOD032.[Assert loads equal a fresh load]
    @run_id uniqueidentifier
AS
BEGIN
    -- the caller has created #ev, #fev, #ar and #far
    EXEC test_MOD032.[Copy MOD-032 tables];
    SELECT e.event_nk, e.event_type, e.event_subtype, e.event_date, e.source_enr_id, e.contact_no, e.grade_id,
           e.assessment_route_id, e.rpq_variant_id, e.hpb_id, e.country_id, e.gender_id, e.membership_status_id,
           e.campaign_year, e.campaign_quarter, e.local_group_id, e.contact_country_id
    INTO #stored_events FROM #ev AS e;
    SELECT s.event_nk, f.event_type, f.event_subtype, f.event_date, f.date_id, f.contact_no, f.grade_id,
           f.assessment_route_id, f.rpq_variant_id, f.hpb_id, f.country_id, f.gender_id, f.membership_status_id,
           f.campaign_year, f.campaign_quarter, f.local_group_id, f.contact_country_id
    INTO #stored_fact_events FROM #fev AS f LEFT JOIN #ev AS s ON s.event_id = f.event_id;
    SELECT * INTO #stored_annual FROM #ar;
    SELECT * INTO #stored_fact_annual FROM #far;

    DELETE FROM Layercake.fact_membership_events;
    DELETE FROM Layercake.fact_annual_rate_base;
    DELETE FROM Layercake.silv_membership_events;
    DELETE FROM Layercake.silv_annual_rate_base;

    EXEC test_MOD032.[Run event and annual loads] @run_id = @run_id;

    EXEC test_MOD032.[Copy MOD-032 tables];
    SELECT e.event_nk, e.event_type, e.event_subtype, e.event_date, e.source_enr_id, e.contact_no, e.grade_id,
           e.assessment_route_id, e.rpq_variant_id, e.hpb_id, e.country_id, e.gender_id, e.membership_status_id,
           e.campaign_year, e.campaign_quarter, e.local_group_id, e.contact_country_id
    INTO #fresh_events FROM #ev AS e;
    SELECT s.event_nk, f.event_type, f.event_subtype, f.event_date, f.date_id, f.contact_no, f.grade_id,
           f.assessment_route_id, f.rpq_variant_id, f.hpb_id, f.country_id, f.gender_id, f.membership_status_id,
           f.campaign_year, f.campaign_quarter, f.local_group_id, f.contact_country_id
    INTO #fresh_fact_events FROM #fev AS f LEFT JOIN #ev AS s ON s.event_id = f.event_id;
    SELECT * INTO #fresh_annual FROM #ar;
    SELECT * INTO #fresh_fact_annual FROM #far;

    EXEC tSQLt.AssertEqualsTable '#fresh_events', '#stored_events', 'silv_membership_events differs from a fresh load';
    EXEC tSQLt.AssertEqualsTable '#fresh_fact_events', '#stored_fact_events', 'fact_membership_events differs from a fresh load';
    EXEC tSQLt.AssertEqualsTable '#fresh_annual', '#stored_annual', 'silv_annual_rate_base differs from a fresh load';
    EXEC tSQLt.AssertEqualsTable '#fresh_fact_annual', '#stored_fact_annual', 'fact_annual_rate_base differs from a fresh load';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-001 events and annual rate base tables gain local_group_id and contact_country_id int not null]
AS
BEGIN
    SELECT PARSENAME(r.OriginalName, 1) AS table_name, c.name AS column_name, TYPE_NAME(c.user_type_id) AS data_type, c.is_nullable
    INTO #Actual
    FROM tSQLt.Private_RenamedObjectLog AS r
    INNER JOIN sys.columns AS c ON c.object_id = r.ObjectId
    WHERE OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake'
      AND PARSENAME(r.OriginalName, 1) IN (N'silv_membership_events', N'fact_membership_events', N'silv_annual_rate_base', N'fact_annual_rate_base')
      AND c.name IN (N'local_group_id', N'contact_country_id');

    SELECT v.table_name, v.column_name, v.data_type, CAST(v.is_nullable AS bit) AS is_nullable
    INTO #Expected
    FROM (VALUES
        (N'silv_membership_events', N'local_group_id', N'int', 0),
        (N'silv_membership_events', N'contact_country_id', N'int', 0),
        (N'fact_membership_events', N'local_group_id', N'int', 0),
        (N'fact_membership_events', N'contact_country_id', N'int', 0),
        (N'silv_annual_rate_base', N'local_group_id', N'int', 0),
        (N'silv_annual_rate_base', N'contact_country_id', N'int', 0),
        (N'fact_annual_rate_base', N'local_group_id', N'int', 0),
        (N'fact_annual_rate_base', N'contact_country_id', N'int', 0)
    ) AS v(table_name, column_name, data_type, is_nullable);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT PARSENAME(r.OriginalName, 1) AS table_name, COUNT(*) AS column_count
    INTO #ActualCounts
    FROM tSQLt.Private_RenamedObjectLog AS r
    INNER JOIN sys.columns AS c ON c.object_id = r.ObjectId
    WHERE OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake'
      AND PARSENAME(r.OriginalName, 1) IN (N'silv_membership_events', N'fact_membership_events', N'silv_annual_rate_base', N'fact_annual_rate_base')
    GROUP BY PARSENAME(r.OriginalName, 1);

    SELECT v.table_name, v.column_count
    INTO #ExpectedCounts
    FROM (VALUES
        (N'silv_membership_events', 27),
        (N'fact_membership_events', 26),
        (N'silv_annual_rate_base', 13),
        (N'fact_annual_rate_base', 14)
    ) AS v(table_name, column_count);

    EXEC tSQLt.AssertEqualsTable '#ExpectedCounts', '#ActualCounts';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-002 the fact annual rate base unique key covers the seven grain columns]
AS
BEGIN
    DECLARE @object_id int =
        (SELECT r.ObjectId
         FROM tSQLt.Private_RenamedObjectLog AS r
         WHERE OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake'
           AND PARSENAME(r.OriginalName, 1) = N'fact_annual_rate_base');

    SELECT i.index_id,
           STRING_AGG(CAST(c.name AS nvarchar(128)), N',') WITHIN GROUP (ORDER BY c.name) AS key_columns
    INTO #keys
    FROM sys.indexes AS i
    INNER JOIN sys.index_columns AS ic
        ON ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
    INNER JOIN sys.columns AS c
        ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = @object_id
      AND i.is_unique = 1
    GROUP BY i.index_id;

    SELECT k.key_columns
    INTO #Actual
    FROM #keys AS k
    WHERE k.key_columns LIKE N'%campaign[_]year%';

    SELECT v.key_columns
    INTO #Expected
    FROM (VALUES (N'campaign_year,contact_country_id,country_id,gender_id,grade_id,local_group_id,membership_status_id'))
        AS v(key_columns);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-003 every event carries the member base country local group and own country]
AS
BEGIN
    CREATE TABLE #ev (event_id int NULL, event_nk nvarchar(220) COLLATE DATABASE_DEFAULT NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, source_enr_id uniqueidentifier NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #fev (event_id int NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, date_id int NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #ar (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);
    CREATE TABLE #far (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);

    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    EXEC test_MOD032.[Copy MOD-032 tables];

    SELECT e.event_nk, e.event_type, e.country_id, e.local_group_id, e.contact_country_id
    INTO #Actual
    FROM #ev AS e;

    SELECT v.event_nk, v.event_type, v.country_id, v.local_group_id, v.contact_country_id
    INTO #Expected
    FROM (VALUES
        (N'JR:G1', 'Join', 2, 1, 1),
        (N'RN:G1:2021', 'Renewal', 2, 1, 1),
        (N'RN:G1:2025', 'Renewal', 2, 1, 1),
        (N'JR:G2', 'Join', 3, 3, 3),
        (N'RN:G2:2025', 'Renewal', 3, 3, 3),
        (N'JR:N1', 'Join', 3, 0, 3),
        (N'RN:N1:2025', 'Renewal', 3, 0, 3)
    ) AS v(event_nk, event_type, country_id, local_group_id, contact_country_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @not_success int = (SELECT COUNT(*) FROM Layercake.etl_run_log WHERE status <> 'Success');
    EXEC tSQLt.AssertEquals 0, @not_success, 'every load logs Success';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-004 gold events reach the group region through country_id and the own region through contact_country_id]
AS
BEGIN
    CREATE TABLE #ev (event_id int NULL, event_nk nvarchar(220) COLLATE DATABASE_DEFAULT NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, source_enr_id uniqueidentifier NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #fev (event_id int NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, date_id int NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #ar (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);
    CREATE TABLE #far (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);

    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    EXEC test_MOD032.[Copy MOD-032 tables];

    SELECT s.event_nk, f.local_group_id,
           dc.country_name, dc.region_name, dc.market_reporting_region,
           oc.country_name AS contact_country_name, oc.region_name AS contact_region_name,
           oc.market_reporting_region AS contact_market_reporting_region
    INTO #Actual
    FROM #fev AS f
    LEFT JOIN #ev AS s ON s.event_id = f.event_id
    LEFT JOIN Layercake.dim_country AS dc ON dc.id = f.country_id
    LEFT JOIN Layercake.dim_country AS oc ON oc.id = f.contact_country_id;

    SELECT v.event_nk, v.local_group_id, v.country_name, v.region_name, v.market_reporting_region,
           v.contact_country_name, v.contact_region_name, v.contact_market_reporting_region
    INTO #Expected
    FROM (VALUES
        (N'JR:G1', 1, N'United Arab Emirates', N'MEA', 'MEA', N'United Kingdom', N'UK&I', 'UK&I'),
        (N'RN:G1:2021', 1, N'United Arab Emirates', N'MEA', 'MEA', N'United Kingdom', N'UK&I', 'UK&I'),
        (N'RN:G1:2025', 1, N'United Arab Emirates', N'MEA', 'MEA', N'United Kingdom', N'UK&I', 'UK&I'),
        (N'JR:G2', 3, N'India', N'MEA', 'MEA', N'India', N'APAC', 'APAC'),
        (N'RN:G2:2025', 3, N'India', N'MEA', 'MEA', N'India', N'APAC', 'APAC'),
        (N'JR:N1', 0, N'India', N'APAC', 'APAC', N'India', N'APAC', 'APAC'),
        (N'RN:N1:2025', 0, N'India', N'APAC', 'APAC', N'India', N'APAC', 'APAC')
    ) AS v(event_nk, local_group_id, country_name, region_name, market_reporting_region,
           contact_country_name, contact_region_name, contact_market_reporting_region);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-005 the silver annual rate base counts members under their local group country and own country]
AS
BEGIN
    CREATE TABLE #ev (event_id int NULL, event_nk nvarchar(220) COLLATE DATABASE_DEFAULT NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, source_enr_id uniqueidentifier NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #fev (event_id int NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, date_id int NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #ar (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);
    CREATE TABLE #far (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);

    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    EXEC test_MOD032.[Copy MOD-032 tables];

    SELECT a.campaign_year, a.grade_id, a.membership_status_id, a.country_id, a.gender_id, a.local_group_id, a.contact_country_id,
           a.members_start, a.members_end, a.members_joined, a.members_readmitted, a.members_lapsed, a.members_renewed
    INTO #Actual
    FROM #ar AS a
    WHERE a.campaign_year IN (2021, 2025);

    SELECT v.campaign_year, v.grade_id, v.membership_status_id, v.country_id, v.gender_id, v.local_group_id, v.contact_country_id,
           v.members_start, v.members_end, v.members_joined, v.members_readmitted, v.members_lapsed, v.members_renewed
    INTO #Expected
    FROM (VALUES
        (2021, 2, 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 1),
        (2021, 2, 1, 3, 1, 3, 3, 1, 1, 0, 0, 0, 0),
        (2021, 2, 1, 3, 1, 0, 3, 1, 1, 0, 0, 0, 0),
        (2025, 2, 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 1),
        (2025, 2, 1, 3, 1, 3, 3, 1, 1, 0, 0, 0, 1),
        (2025, 2, 1, 3, 1, 0, 3, 1, 1, 0, 0, 0, 1)
    ) AS v(campaign_year, grade_id, membership_status_id, country_id, gender_id, local_group_id, contact_country_id,
           members_start, members_end, members_joined, members_readmitted, members_lapsed, members_renewed);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-006 the gold annual rate base reaches the group region and the own region through its two country keys]
AS
BEGIN
    CREATE TABLE #ev (event_id int NULL, event_nk nvarchar(220) COLLATE DATABASE_DEFAULT NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, source_enr_id uniqueidentifier NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #fev (event_id int NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, date_id int NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #ar (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);
    CREATE TABLE #far (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);

    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    EXEC test_MOD032.[Copy MOD-032 tables];

    SELECT f.campaign_year, f.grade_id, f.membership_status_id, f.gender_id, f.local_group_id,
           dc.region_name, dc.market_reporting_region,
           oc.region_name AS contact_region_name, oc.market_reporting_region AS contact_market_reporting_region,
           f.members_start, f.members_end, f.members_joined, f.members_readmitted, f.members_lapsed, f.members_renewed
    INTO #Actual
    FROM #far AS f
    LEFT JOIN Layercake.dim_country AS dc ON dc.id = f.country_id
    LEFT JOIN Layercake.dim_country AS oc ON oc.id = f.contact_country_id
    WHERE f.campaign_year IN (2021, 2025);

    SELECT v.campaign_year, v.grade_id, v.membership_status_id, v.gender_id, v.local_group_id,
           v.region_name, v.market_reporting_region, v.contact_region_name, v.contact_market_reporting_region,
           v.members_start, v.members_end, v.members_joined, v.members_readmitted, v.members_lapsed, v.members_renewed
    INTO #Expected
    FROM (VALUES
        (2021, 2, 1, 1, 1, N'MEA', 'MEA', N'UK&I', 'UK&I', 1, 1, 0, 0, 0, 1),
        (2021, 2, 1, 1, 3, N'MEA', 'MEA', N'APAC', 'APAC', 1, 1, 0, 0, 0, 0),
        (2021, 2, 1, 1, 0, N'APAC', 'APAC', N'APAC', 'APAC', 1, 1, 0, 0, 0, 0),
        (2025, 2, 1, 1, 1, N'MEA', 'MEA', N'UK&I', 'UK&I', 1, 1, 0, 0, 0, 1),
        (2025, 2, 1, 1, 3, N'MEA', 'MEA', N'APAC', 'APAC', 1, 1, 0, 0, 0, 1),
        (2025, 2, 1, 1, 0, N'APAC', 'APAC', N'APAC', 'APAC', 1, 1, 0, 0, 0, 1)
    ) AS v(campaign_year, grade_id, membership_status_id, gender_id, local_group_id,
           region_name, market_reporting_region, contact_region_name, contact_market_reporting_region,
           members_start, members_end, members_joined, members_readmitted, members_lapsed, members_renewed);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-007 the annual grain keeps members of one country in different local groups apart]
AS
BEGIN
    CREATE TABLE #ev (event_id int NULL, event_nk nvarchar(220) COLLATE DATABASE_DEFAULT NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, source_enr_id uniqueidentifier NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #fev (event_id int NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, date_id int NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #ar (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);
    CREATE TABLE #far (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);

    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    EXEC test_MOD032.[Copy MOD-032 tables];

    SELECT a.campaign_year, a.grade_id, a.membership_status_id, a.country_id, a.gender_id, a.local_group_id, a.contact_country_id,
           COUNT(*) AS row_count
    INTO #duplicates
    FROM #ar AS a
    GROUP BY a.campaign_year, a.grade_id, a.membership_status_id, a.country_id, a.gender_id, a.local_group_id, a.contact_country_id
    HAVING COUNT(*) > 1;
    EXEC tSQLt.AssertEmptyTable '#duplicates';

    SELECT a.campaign_year, a.local_group_id, a.members_start, a.members_end
    INTO #Actual
    FROM #ar AS a
    WHERE a.country_id = 3 AND a.campaign_year = 2025;

    SELECT v.campaign_year, v.local_group_id, v.members_start, v.members_end
    INTO #Expected
    FROM (VALUES (2025, 3, 1, 1), (2025, 0, 1, 1)) AS v(campaign_year, local_group_id, members_start, members_end);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT a.campaign_year, a.grade_id, a.membership_status_id, a.gender_id, a.local_group_id, a.contact_country_id,
           a.members_start, a.members_end, a.members_joined, a.members_readmitted, a.members_lapsed, a.members_renewed
    INTO #silver_rows
    FROM #ar AS a;
    SELECT f.campaign_year, f.grade_id, f.membership_status_id, f.gender_id, f.local_group_id, f.contact_country_id,
           f.members_start, f.members_end, f.members_joined, f.members_readmitted, f.members_lapsed, f.members_renewed
    INTO #gold_rows
    FROM #far AS f;
    EXEC tSQLt.AssertEqualsTable '#silver_rows', '#gold_rows', 'one gold row per silver row';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-008 totals not split by region country or local group are the same before and after the change]
AS
BEGIN
    CREATE TABLE #ev (event_id int NULL, event_nk nvarchar(220) COLLATE DATABASE_DEFAULT NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, source_enr_id uniqueidentifier NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #fev (event_id int NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, date_id int NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #ar (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);
    CREATE TABLE #far (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);

    EXEC test_MOD032.[Use own country basis];
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    EXEC test_MOD032.[Copy MOD-032 tables];

    SELECT e.event_nk, e.event_id, e.event_type INTO #before_events FROM #ev AS e;
    SELECT f.event_id, f.event_type INTO #before_fact_events FROM #fev AS f;
    SELECT a.campaign_year, a.grade_id, a.membership_status_id, a.gender_id,
           SUM(a.members_start) AS members_start, SUM(a.members_end) AS members_end, SUM(a.members_joined) AS members_joined,
           SUM(a.members_readmitted) AS members_readmitted, SUM(a.members_lapsed) AS members_lapsed, SUM(a.members_renewed) AS members_renewed
    INTO #before_annual
    FROM #ar AS a
    GROUP BY a.campaign_year, a.grade_id, a.membership_status_id, a.gender_id;
    SELECT a.campaign_year, a.grade_id, a.membership_status_id, a.gender_id,
           SUM(a.members_start) AS members_start, SUM(a.members_end) AS members_end, SUM(a.members_joined) AS members_joined,
           SUM(a.members_readmitted) AS members_readmitted, SUM(a.members_lapsed) AS members_lapsed, SUM(a.members_renewed) AS members_renewed
    INTO #before_fact_annual
    FROM #far AS a
    GROUP BY a.campaign_year, a.grade_id, a.membership_status_id, a.gender_id;

    SELECT b.event_type, COUNT(*) AS event_count INTO #ActualBeforeTypes FROM #before_events AS b GROUP BY b.event_type;
    SELECT v.event_type, v.event_count INTO #ExpectedBeforeTypes
    FROM (VALUES ('Join', 3), ('Renewal', 4)) AS v(event_type, event_count);
    EXEC tSQLt.AssertEqualsTable '#ExpectedBeforeTypes', '#ActualBeforeTypes', 'events before the change';

    SELECT b.campaign_year, b.grade_id, b.membership_status_id, b.gender_id, b.members_start, b.members_end,
           b.members_joined, b.members_readmitted, b.members_lapsed, b.members_renewed
    INTO #ActualBeforeAnnual
    FROM #before_annual AS b WHERE b.campaign_year IN (2021, 2025);
    SELECT v.campaign_year, v.grade_id, v.membership_status_id, v.gender_id, v.members_start, v.members_end,
           v.members_joined, v.members_readmitted, v.members_lapsed, v.members_renewed
    INTO #ExpectedBeforeAnnual
    FROM (VALUES (2021, 2, 1, 1, 3, 3, 0, 0, 0, 1), (2025, 2, 1, 1, 3, 3, 0, 0, 0, 3))
        AS v(campaign_year, grade_id, membership_status_id, gender_id, members_start, members_end,
             members_joined, members_readmitted, members_lapsed, members_renewed);
    EXEC tSQLt.AssertEqualsTable '#ExpectedBeforeAnnual', '#ActualBeforeAnnual', 'annual totals before the change';

    EXEC test_MOD032.[Use local group basis];
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000002';
    EXEC test_MOD032.[Copy MOD-032 tables];

    DECLARE @in_a_group int = (SELECT COUNT(*) FROM #ev WHERE local_group_id <> 0);
    EXEC tSQLt.AssertEquals 5, @in_a_group, 'G1 and G2 events now carry their local group';

    SELECT e.event_nk, e.event_id, e.event_type INTO #after_events FROM #ev AS e;
    SELECT f.event_id, f.event_type INTO #after_fact_events FROM #fev AS f;
    SELECT a.campaign_year, a.grade_id, a.membership_status_id, a.gender_id,
           SUM(a.members_start) AS members_start, SUM(a.members_end) AS members_end, SUM(a.members_joined) AS members_joined,
           SUM(a.members_readmitted) AS members_readmitted, SUM(a.members_lapsed) AS members_lapsed, SUM(a.members_renewed) AS members_renewed
    INTO #after_annual
    FROM #ar AS a
    GROUP BY a.campaign_year, a.grade_id, a.membership_status_id, a.gender_id;
    SELECT a.campaign_year, a.grade_id, a.membership_status_id, a.gender_id,
           SUM(a.members_start) AS members_start, SUM(a.members_end) AS members_end, SUM(a.members_joined) AS members_joined,
           SUM(a.members_readmitted) AS members_readmitted, SUM(a.members_lapsed) AS members_lapsed, SUM(a.members_renewed) AS members_renewed
    INTO #after_fact_annual
    FROM #far AS a
    GROUP BY a.campaign_year, a.grade_id, a.membership_status_id, a.gender_id;

    EXEC tSQLt.AssertEqualsTable '#before_events', '#after_events', 'silver events: same (event_nk, event_id) pairs and types';
    EXEC tSQLt.AssertEqualsTable '#before_fact_events', '#after_fact_events', 'gold events: same event_id and types';
    EXEC tSQLt.AssertEqualsTable '#before_annual', '#after_annual', 'silver annual summed over country, local group and own country';
    EXEC tSQLt.AssertEqualsTable '#before_fact_annual', '#after_fact_annual', 'gold annual summed over country, local group and own country';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-009 contact_country_id holds the country each event and annual row had before the change]
AS
BEGIN
    CREATE TABLE #ev (event_id int NULL, event_nk nvarchar(220) COLLATE DATABASE_DEFAULT NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, source_enr_id uniqueidentifier NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #fev (event_id int NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, date_id int NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #ar (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);
    CREATE TABLE #far (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);

    EXEC test_MOD032.[Use own country basis];
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    EXEC test_MOD032.[Copy MOD-032 tables];

    SELECT e.event_id, e.event_nk, e.country_id INTO #before_events FROM #ev AS e;
    SELECT f.event_id, f.country_id INTO #before_fact_events FROM #fev AS f;
    SELECT a.campaign_year, a.grade_id, a.membership_status_id, a.country_id, a.gender_id,
           SUM(a.members_start) AS members_start, SUM(a.members_end) AS members_end, SUM(a.members_joined) AS members_joined,
           SUM(a.members_readmitted) AS members_readmitted, SUM(a.members_lapsed) AS members_lapsed, SUM(a.members_renewed) AS members_renewed
    INTO #before_annual
    FROM #ar AS a
    GROUP BY a.campaign_year, a.grade_id, a.membership_status_id, a.country_id, a.gender_id;

    EXEC test_MOD032.[Use local group basis];
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000002';
    EXEC test_MOD032.[Copy MOD-032 tables];

    SELECT b.event_nk, s.contact_country_id, b.country_id AS country_before
    INTO #mismatch
    FROM #before_events AS b
    LEFT JOIN #ev AS s ON s.event_id = b.event_id
    WHERE s.event_id IS NULL OR s.contact_country_id <> b.country_id;
    EXEC tSQLt.AssertEmptyTable '#mismatch', 'silver events';

    SELECT b.event_id, f.contact_country_id, b.country_id AS country_before
    INTO #fact_mismatch
    FROM #before_fact_events AS b
    LEFT JOIN #fev AS f ON f.event_id = b.event_id
    WHERE f.event_id IS NULL OR f.contact_country_id <> b.country_id;
    EXEC tSQLt.AssertEmptyTable '#fact_mismatch', 'gold events';

    SELECT e.event_nk, e.contact_country_id INTO #Actual FROM #ev AS e;
    SELECT v.event_nk, v.contact_country_id INTO #Expected
    FROM (VALUES (N'JR:G1', 1), (N'RN:G1:2021', 1), (N'RN:G1:2025', 1), (N'JR:G2', 3), (N'RN:G2:2025', 3),
                 (N'JR:N1', 3), (N'RN:N1:2025', 3)) AS v(event_nk, contact_country_id);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT a.campaign_year, a.grade_id, a.membership_status_id, a.contact_country_id AS country_id, a.gender_id,
           SUM(a.members_start) AS members_start, SUM(a.members_end) AS members_end, SUM(a.members_joined) AS members_joined,
           SUM(a.members_readmitted) AS members_readmitted, SUM(a.members_lapsed) AS members_lapsed, SUM(a.members_renewed) AS members_renewed
    INTO #after_annual
    FROM #ar AS a
    GROUP BY a.campaign_year, a.grade_id, a.membership_status_id, a.contact_country_id, a.gender_id;
    EXEC tSQLt.AssertEqualsTable '#before_annual', '#after_annual', 'annual by own country after equals by country before';

    SELECT a.campaign_year, a.country_id, a.members_start, a.members_end, a.members_renewed
    INTO #ActualAnnual FROM #after_annual AS a WHERE a.campaign_year = 2025;
    SELECT v.campaign_year, v.country_id, v.members_start, v.members_end, v.members_renewed
    INTO #ExpectedAnnual FROM (VALUES (2025, 1, 1, 1, 1), (2025, 3, 2, 2, 2))
        AS v(campaign_year, country_id, members_start, members_end, members_renewed);
    EXEC tSQLt.AssertEqualsTable '#ExpectedAnnual', '#ActualAnnual';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-010 G1 moving from Gulf to London moves its events and annual rows on the next run and matches a fresh load]
AS
BEGIN
    CREATE TABLE #ev (event_id int NULL, event_nk nvarchar(220) COLLATE DATABASE_DEFAULT NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, source_enr_id uniqueidentifier NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #fev (event_id int NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, date_id int NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #ar (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);
    CREATE TABLE #far (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);

    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    SELECT e.event_nk, e.event_id INTO #ids_before FROM Layercake.silv_membership_events AS e;

    -- as MOD-031's member base load leaves G1 once its rics_localgroupid is London
    UPDATE Layercake.silv_member_base SET country_id = 1, local_group_id = 2, contact_country_id = 1 WHERE contact_no = N'G1';
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000002';
    EXEC test_MOD032.[Copy MOD-032 tables];

    SELECT e.event_nk, e.event_id INTO #ids_after FROM Layercake.silv_membership_events AS e;
    EXEC tSQLt.AssertEqualsTable '#ids_before', '#ids_after', 'event_nk and event_id unchanged';

    SELECT e.event_nk, e.country_id, e.local_group_id, e.contact_country_id INTO #Actual FROM #ev AS e;
    SELECT v.event_nk, v.country_id, v.local_group_id, v.contact_country_id INTO #Expected
    FROM (VALUES (N'JR:G1', 1, 2, 1), (N'RN:G1:2021', 1, 2, 1), (N'RN:G1:2025', 1, 2, 1),
                 (N'JR:G2', 3, 3, 3), (N'RN:G2:2025', 3, 3, 3), (N'JR:N1', 3, 0, 3), (N'RN:N1:2025', 3, 0, 3))
        AS v(event_nk, country_id, local_group_id, contact_country_id);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'silver events';

    SELECT a.campaign_year, a.grade_id, a.membership_status_id, a.country_id, a.gender_id, a.local_group_id, a.contact_country_id,
           a.members_start, a.members_end, a.members_renewed
    INTO #ActualAnnual
    FROM #ar AS a
    WHERE a.contact_country_id = 1 AND a.campaign_year IN (2021, 2025);
    SELECT v.campaign_year, v.grade_id, v.membership_status_id, v.country_id, v.gender_id, v.local_group_id, v.contact_country_id,
           v.members_start, v.members_end, v.members_renewed
    INTO #ExpectedAnnual
    FROM (VALUES (2021, 2, 1, 1, 1, 2, 1, 1, 1, 1), (2025, 2, 1, 1, 1, 2, 1, 1, 1, 1))
        AS v(campaign_year, grade_id, membership_status_id, country_id, gender_id, local_group_id, contact_country_id,
             members_start, members_end, members_renewed);
    EXEC tSQLt.AssertEqualsTable '#ExpectedAnnual', '#ActualAnnual', 'silver annual rate base';

    SELECT x.table_name INTO #gulf_rows
    FROM (SELECT 'silv_membership_events' AS table_name FROM #ev WHERE local_group_id = 1
          UNION ALL SELECT 'fact_membership_events' FROM #fev WHERE local_group_id = 1
          UNION ALL SELECT 'silv_annual_rate_base' FROM #ar WHERE local_group_id = 1
          UNION ALL SELECT 'fact_annual_rate_base' FROM #far WHERE local_group_id = 1) AS x;
    EXEC tSQLt.AssertEmptyTable '#gulf_rows', 'no Gulf row remains';

    SELECT s.event_nk, f.local_group_id, dc.region_name, dc.market_reporting_region, oc.region_name AS contact_region_name
    INTO #ActualGold
    FROM #fev AS f
    LEFT JOIN #ev AS s ON s.event_id = f.event_id
    LEFT JOIN Layercake.dim_country AS dc ON dc.id = f.country_id
    LEFT JOIN Layercake.dim_country AS oc ON oc.id = f.contact_country_id
    WHERE f.contact_no = N'G1';
    SELECT v.event_nk, v.local_group_id, v.region_name, v.market_reporting_region, v.contact_region_name INTO #ExpectedGold
    FROM (VALUES (N'JR:G1', 2, N'UK&I', 'UK&I', N'UK&I'), (N'RN:G1:2021', 2, N'UK&I', 'UK&I', N'UK&I'),
                 (N'RN:G1:2025', 2, N'UK&I', 'UK&I', N'UK&I'))
        AS v(event_nk, local_group_id, region_name, market_reporting_region, contact_region_name);
    EXEC tSQLt.AssertEqualsTable '#ExpectedGold', '#ActualGold', 'gold events';

    SELECT f.campaign_year, f.local_group_id, dc.region_name, dc.market_reporting_region, oc.region_name AS contact_region_name
    INTO #ActualGoldAnnual
    FROM #far AS f
    LEFT JOIN Layercake.dim_country AS dc ON dc.id = f.country_id
    LEFT JOIN Layercake.dim_country AS oc ON oc.id = f.contact_country_id
    WHERE f.contact_country_id = 1 AND f.campaign_year IN (2021, 2025);
    SELECT v.campaign_year, v.local_group_id, v.region_name, v.market_reporting_region, v.contact_region_name INTO #ExpectedGoldAnnual
    FROM (VALUES (2021, 2, N'UK&I', 'UK&I', N'UK&I'), (2025, 2, N'UK&I', 'UK&I', N'UK&I'))
        AS v(campaign_year, local_group_id, region_name, market_reporting_region, contact_region_name);
    EXEC tSQLt.AssertEqualsTable '#ExpectedGoldAnnual', '#ActualGoldAnnual', 'gold annual rate base';

    EXEC test_MOD032.[Assert loads equal a fresh load] @run_id = 'E0000000-0000-0000-0000-000000000003';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-011 Gulf made inactive moves G1 events and annual rows wholly back to its own country with local group 0]
AS
BEGIN
    CREATE TABLE #ev (event_id int NULL, event_nk nvarchar(220) COLLATE DATABASE_DEFAULT NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, source_enr_id uniqueidentifier NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #fev (event_id int NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, date_id int NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #ar (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);
    CREATE TABLE #far (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);

    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    SELECT e.event_nk, e.event_id INTO #ids_before FROM Layercake.silv_membership_events AS e;

    -- as MOD-030's list load and MOD-031's member base load leave them once Gulf has statecode 1
    UPDATE Layercake.silv_ref_local_group SET statecode = 1, is_reportable = 0, dim_country_id = NULL WHERE id = 1;
    UPDATE Layercake.silv_member_base SET country_id = 1, local_group_id = 0, contact_country_id = 1 WHERE contact_no = N'G1';
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000002';
    EXEC test_MOD032.[Copy MOD-032 tables];

    SELECT e.event_nk, e.event_id INTO #ids_after FROM Layercake.silv_membership_events AS e;
    EXEC tSQLt.AssertEqualsTable '#ids_before', '#ids_after', 'event_nk and event_id unchanged';

    SELECT e.event_nk, e.country_id, e.local_group_id, e.contact_country_id INTO #Actual
    FROM #ev AS e WHERE e.contact_no = N'G1';
    SELECT v.event_nk, v.country_id, v.local_group_id, v.contact_country_id INTO #Expected
    FROM (VALUES (N'JR:G1', 1, 0, 1), (N'RN:G1:2021', 1, 0, 1), (N'RN:G1:2025', 1, 0, 1))
        AS v(event_nk, country_id, local_group_id, contact_country_id);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'silver events';

    SELECT a.campaign_year, a.country_id, a.local_group_id, a.contact_country_id, a.members_start, a.members_end, a.members_renewed
    INTO #ActualAnnual
    FROM #ar AS a
    WHERE a.contact_country_id = 1 AND a.campaign_year IN (2021, 2025);
    SELECT v.campaign_year, v.country_id, v.local_group_id, v.contact_country_id, v.members_start, v.members_end, v.members_renewed
    INTO #ExpectedAnnual
    FROM (VALUES (2021, 1, 0, 1, 1, 1, 1), (2025, 1, 0, 1, 1, 1, 1))
        AS v(campaign_year, country_id, local_group_id, contact_country_id, members_start, members_end, members_renewed);
    EXEC tSQLt.AssertEqualsTable '#ExpectedAnnual', '#ActualAnnual', 'silver annual rate base';

    SELECT x.table_name INTO #gulf_rows
    FROM (SELECT 'silv_membership_events' AS table_name FROM #ev WHERE local_group_id = 1
          UNION ALL SELECT 'fact_membership_events' FROM #fev WHERE local_group_id = 1
          UNION ALL SELECT 'silv_annual_rate_base' FROM #ar WHERE local_group_id = 1
          UNION ALL SELECT 'fact_annual_rate_base' FROM #far WHERE local_group_id = 1) AS x;
    EXEC tSQLt.AssertEmptyTable '#gulf_rows', 'no Gulf row remains';

    SELECT s.event_nk, f.local_group_id, dc.country_name, dc.region_name, dc.market_reporting_region
    INTO #ActualGold
    FROM #fev AS f
    LEFT JOIN #ev AS s ON s.event_id = f.event_id
    LEFT JOIN Layercake.dim_country AS dc ON dc.id = f.country_id
    WHERE f.contact_no = N'G1';
    SELECT v.event_nk, v.local_group_id, v.country_name, v.region_name, v.market_reporting_region INTO #ExpectedGold
    FROM (VALUES (N'JR:G1', 0, N'United Kingdom', N'UK&I', 'UK&I'), (N'RN:G1:2021', 0, N'United Kingdom', N'UK&I', 'UK&I'),
                 (N'RN:G1:2025', 0, N'United Kingdom', N'UK&I', 'UK&I'))
        AS v(event_nk, local_group_id, country_name, region_name, market_reporting_region);
    EXEC tSQLt.AssertEqualsTable '#ExpectedGold', '#ActualGold', 'gold events';

    SELECT f.campaign_year, f.local_group_id, dc.region_name, dc.market_reporting_region
    INTO #ActualGoldAnnual
    FROM #far AS f
    LEFT JOIN Layercake.dim_country AS dc ON dc.id = f.country_id
    WHERE f.contact_country_id = 1 AND f.campaign_year IN (2021, 2025);
    SELECT v.campaign_year, v.local_group_id, v.region_name, v.market_reporting_region INTO #ExpectedGoldAnnual
    FROM (VALUES (2021, 0, N'UK&I', 'UK&I'), (2025, 0, N'UK&I', 'UK&I'))
        AS v(campaign_year, local_group_id, region_name, market_reporting_region);
    EXEC tSQLt.AssertEqualsTable '#ExpectedGoldAnnual', '#ActualGoldAnnual', 'gold annual rate base';

    EXEC test_MOD032.[Assert loads equal a fresh load] @run_id = 'E0000000-0000-0000-0000-000000000003';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-012 a change to the group dim_country_id alone moves gold rows and leaves silver unchanged]
AS
BEGIN
    CREATE TABLE #ev (event_id int NULL, event_nk nvarchar(220) COLLATE DATABASE_DEFAULT NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, source_enr_id uniqueidentifier NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #fev (event_id int NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, date_id int NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #ar (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);
    CREATE TABLE #far (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);

    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    SELECT * INTO #events_before FROM Layercake.silv_membership_events;
    SELECT * INTO #annual_before FROM Layercake.silv_annual_rate_base;

    -- as MOD-030's loads leave the list and dimension once Gulf's regions are GCC
    INSERT INTO Layercake.silv_ref_country_region (id, country_ref_id, region_name, market_reporting_region, load_id, created_at)
    VALUES (1000002, 2, N'GCC', 'GCC', NULL, '2026-01-01');
    INSERT INTO Layercake.dim_country (id, country_id, country_name, region_name, market_reporting_region)
    VALUES (1000002, 'C0000000-0000-0000-0000-000000000002', N'United Arab Emirates', N'GCC', 'GCC');
    UPDATE Layercake.silv_ref_local_group
    SET region_name = N'GCC', market_reporting_region = 'GCC', dim_country_id = 1000002
    WHERE id = 1;

    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000002';
    EXEC test_MOD032.[Copy MOD-032 tables];

    SELECT * INTO #events_after FROM Layercake.silv_membership_events;
    SELECT * INTO #annual_after FROM Layercake.silv_annual_rate_base;
    EXEC tSQLt.AssertEqualsTable '#events_before', '#events_after', 'silver events unchanged';
    EXEC tSQLt.AssertEqualsTable '#annual_before', '#annual_after', 'silver annual rate base unchanged';

    SELECT s.event_nk, f.local_group_id, dc.region_name, dc.market_reporting_region, oc.region_name AS contact_region_name
    INTO #ActualGold
    FROM #fev AS f
    LEFT JOIN #ev AS s ON s.event_id = f.event_id
    LEFT JOIN Layercake.dim_country AS dc ON dc.id = f.country_id
    LEFT JOIN Layercake.dim_country AS oc ON oc.id = f.contact_country_id;
    SELECT v.event_nk, v.local_group_id, v.region_name, v.market_reporting_region, v.contact_region_name INTO #ExpectedGold
    FROM (VALUES (N'JR:G1', 1, N'GCC', 'GCC', N'UK&I'), (N'RN:G1:2021', 1, N'GCC', 'GCC', N'UK&I'),
                 (N'RN:G1:2025', 1, N'GCC', 'GCC', N'UK&I'),
                 (N'JR:G2', 3, N'MEA', 'MEA', N'APAC'), (N'RN:G2:2025', 3, N'MEA', 'MEA', N'APAC'),
                 (N'JR:N1', 0, N'APAC', 'APAC', N'APAC'), (N'RN:N1:2025', 0, N'APAC', 'APAC', N'APAC'))
        AS v(event_nk, local_group_id, region_name, market_reporting_region, contact_region_name);
    EXEC tSQLt.AssertEqualsTable '#ExpectedGold', '#ActualGold', 'gold events';

    SELECT f.campaign_year, f.local_group_id, dc.region_name, dc.market_reporting_region, oc.region_name AS contact_region_name
    INTO #ActualGoldAnnual
    FROM #far AS f
    LEFT JOIN Layercake.dim_country AS dc ON dc.id = f.country_id
    LEFT JOIN Layercake.dim_country AS oc ON oc.id = f.contact_country_id
    WHERE f.campaign_year IN (2021, 2025);
    SELECT v.campaign_year, v.local_group_id, v.region_name, v.market_reporting_region, v.contact_region_name INTO #ExpectedGoldAnnual
    FROM (VALUES (2021, 1, N'GCC', 'GCC', N'UK&I'), (2021, 3, N'MEA', 'MEA', N'APAC'), (2021, 0, N'APAC', 'APAC', N'APAC'),
                 (2025, 1, N'GCC', 'GCC', N'UK&I'), (2025, 3, N'MEA', 'MEA', N'APAC'), (2025, 0, N'APAC', 'APAC', N'APAC'))
        AS v(campaign_year, local_group_id, region_name, market_reporting_region, contact_region_name);
    EXEC tSQLt.AssertEqualsTable '#ExpectedGoldAnnual', '#ActualGoldAnnual', 'gold annual rate base';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-013 a change of local group alone or of own country alone updates the events in place]
AS
BEGIN
    CREATE TABLE #ev (event_id int NULL, event_nk nvarchar(220) COLLATE DATABASE_DEFAULT NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, source_enr_id uniqueidentifier NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #fev (event_id int NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, date_id int NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #ar (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);
    CREATE TABLE #far (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);

    INSERT INTO Layercake.silv_member_base
        (contact_id, contact_no, enrolment_date, election_date, is_rpq, election_enr_id,
         enrolment_from_exception, election_from_exception, recorded_enrolment_date, enrolment_from_subs_history,
         recorded_election_date, election_from_subs_history, contact_lapsed_date, lapsed_date,
         lapse_reason_id, lapse_reason_name, retirement_date, source_enr_id, rpq_variant_id,
         country_id, gender_id, local_group_id, contact_country_id)
    VALUES ('B0000000-0000-0000-0000-000000000004', N'L1', NULL, '2015-01-01', 0, NULL, 0, 0, NULL, 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, 1, 1, 2, 1);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'L1', 2025, '2024-11-10', '2024-11-10', N'Fully Paid');

    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    SELECT e.event_nk, e.event_id INTO #ids_before FROM Layercake.silv_membership_events AS e;
    SELECT f.event_id INTO #fact_ids_before FROM Layercake.fact_membership_events AS f;

    -- L1 leaves London (only local_group_id changes); G1's own country becomes India (only contact_country_id changes)
    UPDATE Layercake.silv_member_base SET local_group_id = 0 WHERE contact_no = N'L1';
    UPDATE Layercake.silv_member_base SET contact_country_id = 3 WHERE contact_no = N'G1';
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000002';
    EXEC test_MOD032.[Copy MOD-032 tables];

    SELECT e.event_nk, e.event_id INTO #ids_after FROM Layercake.silv_membership_events AS e;
    SELECT f.event_id INTO #fact_ids_after FROM Layercake.fact_membership_events AS f;
    EXEC tSQLt.AssertEqualsTable '#ids_before', '#ids_after', 'silver event_nk and event_id unchanged';
    EXEC tSQLt.AssertEqualsTable '#fact_ids_before', '#fact_ids_after', 'gold event_id unchanged';

    SELECT e.event_nk, e.country_id, e.local_group_id, e.contact_country_id INTO #Actual
    FROM #ev AS e WHERE e.contact_no IN (N'G1', N'L1');
    SELECT v.event_nk, v.country_id, v.local_group_id, v.contact_country_id INTO #Expected
    FROM (VALUES (N'JR:G1', 2, 1, 3), (N'RN:G1:2021', 2, 1, 3), (N'RN:G1:2025', 2, 1, 3),
                 (N'JR:L1', 1, 0, 1), (N'RN:L1:2025', 1, 0, 1))
        AS v(event_nk, country_id, local_group_id, contact_country_id);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'silver events';

    SELECT s.event_nk, f.local_group_id, dc.region_name, oc.region_name AS contact_region_name
    INTO #ActualGold
    FROM #fev AS f
    LEFT JOIN #ev AS s ON s.event_id = f.event_id
    LEFT JOIN Layercake.dim_country AS dc ON dc.id = f.country_id
    LEFT JOIN Layercake.dim_country AS oc ON oc.id = f.contact_country_id
    WHERE f.contact_no IN (N'G1', N'L1');
    SELECT v.event_nk, v.local_group_id, v.region_name, v.contact_region_name INTO #ExpectedGold
    FROM (VALUES (N'JR:G1', 1, N'MEA', N'APAC'), (N'RN:G1:2021', 1, N'MEA', N'APAC'), (N'RN:G1:2025', 1, N'MEA', N'APAC'),
                 (N'JR:L1', 0, N'UK&I', N'UK&I'), (N'RN:L1:2025', 0, N'UK&I', N'UK&I'))
        AS v(event_nk, local_group_id, region_name, contact_region_name);
    EXEC tSQLt.AssertEqualsTable '#ExpectedGold', '#ActualGold', 'gold events';

    SELECT a.campaign_year, a.grade_id, a.membership_status_id, a.country_id, a.gender_id, a.local_group_id, a.contact_country_id,
           a.members_start, a.members_end, a.members_joined, a.members_readmitted, a.members_lapsed, a.members_renewed
    INTO #ActualAnnual
    FROM #ar AS a
    WHERE a.campaign_year = 2025;
    SELECT v.campaign_year, v.grade_id, v.membership_status_id, v.country_id, v.gender_id, v.local_group_id, v.contact_country_id,
           v.members_start, v.members_end, v.members_joined, v.members_readmitted, v.members_lapsed, v.members_renewed
    INTO #ExpectedAnnual
    FROM (VALUES (2025, 2, 1, 2, 1, 1, 3, 1, 1, 0, 0, 0, 1),
                 (2025, 2, 1, 3, 1, 3, 3, 1, 1, 0, 0, 0, 1),
                 (2025, 2, 1, 3, 1, 0, 3, 1, 1, 0, 0, 0, 1),
                 (2025, 2, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 1))
        AS v(campaign_year, grade_id, membership_status_id, country_id, gender_id, local_group_id, contact_country_id,
             members_start, members_end, members_joined, members_readmitted, members_lapsed, members_renewed);
    EXEC tSQLt.AssertEqualsTable '#ExpectedAnnual', '#ActualAnnual', 'silver annual rate base 2025';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-014 a rerun on unchanged data changes no event or annual row and logs 0 0 0]
AS
BEGIN
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    SELECT * INTO #events_before FROM Layercake.silv_membership_events;
    SELECT * INTO #fact_events_before FROM Layercake.fact_membership_events;
    SELECT * INTO #annual_before FROM Layercake.silv_annual_rate_base;
    SELECT * INTO #fact_annual_before FROM Layercake.fact_annual_rate_base;

    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000002';

    SELECT * INTO #events_after FROM Layercake.silv_membership_events;
    SELECT * INTO #fact_events_after FROM Layercake.fact_membership_events;
    SELECT * INTO #annual_after FROM Layercake.silv_annual_rate_base;
    SELECT * INTO #fact_annual_after FROM Layercake.fact_annual_rate_base;
    EXEC tSQLt.AssertEqualsTable '#events_before', '#events_after', 'silv_membership_events';
    EXEC tSQLt.AssertEqualsTable '#fact_events_before', '#fact_events_after', 'fact_membership_events';
    EXEC tSQLt.AssertEqualsTable '#annual_before', '#annual_after', 'silv_annual_rate_base';
    EXEC tSQLt.AssertEqualsTable '#fact_annual_before', '#fact_annual_after', 'fact_annual_rate_base';

    DECLARE @steps int = (SELECT COUNT(*) FROM Layercake.etl_run_log WHERE run_id = 'E0000000-0000-0000-0000-000000000002');
    DECLARE @changed int =
        (SELECT COUNT(*) FROM Layercake.etl_run_log
         WHERE run_id = 'E0000000-0000-0000-0000-000000000002'
           AND (status <> 'Success' OR ISNULL(rows_inserted, 0) <> 0 OR ISNULL(rows_updated, 0) <> 0 OR ISNULL(rows_deleted, 0) <> 0));
    EXEC tSQLt.AssertEquals 4, @steps, 'four steps logged by the rerun';
    EXEC tSQLt.AssertEquals 0, @changed, 'every rerun step logs Success with 0, 0, 0';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-015 daily count totals not split by region country or local group are the same before and after the change]
AS
BEGIN
    EXEC test_MOD032.[Arrange daily count];
    EXEC test_MOD032.[Use own country basis];
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    EXEC test_MOD032.[Run daily count] @run_id = 'E0000000-0000-0000-0000-000000000001';

    SELECT d.[date], d.grade,
           SUM(d.active_count) AS active_count, SUM(d.paid_count) AS paid_count, SUM(d.paid_count_event) AS paid_count_event,
           SUM(d.event_join_count) AS event_join_count, SUM(d.event_renewal_count) AS event_renewal_count,
           SUM(d.event_readmission_count) AS event_readmission_count, SUM(d.event_lapse_count) AS event_lapse_count
    INTO #before_daily
    FROM Layercake.silv_daily_count AS d
    GROUP BY d.[date], d.grade;
    SELECT d.[date], d.gender_id, d.grade, d.membership_status_id, d.payment_method_id, d.payer_type_id, d.concession_type_id,
           SUM(d.active_count) AS active_count, SUM(d.paid_count) AS paid_count, SUM(d.paid_count_event) AS paid_count_event,
           SUM(d.event_join_count) AS event_join_count, SUM(d.event_renewal_count) AS event_renewal_count,
           SUM(d.event_readmission_count) AS event_readmission_count, SUM(d.event_lapse_count) AS event_lapse_count
    INTO #before_detail
    FROM Layercake.silv_daily_count_detail AS d
    GROUP BY d.[date], d.gender_id, d.grade, d.membership_status_id, d.payment_method_id, d.payer_type_id, d.concession_type_id;
    SELECT f.date_id, f.gender_id, f.membership_grade_id, f.membership_status_id, f.payment_method_id, f.payer_type_id, f.concession_type_id,
           SUM(f.ActiveMembers) AS active_members, SUM(f.PaidMembers) AS paid_members, SUM(f.PaidMembersEvent) AS paid_members_event,
           SUM(f.JoinEvents) AS join_events, SUM(f.RenewalEvents) AS renewal_events,
           SUM(f.ReadmissionEvents) AS readmission_events, SUM(f.LapseEvents) AS lapse_events
    INTO #before_fact
    FROM Layercake.fact_daily_member_count_detail AS f
    GROUP BY f.date_id, f.gender_id, f.membership_grade_id, f.membership_status_id, f.payment_method_id, f.payer_type_id, f.concession_type_id;
    SELECT d.[date], d.region, SUM(d.active_count) AS active_count
    INTO #ActualBeforeRegion
    FROM Layercake.silv_daily_count AS d
    GROUP BY d.[date], d.region;

    EXEC test_MOD032.[Use local group basis];
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000002';
    EXEC test_MOD032.[Run daily count] @run_id = 'E0000000-0000-0000-0000-000000000002';

    SELECT d.[date], d.grade,
           SUM(d.active_count) AS active_count, SUM(d.paid_count) AS paid_count, SUM(d.paid_count_event) AS paid_count_event,
           SUM(d.event_join_count) AS event_join_count, SUM(d.event_renewal_count) AS event_renewal_count,
           SUM(d.event_readmission_count) AS event_readmission_count, SUM(d.event_lapse_count) AS event_lapse_count
    INTO #after_daily
    FROM Layercake.silv_daily_count AS d
    GROUP BY d.[date], d.grade;
    SELECT d.[date], d.gender_id, d.grade, d.membership_status_id, d.payment_method_id, d.payer_type_id, d.concession_type_id,
           SUM(d.active_count) AS active_count, SUM(d.paid_count) AS paid_count, SUM(d.paid_count_event) AS paid_count_event,
           SUM(d.event_join_count) AS event_join_count, SUM(d.event_renewal_count) AS event_renewal_count,
           SUM(d.event_readmission_count) AS event_readmission_count, SUM(d.event_lapse_count) AS event_lapse_count
    INTO #after_detail
    FROM Layercake.silv_daily_count_detail AS d
    GROUP BY d.[date], d.gender_id, d.grade, d.membership_status_id, d.payment_method_id, d.payer_type_id, d.concession_type_id;
    SELECT f.date_id, f.gender_id, f.membership_grade_id, f.membership_status_id, f.payment_method_id, f.payer_type_id, f.concession_type_id,
           SUM(f.ActiveMembers) AS active_members, SUM(f.PaidMembers) AS paid_members, SUM(f.PaidMembersEvent) AS paid_members_event,
           SUM(f.JoinEvents) AS join_events, SUM(f.RenewalEvents) AS renewal_events,
           SUM(f.ReadmissionEvents) AS readmission_events, SUM(f.LapseEvents) AS lapse_events
    INTO #after_fact
    FROM Layercake.fact_daily_member_count_detail AS f
    GROUP BY f.date_id, f.gender_id, f.membership_grade_id, f.membership_status_id, f.payment_method_id, f.payer_type_id, f.concession_type_id;
    SELECT d.[date], d.region, SUM(d.active_count) AS active_count
    INTO #ActualAfterRegion
    FROM Layercake.silv_daily_count AS d
    GROUP BY d.[date], d.region;

    EXEC tSQLt.AssertEqualsTable '#before_daily', '#after_daily', 'silv_daily_count summed over region';
    EXEC tSQLt.AssertEqualsTable '#before_detail', '#after_detail', 'silv_daily_count_detail summed over the region and country columns';
    EXEC tSQLt.AssertEqualsTable '#before_fact', '#after_fact', 'fact_daily_member_count_detail summed over the country and local group columns';

    SELECT d.[date], d.grade, d.active_count INTO #ActualTotals FROM #after_daily AS d;
    SELECT v.[date], v.grade, v.active_count INTO #ExpectedTotals
    FROM (VALUES (CAST('2020-10-01' AS date), 'election', 3), (CAST('2025-01-10' AS date), 'election', 3))
        AS v([date], grade, active_count);
    EXEC tSQLt.AssertEqualsTable '#ExpectedTotals', '#ActualTotals', 'active members by date';

    SELECT v.[date], v.region, v.active_count INTO #ExpectedBeforeRegion
    FROM (VALUES (CAST('2020-10-01' AS date), 'UK&I', 1), (CAST('2020-10-01' AS date), 'APAC', 2),
                 (CAST('2025-01-10' AS date), 'UK&I', 1), (CAST('2025-01-10' AS date), 'APAC', 2))
        AS v([date], region, active_count);
    EXEC tSQLt.AssertEqualsTable '#ExpectedBeforeRegion', '#ActualBeforeRegion', 'regions before';
    SELECT v.[date], v.region, v.active_count INTO #ExpectedAfterRegion
    FROM (VALUES (CAST('2020-10-01' AS date), 'MEA', 2), (CAST('2020-10-01' AS date), 'APAC', 1),
                 (CAST('2025-01-10' AS date), 'MEA', 2), (CAST('2025-01-10' AS date), 'APAC', 1))
        AS v([date], region, active_count);
    EXEC tSQLt.AssertEqualsTable '#ExpectedAfterRegion', '#ActualAfterRegion', 'regions after';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-016 daily count detail by own country equals the detail before the change by country]
AS
BEGIN
    EXEC test_MOD032.[Arrange daily count];
    EXEC test_MOD032.[Use own country basis];
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    EXEC test_MOD032.[Run daily count] @run_id = 'E0000000-0000-0000-0000-000000000001';

    SELECT d.[date], d.country_id, d.region, d.gender_id, d.grade, d.membership_status_id,
           d.payment_method_id, d.payer_type_id, d.concession_type_id,
           SUM(d.active_count) AS active_count, SUM(d.paid_count) AS paid_count, SUM(d.paid_count_event) AS paid_count_event,
           SUM(d.event_join_count) AS event_join_count, SUM(d.event_renewal_count) AS event_renewal_count,
           SUM(d.event_readmission_count) AS event_readmission_count, SUM(d.event_lapse_count) AS event_lapse_count
    INTO #before_detail
    FROM Layercake.silv_daily_count_detail AS d
    GROUP BY d.[date], d.country_id, d.region, d.gender_id, d.grade, d.membership_status_id,
             d.payment_method_id, d.payer_type_id, d.concession_type_id;

    EXEC test_MOD032.[Use local group basis];
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000002';
    EXEC test_MOD032.[Run daily count] @run_id = 'E0000000-0000-0000-0000-000000000002';

    SELECT d.[date], d.contact_country_id AS country_id, d.contact_region AS region, d.gender_id, d.grade, d.membership_status_id,
           d.payment_method_id, d.payer_type_id, d.concession_type_id,
           SUM(d.active_count) AS active_count, SUM(d.paid_count) AS paid_count, SUM(d.paid_count_event) AS paid_count_event,
           SUM(d.event_join_count) AS event_join_count, SUM(d.event_renewal_count) AS event_renewal_count,
           SUM(d.event_readmission_count) AS event_readmission_count, SUM(d.event_lapse_count) AS event_lapse_count
    INTO #after_detail
    FROM Layercake.silv_daily_count_detail AS d
    GROUP BY d.[date], d.contact_country_id, d.contact_region, d.gender_id, d.grade, d.membership_status_id,
             d.payment_method_id, d.payer_type_id, d.concession_type_id;

    EXEC tSQLt.AssertEqualsTable '#before_detail', '#after_detail';

    SELECT a.[date], a.country_id, a.region, a.active_count INTO #Actual FROM #after_detail AS a;
    SELECT v.[date], v.country_id, v.region, v.active_count INTO #Expected
    FROM (VALUES (CAST('2020-10-01' AS date), 1, 'UK&I', 1), (CAST('2020-10-01' AS date), 3, 'APAC', 2),
                 (CAST('2025-01-10' AS date), 1, 'UK&I', 1), (CAST('2025-01-10' AS date), 3, 'APAC', 2))
        AS v([date], country_id, region, active_count);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-017 no table holds a null or -2 local group or own country and every id resolves]
AS
BEGIN
    CREATE TABLE #ev (event_id int NULL, event_nk nvarchar(220) COLLATE DATABASE_DEFAULT NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, source_enr_id uniqueidentifier NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #fev (event_id int NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, date_id int NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #ar (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);
    CREATE TABLE #far (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);

    EXEC test_MOD032.[Arrange daily count];
    -- an adjustment row written before deployment, as MOD-031's migration leaves it
    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         payment_method_id, payer_type_id, concession_type_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change,
         local_group_id, contact_country_id, contact_region)
    VALUES ('E0000000-0000-0000-0000-000000000099', 7, '2025-01-10 07:00', '2025-01-10', 'UK&I', 1, 1, 'election', 1,
            0, 0, 0, 1, 0, 0, 0, 0, 0, 0, -2, 1, 'UK&I');

    EXEC test_MOD032.[Use own country basis];
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    EXEC test_MOD032.[Run daily count] @run_id = 'E0000000-0000-0000-0000-000000000001';
    EXEC test_MOD032.[Use local group basis];
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000002';
    EXEC test_MOD032.[Run daily count] @run_id = 'E0000000-0000-0000-0000-000000000002';
    EXEC test_MOD032.[Copy MOD-032 tables];

    SELECT x.table_name, x.row_count
    INTO #ActualRows
    FROM (SELECT 'silv_member_base' AS table_name, CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END AS row_count FROM Layercake.silv_member_base
          UNION ALL SELECT 'silv_member_profile', CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM Layercake.silv_member_profile
          UNION ALL SELECT 'silv_membership_events', CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM #ev
          UNION ALL SELECT 'fact_membership_events', CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM #fev
          UNION ALL SELECT 'silv_annual_rate_base', CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM #ar
          UNION ALL SELECT 'fact_annual_rate_base', CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM #far
          UNION ALL SELECT 'silv_daily_count_detail', CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM Layercake.silv_daily_count_detail
          UNION ALL SELECT 'fact_daily_member_count_detail', CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM Layercake.fact_daily_member_count_detail
          UNION ALL SELECT 'etl_daily_count_cell_contacts', CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM Layercake.etl_daily_count_cell_contacts
          UNION ALL SELECT 'silv_daily_count_adjustment', CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM Layercake.silv_daily_count_adjustment) AS x;
    SELECT v.table_name, v.row_count INTO #ExpectedRows
    FROM (VALUES ('silv_member_base', 1), ('silv_member_profile', 1), ('silv_membership_events', 1), ('fact_membership_events', 1),
                 ('silv_annual_rate_base', 1), ('fact_annual_rate_base', 1), ('silv_daily_count_detail', 1),
                 ('fact_daily_member_count_detail', 1), ('etl_daily_count_cell_contacts', 1), ('silv_daily_count_adjustment', 1))
        AS v(table_name, row_count);
    EXEC tSQLt.AssertEqualsTable '#ExpectedRows', '#ActualRows', 'every checked table holds rows';

    SELECT x.table_name, x.local_group_id, x.contact_country_id
    INTO #bad
    FROM (SELECT 'silv_member_base' AS table_name, local_group_id, contact_country_id FROM Layercake.silv_member_base
          UNION ALL SELECT 'silv_member_profile', local_group_id, contact_country_id FROM Layercake.silv_member_profile
          UNION ALL SELECT 'silv_membership_events', local_group_id, contact_country_id FROM #ev
          UNION ALL SELECT 'fact_membership_events', local_group_id, contact_country_id FROM #fev
          UNION ALL SELECT 'silv_annual_rate_base', local_group_id, contact_country_id FROM #ar
          UNION ALL SELECT 'fact_annual_rate_base', local_group_id, contact_country_id FROM #far
          UNION ALL SELECT 'silv_daily_count_detail', local_group_id, contact_country_id FROM Layercake.silv_daily_count_detail
          UNION ALL SELECT 'fact_daily_member_count_detail', local_group_id, contact_country_id FROM Layercake.fact_daily_member_count_detail
          UNION ALL SELECT 'etl_daily_count_cell_contacts', local_group_id, contact_country_id FROM Layercake.etl_daily_count_cell_contacts) AS x
    WHERE x.local_group_id IS NULL OR x.contact_country_id IS NULL OR x.local_group_id = -2;
    EXEC tSQLt.AssertEmptyTable '#bad', 'null or -2 local group or own country';

    SELECT x.table_name, x.local_group_id
    INTO #orphans
    FROM (SELECT 'silv_member_base' AS table_name, t.local_group_id FROM Layercake.silv_member_base AS t
              WHERE NOT EXISTS (SELECT 1 FROM Layercake.silv_ref_local_group AS r WHERE r.id = t.local_group_id)
          UNION ALL SELECT 'silv_member_profile', t.local_group_id FROM Layercake.silv_member_profile AS t
              WHERE NOT EXISTS (SELECT 1 FROM Layercake.silv_ref_local_group AS r WHERE r.id = t.local_group_id)
          UNION ALL SELECT 'silv_membership_events', t.local_group_id FROM #ev AS t
              WHERE NOT EXISTS (SELECT 1 FROM Layercake.silv_ref_local_group AS r WHERE r.id = t.local_group_id)
          UNION ALL SELECT 'silv_annual_rate_base', t.local_group_id FROM #ar AS t
              WHERE NOT EXISTS (SELECT 1 FROM Layercake.silv_ref_local_group AS r WHERE r.id = t.local_group_id)
          UNION ALL SELECT 'silv_daily_count_detail', t.local_group_id FROM Layercake.silv_daily_count_detail AS t
              WHERE NOT EXISTS (SELECT 1 FROM Layercake.silv_ref_local_group AS r WHERE r.id = t.local_group_id)
          UNION ALL SELECT 'etl_daily_count_cell_contacts', t.local_group_id FROM Layercake.etl_daily_count_cell_contacts AS t
              WHERE NOT EXISTS (SELECT 1 FROM Layercake.silv_ref_local_group AS r WHERE r.id = t.local_group_id)
          UNION ALL SELECT 'silv_daily_count_adjustment', t.local_group_id FROM Layercake.silv_daily_count_adjustment AS t
              WHERE NOT EXISTS (SELECT 1 FROM Layercake.silv_ref_local_group AS r WHERE r.id = t.local_group_id)
          UNION ALL SELECT 'fact_membership_events', t.local_group_id FROM #fev AS t
              WHERE NOT EXISTS (SELECT 1 FROM Layercake.dim_local_group AS r WHERE r.id = t.local_group_id)
          UNION ALL SELECT 'fact_annual_rate_base', t.local_group_id FROM #far AS t
              WHERE NOT EXISTS (SELECT 1 FROM Layercake.dim_local_group AS r WHERE r.id = t.local_group_id)
          UNION ALL SELECT 'fact_daily_member_count_detail', t.local_group_id FROM Layercake.fact_daily_member_count_detail AS t
              WHERE NOT EXISTS (SELECT 1 FROM Layercake.dim_local_group AS r WHERE r.id = t.local_group_id)) AS x;
    EXEC tSQLt.AssertEmptyTable '#orphans', 'local_group_id that does not resolve';

    SELECT x.table_name, x.contact_country_id
    INTO #country_orphans
    FROM (SELECT 'fact_membership_events' AS table_name, t.contact_country_id FROM #fev AS t
              WHERE NOT EXISTS (SELECT 1 FROM Layercake.dim_country AS c WHERE c.id = t.contact_country_id)
          UNION ALL SELECT 'fact_annual_rate_base', t.contact_country_id FROM #far AS t
              WHERE NOT EXISTS (SELECT 1 FROM Layercake.dim_country AS c WHERE c.id = t.contact_country_id)
          UNION ALL SELECT 'fact_daily_member_count_detail', t.contact_country_id FROM Layercake.fact_daily_member_count_detail AS t
              WHERE NOT EXISTS (SELECT 1 FROM Layercake.dim_country AS c WHERE c.id = t.contact_country_id)) AS x;
    EXEC tSQLt.AssertEmptyTable '#country_orphans', 'gold contact_country_id that does not resolve';

    SELECT DISTINCT a.local_group_id INTO #ActualAdjGroups FROM Layercake.silv_daily_count_adjustment AS a;
    SELECT v.local_group_id INTO #ExpectedAdjGroups FROM (VALUES (-2), (0), (1), (3)) AS v(local_group_id);
    EXEC tSQLt.AssertEqualsTable '#ExpectedAdjGroups', '#ActualAdjGroups', 'local groups in the adjustment history';

    SELECT a.run_id, n.local_group_name
    INTO #ActualNotApplicable
    FROM Layercake.silv_daily_count_adjustment AS a
    LEFT JOIN Layercake.silv_ref_local_group AS n ON n.id = a.local_group_id
    WHERE a.local_group_id = -2;
    SELECT CAST(v.run_id AS uniqueidentifier) AS run_id, v.local_group_name INTO #ExpectedNotApplicable
    FROM (VALUES ('E0000000-0000-0000-0000-000000000099', N'Not applicable')) AS v(run_id, local_group_name);
    EXEC tSQLt.AssertEqualsTable '#ExpectedNotApplicable', '#ActualNotApplicable', '-2 only on the pre-deployment row';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-018 gold events annual rate base and daily star reconcile to silver under the gold country by local group rule]
AS
BEGIN
    CREATE TABLE #ev (event_id int NULL, event_nk nvarchar(220) COLLATE DATABASE_DEFAULT NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, source_enr_id uniqueidentifier NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #fev (event_id int NULL, event_type varchar(20) COLLATE DATABASE_DEFAULT NULL, event_subtype varchar(20) COLLATE DATABASE_DEFAULT NULL, event_date date NULL, date_id int NULL, contact_no nvarchar(200) COLLATE DATABASE_DEFAULT NULL, grade_id int NULL, assessment_route_id int NULL, rpq_variant_id int NULL, hpb_id int NULL, country_id int NULL, gender_id int NULL, membership_status_id int NULL, campaign_year int NULL, campaign_quarter char(2) COLLATE DATABASE_DEFAULT NULL, local_group_id int NULL, contact_country_id int NULL);
    CREATE TABLE #ar (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);
    CREATE TABLE #far (campaign_year int NULL, grade_id int NULL, membership_status_id int NULL, country_id int NULL, gender_id int NULL, local_group_id int NULL, contact_country_id int NULL, members_start int NULL, members_end int NULL, members_joined int NULL, members_readmitted int NULL, members_lapsed int NULL, members_renewed int NULL);

    EXEC test_MOD032.[Arrange daily count];
    EXEC test_MOD032.[Run event and annual loads] @run_id = 'E0000000-0000-0000-0000-000000000001';
    EXEC test_MOD032.[Run daily count] @run_id = 'E0000000-0000-0000-0000-000000000001';
    EXEC test_MOD032.[Copy MOD-032 tables];

    -- expected gold country: the group's dim_country_id for a reportable group, else the silver country
    SELECT s.event_id,
           CASE WHEN lg.is_reportable = 1 THEN lg.dim_country_id ELSE s.country_id END AS country_id,
           s.local_group_id, s.contact_country_id, s.gender_id, s.grade_id, s.membership_status_id, s.campaign_year
    INTO #expected_events
    FROM #ev AS s
    LEFT JOIN Layercake.silv_ref_local_group AS lg ON lg.id = s.local_group_id;
    SELECT f.event_id, f.country_id, f.local_group_id, f.contact_country_id, f.gender_id, f.grade_id, f.membership_status_id, f.campaign_year
    INTO #gold_events
    FROM #fev AS f;
    EXEC tSQLt.AssertEqualsTable '#expected_events', '#gold_events', 'events';

    SELECT a.campaign_year, a.grade_id, a.membership_status_id,
           CASE WHEN lg.is_reportable = 1 THEN lg.dim_country_id ELSE a.country_id END AS country_id,
           a.gender_id, a.local_group_id, a.contact_country_id,
           a.members_start, a.members_end, a.members_joined, a.members_readmitted, a.members_lapsed, a.members_renewed
    INTO #expected_annual
    FROM #ar AS a
    LEFT JOIN Layercake.silv_ref_local_group AS lg ON lg.id = a.local_group_id;
    SELECT f.campaign_year, f.grade_id, f.membership_status_id, f.country_id, f.gender_id, f.local_group_id, f.contact_country_id,
           f.members_start, f.members_end, f.members_joined, f.members_readmitted, f.members_lapsed, f.members_renewed
    INTO #gold_annual
    FROM #far AS f;
    EXEC tSQLt.AssertEqualsTable '#expected_annual', '#gold_annual', 'annual rate base';

    SELECT dd.id AS date_id,
           CASE WHEN lg.is_reportable = 1 THEN lg.dim_country_id ELSE d.country_id END AS country_id,
           d.gender_id, d.membership_status_id, d.payment_method_id, d.payer_type_id, d.concession_type_id,
           d.local_group_id, d.contact_country_id,
           SUM(d.active_count) AS active_members, SUM(d.paid_count) AS paid_members, SUM(d.paid_count_event) AS paid_members_event,
           SUM(d.event_join_count) AS join_events, SUM(d.event_renewal_count) AS renewal_events,
           SUM(d.event_readmission_count) AS readmission_events, SUM(d.event_lapse_count) AS lapse_events
    INTO #expected_star
    FROM Layercake.silv_daily_count_detail AS d
    INNER JOIN Layercake.dim_date AS dd ON dd.[date] = d.[date]
    LEFT JOIN Layercake.silv_ref_local_group AS lg ON lg.id = d.local_group_id
    GROUP BY dd.id, CASE WHEN lg.is_reportable = 1 THEN lg.dim_country_id ELSE d.country_id END,
             d.gender_id, d.membership_status_id, d.payment_method_id, d.payer_type_id, d.concession_type_id,
             d.local_group_id, d.contact_country_id;
    SELECT f.date_id, f.country_id, f.gender_id, f.membership_status_id, f.payment_method_id, f.payer_type_id, f.concession_type_id,
           f.local_group_id, f.contact_country_id,
           SUM(f.ActiveMembers) AS active_members, SUM(f.PaidMembers) AS paid_members, SUM(f.PaidMembersEvent) AS paid_members_event,
           SUM(f.JoinEvents) AS join_events, SUM(f.RenewalEvents) AS renewal_events,
           SUM(f.ReadmissionEvents) AS readmission_events, SUM(f.LapseEvents) AS lapse_events
    INTO #gold_star
    FROM Layercake.fact_daily_member_count_detail AS f
    GROUP BY f.date_id, f.country_id, f.gender_id, f.membership_status_id, f.payment_method_id, f.payer_type_id, f.concession_type_id,
             f.local_group_id, f.contact_country_id;
    EXEC tSQLt.AssertEqualsTable '#expected_star', '#gold_star', 'daily star (check D2)';

    DECLARE @events int = (SELECT COUNT(*) FROM #gold_events);
    DECLARE @star int = (SELECT COUNT(*) FROM Layercake.fact_daily_member_count_detail);
    EXEC tSQLt.AssertEquals 7, @events, 'gold events';
    EXEC tSQLt.AssertEquals 6, @star, 'gold daily cells: three per loaded date';
END;
GO

CREATE PROCEDURE test_MOD032.[test TC-032-019 the objects and columns the handover pack describes exist]
AS
BEGIN
    SELECT v.object_name, v.column_name,
           CASE WHEN v.column_name IS NULL THEN CASE WHEN OBJECT_ID(v.object_name) IS NOT NULL THEN 1 ELSE 0 END
                ELSE CASE WHEN COL_LENGTH(v.object_name, v.column_name) IS NOT NULL THEN 1 ELSE 0 END END AS present
    INTO #Actual
    FROM (VALUES
        (N'Layercake.silv_ref_local_group', NULL),
        (N'Layercake.dim_local_group', NULL),
        (N'Layercake.silv_member_base', N'local_group_id'),
        (N'Layercake.silv_member_base', N'contact_country_id'),
        (N'Layercake.silv_membership_events', N'local_group_id'),
        (N'Layercake.silv_membership_events', N'contact_country_id'),
        (N'Layercake.fact_membership_events', N'local_group_id'),
        (N'Layercake.fact_membership_events', N'contact_country_id'),
        (N'Layercake.silv_annual_rate_base', N'local_group_id'),
        (N'Layercake.silv_annual_rate_base', N'contact_country_id'),
        (N'Layercake.fact_annual_rate_base', N'local_group_id'),
        (N'Layercake.fact_annual_rate_base', N'contact_country_id'),
        (N'Layercake.silv_daily_count_detail', N'contact_region'),
        (N'Layercake.fact_daily_member_count_detail', N'local_group_id'),
        (N'Layercake.fact_daily_member_count_detail', N'contact_country_id')
    ) AS v(object_name, column_name);

    SELECT a.object_name, a.column_name, 1 AS present
    INTO #Expected
    FROM #Actual AS a;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
