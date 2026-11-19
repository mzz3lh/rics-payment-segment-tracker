EXEC tSQLt.NewTestClass 'test_MOD027';
GO

CREATE PROCEDURE test_MOD027.[SetUp]
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
    VALUES (7001, '2022-03-01', 2022, 'Q2'),
           (7002, '2022-03-02', 2022, 'Q2'),
           (7003, '2021-01-15', 2021, 'Q2'),
           (7004, '2021-01-16', 2021, 'Q2'),
           (7101, '2023-05-10', 2023, 'Q3'),
           (7201, '2024-02-10', 2024, 'Q2'),
           (7202, '2024-02-09', 2024, 'Q2'),
           (7301, '2025-01-10', 2025, 'Q2'),
           (7302, '2025-01-11', 2025, 'Q2');
END;
GO

CREATE PROCEDURE test_MOD027.[test TC-027-001 first load of an empty fact inserts one row per gold cell with the Phase 1 derivation]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-03-01', 2022, 'Q2', 'UK',       3, 2, 'election',  1, 1, 1, 1, 0, 0, 0, 0),
           ('2022-03-01', 2022, 'Q2', 'Overseas', 3, 2, 'election',  1, 2, 1, 2, 1, 0, 0, 0),
           ('2022-03-01', 2022, 'Q2', 'UK',       3, 2, 'enrolment', 1, 4, 0, 0, 0, 0, 0, 0),
           ('2022-03-01', 2022, 'Q2', 'UK',       3, 2, 'lapse',     1, 0, 1, 1, 0, 0, 0, 1),
           ('2022-03-01', 2022, 'Q2', 'UK',       3, 2, 'election',  2, 1, 1, 1, 0, 1, 0, 0);

    EXEC Layercake.usp_load_fact_daily_member_count_detail;

    SELECT f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
           f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #Expected
    FROM (VALUES (7001, 3, 2, 2, 1, 3, 2, 3, 1, 0, 0, 0),
                 (7001, 3, 2, 1, 0, 4, 0, 0, 0, 0, 0, 0),
                 (7001, 3, 2, 0, 0, 0, 1, 1, 0, 0, 0, 1),
                 (7001, 3, 2, 2, 2, 1, 1, 1, 0, 1, 0, 0))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.layer, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name = 'fact_daily_member_count_detail';

    SELECT CAST('gold' AS varchar(12)) AS layer, CAST('Success' AS varchar(10)) AS status,
           4 AS rows_inserted, 0 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD027.[test TC-027-002 changed cells are updated in place and keep their id while unchanged cells are untouched]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election',  1, 5, 6, 6, 0, 1, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'enrolment', 1, 2, 0, 0, 0, 0, 0, 0),
           ('2025-01-11', 2025, 'Q2', 'UK', 1, 1, 'election',  1, 5, 6, 6, 0, 0, 0, 0),
           ('2024-02-10', 2024, 'Q2', 'UK', 1, 1, 'election',  1, 4, 4, 4, 0, 0, 0, 0);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (1001, 7301, 1, 1, 2, 1, 5, 5, 5, 0, 0, 0, 0),
           (1002, 7301, 1, 1, 1, 0, 2, 0, 0, 0, 0, 0, 0),
           (1003, 7302, 1, 1, 2, 1, 5, 5, 5, 0, 0, 0, 0),
           (1004, 7201, 1, 1, 2, 1, 4, 4, 4, 0, 0, 0, 0);
    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail OFF;

    EXEC Layercake.usp_load_fact_daily_member_count_detail;

    SELECT CAST(f.id AS bigint) AS id, f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
           f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT CAST(v.id AS bigint) AS id, v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #Expected
    FROM (VALUES (1001, 7301, 1, 1, 2, 1, 5, 6, 6, 0, 1, 0, 0),
                 (1002, 7301, 1, 1, 1, 0, 2, 0, 0, 0, 0, 0, 0),
                 (1003, 7302, 1, 1, 2, 1, 5, 6, 6, 0, 0, 0, 0),
                 (1004, 7201, 1, 1, 2, 1, 4, 4, 4, 0, 0, 0, 0))
         AS v(id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name = 'fact_daily_member_count_detail';

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 2 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD027.[test TC-027-003 a new silver cell is inserted and the existing cell on its date keeps its id]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2023-05-10', 2023, 'Q3', 'UK', 1, 1, 'election',  1, 3, 3, 3, 0, 0, 0, 0),
           ('2023-05-10', 2023, 'Q3', 'UK', 2, 1, 'enrolment', 1, 1, 1, 1, 1, 0, 0, 0);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (2001, 7101, 1, 1, 2, 1, 3, 3, 3, 0, 0, 0, 0);
    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail OFF;

    EXEC Layercake.usp_load_fact_daily_member_count_detail;

    SELECT f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
           f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #Expected
    FROM (VALUES (7101, 1, 1, 2, 1, 3, 3, 3, 0, 0, 0, 0),
                 (7101, 2, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT CAST(f.id AS bigint) AS id, f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
           f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents
    INTO #ActualKept
    FROM Layercake.fact_daily_member_count_detail AS f
    WHERE f.id = 2001;

    SELECT CAST(2001 AS bigint) AS id, 7101 AS date_id, 1 AS country_id, 1 AS gender_id, 2 AS membership_grade_id, 1 AS membership_status_id,
           3 AS ActiveMembers, 3 AS PaidMembers, 3 AS PaidMembersEvent, 0 AS JoinEvents, 0 AS RenewalEvents, 0 AS ReadmissionEvents, 0 AS LapseEvents
    INTO #ExpectedKept;

    EXEC tSQLt.AssertEqualsTable '#ExpectedKept', '#ActualKept';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name = 'fact_daily_member_count_detail';

    SELECT CAST('Success' AS varchar(10)) AS status, 1 AS rows_inserted, 0 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD027.[test TC-027-004 a contact moving country updates its old cells in place and inserts its new cells]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-03-01', 2022, 'Q2', 'UK', 1, 1, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
           ('2022-03-01', 2022, 'Q2', 'UK', 2, 1, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
           ('2022-03-01', 2022, 'Q2', 'UK', 5, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0),
           ('2022-03-02', 2022, 'Q2', 'UK', 1, 1, 'election', 1, 1, 1, 1, 0, 0, 0, 0),
           ('2022-03-02', 2022, 'Q2', 'UK', 2, 1, 'election', 1, 1, 1, 1, 0, 0, 0, 0);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (3001, 7001, 1, 1, 2, 1, 2, 2, 2, 0, 0, 0, 0),
           (3002, 7002, 1, 1, 2, 1, 2, 2, 2, 0, 0, 0, 0),
           (3003, 7001, 5, 1, 2, 1, 1, 0, 0, 0, 0, 0, 0);
    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail OFF;

    EXEC Layercake.usp_load_fact_daily_member_count_detail;

    SELECT f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
           f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #Expected
    FROM (VALUES (7001, 1, 1, 2, 1, 1, 1, 1, 0, 0, 0, 0),
                 (7001, 2, 1, 2, 1, 1, 1, 1, 0, 0, 0, 0),
                 (7001, 5, 1, 2, 1, 1, 0, 0, 0, 0, 0, 0),
                 (7002, 1, 1, 2, 1, 1, 1, 1, 0, 0, 0, 0),
                 (7002, 2, 1, 2, 1, 1, 1, 1, 0, 0, 0, 0))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT CAST(f.id AS bigint) AS id, f.date_id, f.country_id, f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent
    INTO #ActualKept
    FROM Layercake.fact_daily_member_count_detail AS f
    WHERE f.id IN (3001, 3002, 3003);

    SELECT CAST(v.id AS bigint) AS id, v.date_id, v.country_id, v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent
    INTO #ExpectedKept
    FROM (VALUES (3001, 7001, 1, 1, 1, 1),
                 (3002, 7002, 1, 1, 1, 1),
                 (3003, 7001, 5, 1, 0, 0))
         AS v(id, date_id, country_id, ActiveMembers, PaidMembers, PaidMembersEvent);

    EXEC tSQLt.AssertEqualsTable '#ExpectedKept', '#ActualKept';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name = 'fact_daily_member_count_detail';

    SELECT CAST('Success' AS varchar(10)) AS status, 2 AS rows_inserted, 2 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD027.[test TC-027-005 a removed contact deletes the cell it held alone and updates the cell it shared]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2021-01-15', 2021, 'Q2', 'UK', 1, 1, 'election', 1, 7, 7, 7, 0, 0, 0, 0),
           ('2021-01-16', 2021, 'Q2', 'UK', 6, 1, 'election', 1, 1, 1, 1, 0, 0, 0, 0);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (4001, 7003, 6, 1, 2, 1, 1, 1, 1, 0, 0, 0, 0),
           (4002, 7004, 6, 1, 2, 1, 2, 2, 2, 0, 0, 0, 0),
           (4003, 7003, 1, 1, 2, 1, 7, 7, 7, 0, 0, 0, 0);
    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail OFF;

    EXEC Layercake.usp_load_fact_daily_member_count_detail;

    SELECT CAST(f.id AS bigint) AS id, f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
           f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT CAST(v.id AS bigint) AS id, v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #Expected
    FROM (VALUES (4002, 7004, 6, 1, 2, 1, 1, 1, 1, 0, 0, 0, 0),
                 (4003, 7003, 1, 1, 2, 1, 7, 7, 7, 0, 0, 0, 0))
         AS v(id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name = 'fact_daily_member_count_detail';

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 1 AS rows_updated, 1 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD027.[test TC-027-006 cell E emptying in the daily run deletes its fact row and other rows on its date keep their id]
AS
BEGIN
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_bronze';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silver',
         @CommandToExecute = N'DELETE FROM Layercake.silv_daily_count_detail WHERE [date] = ''2022-03-01'' AND country_id = 3 AND grade = ''election''; UPDATE Layercake.silv_daily_count_detail SET active_count = 3, paid_count = 3, paid_count_event = 3 WHERE [date] = ''2022-03-01'' AND country_id = 4;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_membership_grade';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_assessment_route';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_rpq_variant';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_country';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_gender';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_membership_status';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_lapse_reason';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_campaign_year';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_date';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_fact_membership_events';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_fact_annual_rate_base';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_run_payment_segments';

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-03-01', 2022, 'Q2', 'UK', 3, 2, 'election',  1, 1, 1, 1, 0, 0, 0, 0),
           ('2022-03-01', 2022, 'Q2', 'UK', 4, 2, 'election',  1, 2, 2, 2, 0, 0, 0, 0),
           ('2022-03-01', 2022, 'Q2', 'UK', 3, 2, 'enrolment', 1, 1, 0, 0, 0, 0, 0, 0);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (5001, 7001, 3, 2, 2, 1, 1, 1, 1, 0, 0, 0, 0),
           (5002, 7001, 4, 2, 2, 1, 2, 2, 2, 0, 0, 0, 0),
           (5003, 7001, 3, 2, 1, 0, 1, 0, 0, 0, 0, 0, 0);
    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail OFF;

    EXEC Layercake.usp_run_daily_load;

    SELECT CAST(f.id AS bigint) AS id, f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
           f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT CAST(v.id AS bigint) AS id, v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #Expected
    FROM (VALUES (5002, 7001, 4, 2, 2, 1, 3, 3, 3, 0, 0, 0, 0),
                 (5003, 7001, 3, 2, 1, 0, 1, 0, 0, 0, 0, 0, 0))
         AS v(id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.layer, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name IN ('fact_daily_member_count_detail', 'usp_run_daily_load');

    SELECT CAST(v.layer AS varchar(12)) AS layer, CAST(v.status AS varchar(10)) AS status,
           v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('gold', 'Success', 0, 1, 1),
                 ('run',  'Success', NULL, NULL, NULL))
         AS v(layer, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD027.[test TC-027-007 a fact row added by hand is deleted by the next daily run and no other row changes]
AS
BEGIN
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_bronze';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silver';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_membership_grade';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_assessment_route';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_rpq_variant';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_country';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_gender';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_membership_status';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_lapse_reason';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_campaign_year';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_date';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_fact_membership_events';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_fact_annual_rate_base';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_run_payment_segments';

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2024-02-10', 2024, 'Q2', 'UK', 1, 1, 'election', 1, 4, 4, 4, 0, 0, 0, 0),
           ('2024-02-10', 2024, 'Q2', 'UK', 1, 1, 'lapse',    0, 0, 1, 1, 0, 0, 0, 1);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (6001, 7201, 1, 1, 2, 1, 4, 4, 4, 0, 0, 0, 0),
           (6002, 7201, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1),
           (6003, 7201, 9, 1, 2, 1, 1, 1, 1, 0, 0, 0, 0);
    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail OFF;

    EXEC Layercake.usp_run_daily_load;

    SELECT CAST(f.id AS bigint) AS id, f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
           f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT CAST(v.id AS bigint) AS id, v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #Expected
    FROM (VALUES (6001, 7201, 1, 1, 2, 1, 4, 4, 4, 0, 0, 0, 0),
                 (6002, 7201, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1))
         AS v(id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.layer, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted, l.error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name IN ('fact_daily_member_count_detail', 'usp_run_daily_load');

    SELECT CAST(v.layer AS varchar(12)) AS layer, CAST(v.status AS varchar(10)) AS status,
           v.rows_inserted, v.rows_updated, v.rows_deleted, CAST(v.error_message AS nvarchar(4000)) AS error_message
    INTO #ExpectedLog
    FROM (VALUES ('gold', 'Success', 0, 0, 1, NULL),
                 ('run',  'Success', NULL, NULL, NULL, NULL))
         AS v(layer, status, rows_inserted, rows_updated, rows_deleted, error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD027.[test TC-027-008 fact rows dated before or after the silver span are deleted]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2024-02-10', 2024, 'Q2', 'UK', 1, 1, 'election', 1, 4, 4, 4, 0, 0, 0, 0);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (6101, 7201, 1, 1, 2, 1, 4, 4, 4, 0, 0, 0, 0),
           (6102, 7202, 1, 1, 2, 1, 4, 4, 4, 0, 0, 0, 0),
           (6103, 7301, 1, 1, 2, 1, 4, 4, 4, 0, 0, 0, 0);
    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail OFF;

    EXEC Layercake.usp_load_fact_daily_member_count_detail;

    SELECT CAST(f.id AS bigint) AS id, f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
           f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT CAST(6101 AS bigint) AS id, 7201 AS date_id, 1 AS country_id, 1 AS gender_id, 2 AS membership_grade_id, 1 AS membership_status_id,
           4 AS ActiveMembers, 4 AS PaidMembers, 4 AS PaidMembersEvent, 0 AS JoinEvents, 0 AS RenewalEvents, 0 AS ReadmissionEvents, 0 AS LapseEvents
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

CREATE PROCEDURE test_MOD027.[test TC-027-009 a change in any one of the seven measures counts as a changed cell]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-03-01', 2022, 'Q2', 'UK', 11, 1, 'election', 1, 3, 2, 2, 2, 2, 2, 2),
           ('2022-03-01', 2022, 'Q2', 'UK', 12, 1, 'election', 1, 2, 3, 2, 2, 2, 2, 2),
           ('2022-03-01', 2022, 'Q2', 'UK', 13, 1, 'election', 1, 2, 2, 3, 2, 2, 2, 2),
           ('2022-03-01', 2022, 'Q2', 'UK', 14, 1, 'election', 1, 2, 2, 2, 3, 2, 2, 2),
           ('2022-03-01', 2022, 'Q2', 'UK', 15, 1, 'election', 1, 2, 2, 2, 2, 3, 2, 2),
           ('2022-03-01', 2022, 'Q2', 'UK', 16, 1, 'election', 1, 2, 2, 2, 2, 2, 3, 2),
           ('2022-03-01', 2022, 'Q2', 'UK', 17, 1, 'election', 1, 2, 2, 2, 2, 2, 2, 3),
           ('2022-03-01', 2022, 'Q2', 'UK', 18, 1, 'election', 1, 2, 2, 2, 2, 2, 2, 2);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (8011, 7001, 11, 1, 2, 1, 2, 2, 2, 2, 2, 2, 2),
           (8012, 7001, 12, 1, 2, 1, 2, 2, 2, 2, 2, 2, 2),
           (8013, 7001, 13, 1, 2, 1, 2, 2, 2, 2, 2, 2, 2),
           (8014, 7001, 14, 1, 2, 1, 2, 2, 2, 2, 2, 2, 2),
           (8015, 7001, 15, 1, 2, 1, 2, 2, 2, 2, 2, 2, 2),
           (8016, 7001, 16, 1, 2, 1, 2, 2, 2, 2, 2, 2, 2),
           (8017, 7001, 17, 1, 2, 1, 2, 2, 2, 2, 2, 2, 2),
           (8018, 7001, 18, 1, 2, 1, 2, 2, 2, 2, 2, 2, 2);
    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail OFF;

    EXEC Layercake.usp_load_fact_daily_member_count_detail;

    SELECT CAST(f.id AS bigint) AS id, f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
           f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT CAST(v.id AS bigint) AS id, v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #Expected
    FROM (VALUES (8011, 7001, 11, 1, 2, 1, 3, 2, 2, 2, 2, 2, 2),
                 (8012, 7001, 12, 1, 2, 1, 2, 3, 2, 2, 2, 2, 2),
                 (8013, 7001, 13, 1, 2, 1, 2, 2, 3, 2, 2, 2, 2),
                 (8014, 7001, 14, 1, 2, 1, 2, 2, 2, 3, 2, 2, 2),
                 (8015, 7001, 15, 1, 2, 1, 2, 2, 2, 2, 3, 2, 2),
                 (8016, 7001, 16, 1, 2, 1, 2, 2, 2, 2, 2, 3, 2),
                 (8017, 7001, 17, 1, 2, 1, 2, 2, 2, 2, 2, 2, 3),
                 (8018, 7001, 18, 1, 2, 1, 2, 2, 2, 2, 2, 2, 2))
         AS v(id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name = 'fact_daily_member_count_detail';

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 7 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD027.[test TC-027-010 a rerun on unchanged silver changes no fact row and logs 0 inserted updated and deleted]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-03-01', 2022, 'Q2', 'UK', 1, 1, 'election',  1, 3, 3, 3, 1, 0, 0, 0),
           ('2022-03-01', 2022, 'Q2', 'UK', 1, 1, 'enrolment', 1, 2, 0, 0, 0, 0, 0, 0),
           ('2022-03-02', 2022, 'Q2', 'UK', 1, 1, 'election',  1, 3, 3, 3, 0, 0, 0, 0);

    EXEC Layercake.usp_load_fact_daily_member_count_detail;

    SELECT * INTO #Before FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_fact_daily_member_count_detail;

    SELECT * INTO #After FROM Layercake.fact_daily_member_count_detail;

    DECLARE @rows int = (SELECT COUNT(*) FROM #After);
    EXEC tSQLt.AssertEquals 3, @rows;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.log_id = (SELECT MAX(x.log_id) FROM Layercake.etl_run_log AS x WHERE x.step_name = 'fact_daily_member_count_detail');

    SELECT CAST('Success' AS varchar(10)) AS status, 0 AS rows_inserted, 0 AS rows_updated, 0 AS rows_deleted
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD027.[test TC-027-011 a cell sum that overflows the fact column fails the load logs Failed and leaves the fact unchanged]
AS
BEGIN
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2022-03-01', 2022, 'Q2', 'UK',       1, 1, 'election', 1, 2147483647, 1, 1, 0, 0, 0, 0),
           ('2022-03-01', 2022, 'Q2', 'Overseas', 1, 1, 'election', 1, 2147483647, 1, 1, 0, 0, 0, 0),
           ('2022-03-01', 2022, 'Q2', 'UK',       2, 1, 'election', 1, 1, 1, 1, 0, 0, 0, 0);

    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail ON;
    INSERT INTO Layercake.fact_daily_member_count_detail
        (id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
         ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (9001, 7001, 1, 1, 2, 1, 5, 2, 2, 0, 0, 0, 0),
           (9002, 7001, 2, 1, 2, 1, 1, 1, 1, 0, 0, 0, 0);
    SET IDENTITY_INSERT Layercake.fact_daily_member_count_detail OFF;

    BEGIN TRY
        EXEC Layercake.usp_load_fact_daily_member_count_detail;
        EXEC tSQLt.Fail 'usp_load_fact_daily_member_count_detail did not raise the arithmetic overflow error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 8115 THROW;
    END CATCH;

    SELECT l.status, CASE WHEN l.error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name = 'fact_daily_member_count_detail';

    SELECT CAST('Failed' AS varchar(10)) AS status, 1 AS has_error_message
    INTO #ExpectedLog;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT CAST(f.id AS bigint) AS id, f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
           f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT CAST(v.id AS bigint) AS id, v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #Expected
    FROM (VALUES (9001, 7001, 1, 1, 2, 1, 5, 2, 2, 0, 0, 0, 0),
                 (9002, 7001, 2, 1, 2, 1, 1, 1, 1, 0, 0, 0, 0))
         AS v(id, date_id, country_id, gender_id, membership_grade_id, membership_status_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD027.[test TC-027-012 fact id is a bigint identity and still the nonclustered primary key with the grain index unchanged]
AS
BEGIN
    DECLARE @obj int;

    SELECT @obj = r.ObjectId
    FROM tSQLt.Private_RenamedObjectLog AS r
    WHERE r.OriginalName LIKE '%fact[_]daily[_]member[_]count[_]detail%';

    IF @obj IS NULL SET @obj = OBJECT_ID('Layercake.fact_daily_member_count_detail');

    SELECT CAST(c.name AS nvarchar(128)) AS column_name, CAST(TYPE_NAME(c.user_type_id) AS nvarchar(128)) AS type_name,
           c.is_nullable, c.is_identity
    INTO #ActualColumns
    FROM sys.columns AS c
    WHERE c.object_id = @obj;

    SELECT CAST(v.column_name AS nvarchar(128)) AS column_name, CAST(v.type_name AS nvarchar(128)) AS type_name,
           CAST(v.is_nullable AS bit) AS is_nullable, CAST(v.is_identity AS bit) AS is_identity
    INTO #ExpectedColumns
    FROM (VALUES ('id', 'bigint', 0, 1),
                 ('date_id', 'int', 0, 0),
                 ('country_id', 'int', 0, 0),
                 ('gender_id', 'int', 0, 0),
                 ('membership_grade_id', 'int', 0, 0),
                 ('membership_status_id', 'int', 0, 0),
                 ('ActiveMembers', 'int', 0, 0),
                 ('PaidMembers', 'int', 0, 0),
                 ('PaidMembersEvent', 'int', 0, 0),
                 ('JoinEvents', 'int', 0, 0),
                 ('RenewalEvents', 'int', 0, 0),
                 ('ReadmissionEvents', 'int', 0, 0),
                 ('LapseEvents', 'int', 0, 0))
         AS v(column_name, type_name, is_nullable, is_identity);

    EXEC tSQLt.AssertEqualsTable '#ExpectedColumns', '#ActualColumns';

    SELECT CAST(i.type_desc AS nvarchar(60)) AS index_type, i.is_primary_key, i.is_unique,
           CAST(c.name AS nvarchar(128)) AS column_name, CAST(ic.key_ordinal AS int) AS key_ordinal
    INTO #ActualIndexes
    FROM sys.indexes AS i
    JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = @obj
      AND (i.is_primary_key = 1 OR i.type_desc = 'CLUSTERED')
      AND ic.key_ordinal > 0;

    SELECT CAST(v.index_type AS nvarchar(60)) AS index_type, CAST(v.is_primary_key AS bit) AS is_primary_key,
           CAST(v.is_unique AS bit) AS is_unique, CAST(v.column_name AS nvarchar(128)) AS column_name, v.key_ordinal
    INTO #ExpectedIndexes
    FROM (VALUES ('NONCLUSTERED', 1, 1, 'id', 1),
                 ('CLUSTERED', 0, 1, 'date_id', 1),
                 ('CLUSTERED', 0, 1, 'country_id', 2),
                 ('CLUSTERED', 0, 1, 'gender_id', 3),
                 ('CLUSTERED', 0, 1, 'membership_grade_id', 4),
                 ('CLUSTERED', 0, 1, 'membership_status_id', 5))
         AS v(index_type, is_primary_key, is_unique, column_name, key_ordinal);

    EXEC tSQLt.AssertEqualsTable '#ExpectedIndexes', '#ActualIndexes';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD027.[test TC-027-013 no Layercake view function or procedure other than the gold load references fact id]
AS
BEGIN
    CREATE TABLE #Modules (rn int IDENTITY(1, 1) NOT NULL, module_name nvarchar(300) COLLATE DATABASE_DEFAULT NOT NULL);
    CREATE TABLE #Readers (module_name nvarchar(300) COLLATE DATABASE_DEFAULT NOT NULL, problem nvarchar(100) COLLATE DATABASE_DEFAULT NOT NULL);

    INSERT INTO #Modules (module_name)
    SELECT DISTINCT QUOTENAME(s.name) + N'.' + QUOTENAME(o.name)
    FROM sys.sql_expression_dependencies AS d
    JOIN sys.objects AS o ON o.object_id = d.referencing_id
    JOIN sys.schemas AS s ON s.schema_id = o.schema_id
    WHERE d.referenced_entity_name = N'fact_daily_member_count_detail'
      AND ISNULL(d.referenced_schema_name, N'Layercake') = N'Layercake'
      AND s.name = N'Layercake'
      AND o.type IN ('V', 'P', 'FN', 'IF', 'TF')
      AND o.name <> N'usp_load_fact_daily_member_count_detail';

    DECLARE @i int = 1, @n int = (SELECT COUNT(*) FROM #Modules), @name nvarchar(300);

    WHILE @i <= @n
    BEGIN
        SELECT @name = m.module_name FROM #Modules AS m WHERE m.rn = @i;
        BEGIN TRY
            INSERT INTO #Readers (module_name, problem)
            SELECT DISTINCT @name, N'references fact_daily_member_count_detail.id'
            FROM sys.dm_sql_referenced_entities(@name, N'OBJECT') AS r
            WHERE r.referenced_entity_name = N'fact_daily_member_count_detail'
              AND r.referenced_minor_name = N'id';
        END TRY
        BEGIN CATCH
            INSERT INTO #Readers (module_name, problem)
            VALUES (@name, N'column references could not be resolved');
        END CATCH;
        SET @i = @i + 1;
    END;

    EXEC tSQLt.AssertEmptyTable '#Readers';
END;
GO
