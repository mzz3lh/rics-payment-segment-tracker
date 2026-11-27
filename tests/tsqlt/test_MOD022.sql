EXEC tSQLt.NewTestClass 'test_MOD022';
GO
CREATE PROCEDURE test_MOD022.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_loaded', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_pending_rebuild', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_input_basis', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count';
    EXEC tSQLt.FakeTable 'Layercake.ref_date_spine';
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_status';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_grade';
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_state_ranges';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_profile';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';

    INSERT INTO Layercake.silv_ref_membership_status (id, status_name)
    VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');

    INSERT INTO Layercake.silv_ref_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2021, '2020-10-01', '2021-09-30', '2021-06-01'),
           (2022, '2021-10-01', '2022-09-30', '2022-06-01'),
           (2023, '2022-10-01', '2023-09-30', '2023-06-01'),
           (2024, '2023-10-01', '2024-09-30', '2024-06-01'),
           (2025, '2024-10-01', '2025-09-30', '2025-06-01');

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2025-01-09', 2025, 'Q2'), ('2025-01-10', 2025, 'Q2'), ('2025-01-11', 2025, 'Q2');

    -- D1 and D2: Qualified ('election'), region UK, active throughout, no retirement date (Practising).
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'D1', '2015-01-01', NULL, 2015, 'election', 'UK', 2),
           (2, N'D2', '2015-01-01', NULL, 2015, 'election', 'UK', 2);

    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D1', 1, 1, NULL), (N'D2', 2, 2, NULL);

    -- D2 paid CY2025 on 2024-10-20 and renewed that day; D1 has no payment and no event.
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'D2', 2025, '2024-10-20', '2024-10-20', N'Fully Paid');

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1, N'RN:D2:2025', 'Renewal', 'Standard', '2024-10-20', N'D2', 2, 0, 0, 0, 2, 2, 1, 2025, 'Q1', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-001 a Renewal added to a loaded date raises event_renewal_count on that date only]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #Actual
    FROM Layercake.silv_daily_count_detail;

    SELECT v.[date], v.campaign_year, v.campaign_quarter, v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES
        (CAST('2025-01-09' AS date), 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
        ('2025-01-09', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 1, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
        ('2025-01-11', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 0, 0, 0),
        ('2025-01-11', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0)
    ) AS v([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-002 after the second run both daily tables equal a FullRebuild on the same data]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID();
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #ActualDetail
    FROM Layercake.silv_daily_count_detail;

    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #ActualDaily
    FROM Layercake.silv_daily_count;

    SELECT v.[date], v.campaign_year, v.campaign_quarter, v.region, v.grade,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpectedDaily
    FROM (VALUES
        (CAST('2025-01-09' AS date), 2025, 'Q2', 'UK', 'election', 2, 1, 1, 0, 0, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 'election', 2, 1, 2, 0, 1, 0, 0),
        ('2025-01-11', 2025, 'Q2', 'UK', 'election', 2, 1, 2, 0, 0, 0, 0)
    ) AS v([date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#ExpectedDaily', '#ActualDaily';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #FullDetail
    FROM Layercake.silv_daily_count_detail;

    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #FullDaily
    FROM Layercake.silv_daily_count;

    EXEC tSQLt.AssertEqualsTable '#FullDetail', '#ActualDetail';
    EXEC tSQLt.AssertEqualsTable '#FullDaily', '#ActualDaily';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-003 a contact removed from every input loses its cells on every loaded date and its basis row]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    DELETE FROM Layercake.silv_member_state_ranges WHERE contact_no = N'D2';
    DELETE FROM Layercake.silv_member_profile WHERE contact_no = N'D2';
    DELETE FROM Layercake.silv_payment_events WHERE contact_no = N'D2';
    DELETE FROM Layercake.silv_membership_events WHERE contact_no = N'D2';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #Actual
    FROM Layercake.silv_daily_count_detail;

    SELECT v.[date], v.campaign_year, v.campaign_quarter, v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES
        (CAST('2025-01-09' AS date), 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
        ('2025-01-11', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0)
    ) AS v([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT input_key INTO #ActualBasis FROM Layercake.etl_daily_count_input_basis WHERE input_name = 'contact';
    SELECT CAST(N'D1' AS nvarchar(200)) AS input_key INTO #ExpectedBasis;
    EXEC tSQLt.AssertEqualsTable '#ExpectedBasis', '#ActualBasis';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-004 a changed retirement date moves past days from Practising to Retired with no rebuild parameter]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    DELETE FROM Layercake.ref_date_spine;
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2024-11-30', 2025, 'Q1'), ('2024-12-01', 2025, 'Q1'), ('2025-01-14', 2025, 'Q2'), ('2025-01-15', 2025, 'Q2');

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (3, N'T5', '2015-01-01', NULL, 2015, 'election', 'UK', 2);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'T5', 3, 1, '2025-01-15');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    UPDATE Layercake.silv_member_profile SET retirement_date = '2024-12-01' WHERE contact_no = N'T5';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #Actual
    FROM Layercake.silv_daily_count_detail
    WHERE country_id = 3;

    SELECT v.[date], v.campaign_year, v.campaign_quarter, v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES
        (CAST('2024-11-30' AS date), 2025, 'Q1', 'UK', 3, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
        ('2024-12-01', 2025, 'Q1', 'UK', 3, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0),
        ('2025-01-14', 2025, 'Q2', 'UK', 3, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0),
        ('2025-01-15', 2025, 'Q2', 'UK', 3, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0)
    ) AS v([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-005 a Lapse in closed CY2021 and a Join on 2020-10-01 added after loading are corrected]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID();

    DELETE FROM Layercake.ref_date_spine;
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2020-10-01', 2021, 'Q1'), ('2021-03-14', 2021, 'Q2'), ('2021-03-15', 2021, 'Q2'), ('2021-03-16', 2021, 'Q2');

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (4, N'D3', '2015-01-01', NULL, 2015, 'election', 'UK', 2);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D3', 4, 1, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'D3', 2021, '2020-10-10', '2020-10-10', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (3, N'RN:D3:2021', 'Renewal', 'Standard', '2020-10-10', N'D3', 2, 0, 0, 0, 4, 1, 1, 2021, 'Q1', -2, 0, -2, 0, -2, 0, NULL, NULL, 'Before invoice data');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    -- D3 lapses on 2021-03-15; D4 joins on 2020-10-01 as a Candidate.
    UPDATE Layercake.silv_member_state_ranges SET valid_to = '2021-03-15' WHERE id = 4;
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (5, N'D3', '2021-03-15', NULL, 2021, 'lapse', 'UK', 3),
           (6, N'D4', '2020-10-01', NULL, 2021, 'enrolment', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D4', 5, 2, NULL);
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (4, N'LA:D3', 'Lapse', 'Standard', '2021-03-15', N'D3', 0, 0, 0, 0, 4, 1, 0, 2021, 'Q2', -2, 0, -2, 0, -2, 0, NULL, NULL, NULL),
           (5, N'JN:D4', 'Join', 'Standard', '2020-10-01', N'D4', 1, 0, 0, 0, 5, 2, 0, 2021, 'Q1', -2, 0, -2, 0, -2, 0, NULL, NULL, 'Before invoice data');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #Actual
    FROM Layercake.silv_daily_count_detail
    WHERE country_id IN (4, 5);

    SELECT v.[date], v.campaign_year, v.campaign_quarter, v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES
        (CAST('2020-10-01' AS date), 2021, 'Q1', 'UK', 4, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
        ('2020-10-01', 2021, 'Q1', 'UK', 5, 2, 'enrolment', 0, 1, 0, 1, 1, 0, 0, 0),
        ('2021-03-14', 2021, 'Q2', 'UK', 4, 1, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
        ('2021-03-14', 2021, 'Q2', 'UK', 5, 2, 'enrolment', 0, 1, 0, 1, 0, 0, 0, 0),
        ('2021-03-15', 2021, 'Q2', 'UK', 4, 1, 'lapse', 0, 0, 1, 1, 0, 0, 0, 1),
        ('2021-03-15', 2021, 'Q2', 'UK', 5, 2, 'enrolment', 0, 1, 0, 1, 0, 0, 0, 0),
        ('2021-03-16', 2021, 'Q2', 'UK', 4, 1, 'lapse', 0, 0, 1, 1, 0, 0, 0, 0),
        ('2021-03-16', 2021, 'Q2', 'UK', 5, 2, 'enrolment', 0, 1, 0, 1, 0, 0, 0, 0)
    ) AS v([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #ActualDetail
    FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #ActualDaily
    FROM Layercake.silv_daily_count;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #FullDetail
    FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #FullDaily
    FROM Layercake.silv_daily_count;

    EXEC tSQLt.AssertEqualsTable '#FullDetail', '#ActualDetail';
    EXEC tSQLt.AssertEqualsTable '#FullDaily', '#ActualDaily';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-006 a change to membership events alone is corrected with no pending rebuild row]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID();
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    -- Only silv_membership_events changes: D2's Renewal moves from 2024-10-20 to 2025-01-10.
    UPDATE Layercake.silv_membership_events SET event_date = '2025-01-10', campaign_quarter = 'Q2' WHERE event_id = 1;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #Actual
    FROM Layercake.silv_daily_count_detail
    WHERE country_id = 2;

    SELECT v.[date], v.campaign_year, v.campaign_quarter, v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES
        (CAST('2025-01-09' AS date), 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 0, 0, 0, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 1, 0, 0),
        ('2025-01-11', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0)
    ) AS v([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #ActualDetail
    FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #ActualDaily
    FROM Layercake.silv_daily_count;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #FullDetail
    FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #FullDaily
    FROM Layercake.silv_daily_count;

    EXEC tSQLt.AssertEqualsTable '#FullDetail', '#ActualDetail';
    EXEC tSQLt.AssertEqualsTable '#FullDaily', '#ActualDaily';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-007 an open pending rebuild row covered by the correction is marked applied]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    UPDATE Layercake.silv_payment_events
    SET payment_date = '2025-01-10', renewal_date_adj = '2025-01-10'
    WHERE contact_no = N'D2' AND campaign_year = 2025;

    INSERT INTO Layercake.etl_daily_count_pending_rebuild
        (source, affected_from, detection_count, first_detected_at, last_detected_at, last_run_id, detail, applied_at)
    VALUES ('payments', '2025-01-10', 1, '2026-11-17 06:00', '2026-11-17 06:00', @r1, N'NOT rebuilt by the daily run; use @RebuildFrom to apply', NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT source, affected_from, CASE WHEN applied_at IS NULL THEN 0 ELSE 1 END AS is_applied
    INTO #ActualPending
    FROM Layercake.etl_daily_count_pending_rebuild;

    SELECT CAST('payments' AS varchar(20)) AS source, CAST('2025-01-10' AS date) AS affected_from, 1 AS is_applied
    INTO #ExpectedPending;

    EXEC tSQLt.AssertEqualsTable '#ExpectedPending', '#ActualPending';

    SELECT [date], country_id, membership_status_id, active_count, paid_count, paid_count_event
    INTO #Actual
    FROM Layercake.silv_daily_count_detail
    WHERE country_id = 2;

    SELECT v.[date], v.country_id, v.membership_status_id, v.active_count, v.paid_count, v.paid_count_event
    INTO #Expected
    FROM (VALUES
        (CAST('2025-01-09' AS date), 2, 1, 1, 0, 1),
        ('2025-01-10', 2, 1, 1, 1, 1),
        ('2025-01-11', 2, 1, 1, 1, 1)
    ) AS v([date], country_id, membership_status_id, active_count, paid_count, paid_count_event);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-008 the first run after deployment corrects Phase 1 drift back to 2022-11-01]
AS
BEGIN
    DECLARE @old uniqueidentifier = NEWID(), @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    DELETE FROM Layercake.ref_date_spine;
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2022-11-01', 2023, 'Q1'), ('2023-06-15', 2023, 'Q3'), ('2025-01-10', 2025, 'Q2');

    -- What the Phase 1 procedure stored from the data before the three changes; every date marked loaded, basis empty.
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-11-01', 2023, 'Q1', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
           ('2022-11-01', 2023, 'Q1', 'UK', 2, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
           ('2023-06-15', 2023, 'Q3', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
           ('2023-06-15', 2023, 'Q3', 'UK', 2, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0);
    INSERT INTO Layercake.silv_daily_count
        ([date], campaign_year, campaign_quarter, region, grade,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-11-01', 2023, 'Q1', 'UK', 'election', 2, 0, 0, 0, 0, 0, 0),
           ('2023-06-15', 2023, 'Q3', 'UK', 'election', 2, 0, 0, 0, 0, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 'election', 2, 1, 1, 0, 0, 0, 0);
    INSERT INTO Layercake.etl_daily_count_loaded ([date], loaded_at, run_id, batch_from, batch_to)
    VALUES ('2022-11-01', '2026-11-01 05:00', @old, '2022-11-01', '2022-11-01'),
           ('2023-06-15', '2026-11-01 05:00', @old, '2023-06-15', '2023-06-15'),
           ('2025-01-10', '2026-11-01 05:00', @old, '2025-01-10', '2025-01-10');

    -- Source changes reaching back to 2022-11-01, 2023-06-15 and 2025-01-10.
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2023', 'Renewal', 'Standard', '2022-11-01', N'D1', 2, 0, 0, 0, 1, 1, 1, 2023, 'Q1', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced'),
           (3, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'D2', 2023, '2023-06-15', '2023-06-15', N'Fully Paid');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #ActualDetail
    FROM Layercake.silv_daily_count_detail;

    SELECT v.[date], v.campaign_year, v.campaign_quarter, v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES
        (CAST('2022-11-01' AS date), 2023, 'Q1', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 1, 0, 0),
        ('2022-11-01', 2023, 'Q1', 'UK', 2, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
        ('2023-06-15', 2023, 'Q3', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 0, 0, 0),
        ('2023-06-15', 2023, 'Q3', 'UK', 2, 2, 'election', 1, 1, 1, 0, 0, 0, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 1, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0)
    ) AS v([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualDetail';

    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #ActualDaily
    FROM Layercake.silv_daily_count;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @FullRebuild = 1;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #FullDetail
    FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #FullDaily
    FROM Layercake.silv_daily_count;

    EXEC tSQLt.AssertEqualsTable '#FullDetail', '#ActualDetail';
    EXEC tSQLt.AssertEqualsTable '#FullDaily', '#ActualDaily';
END;
GO
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD022.[test TC-022-009 a run failing part way re-raises logs Failed keeps committed dates and the next run completes]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @r4 uniqueidentifier = NEWID();
    DECLARE @status varchar(10);

    EXEC tSQLt.ApplyConstraint 'Layercake.silv_daily_count_detail', 'pk_silv_daily_count_detail';
    EXEC tSQLt.ApplyConstraint 'Layercake.silv_daily_count', 'pk_silv_daily_count';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT input_name, input_key, input_fingerprint, earliest_affected_date, run_id, updated_at
    INTO #BasisBefore
    FROM Layercake.etl_daily_count_input_basis;

    -- D1 renews on 2025-01-09 (changes every date); D6 has a range from 2025-01-10 with no region, so the 2025-01-10 batch fails.
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-09', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (7, N'D6', '2025-01-10', NULL, 2025, 'election', NULL, 2);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D6', 7, 1, NULL);

    BEGIN TRY
        EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @DailyCountBatchDays = 1;
        EXEC tSQLt.Fail 'usp_load_silv_daily_count did not raise an error for a cell with a NULL region.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515 THROW;
    END CATCH;

    SELECT @status = status FROM Layercake.etl_run_log
    WHERE run_id = @r2 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEquals 'Failed', @status;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #ActualAfterFail
    FROM Layercake.silv_daily_count_detail;

    SELECT v.[date], v.campaign_year, v.campaign_quarter, v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpectedAfterFail
    FROM (VALUES
        (CAST('2025-01-09' AS date), 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 1, 0, 0),
        ('2025-01-09', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
        ('2025-01-11', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
        ('2025-01-11', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0)
    ) AS v([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#ExpectedAfterFail', '#ActualAfterFail';

    SELECT input_name, input_key, input_fingerprint, earliest_affected_date, run_id, updated_at
    INTO #BasisAfterFail
    FROM Layercake.etl_daily_count_input_basis;
    EXEC tSQLt.AssertEqualsTable '#BasisBefore', '#BasisAfterFail';

    -- The source is corrected; the next run needs no cleanup.
    UPDATE Layercake.silv_member_state_ranges SET region = 'UK' WHERE id = 7;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3;

    SET @status = NULL;
    SELECT @status = status FROM Layercake.etl_run_log
    WHERE run_id = @r3 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEquals 'Success', @status;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #ActualDetail
    FROM Layercake.silv_daily_count_detail;

    SELECT v.[date], v.campaign_year, v.campaign_quarter, v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES
        (CAST('2025-01-09' AS date), 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 1, 0, 0),
        ('2025-01-09', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 0, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 7, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
        ('2025-01-11', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 0, 0, 0),
        ('2025-01-11', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
        ('2025-01-11', 2025, 'Q2', 'UK', 7, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0)
    ) AS v([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualDetail';

    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #ActualDaily
    FROM Layercake.silv_daily_count;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r4, @FullRebuild = 1;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #FullDetail
    FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #FullDaily
    FROM Layercake.silv_daily_count;

    EXEC tSQLt.AssertEqualsTable '#FullDetail', '#ActualDetail';
    EXEC tSQLt.AssertEqualsTable '#FullDaily', '#ActualDaily';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-010 the gold daily fact follows the corrected silver detail by date]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    EXEC tSQLt.FakeTable 'Layercake.fact_daily_member_count_detail', @Identity = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_date';
    EXEC tSQLt.FakeTable 'Layercake.dim_membership_grade';

    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2025-01-09', 2025, 'Q2'), (2, '2025-01-10', 2025, 'Q2'), (3, '2025-01-11', 2025, 'Q2');
    INSERT INTO Layercake.dim_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;

    SELECT v.[date], v.active_members, v.paid_members, v.paid_members_event, v.join_events, v.renewal_events, v.readmission_events, v.lapse_events
    INTO #Expected
    FROM (VALUES
        (CAST('2025-01-09' AS date), 2, 1, 1, 0, 0, 0, 0),
        ('2025-01-10', 2, 1, 2, 0, 1, 0, 0),
        ('2025-01-11', 2, 1, 2, 0, 0, 0, 0)
    ) AS v([date], active_members, paid_members, paid_members_event, join_events, renewal_events, readmission_events, lapse_events);

    SELECT d.[date],
           SUM(f.ActiveMembers) AS active_members, SUM(f.PaidMembers) AS paid_members, SUM(f.PaidMembersEvent) AS paid_members_event,
           SUM(f.JoinEvents) AS join_events, SUM(f.RenewalEvents) AS renewal_events, SUM(f.ReadmissionEvents) AS readmission_events,
           SUM(f.LapseEvents) AS lapse_events
    INTO #ActualGold
    FROM Layercake.fact_daily_member_count_detail AS f
    INNER JOIN Layercake.dim_date AS d ON d.id = f.date_id
    GROUP BY d.[date];

    SELECT s.[date],
           SUM(s.active_count) AS active_members, SUM(s.paid_count) AS paid_members, SUM(s.paid_count_event) AS paid_members_event,
           SUM(s.event_join_count) AS join_events, SUM(s.event_renewal_count) AS renewal_events,
           SUM(s.event_readmission_count) AS readmission_events, SUM(s.event_lapse_count) AS lapse_events
    INTO #ActualSilver
    FROM Layercake.silv_daily_count_detail AS s
    GROUP BY s.[date];

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualGold';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSilver';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-011 RebuildFrom and FullRebuild still run log Success and leave the correct history]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID();
    DECLARE @status varchar(10);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @RebuildFrom = '2025-01-01';

    SELECT @status = status FROM Layercake.etl_run_log
    WHERE run_id = @r2 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEquals 'Success', @status;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #AfterRebuildFrom
    FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #AfterRebuildFromDaily
    FROM Layercake.silv_daily_count;

    SELECT v.[date], v.campaign_year, v.campaign_quarter, v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES
        (CAST('2025-01-09' AS date), 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
        ('2025-01-09', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 1, 0, 0),
        ('2025-01-10', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
        ('2025-01-11', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 0, 0, 0),
        ('2025-01-11', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0)
    ) AS v([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#AfterRebuildFrom';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;

    SET @status = NULL;
    SELECT @status = status FROM Layercake.etl_run_log
    WHERE run_id = @r3 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEquals 'Success', @status;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #AfterFull
    FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #AfterFullDaily
    FROM Layercake.silv_daily_count;

    EXEC tSQLt.AssertEqualsTable '#AfterRebuildFrom', '#AfterFull';
    EXEC tSQLt.AssertEqualsTable '#AfterRebuildFromDaily', '#AfterFullDaily';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-012 the second run writes one adjustment row per changed cell and they reconcile before to after]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #Before
    FROM Layercake.silv_daily_count_detail;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #Actual
    FROM Layercake.silv_daily_count_adjustment;

    SELECT v.run_id, v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count_change, v.paid_count_change, v.paid_count_event_change, v.event_join_count_change,
           v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #Expected
    FROM (VALUES
        (@r2, CAST('2025-01-10' AS date), 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 1, 0, 0),
        (@r2, '2025-01-11', 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 0, 0, 0)
    ) AS v(run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT x.[date], x.region, x.country_id, x.gender_id, x.grade, x.membership_status_id
    INTO #Mismatch
    FROM (
        SELECT b.[date], b.region, b.country_id, b.gender_id, b.grade, b.membership_status_id,
               b.active_count AS m1, b.paid_count AS m2, b.paid_count_event AS m3, b.event_join_count AS m4,
               b.event_renewal_count AS m5, b.event_readmission_count AS m6, b.event_lapse_count AS m7
        FROM #Before AS b
        UNION ALL
        SELECT a.[date], a.region, a.country_id, a.gender_id, a.grade, a.membership_status_id,
               a.active_count_change, a.paid_count_change, a.paid_count_event_change, a.event_join_count_change,
               a.event_renewal_count_change, a.event_readmission_count_change, a.event_lapse_count_change
        FROM Layercake.silv_daily_count_adjustment AS a
        WHERE a.run_id = @r2
        UNION ALL
        SELECT d.[date], d.region, d.country_id, d.gender_id, d.grade, d.membership_status_id,
               -d.active_count, -d.paid_count, -d.paid_count_event, -d.event_join_count,
               -d.event_renewal_count, -d.event_readmission_count, -d.event_lapse_count
        FROM Layercake.silv_daily_count_detail AS d
    ) AS x
    GROUP BY x.[date], x.region, x.country_id, x.gender_id, x.grade, x.membership_status_id
    HAVING SUM(x.m1) <> 0 OR SUM(x.m2) <> 0 OR SUM(x.m3) <> 0 OR SUM(x.m4) <> 0
        OR SUM(x.m5) <> 0 OR SUM(x.m6) <> 0 OR SUM(x.m7) <> 0;

    EXEC tSQLt.AssertEmptyTable '#Mismatch';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-013 a cell missing before or after the change counts as 0 in its adjustment]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    DELETE FROM Layercake.ref_date_spine;
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2020-10-01', 2021, 'Q1'), ('2021-03-14', 2021, 'Q2'), ('2021-03-15', 2021, 'Q2'), ('2021-03-16', 2021, 'Q2');

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (4, N'D3', '2015-01-01', NULL, 2015, 'election', 'UK', 2);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D3', 4, 1, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'D3', 2021, '2020-10-10', '2020-10-10', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (3, N'RN:D3:2021', 'Renewal', 'Standard', '2020-10-10', N'D3', 2, 0, 0, 0, 4, 1, 1, 2021, 'Q1', -2, 0, -2, 0, -2, 0, NULL, NULL, 'Before invoice data');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    UPDATE Layercake.silv_member_state_ranges SET valid_to = '2021-03-15' WHERE id = 4;
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (5, N'D3', '2021-03-15', NULL, 2021, 'lapse', 'UK', 3),
           (6, N'D4', '2020-10-01', NULL, 2021, 'enrolment', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D4', 5, 2, NULL);
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (4, N'LA:D3', 'Lapse', 'Standard', '2021-03-15', N'D3', 0, 0, 0, 0, 4, 1, 0, 2021, 'Q2', -2, 0, -2, 0, -2, 0, NULL, NULL, NULL),
           (5, N'JN:D4', 'Join', 'Standard', '2020-10-01', N'D4', 1, 0, 0, 0, 5, 2, 0, 2021, 'Q1', -2, 0, -2, 0, -2, 0, NULL, NULL, 'Before invoice data');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #Actual
    FROM Layercake.silv_daily_count_adjustment;

    SELECT v.run_id, v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count_change, v.paid_count_change, v.paid_count_event_change, v.event_join_count_change,
           v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #Expected
    FROM (VALUES
        (@r2, CAST('2020-10-01' AS date), 'UK', 5, 2, 'enrolment', 0, 1, 0, 1, 1, 0, 0, 0),
        (@r2, '2021-03-14', 'UK', 5, 2, 'enrolment', 0, 1, 0, 1, 0, 0, 0, 0),
        (@r2, '2021-03-15', 'UK', 4, 1, 'election', 1, -1, -1, -1, 0, 0, 0, 0),
        (@r2, '2021-03-15', 'UK', 4, 1, 'lapse', 0, 0, 1, 1, 0, 0, 0, 1),
        (@r2, '2021-03-15', 'UK', 5, 2, 'enrolment', 0, 1, 0, 1, 0, 0, 0, 0),
        (@r2, '2021-03-16', 'UK', 4, 1, 'election', 1, -1, -1, -1, 0, 0, 0, 0),
        (@r2, '2021-03-16', 'UK', 4, 1, 'lapse', 0, 0, 1, 1, 0, 0, 0, 0),
        (@r2, '2021-03-16', 'UK', 5, 2, 'enrolment', 0, 1, 0, 1, 0, 0, 0, 0)
    ) AS v(run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-014 the first run on a database with no loaded date writes no adjustment row]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();
    DECLARE @today date = CAST(SYSDATETIME() AS date);
    DECLARE @cy int = YEAR(@today) + CASE WHEN MONTH(@today) >= 10 THEN 1 ELSE 0 END;
    DECLARE @cq char(2) = CASE WHEN MONTH(@today) >= 10 THEN 'Q1' WHEN MONTH(@today) <= 3 THEN 'Q2' WHEN MONTH(@today) <= 6 THEN 'Q3' ELSE 'Q4' END;
    DECLARE @rows int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES (@today, @cy, @cq);
    IF NOT EXISTS (SELECT 1 FROM Layercake.ref_campaign_year_config WHERE campaign_year = @cy)
        INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
        VALUES (@cy, DATEFROMPARTS(@cy - 1, 10, 1), DATEFROMPARTS(@cy, 9, 30), DATEFROMPARTS(@cy, 6, 1));

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_daily_count_adjustment';

    SELECT @rows = COUNT(*) FROM Layercake.silv_daily_count_detail;
    EXEC tSQLt.AssertEquals 8, @rows;
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-015 a Join added today between two same-day runs is recorded only by the second run]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();
    DECLARE @today date = CAST(SYSDATETIME() AS date);
    DECLARE @cy int = YEAR(@today) + CASE WHEN MONTH(@today) >= 10 THEN 1 ELSE 0 END;
    DECLARE @cq char(2) = CASE WHEN MONTH(@today) >= 10 THEN 'Q1' WHEN MONTH(@today) <= 3 THEN 'Q2' WHEN MONTH(@today) <= 6 THEN 'Q3' ELSE 'Q4' END;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES (@today, @cy, @cq);
    IF NOT EXISTS (SELECT 1 FROM Layercake.ref_campaign_year_config WHERE campaign_year = @cy)
        INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
        VALUES (@cy, DATEFROMPARTS(@cy - 1, 10, 1), DATEFROMPARTS(@cy, 9, 30), DATEFROMPARTS(@cy, 6, 1));

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (8, N'D5', '2024-01-01', NULL, 2024, 'enrolment', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D5', 6, 1, NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (6, N'JN:D5', 'Join', 'Standard', @today, N'D5', 1, 0, 0, 0, 6, 1, 0, @cy, @cq, 3, 0, 1, 0, 0, 0, 50.0000, 50.0000, 'Invoiced');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #Actual
    FROM Layercake.silv_daily_count_adjustment;

    SELECT @r2 AS run_id, @today AS [date], 'UK' AS region, 6 AS country_id, 1 AS gender_id, 'enrolment' AS grade, 0 AS membership_status_id,
           0 AS active_count_change, 0 AS paid_count_change, 1 AS paid_count_event_change, 1 AS event_join_count_change,
           0 AS event_renewal_count_change, 0 AS event_readmission_count_change, 0 AS event_lapse_count_change
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-016 a second same-day run with no source change writes nothing and changes no daily row]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();
    DECLARE @today date = CAST(SYSDATETIME() AS date);
    DECLARE @cy int = YEAR(@today) + CASE WHEN MONTH(@today) >= 10 THEN 1 ELSE 0 END;
    DECLARE @cq char(2) = CASE WHEN MONTH(@today) >= 10 THEN 'Q1' WHEN MONTH(@today) <= 3 THEN 'Q2' WHEN MONTH(@today) <= 6 THEN 'Q3' ELSE 'Q4' END;
    DECLARE @status varchar(10);

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES (@today, @cy, @cq);
    IF NOT EXISTS (SELECT 1 FROM Layercake.ref_campaign_year_config WHERE campaign_year = @cy)
        INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
        VALUES (@cy, DATEFROMPARTS(@cy - 1, 10, 1), DATEFROMPARTS(@cy, 9, 30), DATEFROMPARTS(@cy, 6, 1));

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT * INTO #BeforeDetail FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #BeforeDaily FROM Layercake.silv_daily_count;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT @status = status FROM Layercake.etl_run_log
    WHERE run_id = @r2 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEquals 'Success', @status;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_daily_count_adjustment';

    SELECT * INTO #AfterDetail FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #AfterDaily FROM Layercake.silv_daily_count;

    EXEC tSQLt.AssertEqualsTable '#BeforeDetail', '#AfterDetail';
    EXEC tSQLt.AssertEqualsTable '#BeforeDaily', '#AfterDaily';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-017 RebuildFrom records its changes under its own run_id and a following FullRebuild records none]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID();
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @RebuildFrom = '2025-01-01';

    SELECT run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #Actual
    FROM Layercake.silv_daily_count_adjustment;

    SELECT v.run_id, v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count_change, v.paid_count_change, v.paid_count_event_change, v.event_join_count_change,
           v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #Expected
    FROM (VALUES
        (@r2, CAST('2025-01-10' AS date), 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 1, 0, 0),
        (@r2, '2025-01-11', 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 0, 0, 0)
    ) AS v(run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;

    SELECT adjustment_id INTO #FullRebuildRows FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEmptyTable '#FullRebuildRows';
END;
GO
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD022.[test TC-022-018 a failed run and its completing run hold exactly the committed changes in the history]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID();

    EXEC tSQLt.ApplyConstraint 'Layercake.silv_daily_count_detail', 'pk_silv_daily_count_detail';
    EXEC tSQLt.ApplyConstraint 'Layercake.silv_daily_count', 'pk_silv_daily_count';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #Before
    FROM Layercake.silv_daily_count_detail;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-09', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (7, N'D6', '2025-01-10', NULL, 2025, 'election', NULL, 2);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D6', 7, 1, NULL);

    BEGIN TRY
        EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @DailyCountBatchDays = 1;
        EXEC tSQLt.Fail 'usp_load_silv_daily_count did not raise an error for a cell with a NULL region.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515 THROW;
    END CATCH;

    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #AfterFail
    FROM Layercake.silv_daily_count_detail;

    SELECT run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #ActualFailRows
    FROM Layercake.silv_daily_count_adjustment;

    SELECT @r2 AS run_id, CAST('2025-01-09' AS date) AS [date], 'UK' AS region, 1 AS country_id, 1 AS gender_id, 'election' AS grade,
           1 AS membership_status_id, 0 AS active_count_change, 0 AS paid_count_change, 1 AS paid_count_event_change,
           0 AS event_join_count_change, 1 AS event_renewal_count_change, 0 AS event_readmission_count_change, 0 AS event_lapse_count_change
    INTO #ExpectedFailRows;

    EXEC tSQLt.AssertEqualsTable '#ExpectedFailRows', '#ActualFailRows';

    SELECT x.[date], x.region, x.country_id, x.gender_id, x.grade, x.membership_status_id
    INTO #MismatchFail
    FROM (
        SELECT b.[date], b.region, b.country_id, b.gender_id, b.grade, b.membership_status_id,
               b.active_count AS m1, b.paid_count AS m2, b.paid_count_event AS m3, b.event_join_count AS m4,
               b.event_renewal_count AS m5, b.event_readmission_count AS m6, b.event_lapse_count AS m7
        FROM #Before AS b
        UNION ALL
        SELECT a.[date], a.region, a.country_id, a.gender_id, a.grade, a.membership_status_id,
               a.active_count_change, a.paid_count_change, a.paid_count_event_change, a.event_join_count_change,
               a.event_renewal_count_change, a.event_readmission_count_change, a.event_lapse_count_change
        FROM Layercake.silv_daily_count_adjustment AS a
        WHERE a.run_id = @r2
        UNION ALL
        SELECT f.[date], f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id,
               -f.active_count, -f.paid_count, -f.paid_count_event, -f.event_join_count,
               -f.event_renewal_count, -f.event_readmission_count, -f.event_lapse_count
        FROM #AfterFail AS f
    ) AS x
    GROUP BY x.[date], x.region, x.country_id, x.gender_id, x.grade, x.membership_status_id
    HAVING SUM(x.m1) <> 0 OR SUM(x.m2) <> 0 OR SUM(x.m3) <> 0 OR SUM(x.m4) <> 0
        OR SUM(x.m5) <> 0 OR SUM(x.m6) <> 0 OR SUM(x.m7) <> 0;

    EXEC tSQLt.AssertEmptyTable '#MismatchFail';

    UPDATE Layercake.silv_member_state_ranges SET region = 'UK' WHERE id = 7;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3;

    SELECT run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #ActualNextRows
    FROM Layercake.silv_daily_count_adjustment
    WHERE run_id = @r3;

    SELECT v.run_id, v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count_change, v.paid_count_change, v.paid_count_event_change, v.event_join_count_change,
           v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpectedNextRows
    FROM (VALUES
        (@r3, CAST('2025-01-10' AS date), 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 0, 0, 0),
        (@r3, '2025-01-10', 'UK', 7, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
        (@r3, '2025-01-11', 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 0, 0, 0),
        (@r3, '2025-01-11', 'UK', 7, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0)
    ) AS v(run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);

    EXEC tSQLt.AssertEqualsTable '#ExpectedNextRows', '#ActualNextRows';

    SELECT x.[date], x.region, x.country_id, x.gender_id, x.grade, x.membership_status_id
    INTO #MismatchBoth
    FROM (
        SELECT b.[date], b.region, b.country_id, b.gender_id, b.grade, b.membership_status_id,
               b.active_count AS m1, b.paid_count AS m2, b.paid_count_event AS m3, b.event_join_count AS m4,
               b.event_renewal_count AS m5, b.event_readmission_count AS m6, b.event_lapse_count AS m7
        FROM #Before AS b
        UNION ALL
        SELECT a.[date], a.region, a.country_id, a.gender_id, a.grade, a.membership_status_id,
               a.active_count_change, a.paid_count_change, a.paid_count_event_change, a.event_join_count_change,
               a.event_renewal_count_change, a.event_readmission_count_change, a.event_lapse_count_change
        FROM Layercake.silv_daily_count_adjustment AS a
        WHERE a.run_id IN (@r2, @r3)
        UNION ALL
        SELECT d.[date], d.region, d.country_id, d.gender_id, d.grade, d.membership_status_id,
               -d.active_count, -d.paid_count, -d.paid_count_event, -d.event_join_count,
               -d.event_renewal_count, -d.event_readmission_count, -d.event_lapse_count
        FROM Layercake.silv_daily_count_detail AS d
    ) AS x
    GROUP BY x.[date], x.region, x.country_id, x.gender_id, x.grade, x.membership_status_id
    HAVING SUM(x.m1) <> 0 OR SUM(x.m2) <> 0 OR SUM(x.m3) <> 0 OR SUM(x.m4) <> 0
        OR SUM(x.m5) <> 0 OR SUM(x.m6) <> 0 OR SUM(x.m7) <> 0;

    EXEC tSQLt.AssertEmptyTable '#MismatchBoth';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-019 the first run after deployment records the drift it corrects as adjustments]
AS
BEGIN
    DECLARE @old uniqueidentifier = NEWID(), @r1 uniqueidentifier = NEWID();

    -- AMD-007: the daily count reads the attributes; none for D1 or D2, so every cell takes 0 Unknown.
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes';

    -- AMD-008 (MOD-031): D1 and D2 have no usable local group, so they carry local_group_id 0,
    -- contact_country_id = country_id and contact_region = region, as a migrated Phase 1 row does.
    UPDATE Layercake.silv_member_profile SET local_group_id = 0, contact_country_id = country_id;
    UPDATE Layercake.silv_member_state_ranges SET contact_region = region;

    DELETE FROM Layercake.ref_date_spine;
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2022-11-01', 2023, 'Q1'), ('2023-06-15', 2023, 'Q3'), ('2025-01-10', 2025, 'Q2');

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         payment_method_id, payer_type_id, concession_type_id, local_group_id, contact_country_id, contact_region,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-11-01', 2023, 'Q1', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK', 1, 0, 0, 0, 0, 0, 0),
           ('2022-11-01', 2023, 'Q1', 'UK', 2, 2, 'election', 1, 0, 0, 0, 0, 2, 'UK', 1, 0, 0, 0, 0, 0, 0),
           ('2023-06-15', 2023, 'Q3', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK', 1, 0, 0, 0, 0, 0, 0),
           ('2023-06-15', 2023, 'Q3', 'UK', 2, 2, 'election', 1, 0, 0, 0, 0, 2, 'UK', 1, 0, 0, 0, 0, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK', 1, 0, 0, 0, 0, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 2, 2, 'election', 1, 0, 0, 0, 0, 2, 'UK', 1, 1, 1, 0, 0, 0, 0);
    INSERT INTO Layercake.silv_daily_count
        ([date], campaign_year, campaign_quarter, region, grade,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-11-01', 2023, 'Q1', 'UK', 'election', 2, 0, 0, 0, 0, 0, 0),
           ('2023-06-15', 2023, 'Q3', 'UK', 'election', 2, 0, 0, 0, 0, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 'election', 2, 1, 1, 0, 0, 0, 0);
    INSERT INTO Layercake.etl_daily_count_loaded ([date], loaded_at, run_id, batch_from, batch_to)
    VALUES ('2022-11-01', '2026-11-01 05:00', @old, '2022-11-01', '2022-11-01'),
           ('2023-06-15', '2026-11-01 05:00', @old, '2023-06-15', '2023-06-15'),
           ('2025-01-10', '2026-11-01 05:00', @old, '2025-01-10', '2025-01-10');

    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           payment_method_id, payer_type_id, concession_type_id, local_group_id, contact_country_id, contact_region,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #Before
    FROM Layercake.silv_daily_count_detail;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2023', 'Renewal', 'Standard', '2022-11-01', N'D1', 2, 0, 0, 0, 1, 1, 1, 2023, 'Q1', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced'),
           (3, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'D2', 2023, '2023-06-15', '2023-06-15', N'Fully Paid');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           payment_method_id, payer_type_id, concession_type_id, local_group_id, contact_country_id, contact_region,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #Actual
    FROM Layercake.silv_daily_count_adjustment;

    SELECT v.run_id, v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id, v.local_group_id, v.contact_country_id, v.contact_region,
           v.active_count_change, v.paid_count_change, v.paid_count_event_change, v.event_join_count_change,
           v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #Expected
    FROM (VALUES
        (@r1, CAST('2022-11-01' AS date), 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK', 0, 0, 1, 0, 1, 0, 0),
        (@r1, '2023-06-15', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK', 0, 0, 1, 0, 0, 0, 0),
        (@r1, '2023-06-15', 'UK', 2, 2, 'election', 1, 0, 0, 0, 0, 2, 'UK', 0, 1, 0, 0, 0, 0, 0),
        (@r1, '2025-01-10', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK', 0, 0, 1, 0, 1, 0, 0)
    ) AS v(run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           payment_method_id, payer_type_id, concession_type_id, local_group_id, contact_country_id, contact_region,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT x.[date], x.region, x.country_id, x.gender_id, x.grade, x.membership_status_id,
           x.payment_method_id, x.payer_type_id, x.concession_type_id, x.local_group_id, x.contact_country_id, x.contact_region
    INTO #Mismatch
    FROM (
        SELECT b.[date], b.region, b.country_id, b.gender_id, b.grade, b.membership_status_id,
               b.payment_method_id, b.payer_type_id, b.concession_type_id, b.local_group_id, b.contact_country_id, b.contact_region,
               b.active_count AS m1, b.paid_count AS m2, b.paid_count_event AS m3, b.event_join_count AS m4,
               b.event_renewal_count AS m5, b.event_readmission_count AS m6, b.event_lapse_count AS m7
        FROM #Before AS b
        UNION ALL
        SELECT a.[date], a.region, a.country_id, a.gender_id, a.grade, a.membership_status_id,
               a.payment_method_id, a.payer_type_id, a.concession_type_id, a.local_group_id, a.contact_country_id, a.contact_region,
               a.active_count_change, a.paid_count_change, a.paid_count_event_change, a.event_join_count_change,
               a.event_renewal_count_change, a.event_readmission_count_change, a.event_lapse_count_change
        FROM Layercake.silv_daily_count_adjustment AS a
        WHERE a.run_id = @r1
        UNION ALL
        SELECT d.[date], d.region, d.country_id, d.gender_id, d.grade, d.membership_status_id,
               d.payment_method_id, d.payer_type_id, d.concession_type_id, d.local_group_id, d.contact_country_id, d.contact_region,
               -d.active_count, -d.paid_count, -d.paid_count_event, -d.event_join_count,
               -d.event_renewal_count, -d.event_readmission_count, -d.event_lapse_count
        FROM Layercake.silv_daily_count_detail AS d
    ) AS x
    GROUP BY x.[date], x.region, x.country_id, x.gender_id, x.grade, x.membership_status_id,
             x.payment_method_id, x.payer_type_id, x.concession_type_id, x.local_group_id, x.contact_country_id, x.contact_region
    HAVING SUM(x.m1) <> 0 OR SUM(x.m2) <> 0 OR SUM(x.m3) <> 0 OR SUM(x.m4) <> 0
        OR SUM(x.m5) <> 0 OR SUM(x.m6) <> 0 OR SUM(x.m7) <> 0;

    EXEC tSQLt.AssertEmptyTable '#Mismatch';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-020 a change to segment columns on events alone writes no adjustment and no daily change]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT * INTO #BeforeDetail FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #BeforeDaily FROM Layercake.silv_daily_count;

    -- D2's CY2025 Renewal: payment method Card (3) becomes Direct Debit (1), with new amounts; no count input changes.
    UPDATE Layercake.silv_membership_events
    SET payment_method_id = 1, payment_method_carried = 0, payer_type_id = 1, payer_type_carried = 0,
        subs_amount_gbp = 120.0000, invoiced_subtotal_gbp = 120.0000, amount_status = 'Invoiced'
    WHERE event_id = 1;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_daily_count_adjustment';

    SELECT * INTO #AfterDetail FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #AfterDaily FROM Layercake.silv_daily_count;

    EXEC tSQLt.AssertEqualsTable '#BeforeDetail', '#AfterDetail';
    EXEC tSQLt.AssertEqualsTable '#BeforeDaily', '#AfterDaily';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-021 the first adjusting run of four keeps its rows unchanged after the fourth]
AS
BEGIN
    DECLARE @r0 uniqueidentifier = NEWID(), @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(),
            @r3 uniqueidentifier = NEWID(), @r4 uniqueidentifier = NEWID();
    DECLARE @runs int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r0;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT * INTO #FirstRunRowsThen FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r1;

    UPDATE Layercake.silv_membership_events SET event_date = '2025-01-11' WHERE event_id = 2;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    UPDATE Layercake.silv_member_profile SET retirement_date = '2025-01-09' WHERE contact_no = N'D1';
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3;

    DELETE FROM Layercake.silv_membership_events WHERE event_id = 2;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r4;

    SELECT @runs = COUNT(DISTINCT run_id) FROM Layercake.silv_daily_count_adjustment;
    EXEC tSQLt.AssertEquals 4, @runs;

    SELECT * INTO #FirstRunRowsNow FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r1;
    EXEC tSQLt.AssertEqualsTable '#FirstRunRowsThen', '#FirstRunRowsNow';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-022 no adjustment row written by the load has a NULL in any column]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID();
    DECLARE @rows int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    UPDATE Layercake.silv_member_profile SET retirement_date = '2025-01-09' WHERE contact_no = N'D1';
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3;

    SELECT @rows = COUNT(*) FROM Layercake.silv_daily_count_adjustment;
    EXEC tSQLt.AssertEquals 8, @rows;

    SELECT adjustment_id
    INTO #RowsWithNull
    FROM Layercake.silv_daily_count_adjustment
    WHERE adjustment_id IS NULL OR run_id IS NULL OR load_id IS NULL OR written_at IS NULL OR [date] IS NULL
       OR region IS NULL OR country_id IS NULL OR gender_id IS NULL OR grade IS NULL OR membership_status_id IS NULL
       OR active_count_change IS NULL OR paid_count_change IS NULL OR paid_count_event_change IS NULL
       OR event_join_count_change IS NULL OR event_renewal_count_change IS NULL
       OR event_readmission_count_change IS NULL OR event_lapse_count_change IS NULL;

    EXEC tSQLt.AssertEmptyTable '#RowsWithNull';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-023 two runs changing the same cell write one row each and never two for one run and cell]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID();

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    UPDATE Layercake.silv_membership_events SET event_date = '2025-01-11' WHERE event_id = 2;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3;

    SELECT run_id, [date], region, country_id, gender_id, grade, membership_status_id
    INTO #Duplicates
    FROM Layercake.silv_daily_count_adjustment
    GROUP BY run_id, [date], region, country_id, gender_id, grade, membership_status_id
    HAVING COUNT(*) > 1;

    EXEC tSQLt.AssertEmptyTable '#Duplicates';

    SELECT run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #Actual
    FROM Layercake.silv_daily_count_adjustment;

    SELECT v.run_id, v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count_change, v.paid_count_change, v.paid_count_event_change, v.event_join_count_change,
           v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #Expected
    FROM (VALUES
        (@r2, CAST('2025-01-10' AS date), 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 1, 0, 0),
        (@r2, '2025-01-11', 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 0, 0, 0),
        (@r3, '2025-01-10', 'UK', 1, 1, 'election', 1, 0, 0, -1, 0, -1, 0, 0),
        (@r3, '2025-01-11', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 0, 0)
    ) AS v(run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-024 the review view lists the retirement date move as Practising -1 and Retired +1]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    DELETE FROM Layercake.ref_date_spine;
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2024-11-30', 2025, 'Q1'), ('2024-12-01', 2025, 'Q1'), ('2025-01-14', 2025, 'Q2'), ('2025-01-15', 2025, 'Q2');

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (3, N'T5', '2015-01-01', NULL, 2015, 'election', 'UK', 2);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'T5', 3, 1, '2025-01-15');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    UPDATE Layercake.silv_member_profile SET retirement_date = '2024-12-01' WHERE contact_no = N'T5';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT region, country_id, gender_id, grade, membership_status_id, measure_name, change_value
    INTO #Actual
    FROM Layercake.vw_silv_daily_count_adjustment_review
    WHERE run_id = @r2 AND [date] = '2024-12-01';

    SELECT v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.measure_name, v.change_value
    INTO #Expected
    FROM (VALUES
        ('UK', 3, 1, 'election', 1, 'active_count', -1),
        ('UK', 3, 1, 'election', 2, 'active_count', 1)
    ) AS v(region, country_id, gender_id, grade, membership_status_id, measure_name, change_value);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-025 figures as known at a time after the last adjustment equal the stored daily counts]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID();
    DECLARE @t datetime2(3);
    DECLARE @adjustments int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 3, 0, 1, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    UPDATE Layercake.silv_member_profile SET retirement_date = '2025-01-09' WHERE contact_no = N'D1';
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3;

    SELECT @adjustments = COUNT(*) FROM Layercake.silv_daily_count_adjustment;
    EXEC tSQLt.AssertEquals 8, @adjustments;

    SET @t = DATEADD(SECOND, 1, SYSDATETIME());

    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #StoredDetail
    FROM Layercake.silv_daily_count_detail;

    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #KnownDetail
    FROM Layercake.fn_silv_daily_count_detail_as_known_at('2020-10-01', '2025-12-31', @t);

    SELECT [date], region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #StoredDaily
    FROM Layercake.silv_daily_count;

    SELECT [date], region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #KnownDaily
    FROM Layercake.fn_silv_daily_count_as_known_at('2020-10-01', '2025-12-31', @t);

    EXEC tSQLt.AssertEqualsTable '#StoredDetail', '#KnownDetail';
    EXEC tSQLt.AssertEqualsTable '#StoredDaily', '#KnownDaily';
END;
GO
CREATE PROCEDURE test_MOD022.[test TC-022-026 a completed run records each contact in the input basis with its earliest affected date]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();

    -- D7 first appears on 2024-11-05 (CY2025) as a Candidate who joined that day.
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (9, N'D7', '2024-11-05', NULL, 2025, 'enrolment', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D7', 8, 1, NULL);
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried,
         payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (7, N'JN:D7', 'Join', 'Standard', '2024-11-05', N'D7', 1, 0, 0, 0, 8, 1, 0, 2025, 'Q1', 3, 0, 1, 0, 0, 0, 50.0000, 50.0000, 'Invoiced');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT input_key, earliest_affected_date, run_id
    INTO #Actual
    FROM Layercake.etl_daily_count_input_basis
    WHERE input_name = 'contact';

    SELECT CAST(v.input_key AS nvarchar(200)) AS input_key, v.earliest_affected_date, v.run_id
    INTO #Expected
    FROM (VALUES
        (N'D1', CAST('2020-10-01' AS date), @r1),
        (N'D2', '2020-10-01', @r1),
        (N'D7', '2024-10-01', @r1)
    ) AS v(input_key, earliest_affected_date, run_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
