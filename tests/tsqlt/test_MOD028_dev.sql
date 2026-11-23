EXEC tSQLt.NewTestClass 'test_MOD028_dev';
GO

CREATE PROCEDURE test_MOD028_dev.[SetUp]
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
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_attribute', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_cell_contacts', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_date_spine';
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_status';
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_state_ranges';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_profile';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_daily_member_count_detail', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_date';
    EXEC tSQLt.FakeTable 'Layercake.dim_membership_grade';

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2019, '2018-10-01', '2019-09-30', '2019-06-01'),
           (2025, '2024-10-01', '2025-09-30', '2025-06-01');
    INSERT INTO Layercake.silv_ref_membership_status (id, status_name) VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');
    INSERT INTO Layercake.dim_membership_grade (id, grade_name) VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES ('2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter) VALUES (1, '2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'U1', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date) VALUES (N'U1', 1, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'U1', 2019, -2, 0, -2, 0, -2, 0, 1),
           (N'U1', 2025, 2, 0, 1, 0, 1, 0, 1);
END;
GO

-- The attributes are an input of the contact (RULE-160), so a change in a Campaign Year with no
-- loaded day still makes it a changed contact; it moves no cell, so no adjustment is written, and
-- the attribute snapshot holds the rows as now applied.
CREATE PROCEDURE test_MOD028_dev.[test an attribute change in a year with no loaded day recomputes the contact and writes no adjustment]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @cr int, @fp int, @adj int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #DetailBefore
    FROM Layercake.silv_daily_count_detail;

    UPDATE Layercake.silv_member_year_attributes SET payment_method_id = 3 WHERE contact_no = N'U1' AND campaign_year = 2019;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT @cr = p.rows_affected FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND p.substep = N'contacts_recomputed';
    SELECT @fp = p.rows_affected FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND p.substep = N'full_recompute_path';
    SELECT @adj = COUNT(*) FROM Layercake.silv_daily_count_adjustment;

    EXEC tSQLt.AssertEquals 1, @cr, 'contacts_recomputed';
    EXEC tSQLt.AssertEquals 0, @fp, 'full_recompute_path';
    EXEC tSQLt.AssertEquals 0, @adj, 'adjustment rows';

    SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #DetailAfter
    FROM Layercake.silv_daily_count_detail;
    EXEC tSQLt.AssertEqualsTable '#DetailBefore', '#DetailAfter', 'detail unchanged';

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payer_type_id, v.concession_type_id
    INTO #ExpectedSnap
    FROM (VALUES (N'U1', 2019, 3, -2, -2), (N'U1', 2025, 2, 1, 1))
         AS v(contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id);
    SELECT contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id
    INTO #ActualSnap
    FROM Layercake.etl_daily_count_applied_attribute;
    EXEC tSQLt.AssertEqualsTable '#ExpectedSnap', '#ActualSnap', 'attribute snapshot as applied';
END;
GO

-- The cell assumes one attributes row per contact and Campaign Year. Two rows for one key would
-- put a contact in two cells on one day, so the run fails before anything is written.
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD028_dev.[test a duplicated attributes row fails the run and leaves the counts unchanged]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @status varchar(10), @msg nvarchar(4000), @adj int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #DetailBefore
    FROM Layercake.silv_daily_count_detail;
    SELECT contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id
    INTO #SnapBefore
    FROM Layercake.etl_daily_count_applied_attribute;

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'U1', 2025, 1, 0, 1, 0, 1, 0, 1);

    BEGIN TRY
        EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;
        EXEC tSQLt.Fail 'The run should fail on the duplicated attributes row.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 2627 THROW;
    END CATCH;

    SELECT @status = l.status, @msg = l.error_message FROM Layercake.etl_run_log AS l WHERE l.run_id = @r2;
    SELECT @adj = COUNT(*) FROM Layercake.silv_daily_count_adjustment;
    EXEC tSQLt.AssertEqualsString 'Failed', @status, 'run status';
    EXEC tSQLt.AssertLike '%(error 2627,%', @msg, 'error logged';
    EXEC tSQLt.AssertEquals 0, @adj, 'adjustment rows';

    SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #DetailAfter
    FROM Layercake.silv_daily_count_detail;
    SELECT contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id
    INTO #SnapAfter
    FROM Layercake.etl_daily_count_applied_attribute;
    EXEC tSQLt.AssertEqualsTable '#DetailBefore', '#DetailAfter', 'detail unchanged';
    EXEC tSQLt.AssertEqualsTable '#SnapBefore', '#SnapAfter', 'attribute snapshot unchanged';
END;
GO

-- The star grain drops the range region but keeps the three segment keys: silver cells that
-- differ only by region add into one fact cell, cells that differ by a segment stay apart.
CREATE PROCEDURE test_MOD028_dev.[test gold sums regions within a segment cell and keeps segment cells apart]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         payment_method_id, payer_type_id, concession_type_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 2, 1, 1, 1, 1, 0, 0, 0, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'EU', 1, 1, 'election', 1, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0);

    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id, v.ActiveMembers, v.PaidMembers
    INTO #Expected
    FROM (VALUES (1, 1, 1, 2, 1, 2, 1, 1, 2, 1),
                 (1, 1, 1, 2, 1, 1, 1, 1, 1, 0))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id,
              payment_method_id, payer_type_id, concession_type_id, ActiveMembers, PaidMembers);

    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           payment_method_id, payer_type_id, concession_type_id, ActiveMembers, PaidMembers
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

-- A cell removed after T exists only in the history; at T it comes back under its own segment ids.
CREATE PROCEDURE test_MOD028_dev.[test the detail as-known-at function returns a removed segment cell under its ids]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         payment_method_id, payer_type_id, concession_type_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES (NEWID(), 1, '2025-01-10T09:00:00', '2025-01-10', 'UK', 1, 1, 'election', 1, 5, 2, 6, -1, -1, 0, 0, 0, 0, 0);

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id,
           CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id, v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count
    INTO #Expected
    FROM (VALUES ('2025-01-10', 'UK', 1, 1, 'election', 1, 5, 2, 6, 1, 1))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count);

    SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
           active_count, paid_count
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_detail_as_known_at('2025-01-01', '2025-01-31', '2025-01-10T08:00:00');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'at 08:00';

    DECLARE @later int = (SELECT COUNT(*) FROM Layercake.fn_silv_daily_count_detail_as_known_at('2025-01-01', '2025-01-31', '2025-01-10T10:00:00'));
    EXEC tSQLt.AssertEquals 0, @later, 'at 10:00';
END;
GO

-- The review view lists each measure of an adjustment row under the row's segment ids.
CREATE PROCEDURE test_MOD028_dev.[test the review view lists each non-zero measure under the row segment ids]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         payment_method_id, payer_type_id, concession_type_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES (NEWID(), 1, '2025-01-10T09:00:00', '2025-01-10', 'UK', 1, 1, 'election', 1, 5, 2, 6, -1, 0, 0, 0, 0, 0, 1);

    SELECT v.payment_method_id, v.payer_type_id, v.concession_type_id, CAST(v.measure_name AS varchar(30)) AS measure_name, v.change_value
    INTO #Expected
    FROM (VALUES (5, 2, 6, 'active_count', -1), (5, 2, 6, 'event_lapse_count', 1))
         AS v(payment_method_id, payer_type_id, concession_type_id, measure_name, change_value);

    SELECT payment_method_id, payer_type_id, concession_type_id, measure_name, change_value
    INTO #Actual
    FROM Layercake.vw_silv_daily_count_adjustment_review;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

-- DEF-007: the three MOD-027 window tests at the new grain (segment ids 0), so the MOD-027
-- window, count and error-path behaviour is proven on this branch. Same data and expectations
-- as test_MOD027_dev, plus payment_method_id, payer_type_id and concession_type_id = 0.
CREATE PROCEDURE test_MOD028_dev.[test MOD-027 rows_deleted counts the span trim and the in-window deletes together at the segment grain]
AS
BEGIN
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (7000, '2022-02-28', 2022, 'Q2'), (7001, '2022-03-01', 2022, 'Q2'),
           (7002, '2022-03-02', 2022, 'Q2'), (7003, '2022-03-03', 2022, 'Q2');

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         payment_method_id, payer_type_id, concession_type_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-03-01', 2022, 'Q2', 'UK', 1, 1, 'election', 1, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
         payment_method_id, payer_type_id, concession_type_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (9201, 7001, 1, 1, 2, 1, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0),
           (9202, 7001, 2, 1, 2, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0),
           (9203, 7000, 1, 1, 2, 1, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0);
    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail OFF;

    EXEC Layercake.usp_load_fact_daily_member_count_detail;

    SELECT CAST(f.id AS bigint) AS id, f.date_id, f.country_id
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT CAST(9201 AS bigint) AS id, 7001 AS date_id, 1 AS country_id
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name = 'fact_daily_member_count_detail';

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 0 AS rows_updated, 2 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD028_dev.[test MOD-027 counts add up across one-day windows and each window logs its synced cells at the segment grain]
AS
BEGIN
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (7000, '2022-02-28', 2022, 'Q2'), (7001, '2022-03-01', 2022, 'Q2'),
           (7002, '2022-03-02', 2022, 'Q2'), (7003, '2022-03-03', 2022, 'Q2');

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         payment_method_id, payer_type_id, concession_type_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-03-01', 2022, 'Q2', 'UK', 1, 1, 'election', 1, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0),
           ('2022-03-02', 2022, 'Q2', 'UK', 1, 1, 'election', 1, 0, 0, 0, 3, 3, 3, 0, 0, 0, 0),
           ('2022-03-03', 2022, 'Q2', 'UK', 1, 1, 'election', 1, 0, 0, 0, 5, 5, 5, 0, 0, 0, 0);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
         payment_method_id, payer_type_id, concession_type_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (9301, 7001, 1, 1, 2, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0),
           (9302, 7002, 1, 1, 2, 1, 0, 0, 0, 3, 3, 3, 0, 0, 0, 0),
           (9303, 7002, 7, 1, 2, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0);
    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail OFF;

    EXEC Layercake.usp_load_fact_daily_member_count_detail @DetailBatchDays = 1;

    SELECT f.date_id, f.country_id, f.ActiveMembers
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT v.date_id, v.country_id, v.ActiveMembers
    INTO #Expected
    FROM (VALUES (7001, 1, 2), (7002, 1, 3), (7003, 1, 5)) AS v(date_id, country_id, ActiveMembers);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name = 'fact_daily_member_count_detail';

    SELECT CAST('Success' AS varchar(10)) AS status, 1 AS rows_inserted, 1 AS rows_updated, 1 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT p.substep
    INTO #ActualProgress
    FROM Layercake.etl_progress_log AS p;

    SELECT CAST(v.substep AS nvarchar(128)) AS substep
    INTO #ExpectedProgress
    FROM (VALUES (N'trim rows outside the silver date span'),
                 (N'window 2022-03-01 -> 2022-03-01 (1 cells synced)'),
                 (N'window 2022-03-02 -> 2022-03-02 (1 cells synced)'),
                 (N'window 2022-03-03 -> 2022-03-03 (1 cells synced)'))
         AS v(substep);

    EXEC tSQLt.AssertEqualsTable '#ExpectedProgress', '#ActualProgress';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD028_dev.[test MOD-027 an overflow in a later window keeps the committed window and logs Failed at the segment grain]
AS
BEGIN
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (7000, '2022-02-28', 2022, 'Q2'), (7001, '2022-03-01', 2022, 'Q2'),
           (7002, '2022-03-02', 2022, 'Q2'), (7003, '2022-03-03', 2022, 'Q2');

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         payment_method_id, payer_type_id, concession_type_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-03-01', 2022, 'Q2', 'UK',       1, 1, 'election', 1, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0),
           ('2022-03-02', 2022, 'Q2', 'UK',       1, 1, 'election', 1, 0, 0, 0, 2147483647, 1, 1, 0, 0, 0, 0),
           ('2022-03-02', 2022, 'Q2', 'Overseas', 1, 1, 'election', 1, 0, 0, 0, 2147483647, 1, 1, 0, 0, 0, 0);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
         payment_method_id, payer_type_id, concession_type_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (9401, 7001, 1, 1, 2, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0),
           (9402, 7002, 1, 1, 2, 1, 0, 0, 0, 5, 2, 2, 0, 0, 0, 0);
    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail OFF;

    BEGIN TRY
        EXEC Layercake.usp_load_fact_daily_member_count_detail @DetailBatchDays = 1;
        EXEC tSQLt.Fail 'usp_load_fact_daily_member_count_detail did not raise the arithmetic overflow error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 8115 THROW;
    END CATCH;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted,
           CASE WHEN l.error_message LIKE N'%error 8115%' THEN 1 ELSE 0 END AS has_error_8115
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name = 'fact_daily_member_count_detail';

    SELECT CAST('Failed' AS varchar(10)) AS status, 0 AS rows_inserted, 1 AS rows_updated, 0 AS rows_deleted, 1 AS has_error_8115
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT CAST(f.id AS bigint) AS id, f.date_id, f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT CAST(v.id AS bigint) AS id, v.date_id, v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent
    INTO #Expected
    FROM (VALUES (9401, 7001, 2, 2, 2),
                 (9402, 7002, 5, 2, 2))
         AS v(id, date_id, ActiveMembers, PaidMembers, PaidMembersEvent);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
