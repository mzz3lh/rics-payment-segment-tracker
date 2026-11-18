EXEC tSQLt.NewTestClass 'test_MOD023_dev';
GO

CREATE PROCEDURE test_MOD023_dev.[SpyRunSteps]
    @segment_command nvarchar(max)
AS
BEGIN
    -- Each step records its position, its run_id and (for the segment run) its as-of date in #calls.
    DECLARE @bronze nvarchar(max) = N'INSERT INTO #calls (step, run_id) VALUES (''bronze'', @run_id);';
    DECLARE @silver nvarchar(max) = N'INSERT INTO #calls (step, run_id) VALUES (''silver'', @run_id);';
    DECLARE @gold   nvarchar(max) = N'INSERT INTO #calls (step, run_id) VALUES (''gold'', @run_id);';

    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_bronze', @CommandToExecute = @bronze;
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_silver', @CommandToExecute = @silver;
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_gold', @CommandToExecute = @gold;
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_run_payment_segments', @CommandToExecute = @segment_command;
END;
GO

CREATE PROCEDURE test_MOD023_dev.[test the segment run is called once, last, with the daily run id and no as-of date]
AS
BEGIN
    -- tempdb's collation differs from the database's, so the string column takes the database's.
    CREATE TABLE #calls
    (
        call_no    int IDENTITY(1, 1) NOT NULL,
        step       varchar(20) COLLATE DATABASE_DEFAULT NOT NULL,
        run_id     uniqueidentifier NULL,
        as_of_date date NULL
    );

    EXEC test_MOD023_dev.[SpyRunSteps]
        @segment_command = N'INSERT INTO #calls (step, run_id, as_of_date) VALUES (''segments'', @run_id, @as_of_date);';

    EXEC Layercake.usp_run_daily_load @FullRebuild = 1;

    DECLARE @daily_run_id uniqueidentifier = (SELECT l.run_id FROM Layercake.etl_run_log AS l
                                              WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load');

    SELECT c.call_no, c.step, CASE WHEN c.run_id = @daily_run_id THEN 1 ELSE 0 END AS same_run_id, c.as_of_date
    INTO #Actual
    FROM #calls AS c;

    SELECT v.call_no, v.step, v.same_run_id, v.as_of_date
    INTO #Expected
    FROM (VALUES (1, 'bronze', 1, CAST(NULL AS date)),
                 (2, 'silver', 1, CAST(NULL AS date)),
                 (3, 'gold', 1, CAST(NULL AS date)),
                 (4, 'segments', 1, CAST(NULL AS date))) AS v (call_no, step, same_run_id, as_of_date);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @run_status varchar(10) = (SELECT l.status FROM Layercake.etl_run_log AS l
                                       WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load');
    EXEC tSQLt.AssertEquals 'Success', @run_status, 'The daily run row ends Success';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD023_dev.[test a segment run error fails the daily run row and reaches the caller unchanged]
AS
BEGIN
    CREATE TABLE #calls
    (
        call_no    int IDENTITY(1, 1) NOT NULL,
        step       varchar(20) COLLATE DATABASE_DEFAULT NOT NULL,
        run_id     uniqueidentifier NULL,
        as_of_date date NULL
    );

    EXEC test_MOD023_dev.[SpyRunSteps]
        @segment_command = N'THROW 50923, ''segment step failed'', 1;';

    DECLARE @error_number int = NULL;

    BEGIN TRY
        EXEC Layercake.usp_run_daily_load;
        EXEC tSQLt.Fail 'usp_run_daily_load did not fail when the segment run failed';
    END TRY
    BEGIN CATCH
        SET @error_number = ERROR_NUMBER();
        IF @error_number <> 50923 THROW;
    END CATCH;

    EXEC tSQLt.AssertEquals 50923, @error_number, 'The original error reaches the caller';

    DECLARE @run_rows int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l);
    DECLARE @failed_with_message int =
        (SELECT COUNT(*) FROM Layercake.etl_run_log AS l
         WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load' AND l.status = 'Failed'
           AND l.finished_at IS NOT NULL
           AND l.error_message LIKE N'segment step failed (error 50923, line %');
    DECLARE @steps_run int = (SELECT COUNT(*) FROM #calls);

    EXEC tSQLt.AssertEquals 1, @run_rows, 'Only the daily run row is logged (the steps are stand-ins)';
    EXEC tSQLt.AssertEquals 1, @failed_with_message, 'The daily run row ends Failed with the error message';
    EXEC tSQLt.AssertEquals 3, @steps_run, 'Bronze, silver and gold ran before the segment run';
END;
GO
