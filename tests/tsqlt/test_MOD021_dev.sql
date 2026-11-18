EXEC tSQLt.NewTestClass 'test_MOD021_dev';
GO
CREATE PROCEDURE test_MOD021_dev.[test detail function returns a stored row of zeros with no adjustments and sums several later changes to one cell]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-02-01', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 20, 18, 17, 3, 4, 1, 2),
           ('2025-02-01', 2025, 'Q2', 'UK', 1, 1, 'election', 2, 0, 0, 0, 0, 0, 0, 0);

    -- Three changes to the first cell: one at or before T (kept) and two after T (both undone).
    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('E5000000-0000-0000-0000-000000000001', 501, '2026-11-01T06:00:00.000', '2025-02-01', 'UK', 1, 1, 'election', 1, 5, 0, 0, 0, 0, 0, 0),
           ('E5000000-0000-0000-0000-000000000002', 502, '2026-11-02T06:00:00.000', '2025-02-01', 'UK', 1, 1, 'election', 1, 2, 1, 0, 0, -1, 0, 0),
           ('E5000000-0000-0000-0000-000000000003', 503, '2026-11-03T06:00:00.000', '2025-02-01', 'UK', 1, 1, 'election', 1, -3, 0, 2, 0, 0, 0, 1);

    SELECT f.[date], f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id,
           f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
           f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_detail_as_known_at('2025-02-01', '2025-02-01', '2026-11-01T12:00:00.000') AS f;

    SELECT v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count,
           v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES (CAST('2025-02-01' AS date), 'UK', 1, 1, 'election', 1, 21, 17, 15, 3, 5, 1, 1),
                 (CAST('2025-02-01' AS date), 'UK', 1, 1, 'election', 2, 0, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              active_count, paid_count, paid_count_event, event_join_count,
              event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021_dev.[test detail function returns a removed cell whose only figure at T is a non-active measure]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    -- No stored row: the cell was removed after T, when it held only a lapse.
    -- A second removed cell was removed before T, so it is not returned.
    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('E5000000-0000-0000-0000-000000000003', 503, '2026-11-03T06:00:00.000', '2025-02-01', 'UK', 1, 1, 'lapse', 1, 0, 0, 0, 0, 0, 0, -1),
           ('E5000000-0000-0000-0000-000000000001', 501, '2026-11-01T06:00:00.000', '2025-02-01', 'UK', 2, 1, 'lapse', 1, -4, 0, 0, 0, 0, 0, 0);

    SELECT f.[date], f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id,
           f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
           f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_detail_as_known_at('2025-02-01', '2025-02-01', '2026-11-02T12:00:00.000') AS f;

    SELECT v.[date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count,
           v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES (CAST('2025-02-01' AS date), 'UK', 1, 1, 'lapse', 1, 0, 0, 0, 0, 0, 0, 1))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              active_count, paid_count, paid_count_event, event_join_count,
              event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021_dev.[test detail function returns no rows when date_from is after date_to]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-02-01', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 20, 18, 17, 3, 4, 1, 2);

    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('E5000000-0000-0000-0000-000000000003', 503, '2026-11-03T06:00:00.000', '2025-02-01', 'UK', 1, 2, 'election', 1, -1, 0, 0, 0, 0, 0, 0);

    SELECT f.[date]
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_detail_as_known_at('2025-02-02', '2025-02-01', '2026-11-02T12:00:00.000') AS f;

    EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021_dev.[test daily function sums status cells that cancel out and keeps regions and grades apart]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-02-01', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 9, 8, 8, 0, 1, 0, 0),
           ('2025-02-01', 2025, 'Q2', 'UK', 1, 1, 'election', 2, 3, 3, 3, 0, 0, 0, 0),
           ('2025-02-01', 2025, 'Q2', 'UK', 1, 1, 'enrolment', 1, 6, 0, 0, 2, 0, 0, 0),
           ('2025-02-01', 2025, 'Q2', 'EMEA', 4, 1, 'election', 1, 2, 2, 2, 0, 0, 0, 0);

    -- After T one contact moved from Practising to Retired: -1 and +1 cancel at the daily grain.
    -- A removed EMEA enrolment cell exists only in the history and gives its own daily row at T.
    INSERT INTO Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
    VALUES ('E5000000-0000-0000-0000-000000000003', 503, '2026-11-03T06:00:00.000', '2025-02-01', 'UK', 1, 1, 'election', 1, -1, -1, -1, 0, 0, 0, 0),
           ('E5000000-0000-0000-0000-000000000003', 503, '2026-11-03T06:00:00.000', '2025-02-01', 'UK', 1, 1, 'election', 2, 1, 1, 1, 0, 0, 0, 0),
           ('E5000000-0000-0000-0000-000000000003', 503, '2026-11-03T06:00:00.000', '2025-02-01', 'EMEA', 4, 2, 'enrolment', 1, -2, 0, 0, -1, 0, 0, 0);

    SELECT f.[date], f.region, f.grade, f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
           f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_as_known_at('2025-02-01', '2025-02-01', '2026-11-02T12:00:00.000') AS f;

    SELECT v.[date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event, v.event_join_count,
           v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES (CAST('2025-02-01' AS date), 'UK', 'election', 12, 11, 11, 0, 1, 0, 0),
                 (CAST('2025-02-01' AS date), 'UK', 'enrolment', 6, 0, 0, 2, 0, 0, 0),
                 (CAST('2025-02-01' AS date), 'EMEA', 'election', 2, 2, 2, 0, 0, 0, 0),
                 (CAST('2025-02-01' AS date), 'EMEA', 'enrolment', 2, 0, 0, 1, 0, 0, 0))
         AS v([date], region, grade, active_count, paid_count, paid_count_event, event_join_count,
              event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021_dev.[test daily function returns a row of zeros for a stored detail row of zeros]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-02-01', 2025, 'Q2', 'UK', 1, 1, 'lapse', 2, 0, 0, 0, 0, 0, 0, 0);

    SELECT f.[date], f.region, f.grade, f.active_count, f.paid_count, f.paid_count_event, f.event_join_count,
           f.event_renewal_count, f.event_readmission_count, f.event_lapse_count
    INTO #Actual
    FROM Layercake.fn_silv_daily_count_as_known_at('2025-02-01', '2025-02-01', '2026-11-02T12:00:00.000') AS f;

    SELECT v.[date], v.region, v.grade, v.active_count, v.paid_count, v.paid_count_event, v.event_join_count,
           v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES (CAST('2025-02-01' AS date), 'UK', 'lapse', 0, 0, 0, 0, 0, 0, 0))
         AS v([date], region, grade, active_count, paid_count, paid_count_event, event_join_count,
              event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD021_dev.[test review view returns measure_name as varchar(30) and change_value as int, both not null]
AS
BEGIN
    SELECT c.name AS column_name, t.name AS type_name, CAST(c.max_length AS int) AS max_length,
           CAST(c.is_nullable AS int) AS is_nullable
    INTO #Actual
    FROM sys.columns AS c
    JOIN sys.types AS t ON t.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID('Layercake.vw_silv_daily_count_adjustment_review')
      AND c.name IN ('measure_name', 'change_value');

    SELECT v.column_name, v.type_name, v.max_length, v.is_nullable
    INTO #Expected
    FROM (VALUES ('measure_name', 'varchar', 30, 0),
                 ('change_value', 'int', 4, 0))
         AS v(column_name, type_name, max_length, is_nullable);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
