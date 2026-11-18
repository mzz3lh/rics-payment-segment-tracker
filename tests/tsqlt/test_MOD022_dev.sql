EXEC tSQLt.NewTestClass 'test_MOD022_dev';
GO
CREATE PROCEDURE test_MOD022_dev.[SetUp]
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
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_state_ranges';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_profile';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';

    INSERT INTO Layercake.silv_ref_membership_status (id, status_name)
    VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2024, '2023-10-01', '2024-09-30', '2024-06-01'),
           (2025, '2024-10-01', '2025-09-30', '2025-06-01');

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2025-01-09', 2025, 'Q2'), ('2025-01-10', 2025, 'Q2'), ('2025-01-11', 2025, 'Q2');

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'D1', '2015-01-01', NULL, 2015, 'election', 'UK', 2),
           (2, N'D2', '2015-01-01', NULL, 2015, 'election', 'UK', 2);

    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D1', 1, 1, NULL), (N'D2', 2, 2, NULL);

    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'D2', 2025, '2024-10-20', '2024-10-20', N'Fully Paid');

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:D2:2025', 'Renewal', '2024-10-20', N'D2', 2025);
END;
GO
CREATE PROCEDURE test_MOD022_dev.[test a rerun on unchanged data logs 0 inserted 0 updated 0 deleted after a first load of 9 rows]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT CASE WHEN run_id = @r1 THEN 1 ELSE 2 END AS run_no, status, rows_inserted, rows_updated, rows_deleted
    INTO #Actual
    FROM Layercake.etl_run_log
    WHERE step_name = 'silv_daily_count';

    -- run 1: 6 detail cells and 3 main rows
    SELECT v.run_no, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #Expected
    FROM (VALUES (1, CAST('Success' AS varchar(10)), 9, 0, 0), (2, 'Success', 0, 0, 0))
         AS v (run_no, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD022_dev.[test an added Renewal is logged as 4 updated rows and nothing inserted or deleted]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (2, N'RN:D1:2025', 'Renewal', '2025-01-10', N'D1', 2025);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    -- D1's detail cell and the main row on 2025-01-10 and 2025-01-11
    SELECT rows_inserted, rows_updated, rows_deleted
    INTO #Actual
    FROM Layercake.etl_run_log
    WHERE run_id = @r2 AND step_name = 'silv_daily_count';

    SELECT 0 AS rows_inserted, 4 AS rows_updated, 0 AS rows_deleted INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD022_dev.[test a changed spine quarter on a loaded date updates both tables and writes no adjustment]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    UPDATE Layercake.ref_date_spine SET campaign_quarter = 'Q3' WHERE [date] = '2025-01-10';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_daily_count_adjustment';

    SELECT [date], campaign_quarter, country_id INTO #ActualDetail FROM Layercake.silv_daily_count_detail;
    SELECT v.[date], v.campaign_quarter, v.country_id
    INTO #ExpectedDetail
    FROM (VALUES (CAST('2025-01-09' AS date), CAST('Q2' AS char(2)), 1), ('2025-01-09', 'Q2', 2),
                 ('2025-01-10', 'Q3', 1), ('2025-01-10', 'Q3', 2),
                 ('2025-01-11', 'Q2', 1), ('2025-01-11', 'Q2', 2)) AS v ([date], campaign_quarter, country_id);
    EXEC tSQLt.AssertEqualsTable '#ExpectedDetail', '#ActualDetail';

    SELECT [date], campaign_quarter INTO #ActualDaily FROM Layercake.silv_daily_count;
    SELECT v.[date], v.campaign_quarter
    INTO #ExpectedDaily
    FROM (VALUES (CAST('2025-01-09' AS date), CAST('Q2' AS char(2))), ('2025-01-10', 'Q3'), ('2025-01-11', 'Q2'))
         AS v ([date], campaign_quarter);
    EXEC tSQLt.AssertEqualsTable '#ExpectedDaily', '#ActualDaily';
END;
GO
CREATE PROCEDURE test_MOD022_dev.[test the basis holds one row per reference table with an empty key and 2020-10-01]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT input_name, input_key, earliest_affected_date, run_id
    INTO #Actual
    FROM Layercake.etl_daily_count_input_basis
    WHERE input_name <> 'contact';

    SELECT CAST(v.input_name AS varchar(64)) AS input_name, CAST(N'' AS nvarchar(200)) AS input_key,
           CAST('2020-10-01' AS date) AS earliest_affected_date, @r1 AS run_id
    INTO #Expected
    FROM (VALUES ('ref_date_spine'), ('ref_campaign_year_config'), ('silv_ref_membership_status')) AS v (input_name);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD022_dev.[test a spine date added after the latest loaded date is no change and an uncovered pending row stays open]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();
    DECLARE @future date = DATEADD(DAY, 30, CAST(SYSDATETIME() AS date));
    DECLARE @open int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    -- the daily spine extension; and a pending row no input change reaches
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES (@future, 2099, 'Q1');
    INSERT INTO Layercake.etl_daily_count_pending_rebuild (source, affected_from, detection_count, first_detected_at, last_detected_at, applied_at)
    VALUES ('payments', '2025-01-09', 1, '2026-11-17 06:00', '2026-11-17 06:00', NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    -- the run started at today, after 2025-01-09, so the row is not covered
    SELECT @open = COUNT(*) FROM Layercake.etl_daily_count_pending_rebuild WHERE applied_at IS NULL;
    EXEC tSQLt.AssertEquals 1, @open;
END;
GO
CREATE PROCEDURE test_MOD022_dev.[test a contact with only a profile row affects no date and its change does not reach back]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();
    DECLARE @earliest date, @expected date = '9999-12-31', @open int;

    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'P1', 9, 1, NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT @earliest = earliest_affected_date
    FROM Layercake.etl_daily_count_input_basis
    WHERE input_name = 'contact' AND input_key = N'P1';
    EXEC tSQLt.AssertEquals @expected, @earliest;

    UPDATE Layercake.silv_member_profile SET country_id = 10 WHERE contact_no = N'P1';
    INSERT INTO Layercake.etl_daily_count_pending_rebuild (source, affected_from, detection_count, first_detected_at, last_detected_at, applied_at)
    VALUES ('member_profile', '2025-01-09', 1, '2026-11-17 06:00', '2026-11-17 06:00', NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT @open = COUNT(*) FROM Layercake.etl_daily_count_pending_rebuild WHERE applied_at IS NULL;
    EXEC tSQLt.AssertEquals 1, @open;
END;
GO
CREATE PROCEDURE test_MOD022_dev.[test a payment dated in the previous Campaign Year moves the earliest affected date to that year's start]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();
    DECLARE @earliest date, @expected date = '2023-10-01';

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (3, N'D8', '2024-11-05', NULL, 2025, 'enrolment', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D8', 8, 1, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'D8', 2025, '2024-09-20', '2024-10-01', N'Fully Paid');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT @earliest = earliest_affected_date
    FROM Layercake.etl_daily_count_input_basis
    WHERE input_name = 'contact' AND input_key = N'D8';
    EXEC tSQLt.AssertEquals @expected, @earliest;
END;
GO
CREATE PROCEDURE test_MOD022_dev.[test a stored row of a loaded date after today is removed with its mark and recorded as a negative adjustment]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();
    DECLARE @future date = DATEADD(DAY, 10, CAST(SYSDATETIME() AS date));
    DECLARE @marks int;

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES (@future, 2099, 'Q1', 'UK', 1, 1, 'election', 1, 1, 0, 0, 0, 0, 0, 0);
    INSERT INTO Layercake.silv_daily_count
        ([date], campaign_year, campaign_quarter, region, grade,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES (@future, 2099, 'Q1', 'UK', 'election', 1, 0, 0, 0, 0, 0, 0);
    INSERT INTO Layercake.etl_daily_count_loaded ([date], loaded_at, run_id, batch_from, batch_to)
    VALUES (@future, '2026-11-01 05:00', NEWID(), @future, @future);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT [date] INTO #FutureDetail FROM Layercake.silv_daily_count_detail WHERE [date] = @future;
    EXEC tSQLt.AssertEmptyTable '#FutureDetail';
    SELECT [date] INTO #FutureDaily FROM Layercake.silv_daily_count WHERE [date] = @future;
    EXEC tSQLt.AssertEmptyTable '#FutureDaily';
    SELECT @marks = COUNT(*) FROM Layercake.etl_daily_count_loaded WHERE [date] = @future;
    EXEC tSQLt.AssertEquals 0, @marks;

    SELECT run_id, [date], region, country_id, gender_id, grade, membership_status_id,
           active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
    INTO #Actual
    FROM Layercake.silv_daily_count_adjustment;

    SELECT @r1 AS run_id, @future AS [date], 'UK' AS region, 1 AS country_id, 1 AS gender_id, 'election' AS grade,
           1 AS membership_status_id, -1 AS active_count_change, 0 AS paid_count_change, 0 AS paid_count_event_change,
           0 AS event_join_count_change, 0 AS event_renewal_count_change, 0 AS event_readmission_count_change,
           0 AS event_lapse_count_change
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD022_dev.[test a failing first run logs Failed with error 515 and leaves the tables marks history and basis empty]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();
    DECLARE @status varchar(10), @message nvarchar(4000), @errors int;

    -- a spine date with no Campaign Year cannot be stored (campaign_year is NOT NULL)
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES ('2025-01-12', NULL, 'Q2');

    BEGIN TRY
        EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
        EXEC tSQLt.Fail 'usp_load_silv_daily_count did not raise an error for a spine date with no Campaign Year.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515 THROW;
    END CATCH;

    SELECT @status = status, @message = error_message
    FROM Layercake.etl_run_log
    WHERE run_id = @r1 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEquals 'Failed', @status;
    SET @errors = CASE WHEN @message LIKE N'%(error 515, line %' THEN 1 ELSE 0 END;
    EXEC tSQLt.AssertEquals 1, @errors;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_daily_count';
    EXEC tSQLt.AssertEmptyTable 'Layercake.etl_daily_count_loaded';
    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_daily_count_adjustment';
    EXEC tSQLt.AssertEmptyTable 'Layercake.etl_daily_count_input_basis';
END;
GO
