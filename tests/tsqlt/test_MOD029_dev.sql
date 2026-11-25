EXEC tSQLt.NewTestClass 'test_MOD029_dev';
GO

CREATE PROCEDURE test_MOD029_dev.[SpyDailyRun]
AS
BEGIN
    -- every step of the daily run logs a stub row, so the order can be read from log_id
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_bronze',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''stub'', ''bronze'', @l OUTPUT;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silver',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''stub'', ''silver'', @l OUTPUT;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_gold',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''stub'', ''gold'', @l OUTPUT;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''stub'', ''daily_count'', @l OUTPUT;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''stub'', ''daily_fact'', @l OUTPUT;';
END;
GO

CREATE PROCEDURE test_MOD029_dev.[test usp_run_daily_load runs the six steps in order under one run_id]
AS
BEGIN
    EXEC test_MOD029_dev.SpyDailyRun;
    EXEC tSQLt.SpyProcedure 'Layercake.usp_run_payment_segments',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''stub'', ''segments'', @l OUTPUT;';

    EXEC Layercake.usp_run_daily_load;

    SELECT ROW_NUMBER() OVER (ORDER BY r.log_id) AS seq, r.step_name
    INTO #Actual
    FROM Layercake.etl_run_log AS r
    WHERE r.layer = 'stub';

    SELECT v.seq, v.step_name
    INTO #Expected
    FROM (VALUES (CAST(1 AS bigint), 'bronze'), (2, 'silver'), (3, 'gold'), (4, 'segments'),
                 (5, 'daily_count'), (6, 'daily_fact')) AS v(seq, step_name);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @run_ids int = (SELECT COUNT(DISTINCT run_id) FROM Layercake.etl_run_log);
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @run_ids, @Message = N'distinct run ids';
END;
GO

CREATE PROCEDURE test_MOD029_dev.[test usp_run_daily_load holds back the daily steps and gives the daily count only FullRebuild]
AS
BEGIN
    EXEC test_MOD029_dev.SpyDailyRun;
    EXEC tSQLt.SpyProcedure 'Layercake.usp_run_payment_segments';

    EXEC Layercake.usp_run_daily_load @FullRebuild = 1;

    SELECT FullRebuild, RebuildFrom, DailyCountBatchDays, SkipDailyCount
    INTO #ActualSilver FROM Layercake.usp_load_silver_SpyProcedureLog;
    SELECT CAST(NULL AS bit) AS FullRebuild, CAST(NULL AS date) AS RebuildFrom, CAST(NULL AS int) AS DailyCountBatchDays,
           CAST(1 AS bit) AS SkipDailyCount
    INTO #ExpectedSilver;
    EXEC tSQLt.AssertEqualsTable '#ExpectedSilver', '#ActualSilver', @Message = N'silver step arguments';

    SELECT DetailBatchDays, SkipDailyFact INTO #ActualGold FROM Layercake.usp_load_gold_SpyProcedureLog;
    SELECT CAST(NULL AS int) AS DetailBatchDays, CAST(1 AS bit) AS SkipDailyFact INTO #ExpectedGold;
    EXEC tSQLt.AssertEqualsTable '#ExpectedGold', '#ActualGold', @Message = N'gold step arguments';

    SELECT FullRebuild, RebuildFrom, DailyCountBatchDays INTO #ActualDc FROM Layercake.usp_load_silv_daily_count_SpyProcedureLog;
    SELECT CAST(1 AS bit) AS FullRebuild, CAST(NULL AS date) AS RebuildFrom, CAST(NULL AS int) AS DailyCountBatchDays
    INTO #ExpectedDc;
    EXEC tSQLt.AssertEqualsTable '#ExpectedDc', '#ActualDc', @Message = N'daily count arguments';

    DECLARE @fact_calls int = (SELECT COUNT(*) FROM Layercake.usp_load_fact_daily_member_count_detail_SpyProcedureLog);
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @fact_calls, @Message = N'gold daily fact calls';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD029_dev.[test usp_run_daily_load re-raises a segment failure logs Failed and runs no daily step]
AS
BEGIN
    DECLARE @status varchar(10), @err nvarchar(4000), @late int;

    EXEC test_MOD029_dev.SpyDailyRun;
    EXEC tSQLt.SpyProcedure 'Layercake.usp_run_payment_segments',
        @CommandToExecute = N'THROW 50991, ''segment stub failure'', 1;';

    BEGIN TRY
        EXEC Layercake.usp_run_daily_load;
        EXEC tSQLt.Fail 'usp_run_daily_load should have failed with error 50991';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 50991 THROW;
    END CATCH;

    SELECT @status = status, @err = error_message
    FROM Layercake.etl_run_log WHERE layer = 'run' AND step_name = 'usp_run_daily_load';
    SELECT @late = COUNT(*) FROM Layercake.etl_run_log WHERE step_name IN ('daily_count', 'daily_fact');

    EXEC tSQLt.AssertEquals @Expected = 'Failed', @Actual = @status, @Message = N'run row status';
    EXEC tSQLt.AssertLike @ExpectedPattern = N'segment stub failure (error 50991%', @Actual = @err, @Message = N'run row error';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @late, @Message = N'daily steps after the failure';
END;
GO

CREATE PROCEDURE test_MOD029_dev.[test usp_load_silver with SkipDailyCount still runs the annual rate base after the profile]
AS
BEGIN
    DECLARE @r uniqueidentifier = 'D0000000-0000-0000-0000-000000000029';

    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_ref_assessment_route';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_ref_rpq_variant';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_ref_country';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_ref_lapse_reason';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_ref_date_spine';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_ref_campaign_year_config';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_payment_events';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_ref_enrolment_exception';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_member_base';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_membership_events';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_data_anomaly';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_member_state_ranges';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_member_profile',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''stub'', ''profile'', @l OUTPUT;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''stub'', ''daily_count'', @l OUTPUT;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_annual_rate_base',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''stub'', ''rate_base'', @l OUTPUT;';

    EXEC Layercake.usp_load_silver @run_id = @r, @FullRebuild = 1, @SkipDailyCount = 1;

    SELECT ROW_NUMBER() OVER (ORDER BY l.log_id) AS seq, l.step_name, l.run_id
    INTO #Actual
    FROM Layercake.etl_run_log AS l
    WHERE l.layer = 'stub';

    SELECT v.seq, v.step_name, @r AS run_id
    INTO #Expected
    FROM (VALUES (CAST(1 AS bigint), 'profile'), (2, 'rate_base')) AS v(seq, step_name);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD029_dev.[test usp_load_gold with SkipDailyFact still runs the annual rate base fact after the events fact]
AS
BEGIN
    DECLARE @r uniqueidentifier = 'D0000000-0000-0000-0000-000000000030';

    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_membership_grade';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_assessment_route';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_rpq_variant';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_country';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_gender';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_membership_status';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_lapse_reason';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_campaign_year';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_date';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_fact_membership_events',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''stub'', ''fact_events'', @l OUTPUT;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''stub'', ''daily_fact'', @l OUTPUT;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_fact_annual_rate_base',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''stub'', ''rate_base_fact'', @l OUTPUT;';

    EXEC Layercake.usp_load_gold @run_id = @r, @DetailBatchDays = 5, @SkipDailyFact = 1;

    SELECT ROW_NUMBER() OVER (ORDER BY l.log_id) AS seq, l.step_name, l.run_id
    INTO #Actual
    FROM Layercake.etl_run_log AS l
    WHERE l.layer = 'stub';

    SELECT v.seq, v.step_name, @r AS run_id
    INTO #Expected
    FROM (VALUES (CAST(1 AS bigint), 'fact_events'), (2, 'rate_base_fact')) AS v(seq, step_name);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
