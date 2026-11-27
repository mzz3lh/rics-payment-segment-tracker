EXEC tSQLt.NewTestClass 'test_MOD021';
GO
CREATE PROCEDURE test_MOD021.[test TC-021-001 detail as known at three times gives 10, 12 and 11 for cell X]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 11, 9, 8, 1, 2, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 1, 2, 'election', 1, 5, 4, 4, 0, 1, 1, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 2, 0, 0, 0, 0, 0, 0, 0);

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('A1000000-0000-0000-0000-000000000002', 102, '2026-11-02T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, 2, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 2, -1, 0, 0, 0, 0, 0, 0);

    DECLARE @d date = '2025-01-10';
    DECLARE @t1 datetime2(3) = '2026-11-01T12:00:00.000';
    DECLARE @t2 datetime2(3) = '2026-11-02T12:00:00.000';
    DECLARE @t3 datetime2(3) = '2026-11-03T12:00:00.000';

    SELECT u.known_at, u.active_count, u.paid_count, u.paid_count_event, u.event_join_count,
           u.event_renewal_count, u.event_readmission_count, u.event_lapse_count
    INTO #Actual
    FROM (
        SELECT 'T1' AS known_at, f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
               f.event_renewal_count, f.event_readmission_count, f.event_lapse_count,
               f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id
        FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @t1) AS f
        UNION ALL
        SELECT 'T2', f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
               f.event_renewal_count, f.event_readmission_count, f.event_lapse_count,
               f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id
        FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @t2) AS f
        UNION ALL
        SELECT 'T3', f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
               f.event_renewal_count, f.event_readmission_count, f.event_lapse_count,
               f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id
        FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @t3) AS f
    ) AS u
    WHERE u.region = 'UK' AND u.country_id = 1 AND u.gender_id = 1 AND u.grade = 'election' AND u.membership_status_id = 1;

    SELECT v.known_at, v.active_count, v.paid_count, v.paid_count_event, v.event_join_count,
           v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('T1', 10, 9, 8, 1, 2, 0, 0),
                 ('T2', 12, 9, 8, 1, 2, 0, 0),
                 ('T3', 11, 9, 8, 1, 2, 0, 0))
         AS v(known_at, active_count, paid_count, paid_count_event, event_join_count,
              event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-002 a change written exactly at T is part of the figure at T]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 11, 9, 8, 1, 2, 0, 0);

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('A1000000-0000-0000-0000-000000000002', 102, '2026-11-02T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, 2, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0);

    DECLARE @d date = '2025-01-10';
    DECLARE @before_r2 datetime2(3) = '2026-11-02T05:59:59.999';
    DECLARE @at_r2 datetime2(3) = '2026-11-02T06:00:00.000';
    DECLARE @at_r3 datetime2(3) = '2026-11-03T06:00:00.000';

    SELECT u.known_at, u.active_count
    INTO #Actual
    FROM (
        SELECT 'before R2' AS known_at, f.active_count FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @before_r2) AS f
        UNION ALL
        SELECT 'at R2', f.active_count FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @at_r2) AS f
        UNION ALL
        SELECT 'at R3', f.active_count FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @at_r3) AS f
    ) AS u;

    SELECT v.known_at, v.active_count
    INTO #Expected
    FROM (VALUES ('before R2', 10), ('at R2', 12), ('at R3', 11)) AS v(known_at, active_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-003 silv_daily_count grain sums cells X and Y to 17 then 16]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 11, 9, 8, 1, 2, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 1, 2, 'election', 1, 5, 4, 4, 0, 1, 1, 0);

    INSERT INTO Layercake.silv_daily_count
        ([date], campaign_year, campaign_quarter, region, grade,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 'election', 16, 13, 12, 1, 3, 1, 0);

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('A1000000-0000-0000-0000-000000000002', 102, '2026-11-02T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, 2, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0);

    DECLARE @d date = '2025-01-10';
    DECLARE @t2 datetime2(3) = '2026-11-02T12:00:00.000';
    DECLARE @t3 datetime2(3) = '2026-11-03T12:00:00.000';

    SELECT f.[date], f.region, f.grade, f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
           f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_as_known_at(@d, @d, @t2) AS f;

    SELECT v.[date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event, v.event_join_count,
           v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES (CAST('2025-01-10' AS date), 'UK', 'election', 17, 13, 12, 1, 3, 1, 0))
         AS v([date], region, grade, active_count, paid_count, paid_count_event, event_join_count,
              event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT f.[date], f.region, f.grade, f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
           f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #ActualLatest
    FROM Layercake.fn_silv_daily_count_as_known_at(@d, @d, @t3) AS f;

    SELECT s.[date], s.region, s.grade, s.active_count, s.paid_count, s.paid_count_event, s.event_join_count,
           s.event_renewal_count, s.event_readmission_count, s.event_lapse_count
    INTO #ExpectedLatest
    FROM Layercake.silv_daily_count AS s;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLatest', '#ActualLatest';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-004 cell Z changed to 0 with a stored row shows 1 as known before the change]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 11, 9, 8, 1, 2, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 2, 0, 0, 0, 0, 0, 0, 0);

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('A1000000-0000-0000-0000-000000000002', 102, '2026-11-02T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, 2, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 2, -1, 0, 0, 0, 0, 0, 0);

    DECLARE @d date = '2025-01-10';
    DECLARE @t2 datetime2(3) = '2026-11-02T12:00:00.000';

    SELECT f.[date], f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id,
           f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
           f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @t2) AS f
    WHERE f.membership_status_id = 2;

    SELECT v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count,
           v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES (CAST('2025-01-10' AS date), 'UK', 1, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              active_count, paid_count, paid_count_event, event_join_count,
              event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-005 cell Z removed with no stored row shows 1 before the change and nothing after]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 11, 9, 8, 1, 2, 0, 0);

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('A1000000-0000-0000-0000-000000000002', 102, '2026-11-02T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, 2, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 2, -1, 0, 0, 0, 0, 0, 0);

    DECLARE @d date = '2025-01-10';
    DECLARE @t2 datetime2(3) = '2026-11-02T12:00:00.000';
    DECLARE @t3 datetime2(3) = '2026-11-03T12:00:00.000';

    SELECT f.[date], f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id,
           f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
           f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @t2) AS f
    WHERE f.membership_status_id = 2;

    SELECT v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count,
           v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES (CAST('2025-01-10' AS date), 'UK', 1, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              active_count, paid_count, paid_count_event, event_join_count,
              event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT f.[date], f.membership_status_id
    INTO #ActualAfter
    FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @t3) AS f
    WHERE f.membership_status_id = 2;

    EXEC tSQLt.AssertEmptyTable '#ActualAfter';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-006 a date first loaded after T returns its first-load figures]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 11, 9, 8, 1, 2, 0, 0),
           ('2025-01-20', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 7, 6, 6, 0, 0, 0, 0);

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('A1000000-0000-0000-0000-000000000002', 102, '2026-11-02T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, 2, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0);

    DECLARE @d date = '2025-01-20';
    DECLARE @t2 datetime2(3) = '2026-11-02T12:00:00.000';

    SELECT f.[date], f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id,
           f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
           f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @t2) AS f;

    SELECT v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count,
           v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES (CAST('2025-01-20' AS date), 'UK', 1, 1, 'election', 1, 7, 6, 6, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              active_count, paid_count, paid_count_event, event_join_count,
              event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-007 a one-day range returns only that date's cells X and Y]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 11, 9, 8, 1, 2, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 1, 2, 'election', 1, 5, 4, 4, 0, 1, 1, 0),
           ('2025-01-20', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 7, 6, 6, 0, 0, 0, 0);

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('A1000000-0000-0000-0000-000000000002', 102, '2026-11-02T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, 2, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-20', 'UK', 1, 2, 'election', 1, -3, 0, 0, 0, 0, 0, 0);

    DECLARE @d date = '2025-01-10';
    DECLARE @t2 datetime2(3) = '2026-11-02T12:00:00.000';

    SELECT f.[date], f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id,
           f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
           f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @t2) AS f;

    SELECT v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count,
           v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES (CAST('2025-01-10' AS date), 'UK', 1, 1, 'election', 1, 12, 9, 8, 1, 2, 0, 0),
                 (CAST('2025-01-10' AS date), 'UK', 1, 2, 'election', 1, 5, 4, 4, 0, 1, 1, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              active_count, paid_count, paid_count_event, event_join_count,
              event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-008 the date range includes both end dates and nothing outside them]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-09', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 4, 0, 0, 0, 0, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 11, 9, 8, 1, 2, 0, 0),
           ('2025-01-20', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 7, 6, 6, 0, 0, 0, 0),
           ('2025-01-21', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 8, 0, 0, 0, 0, 0, 0);

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-09', 'UK', 1, 2, 'election', 1, -2, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-21', 'UK', 1, 2, 'election', 1, -2, 0, 0, 0, 0, 0, 0);

    DECLARE @from date = '2025-01-10';
    DECLARE @to date = '2025-01-20';
    DECLARE @t2 datetime2(3) = '2026-11-02T12:00:00.000';

    SELECT f.[date], f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id, f.active_count
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_detail_as_known_at(@from, @to, @t2) AS f;

    SELECT v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id, v.active_count
    INTO #Expected
    FROM (VALUES (CAST('2025-01-10' AS date), 'UK', 1, 1, 'election', 1, 11),
                 (CAST('2025-01-20' AS date), 'UK', 1, 1, 'election', 1, 7))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, active_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-009 a NULL parameter returns no rows from either function]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 11, 9, 8, 1, 2, 0, 0);

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('A1000000-0000-0000-0000-000000000002', 102, '2026-11-02T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, 2, 0, 0, 0, 0, 0, 0);

    DECLARE @d date = '2025-01-10';
    DECLARE @t datetime2(3) = '2026-11-02T12:00:00.000';
    DECLARE @nd date = NULL;
    DECLARE @nt datetime2(3) = NULL;

    SELECT f.[date] INTO #Actual FROM Layercake.fn_silv_daily_count_detail_as_known_at(@nd, @d, @t) AS f;
    INSERT INTO #Actual ([date]) SELECT f.[date] FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @nd, @t) AS f;
    INSERT INTO #Actual ([date]) SELECT f.[date] FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @nt) AS f;
    INSERT INTO #Actual ([date]) SELECT f.[date] FROM Layercake.fn_silv_daily_count_as_known_at(@nd, @d, @t) AS f;
    INSERT INTO #Actual ([date]) SELECT f.[date] FROM Layercake.fn_silv_daily_count_as_known_at(@d, @nd, @t) AS f;
    INSERT INTO #Actual ([date]) SELECT f.[date] FROM Layercake.fn_silv_daily_count_as_known_at(@d, @d, @nt) AS f;

    EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-010 with T after the latest adjustment both functions equal the stored counts]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 11, 9, 8, 1, 2, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 1, 2, 'election', 1, 5, 4, 4, 0, 1, 1, 0),
           ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 2, 0, 0, 0, 0, 0, 0, 0),
           ('2025-01-10', 2025, 'Q2', 'EMEA', 2, 2, 'enrolment', 1, 3, 0, 0, 1, 0, 0, 0),
           ('2025-01-20', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 7, 6, 6, 0, 0, 0, 0);

    INSERT INTO Layercake.silv_daily_count
        ([date], campaign_year, campaign_quarter, region, grade,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 'election', 16, 13, 12, 1, 3, 1, 0),
           ('2025-01-10', 2025, 'Q2', 'EMEA', 'enrolment', 3, 0, 0, 1, 0, 0, 0),
           ('2025-01-20', 2025, 'Q2', 'UK', 'election', 7, 6, 6, 0, 0, 0, 0);

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('A1000000-0000-0000-0000-000000000002', 102, '2026-11-02T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, 2, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 2, -1, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'EMEA', 2, 2, 'enrolment', 1, 0, 0, 0, 1, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-20', 'UK', 1, 2, 'election', 1, -3, 0, 0, 0, 0, 0, 0);

    DECLARE @from date = '2025-01-01';
    DECLARE @to date = '2025-01-31';
    DECLARE @t datetime2(3) = '2026-11-04T00:00:00.000';

    SELECT f.[date], f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id,
           f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
           f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #ActualDetail
    FROM Layercake.fn_silv_daily_count_detail_as_known_at(@from, @to, @t) AS f;

    SELECT s.[date], s.region, s.country_id, s.gender_id, s.grade, s.membership_status_id,
           s.active_count, s.paid_count, s.paid_count_event, s.event_join_count,
           s.event_renewal_count, s.event_readmission_count, s.event_lapse_count
    INTO #ExpectedDetail
    FROM Layercake.silv_daily_count_detail AS s;

    EXEC tSQLt.AssertEqualsTable '#ExpectedDetail', '#ActualDetail';

    SELECT f.[date], f.region, f.grade, f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
           f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #ActualDaily
    FROM Layercake.fn_silv_daily_count_as_known_at(@from, @to, @t) AS f;

    SELECT s.[date], s.region, s.grade, s.active_count, s.paid_count, s.paid_count_event, s.event_join_count,
           s.event_renewal_count, s.event_readmission_count, s.event_lapse_count
    INTO #ExpectedDaily
    FROM Layercake.silv_daily_count AS s;

    EXEC tSQLt.AssertEqualsTable '#ExpectedDaily', '#ActualDaily';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-011 a cell with no stored row that nets to 0 at T is not returned]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-01-10', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 11, 9, 8, 1, 2, 0, 0);

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('A1000000-0000-0000-0000-000000000002', 102, '2026-11-02T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'enrolment', 1, 1, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'enrolment', 1, -1, 0, 0, 0, 0, 0, 0);

    DECLARE @d date = '2025-01-10';
    DECLARE @t1 datetime2(3) = '2026-11-01T12:00:00.000';
    DECLARE @t2 datetime2(3) = '2026-11-02T12:00:00.000';

    SELECT f.[date], f.grade
    INTO #ActualBefore
    FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @t1) AS f
    WHERE f.grade = 'enrolment';

    EXEC tSQLt.AssertEmptyTable '#ActualBefore';

    SELECT f.[date], f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id,
           f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
           f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_detail_as_known_at(@d, @d, @t2) AS f
    WHERE f.grade = 'enrolment';

    SELECT v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count,
           v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES (CAST('2025-01-10' AS date), 'UK', 1, 1, 'enrolment', 1, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              active_count, paid_count, paid_count_event, event_join_count,
              event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-012 review view lists exactly the two non-zero changes for cell X]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('A1000000-0000-0000-0000-000000000002', 102, '2026-11-02T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, 2, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
           ('A1000000-0000-0000-0000-000000000003', 103, '2026-11-03T06:00:00.000', '2025-01-10', 'UK', 1, 1, 'election', 2, -1, 0, 0, 0, 0, 0, 0);

    SELECT r.run_id, r.written_at, r.[date], r.region, r.country_id, r.gender_id, r.grade, r.membership_status_id,
           r.measure_name, r.change_value
    INTO #Actual
    FROM Layercake.vw_silv_daily_count_adjustment_review AS r
    WHERE r.[date] = '2025-01-10' AND r.region = 'UK' AND r.country_id = 1 AND r.gender_id = 1
      AND r.grade = 'election' AND r.membership_status_id = 1;

    SELECT v.run_id, v.written_at, v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.measure_name, v.change_value
    INTO #Expected
    FROM (VALUES (CAST('A1000000-0000-0000-0000-000000000002' AS uniqueidentifier), CAST('2026-11-02T06:00:00.000' AS datetime2(3)),
                  CAST('2025-01-10' AS date), 'UK', 1, 1, 'election', 1, 'active_count', 2),
                 (CAST('A1000000-0000-0000-0000-000000000003' AS uniqueidentifier), CAST('2026-11-03T06:00:00.000' AS datetime2(3)),
                  CAST('2025-01-10' AS date), 'UK', 1, 1, 'election', 1, 'active_count', -1))
         AS v(run_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id, measure_name, change_value);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-013 review view gives one row per non-zero measure with the exact column names]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('B2000000-0000-0000-0000-000000000001', 201, '2026-11-05T06:00:00.000', '2025-03-01', 'UK', 3, 1, 'election', 1, 1, -2, 3, -4, 5, -6, 7),
           ('B2000000-0000-0000-0000-000000000002', 202, '2026-11-06T06:00:00.000', '2025-03-01', 'UK', 3, 1, 'election', 1, 0, 2, 0, 0, 0, 0, -1);

    SELECT r.run_id, CAST(r.measure_name AS varbinary(30)) AS measure_bytes, r.change_value
    INTO #Actual
    FROM Layercake.vw_silv_daily_count_adjustment_review AS r;

    SELECT v.run_id, CAST(v.measure_name AS varbinary(30)) AS measure_bytes, v.change_value
    INTO #Expected
    FROM (VALUES (CAST('B2000000-0000-0000-0000-000000000001' AS uniqueidentifier), 'active_count', 1),
                 (CAST('B2000000-0000-0000-0000-000000000001' AS uniqueidentifier), 'paid_count', -2),
                 (CAST('B2000000-0000-0000-0000-000000000001' AS uniqueidentifier), 'paid_count_event', 3),
                 (CAST('B2000000-0000-0000-0000-000000000001' AS uniqueidentifier), 'event_join_count', -4),
                 (CAST('B2000000-0000-0000-0000-000000000001' AS uniqueidentifier), 'event_renewal_count', 5),
                 (CAST('B2000000-0000-0000-0000-000000000001' AS uniqueidentifier), 'event_readmission_count', -6),
                 (CAST('B2000000-0000-0000-0000-000000000001' AS uniqueidentifier), 'event_lapse_count', 7),
                 (CAST('B2000000-0000-0000-0000-000000000002' AS uniqueidentifier), 'paid_count', 2),
                 (CAST('B2000000-0000-0000-0000-000000000002' AS uniqueidentifier), 'event_lapse_count', -1))
         AS v(run_id, measure_name, change_value);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @unmatched int;
    SELECT @unmatched = COUNT(*)
    FROM Layercake.vw_silv_daily_count_adjustment_review AS r
    LEFT JOIN Layercake.silv_daily_count_adjustment AS a
        ON a.adjustment_id = r.adjustment_id AND a.run_id = r.run_id
    WHERE a.adjustment_id IS NULL;

    EXEC tSQLt.AssertEquals 0, @unmatched;
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-014 review view keeps changes that cancel out across cells as separate rows]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('C3000000-0000-0000-0000-000000000004', 304, '2026-11-04T06:00:00.000', '2024-12-01', 'UK', 1, 1, 'election', 1, -1, 0, 0, 0, 0, 0, 0),
           ('C3000000-0000-0000-0000-000000000004', 304, '2026-11-04T06:00:00.000', '2024-12-01', 'UK', 1, 1, 'election', 2, 1, 0, 0, 0, 0, 0, 0);

    SELECT r.run_id, r.[date], r.region, r.country_id, r.gender_id, r.grade, r.membership_status_id,
           r.measure_name, r.change_value
    INTO #Actual
    FROM Layercake.vw_silv_daily_count_adjustment_review AS r;

    SELECT v.run_id, v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.measure_name, v.change_value
    INTO #Expected
    FROM (VALUES (CAST('C3000000-0000-0000-0000-000000000004' AS uniqueidentifier), CAST('2024-12-01' AS date), 'UK', 1, 1, 'election', 1, 'active_count', -1),
                 (CAST('C3000000-0000-0000-0000-000000000004' AS uniqueidentifier), CAST('2024-12-01' AS date), 'UK', 1, 1, 'election', 2, 'active_count', 1))
         AS v(run_id, [date], region, country_id, gender_id, grade, membership_status_id, measure_name, change_value);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-015 adjustment table has the designed columns, types and nullability]
AS
BEGIN
    SELECT c.name AS column_name,
           CASE WHEN t.name IN ('varchar', 'nvarchar', 'char', 'nchar')
                    THEN t.name + '(' + CAST(CASE WHEN t.name LIKE 'n%' THEN c.max_length / 2 ELSE c.max_length END AS varchar(10)) + ')'
                WHEN t.name IN ('datetime2', 'time', 'datetimeoffset')
                    THEN t.name + '(' + CAST(c.scale AS varchar(10)) + ')'
                ELSE t.name END AS type_text,
           CAST(c.is_nullable AS int) AS is_nullable,
           CAST(c.is_identity AS int) AS is_identity
    INTO #Actual
    FROM sys.columns AS c
    JOIN sys.types AS t ON t.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID('Layercake.silv_daily_count_adjustment');

    SELECT v.column_name, v.type_text, v.is_nullable, v.is_identity
    INTO #Expected
    FROM (VALUES ('adjustment_id', 'bigint', 0, 1),
                 ('run_id', 'uniqueidentifier', 0, 0),
                 ('load_id', 'bigint', 0, 0),
                 ('written_at', 'datetime2(3)', 0, 0),
                 ('date', 'date', 0, 0),
                 ('region', 'varchar(12)', 0, 0),
                 ('country_id', 'int', 0, 0),
                 ('gender_id', 'int', 0, 0),
                 ('grade', 'varchar(12)', 0, 0),
                 ('membership_status_id', 'int', 0, 0),
                 ('payment_method_id', 'int', 0, 0),
                 ('payer_type_id', 'int', 0, 0),
                 ('concession_type_id', 'int', 0, 0),
                 ('local_group_id', 'int', 0, 0),
                 ('contact_country_id', 'int', 0, 0),
                 ('contact_region', 'varchar(12)', 0, 0),
                 ('active_count_change', 'int', 0, 0),
                 ('paid_count_change', 'int', 0, 0),
                 ('paid_count_event_change', 'int', 0, 0),
                 ('event_join_count_change', 'int', 0, 0),
                 ('event_renewal_count_change', 'int', 0, 0),
                 ('event_readmission_count_change', 'int', 0, 0),
                 ('event_lapse_count_change', 'int', 0, 0))
         AS v(column_name, type_text, is_nullable, is_identity);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-016 adjustment table rejects a row whose seven changes are all 0]
AS
BEGIN
    DECLARE @checks TABLE (rn int IDENTITY(1, 1), constraint_name sysname);
    INSERT INTO @checks (constraint_name)
    SELECT cc.name
    FROM sys.check_constraints AS cc
    WHERE cc.parent_object_id = OBJECT_ID('Layercake.silv_daily_count_adjustment');

    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    DECLARE @i int = 1, @n int, @name sysname;
    SELECT @n = COUNT(*) FROM @checks;
    WHILE @i <= @n
    BEGIN
        SELECT @name = c.constraint_name FROM @checks AS c WHERE c.rn = @i;
        EXEC tSQLt.ApplyConstraint 'Layercake.silv_daily_count_adjustment', @name;
        SET @i += 1;
    END;

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('D4000000-0000-0000-0000-000000000001', 401, '2026-11-05T06:00:00.000', '2025-02-01', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 0, 0, -1);

    EXEC tSQLt.ExpectException @ExpectedErrorNumber = 547;

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('D4000000-0000-0000-0000-000000000001', 401, '2026-11-05T06:00:00.000', '2025-02-02', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 0, 0, 0);
END;
GO
CREATE PROCEDURE test_MOD021.[test TC-021-017 adjustment table is unique on run_id and the twelve cell columns]
AS
BEGIN
    SELECT i.index_id
    INTO #Actual
    FROM sys.indexes AS i
    WHERE i.object_id = OBJECT_ID('Layercake.silv_daily_count_adjustment')
      AND i.is_unique = 1
      AND i.has_filter = 0
      AND (SELECT COUNT(*) FROM sys.index_columns AS ic
           WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0) = 13
      AND (SELECT COUNT(*) FROM sys.index_columns AS ic
           JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
           WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
             AND c.name IN ('run_id', 'date', 'region', 'country_id', 'gender_id', 'grade', 'membership_status_id',
                            'payment_method_id', 'payer_type_id', 'concession_type_id',
                            'local_group_id', 'contact_country_id', 'contact_region')) = 13;

    DECLARE @matching int;
    SELECT @matching = COUNT(*) FROM #Actual;

    EXEC tSQLt.AssertEquals 1, @matching, 'Expected exactly one unfiltered unique index or constraint keyed on run_id, [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id, local_group_id, contact_country_id, contact_region.';
END;
GO
