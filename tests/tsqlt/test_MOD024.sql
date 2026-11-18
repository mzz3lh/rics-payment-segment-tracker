EXEC tSQLt.NewTestClass 'test_MOD024';
GO

CREATE PROCEDURE test_MOD024.[SetUp]
AS
BEGIN
    -- The module's source, target and logging.
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;

    -- Inputs and targets of the two readers run for real in the full-run tests
    -- (usp_load_silv_member_year_attributes, usp_load_silv_data_anomaly_segment).
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_invoice_line_type';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes';
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1;

    -- Loads MOD-024 does not change and that do not read brnz_corporate_subscription:
    -- stand-ins that log one Success step under the run_id they receive.
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_brnz_subs_invoice', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''bronze'', ''brnz_subs_invoice'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_brnz_subs_invoice_line', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''bronze'', ''brnz_subs_invoice_line'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_brnz_concession', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''bronze'', ''brnz_concession'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_silv_ref_invoice_line_type', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''silv_ref_invoice_line_type'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_silv_ref_currency', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''silv_ref_currency'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_silv_ref_concession_type', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''silv_ref_concession_type'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_dim_payment_method', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''dim_payment_method'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_dim_payer_type', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''dim_payer_type'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_dim_currency', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''dim_currency'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_dim_concession_type', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''dim_concession_type'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_silv_event_amount', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''silv_event_amount'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_silv_data_anomaly_invoice', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''silv_data_anomaly_invoice'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_silv_membership_events_segments', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''silv_membership_events_segments'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_fact_membership_events_segments', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''fact_membership_events_segments'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', 0, 0, 0;';
    -- Phase 1 orchestrators of the daily run (unchanged, tested by their own suites).
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_bronze', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''bronze'', ''phase1_bronze_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_silver', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''phase1_silver_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_gold', @CommandToExecute = 'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''phase1_gold_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';

    -- AC-022-01 to AC-022-06: 17 source rows on 8 keys, Scheme No SCH-020, Sub Campaign Year 2025.
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES
        (N'C2201', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   '2024-10-01', N'Round 1'),
        (N'C2202', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Inactive', '2024-10-01', N'Round 1'),
        (N'C2202', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Inactive', '2024-12-01', N'Round 2'),
        (N'C2202', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   '2024-11-01', N'Round 3'),
        (N'C2202', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Inactive', '2025-01-10', N'Round 4'),
        (N'C2203', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Active',   '2024-10-01', N'Round 3'),
        (N'C2203', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', '2024-11-15', N'Round 1'),
        (N'C2204', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Active',   NULL,         N'Round 4'),
        (N'C2204', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', '2024-10-05', N'Round 1'),
        (N'C2205', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Active',   '2024-10-01', N'Round 9'),
        (N'C2205', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 10'),
        (N'C2206', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Active',   '2024-10-01', NULL),
        (N'C2206', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 1'),
        (N'C2207', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Active',   '2024-10-01', N'Round X'),
        (N'C2207', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 2'),
        (N'C2208', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   '2024-10-01', N'Round 1'),
        (N'C2208', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   '2024-10-01', N'Round 1');

    -- Campaign Years 2021 to 2060 (1 October to 30 September).
    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    SELECT n.y, DATEFROMPARTS(n.y - 1, 10, 1), DATEFROMPARTS(n.y, 9, 30), DATEFROMPARTS(n.y, 9, 30)
    FROM (SELECT TOP (40) 2020 + ROW_NUMBER() OVER (ORDER BY o.object_id) AS y
          FROM sys.all_objects AS o) AS n;

    -- Seeded reference lists.
    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code)
    VALUES (0, 'Unknown', NULL), (-1, 'Unrecognised', NULL), (-2, 'Not applicable', NULL),
           (1, 'Direct Debit', 'DD'), (2, 'Card', 'Card'), (3, 'Bank transfer', 'Bank'),
           (4, 'Cheque', 'Cheque'), (5, 'Corporate', 'Corporate');
    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name)
    VALUES (0, 'Unknown'), (-1, 'Unrecognised'), (-2, 'Not applicable'), (1, 'Individual'), (2, 'Corporate');
    INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0), (-1, NULL, N'Unrecognised', NULL, 0, 0),
           (-2, NULL, N'Not applicable', NULL, 0, 0), (1, NULL, N'No concession', NULL, 0, 0);

    -- Phase 1 state: a 2025 Renewal and a 2025 paid position for each of the 8 contacts.
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id,
         rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES
        (2201, N'RN:C2201:2025', 'Renewal', 'Standard', '2024-10-15', N'C2201', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0),
        (2202, N'RN:C2202:2025', 'Renewal', 'Standard', '2024-10-15', N'C2202', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0),
        (2203, N'RN:C2203:2025', 'Renewal', 'Standard', '2024-10-15', N'C2203', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0),
        (2204, N'RN:C2204:2025', 'Renewal', 'Standard', '2024-10-15', N'C2204', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0),
        (2205, N'RN:C2205:2025', 'Renewal', 'Standard', '2024-10-15', N'C2205', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0),
        (2206, N'RN:C2206:2025', 'Renewal', 'Standard', '2024-10-15', N'C2206', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0),
        (2207, N'RN:C2207:2025', 'Renewal', 'Standard', '2024-10-15', N'C2207', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0),
        (2208, N'RN:C2208:2025', 'Renewal', 'Standard', '2024-10-15', N'C2208', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0);

    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'C2201', 2025, '2024-10-10', '2024-10-10', N'Fully Paid'), (N'C2202', 2025, '2024-10-10', '2024-10-10', N'Fully Paid'),
           (N'C2203', 2025, '2024-10-10', '2024-10-10', N'Fully Paid'), (N'C2204', 2025, '2024-10-10', '2024-10-10', N'Fully Paid'),
           (N'C2205', 2025, '2024-10-10', '2024-10-10', N'Fully Paid'), (N'C2206', 2025, '2024-10-10', '2024-10-10', N'Fully Paid'),
           (N'C2207', 2025, '2024-10-10', '2024-10-10', N'Fully Paid'), (N'C2208', 2025, '2024-10-10', '2024-10-10', N'Fully Paid');

    -- One live 2025 subscription invoice per contact, payment mode Corporate, GBP, not credited, no lines.
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, invoice_amount_gbp, fully_credited, payment_status, has_concession, full_concession_flag,
         _loaded_at, _updated_at, _is_deleted, _deleted_at)
    VALUES
        (22010, N'C2201', 2025, N'INV-2201', N'V2201', '2024-10-10', N'Corporate', N'GBP', 450.00, 450.00, N'N', N'Fully Paid', N'N', N'N', SYSDATETIME(), SYSDATETIME(), 0, NULL),
        (22020, N'C2202', 2025, N'INV-2202', N'V2202', '2024-10-10', N'Corporate', N'GBP', 450.00, 450.00, N'N', N'Fully Paid', N'N', N'N', SYSDATETIME(), SYSDATETIME(), 0, NULL),
        (22030, N'C2203', 2025, N'INV-2203', N'V2203', '2024-10-10', N'Corporate', N'GBP', 450.00, 450.00, N'N', N'Fully Paid', N'N', N'N', SYSDATETIME(), SYSDATETIME(), 0, NULL),
        (22040, N'C2204', 2025, N'INV-2204', N'V2204', '2024-10-10', N'Corporate', N'GBP', 450.00, 450.00, N'N', N'Fully Paid', N'N', N'N', SYSDATETIME(), SYSDATETIME(), 0, NULL),
        (22050, N'C2205', 2025, N'INV-2205', N'V2205', '2024-10-10', N'Corporate', N'GBP', 450.00, 450.00, N'N', N'Fully Paid', N'N', N'N', SYSDATETIME(), SYSDATETIME(), 0, NULL),
        (22060, N'C2206', 2025, N'INV-2206', N'V2206', '2024-10-10', N'Corporate', N'GBP', 450.00, 450.00, N'N', N'Fully Paid', N'N', N'N', SYSDATETIME(), SYSDATETIME(), 0, NULL),
        (22070, N'C2207', 2025, N'INV-2207', N'V2207', '2024-10-10', N'Corporate', N'GBP', 450.00, 450.00, N'N', N'Fully Paid', N'N', N'N', SYSDATETIME(), SYSDATETIME(), 0, NULL),
        (22080, N'C2208', 2025, N'INV-2208', N'V2208', '2024-10-10', N'Corporate', N'GBP', 450.00, 450.00, N'N', N'Fully Paid', N'N', N'N', SYSDATETIME(), SYSDATETIME(), 0, NULL);
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-001 the 17 row source lands 8 live rows one per key and logs Success]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT r.status, r.rows_inserted, r.rows_updated, r.rows_deleted, r.error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS r
    WHERE r.step_name = 'brnz_corporate_subscription';

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted, v.error_message
    INTO #ExpectedLog
    FROM (VALUES ('Success', 8, 0, 0, CAST(NULL AS nvarchar(4000)))) AS v(status, rows_inserted, rows_updated, rows_deleted, error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT t.contact_no, t.scheme_no, t.sub_campaign_year
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t
    WHERE t._is_deleted = 0;

    SELECT v.contact_no, v.scheme_no, v.sub_campaign_year
    INTO #Expected
    FROM (VALUES (N'C2201', N'SCH-020', 2025), (N'C2202', N'SCH-020', 2025), (N'C2203', N'SCH-020', 2025),
                 (N'C2204', N'SCH-020', 2025), (N'C2205', N'SCH-020', 2025), (N'C2206', N'SCH-020', 2025),
                 (N'C2207', N'SCH-020', 2025), (N'C2208', N'SCH-020', 2025)) AS v(contact_no, scheme_no, sub_campaign_year);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @repeated_live_keys int =
        (SELECT COUNT(*)
         FROM (SELECT t.contact_no, t.scheme_no, t.sub_campaign_year
               FROM Layercake.brnz_corporate_subscription AS t
               WHERE t._is_deleted = 0
               GROUP BY t.contact_no, t.scheme_no, t.sub_campaign_year
               HAVING COUNT(*) > 1) AS d);
    EXEC tSQLt.AssertEquals 0, @repeated_live_keys;
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-002 the load logs 9 source rows not landed as the repeated key sub-step]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT p.substep, p.rows_affected
    INTO #Actual
    FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS r
        ON r.log_id = p.log_id
    WHERE r.step_name = 'brnz_corporate_subscription'
      AND p.substep = N'repeated_key_rows_not_landed';

    SELECT v.substep, v.rows_affected
    INTO #Expected
    FROM (VALUES (N'repeated_key_rows_not_landed', 9)) AS v(substep, rows_affected);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-003 a single row key lands as it is and the Active Active copy beats a later date and higher Round]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT t.contact_no, t.scheme_no, t.scheme_name, t.sub_campaign_year,
           CAST(t.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t
    WHERE t._is_deleted = 0
      AND t.contact_no IN (N'C2201', N'C2202');

    SELECT v.contact_no, v.scheme_no, v.scheme_name, v.sub_campaign_year, v.sub_status_bytes, v.sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (N'C2201', N'SCH-020', N'Scheme Twenty', 2025, CAST(N'Active' AS varbinary(700)), CAST(N'Active' AS varbinary(700))),
                 (N'C2202', N'SCH-020', N'Scheme Twenty', 2025, CAST(N'Active' AS varbinary(700)), CAST(N'Active' AS varbinary(700))))
         AS v(contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status_bytes, sub_user_status_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-004 with no Active Active copy the later created date beats the higher Round]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT t.contact_no,
           CAST(t.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t
    WHERE t._is_deleted = 0
      AND t.contact_no = N'C2203';

    SELECT v.contact_no, v.sub_status_bytes, v.sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (N'C2203', CAST(N'Inactive' AS varbinary(700)), CAST(N'Inactive' AS varbinary(700))))
         AS v(contact_no, sub_status_bytes, sub_user_status_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-005 a copy with a NULL created date loses to a dated copy]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT t.contact_no,
           CAST(t.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t
    WHERE t._is_deleted = 0
      AND t.contact_no = N'C2204';

    SELECT v.contact_no, v.sub_status_bytes, v.sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (N'C2204', CAST(N'Inactive' AS varbinary(700)), CAST(N'Inactive' AS varbinary(700))))
         AS v(contact_no, sub_status_bytes, sub_user_status_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-006 Round compares by its trailing number with NULL or no number lowest]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT t.contact_no,
           CAST(t.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t
    WHERE t._is_deleted = 0
      AND t.contact_no IN (N'C2205', N'C2206', N'C2207');

    SELECT v.contact_no, v.sub_status_bytes, v.sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (N'C2205', CAST(N'Inactive' AS varbinary(700)), CAST(N'Inactive' AS varbinary(700))),
                 (N'C2206', CAST(N'Inactive' AS varbinary(700)), CAST(N'Inactive' AS varbinary(700))),
                 (N'C2207', CAST(N'Inactive' AS varbinary(700)), CAST(N'Inactive' AS varbinary(700))))
         AS v(contact_no, sub_status_bytes, sub_user_status_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-007 two identical copies land as exactly one row with their values]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT t.contact_no, t.scheme_no, t.scheme_name, t.sub_campaign_year, t._is_deleted,
           CAST(t.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t
    WHERE t.contact_no = N'C2208';

    SELECT v.contact_no, v.scheme_no, v.scheme_name, v.sub_campaign_year, v._is_deleted, v.sub_status_bytes, v.sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (N'C2208', N'SCH-020', N'Scheme Twenty', 2025, CAST(0 AS bit),
                  CAST(N'Active' AS varbinary(700)), CAST(N'Active' AS varbinary(700))))
         AS v(contact_no, scheme_no, scheme_name, sub_campaign_year, _is_deleted, sub_status_bytes, sub_user_status_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-008 a second load on the unchanged source logs 0 0 0 changes nothing and logs 9 again]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    DECLARE @second_log bigint =
        (SELECT MAX(r.log_id) FROM Layercake.etl_run_log AS r WHERE r.step_name = 'brnz_corporate_subscription');

    SELECT r.status, r.rows_inserted, r.rows_updated, r.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS r
    WHERE r.log_id = @second_log;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT p.rows_affected
    INTO #ActualStep
    FROM Layercake.etl_progress_log AS p
    WHERE p.log_id = @second_log
      AND p.substep = N'repeated_key_rows_not_landed';

    SELECT v.rows_affected
    INTO #ExpectedStep
    FROM (VALUES (9)) AS v(rows_affected);
    EXEC tSQLt.AssertEqualsTable '#ExpectedStep', '#ActualStep';

    DECLARE @live int = (SELECT COUNT(*) FROM Layercake.brnz_corporate_subscription AS t WHERE t._is_deleted = 0);
    EXEC tSQLt.AssertEquals 8, @live;
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-009 the same source returned in another row order lands the same rows and logs 0 0 0]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;
    SELECT * INTO #Source FROM Subs.vwCorpSubscriptions;

    DELETE FROM Subs.vwCorpSubscriptions;
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    SELECT s.[Contact No], s.[Scheme No], s.[Scheme Name], s.[Sub Campaign Year], s.[Sub Status], s.[Sub User Status], s.[Sub User Created Date], s.[Round]
    FROM #Source AS s
    ORDER BY s.[Contact No] DESC, s.[Sub User Status] DESC, s.[Sub User Created Date] DESC, s.[Round] DESC;

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT r.status, r.rows_inserted, r.rows_updated, r.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS r
    WHERE r.log_id = (SELECT MAX(x.log_id) FROM Layercake.etl_run_log AS x WHERE x.step_name = 'brnz_corporate_subscription');

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-010 a source with no repeated key logs 0 source rows not landed]
AS
BEGIN
    DELETE FROM Subs.vwCorpSubscriptions;
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES
        (N'P1',  N'SCH-001', N'Scheme One',   2025, N'Active', N'Active',   '2024-10-01', N'1'),
        (N'P6',  N'SCH-006', N'Scheme Six',   2025, N'Active', N'Active',   '2024-10-01', N'1'),
        (N'P7',  N'SCH-007', N'Scheme Seven', 2025, N'Active', N'Inactive', '2024-10-01', N'1'),
        (N'P10', N'SCH-010', N'Scheme Ten',   2025, N'Active', N'Active',   '2024-10-01', N'1');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT r.status, r.rows_inserted, r.rows_updated, r.rows_deleted, p.substep, p.rows_affected
    INTO #Actual
    FROM Layercake.etl_run_log AS r
    INNER JOIN Layercake.etl_progress_log AS p
        ON  p.log_id = r.log_id
        AND p.substep = N'repeated_key_rows_not_landed'
    WHERE r.step_name = 'brnz_corporate_subscription';

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted, v.substep, v.rows_affected
    INTO #Expected
    FROM (VALUES ('Success', 4, 0, 0, N'repeated_key_rows_not_landed', 0))
         AS v(status, rows_inserted, rows_updated, rows_deleted, substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @live int = (SELECT COUNT(*) FROM Layercake.brnz_corporate_subscription AS t WHERE t._is_deleted = 0);
    EXEC tSQLt.AssertEquals 4, @live;
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-011 Round number ignores outer spaces uses a value with no space whole and compares by value]
AS
BEGIN
    DELETE FROM Subs.vwCorpSubscriptions;
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES
        (N'C2401', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Active',   '2024-10-01', N'Round 6'),
        (N'C2401', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Inactive', '2024-10-01', N'  Round 7  '),
        (N'C2402', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Active',   '2024-10-01', N'Round 9'),
        (N'C2402', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Inactive', '2024-10-01', N'12'),
        (N'C2403', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Active',   '2024-10-01', N'Round 1a'),
        (N'C2403', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 0'),
        (N'C2404', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Active',   '2024-10-01', N'Round 9'),
        (N'C2404', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 0010'),
        (N'C2405', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 10'),
        (N'C2405', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Active',   '2024-10-01', N'10'),
        (N'C2406', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round'),
        (N'C2406', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Active',   '2024-10-01', N'   ');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT t.contact_no, CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t
    WHERE t._is_deleted = 0;

    SELECT v.contact_no, v.sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (N'C2401', CAST(N'Inactive' AS varbinary(700))),
                 (N'C2402', CAST(N'Inactive' AS varbinary(700))),
                 (N'C2403', CAST(N'Inactive' AS varbinary(700))),
                 (N'C2404', CAST(N'Inactive' AS varbinary(700))),
                 (N'C2405', CAST(N'Active' AS varbinary(700))),
                 (N'C2406', CAST(N'Active' AS varbinary(700))))
         AS v(contact_no, sub_user_status_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-012 copies that all lack a created date go on to Round and a dated copy beats undated ones]
AS
BEGIN
    DELETE FROM Subs.vwCorpSubscriptions;
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES
        (N'C2411', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Active',   NULL,         N'Round 2'),
        (N'C2411', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Inactive', NULL,         N'Round 5'),
        (N'C2412', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Active',   NULL,         N'Round 9'),
        (N'C2412', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Pending',  NULL,         N'Round 8'),
        (N'C2412', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 1');

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT t.contact_no, CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t
    WHERE t._is_deleted = 0;

    SELECT v.contact_no, v.sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (N'C2411', CAST(N'Inactive' AS varbinary(700))),
                 (N'C2412', CAST(N'Inactive' AS varbinary(700))))
         AS v(contact_no, sub_user_status_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @not_landed int =
        (SELECT p.rows_affected FROM Layercake.etl_progress_log AS p WHERE p.substep = N'repeated_key_rows_not_landed');
    EXEC tSQLt.AssertEquals 3, @not_landed;
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-013 the final tie-break takes the missing then exactly first sub_user_status]
AS
BEGIN
    DELETE FROM Subs.vwCorpSubscriptions;
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES
        (N'C2421', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Inactive', '2024-10-01', NULL),
        (N'C2421', N'SCH-024', N'Scheme 24', 2025, N'Inactive', NULL,        '2024-10-01', N'Round X'),
        (N'C2422', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Inactive', '2024-10-01', NULL),
        (N'C2422', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'INACTIVE', '2024-10-01', NULL),
        (N'C2423', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Removed',  '2024-10-01', N'Round'),
        (N'C2423', N'SCH-024', N'Scheme 24', 2025, N'Inactive', N'Expired',  '2024-10-01', NULL);

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT t.contact_no, CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t
    WHERE t._is_deleted = 0;

    SELECT v.contact_no, v.sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (N'C2421', CAST(NULL AS varbinary(700))),
                 (N'C2422', CAST(N'INACTIVE' AS varbinary(700))),
                 (N'C2423', CAST(N'Expired' AS varbinary(700))))
         AS v(contact_no, sub_user_status_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-014 the final tie-break goes on to sub_status and then scheme_name]
AS
BEGIN
    DELETE FROM Subs.vwCorpSubscriptions;
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES
        (N'C2431', N'SCH-024', N'Scheme 24', 2025, N'Lapsed',    N'Inactive', '2024-10-01', NULL),
        (N'C2431', N'SCH-024', N'Scheme 24', 2025, N'Cancelled', N'Inactive', '2024-10-01', NULL),
        (N'C2432', N'SCH-024', N'Scheme B',  2025, N'Inactive',  N'Inactive', '2024-10-01', NULL),
        (N'C2432', N'SCH-024', NULL,         2025, N'Inactive',  N'Inactive', '2024-10-01', NULL),
        (N'C2433', N'SCH-024', N'scheme a',  2025, N'Inactive',  N'Inactive', '2024-10-01', NULL),
        (N'C2433', N'SCH-024', N'Scheme a',  2025, N'Inactive',  N'Inactive', '2024-10-01', NULL);

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT t.contact_no,
           CAST(t.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(t.scheme_name AS varbinary(8000)) AS scheme_name_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t
    WHERE t._is_deleted = 0;

    SELECT v.contact_no, v.sub_status_bytes, v.scheme_name_bytes
    INTO #Expected
    FROM (VALUES (N'C2431', CAST(N'Cancelled' AS varbinary(700)), CAST(N'Scheme 24' AS varbinary(8000))),
                 (N'C2432', CAST(N'Inactive' AS varbinary(700)),  CAST(NULL AS varbinary(8000))),
                 (N'C2433', CAST(N'Inactive' AS varbinary(700)),  CAST(N'Scheme a' AS varbinary(8000))))
         AS v(contact_no, sub_status_bytes, scheme_name_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-015 a source change that makes another copy win updates only that row]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription WHERE contact_no <> N'C2203';

    UPDATE Subs.vwCorpSubscriptions
    SET [Sub User Created Date] = '2024-09-01'
    WHERE [Contact No] = N'C2203'
      AND [Sub User Status] = N'Inactive';

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription WHERE contact_no <> N'C2203';
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT t.contact_no, t._is_deleted,
           CAST(t.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t
    WHERE t.contact_no = N'C2203';

    SELECT v.contact_no, v._is_deleted, v.sub_status_bytes, v.sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (N'C2203', CAST(0 AS bit), CAST(N'Inactive' AS varbinary(700)), CAST(N'Active' AS varbinary(700))))
         AS v(contact_no, _is_deleted, sub_status_bytes, sub_user_status_bytes);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT r.status, r.rows_inserted, r.rows_updated, r.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS r
    WHERE r.log_id = (SELECT MAX(x.log_id) FROM Layercake.etl_run_log AS x WHERE x.step_name = 'brnz_corporate_subscription');

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-016 a repeated key gone from the source is soft deleted and the distinct key check still passes]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    DELETE FROM Subs.vwCorpSubscriptions WHERE [Contact No] = N'C2202';

    EXEC Layercake.usp_load_brnz_corporate_subscription;

    DECLARE @second_log bigint =
        (SELECT MAX(r.log_id) FROM Layercake.etl_run_log AS r WHERE r.step_name = 'brnz_corporate_subscription');

    SELECT r.status, r.rows_inserted, r.rows_updated, r.rows_deleted, p.rows_affected
    INTO #ActualLog
    FROM Layercake.etl_run_log AS r
    LEFT JOIN Layercake.etl_progress_log AS p
        ON  p.log_id = r.log_id
        AND p.substep = N'repeated_key_rows_not_landed'
    WHERE r.log_id = @second_log;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted, v.rows_affected
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 0, 1, 6)) AS v(status, rows_inserted, rows_updated, rows_deleted, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT t.contact_no, t._is_deleted, CASE WHEN t._deleted_at IS NULL THEN 0 ELSE 1 END AS has_deleted_at
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t
    WHERE t.contact_no = N'C2202';

    SELECT v.contact_no, v._is_deleted, v.has_deleted_at
    INTO #Expected
    FROM (VALUES (N'C2202', CAST(1 AS bit), 1)) AS v(contact_no, _is_deleted, has_deleted_at);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @live int = (SELECT COUNT(*) FROM Layercake.brnz_corporate_subscription AS t WHERE t._is_deleted = 0);
    EXEC tSQLt.AssertEquals 7, @live;
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-017 a full segment run raises the same anomalies on the repeated source as on its 8 landed copies]
AS
BEGIN
    DECLARE @run_a uniqueidentifier = 'A0000000-0000-0000-0000-000000000024',
            @run_b uniqueidentifier = 'B0000000-0000-0000-0000-000000000024';

    EXEC Layercake.usp_run_payment_segments @run_id = @run_a, @as_of_date = '2025-06-15';

    SELECT a.anomaly_type, a.contact_no, a.anomaly_nk
    INTO #WithRepeats
    FROM Layercake.silv_data_anomaly AS a;

    -- Same run on a source holding only the 8 copies AC-022-01 to AC-022-06 land.
    DELETE FROM Layercake.brnz_corporate_subscription;
    DELETE FROM Layercake.silv_member_year_attributes;
    DELETE FROM Layercake.silv_data_anomaly;
    DELETE FROM Subs.vwCorpSubscriptions;
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES
        (N'C2201', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   '2024-10-01', N'Round 1'),
        (N'C2202', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   '2024-11-01', N'Round 3'),
        (N'C2203', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', '2024-11-15', N'Round 1'),
        (N'C2204', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', '2024-10-05', N'Round 1'),
        (N'C2205', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 10'),
        (N'C2206', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 1'),
        (N'C2207', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Inactive', '2024-10-01', N'Round 2'),
        (N'C2208', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active',   '2024-10-01', N'Round 1');

    EXEC Layercake.usp_run_payment_segments @run_id = @run_b, @as_of_date = '2025-06-15';

    SELECT a.anomaly_type, a.contact_no, a.anomaly_nk
    INTO #SingleCopies
    FROM Layercake.silv_data_anomaly AS a;

    EXEC tSQLt.AssertEqualsTable '#SingleCopies', '#WithRepeats';

    SELECT w.anomaly_type, w.contact_no
    INTO #Actual
    FROM #WithRepeats AS w;

    SELECT v.anomaly_type, v.contact_no
    INTO #Expected
    FROM (VALUES ('CORPORATE_FLAG_NO_SCHEME', N'C2203'), ('CORPORATE_FLAG_NO_SCHEME', N'C2204'),
                 ('CORPORATE_FLAG_NO_SCHEME', N'C2205'), ('CORPORATE_FLAG_NO_SCHEME', N'C2206'),
                 ('CORPORATE_FLAG_NO_SCHEME', N'C2207')) AS v(anomaly_type, contact_no);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD024.[test TC-024-018 a NULL Scheme No after a good load fails with 515 logs Failed and leaves the 8 rows]
AS
BEGIN
    EXEC Layercake.usp_load_brnz_corporate_subscription;

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;

    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES (N'C2209', NULL, N'Scheme Twenty', 2025, N'Active', N'Active', '2024-10-01', N'Round 1');

    DECLARE @err int = NULL;
    BEGIN TRY
        EXEC Layercake.usp_load_brnz_corporate_subscription;
        EXEC tSQLt.Fail 'Expected error 515 from usp_load_brnz_corporate_subscription, but no error was raised.';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_NUMBER();
        IF @err <> 515 THROW;
    END CATCH;

    EXEC tSQLt.AssertEquals 515, @err;

    SELECT r.status, CASE WHEN r.error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS r
    WHERE r.log_id = (SELECT MAX(x.log_id) FROM Layercake.etl_run_log AS x WHERE x.step_name = 'brnz_corporate_subscription');

    SELECT v.status, v.has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_error_message);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD024.[test TC-024-019 a NULL Sub Campaign Year on a repeated contact fails with 515 and changes nothing]
AS
BEGIN
    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status)
    VALUES (N'C2201', N'SCH-020', N'Scheme Twenty', 2025, N'Active', N'Active');

    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES (N'C2203', N'SCH-020', N'Scheme Twenty', NULL, N'Inactive', N'Inactive', '2024-12-01', N'Round 2');

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;

    DECLARE @err int = NULL;
    BEGIN TRY
        EXEC Layercake.usp_load_brnz_corporate_subscription;
        EXEC tSQLt.Fail 'Expected error 515 from usp_load_brnz_corporate_subscription, but no error was raised.';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_NUMBER();
        IF @err <> 515 THROW;
    END CATCH;

    EXEC tSQLt.AssertEquals 515, @err;

    SELECT r.status, CASE WHEN r.error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS r
    WHERE r.step_name = 'brnz_corporate_subscription';

    SELECT v.status, v.has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_error_message);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-020 C2202 is Corporate on SCH-020 and C2203 Individual with one CORPORATE_FLAG_NO_SCHEME]
AS
BEGIN
    EXEC Layercake.usp_run_payment_segments @run_id = 'C0000000-0000-0000-0000-000000000024', @as_of_date = '2025-06-15';

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payer_type_id, a.corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payer_type_id, v.corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'C2201', 2025, 5, 2, N'SCH-020'), (N'C2202', 2025, 5, 2, N'SCH-020'),
                 (N'C2203', 2025, 5, 1, CAST(NULL AS nvarchar(100))), (N'C2204', 2025, 5, 1, CAST(NULL AS nvarchar(100))),
                 (N'C2205', 2025, 5, 1, CAST(NULL AS nvarchar(100))), (N'C2206', 2025, 5, 1, CAST(NULL AS nvarchar(100))),
                 (N'C2207', 2025, 5, 1, CAST(NULL AS nvarchar(100))), (N'C2208', 2025, 5, 2, N'SCH-020'))
         AS v(contact_no, campaign_year, payment_method_id, payer_type_id, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @c2202 int = (SELECT COUNT(*) FROM Layercake.silv_data_anomaly AS d
                          WHERE d.anomaly_type = 'CORPORATE_FLAG_NO_SCHEME' AND d.contact_no = N'C2202');
    DECLARE @c2203 int = (SELECT COUNT(*) FROM Layercake.silv_data_anomaly AS d
                          WHERE d.anomaly_type = 'CORPORATE_FLAG_NO_SCHEME' AND d.contact_no = N'C2203');
    EXEC tSQLt.AssertEquals 0, @c2202;
    EXEC tSQLt.AssertEquals 1, @c2203;
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-021 the table keeps its structure and key and the five readers still read it]
AS
BEGIN
    DECLARE @obj int =
        (SELECT TOP (1) l.ObjectId
         FROM tSQLt.Private_RenamedObjectLog AS l
         WHERE REPLACE(REPLACE(l.OriginalName, '[', ''), ']', '') IN (N'brnz_corporate_subscription', N'Layercake.brnz_corporate_subscription')
           AND OBJECT_SCHEMA_NAME(l.ObjectId) = N'Layercake'
           AND OBJECT_NAME(l.ObjectId) IS NOT NULL
         ORDER BY l.Id DESC);

    SELECT ROW_NUMBER() OVER (ORDER BY c.column_id) AS ordinal,
           CAST(c.name AS nvarchar(128)) AS column_name,
           CAST(TYPE_NAME(c.user_type_id) AS nvarchar(128)) AS type_name,
           CAST(c.max_length AS int) AS max_length,
           CAST(c.scale AS int) AS scale,
           CAST(c.is_nullable AS int) AS is_nullable
    INTO #ActualColumns
    FROM sys.columns AS c
    WHERE c.object_id = @obj;

    SELECT v.ordinal, v.column_name, v.type_name, v.max_length, v.scale, v.is_nullable
    INTO #ExpectedColumns
    FROM (VALUES (CAST(1 AS bigint), N'contact_no', N'nvarchar', 200, 0, 0),
                 (2, N'scheme_no', N'nvarchar', 200, 0, 0),
                 (3, N'scheme_name', N'nvarchar', 8000, 0, 1),
                 (4, N'sub_campaign_year', N'int', 4, 0, 0),
                 (5, N'sub_status', N'nvarchar', 700, 0, 1),
                 (6, N'sub_user_status', N'nvarchar', 700, 0, 1),
                 (7, N'_loaded_at', N'datetime2', 7, 3, 0),
                 (8, N'_updated_at', N'datetime2', 7, 3, 0),
                 (9, N'_is_deleted', N'bit', 1, 0, 0),
                 (10, N'_deleted_at', N'datetime2', 7, 3, 1))
         AS v(ordinal, column_name, type_name, max_length, scale, is_nullable);

    EXEC tSQLt.AssertEqualsTable '#ExpectedColumns', '#ActualColumns';

    SELECT CAST(ic.key_ordinal AS int) AS key_ordinal, CAST(c.name AS nvarchar(128)) AS column_name
    INTO #ActualKey
    FROM sys.indexes AS i
    INNER JOIN sys.index_columns AS ic
        ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    INNER JOIN sys.columns AS c
        ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = @obj
      AND i.is_primary_key = 1;

    SELECT v.key_ordinal, v.column_name
    INTO #ExpectedKey
    FROM (VALUES (1, N'contact_no'), (2, N'scheme_no'), (3, N'sub_campaign_year')) AS v(key_ordinal, column_name);

    EXEC tSQLt.AssertEqualsTable '#ExpectedKey', '#ActualKey';

    SELECT r.reader
    INTO #ActualReaders
    FROM (VALUES (N'usp_load_silv_member_year_attributes'), (N'usp_load_silv_data_anomaly_segment'),
                 (N'usp_report_employer_scheme_coverage'), (N'usp_report_employer_source_agreement'),
                 (N'usp_report_top_employers')) AS r(reader)
    WHERE OBJECT_ID(N'Layercake.' + r.reader, N'P') IS NOT NULL
      AND EXISTS (SELECT 1
                  FROM sys.sql_expression_dependencies AS d
                  WHERE d.referencing_id = OBJECT_ID(N'Layercake.' + r.reader, N'P')
                    AND d.referenced_schema_name = N'Layercake'
                    AND d.referenced_entity_name = N'brnz_corporate_subscription');

    SELECT v.reader
    INTO #ExpectedReaders
    FROM (VALUES (N'usp_load_silv_member_year_attributes'), (N'usp_load_silv_data_anomaly_segment'),
                 (N'usp_report_employer_scheme_coverage'), (N'usp_report_employer_source_agreement'),
                 (N'usp_report_top_employers')) AS v(reader);

    EXEC tSQLt.AssertEqualsTable '#ExpectedReaders', '#ActualReaders';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-022 one segment run over earlier bronze rows ends Success on every step and lands the 8 rows]
AS
BEGIN
    DECLARE @run_id uniqueidentifier = 'D0000000-0000-0000-0000-000000000024';

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status)
    VALUES (N'C2201', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active'),
           (N'C2203', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Active'),
           (N'C2290', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active');

    EXEC Layercake.usp_run_payment_segments @run_id = @run_id, @as_of_date = '2025-06-15';

    SELECT r.layer, r.step_name, r.status
    INTO #ActualSteps
    FROM Layercake.etl_run_log AS r
    WHERE r.run_id = @run_id;

    SELECT v.layer, v.step_name, v.status
    INTO #ExpectedSteps
    FROM (VALUES ('run', 'usp_run_payment_segments', 'Success'),
                 ('bronze', 'brnz_subs_invoice', 'Success'), ('bronze', 'brnz_subs_invoice_line', 'Success'),
                 ('bronze', 'brnz_corporate_subscription', 'Success'), ('bronze', 'brnz_concession', 'Success'),
                 ('silver', 'silv_ref_invoice_line_type', 'Success'), ('silver', 'silv_ref_currency', 'Success'),
                 ('silver', 'silv_ref_concession_type', 'Success'),
                 ('gold', 'dim_payment_method', 'Success'), ('gold', 'dim_payer_type', 'Success'),
                 ('gold', 'dim_currency', 'Success'), ('gold', 'dim_concession_type', 'Success'),
                 ('silver', 'silv_member_year_attributes', 'Success'), ('silver', 'silv_event_amount', 'Success'),
                 ('silver', 'silv_data_anomaly_segment', 'Success'), ('silver', 'silv_data_anomaly_invoice', 'Success'),
                 ('silver', 'silv_membership_events_segments', 'Success'),
                 ('gold', 'fact_membership_events_segments', 'Success'))
         AS v(layer, step_name, status);

    EXEC tSQLt.AssertEqualsTable '#ExpectedSteps', '#ActualSteps';

    SELECT r.rows_inserted, r.rows_updated, r.rows_deleted
    INTO #ActualCounts
    FROM Layercake.etl_run_log AS r
    WHERE r.run_id = @run_id
      AND r.step_name = 'brnz_corporate_subscription';

    SELECT v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedCounts
    FROM (VALUES (6, 1, 1)) AS v(rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedCounts', '#ActualCounts';

    SELECT t.contact_no, t.scheme_no, t.scheme_name, t.sub_campaign_year, t._is_deleted,
           CAST(t.sub_status AS varbinary(700)) AS sub_status_bytes,
           CAST(t.sub_user_status AS varbinary(700)) AS sub_user_status_bytes
    INTO #Actual
    FROM Layercake.brnz_corporate_subscription AS t;

    SELECT v.contact_no, v.scheme_no, v.scheme_name, v.sub_campaign_year, v._is_deleted, v.sub_status_bytes, v.sub_user_status_bytes
    INTO #Expected
    FROM (VALUES (N'C2201', N'SCH-020', N'Scheme Twenty', 2025, CAST(0 AS bit), CAST(N'Active' AS varbinary(700)),   CAST(N'Active' AS varbinary(700))),
                 (N'C2202', N'SCH-020', N'Scheme Twenty', 2025, CAST(0 AS bit), CAST(N'Active' AS varbinary(700)),   CAST(N'Active' AS varbinary(700))),
                 (N'C2203', N'SCH-020', N'Scheme Twenty', 2025, CAST(0 AS bit), CAST(N'Inactive' AS varbinary(700)), CAST(N'Inactive' AS varbinary(700))),
                 (N'C2204', N'SCH-020', N'Scheme Twenty', 2025, CAST(0 AS bit), CAST(N'Inactive' AS varbinary(700)), CAST(N'Inactive' AS varbinary(700))),
                 (N'C2205', N'SCH-020', N'Scheme Twenty', 2025, CAST(0 AS bit), CAST(N'Inactive' AS varbinary(700)), CAST(N'Inactive' AS varbinary(700))),
                 (N'C2206', N'SCH-020', N'Scheme Twenty', 2025, CAST(0 AS bit), CAST(N'Inactive' AS varbinary(700)), CAST(N'Inactive' AS varbinary(700))),
                 (N'C2207', N'SCH-020', N'Scheme Twenty', 2025, CAST(0 AS bit), CAST(N'Inactive' AS varbinary(700)), CAST(N'Inactive' AS varbinary(700))),
                 (N'C2208', N'SCH-020', N'Scheme Twenty', 2025, CAST(0 AS bit), CAST(N'Active' AS varbinary(700)),   CAST(N'Active' AS varbinary(700))),
                 (N'C2290', N'SCH-020', N'Scheme Twenty', 2025, CAST(1 AS bit), CAST(N'Active' AS varbinary(700)),   CAST(N'Active' AS varbinary(700))))
         AS v(contact_no, scheme_no, scheme_name, sub_campaign_year, _is_deleted, sub_status_bytes, sub_user_status_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD024.[test TC-024-023 a daily run after the segment run records 0 0 0 for the corporate subscription load]
AS
BEGIN
    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status)
    VALUES (N'C2201', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active'),
           (N'C2203', N'SCH-020', N'Scheme Twenty', 2025, N'Inactive', N'Active'),
           (N'C2290', N'SCH-020', N'Scheme Twenty', 2025, N'Active',   N'Active');

    EXEC Layercake.usp_run_payment_segments @run_id = 'E0000000-0000-0000-0000-000000000024', @as_of_date = '2025-06-15';

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;

    EXEC Layercake.usp_run_daily_load;

    DECLARE @daily_run uniqueidentifier =
        (SELECT r.run_id FROM Layercake.etl_run_log AS r WHERE r.step_name = 'usp_run_daily_load');

    SELECT r.step_name, r.status, r.rows_inserted, r.rows_updated, r.rows_deleted
    INTO #Actual
    FROM Layercake.etl_run_log AS r
    WHERE r.run_id = @daily_run
      AND r.step_name IN ('usp_run_daily_load', 'brnz_corporate_subscription');

    SELECT v.step_name, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #Expected
    FROM (VALUES ('usp_run_daily_load', 'Success', CAST(NULL AS int), CAST(NULL AS int), CAST(NULL AS int)),
                 ('brnz_corporate_subscription', 'Success', 0, 0, 0))
         AS v(step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT * INTO #After FROM Layercake.brnz_corporate_subscription;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD024.[test TC-024-024 after a missing key stops the run one more segment run recovers with no cleanup]
AS
BEGIN
    DECLARE @run_1 uniqueidentifier = 'F1000000-0000-0000-0000-000000000024',
            @run_2 uniqueidentifier = 'F2000000-0000-0000-0000-000000000024';

    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status)
    VALUES (N'C2201', N'SCH-020', N'Scheme Twenty', 2025, N'Active', N'Active');

    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Sub User Created Date], [Round])
    VALUES (N'C2209', NULL, N'Scheme Twenty', 2025, N'Active', N'Active', '2024-10-01', N'Round 1');

    SELECT * INTO #Before FROM Layercake.brnz_corporate_subscription;

    DECLARE @err int = NULL;
    BEGIN TRY
        EXEC Layercake.usp_run_payment_segments @run_id = @run_1, @as_of_date = '2025-06-15';
        EXEC tSQLt.Fail 'Expected error 515 from usp_run_payment_segments, but no error was raised.';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_NUMBER();
        IF @err <> 515 THROW;
    END CATCH;

    EXEC tSQLt.AssertEquals 515, @err;

    SELECT r.step_name, r.status
    INTO #ActualFailed
    FROM Layercake.etl_run_log AS r
    WHERE r.run_id = @run_1
      AND r.status <> 'Success';

    SELECT v.step_name, v.status
    INTO #ExpectedFailed
    FROM (VALUES ('usp_run_payment_segments', 'Failed'), ('brnz_corporate_subscription', 'Failed')) AS v(step_name, status);
    EXEC tSQLt.AssertEqualsTable '#ExpectedFailed', '#ActualFailed';

    DECLARE @later_steps int =
        (SELECT COUNT(*) FROM Layercake.etl_run_log AS r
         WHERE r.run_id = @run_1
           AND r.layer <> 'bronze'
           AND r.layer <> 'run');
    EXEC tSQLt.AssertEquals 0, @later_steps;

    SELECT * INTO #AfterFailure FROM Layercake.brnz_corporate_subscription;
    EXEC tSQLt.AssertEqualsTable '#Before', '#AfterFailure';

    -- The source row is corrected; one more call, with no manual cleanup.
    DELETE FROM Subs.vwCorpSubscriptions WHERE [Contact No] = N'C2209';

    EXEC Layercake.usp_run_payment_segments @run_id = @run_2, @as_of_date = '2025-06-15';

    DECLARE @not_success int =
        (SELECT COUNT(*) FROM Layercake.etl_run_log AS r WHERE r.run_id = @run_2 AND r.status <> 'Success');
    DECLARE @steps int =
        (SELECT COUNT(*) FROM Layercake.etl_run_log AS r WHERE r.run_id = @run_2);
    EXEC tSQLt.AssertEquals 0, @not_success;
    EXEC tSQLt.AssertEquals 18, @steps;

    DECLARE @live int = (SELECT COUNT(*) FROM Layercake.brnz_corporate_subscription AS t WHERE t._is_deleted = 0);
    EXEC tSQLt.AssertEquals 8, @live;

    SELECT a.contact_no, a.campaign_year, a.payer_type_id, a.corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a
    WHERE a.contact_no IN (N'C2202', N'C2203');

    SELECT v.contact_no, v.campaign_year, v.payer_type_id, v.corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'C2202', 2025, 2, N'SCH-020'), (N'C2203', 2025, 1, CAST(NULL AS nvarchar(100))))
         AS v(contact_no, campaign_year, payer_type_id, corporate_account_ref);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
