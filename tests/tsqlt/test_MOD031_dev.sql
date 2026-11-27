EXEC tSQLt.NewTestClass 'test_MOD031_dev';
GO

CREATE PROCEDURE test_MOD031_dev.[SetUp]
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

    -- row 0 is the Phase 1 'N/A' country a member with no known own country gets
    INSERT INTO Layercake.silv_ref_country (id, country_id, country_name, region_name, market_reporting_region)
    VALUES (0, NULL, N'N/A', N'N/A', 'N/A'),
           (1, 'C0000000-0000-0000-0000-000000000001', N'United Kingdom', N'UK&I', 'UK&I'),
           (2, 'C0000000-0000-0000-0000-000000000002', N'United Arab Emirates', N'MEA', 'MEA'),
           (3, 'C0000000-0000-0000-0000-000000000003', N'India', N'APAC', 'APAC');

    INSERT INTO Layercake.silv_ref_local_group
        (id, local_group_bk, local_group_name, local_group_code, country_id, region_name, market_reporting_region,
         statecode, is_reportable, dim_country_id, load_id, created_at, updated_at)
    VALUES (-2, NULL, N'Not applicable', NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-01-01', '2026-01-01'),
           (0, NULL, N'Unknown', NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-01-01', '2026-01-01'),
           (1, 'A0000000-0000-0000-0000-000000000001', N'Gulf', N'GULF', 2, N'MEA', 'MEA', 0, 1, 2, 1, '2026-01-01', '2026-01-01'),
           (2, 'A0000000-0000-0000-0000-000000000002', N'London', N'LON', 1, N'UK&I', 'UK&I', 0, 1, 1, 1, '2026-01-01', '2026-01-01'),
           (3, 'A0000000-0000-0000-0000-000000000003', N'Gulf India', N'GIND', 3, N'MEA', 'MEA', 0, 1, 1000001, 1, '2026-01-01', '2026-01-01'),
           (6, 'A0000000-0000-0000-0000-000000000006', N'Closed Gulf', N'CGULF', 2, N'MEA', 'MEA', 1, 0, NULL, 1, '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.silv_ref_gender (id, gender_code, gender_name) VALUES (1, 1, 'Male');
    INSERT INTO Layercake.silv_ref_membership_grade (id, grade_name) VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');
    INSERT INTO Layercake.dim_membership_grade (id, grade_name) VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');
    INSERT INTO Layercake.silv_ref_membership_status (id, status_name) VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2025, '2024-10-01', '2025-09-30', '2025-09-30');

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES ('2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter) VALUES (1, '2025-01-10', 2025, 'Q2');
END;
GO

-- A member as the Phase 1 sources hold one: contact, rics record, a transaction and a Join (Direct
-- Entry) event on 2015-01-01 carrying @event_country_id, the country Phase 1 gives the event.
CREATE PROCEDURE test_MOD031_dev.[Add member]
    @contact_no nvarchar(100),
    @country_guid uniqueidentifier,
    @local_group_bk uniqueidentifier,
    @event_country_id int
AS
BEGIN
    DECLARE @contact_id uniqueidentifier = NEWID();
    DECLARE @recid bigint = (SELECT ISNULL(MAX(t.recid), 0) + 1 FROM Layercake.brnz_cust_trans AS t);

    INSERT INTO Layercake.brnz_contact
        (ContactId, Rics_contactno, GenderCode, rics_countryid, rics_localgroupid, StateCode, CreatedOn,
         _loaded_at, _updated_at, _is_deleted)
    VALUES (@contact_id, @contact_no, 1, @country_guid, @local_group_bk, 0, '2014-01-01', '2026-01-01', '2026-01-01', 0);

    INSERT INTO Layercake.brnz_rics_record
        (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_membergrade, statecode, ModifiedOn, _loaded_at, _updated_at, _is_deleted)
    VALUES (NEWID(), @contact_id, @contact_no, NULL, 0, '2020-01-01', '2026-01-01', '2026-01-01', 0);

    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, transdate, amountcur, approved, _loaded_at, _updated_at, _is_deleted)
    VALUES (@recid, @contact_no, '2015-01-01', 100, 1, '2026-01-01', '2026-01-01', 0);

    INSERT INTO Layercake.silv_membership_events
        (event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (N'JR:' + @contact_no, 'Join', 'Direct Entry', '2015-01-01', @contact_no, 2, 0, 0, 0,
            @event_country_id, 1, 1, 2015, 'Q2', -2, 0, -2, 0, -2, 0);
END;
GO

CREATE PROCEDURE test_MOD031_dev.[Run members]
    @run_id uniqueidentifier
AS
BEGIN
    EXEC Layercake.usp_load_silv_member_base @run_id = @run_id;
    EXEC Layercake.usp_load_silv_member_state_ranges @run_id = @run_id;
    EXEC Layercake.usp_load_silv_member_profile @run_id = @run_id;
END;
GO

CREATE PROCEDURE test_MOD031_dev.[test a member with no known own country gets N/K unless a usable group gives its region]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();

    -- Z1: no own country, no group; Z2: no own country, in Gulf; Z3: an own country CE has but
    -- silv_ref_country does not, in Gulf. Phase 1 gives all three events country 0.
    EXEC test_MOD031_dev.[Add member] N'Z1', NULL, NULL, 0;
    EXEC test_MOD031_dev.[Add member] N'Z2', NULL, 'A0000000-0000-0000-0000-000000000001', 0;
    EXEC test_MOD031_dev.[Add member] N'Z3', 'C0000000-0000-0000-0000-000000000099', 'A0000000-0000-0000-0000-000000000001', 0;

    EXEC test_MOD031_dev.[Run members] @run_id = @r1;

    SELECT v.contact_no, v.country_id, v.local_group_id, v.contact_country_id
    INTO #ExpectedBase
    FROM (VALUES (N'Z1', 0, 0, 0), (N'Z2', 2, 1, 0), (N'Z3', 2, 1, 0)) AS v (contact_no, country_id, local_group_id, contact_country_id);

    EXEC (N'SELECT contact_no, country_id, local_group_id, contact_country_id INTO #ActualBase FROM Layercake.silv_member_base;
EXEC tSQLt.AssertEqualsTable ''#ExpectedBase'', ''#ActualBase'', ''silv_member_base'';');

    SELECT v.contact_no, v.region, v.contact_region
    INTO #ExpectedRanges
    FROM (VALUES (N'Z1', 'N/K', 'N/K'), (N'Z2', 'MEA', 'N/K'), (N'Z3', 'MEA', 'N/K')) AS v (contact_no, region, contact_region);

    EXEC (N'SELECT contact_no, region, contact_region INTO #ActualRanges FROM Layercake.silv_member_state_ranges;
EXEC tSQLt.AssertEqualsTable ''#ExpectedRanges'', ''#ActualRanges'', ''silv_member_state_ranges'';');
END;
GO

CREATE PROCEDURE test_MOD031_dev.[test a contact with no live brnz_contact row keeps the Phase 1 region from its event]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();

    -- X9 has events but no live contact row (soft-deleted), so the view has no row for it
    EXEC test_MOD031_dev.[Add member] N'X9', 'C0000000-0000-0000-0000-000000000003', 'A0000000-0000-0000-0000-000000000001', 3;
    UPDATE Layercake.brnz_contact SET _is_deleted = 1 WHERE Rics_contactno = N'X9';

    EXEC Layercake.usp_load_silv_member_state_ranges @run_id = @r1;

    SELECT v.contact_no, v.region, v.contact_region
    INTO #ExpectedRanges
    FROM (VALUES (N'X9', 'APAC', 'APAC')) AS v (contact_no, region, contact_region);

    EXEC (N'SELECT contact_no, region, contact_region INTO #ActualRanges FROM Layercake.silv_member_state_ranges;
EXEC tSQLt.AssertEqualsTable ''#ExpectedRanges'', ''#ActualRanges'', ''silv_member_state_ranges'';');
END;
GO

CREATE PROCEDURE test_MOD031_dev.[test the profile load updates a row whose local group alone changed and logs it]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @ins int, @upd int, @del int;

    EXEC (N'INSERT INTO Layercake.silv_member_base (contact_id, contact_no, is_rpq, enrolment_from_exception, election_from_exception,
    enrolment_from_subs_history, election_from_subs_history, lapse_reason_id, rpq_variant_id, country_id, gender_id,
    local_group_id, contact_country_id)
VALUES (NEWID(), N''P1'', 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1);
INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date, local_group_id, contact_country_id)
VALUES (N''P1'', 1, 1, NULL, 2, 1);');

    EXEC Layercake.usp_load_silv_member_profile @run_id = @r1;

    SELECT @ins = l.rows_inserted, @upd = l.rows_updated, @del = l.rows_deleted
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @r1;
    EXEC tSQLt.AssertEquals 0, @ins, 'rows_inserted';
    EXEC tSQLt.AssertEquals 1, @upd, 'rows_updated';
    EXEC tSQLt.AssertEquals 0, @del, 'rows_deleted';

    SELECT v.contact_no, v.country_id, v.local_group_id, v.contact_country_id
    INTO #ExpectedProfile
    FROM (VALUES (N'P1', 1, 0, 1)) AS v (contact_no, country_id, local_group_id, contact_country_id);

    EXEC (N'SELECT contact_no, country_id, local_group_id, contact_country_id INTO #ActualProfile FROM Layercake.silv_member_profile;
EXEC tSQLt.AssertEqualsTable ''#ExpectedProfile'', ''#ActualProfile'', ''silv_member_profile'';');
END;
GO

CREATE PROCEDURE test_MOD031_dev.[test gold takes the silver country for a local group that is no longer reportable]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();

    -- Closed Gulf (6) is not reportable, so its row keeps silver country 2; Gulf India (3) is, so
    -- its row takes the list's dim_country_id 1000001
    EXEC (N'INSERT INTO Layercake.silv_daily_count_detail
    ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
     payment_method_id, payer_type_id, concession_type_id, local_group_id, contact_country_id, contact_region,
     active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
VALUES (''2025-01-10'', 2025, ''Q2'', ''MEA'', 2, 1, ''election'', 1, 0, 0, 0, 6, 1, ''UK&I'', 1, 0, 0, 0, 0, 0, 0),
       (''2025-01-10'', 2025, ''Q2'', ''MEA'', 3, 1, ''election'', 1, 0, 0, 0, 3, 3, ''APAC'', 1, 0, 0, 0, 0, 0, 0);');

    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    SELECT v.date_id, v.country_id, v.local_group_id, v.contact_country_id, v.ActiveMembers
    INTO #ExpectedFact
    FROM (VALUES (1, 2, 6, 1, 1), (1, 1000001, 3, 3, 1)) AS v (date_id, country_id, local_group_id, contact_country_id, ActiveMembers);

    EXEC (N'SELECT date_id, country_id, local_group_id, contact_country_id, ActiveMembers INTO #ActualFact
FROM Layercake.fact_daily_member_count_detail;
EXEC tSQLt.AssertEqualsTable ''#ExpectedFact'', ''#ActualFact'', ''fact_daily_member_count_detail'';');
END;
GO

CREATE PROCEDURE test_MOD031_dev.[test a local group move on the normal path logs the detail and main cells it inserts and deletes]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @ins int, @upd int, @del int, @adj int;

    EXEC test_MOD031_dev.[Add member] N'G1', 'C0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031_dev.[Run members] @run_id = @r1;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    UPDATE Layercake.brnz_contact SET rics_localgroupid = 'A0000000-0000-0000-0000-000000000002' WHERE Rics_contactno = N'G1';
    EXEC test_MOD031_dev.[Run members] @run_id = @r2;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    -- the Gulf / MEA detail cell and main row go, the London / UK&I ones come
    SELECT @ins = l.rows_inserted, @upd = l.rows_updated, @del = l.rows_deleted
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @r2 AND l.step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEquals 2, @ins, 'rows_inserted';
    EXEC tSQLt.AssertEquals 0, @upd, 'rows_updated';
    EXEC tSQLt.AssertEquals 2, @del, 'rows_deleted';

    SELECT @adj = COUNT(*) FROM Layercake.silv_daily_count_adjustment AS a WHERE a.run_id = @r2;
    EXEC tSQLt.AssertEquals 2, @adj, 'adjustment rows';

    SELECT v.region, v.grade, v.active_count
    INTO #ExpectedDaily
    FROM (VALUES ('UK&I', 'election', 1)) AS v (region, grade, active_count);

    SELECT d.region, d.grade, d.active_count INTO #ActualDaily FROM Layercake.silv_daily_count AS d;
    EXEC tSQLt.AssertEqualsTable '#ExpectedDaily', '#ActualDaily', 'silv_daily_count';
END;
GO

CREATE PROCEDURE test_MOD031_dev.[test a change to the own country region alone is recomputed on the normal path]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @contacts int, @full int;

    EXEC test_MOD031_dev.[Add member] N'G1', 'C0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000001', 1;
    EXEC test_MOD031_dev.[Run members] @run_id = @r1;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    -- only contact_region moves: G1 stays in Gulf / MEA, its own country's region becomes BRIT
    UPDATE Layercake.silv_ref_country SET region_name = N'BRIT' WHERE id = 1;
    EXEC test_MOD031_dev.[Run members] @run_id = @r2;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT @contacts = MAX(CASE WHEN p.substep = N'contacts_recomputed' THEN p.rows_affected END),
           @full = MAX(CASE WHEN p.substep = N'full_recompute_path' THEN p.rows_affected END)
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2;
    EXEC tSQLt.AssertEquals 1, @contacts, 'contacts_recomputed';
    EXEC tSQLt.AssertEquals 0, @full, 'full_recompute_path';

    SELECT v.region, v.country_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count
    INTO #ExpectedDetail
    FROM (VALUES ('MEA', 2, 1, 1, 'BRIT', 1)) AS v (region, country_id, local_group_id, contact_country_id, contact_region, active_count);

    EXEC (N'SELECT region, country_id, local_group_id, contact_country_id, contact_region, active_count INTO #ActualDetail
FROM Layercake.silv_daily_count_detail;
EXEC tSQLt.AssertEqualsTable ''#ExpectedDetail'', ''#ActualDetail'', ''silv_daily_count_detail'';');
END;
GO

CREATE PROCEDURE test_MOD031_dev.[test the detail as-known-at function undoes later changes cell by cell on the local group columns]
AS
BEGIN
    -- stored: G1 in London. After T a move from Gulf to London was written; before T a
    -- pre-deployment row with local group -2 was written, which is part of the figure at T.
    EXEC (N'INSERT INTO Layercake.silv_daily_count_detail
    ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
     payment_method_id, payer_type_id, concession_type_id, local_group_id, contact_country_id, contact_region,
     active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
VALUES (''2025-01-10'', 2025, ''Q2'', ''UK&I'', 1, 1, ''election'', 1, 0, 0, 0, 2, 1, ''UK&I'', 1, 0, 0, 0, 0, 0, 0);
INSERT INTO Layercake.silv_daily_count_adjustment
    (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
     payment_method_id, payer_type_id, concession_type_id, local_group_id, contact_country_id, contact_region,
     active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
     event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
VALUES (''E0000000-0000-0000-0000-000000000001'', 1, ''2024-12-01 07:00:00.000'', ''2025-01-10'', ''UK&I'', 1, 1, ''election'', 1,
        0, 0, 0, -2, 1, ''UK&I'', 0, 1, 0, 0, 0, 0, 0),
       (''E0000000-0000-0000-0000-000000000002'', 2, ''2025-02-01 07:00:00.000'', ''2025-01-10'', ''MEA'', 2, 1, ''election'', 1,
        0, 0, 0, 1, 1, ''UK&I'', -1, 0, 0, 0, 0, 0, 0),
       (''E0000000-0000-0000-0000-000000000002'', 2, ''2025-02-01 07:00:00.000'', ''2025-01-10'', ''UK&I'', 1, 1, ''election'', 1,
        0, 0, 0, 2, 1, ''UK&I'', 1, 0, 0, 0, 0, 0, 0);');

    SELECT v.region, v.country_id, v.local_group_id, v.contact_country_id, v.contact_region, v.active_count, v.paid_count
    INTO #Expected
    FROM (VALUES ('UK&I', 1, 2, 1, 'UK&I', 0, 0),
                 ('MEA', 2, 1, 1, 'UK&I', 1, 0)) AS v (region, country_id, local_group_id, contact_country_id, contact_region, active_count, paid_count);

    SELECT f.region, f.country_id, f.local_group_id, f.contact_country_id, f.contact_region, f.active_count, f.paid_count
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_detail_as_known_at('2025-01-01', '2025-01-31', '2025-01-15 00:00:00.000') AS f;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'detail as known at 2025-01-15';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD031_dev.[test an own country region too long for the state ranges fails the load naming the value]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @msg nvarchar(4000), @status varchar(10), @ranges int;

    UPDATE Layercake.silv_ref_country SET region_name = N'Asia and the Pacific' WHERE id = 3;
    EXEC test_MOD031_dev.[Add member] N'G2', 'C0000000-0000-0000-0000-000000000003', 'A0000000-0000-0000-0000-000000000003', 3;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_member_state_ranges @run_id = @r1;
        EXEC tSQLt.Fail 'the state ranges load should fail on an own-country region longer than its column';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 50031
            THROW;
        SET @msg = ERROR_MESSAGE();
    END CATCH;

    IF @msg NOT LIKE N'%Asia and the Pacific%'
        EXEC tSQLt.Fail 'expected the error to name the whole region value, got: ', @msg;

    SELECT @status = l.status FROM Layercake.etl_run_log AS l WHERE l.run_id = @r1;
    EXEC tSQLt.AssertEquals 'Failed', @status, 'state ranges load status';

    SELECT @ranges = COUNT(*) FROM Layercake.silv_member_state_ranges;
    EXEC tSQLt.AssertEquals 0, @ranges, 'state ranges written';
END;
GO
