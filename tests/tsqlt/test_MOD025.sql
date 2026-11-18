EXEC tSQLt.NewTestClass 'test_MOD025';
GO
CREATE PROCEDURE test_MOD025.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    -- AC-022-01's 17 rows on 8 keys, plus AC-023-01's 4 rows with no Sub Campaign Year.
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Start Date], [Sub End Date], [Sub Status],
         [Sub Campaign Year], [Round], [Sub User Status], [Sub User Created Date])
    VALUES
        (N'C2201', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Active',   2025, N'Round 1',  N'Active',   '2024-10-01'),
        (N'C2202', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Active',   2025, N'Round 1',  N'Inactive', '2024-10-01'),
        (N'C2202', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Active',   2025, N'Round 2',  N'Inactive', '2024-12-01'),
        (N'C2202', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Active',   2025, N'Round 3',  N'Active',   '2024-11-01'),
        (N'C2202', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Active',   2025, N'Round 4',  N'Inactive', '2025-01-10'),
        (N'C2203', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Inactive', 2025, N'Round 3',  N'Active',   '2024-10-01'),
        (N'C2203', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Inactive', 2025, N'Round 1',  N'Inactive', '2024-11-15'),
        (N'C2204', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Inactive', 2025, N'Round 4',  N'Active',   NULL),
        (N'C2204', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Inactive', 2025, N'Round 1',  N'Inactive', '2024-10-05'),
        (N'C2205', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Inactive', 2025, N'Round 9',  N'Active',   '2024-10-01'),
        (N'C2205', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Inactive', 2025, N'Round 10', N'Inactive', '2024-10-01'),
        (N'C2206', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Inactive', 2025, NULL,        N'Active',   '2024-10-01'),
        (N'C2206', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Inactive', 2025, N'Round 1',  N'Inactive', '2024-10-01'),
        (N'C2207', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Inactive', 2025, N'Round X',  N'Active',   '2024-10-01'),
        (N'C2207', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Inactive', 2025, N'Round 2',  N'Inactive', '2024-10-01'),
        (N'C2208', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Active',   2025, N'Round 1',  N'Active',   '2024-10-01'),
        (N'C2208', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Active',   2025, N'Round 1',  N'Active',   '2024-10-01'),
        (N'C2201', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Active',   NULL, N'Round 1',  N'Inactive', '2024-10-01'),
        (N'C2301', N'SCH-030', N'Scheme Thirty', '2026-10-19', NULL,         N'Active',   NULL, N'Round 1',  N'Active',   '2026-10-19'),
        (N'C2301', N'SCH-030', N'Scheme Thirty', '2026-10-19', NULL,         N'Active',   NULL, N'Round 1',  N'Active',   '2026-10-19'),
        (N'C2302', N'SCH-031', N'Scheme Thirty-One', '2024-10-01', '2025-09-30', N'Inactive', NULL, N'Round 1', N'Inactive', '2024-10-01');
END;
GO
CREATE PROCEDURE test_MOD025.[Arrange segment run]
AS
BEGIN
    -- Inputs of the two unchanged readers that run for real (attributes, segment anomalies).
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_invoice_line_type';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes';

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    SELECT y.yr, DATEFROMPARTS(y.yr - 1, 10, 1), DATEFROMPARTS(y.yr, 9, 30), DATEFROMPARTS(y.yr, 9, 30)
    FROM (SELECT TOP (40) 2020 + ROW_NUMBER() OVER (ORDER BY o.object_id) AS yr FROM sys.all_objects AS o) AS y;

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code)
    VALUES (-2, 'Not applicable', NULL), (-1, 'Unrecognised', NULL), (0, 'Unknown', NULL), (5, 'Corporate', 'Corporate');

    INSERT INTO Layercake.silv_membership_events (event_nk, event_type, event_subtype, event_date, contact_no, campaign_year)
    SELECT CONCAT(N'RN:', c.contact_no, N':2025'), 'Renewal', 'Standard', '2024-10-15', c.contact_no, 2025
    FROM (VALUES (N'C2201'), (N'C2202'), (N'C2203'), (N'C2204'), (N'C2205'), (N'C2206'), (N'C2207'), (N'C2208'), (N'C2301'))
         AS c(contact_no);

    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    SELECT c.contact_no, 2025, '2024-10-15', '2024-10-15', N'Fully Paid'
    FROM (VALUES (N'C2201'), (N'C2202'), (N'C2203'), (N'C2204'), (N'C2205'), (N'C2206'), (N'C2207'), (N'C2208'), (N'C2301'))
         AS c(contact_no);

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, fully_credited, _is_deleted)
    SELECT c.rec_id, c.contact_no, 2025, CONCAT(N'INV-', c.rec_id), CONCAT(N'V', c.rec_id), '2024-10-10', N'Corporate', N'N', 0
    FROM (VALUES (22010, N'C2201'), (22020, N'C2202'), (22030, N'C2203'), (22040, N'C2204'), (22050, N'C2205'),
                 (22060, N'C2206'), (22070, N'C2207'), (22080, N'C2208'), (23010, N'C2301'))
         AS c(rec_id, contact_no);

    -- The other 14 loads of the run do not read or write brnz_corporate_subscription and are
    -- unchanged by MOD-025: stand-ins that only log 'Success' under the run's run_id.
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_brnz_subs_invoice', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''bronze'', ''brnz_subs_invoice'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_brnz_subs_invoice_line', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''bronze'', ''brnz_subs_invoice_line'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_brnz_concession', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''bronze'', ''brnz_concession'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_ref_invoice_line_type', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''silv_ref_invoice_line_type'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_ref_currency', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''silv_ref_currency'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_ref_concession_type', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''silv_ref_concession_type'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_payment_method', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''dim_payment_method'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_payer_type', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''dim_payer_type'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_currency', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''dim_currency'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_concession_type', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''dim_concession_type'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_event_amount', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''silv_event_amount'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_data_anomaly_invoice', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''silv_data_anomaly_invoice'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_membership_events_segments', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''silv_membership_events_segments'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_fact_membership_events_segments', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''fact_membership_events_segments'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
END;
GO
CREATE PROCEDURE test_MOD025.[Arrange daily run]
AS
BEGIN
    EXEC test_MOD025.[Arrange segment run];

    -- Phase 1 orchestrators, unchanged by MOD-025 and tested by their own suites: stand-ins that log 'Success'.
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_bronze', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''bronze'', ''usp_load_bronze'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silver', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''usp_load_silver'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_gold', @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''usp_load_gold'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-001 the 21 row source lands the 8 dated keys and no row for the 4 rows with no Campaign Year]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted, l.error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted, v.error_message
    INTO #ExpectedLog
    FROM (VALUES ('Success', 8, 0, 0, CAST(NULL AS nvarchar(4000))))
         AS v(status, rows_inserted, rows_updated, rows_deleted, error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT b.contact_no, b.scheme_no, b.scheme_name, b.sub_campaign_year,
           CAST(b.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(b.sub_user_status AS varbinary(700)) AS sub_user_status_bytes,
           b._is_deleted
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.contact_no, v.scheme_no, v.scheme_name, v.sub_campaign_year,
           CAST(v.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(v.sub_user_status AS varbinary(700)) AS sub_user_status_bytes,
           CAST(0 AS bit) AS _is_deleted
    INTO #Expected
    FROM (VALUES (N'C2201', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active'),
                 (N'C2202', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active'),
                 (N'C2203', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive'),
                 (N'C2204', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive'),
                 (N'C2205', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive'),
                 (N'C2206', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive'),
                 (N'C2207', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive'),
                 (N'C2208', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active'))
         AS v(contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-002 the load logs 4 rows with no Campaign Year and 9 repeats as its two sub-steps]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    DECLARE @log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l);

    SELECT p.substep, p.rows_affected
    INTO #Actual
    FROM Layercake.etl_progress_log AS p
    WHERE p.log_id = @log_id
      AND p.substep IN (N'no_campaign_year_rows_not_landed', N'repeated_key_rows_not_landed');

    SELECT v.substep, v.rows_affected
    INTO #Expected
    FROM (VALUES (N'no_campaign_year_rows_not_landed', 4),
                 (N'repeated_key_rows_not_landed', 9))
         AS v(substep, rows_affected);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-003 a source of only rows with no Campaign Year lands nothing logs Success and counts no repeat]
AS
BEGIN
    DELETE FROM Subs.vwCorpSubscriptions WHERE [Sub Campaign Year] IS NOT NULL;

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    DECLARE @log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l);

    SELECT p.substep, p.rows_affected
    INTO #Actual
    FROM Layercake.etl_progress_log AS p
    WHERE p.log_id = @log_id
      AND p.substep IN (N'no_campaign_year_rows_not_landed', N'repeated_key_rows_not_landed');

    SELECT v.substep, v.rows_affected
    INTO #Expected
    FROM (VALUES (N'no_campaign_year_rows_not_landed', 4),
                 (N'repeated_key_rows_not_landed', 0))
         AS v(substep, rows_affected);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
    EXEC tSQLt.AssertEmptyTable 'Layercake.brnz_corporate_subscription';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-004 a row with no Campaign Year takes no part in choosing a repeated key copy]
AS
BEGIN
    -- Would win C2203's 2025 key (Active/Active, latest date, highest Round) if its year were guessed from its dates.
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Start Date], [Sub End Date], [Sub Status],
         [Sub Campaign Year], [Round], [Sub User Status], [Sub User Created Date])
    VALUES (N'C2203', N'SCH-020', N'Scheme Twenty', '2024-10-01', '2025-09-30', N'Active', NULL, N'Round 9', N'Active', '2025-02-01');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT b.contact_no, b.scheme_no, b.sub_campaign_year,
           CAST(b.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(b.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b
    WHERE b.contact_no = N'C2203';

    SELECT v.contact_no, v.scheme_no, v.sub_campaign_year,
           CAST(v.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(v.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (N'C2203', N'SCH-020', 2025, N'Inactive', N'Inactive'))
         AS v(contact_no, scheme_no, sub_campaign_year, sub_status, sub_user_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l);

    SELECT p.substep, p.rows_affected
    INTO #ActualSteps
    FROM Layercake.etl_progress_log AS p
    WHERE p.log_id = @log_id
      AND p.substep IN (N'no_campaign_year_rows_not_landed', N'repeated_key_rows_not_landed');

    SELECT v.substep, v.rows_affected
    INTO #ExpectedSteps
    FROM (VALUES (N'no_campaign_year_rows_not_landed', 5),
                 (N'repeated_key_rows_not_landed', 9))
         AS v(substep, rows_affected);

    EXEC tSQLt.AssertEqualsTable '#ExpectedSteps', '#ActualSteps';

    DECLARE @rows int = (SELECT COUNT(*) FROM Layercake.brnz_corporate_subscription);
    EXEC tSQLt.AssertEquals 8, @rows;
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-005 rows with no Campaign Year write no data anomaly]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_data_anomaly';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-006 a second load on the unchanged source logs 0 0 0 and the same two counts]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    DECLARE @log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l);

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.log_id = @log_id;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT p.substep, p.rows_affected
    INTO #ActualSteps
    FROM Layercake.etl_progress_log AS p
    WHERE p.log_id = @log_id
      AND p.substep IN (N'no_campaign_year_rows_not_landed', N'repeated_key_rows_not_landed');

    SELECT v.substep, v.rows_affected
    INTO #ExpectedSteps
    FROM (VALUES (N'no_campaign_year_rows_not_landed', 4),
                 (N'repeated_key_rows_not_landed', 9))
         AS v(substep, rows_affected);

    EXEC tSQLt.AssertEqualsTable '#ExpectedSteps', '#ActualSteps';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-007 a source with no NULL Campaign Year logs 0 rows with no Campaign Year]
AS
BEGIN
    DELETE FROM Subs.vwCorpSubscriptions;

    -- AC-006-02 to AC-006-16 corporate subscription rows.
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Start Date], [Sub End Date], [Sub Status],
         [Sub Campaign Year], [Round], [Sub User Status], [Sub User Created Date])
    VALUES (N'P1',  N'SCH-001', N'Scheme One',   '2024-10-01', '2025-09-30', N'Active', 2025, N'1',  N'Active',   '2024-10-01'),
           (N'P6',  N'SCH-006', N'Scheme Six',   '2024-10-01', '2025-09-30', N'Active', 2025, NULL,  N'Active',   '2024-10-01'),
           (N'P7',  N'SCH-007', N'Scheme Seven', '2024-10-01', '2025-09-30', N'Active', 2025, NULL,  N'Inactive', '2024-10-01'),
           (N'P10', N'SCH-010', N'Scheme Ten',   '2024-10-01', '2025-09-30', N'Active', 2025, NULL,  N'Active',   '2024-10-01');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 4, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    DECLARE @log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l);

    SELECT p.substep, p.rows_affected
    INTO #Actual
    FROM Layercake.etl_progress_log AS p
    WHERE p.log_id = @log_id
      AND p.substep IN (N'no_campaign_year_rows_not_landed', N'repeated_key_rows_not_landed');

    SELECT v.substep, v.rows_affected
    INTO #Expected
    FROM (VALUES (N'no_campaign_year_rows_not_landed', 0),
                 (N'repeated_key_rows_not_landed', 0))
         AS v(substep, rows_affected);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD025.[test TC-025-008 a NULL Contact No with no Campaign Year fails with 515 and changes nothing]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;

    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Start Date], [Sub End Date], [Sub Status],
         [Sub Campaign Year], [Round], [Sub User Status], [Sub User Created Date])
    VALUES (NULL, N'SCH-030', N'Scheme Thirty', '2026-10-19', NULL, N'Active', NULL, N'Round 1', N'Active', '2026-10-19');

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_corporate_subscription;
        EXEC tSQLt.Fail 'Expected error 515, but the load raised no error.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515 THROW;
    END CATCH;

    DECLARE @log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l);

    SELECT l.status, CAST(CASE WHEN l.error_message IS NULL THEN 0 ELSE 1 END AS bit) AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.log_id = @log_id;

    SELECT v.status, CAST(v.has_error_message AS bit) AS has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT p.substep, p.rows_affected
    INTO #FailedRunSteps
    FROM Layercake.etl_progress_log AS p
    WHERE p.log_id = @log_id
      AND p.substep IN (N'no_campaign_year_rows_not_landed', N'repeated_key_rows_not_landed');

    EXEC tSQLt.AssertEmptyTable '#FailedRunSteps';
END;
GO
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD025.[test TC-025-009 a NULL Scheme No with no Campaign Year fails with 515 and changes nothing]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;

    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Start Date], [Sub End Date], [Sub Status],
         [Sub Campaign Year], [Round], [Sub User Status], [Sub User Created Date])
    VALUES (N'C2303', NULL, N'Scheme Thirty', '2026-10-19', NULL, N'Active', NULL, N'Round 1', N'Active', '2026-10-19');

    BEGIN TRY
        EXEC Layercake.usp_load_brnz_corporate_subscription;
        EXEC tSQLt.Fail 'Expected error 515, but the load raised no error.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515 THROW;
    END CATCH;

    DECLARE @log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l);

    SELECT l.status, CAST(CASE WHEN l.error_message IS NULL THEN 0 ELSE 1 END AS bit) AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.log_id = @log_id;

    SELECT v.status, CAST(v.has_error_message AS bit) AS has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT p.substep, p.rows_affected
    INTO #FailedRunSteps
    FROM Layercake.etl_progress_log AS p
    WHERE p.log_id = @log_id
      AND p.substep IN (N'no_campaign_year_rows_not_landed', N'repeated_key_rows_not_landed');

    EXEC tSQLt.AssertEmptyTable '#FailedRunSteps';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-010 a row whose Campaign Year is set later is landed by the next load]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;

    UPDATE Subs.vwCorpSubscriptions SET [Sub Campaign Year] = 2027 WHERE [Contact No] = N'C2302';

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    DECLARE @log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l);

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.log_id = @log_id;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT b.contact_no, b.scheme_no, b.scheme_name, b.sub_campaign_year,
           CAST(b.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(b.sub_user_status AS varbinary(700)) AS sub_user_status_bytes,
           b._is_deleted
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b
    WHERE b.contact_no = N'C2302';

    SELECT v.contact_no, v.scheme_no, v.scheme_name, v.sub_campaign_year,
           CAST(v.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(v.sub_user_status AS varbinary(700)) AS sub_user_status_bytes,
           CAST(0 AS bit) AS _is_deleted
    INTO #Expected
    FROM (VALUES (N'C2302', N'SCH-031', N'Scheme Thirty-One', 2027, N'Inactive', N'Inactive'))
         AS v(contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription WHERE contact_no <> N'C2302';

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    DECLARE @live int = (SELECT COUNT(*) FROM Layercake.brnz_corporate_subscription WHERE _is_deleted = 0);
    EXEC tSQLt.AssertEquals 9, @live;

    SELECT p.substep, p.rows_affected
    INTO #ActualSteps
    FROM Layercake.etl_progress_log AS p
    WHERE p.log_id = @log_id
      AND p.substep IN (N'no_campaign_year_rows_not_landed', N'repeated_key_rows_not_landed');

    SELECT v.substep, v.rows_affected
    INTO #ExpectedSteps
    FROM (VALUES (N'no_campaign_year_rows_not_landed', 3),
                 (N'repeated_key_rows_not_landed', 9))
         AS v(substep, rows_affected);

    EXEC tSQLt.AssertEqualsTable '#ExpectedSteps', '#ActualSteps';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-011 two identical rows whose Campaign Year is set later land as one row and count one repeat]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    UPDATE Subs.vwCorpSubscriptions SET [Sub Campaign Year] = 2027 WHERE [Contact No] = N'C2301';

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    DECLARE @log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l);

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.log_id = @log_id;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT b.contact_no, b.scheme_no, b.scheme_name, b.sub_campaign_year,
           CAST(b.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(b.sub_user_status AS varbinary(700)) AS sub_user_status_bytes,
           b._is_deleted
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b
    WHERE b.contact_no = N'C2301';

    SELECT v.contact_no, v.scheme_no, v.scheme_name, v.sub_campaign_year,
           CAST(v.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(v.sub_user_status AS varbinary(700)) AS sub_user_status_bytes,
           CAST(0 AS bit) AS _is_deleted
    INTO #Expected
    FROM (VALUES (N'C2301', N'SCH-030', N'Scheme Thirty', 2027, N'Active', N'Active'))
         AS v(contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT p.substep, p.rows_affected
    INTO #ActualSteps
    FROM Layercake.etl_progress_log AS p
    WHERE p.log_id = @log_id
      AND p.substep IN (N'no_campaign_year_rows_not_landed', N'repeated_key_rows_not_landed');

    SELECT v.substep, v.rows_affected
    INTO #ExpectedSteps
    FROM (VALUES (N'no_campaign_year_rows_not_landed', 2),
                 (N'repeated_key_rows_not_landed', 10))
         AS v(substep, rows_affected);

    EXEC tSQLt.AssertEqualsTable '#ExpectedSteps', '#ActualSteps';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-012 a landed key whose rows all lose their Campaign Year is soft deleted]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription WHERE contact_no <> N'C2208';

    UPDATE Subs.vwCorpSubscriptions SET [Sub Campaign Year] = NULL WHERE [Contact No] = N'C2208';

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    DECLARE @log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l);

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.log_id = @log_id;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 0, 1)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT b.contact_no, b.scheme_no, b.sub_campaign_year, b._is_deleted,
           CAST(CASE WHEN b._deleted_at IS NULL THEN 0 ELSE 1 END AS bit) AS has_deleted_at
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b
    WHERE b.contact_no = N'C2208';

    SELECT v.contact_no, v.scheme_no, v.sub_campaign_year, CAST(1 AS bit) AS _is_deleted, CAST(1 AS bit) AS has_deleted_at
    INTO #Expected
    FROM (VALUES (N'C2208', N'SCH-020', 2025)) AS v(contact_no, scheme_no, sub_campaign_year);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription WHERE contact_no <> N'C2208';

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT p.substep, p.rows_affected
    INTO #ActualSteps
    FROM Layercake.etl_progress_log AS p
    WHERE p.log_id = @log_id
      AND p.substep IN (N'no_campaign_year_rows_not_landed', N'repeated_key_rows_not_landed');

    SELECT v.substep, v.rows_affected
    INTO #ExpectedSteps
    FROM (VALUES (N'no_campaign_year_rows_not_landed', 6),
                 (N'repeated_key_rows_not_landed', 8))
         AS v(substep, rows_affected);

    EXEC tSQLt.AssertEqualsTable '#ExpectedSteps', '#ActualSteps';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-013 a segment run makes C2301 Individual with one CORPORATE_FLAG_NO_SCHEME]
AS
BEGIN
    EXEC test_MOD025.[Arrange segment run];

    EXEC Layercake.usp_run_payment_segments @run_id = '25000000-0000-0000-0000-000000000013', @as_of_date = '2025-06-15';

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payer_type_id, a.corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payer_type_id, v.corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'C2201', 2025, 5, 2, N'SCH-020'),
                 (N'C2202', 2025, 5, 2, N'SCH-020'),
                 (N'C2203', 2025, 5, 1, CAST(NULL AS nvarchar(100))),
                 (N'C2204', 2025, 5, 1, NULL),
                 (N'C2205', 2025, 5, 1, NULL),
                 (N'C2206', 2025, 5, 1, NULL),
                 (N'C2207', 2025, 5, 1, NULL),
                 (N'C2208', 2025, 5, 2, N'SCH-020'),
                 (N'C2301', 2025, 5, 1, NULL))
         AS v(contact_no, campaign_year, payment_method_id, payer_type_id, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT d.anomaly_type, d.contact_no
    INTO #ActualAnomaly
    FROM Layercake.silv_data_anomaly AS d
    WHERE d.contact_no = N'C2301';

    SELECT v.anomaly_type, v.contact_no
    INTO #ExpectedAnomaly
    FROM (VALUES ('CORPORATE_FLAG_NO_SCHEME', N'C2301')) AS v(anomaly_type, contact_no);

    EXEC tSQLt.AssertEqualsTable '#ExpectedAnomaly', '#ActualAnomaly';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-014 a segment run raises the same anomalies with and without the rows with no Campaign Year]
AS
BEGIN
    EXEC test_MOD025.[Arrange segment run];

    EXEC Layercake.usp_run_payment_segments @run_id = '25000000-0000-0000-0000-00000000014a', @as_of_date = '2025-06-15';

    SELECT d.anomaly_type, d.contact_no, d.anomaly_nk
    INTO #RunA
    FROM Layercake.silv_data_anomaly AS d;

    SELECT d.anomaly_type, d.contact_no
    INTO #ActualRunA
    FROM #RunA AS d;

    SELECT v.anomaly_type, v.contact_no
    INTO #ExpectedRunA
    FROM (VALUES ('CORPORATE_FLAG_NO_SCHEME', N'C2203'),
                 ('CORPORATE_FLAG_NO_SCHEME', N'C2204'),
                 ('CORPORATE_FLAG_NO_SCHEME', N'C2205'),
                 ('CORPORATE_FLAG_NO_SCHEME', N'C2206'),
                 ('CORPORATE_FLAG_NO_SCHEME', N'C2207'),
                 ('CORPORATE_FLAG_NO_SCHEME', N'C2301'))
         AS v(anomaly_type, contact_no);

    EXEC tSQLt.AssertEqualsTable '#ExpectedRunA', '#ActualRunA';

    -- Run B: the same data without the 4 rows that have no Sub Campaign Year, from empty bronze and anomalies.
    DELETE FROM Layercake.brnz_corporate_subscription;
    DELETE FROM Layercake.silv_data_anomaly;
    DELETE FROM Subs.vwCorpSubscriptions WHERE [Sub Campaign Year] IS NULL;

    EXEC Layercake.usp_run_payment_segments @run_id = '25000000-0000-0000-0000-00000000014b', @as_of_date = '2025-06-15';

    SELECT d.anomaly_type, d.contact_no, d.anomaly_nk
    INTO #RunB
    FROM Layercake.silv_data_anomaly AS d;

    EXEC tSQLt.AssertEqualsTable '#RunA', '#RunB';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-015 one segment run over earlier bronze rows ends Success on every step and lands the 8 rows]
AS
BEGIN
    EXEC test_MOD025.[Arrange segment run];

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'C2201', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active', 0),
           (N'C2203', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Active', 0),
           (N'C2290', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active', 0);

    DECLARE @run_id uniqueidentifier = '25000000-0000-0000-0000-000000000015';

    EXEC Layercake.usp_run_payment_segments @run_id = @run_id, @as_of_date = '2025-06-15';

    SELECT l.status, COUNT(*) AS step_rows
    INTO #ActualStatus
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @run_id
    GROUP BY l.status;

    SELECT v.status, v.step_rows
    INTO #ExpectedStatus
    FROM (VALUES ('Success', 18)) AS v(status, step_rows);

    EXEC tSQLt.AssertEqualsTable '#ExpectedStatus', '#ActualStatus';

    SELECT l.layer, l.step_name, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualSteps
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @run_id
      AND l.step_name IN ('usp_run_payment_segments', 'brnz_corporate_subscription');

    SELECT v.layer, v.step_name, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedSteps
    FROM (VALUES ('run',    'usp_run_payment_segments',    'Success', CAST(NULL AS int), CAST(NULL AS int), CAST(NULL AS int)),
                 ('bronze', 'brnz_corporate_subscription', 'Success', 6, 1, 1))
         AS v(layer, step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedSteps', '#ActualSteps';

    SELECT b.contact_no, b.scheme_no, b.scheme_name, b.sub_campaign_year,
           CAST(b.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(b.sub_user_status AS varbinary(700)) AS sub_user_status_bytes,
           b._is_deleted
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.contact_no, v.scheme_no, v.scheme_name, v.sub_campaign_year,
           CAST(v.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(v.sub_user_status AS varbinary(700)) AS sub_user_status_bytes,
           CAST(v.is_deleted AS bit) AS _is_deleted
    INTO #Expected
    FROM (VALUES (N'C2201', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   0),
                 (N'C2202', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   0),
                 (N'C2203', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', 0),
                 (N'C2204', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', 0),
                 (N'C2205', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', 0),
                 (N'C2206', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', 0),
                 (N'C2207', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', 0),
                 (N'C2208', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   0),
                 (N'C2290', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   1))
         AS v(contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-016 one daily run over earlier bronze rows ends Success and lands the 8 rows]
AS
BEGIN
    EXEC test_MOD025.[Arrange daily run];

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'C2201', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active', 0),
           (N'C2203', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Active', 0),
           (N'C2290', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active', 0);

    EXEC Layercake.usp_run_daily_load;

    DECLARE @run_id uniqueidentifier =
        (SELECT l.run_id FROM Layercake.etl_run_log AS l WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load');

    SELECT l.status, COUNT(*) AS step_rows
    INTO #ActualStatus
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @run_id
    GROUP BY l.status;

    -- usp_run_daily_load, 3 Phase 1 stand-ins, usp_run_payment_segments and its 17 loads.
    SELECT v.status, v.step_rows
    INTO #ExpectedStatus
    FROM (VALUES ('Success', 22)) AS v(status, step_rows);

    EXEC tSQLt.AssertEqualsTable '#ExpectedStatus', '#ActualStatus';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLoad
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @run_id
      AND l.step_name = 'brnz_corporate_subscription';

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLoad
    FROM (VALUES ('Success', 6, 1, 1)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLoad', '#ActualLoad';

    SELECT b.contact_no, b.scheme_no, b.scheme_name, b.sub_campaign_year,
           CAST(b.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(b.sub_user_status AS varbinary(700)) AS sub_user_status_bytes,
           b._is_deleted
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS b;

    SELECT v.contact_no, v.scheme_no, v.scheme_name, v.sub_campaign_year,
           CAST(v.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(v.sub_user_status AS varbinary(700)) AS sub_user_status_bytes,
           CAST(v.is_deleted AS bit) AS _is_deleted
    INTO #Expected
    FROM (VALUES (N'C2201', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   0),
                 (N'C2202', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   0),
                 (N'C2203', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', 0),
                 (N'C2204', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', 0),
                 (N'C2205', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', 0),
                 (N'C2206', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', 0),
                 (N'C2207', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', 0),
                 (N'C2208', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   0),
                 (N'C2290', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   1))
         AS v(contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, is_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-017 a second daily run on unchanged data records 0 0 0 for the corporate subscription load]
AS
BEGIN
    EXEC test_MOD025.[Arrange daily run];

    EXEC Layercake.usp_run_daily_load;

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;

    EXEC Layercake.usp_run_daily_load;

    DECLARE @run_id uniqueidentifier =
        (SELECT l.run_id
         FROM Layercake.etl_run_log AS l
         WHERE l.log_id = (SELECT MAX(r.log_id) FROM Layercake.etl_run_log AS r
                           WHERE r.layer = 'run' AND r.step_name = 'usp_run_daily_load'));

    SELECT l.step_name, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLoad
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @run_id
      AND l.step_name IN ('usp_run_daily_load', 'brnz_corporate_subscription');

    SELECT v.step_name, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLoad
    FROM (VALUES ('usp_run_daily_load',          'Success', CAST(NULL AS int), CAST(NULL AS int), CAST(NULL AS int)),
                 ('brnz_corporate_subscription', 'Success', 0, 0, 0))
         AS v(step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLoad', '#ActualLoad';

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';
END;
GO
CREATE PROCEDURE test_MOD025.[test TC-025-018 a segment run ends Success and its corporate subscription step carries the count of rows with no Campaign Year]
AS
BEGIN
    EXEC test_MOD025.[Arrange segment run];

    DECLARE @run_id uniqueidentifier = '25000000-0000-0000-0000-000000000018';

    EXEC Layercake.usp_run_payment_segments @run_id = @run_id, @as_of_date = '2025-06-15';

    SELECT l.step_name, l.status, p.substep, p.rows_affected
    INTO #Actual
    FROM Layercake.etl_run_log AS l
    LEFT JOIN Layercake.etl_progress_log AS p
        ON  p.log_id = l.log_id
        AND p.substep = N'no_campaign_year_rows_not_landed'
    WHERE l.run_id = @run_id
      AND l.step_name IN ('usp_run_payment_segments', 'brnz_corporate_subscription');

    SELECT v.step_name, v.status, v.substep, v.rows_affected
    INTO #Expected
    FROM (VALUES ('usp_run_payment_segments',    'Success', CAST(NULL AS nvarchar(128)), CAST(NULL AS int)),
                 ('brnz_corporate_subscription', 'Success', N'no_campaign_year_rows_not_landed', 4))
         AS v(step_name, status, substep, rows_affected);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
