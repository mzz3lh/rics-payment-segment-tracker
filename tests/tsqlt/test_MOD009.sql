EXEC tSQLt.NewTestClass 'test_MOD009';
GO

CREATE PROCEDURE test_MOD009.[test TC-009-001 silv_payment_events has no payment_source column]
AS
BEGIN
    DECLARE @table_exists int = CASE WHEN OBJECT_ID(N'Layercake.silv_payment_events', N'U') IS NULL THEN 0 ELSE 1 END;
    DECLARE @column_count int =
        (SELECT COUNT(*)
         FROM sys.columns AS c
         WHERE c.object_id = OBJECT_ID(N'Layercake.silv_payment_events', N'U')
           AND c.name = N'payment_source');
    DECLARE @default_count int =
        (SELECT COUNT(*)
         FROM sys.default_constraints AS d
         WHERE d.parent_object_id = OBJECT_ID(N'Layercake.silv_payment_events', N'U')
           AND d.name = N'df_silv_payment_events_src');

    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @table_exists, @Message = N'Layercake.silv_payment_events must still exist';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @column_count, @Message = N'payment_source must be removed';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @default_count, @Message = N'the payment_source default must be removed with the column';
END;
GO

CREATE PROCEDURE test_MOD009.[test TC-009-002 silv_payment_events keeps its other five Phase 1 columns unchanged]
AS
BEGIN
    SELECT CAST(c.name AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS column_name,
           CAST(t.name AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS type_name,
           CAST(c.max_length AS int) AS max_length,
           CAST(c.precision AS int) AS [precision],
           CAST(c.scale AS int) AS scale,
           CAST(c.is_nullable AS int) AS is_nullable
    INTO #Actual
    FROM sys.columns AS c
    JOIN sys.types AS t
      ON t.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(N'Layercake.silv_payment_events', N'U');

    SELECT CAST(v.column_name AS nvarchar(128)) AS column_name,
           CAST(v.type_name AS nvarchar(128)) AS type_name,
           CAST(v.max_length AS int) AS max_length,
           CAST(v.[precision] AS int) AS [precision],
           CAST(v.scale AS int) AS scale,
           CAST(v.is_nullable AS int) AS is_nullable
    INTO #Expected
    FROM (VALUES
            (N'contact_no',       N'nvarchar', 400,  0, 0, 0),
            (N'campaign_year',    N'int',        4, 10, 0, 0),
            (N'payment_date',     N'date',       3, 10, 0, 1),
            (N'renewal_date_adj', N'date',       3, 10, 0, 1),
            (N'invoice_position', N'nvarchar', 128,  0, 0, 1)
         ) AS v(column_name, type_name, max_length, [precision], scale, is_nullable);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD009.[test TC-009-003 silv_payment_events keeps its clustered primary key on contact_no and campaign_year]
AS
BEGIN
    SELECT CAST(i.type_desc AS nvarchar(60)) COLLATE DATABASE_DEFAULT AS index_type,
           CAST(ic.key_ordinal AS int) AS key_ordinal,
           CAST(c.name AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS column_name
    INTO #Actual
    FROM sys.indexes AS i
    JOIN sys.index_columns AS ic
      ON ic.object_id = i.object_id
     AND ic.index_id = i.index_id
    JOIN sys.columns AS c
      ON c.object_id = ic.object_id
     AND c.column_id = ic.column_id
    WHERE i.object_id = OBJECT_ID(N'Layercake.silv_payment_events', N'U')
      AND i.is_primary_key = 1
      AND ic.key_ordinal > 0;

    SELECT CAST(v.index_type AS nvarchar(60)) AS index_type,
           CAST(v.key_ordinal AS int) AS key_ordinal,
           CAST(v.column_name AS nvarchar(128)) AS column_name
    INTO #Expected
    FROM (VALUES
            (N'CLUSTERED', 1, N'contact_no'),
            (N'CLUSTERED', 2, N'campaign_year')
         ) AS v(index_type, key_ordinal, column_name);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD009.[test TC-009-004 payment events load inserts paid positions without payment_source]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status';
    EXEC tSQLt.FakeTable 'Layercake.brnz_cust_trans';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_pending_rebuild', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_loaded';

    INSERT INTO Layercake.brnz_subs_status
        ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted)
    VALUES
        (N'9000001', 2025, 'Fully Paid',       '2024-11-01', '2024-11-01', 0),
        (N'9000002', 2025, 'Partially Paid',   NULL,         '2024-12-15', 0),
        (N'9000003', 2025, 'Full Concession',  NULL,         NULL,         0),
        (N'9000004', 2024, 'Pre-Subs Payment', NULL,         '2023-10-05', 0),
        (N'9000005', 2025, 'Unpaid',           NULL,         '2024-11-01', 0),
        (N'9000006', 2025, 'Fully Paid',       NULL,         '2024-11-01', 1);

    EXEC Layercake.usp_load_silv_payment_events;

    SELECT p.contact_no, p.campaign_year, p.payment_date, p.renewal_date_adj, p.invoice_position
    INTO #Actual
    FROM Layercake.silv_payment_events AS p;

    SELECT CAST(v.contact_no AS nvarchar(200)) AS contact_no,
           CAST(v.campaign_year AS int) AS campaign_year,
           CAST(v.payment_date AS date) AS payment_date,
           CAST(v.renewal_date_adj AS date) AS renewal_date_adj,
           CAST(v.invoice_position AS nvarchar(64)) AS invoice_position
    INTO #Expected
    FROM (VALUES
            (N'9000001', 2025, NULL, '2024-11-01', N'Fully Paid'),
            (N'9000002', 2025, NULL, '2024-12-15', N'Partially Paid'),
            (N'9000003', 2025, NULL, NULL,         N'Full Concession'),
            (N'9000004', 2024, NULL, '2023-10-05', N'Pre-Subs Payment')
         ) AS v(contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';

    SELECT l.layer, l.step_name, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT CAST(v.layer AS varchar(12)) AS layer,
           CAST(v.step_name AS varchar(128)) AS step_name,
           CAST(v.status AS varchar(10)) AS status,
           CAST(v.rows_inserted AS int) AS rows_inserted,
           CAST(v.rows_updated AS int) AS rows_updated,
           CAST(v.rows_deleted AS int) AS rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('silver', 'silv_payment_events', 'Success', 4, 0, 0)
         ) AS v(layer, step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable @Expected = '#ExpectedLog', @Actual = '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD009.[test TC-009-005 payment events load updates changed and deletes no longer paid positions]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status';
    EXEC tSQLt.FakeTable 'Layercake.brnz_cust_trans';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_pending_rebuild', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_loaded';

    INSERT INTO Layercake.silv_payment_events
        (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'9100001', 2025, NULL, '2024-11-01', N'Partially Paid'),
        (N'9100002', 2025, NULL, '2024-11-10', N'Fully Paid'),
        (N'9100003', 2024, NULL, '2023-11-01', N'Fully Paid');

    INSERT INTO Layercake.brnz_subs_status
        ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted)
    VALUES
        (N'9100001', 2025, 'Fully Paid', NULL, '2024-11-01', 0),
        (N'9100002', 2025, 'Unpaid',     NULL, '2024-11-10', 0),
        (N'9100003', 2024, 'Fully Paid', NULL, '2023-11-01', 0);

    EXEC Layercake.usp_load_silv_payment_events;

    SELECT p.contact_no, p.campaign_year, p.payment_date, p.renewal_date_adj, p.invoice_position
    INTO #Actual
    FROM Layercake.silv_payment_events AS p;

    SELECT CAST(v.contact_no AS nvarchar(200)) AS contact_no,
           CAST(v.campaign_year AS int) AS campaign_year,
           CAST(v.payment_date AS date) AS payment_date,
           CAST(v.renewal_date_adj AS date) AS renewal_date_adj,
           CAST(v.invoice_position AS nvarchar(64)) AS invoice_position
    INTO #Expected
    FROM (VALUES
            (N'9100001', 2025, NULL, '2024-11-01', N'Fully Paid'),
            (N'9100003', 2024, NULL, '2023-11-01', N'Fully Paid')
         ) AS v(contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';

    SELECT l.step_name, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT CAST(v.step_name AS varchar(128)) AS step_name,
           CAST(v.status AS varchar(10)) AS status,
           CAST(v.rows_inserted AS int) AS rows_inserted,
           CAST(v.rows_updated AS int) AS rows_updated,
           CAST(v.rows_deleted AS int) AS rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('silv_payment_events', 'Success', 0, 1, 1)
         ) AS v(step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable @Expected = '#ExpectedLog', @Actual = '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD009.[test TC-009-006 payment events load rerun on unchanged data changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status';
    EXEC tSQLt.FakeTable 'Layercake.brnz_cust_trans';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_pending_rebuild', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_loaded';

    INSERT INTO Layercake.brnz_subs_status
        ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted)
    VALUES
        (N'9200001', 2025, 'Fully Paid',      NULL, '2024-11-01', 0),
        (N'9200002', 2025, 'Partially Paid',  NULL, '2024-12-15', 0),
        (N'9200003', 2024, 'Full Concession', NULL, NULL,         0);

    EXEC Layercake.usp_load_silv_payment_events;

    SELECT *
    INTO #AfterFirst
    FROM Layercake.silv_payment_events;

    EXEC Layercake.usp_load_silv_payment_events;

    SELECT *
    INTO #AfterSecond
    FROM Layercake.silv_payment_events;

    EXEC tSQLt.AssertEqualsTable @Expected = '#AfterFirst', @Actual = '#AfterSecond';

    SELECT l.step_name, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT CAST(v.step_name AS varchar(128)) AS step_name,
           CAST(v.status AS varchar(10)) AS status,
           CAST(v.rows_inserted AS int) AS rows_inserted,
           CAST(v.rows_updated AS int) AS rows_updated,
           CAST(v.rows_deleted AS int) AS rows_deleted
    INTO #ExpectedLog
    FROM (VALUES
            ('silv_payment_events', 'Success', 3, 0, 0),
            ('silv_payment_events', 'Success', 0, 0, 0)
         ) AS v(step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable @Expected = '#ExpectedLog', @Actual = '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD009.[test TC-009-007 failed payment events load rolls back logs Failed and re-raises]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status';
    EXEC tSQLt.FakeTable 'Layercake.brnz_cust_trans';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_pending_rebuild', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_loaded';

    -- test-only rule on the fake: rejecting this contact forces the write to fail part-way
    ALTER TABLE Layercake.silv_payment_events
        ADD CONSTRAINT ck_test_mod009_reject CHECK (contact_no <> N'REJECT-01');

    INSERT INTO Layercake.silv_payment_events
        (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'9300001', 2025, NULL, '2024-11-01', N'Partially Paid'),
        (N'9300002', 2024, NULL, '2023-11-01', N'Fully Paid');

    INSERT INTO Layercake.brnz_subs_status
        ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted)
    VALUES
        (N'9300001',   2025, 'Fully Paid', NULL, '2024-11-01', 0),
        (N'9300003',   2025, 'Fully Paid', NULL, '2024-11-05', 0),
        (N'REJECT-01', 2025, 'Fully Paid', NULL, '2024-11-07', 0);

    DECLARE @error_number int = NULL;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_payment_events;
        EXEC tSQLt.Fail 'usp_load_silv_payment_events should have raised an error';
    END TRY
    BEGIN CATCH
        SET @error_number = ERROR_NUMBER();
        IF @error_number <> 547
            THROW;
    END CATCH;

    EXEC tSQLt.AssertEquals @Expected = 547, @Actual = @error_number;

    SELECT p.contact_no, p.campaign_year, p.payment_date, p.renewal_date_adj, p.invoice_position
    INTO #Actual
    FROM Layercake.silv_payment_events AS p;

    SELECT CAST(v.contact_no AS nvarchar(200)) AS contact_no,
           CAST(v.campaign_year AS int) AS campaign_year,
           CAST(v.payment_date AS date) AS payment_date,
           CAST(v.renewal_date_adj AS date) AS renewal_date_adj,
           CAST(v.invoice_position AS nvarchar(64)) AS invoice_position
    INTO #Expected
    FROM (VALUES
            (N'9300001', 2025, NULL, '2024-11-01', N'Partially Paid'),
            (N'9300002', 2024, NULL, '2023-11-01', N'Fully Paid')
         ) AS v(contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';

    DECLARE @log_rows int = (SELECT COUNT(*) FROM Layercake.etl_run_log);
    DECLARE @failed_rows int =
        (SELECT COUNT(*)
         FROM Layercake.etl_run_log AS l
         WHERE l.step_name = 'silv_payment_events'
           AND l.status = 'Failed'
           AND l.error_message IS NOT NULL);

    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @log_rows, @Message = N'exactly one etl_run_log row';
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @failed_rows, @Message = N'the etl_run_log row ends Failed with an error message';
END;
GO
