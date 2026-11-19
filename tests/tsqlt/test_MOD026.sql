EXEC tSQLt.NewTestClass 'test_MOD026';
GO

CREATE PROCEDURE test_MOD026.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_loaded', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_pending_rebuild', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_input_basis', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_contact', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_state_range', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_payment', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_event', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_cell_contacts', @Defaults = 1;
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
    EXEC tSQLt.FakeTable 'Layercake.fact_daily_member_count_detail', @Identity = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_date';
    EXEC tSQLt.FakeTable 'Layercake.dim_membership_grade';

    INSERT INTO Layercake.silv_ref_membership_status (id, status_name)
    VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');
    INSERT INTO Layercake.silv_ref_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');
    INSERT INTO Layercake.dim_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2021, '2020-10-01', '2021-09-30', '2021-06-01'),
           (2022, '2021-10-01', '2022-09-30', '2022-06-01'),
           (2023, '2022-10-01', '2023-09-30', '2023-06-01'),
           (2024, '2023-10-01', '2024-09-30', '2024-06-01'),
           (2025, '2024-10-01', '2025-09-30', '2025-06-01');

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2025-01-09', 2025, 'Q2'), ('2025-01-10', 2025, 'Q2'), ('2025-01-11', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2025-01-09', 2025, 'Q2'), (2, '2025-01-10', 2025, 'Q2'), (3, '2025-01-11', 2025, 'Q2');

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'D1', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (2, N'D2', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D1', 1, 1, NULL), (N'D2', 2, 2, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'D2', 2025, '2024-10-20', '2024-10-20', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, country_id, gender_id,
         membership_status_id, campaign_year, campaign_quarter, payment_method_id, payer_type_id,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1, N'RN:D2:2025', 'Renewal', 'Standard', '2024-10-20', N'D2', 2, 2, 2, 1, 2025, 'Q1', 3, 1, 100.0000, 100.0000, 'Invoiced');
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-001 changes to three contacts log 3 contacts recomputed and the normal path]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (11, N'L1', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (12, N'G1', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'L1', 14, 1, NULL), (N'G1', 15, 1, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'L1', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (11, N'RN:L1:2025', 'Renewal', 'Standard', '2024-10-15', N'L1', 2025, 'Q1');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2025, 'Q2'),
           (12, N'LP:L1:2025', 'Lapse', 'Standard', '2025-01-10', N'L1', 2025, 'Q2');
    UPDATE Layercake.silv_member_state_ranges SET valid_to = '2025-01-10' WHERE id = 11;
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (13, N'L1', '2025-01-10', NULL, 2025, 'lapse', 'UK', 2);
    UPDATE Layercake.silv_member_profile SET country_id = 16 WHERE contact_no = N'G1';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 3), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 sub-steps';

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_run2 FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_run2 FROM Layercake.silv_daily_count;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_full FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_full FROM Layercake.silv_daily_count;
    EXEC tSQLt.AssertEqualsTable '#detail_full', '#detail_run2', 'detail after the normal run differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_run2', 'daily after the normal run differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences the normal run left';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-002 a same-day rerun with no source change recomputes 0 contacts and changes nothing]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2025, 'Q2');
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;

    SELECT * INTO #detail_before FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_before FROM Layercake.silv_daily_count;
    SELECT * INTO #fact_before FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r3;

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r3 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 0), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 3 sub-steps';

    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'run 3 wrote adjustment rows';

    SELECT * INTO #detail_after FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_after FROM Layercake.silv_daily_count;
    SELECT * INTO #fact_after FROM Layercake.fact_daily_member_count_detail;
    EXEC tSQLt.AssertEqualsTable '#detail_before', '#detail_after', 'detail changed';
    EXEC tSQLt.AssertEqualsTable '#daily_before', '#daily_after', 'daily changed';
    EXEC tSQLt.AssertEqualsTable '#fact_before', '#fact_after', 'gold fact changed';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-003 a new contact N1 with a Join on 2023-05-10 gets its cells and equals a full recompute]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2023-05-09', 2023, 'Q3'), ('2023-05-10', 2023, 'Q3');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (11, '2023-05-09', 2023, 'Q3'), (12, '2023-05-10', 2023, 'Q3');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (21, N'N1', '2023-05-10', NULL, 2023, 'enrolment', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'N1', 11, 1, NULL);
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (21, N'JN:N1', 'Join', 'Standard', '2023-05-10', N'N1', 2023, 'Q3');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event, v.j AS event_join_count,
           v.r AS event_renewal_count, v.rd AS event_readmission_count, v.l AS event_lapse_count
    INTO #expected
    FROM (VALUES ('2023-05-10', 'UK', 11, 1, 'enrolment', 0, 1, 0, 1, 1, 0, 0, 0),
                 ('2025-01-09', 'UK', 11, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 11, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 11, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual FROM Layercake.silv_daily_count_detail WHERE country_id = 11;
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'N1 detail rows';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count_change, v.p AS paid_count_change, v.pe AS paid_count_event_change, v.j AS event_join_count_change,
           v.r AS event_renewal_count_change, v.rd AS event_readmission_count_change, v.l AS event_lapse_count_change
    INTO #adj_expected
    FROM (VALUES ('2023-05-10', 'UK', 11, 1, 'enrolment', 0, 1, 0, 1, 1, 0, 0, 0),
                 ('2025-01-09', 'UK', 11, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 11, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 11, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #adj_actual FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'run 2 adjustment rows';

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 1), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 sub-steps';

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_run2 FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_run2 FROM Layercake.silv_daily_count;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_run2 FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r3;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_full FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;
    EXEC tSQLt.AssertEqualsTable '#detail_full', '#detail_run2', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_run2', 'daily differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_run2', 'gold fact differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences the normal run left';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-004 a removed contact R1 loses its cells snapshot and basis rows and equals a full recompute]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2021-01-14', 2021, 'Q2'), ('2021-01-15', 2021, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (11, '2021-01-14', 2021, 'Q2'), (12, '2021-01-15', 2021, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (21, N'R1', '2021-01-15', NULL, 2021, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'R1', 12, 1, NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    DELETE FROM Layercake.silv_member_state_ranges WHERE contact_no = N'R1';
    DELETE FROM Layercake.silv_member_profile WHERE contact_no = N'R1';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT [date], region, country_id, gender_id, grade, membership_status_id
    INTO #r1_cells FROM Layercake.silv_daily_count_detail WHERE country_id = 12;
    EXEC tSQLt.AssertEmptyTable '#r1_cells', 'R1 still has detail cells';
    SELECT [date], region, country_id, gender_id, grade, membership_status_id
    INTO #r1_counts FROM Layercake.etl_daily_count_cell_contacts WHERE country_id = 12;
    EXEC tSQLt.AssertEmptyTable '#r1_counts', 'R1 still has cell contact counts';
    SELECT contact_no INTO #r1_snapshot FROM Layercake.etl_daily_count_applied_contact WHERE contact_no = N'R1';
    EXEC tSQLt.AssertEmptyTable '#r1_snapshot', 'R1 still has a snapshot row';
    SELECT input_key INTO #r1_basis FROM Layercake.etl_daily_count_input_basis WHERE input_name = 'contact' AND input_key = N'R1';
    EXEC tSQLt.AssertEmptyTable '#r1_basis', 'R1 still has a basis row';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count_change, v.p AS paid_count_change, v.pe AS paid_count_event_change, v.j AS event_join_count_change,
           v.r AS event_renewal_count_change, v.rd AS event_readmission_count_change, v.l AS event_lapse_count_change
    INTO #adj_expected
    FROM (VALUES ('2021-01-15', 'UK', 12, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 12, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 12, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 12, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #adj_actual FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'run 2 adjustment rows';

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 1), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 sub-steps';

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_run2 FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_run2 FROM Layercake.silv_daily_count;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_run2 FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r3;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_full FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;
    EXEC tSQLt.AssertEqualsTable '#detail_full', '#detail_run2', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_run2', 'daily differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_run2', 'gold fact differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences the normal run left';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-005 a backdated enrolment for E1 on 2021-02-01 raises active_count from that date to the run date only]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;
    DECLARE @today date = CAST(SYSDATETIME() AS date);
    DECLARE @cy int = YEAR(@today) + CASE WHEN MONTH(@today) >= 10 THEN 1 ELSE 0 END;
    DECLARE @q char(2) = CASE WHEN MONTH(@today) >= 10 THEN 'Q1' WHEN MONTH(@today) <= 3 THEN 'Q2' WHEN MONTH(@today) <= 6 THEN 'Q3' ELSE 'Q4' END;
    DECLARE @today_text char(10) = CONVERT(char(10), @today, 23);

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    SELECT v.y, DATEFROMPARTS(v.y - 1, 10, 1), DATEFROMPARTS(v.y, 9, 30), DATEFROMPARTS(v.y, 6, 1)
    FROM (VALUES (2026), (2027), (2028), (2029)) AS v(y)
    WHERE v.y <= @cy;
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2021-01-31', 2021, 'Q2'), ('2021-02-01', 2021, 'Q2'), (@today, @cy, @q);
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (11, '2021-01-31', 2021, 'Q2'), (12, '2021-02-01', 2021, 'Q2'), (13, @today, @cy, @q);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (21, N'E1', '2021-02-01', NULL, 2021, 'enrolment', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'E1', 13, 1, NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event, v.j AS event_join_count,
           v.r AS event_renewal_count, v.rd AS event_readmission_count, v.l AS event_lapse_count
    INTO #expected
    FROM (VALUES ('2021-02-01', 'UK', 13, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 13, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 13, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 13, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0),
                 (@today_text, 'UK', 13, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual FROM Layercake.silv_daily_count_detail WHERE country_id = 13;
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'E1 detail rows (none on 2021-01-31)';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count_change, v.p AS paid_count_change, v.pe AS paid_count_event_change, v.j AS event_join_count_change,
           v.r AS event_renewal_count_change, v.rd AS event_readmission_count_change, v.l AS event_lapse_count_change
    INTO #adj_expected
    FROM (VALUES ('2021-02-01', 'UK', 13, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 13, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 13, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 13, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0),
                 (@today_text, 'UK', 13, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #adj_actual FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'run 2 adjustment rows';

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 1), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 sub-steps';

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_run2 FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_run2 FROM Layercake.silv_daily_count;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_run2 FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r3;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_full FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;
    EXEC tSQLt.AssertEqualsTable '#detail_full', '#detail_run2', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_run2', 'daily differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_run2', 'gold fact differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences the normal run left';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-006 a Lapse for L1 on 2024-02-10 moves its later days to the lapse cell and equals a full recompute]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2024-02-09', 2024, 'Q2'), ('2024-02-10', 2024, 'Q2'), ('2024-02-11', 2024, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (11, '2024-02-09', 2024, 'Q2'), (12, '2024-02-10', 2024, 'Q2'), (13, '2024-02-11', 2024, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (21, N'L1', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'L1', 14, 1, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'L1', 2024, '2023-10-15', '2023-10-15', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (21, N'RN:L1:2024', 'Renewal', 'Standard', '2023-10-15', N'L1', 2024, 'Q1');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    UPDATE Layercake.silv_member_state_ranges SET valid_to = '2024-02-10' WHERE id = 21;
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (22, N'L1', '2024-02-10', NULL, 2024, 'lapse', 'UK', 2);
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (22, N'LP:L1:2024', 'Lapse', 'Standard', '2024-02-10', N'L1', 2024, 'Q2');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event, v.j AS event_join_count,
           v.r AS event_renewal_count, v.rd AS event_readmission_count, v.l AS event_lapse_count
    INTO #expected
    FROM (VALUES ('2024-02-09', 'UK', 14, 1, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2024-02-10', 'UK', 14, 1, 'lapse', 0, 0, 1, 1, 0, 0, 0, 1),
                 ('2024-02-11', 'UK', 14, 1, 'lapse', 0, 0, 1, 1, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual FROM Layercake.silv_daily_count_detail WHERE country_id = 14 AND [date] < '2025-01-01';
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'L1 detail rows in CY2024';

    SELECT [date], grade INTO #late_election
    FROM Layercake.silv_daily_count_detail
    WHERE country_id = 14 AND grade = 'election' AND [date] >= '2024-02-10';
    EXEC tSQLt.AssertEmptyTable '#late_election', 'L1 still sits in the election cell from 2024-02-10';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count_change, v.p AS paid_count_change, v.pe AS paid_count_event_change, v.j AS event_join_count_change,
           v.r AS event_renewal_count_change, v.rd AS event_readmission_count_change, v.l AS event_lapse_count_change
    INTO #adj_expected
    FROM (VALUES ('2024-02-10', 'UK', 14, 1, 'election', 1, -1, -1, -1, 0, 0, 0, 0),
                 ('2024-02-10', 'UK', 14, 1, 'lapse', 0, 0, 1, 1, 0, 0, 0, 1),
                 ('2024-02-11', 'UK', 14, 1, 'election', 1, -1, -1, -1, 0, 0, 0, 0),
                 ('2024-02-11', 'UK', 14, 1, 'lapse', 0, 0, 1, 1, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 14, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 14, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 14, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #adj_actual FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'run 2 adjustment rows';

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 1), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 sub-steps';

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_run2 FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_run2 FROM Layercake.silv_daily_count;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_run2 FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r3;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_full FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;
    EXEC tSQLt.AssertEqualsTable '#detail_full', '#detail_run2', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_run2', 'daily differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_run2', 'gold fact differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences the normal run left';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-007 a Renewal for D1 on 2025-01-10 raises its event counts from that date and equals a full recompute]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2025, 'Q2');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event, v.j AS event_join_count,
           v.r AS event_renewal_count, v.rd AS event_readmission_count, v.l AS event_lapse_count
    INTO #expected
    FROM (VALUES ('2025-01-09', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 1, 0, 0),
                 ('2025-01-11', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual FROM Layercake.silv_daily_count_detail;
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'detail rows';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count_change, v.p AS paid_count_change, v.pe AS paid_count_event_change, v.j AS event_join_count_change,
           v.r AS event_renewal_count_change, v.rd AS event_readmission_count_change, v.l AS event_lapse_count_change
    INTO #adj_expected
    FROM (VALUES ('2025-01-10', 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 1, 0, 0),
                 ('2025-01-11', 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #adj_actual FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'run 2 adjustment rows';

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 1), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 sub-steps';

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_run2 FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_run2 FROM Layercake.silv_daily_count;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_run2 FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r3;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_full FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;
    EXEC tSQLt.AssertEqualsTable '#detail_full', '#detail_run2', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_run2', 'daily differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_run2', 'gold fact differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences the normal run left';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-008 G1 country 1 to 2 moves its whole history out of a shared cell with -1 and +1 per loaded date]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2020-10-01', 2021, 'Q1');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (11, '2020-10-01', 2021, 'Q1');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (21, N'G1', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'G1', 1, 1, NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    UPDATE Layercake.silv_member_profile SET country_id = 2 WHERE contact_no = N'G1';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event, v.j AS event_join_count,
           v.r AS event_renewal_count, v.rd AS event_readmission_count, v.l AS event_lapse_count
    INTO #expected
    FROM (VALUES ('2020-10-01', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2020-10-01', 'UK', 2, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 2, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 2, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 2, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual FROM Layercake.silv_daily_count_detail WHERE gender_id = 1;
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'gender 1 detail rows';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count_change, v.p AS paid_count_change, v.pe AS paid_count_event_change, v.j AS event_join_count_change,
           v.r AS event_renewal_count_change, v.rd AS event_readmission_count_change, v.l AS event_lapse_count_change
    INTO #adj_expected
    FROM (VALUES ('2020-10-01', 'UK', 1, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 1, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 1, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2020-10-01', 'UK', 2, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 2, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 2, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 2, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #adj_actual FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'run 2 adjustment rows';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.c AS contact_count
    INTO #cells_expected
    FROM (VALUES ('2020-10-01', 'UK', 1, 1, 'election', 1, 1), ('2025-01-09', 'UK', 1, 1, 'election', 1, 1),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 1), ('2025-01-11', 'UK', 1, 1, 'election', 1, 1),
                 ('2020-10-01', 'UK', 2, 1, 'election', 1, 1), ('2025-01-09', 'UK', 2, 1, 'election', 1, 1),
                 ('2025-01-10', 'UK', 2, 1, 'election', 1, 1), ('2025-01-11', 'UK', 2, 1, 'election', 1, 1))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, c);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id, contact_count
    INTO #cells_actual FROM Layercake.etl_daily_count_cell_contacts WHERE gender_id = 1;
    EXEC tSQLt.AssertEqualsTable '#cells_expected', '#cells_actual', 'cell contact counts for gender 1';

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 1), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 sub-steps';

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_run2 FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_run2 FROM Layercake.silv_daily_count;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_run2 FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r3;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_full FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;
    EXEC tSQLt.AssertEqualsTable '#detail_full', '#detail_run2', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_run2', 'daily differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_run2', 'gold fact differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences the normal run left';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-009 G2 gender 1 to 2 moves every loaded date to the gender 2 cell and equals a full recompute]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (21, N'G2', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'G2', 21, 1, NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    UPDATE Layercake.silv_member_profile SET gender_id = 2 WHERE contact_no = N'G2';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event, v.j AS event_join_count,
           v.r AS event_renewal_count, v.rd AS event_readmission_count, v.l AS event_lapse_count
    INTO #expected
    FROM (VALUES ('2025-01-09', 'UK', 21, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 21, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 21, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual FROM Layercake.silv_daily_count_detail WHERE country_id = 21;
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'G2 detail rows';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count_change, v.p AS paid_count_change, v.pe AS paid_count_event_change, v.j AS event_join_count_change,
           v.r AS event_renewal_count_change, v.rd AS event_readmission_count_change, v.l AS event_lapse_count_change
    INTO #adj_expected
    FROM (VALUES ('2025-01-09', 'UK', 21, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 21, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 21, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 21, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 21, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 21, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #adj_actual FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'run 2 adjustment rows';

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 1), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 sub-steps';

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_run2 FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_run2 FROM Layercake.silv_daily_count;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_run2 FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r3;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_full FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;
    EXEC tSQLt.AssertEqualsTable '#detail_full', '#detail_run2', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_run2', 'daily differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_run2', 'gold fact differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences the normal run left';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-010 T5 retirement date 2025-01-15 to 2024-12-01 moves those days to Retired and equals a full recompute]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2024-11-30', 2025, 'Q1'), ('2024-12-01', 2025, 'Q1'), ('2025-01-14', 2025, 'Q2'), ('2025-01-15', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (11, '2024-11-30', 2025, 'Q1'), (12, '2024-12-01', 2025, 'Q1'), (13, '2025-01-14', 2025, 'Q2'), (14, '2025-01-15', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (21, N'T5', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'T5', 31, 1, '2025-01-15');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    UPDATE Layercake.silv_member_profile SET retirement_date = '2024-12-01' WHERE contact_no = N'T5';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event, v.j AS event_join_count,
           v.r AS event_renewal_count, v.rd AS event_readmission_count, v.l AS event_lapse_count
    INTO #expected
    FROM (VALUES ('2024-11-30', 'UK', 31, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2024-12-01', 'UK', 31, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 31, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 31, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 31, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-14', 'UK', 31, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-15', 'UK', 31, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual FROM Layercake.silv_daily_count_detail WHERE country_id = 31;
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'T5 detail rows';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count_change, v.p AS paid_count_change, v.pe AS paid_count_event_change, v.j AS event_join_count_change,
           v.r AS event_renewal_count_change, v.rd AS event_readmission_count_change, v.l AS event_lapse_count_change
    INTO #adj_expected
    FROM (VALUES ('2024-12-01', 'UK', 31, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2024-12-01', 'UK', 31, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 31, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 31, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 31, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 31, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 31, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 31, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-14', 'UK', 31, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-14', 'UK', 31, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #adj_actual FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'run 2 adjustment rows';

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 1), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 sub-steps';

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_run2 FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_run2 FROM Layercake.silv_daily_count;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_run2 FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r3;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_full FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;
    EXEC tSQLt.AssertEqualsTable '#detail_full', '#detail_run2', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_run2', 'daily differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_run2', 'gold fact differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences the normal run left';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-011 V1 moving from enrolment to election on 2023-09-01 moves those days to election]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2023-08-31', 2023, 'Q4'), ('2023-09-01', 2023, 'Q4');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (11, '2023-08-31', 2023, 'Q4'), (12, '2023-09-01', 2023, 'Q4');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (21, N'V1', '2022-01-01', NULL, 2022, 'enrolment', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'V1', 41, 1, NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    UPDATE Layercake.silv_member_state_ranges SET valid_to = '2023-09-01' WHERE id = 21;
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (22, N'V1', '2023-09-01', NULL, 2023, 'election', 'UK', 2);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event, v.j AS event_join_count,
           v.r AS event_renewal_count, v.rd AS event_readmission_count, v.l AS event_lapse_count
    INTO #expected
    FROM (VALUES ('2023-08-31', 'UK', 41, 1, 'enrolment', 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2023-09-01', 'UK', 41, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 41, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 41, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 41, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual FROM Layercake.silv_daily_count_detail WHERE country_id = 41;
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'V1 detail rows';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count_change, v.p AS paid_count_change, v.pe AS paid_count_event_change, v.j AS event_join_count_change,
           v.r AS event_renewal_count_change, v.rd AS event_readmission_count_change, v.l AS event_lapse_count_change
    INTO #adj_expected
    FROM (VALUES ('2023-09-01', 'UK', 41, 1, 'enrolment', 0, -1, 0, 0, 0, 0, 0, 0),
                 ('2023-09-01', 'UK', 41, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 41, 1, 'enrolment', 0, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 41, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 41, 1, 'enrolment', 0, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 41, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 41, 1, 'enrolment', 0, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 41, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #adj_actual FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'run 2 adjustment rows';

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 1), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 sub-steps';

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_run2 FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_run2 FROM Layercake.silv_daily_count;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_run2 FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r3;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_full FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;
    EXEC tSQLt.AssertEqualsTable '#detail_full', '#detail_run2', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_run2', 'daily differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_run2', 'gold fact differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences the normal run left';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-012 cell E emptied by M1 moving country is removed from silver the cell counts and gold]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2022-03-01', 2022, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (11, '2022-03-01', 2022, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (21, N'M1', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'M1', 3, 2, NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    UPDATE Layercake.silv_member_profile SET country_id = 4 WHERE contact_no = N'M1';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;

    SELECT [date], region, country_id, gender_id, grade, membership_status_id
    INTO #cell_e_detail FROM Layercake.silv_daily_count_detail WHERE country_id = 3;
    EXEC tSQLt.AssertEmptyTable '#cell_e_detail', 'cell E (country 3) still in silv_daily_count_detail';
    SELECT [date], region, country_id, gender_id, grade, membership_status_id
    INTO #cell_e_counts FROM Layercake.etl_daily_count_cell_contacts WHERE country_id = 3;
    EXEC tSQLt.AssertEmptyTable '#cell_e_counts', 'cell E (country 3) still in etl_daily_count_cell_contacts';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event, v.j AS event_join_count,
           v.r AS event_renewal_count, v.rd AS event_readmission_count, v.l AS event_lapse_count
    INTO #expected
    FROM (VALUES ('2022-03-01', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2022-03-01', 'UK', 2, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2022-03-01', 'UK', 4, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual FROM Layercake.silv_daily_count_detail WHERE [date] = '2022-03-01';
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'detail rows on 2022-03-01';

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id,
           v.a AS ActiveMembers, v.p AS PaidMembers, v.pe AS PaidMembersEvent, v.j AS JoinEvents,
           v.r AS RenewalEvents, v.rd AS ReadmissionEvents, v.l AS LapseEvents
    INTO #fact_expected
    FROM (VALUES (11, 1, 1, 2, 1, 1, 0, 0, 0, 0, 0, 0),
                 (11, 2, 2, 2, 1, 1, 0, 0, 0, 0, 0, 0),
                 (11, 4, 2, 2, 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_actual FROM Layercake.fact_daily_member_count_detail WHERE date_id = 11;
    EXEC tSQLt.AssertEqualsTable '#fact_expected', '#fact_actual', 'gold fact rows on 2022-03-01';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count_change, v.p AS paid_count_change, v.pe AS paid_count_event_change, v.j AS event_join_count_change,
           v.r AS event_renewal_count_change, v.rd AS event_readmission_count_change, v.l AS event_lapse_count_change
    INTO #adj_expected
    FROM (VALUES ('2022-03-01', 'UK', 3, 2, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2022-03-01', 'UK', 4, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 3, 2, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 4, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 3, 2, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 4, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 3, 2, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 4, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #adj_actual FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'run 2 adjustment rows';

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 1), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 sub-steps';

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_run2 FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_run2 FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_run2 FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r3;

    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_full FROM Layercake.silv_daily_count_detail;
    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;
    EXEC tSQLt.AssertEqualsTable '#detail_full', '#detail_run2', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_run2', 'daily differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_run2', 'gold fact differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences the normal run left';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD026.[test TC-026-013 overlapping ranges for S9 fail a normal run naming S9 and writing nothing]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();
    DECLARE @failed bit = 0, @err_msg nvarchar(4000), @status varchar(10), @logged nvarchar(4000);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (21, N'S9', '2023-01-01', NULL, 2023, 'election', 'UK', 1),
           (22, N'S9', '2024-01-01', '2024-06-01', 2024, 'election', 'UK', 2);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'S9', 61, 1, NULL);

    SELECT * INTO #detail_before FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_before FROM Layercake.silv_daily_count;
    SELECT * INTO #adj_before FROM Layercake.silv_daily_count_adjustment;
    SELECT * INTO #loaded_before FROM Layercake.etl_daily_count_loaded;
    SELECT * INTO #basis_before FROM Layercake.etl_daily_count_input_basis;
    SELECT * INTO #applied_contact_before FROM Layercake.etl_daily_count_applied_contact;
    SELECT * INTO #applied_range_before FROM Layercake.etl_daily_count_applied_state_range;
    SELECT * INTO #cells_before FROM Layercake.etl_daily_count_cell_contacts;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;
    END TRY
    BEGIN CATCH
        SET @failed = 1;
        SET @err_msg = ERROR_MESSAGE();
    END CATCH;
    IF @failed = 0
        EXEC tSQLt.Fail 'usp_load_silv_daily_count did not fail on S9''s overlapping ranges';

    EXEC tSQLt.AssertLike '%S9%', @err_msg, 'the re-raised error does not name S9';
    SELECT @status = status, @logged = error_message
    FROM Layercake.etl_run_log
    WHERE run_id = @r2 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEqualsString 'Failed', @status, 'step status';
    EXEC tSQLt.AssertLike '%S9%', @logged, 'the logged error_message does not name S9';

    SELECT * INTO #detail_after FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_after FROM Layercake.silv_daily_count;
    SELECT * INTO #adj_after FROM Layercake.silv_daily_count_adjustment;
    SELECT * INTO #loaded_after FROM Layercake.etl_daily_count_loaded;
    SELECT * INTO #basis_after FROM Layercake.etl_daily_count_input_basis;
    SELECT * INTO #applied_contact_after FROM Layercake.etl_daily_count_applied_contact;
    SELECT * INTO #applied_range_after FROM Layercake.etl_daily_count_applied_state_range;
    SELECT * INTO #cells_after FROM Layercake.etl_daily_count_cell_contacts;
    EXEC tSQLt.AssertEqualsTable '#detail_before', '#detail_after', 'detail changed';
    EXEC tSQLt.AssertEqualsTable '#daily_before', '#daily_after', 'daily changed';
    EXEC tSQLt.AssertEqualsTable '#adj_before', '#adj_after', 'adjustment history changed';
    EXEC tSQLt.AssertEqualsTable '#loaded_before', '#loaded_after', 'loaded marks changed';
    EXEC tSQLt.AssertEqualsTable '#basis_before', '#basis_after', 'basis changed';
    EXEC tSQLt.AssertEqualsTable '#applied_contact_before', '#applied_contact_after', 'snapshot header changed';
    EXEC tSQLt.AssertEqualsTable '#applied_range_before', '#applied_range_after', 'snapshot ranges changed';
    EXEC tSQLt.AssertEqualsTable '#cells_before', '#cells_after', 'cell contact counts changed';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD026.[test TC-026-014 overlapping ranges for S9 fail a FullRebuild naming S9 and writing nothing]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();
    DECLARE @failed bit = 0, @err_msg nvarchar(4000), @status varchar(10), @logged nvarchar(4000);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (21, N'S9', '2023-01-01', NULL, 2023, 'election', 'UK', 1),
           (22, N'S9', '2024-01-01', '2024-06-01', 2024, 'election', 'UK', 2);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'S9', 61, 1, NULL);

    SELECT * INTO #detail_before FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_before FROM Layercake.silv_daily_count;
    SELECT * INTO #adj_before FROM Layercake.silv_daily_count_adjustment;
    SELECT * INTO #loaded_before FROM Layercake.etl_daily_count_loaded;
    SELECT * INTO #basis_before FROM Layercake.etl_daily_count_input_basis;
    SELECT * INTO #applied_contact_before FROM Layercake.etl_daily_count_applied_contact;
    SELECT * INTO #cells_before FROM Layercake.etl_daily_count_cell_contacts;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @FullRebuild = 1;
    END TRY
    BEGIN CATCH
        SET @failed = 1;
        SET @err_msg = ERROR_MESSAGE();
    END CATCH;
    IF @failed = 0
        EXEC tSQLt.Fail 'usp_load_silv_daily_count @FullRebuild = 1 did not fail on S9''s overlapping ranges';

    EXEC tSQLt.AssertLike '%S9%', @err_msg, 'the re-raised error does not name S9';
    SELECT @status = status, @logged = error_message
    FROM Layercake.etl_run_log
    WHERE run_id = @r2 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEqualsString 'Failed', @status, 'step status';
    EXEC tSQLt.AssertLike '%S9%', @logged, 'the logged error_message does not name S9';

    SELECT * INTO #detail_after FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_after FROM Layercake.silv_daily_count;
    SELECT * INTO #adj_after FROM Layercake.silv_daily_count_adjustment;
    SELECT * INTO #loaded_after FROM Layercake.etl_daily_count_loaded;
    SELECT * INTO #basis_after FROM Layercake.etl_daily_count_input_basis;
    SELECT * INTO #applied_contact_after FROM Layercake.etl_daily_count_applied_contact;
    SELECT * INTO #cells_after FROM Layercake.etl_daily_count_cell_contacts;
    EXEC tSQLt.AssertEqualsTable '#detail_before', '#detail_after', 'detail changed';
    EXEC tSQLt.AssertEqualsTable '#daily_before', '#daily_after', 'daily changed';
    EXEC tSQLt.AssertEqualsTable '#adj_before', '#adj_after', 'adjustment history changed';
    EXEC tSQLt.AssertEqualsTable '#loaded_before', '#loaded_after', 'loaded marks changed';
    EXEC tSQLt.AssertEqualsTable '#basis_before', '#basis_after', 'basis changed';
    EXEC tSQLt.AssertEqualsTable '#applied_contact_before', '#applied_contact_after', 'snapshot header changed';
    EXEC tSQLt.AssertEqualsTable '#cells_before', '#cells_after', 'cell contact counts changed';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-015 ranges that meet S10 and a zero-length range S11 pass the guard on normal and full runs]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @status varchar(10);

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2024-01-01', 2024, 'Q2'), ('2024-03-01', 2024, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (21, N'S10', '2023-01-01', '2024-01-01', 2023, 'enrolment', 'UK', 1),
           (22, N'S10', '2024-01-01', NULL, 2024, 'election', 'UK', 2),
           (23, N'S11', '2023-01-01', NULL, 2023, 'election', 'UK', 1),
           (24, N'S11', '2024-03-01', '2024-03-01', 2024, 'lapse', 'UK', 2);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'S10', 51, 1, NULL), (N'S11', 52, 1, NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT @status = status FROM Layercake.etl_run_log WHERE run_id = @r1 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEqualsString 'Success', @status, 'normal run status';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event, v.j AS event_join_count,
           v.r AS event_renewal_count, v.rd AS event_readmission_count, v.l AS event_lapse_count
    INTO #expected
    FROM (VALUES ('2024-01-01', 'UK', 51, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2024-03-01', 'UK', 51, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 51, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 51, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 51, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2024-01-01', 'UK', 52, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2024-03-01', 'UK', 52, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 52, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 52, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 52, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual_normal FROM Layercake.silv_daily_count_detail WHERE country_id IN (51, 52);
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual_normal', 'S10 and S11 rows after the normal run';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @FullRebuild = 1;

    SELECT @status = status FROM Layercake.etl_run_log WHERE run_id = @r2 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEqualsString 'Success', @status, 'full rebuild status';
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual_full FROM Layercake.silv_daily_count_detail WHERE country_id IN (51, 52);
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual_full', 'S10 and S11 rows after the full rebuild';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-016 RebuildFrom and FullRebuild log the full-recompute path and leave the correct history]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2025, 'Q2');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @RebuildFrom = '2025-01-01';

    SELECT 2 AS run_no, p.substep, p.rows_affected
    INTO #log_actual FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event, v.j AS event_join_count,
           v.r AS event_renewal_count, v.rd AS event_readmission_count, v.l AS event_lapse_count
    INTO #expected
    FROM (VALUES ('2025-01-09', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 1, 0, 0),
                 ('2025-01-11', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual FROM Layercake.silv_daily_count_detail;
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'detail after RebuildFrom';

    SELECT * INTO #detail_r2 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r2 FROM Layercake.silv_daily_count;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;

    INSERT INTO #log_actual (run_no, substep, rows_affected)
    SELECT 3, p.substep, p.rows_affected
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r3 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.run_no, v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (2, N'contacts_recomputed', 2), (2, N'full_recompute_path', 1),
                 (3, N'contacts_recomputed', 2), (3, N'full_recompute_path', 1)) AS v(run_no, substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'sub-steps of RebuildFrom (2) and FullRebuild (3)';

    SELECT * INTO #detail_r3 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r3 FROM Layercake.silv_daily_count;
    EXEC tSQLt.AssertEqualsTable '#detail_r2', '#detail_r3', 'FullRebuild changed the detail left by RebuildFrom';
    EXEC tSQLt.AssertEqualsTable '#daily_r2', '#daily_r3', 'FullRebuild changed the daily rows left by RebuildFrom';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'FullRebuild wrote adjustment rows';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-017 a changed ref_date_spine row on a loaded date makes the next run take the full-recompute path]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    UPDATE Layercake.ref_date_spine SET campaign_quarter = 'Q3' WHERE [date] = '2025-01-11';
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep = N'full_recompute_path';
    SELECT v.rows_affected INTO #log_expected FROM (VALUES (1)) AS v(rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'full_recompute_path after a spine change';

    SELECT * INTO #detail_r2 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r2 FROM Layercake.silv_daily_count;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    SELECT * INTO #detail_r3 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r3 FROM Layercake.silv_daily_count;
    EXEC tSQLt.AssertEqualsTable '#detail_r3', '#detail_r2', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_r3', '#daily_r2', 'daily differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-018 a changed ref_campaign_year_config row for CY2023 makes the next run take the full-recompute path]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    UPDATE Layercake.ref_campaign_year_config SET campaign_year_start = '2022-10-02' WHERE campaign_year = 2023;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep = N'full_recompute_path';
    SELECT v.rows_affected INTO #log_expected FROM (VALUES (1)) AS v(rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'full_recompute_path after a CY2023 config change';

    SELECT * INTO #detail_r2 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r2 FROM Layercake.silv_daily_count;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    SELECT * INTO #detail_r3 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r3 FROM Layercake.silv_daily_count;
    EXEC tSQLt.AssertEqualsTable '#detail_r3', '#detail_r2', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_r3', '#daily_r2', 'daily differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-019 a changed silv_ref_membership_status row makes the next run take the full-recompute path]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    UPDATE Layercake.silv_ref_membership_status SET status_name = 'Not applicable' WHERE id = 0;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep = N'full_recompute_path';
    SELECT v.rows_affected INTO #log_expected FROM (VALUES (1)) AS v(rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'full_recompute_path after a membership status change';

    SELECT * INTO #detail_r2 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r2 FROM Layercake.silv_daily_count;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    SELECT * INTO #detail_r3 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r3 FROM Layercake.silv_daily_count;
    EXEC tSQLt.AssertEqualsTable '#detail_r3', '#detail_r2', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_r3', '#daily_r2', 'daily differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-020 spine dates and a Campaign Year after the latest loaded date keep the normal path]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2026, '2025-10-01', '2026-09-30', '2026-05-01'),
           (2027, '2026-10-01', '2027-09-30', '2027-05-01'),
           (2028, '2027-10-01', '2028-09-30', '2028-05-01');
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2025-10-15', 2026, 'Q1'), ('2028-01-15', 2028, 'Q2');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2025, 'Q2');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 1), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 sub-steps';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count_change, v.p AS paid_count_change, v.pe AS paid_count_event_change, v.j AS event_join_count_change,
           v.r AS event_renewal_count_change, v.rd AS event_readmission_count_change, v.l AS event_lapse_count_change
    INTO #adj_expected
    FROM (VALUES ('2025-01-10', 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 1, 0, 0),
                 ('2025-01-11', 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #adj_actual FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'run 2 adjustment rows (none for the first-loaded 2025-10-15)';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event, v.j AS event_join_count,
           v.r AS event_renewal_count, v.rd AS event_readmission_count, v.l AS event_lapse_count
    INTO #expected
    FROM (VALUES ('2025-10-15', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-10-15', 'UK', 2, 2, 'election', 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual FROM Layercake.silv_daily_count_detail WHERE [date] >= '2025-10-01';
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'first-loaded 2025-10-15 rows and nothing for 2028-01-15';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-021 the first run after deployment takes the full path writes no adjustment and sets up the snapshot]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @n int, @status varchar(10);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    DELETE FROM Layercake.etl_daily_count_applied_contact;
    DELETE FROM Layercake.etl_daily_count_applied_state_range;
    DELETE FROM Layercake.etl_daily_count_applied_payment;
    DELETE FROM Layercake.etl_daily_count_applied_event;
    DELETE FROM Layercake.etl_daily_count_cell_contacts;

    SELECT * INTO #detail_before FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_before FROM Layercake.silv_daily_count;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT @status = status FROM Layercake.etl_run_log WHERE run_id = @r2 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEqualsString 'Success', @status, 'first run status';

    SELECT p.rows_affected
    INTO #path_r2
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep = N'full_recompute_path';
    SELECT v.rows_affected INTO #path_expected FROM (VALUES (1)) AS v(rows_affected);
    EXEC tSQLt.AssertEqualsTable '#path_expected', '#path_r2', 'the first run after deployment did not take the full path';

    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEquals 0, @n, 'the first run after deployment wrote adjustment rows';

    SELECT * INTO #detail_after FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_after FROM Layercake.silv_daily_count;
    EXEC tSQLt.AssertEqualsTable '#detail_before', '#detail_after', 'detail changed';
    EXEC tSQLt.AssertEqualsTable '#daily_before', '#daily_after', 'daily changed';

    SELECT v.contact_no INTO #snap_expected FROM (VALUES (N'D1'), (N'D2')) AS v(contact_no);
    SELECT contact_no INTO #snap_actual FROM Layercake.etl_daily_count_applied_contact;
    EXEC tSQLt.AssertEqualsTable '#snap_expected', '#snap_actual', 'snapshot contacts';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.c AS contact_count
    INTO #cells_expected
    FROM (VALUES ('2025-01-09', 'UK', 1, 1, 'election', 1, 1), ('2025-01-10', 'UK', 1, 1, 'election', 1, 1),
                 ('2025-01-11', 'UK', 1, 1, 'election', 1, 1), ('2025-01-09', 'UK', 2, 2, 'election', 1, 1),
                 ('2025-01-10', 'UK', 2, 2, 'election', 1, 1), ('2025-01-11', 'UK', 2, 2, 'election', 1, 1))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, c);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id, contact_count
    INTO #cells_actual FROM Layercake.etl_daily_count_cell_contacts;
    EXEC tSQLt.AssertEqualsTable '#cells_expected', '#cells_actual', 'cell contact counts';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3;
    SELECT p.substep, p.rows_affected
    INTO #log_r3
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r3 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_r3_expected
    FROM (VALUES (N'contacts_recomputed', 0), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_r3_expected', '#log_r3', 'the run after the first takes the normal path';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-022 the first run after deployment corrects drift in stored figures and records it]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    DELETE FROM Layercake.etl_daily_count_applied_contact;
    DELETE FROM Layercake.etl_daily_count_applied_state_range;
    DELETE FROM Layercake.etl_daily_count_applied_payment;
    DELETE FROM Layercake.etl_daily_count_applied_event;
    DELETE FROM Layercake.etl_daily_count_cell_contacts;
    UPDATE Layercake.silv_daily_count_detail SET active_count = 5 WHERE [date] = '2025-01-10' AND country_id = 2;
    UPDATE Layercake.silv_daily_count SET active_count = 6 WHERE [date] = '2025-01-10';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT p.rows_affected
    INTO #path_r2
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep = N'full_recompute_path';
    SELECT v.rows_affected INTO #path_expected FROM (VALUES (1)) AS v(rows_affected);
    EXEC tSQLt.AssertEqualsTable '#path_expected', '#path_r2', 'the first run after deployment did not take the full path';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count_change, v.p AS paid_count_change, v.pe AS paid_count_event_change, v.j AS event_join_count_change,
           v.r AS event_renewal_count_change, v.rd AS event_readmission_count_change, v.l AS event_lapse_count_change
    INTO #adj_expected
    FROM (VALUES ('2025-01-10', 'UK', 2, 2, 'election', 1, -4, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #adj_actual FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'drift adjustment rows';

    SELECT CAST(v.d AS date) AS [date], v.region, v.grade, v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event
    INTO #daily_expected
    FROM (VALUES ('2025-01-09', 'UK', 'election', 2, 1, 1), ('2025-01-10', 'UK', 'election', 2, 1, 1),
                 ('2025-01-11', 'UK', 'election', 2, 1, 1))
         AS v(d, region, grade, a, p, pe);
    SELECT [date], region, grade, active_count, paid_count, paid_count_event
    INTO #daily_actual FROM Layercake.silv_daily_count;
    EXEC tSQLt.AssertEqualsTable '#daily_expected', '#daily_actual', 'daily rows after the drift is corrected';

    SELECT CAST(v.d AS date) AS [date], v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event
    INTO #d2_expected
    FROM (VALUES ('2025-01-10', 1, 1, 1)) AS v(d, a, p, pe);
    SELECT [date], active_count, paid_count, paid_count_event
    INTO #d2_actual FROM Layercake.silv_daily_count_detail WHERE [date] = '2025-01-10' AND country_id = 2;
    EXEC tSQLt.AssertEqualsTable '#d2_expected', '#d2_actual', 'D2 on 2025-01-10 after the drift is corrected';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-023 the snapshot holds each contact inputs as last applied and only changed contacts are rewritten]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT v.contact_no, v.profile_found, v.country_id, v.gender_id, v.retirement_date, v.run_id
    INTO #contact_expected
    FROM (VALUES (N'D1', CAST(1 AS bit), 1, 1, CAST(NULL AS date), @r1),
                 (N'D2', CAST(1 AS bit), 2, 2, CAST(NULL AS date), @r1))
         AS v(contact_no, profile_found, country_id, gender_id, retirement_date, run_id);
    SELECT contact_no, profile_found, country_id, gender_id, retirement_date, run_id
    INTO #contact_actual FROM Layercake.etl_daily_count_applied_contact;
    EXEC tSQLt.AssertEqualsTable '#contact_expected', '#contact_actual', 'snapshot header after run 1';

    SELECT v.contact_no, CAST(v.valid_from AS date) AS valid_from, v.valid_to, v.grade, v.region
    INTO #range_expected
    FROM (VALUES (N'D1', '2015-01-01', CAST(NULL AS date), 'election', 'UK'),
                 (N'D2', '2015-01-01', CAST(NULL AS date), 'election', 'UK'))
         AS v(contact_no, valid_from, valid_to, grade, region);
    SELECT contact_no, valid_from, valid_to, grade, region
    INTO #range_actual FROM Layercake.etl_daily_count_applied_state_range;
    EXEC tSQLt.AssertEqualsTable '#range_expected', '#range_actual', 'snapshot ranges after run 1';

    SELECT v.contact_no, CAST(v.event_type AS varchar(20)) AS event_type, CAST(v.event_date AS date) AS event_date, v.campaign_year
    INTO #event_expected
    FROM (VALUES (N'D2', 'Renewal', '2024-10-20', 2025)) AS v(contact_no, event_type, event_date, campaign_year);
    SELECT contact_no, event_type, event_date, campaign_year
    INTO #event_actual FROM Layercake.etl_daily_count_applied_event;
    EXEC tSQLt.AssertEqualsTable '#event_expected', '#event_actual', 'snapshot events after run 1';

    UPDATE Layercake.silv_payment_events SET payment_date = '2025-01-10', renewal_date_adj = '2025-01-10' WHERE contact_no = N'D2';
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT v.contact_no, v.campaign_year, CAST(v.renewal_date_adj AS date) AS renewal_date_adj
    INTO #payment_expected
    FROM (VALUES (N'D2', 2025, '2025-01-10')) AS v(contact_no, campaign_year, renewal_date_adj);
    SELECT contact_no, campaign_year, renewal_date_adj
    INTO #payment_actual FROM Layercake.etl_daily_count_applied_payment;
    EXEC tSQLt.AssertEqualsTable '#payment_expected', '#payment_actual', 'snapshot payments after run 2';

    SELECT v.contact_no, v.run_id
    INTO #writer_expected
    FROM (VALUES (N'D1', @r1), (N'D2', @r2)) AS v(contact_no, run_id);
    SELECT contact_no, run_id INTO #writer_actual FROM Layercake.etl_daily_count_applied_contact;
    EXEC tSQLt.AssertEqualsTable '#writer_expected', '#writer_actual', 'run that last wrote each contact snapshot';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD026.[test TC-026-024 a normal run failing part way re-raises keeps the history consistent and the next run completes]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @r4 uniqueidentifier = NEWID();
    DECLARE @failed bit = 0, @err_no int, @status varchar(10), @n int;

    EXEC tSQLt.ApplyConstraint @TableName = 'Layercake.silv_daily_count_detail', @ConstraintName = 'pk_silv_daily_count_detail';
    EXEC tSQLt.ApplyConstraint @TableName = 'Layercake.silv_daily_count', @ConstraintName = 'pk_silv_daily_count';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-09', N'D1', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (6, N'D6', '2025-01-10', NULL, 2025, 'election', NULL, 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D6', 7, 1, NULL);

    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #detail_before FROM Layercake.silv_daily_count_detail;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @DailyCountBatchDays = 1;
    END TRY
    BEGIN CATCH
        SET @failed = 1;
        SET @err_no = ERROR_NUMBER();
        IF @err_no <> 515 THROW;
    END CATCH;
    IF @failed = 0
        EXEC tSQLt.Fail 'run 2 did not fail on D6''s NULL region';

    SELECT @status = status FROM Layercake.etl_run_log WHERE run_id = @r2 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEqualsString 'Failed', @status, 'run 2 step status';

    SELECT x.[date], x.region, x.country_id, x.gender_id, x.grade, x.membership_status_id,
           SUM(x.a) AS a, SUM(x.p) AS p, SUM(x.pe) AS pe, SUM(x.j) AS j, SUM(x.r) AS r, SUM(x.rd) AS rd, SUM(x.l) AS l
    INTO #recon_r2
    FROM (
        SELECT b.[date], b.region, b.country_id, b.gender_id, b.grade, b.membership_status_id,
               b.active_count AS a, b.paid_count AS p, b.paid_count_event AS pe, b.event_join_count AS j,
               b.event_renewal_count AS r, b.event_readmission_count AS rd, b.event_lapse_count AS l
        FROM #detail_before AS b
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
    HAVING SUM(x.a) <> 0 OR SUM(x.p) <> 0 OR SUM(x.pe) <> 0 OR SUM(x.j) <> 0 OR SUM(x.r) <> 0 OR SUM(x.rd) <> 0 OR SUM(x.l) <> 0;
    EXEC tSQLt.AssertEmptyTable '#recon_r2', 'stored before plus the failed run''s adjustments does not equal stored after';

    UPDATE Layercake.silv_member_state_ranges SET region = 'UK' WHERE id = 6;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3;

    SELECT @status = status FROM Layercake.etl_run_log WHERE run_id = @r3 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEqualsString 'Success', @status, 'run 3 step status';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a AS active_count, v.p AS paid_count, v.pe AS paid_count_event, v.j AS event_join_count,
           v.r AS event_renewal_count, v.rd AS event_readmission_count, v.l AS event_lapse_count
    INTO #expected
    FROM (VALUES ('2025-01-09', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 1, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 1, 1, 'election', 1, 1, 0, 1, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 2, 2, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 7, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 7, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #actual FROM Layercake.silv_daily_count_detail;
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'detail after the completing run';

    SELECT CAST(v.d AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.a, v.p, v.pe, v.j, v.r, v.rd, v.l
    INTO #adj_expected
    FROM (VALUES ('2025-01-09', 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 1, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 1, 1, 'election', 1, 0, 0, 1, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 7, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 7, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(d, region, country_id, gender_id, grade, membership_status_id, a, p, pe, j, r, rd, l);
    SELECT a.[date], a.region, a.country_id, a.gender_id, a.grade, a.membership_status_id,
           SUM(a.active_count_change) AS a, SUM(a.paid_count_change) AS p, SUM(a.paid_count_event_change) AS pe,
           SUM(a.event_join_count_change) AS j, SUM(a.event_renewal_count_change) AS r,
           SUM(a.event_readmission_count_change) AS rd, SUM(a.event_lapse_count_change) AS l
    INTO #adj_actual
    FROM Layercake.silv_daily_count_adjustment AS a
    WHERE a.run_id IN (@r2, @r3)
    GROUP BY a.[date], a.region, a.country_id, a.gender_id, a.grade, a.membership_status_id;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'adjustments of the failed and completing runs together';

    SELECT * INTO #detail_r3 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r3 FROM Layercake.silv_daily_count;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r4, @FullRebuild = 1;
    SELECT * INTO #detail_r4 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_r4 FROM Layercake.silv_daily_count;
    EXEC tSQLt.AssertEqualsTable '#detail_r4', '#detail_r3', 'detail differs from a full recompute';
    EXEC tSQLt.AssertEqualsTable '#daily_r4', '#daily_r3', 'daily differs from a full recompute';
    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r4;
    EXEC tSQLt.AssertEquals 0, @n, 'the full recompute found differences';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-025 figures as known at times before and after a normal run match the stored figures of that time]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();
    DECLARE @t1 datetime2(3), @t2 datetime2(3);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #stored_t1 FROM Layercake.silv_daily_count_detail;
    WAITFOR DELAY '00:00:00.050';
    SET @t1 = SYSDATETIME();
    WAITFOR DELAY '00:00:00.050';

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2025, 'Q2');
    UPDATE Layercake.silv_member_profile SET retirement_date = '2025-01-10' WHERE contact_no = N'D1';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;
    WAITFOR DELAY '00:00:00.050';
    SET @t2 = SYSDATETIME();

    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #known_t1
    FROM Layercake.fn_silv_daily_count_detail_as_known_at('2020-10-01', '2025-12-31', @t1)
    WHERE active_count <> 0 OR paid_count <> 0 OR paid_count_event <> 0 OR event_join_count <> 0
       OR event_renewal_count <> 0 OR event_readmission_count <> 0 OR event_lapse_count <> 0;
    EXEC tSQLt.AssertEqualsTable '#stored_t1', '#known_t1', 'figures as known at T1 differ from those stored at T1';

    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #stored_t2 FROM Layercake.silv_daily_count_detail;
    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #known_t2
    FROM Layercake.fn_silv_daily_count_detail_as_known_at('2020-10-01', '2025-12-31', @t2);
    EXEC tSQLt.AssertEqualsTable '#stored_t2', '#known_t2', 'figures as known at T2 differ from those stored now';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-026 every run logs one contacts_recomputed and one full_recompute_path sub-step for the speed check]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID();

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;

    SELECT CASE l.run_id WHEN @r1 THEN 1 WHEN @r2 THEN 2 ELSE 3 END AS run_no, p.substep, COUNT(*) AS n
    INTO #count_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id IN (@r1, @r2, @r3) AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path')
    GROUP BY CASE l.run_id WHEN @r1 THEN 1 WHEN @r2 THEN 2 ELSE 3 END, p.substep;
    SELECT v.run_no, v.substep, v.n
    INTO #count_expected
    FROM (VALUES (1, N'contacts_recomputed', 1), (1, N'full_recompute_path', 1),
                 (2, N'contacts_recomputed', 1), (2, N'full_recompute_path', 1),
                 (3, N'contacts_recomputed', 1), (3, N'full_recompute_path', 1)) AS v(run_no, substep, n);
    EXEC tSQLt.AssertEqualsTable '#count_expected', '#count_actual', 'sub-steps per run';

    SELECT CASE l.run_id WHEN @r2 THEN 2 ELSE 3 END AS run_no, p.substep, p.rows_affected
    INTO #value_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id IN (@r2, @r3) AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.run_no, v.substep, v.rows_affected
    INTO #value_expected
    FROM (VALUES (2, N'contacts_recomputed', 0), (2, N'full_recompute_path', 0),
                 (3, N'contacts_recomputed', 2), (3, N'full_recompute_path', 1)) AS v(run_no, substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#value_expected', '#value_actual', 'sub-step values for the normal (2) and full (3) runs';

    SELECT CASE l.run_id WHEN @r1 THEN 1 WHEN @r2 THEN 2 ELSE 3 END AS run_no, l.status,
           CASE WHEN l.started_at IS NOT NULL AND l.finished_at IS NOT NULL THEN 1 ELSE 0 END AS timed
    INTO #step_actual
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id IN (@r1, @r2, @r3) AND l.layer = 'silver' AND l.step_name = 'silv_daily_count';
    SELECT v.run_no, v.status, v.timed
    INTO #step_expected
    FROM (VALUES (1, 'Success', 1), (2, 'Success', 1), (3, 'Success', 1)) AS v(run_no, status, timed);
    EXEC tSQLt.AssertEqualsTable '#step_expected', '#step_actual', 'one timed Success step row per run';
END;
GO

CREATE PROCEDURE test_MOD026.[test TC-026-027 a change to segment columns on an event alone recomputes 0 contacts and changes nothing]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @n int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    SELECT * INTO #detail_before FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_before FROM Layercake.silv_daily_count;

    UPDATE Layercake.silv_membership_events
    SET payment_method_id = 1, payer_type_id = 2, subs_amount_gbp = 120.0000, invoiced_subtotal_gbp = 120.0000
    WHERE event_id = 1;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT p.substep, p.rows_affected
    INTO #log_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.layer = 'silver' AND l.step_name = 'silv_daily_count'
      AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    SELECT v.substep, v.rows_affected
    INTO #log_expected
    FROM (VALUES (N'contacts_recomputed', 0), (N'full_recompute_path', 0)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 sub-steps';

    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEquals 0, @n, 'run 2 wrote adjustment rows';
    SELECT * INTO #detail_after FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_after FROM Layercake.silv_daily_count;
    EXEC tSQLt.AssertEqualsTable '#detail_before', '#detail_after', 'detail changed';
    EXEC tSQLt.AssertEqualsTable '#daily_before', '#daily_after', 'daily changed';
END;
GO
