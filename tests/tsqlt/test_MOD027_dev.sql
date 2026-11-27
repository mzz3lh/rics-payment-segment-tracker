EXEC tSQLt.NewTestClass 'test_MOD027_dev';
GO

CREATE PROCEDURE test_MOD027_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.dim_date';
    EXEC tSQLt.FakeTable 'Layercake.dim_membership_grade';
    EXEC tSQLt.FakeTable 'Layercake.fact_daily_member_count_detail', @Identity = 1;

    INSERT INTO Layercake.dim_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');

    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (7000, '2022-02-28', 2022, 'Q2'),
           (7001, '2022-03-01', 2022, 'Q2'),
           (7002, '2022-03-02', 2022, 'Q2'),
           (7003, '2022-03-03', 2022, 'Q2');
END;
GO

-- Choice: rows_deleted counts the up-front trim of dates outside the silver
-- span and the per-window deletes of cells silver no longer holds together.
-- MOD-031 (DEF-016): rows carry local_group_id 0, contact_country_id = country_id
-- and contact_region = region (the ten-column star grain).
CREATE PROCEDURE test_MOD027_dev.[test rows_deleted counts the span trim and the in-window deletes together]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
         local_group_id, contact_country_id, contact_region,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-03-01', 2022, 'Q2', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK', 4, 4, 4, 0, 0, 0, 0);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
         local_group_id, contact_country_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (9201, 7001, 1, 1, 2, 1, 0, 0, 0, 0, 1, 4, 4, 4, 0, 0, 0, 0),
           (9202, 7001, 2, 1, 2, 1, 0, 0, 0, 0, 2, 1, 1, 1, 0, 0, 0, 0),
           (9203, 7000, 1, 1, 2, 1, 0, 0, 0, 0, 1, 4, 4, 4, 0, 0, 0, 0);
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

-- Choice: counts accumulate over the date windows, and each window logs the
-- number of cells it synced.
CREATE PROCEDURE test_MOD027_dev.[test counts add up across one-day windows and each window logs its synced cells]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
         local_group_id, contact_country_id, contact_region,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-03-01', 2022, 'Q2', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK', 2, 2, 2, 0, 0, 0, 0),
           ('2022-03-02', 2022, 'Q2', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK', 3, 3, 3, 0, 0, 0, 0),
           ('2022-03-03', 2022, 'Q2', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK', 5, 5, 5, 0, 0, 0, 0);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
         local_group_id, contact_country_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (9301, 7001, 1, 1, 2, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0),
           (9302, 7002, 1, 1, 2, 1, 0, 0, 0, 0, 1, 3, 3, 3, 0, 0, 0, 0),
           (9303, 7002, 7, 1, 2, 1, 0, 0, 0, 0, 7, 1, 1, 1, 0, 0, 0, 0);
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

-- Error path: a window that fails rolls back only its own changes. Windows
-- already committed stay (Phase 1 resume behaviour), the log row ends Failed
-- with the counts committed so far, and the error is re-raised.
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD027_dev.[test an overflow in a later window keeps the committed window and logs Failed with its counts]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
         local_group_id, contact_country_id, contact_region,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-03-01', 2022, 'Q2', 'UK',       1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK',       2, 2, 2, 0, 0, 0, 0),
           ('2022-03-02', 2022, 'Q2', 'UK',       1, 1, 'election', 1, 0, 0, 0, 0, 1, 'UK',       2147483647, 1, 1, 0, 0, 0, 0),
           ('2022-03-02', 2022, 'Q2', 'Overseas', 1, 1, 'election', 1, 0, 0, 0, 0, 1, 'Overseas', 2147483647, 1, 1, 0, 0, 0, 0);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
         local_group_id, contact_country_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (9401, 7001, 1, 1, 2, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0),
           (9402, 7002, 1, 1, 2, 1, 0, 0, 0, 0, 1, 5, 2, 2, 0, 0, 0, 0);
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
