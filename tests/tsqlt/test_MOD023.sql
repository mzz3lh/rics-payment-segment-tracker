EXEC tSQLt.NewTestClass 'test_MOD023';
GO

CREATE PROCEDURE test_MOD023.[SetUp]
AS
BEGIN
    -- External sources the segment loads read (stand-ins, faked before rows go in).
    EXEC tSQLt.FakeTable 'Subs.tblSubsInvoices';
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';

    -- Bronze, reference lists, dimensions, silver, gold and the run log.
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_invoice_line_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_currency', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_currency', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_event_amount', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    -- The Phase 1 steps are stood in for: each logs one step row under the run_id it
    -- receives. Silver adds P1's 2026 Lapse (new to the source data), as the Phase 1
    -- events load would, and records its rebuild arguments when a test asks for them
    -- (#silver_calls); gold copies every silver event that has no fact row yet, with
    -- the segment columns at their defaults, as the Phase 1 fact load would.
    DECLARE @bronze_stub nvarchar(max) = N'
DECLARE @stub_log_id bigint;
EXEC Layercake.usp_etl_log_start @run_id, ''bronze'', ''phase1_bronze_stub'', @stub_log_id OUTPUT;
EXEC Layercake.usp_etl_log_end @stub_log_id, ''Success'';';

    DECLARE @silver_stub nvarchar(max) = N'
DECLARE @stub_log_id bigint;
EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''phase1_silver_stub'', @stub_log_id OUTPUT;
IF OBJECT_ID(''tempdb..#silver_calls'') IS NOT NULL
    INSERT INTO #silver_calls (full_rebuild, rebuild_from) VALUES (@FullRebuild, @RebuildFrom);
INSERT INTO Layercake.silv_membership_events
    (event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id,
     assessment_route_id, rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year,
     campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
     concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
SELECT 102, N''LA:P1:2026'', ''Lapse'', ''Standard'', ''2025-12-31'', NULL, N''P1'', 2,
       0, 0, 0, 0, 0, 1, 2026,
       ''Q1'', 0, 0, 0, 0,
       0, 0, NULL, NULL, NULL
WHERE NOT EXISTS (SELECT 1 FROM Layercake.silv_membership_events AS e WHERE e.event_id = 102);
EXEC Layercake.usp_etl_log_end @stub_log_id, ''Success'';';

    DECLARE @gold_stub nvarchar(max) = N'
DECLARE @stub_log_id bigint;
EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''phase1_gold_stub'', @stub_log_id OUTPUT;
INSERT INTO Layercake.fact_membership_events
    (event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id,
     rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
     payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id,
     concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
SELECT e.event_id, e.event_type, e.event_subtype, e.event_date, 0, e.contact_no, e.grade_id, e.assessment_route_id,
       e.rpq_variant_id, e.hpb_id, e.country_id, e.gender_id, e.membership_status_id, e.campaign_year, e.campaign_quarter,
       0, 0, 0, 0, 0,
       0, NULL, NULL, NULL
FROM Layercake.silv_membership_events AS e
WHERE NOT EXISTS (SELECT 1 FROM Layercake.fact_membership_events AS f WHERE f.event_id = e.event_id);
EXEC Layercake.usp_etl_log_end @stub_log_id, ''Success'';';

    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_bronze', @CommandToExecute = @bronze_stub;
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_silver', @CommandToExecute = @silver_stub;
    EXEC tSQLt.SpyProcedure @ProcedureName = 'Layercake.usp_load_gold', @CommandToExecute = @gold_stub;

    -- Seeded reference lists (seed ids and names).
    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code)
    VALUES (0, 'Unknown', NULL), (-1, 'Unrecognised', NULL), (-2, 'Not applicable', NULL),
           (1, 'Direct Debit', 'DD'), (2, 'Card', 'Card'), (3, 'Bank transfer', 'Bank'),
           (4, 'Cheque', 'Cheque'), (5, 'Corporate', 'Corporate');

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name)
    VALUES (0, 'Unknown'), (-1, 'Unrecognised'), (-2, 'Not applicable'), (1, 'Individual'), (2, 'Corporate');

    INSERT INTO Layercake.silv_ref_concession_type
        (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL), (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL),
           (-2, NULL, N'Not applicable', NULL, 0, 0, NULL), (1, NULL, N'No concession', NULL, 0, 0, NULL);

    -- Campaign Years 2020 to 2060 (1 October to 30 September), so the run date always has one.
    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    SELECT y.campaign_year,
           DATEFROMPARTS(y.campaign_year - 1, 10, 1),
           DATEFROMPARTS(y.campaign_year, 9, 30),
           DATEFROMPARTS(y.campaign_year, 3, 31)
    FROM (SELECT 2020 + t.n * 10 + u.n AS campaign_year
          FROM (VALUES (0), (1), (2), (3), (4)) AS t (n)
          CROSS JOIN (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) AS u (n)) AS y
    WHERE y.campaign_year <= 2060;

    -- Sources: P1's 2025 Corporate invoice and live corporate subscription; P2's 2025 DD invoice (no event).
    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency,
         Exchange_Rate, Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR,
         Inv_Credit_Amount_GBP, Fully_Credited, Payment_Status, Has_Concession, [100%_Concession],
         Last_Settle_Voucher, Retired_Concession, APP_Invoice_Flag)
    VALUES (5001, N'P1', 2025, N'INV-5001', N'V5001', '2024-10-05', N'Corporate', N'GBP',
            1, 450.000000, 450.000000, 450.000000, 0, 0, 'N', N'Fully Paid', 'N', 'N', N'V5001', 'N', 'N'),
           (6001, N'P2', 2025, N'INV-6001', N'V6001', '2024-10-08', N'DD', N'GBP',
            1, 300.000000, 300.000000, 300.000000, 0, 0, 'N', N'Fully Paid', 'N', 'N', N'V6001', 'N', 'N');

    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (N'P1', N'S-100', N'Scheme 100', 2025, N'Active', N'Active', N'1');

    -- Phase 1 state from earlier runs: P1's 2025 paid position, status row and Renewal (silver and gold).
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'P1', 2025, '2024-10-05', '2024-10-05', N'Fully Paid');

    INSERT INTO Layercake.brnz_subs_status
        ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj],
         _is_deleted, inv_total_amount, retired_concession)
    VALUES (N'P1', 2025, 'Fully Paid', '2024-10-05', '2024-10-05', 0, 450.000000, NULL);

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id,
         assessment_route_id, rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year,
         campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (101, N'RN:P1:2025', 'Renewal', 'Standard', '2024-10-05', NULL, N'P1', 2,
            0, 0, 0, 0, 0, 1, 2025,
            'Q1', 0, 0, 0, 0,
            0, 0, NULL, NULL, NULL);

    INSERT INTO Layercake.fact_membership_events
        (event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id,
         rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id,
         concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (101, 'Renewal', 'Standard', '2024-10-05', 0, N'P1', 2, 0,
            0, 0, 0, 0, 1, 2025, 'Q1',
            0, 0, 0, 0, 0,
            0, NULL, NULL, NULL);
END;
GO

CREATE PROCEDURE test_MOD023.[test TC-023-001 one daily run logs every segment load as Success under the daily run id]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''daily_count_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''daily_fact_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';

    EXEC Layercake.usp_run_daily_load;

    DECLARE @run_ids int = (SELECT COUNT(DISTINCT l.run_id) FROM Layercake.etl_run_log AS l);
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @run_ids, @Message = N'every row of the daily run carries one run_id';

    SELECT v.layer, v.step_name, v.status, v.row_count
    INTO #Expected
    FROM (VALUES
        (CAST('run' AS varchar(12)), CAST('usp_run_daily_load' AS varchar(128)), CAST('Success' AS varchar(10)), 1),
        ('bronze', 'phase1_bronze_stub', 'Success', 1),
        ('silver', 'phase1_silver_stub', 'Success', 1),
        ('gold', 'phase1_gold_stub', 'Success', 1),
        ('bronze', 'brnz_subs_invoice', 'Success', 1),
        ('bronze', 'brnz_subs_invoice_line', 'Success', 1),
        ('bronze', 'brnz_corporate_subscription', 'Success', 1),
        ('bronze', 'brnz_concession', 'Success', 1),
        ('silver', 'silv_ref_invoice_line_type', 'Success', 1),
        ('silver', 'silv_ref_currency', 'Success', 1),
        ('silver', 'silv_ref_concession_type', 'Success', 1),
        ('gold', 'dim_payment_method', 'Success', 1),
        ('gold', 'dim_payer_type', 'Success', 1),
        ('gold', 'dim_currency', 'Success', 1),
        ('gold', 'dim_concession_type', 'Success', 1),
        ('silver', 'silv_member_year_attributes', 'Success', 1),
        ('silver', 'silv_event_amount', 'Success', 1),
        ('silver', 'silv_data_anomaly_segment', 'Success', 1),
        ('silver', 'silv_data_anomaly_invoice', 'Success', 1),
        ('silver', 'silv_membership_events_segments', 'Success', 1),
        ('gold', 'fact_membership_events_segments', 'Success', 1),
        ('silver', 'daily_count_stub', 'Success', 1),
        ('gold', 'daily_fact_stub', 'Success', 1)
    ) AS v(layer, step_name, status, row_count);

    SELECT l.layer, l.step_name, l.status, COUNT(*) AS row_count
    INTO #Actual
    FROM Layercake.etl_run_log AS l
    WHERE NOT (l.layer = 'run' AND l.step_name = 'usp_run_payment_segments')
    GROUP BY l.layer, l.step_name, l.status;

    EXEC tSQLt.AssertEqualsTable @Expected = N'#Expected', @Actual = N'#Actual';
END
GO

CREATE PROCEDURE test_MOD023.[test TC-023-002 every segment load starts after the Phase 1 gold step]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''daily_count_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''daily_fact_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';

    EXEC Layercake.usp_run_daily_load;

    DECLARE @gold_log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l WHERE l.layer = 'gold' AND l.step_name = 'phase1_gold_stub');
    DECLARE @daily_count_log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l WHERE l.layer = 'silver' AND l.step_name = 'daily_count_stub');
    DECLARE @daily_fact_log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l WHERE l.layer = 'gold' AND l.step_name = 'daily_fact_stub');

    SELECT v.layer, v.step_name
    INTO #segment_rows
    FROM (VALUES
        (CAST('bronze' AS varchar(12)), CAST('brnz_subs_invoice' AS varchar(128))),
        ('bronze', 'brnz_subs_invoice_line'),
        ('bronze', 'brnz_corporate_subscription'),
        ('bronze', 'brnz_concession'),
        ('silver', 'silv_ref_invoice_line_type'),
        ('silver', 'silv_ref_currency'),
        ('silver', 'silv_ref_concession_type'),
        ('gold', 'dim_payment_method'),
        ('gold', 'dim_payer_type'),
        ('gold', 'dim_currency'),
        ('gold', 'dim_concession_type'),
        ('silver', 'silv_member_year_attributes'),
        ('silver', 'silv_event_amount'),
        ('silver', 'silv_data_anomaly_segment'),
        ('silver', 'silv_data_anomaly_invoice'),
        ('silver', 'silv_membership_events_segments'),
        ('gold', 'fact_membership_events_segments')
    ) AS v(layer, step_name);

    DECLARE @segment_count int = (
        SELECT COUNT(*) FROM Layercake.etl_run_log AS l
        JOIN #segment_rows AS s ON s.layer = l.layer AND s.step_name = l.step_name);
    EXEC tSQLt.AssertEquals @Expected = 17, @Actual = @segment_count, @Message = N'17 segment load rows are logged';

    IF @gold_log_id IS NULL EXEC tSQLt.Fail N'the Phase 1 gold step was not logged';
    IF @daily_count_log_id IS NULL EXEC tSQLt.Fail N'the daily count step was not logged';
    IF @daily_fact_log_id IS NULL EXEC tSQLt.Fail N'the gold daily fact step was not logged';

    DECLARE @before_gold int = (
        SELECT COUNT(*) FROM Layercake.etl_run_log AS l
        JOIN #segment_rows AS s ON s.layer = l.layer AND s.step_name = l.step_name
        WHERE l.log_id < @gold_log_id);
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @before_gold, @Message = N'no segment load starts before the Phase 1 gold step';

    DECLARE @after_daily_count int = (
        SELECT COUNT(*) FROM Layercake.etl_run_log AS l
        JOIN #segment_rows AS s ON s.layer = l.layer AND s.step_name = l.step_name
        WHERE l.log_id > @daily_count_log_id);
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @after_daily_count, @Message = N'no segment load starts after the daily count step';

    DECLARE @fact_after_count int = CASE WHEN @daily_fact_log_id > @daily_count_log_id THEN 1 ELSE 0 END;
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @fact_after_count, @Message = N'the gold daily fact starts after the daily count';
END
GO

CREATE PROCEDURE test_MOD023.[test TC-023-003 one daily run gives the same segment results as Phase 1 then a separate segment run]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''daily_count_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''daily_fact_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';

    -- Phase 1 run, then a separate segment run
    DECLARE @separate_run_id uniqueidentifier = NEWID();
    EXEC Layercake.usp_load_bronze @run_id = @separate_run_id;
    EXEC Layercake.usp_load_silver @run_id = @separate_run_id;
    EXEC Layercake.usp_load_gold @run_id = @separate_run_id;
    EXEC Layercake.usp_run_payment_segments @run_id = @separate_run_id;

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried, a.payer_type_id, a.payer_type_carried,
           a.concession_type_id, a.concession_type_carried, a.corporate_account_ref, a.segment_invoice_rec_id
    INTO #separate_attributes
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT e.event_id, e.event_nk, e.payment_method_id, e.payment_method_carried, e.payer_type_id, e.payer_type_carried,
           e.concession_type_id, e.concession_type_carried, e.subs_amount_gbp, e.invoiced_subtotal_gbp, e.amount_status
    INTO #separate_events
    FROM Layercake.silv_membership_events AS e;

    SELECT f.event_id, f.payment_method_id, f.payment_method_carried, f.payer_type_id, f.payer_type_carried,
           f.concession_type_id, f.concession_type_carried, f.subs_amount_gbp, f.invoiced_subtotal_gbp, f.amount_status
    INTO #separate_facts
    FROM Layercake.fact_membership_events AS f;

    SELECT d.anomaly_nk, d.anomaly_type, d.contact_no, d.detail, d.resolved_at
    INTO #separate_anomalies
    FROM Layercake.silv_data_anomaly AS d;

    -- clear everything either run writes; restore the Phase 1 Renewal 101 as the SetUp left it
    DELETE FROM Layercake.brnz_subs_invoice;
    DELETE FROM Layercake.brnz_subs_invoice_line;
    DELETE FROM Layercake.brnz_corporate_subscription;
    DELETE FROM Layercake.brnz_concession;
    DELETE FROM Layercake.silv_ref_invoice_line_type;
    DELETE FROM Layercake.silv_ref_currency;
    DELETE FROM Layercake.silv_ref_concession_type WHERE concession_type_bk IS NOT NULL;
    DELETE FROM Layercake.dim_payment_method;
    DELETE FROM Layercake.dim_payer_type;
    DELETE FROM Layercake.dim_currency;
    DELETE FROM Layercake.dim_concession_type;
    DELETE FROM Layercake.silv_member_year_attributes;
    DELETE FROM Layercake.silv_event_amount;
    DELETE FROM Layercake.silv_data_anomaly;
    DELETE FROM Layercake.silv_membership_events WHERE event_id <> 101;
    DELETE FROM Layercake.fact_membership_events WHERE event_id <> 101;
    UPDATE Layercake.silv_membership_events
    SET payment_method_id = 0, payment_method_carried = 0, payer_type_id = 0, payer_type_carried = 0,
        concession_type_id = 0, concession_type_carried = 0,
        subs_amount_gbp = NULL, invoiced_subtotal_gbp = NULL, amount_status = NULL
    WHERE event_id = 101;
    UPDATE Layercake.fact_membership_events
    SET payment_method_id = 0, payment_method_carried = 0, payer_type_id = 0, payer_type_carried = 0,
        concession_type_id = 0, concession_type_carried = 0,
        subs_amount_gbp = NULL, invoiced_subtotal_gbp = NULL, amount_status = NULL
    WHERE event_id = 101;
    DELETE FROM Layercake.etl_run_log;

    -- one daily run
    EXEC Layercake.usp_run_daily_load;

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried, a.payer_type_id, a.payer_type_carried,
           a.concession_type_id, a.concession_type_carried, a.corporate_account_ref, a.segment_invoice_rec_id
    INTO #daily_attributes
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT e.event_id, e.event_nk, e.payment_method_id, e.payment_method_carried, e.payer_type_id, e.payer_type_carried,
           e.concession_type_id, e.concession_type_carried, e.subs_amount_gbp, e.invoiced_subtotal_gbp, e.amount_status
    INTO #daily_events
    FROM Layercake.silv_membership_events AS e;

    SELECT f.event_id, f.payment_method_id, f.payment_method_carried, f.payer_type_id, f.payer_type_carried,
           f.concession_type_id, f.concession_type_carried, f.subs_amount_gbp, f.invoiced_subtotal_gbp, f.amount_status
    INTO #daily_facts
    FROM Layercake.fact_membership_events AS f;

    SELECT d.anomaly_nk, d.anomaly_type, d.contact_no, d.detail, d.resolved_at
    INTO #daily_anomalies
    FROM Layercake.silv_data_anomaly AS d;

    DECLARE @corporate_events int = (SELECT COUNT(*) FROM #separate_events WHERE payer_type_id = 2);
    EXEC tSQLt.AssertEquals @Expected = 2, @Actual = @corporate_events, @Message = N'the separate run gives both P1 events payer type 2';
    DECLARE @separate_anomaly_count int = (SELECT COUNT(*) FROM #separate_anomalies);
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @separate_anomaly_count, @Message = N'the separate run raises exactly one anomaly';

    EXEC tSQLt.AssertEqualsTable @Expected = N'#separate_attributes', @Actual = N'#daily_attributes', @Message = N'attributes';
    EXEC tSQLt.AssertEqualsTable @Expected = N'#separate_events', @Actual = N'#daily_events', @Message = N'silver events';
    EXEC tSQLt.AssertEqualsTable @Expected = N'#separate_facts', @Actual = N'#daily_facts', @Message = N'gold facts';
    EXEC tSQLt.AssertEqualsTable @Expected = N'#separate_anomalies', @Actual = N'#daily_anomalies', @Message = N'anomalies';
END
GO

CREATE PROCEDURE test_MOD023.[test TC-023-004 a Lapse new in this run carries Corporate carried in silver and gold after one daily run]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''daily_count_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''daily_fact_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';

    EXEC Layercake.usp_run_daily_load;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried,
           v.concession_type_id, v.concession_type_carried, v.subs_amount_gbp, v.invoiced_subtotal_gbp, v.amount_status
    INTO #Expected
    FROM (VALUES
        (101, 5, CAST(0 AS bit), 2, CAST(0 AS bit), 1, CAST(0 AS bit), CAST(450.0000 AS decimal(19,4)), CAST(450.0000 AS decimal(19,4)), CAST('Invoiced' AS varchar(30))),
        (102, 5, CAST(1 AS bit), 2, CAST(1 AS bit), 0, CAST(0 AS bit), CAST(NULL AS decimal(19,4)), CAST(NULL AS decimal(19,4)), CAST(NULL AS varchar(30)))
    ) AS v(event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
           concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status);

    SELECT e.event_id, e.payment_method_id, e.payment_method_carried, e.payer_type_id, e.payer_type_carried,
           e.concession_type_id, e.concession_type_carried,
           CAST(e.subs_amount_gbp AS decimal(19,4)) AS subs_amount_gbp,
           CAST(e.invoiced_subtotal_gbp AS decimal(19,4)) AS invoiced_subtotal_gbp,
           e.amount_status
    INTO #ActualSilver
    FROM Layercake.silv_membership_events AS e;

    SELECT f.event_id, f.payment_method_id, f.payment_method_carried, f.payer_type_id, f.payer_type_carried,
           f.concession_type_id, f.concession_type_carried,
           CAST(f.subs_amount_gbp AS decimal(19,4)) AS subs_amount_gbp,
           CAST(f.invoiced_subtotal_gbp AS decimal(19,4)) AS invoiced_subtotal_gbp,
           f.amount_status
    INTO #ActualGold
    FROM Layercake.fact_membership_events AS f;

    EXEC tSQLt.AssertEqualsTable @Expected = N'#Expected', @Actual = N'#ActualSilver', @Message = N'silv_membership_events';
    EXEC tSQLt.AssertEqualsTable @Expected = N'#Expected', @Actual = N'#ActualGold', @Message = N'fact_membership_events';
END
GO

CREATE PROCEDURE test_MOD023.[test TC-023-005 the daily run derives attributes up to the Campaign Year of the run date]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''daily_count_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''daily_fact_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';

    EXEC Layercake.usp_run_daily_load;

    DECLARE @today date = CAST(SYSDATETIME() AS date);
    DECLARE @current_year int = (
        SELECT c.campaign_year FROM Layercake.ref_campaign_year_config AS c
        WHERE c.campaign_year_start <= @today AND c.campaign_year_end >= @today);

    DECLARE @min_year int = (SELECT MIN(a.campaign_year) FROM Layercake.silv_member_year_attributes AS a WHERE a.contact_no = N'P1');
    DECLARE @max_year int = (SELECT MAX(a.campaign_year) FROM Layercake.silv_member_year_attributes AS a WHERE a.contact_no = N'P1');
    DECLARE @p1_rows int = (SELECT COUNT(*) FROM Layercake.silv_member_year_attributes AS a WHERE a.contact_no = N'P1');
    DECLARE @expected_rows int = @current_year - 2024;
    DECLARE @other_rows int = (SELECT COUNT(*) FROM Layercake.silv_member_year_attributes AS a WHERE a.contact_no <> N'P1');
    DECLARE @odd_later_rows int = (
        SELECT COUNT(*) FROM Layercake.silv_member_year_attributes AS a
        WHERE a.contact_no = N'P1' AND a.campaign_year > 2025
          AND NOT (a.payment_method_id = 5 AND a.payment_method_carried = 1
               AND a.payer_type_id = 2 AND a.payer_type_carried = 1
               AND ISNULL(a.corporate_account_ref, N'') = N'S-100'
               AND a.concession_type_id = 0 AND a.concession_type_carried = 0
               AND a.segment_invoice_rec_id IS NULL));

    EXEC tSQLt.AssertEquals @Expected = 2025, @Actual = @min_year, @Message = N'first attributes year';
    EXEC tSQLt.AssertEquals @Expected = @current_year, @Actual = @max_year, @Message = N'last attributes year is the Campaign Year of the run date';
    EXEC tSQLt.AssertEquals @Expected = @expected_rows, @Actual = @p1_rows, @Message = N'one row per year';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @other_rows, @Message = N'no other contact has attributes';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @odd_later_rows, @Message = N'every later year carries the 2025 Corporate values';

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried,
           v.corporate_account_ref, v.concession_type_id, v.concession_type_carried, v.segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES
        (CAST(N'P1' AS nvarchar(200)), 2025, 5, CAST(0 AS bit), 2, CAST(0 AS bit), CAST(N'S-100' AS nvarchar(100)), 1, CAST(0 AS bit), CAST(5001 AS bigint)),
        (N'P1', 2026, 5, CAST(1 AS bit), 2, CAST(1 AS bit), N'S-100', 0, CAST(0 AS bit), CAST(NULL AS bigint))
    ) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
           corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id);

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried, a.payer_type_id, a.payer_type_carried,
           a.corporate_account_ref, a.concession_type_id, a.concession_type_carried, a.segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a
    WHERE a.campaign_year <= 2026;

    EXEC tSQLt.AssertEqualsTable @Expected = N'#Expected', @Actual = N'#Actual';
END
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD023.[test TC-023-006 a failing segment load fails the daily run with 515 and keeps the Phase 1 work]
AS
BEGIN
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (NULL, N'S-200', N'Scheme 200', 2025, N'Active', N'Active', N'1');

    DECLARE @error_number int = NULL;

    BEGIN TRY
        EXEC Layercake.usp_run_daily_load;
        EXEC tSQLt.Fail 'usp_run_daily_load did not fail on a corporate subscription with no Contact No';
    END TRY
    BEGIN CATCH
        SET @error_number = ERROR_NUMBER();
        IF @error_number <> 515 THROW;
    END CATCH;

    EXEC tSQLt.AssertEquals 515, @error_number, 'The original error reaches the caller';

    DECLARE @run_status varchar(10) = (SELECT l.status FROM Layercake.etl_run_log AS l
                                       WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load');
    DECLARE @run_error_logged int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l
                                     WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load'
                                       AND l.error_message IS NOT NULL);
    DECLARE @corporate_status varchar(10) = (SELECT l.status FROM Layercake.etl_run_log AS l
                                             WHERE l.layer = 'bronze' AND l.step_name = 'brnz_corporate_subscription');
    DECLARE @run_ids int = (SELECT COUNT(DISTINCT l.run_id) FROM Layercake.etl_run_log AS l);

    EXEC tSQLt.AssertEquals 'Failed', @run_status, 'The daily run row ends Failed';
    EXEC tSQLt.AssertEquals 1, @run_error_logged, 'The daily run row holds the error message';
    EXEC tSQLt.AssertEquals 'Failed', @corporate_status, 'The failing load logged Failed';
    EXEC tSQLt.AssertEquals 1, @run_ids, 'Every row the call logs carries the same run_id';

    SELECT l.layer, l.step_name, l.status
    INTO #ActualPhase1
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name IN ('phase1_bronze_stub', 'phase1_silver_stub', 'phase1_gold_stub');

    SELECT v.layer, v.step_name, v.status
    INTO #ExpectedPhase1
    FROM (VALUES ('bronze', 'phase1_bronze_stub', 'Success'),
                 ('silver', 'phase1_silver_stub', 'Success'),
                 ('gold', 'phase1_gold_stub', 'Success')) AS v (layer, step_name, status);

    EXEC tSQLt.AssertEqualsTable '#ExpectedPhase1', '#ActualPhase1', 'Phase 1 step rows';

    SELECT e.event_id, e.event_nk, e.event_type, e.campaign_year
    INTO #ActualEvents
    FROM Layercake.silv_membership_events AS e;

    SELECT f.event_id, f.event_type, f.campaign_year
    INTO #ActualFacts
    FROM Layercake.fact_membership_events AS f;

    SELECT v.event_id, v.event_nk, v.event_type, v.campaign_year
    INTO #ExpectedEvents
    FROM (VALUES (101, N'RN:P1:2025', 'Renewal', 2025), (102, N'LA:P1:2026', 'Lapse', 2026))
         AS v (event_id, event_nk, event_type, campaign_year);

    SELECT v.event_id, v.event_type, v.campaign_year
    INTO #ExpectedFacts
    FROM (VALUES (101, 'Renewal', 2025), (102, 'Lapse', 2026)) AS v (event_id, event_type, campaign_year);

    EXEC tSQLt.AssertEqualsTable '#ExpectedEvents', '#ActualEvents', 'Phase 1 silver data kept';
    EXEC tSQLt.AssertEqualsTable '#ExpectedFacts', '#ActualFacts', 'Phase 1 gold data kept';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD023.[test TC-023-007 after the source row is corrected the next daily run succeeds and fills every segment]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''daily_count_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''daily_fact_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (NULL, N'S-200', N'Scheme 200', 2025, N'Active', N'Active', N'1');

    BEGIN TRY
        EXEC Layercake.usp_run_daily_load;
        EXEC tSQLt.Fail N'the first daily run should fail with 515';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515 THROW;
    END CATCH;

    DELETE FROM Subs.vwCorpSubscriptions WHERE [Contact No] IS NULL;

    EXEC Layercake.usp_run_daily_load;

    DECLARE @second_run_id uniqueidentifier = (
        SELECT TOP (1) l.run_id FROM Layercake.etl_run_log AS l
        WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load'
        ORDER BY l.log_id DESC);
    DECLARE @daily_runs int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load');
    DECLARE @second_status varchar(10) = (
        SELECT l.status FROM Layercake.etl_run_log AS l
        WHERE l.run_id = @second_run_id AND l.layer = 'run' AND l.step_name = 'usp_run_daily_load');
    DECLARE @second_not_success int = (
        SELECT COUNT(*) FROM Layercake.etl_run_log AS l
        WHERE l.run_id = @second_run_id AND ISNULL(l.status, '') <> 'Success');

    EXEC tSQLt.AssertEquals @Expected = 2, @Actual = @daily_runs, @Message = N'two daily run rows';
    EXEC tSQLt.AssertEqualsString @Expected = 'Success', @Actual = @second_status, @Message = N'the second daily run succeeds';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @second_not_success, @Message = N'every row of the second run is Success';

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried,
           v.concession_type_id, v.concession_type_carried, v.subs_amount_gbp, v.invoiced_subtotal_gbp, v.amount_status
    INTO #ExpectedEvents
    FROM (VALUES
        (101, 5, CAST(0 AS bit), 2, CAST(0 AS bit), 1, CAST(0 AS bit), CAST(450.0000 AS decimal(19,4)), CAST(450.0000 AS decimal(19,4)), CAST('Invoiced' AS varchar(30))),
        (102, 5, CAST(1 AS bit), 2, CAST(1 AS bit), 0, CAST(0 AS bit), CAST(NULL AS decimal(19,4)), CAST(NULL AS decimal(19,4)), CAST(NULL AS varchar(30)))
    ) AS v(event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
           concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status);

    SELECT e.event_id, e.payment_method_id, e.payment_method_carried, e.payer_type_id, e.payer_type_carried,
           e.concession_type_id, e.concession_type_carried,
           CAST(e.subs_amount_gbp AS decimal(19,4)) AS subs_amount_gbp,
           CAST(e.invoiced_subtotal_gbp AS decimal(19,4)) AS invoiced_subtotal_gbp,
           e.amount_status
    INTO #ActualSilver
    FROM Layercake.silv_membership_events AS e;

    SELECT f.event_id, f.payment_method_id, f.payment_method_carried, f.payer_type_id, f.payer_type_carried,
           f.concession_type_id, f.concession_type_carried,
           CAST(f.subs_amount_gbp AS decimal(19,4)) AS subs_amount_gbp,
           CAST(f.invoiced_subtotal_gbp AS decimal(19,4)) AS invoiced_subtotal_gbp,
           f.amount_status
    INTO #ActualGold
    FROM Layercake.fact_membership_events AS f;

    EXEC tSQLt.AssertEqualsTable @Expected = N'#ExpectedEvents', @Actual = N'#ActualSilver', @Message = N'silv_membership_events';
    EXEC tSQLt.AssertEqualsTable @Expected = N'#ExpectedEvents', @Actual = N'#ActualGold', @Message = N'fact_membership_events';

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payer_type_id, v.corporate_account_ref
    INTO #ExpectedAttributes
    FROM (VALUES
        (CAST(N'P1' AS nvarchar(200)), 2025, 5, 2, CAST(N'S-100' AS nvarchar(100))),
        (N'P1', 2026, 5, 2, N'S-100')
    ) AS v(contact_no, campaign_year, payment_method_id, payer_type_id, corporate_account_ref);

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payer_type_id, a.corporate_account_ref
    INTO #ActualAttributes
    FROM Layercake.silv_member_year_attributes AS a
    WHERE a.campaign_year <= 2026;

    EXEC tSQLt.AssertEqualsTable @Expected = N'#ExpectedAttributes', @Actual = N'#ActualAttributes', @Message = N'attributes up to 2026';

    SELECT v.anomaly_type, v.contact_no
    INTO #ExpectedAnomalies
    FROM (VALUES (CAST('INVOICE_NO_EVENT' AS varchar(40)), CAST(N'P2' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT d.anomaly_type, d.contact_no
    INTO #ActualAnomalies
    FROM Layercake.silv_data_anomaly AS d;

    EXEC tSQLt.AssertEqualsTable @Expected = N'#ExpectedAnomalies', @Actual = N'#ActualAnomalies', @Message = N'anomalies';
END
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD023.[test TC-023-008 a failing Phase 1 step fails the daily run and no segment load runs]
AS
BEGIN
    -- The fact's real primary key, and two silver events with one event_id: the Phase 1
    -- gold step's fact insert fails with a duplicate key (2627).
    EXEC tSQLt.ApplyConstraint 'Layercake.fact_membership_events', 'pk_fact_membership_events';

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id,
         assessment_route_id, rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year,
         campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (103, N'RN:P3:2025', 'Renewal', 'Standard', '2024-10-12', NULL, N'P3', 2,
            0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (103, N'RN:P3:2025b', 'Renewal', 'Standard', '2024-10-12', NULL, N'P3', 2,
            0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);

    DECLARE @error_number int = NULL;

    BEGIN TRY
        EXEC Layercake.usp_run_daily_load;
        EXEC tSQLt.Fail 'usp_run_daily_load did not fail when the Phase 1 gold step failed';
    END TRY
    BEGIN CATCH
        SET @error_number = ERROR_NUMBER();
        IF @error_number <> 2627 THROW;
    END CATCH;

    EXEC tSQLt.AssertEquals 2627, @error_number, 'The original error reaches the caller';

    DECLARE @run_status varchar(10) = (SELECT l.status FROM Layercake.etl_run_log AS l
                                       WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load');
    DECLARE @segment_rows int =
        (SELECT COUNT(*)
         FROM Layercake.etl_run_log AS l
         WHERE l.step_name IN ('usp_run_payment_segments', 'brnz_subs_invoice', 'brnz_subs_invoice_line',
                               'brnz_corporate_subscription', 'brnz_concession', 'silv_ref_invoice_line_type',
                               'silv_ref_currency', 'silv_ref_concession_type', 'dim_payment_method',
                               'dim_payer_type', 'dim_currency', 'dim_concession_type',
                               'silv_member_year_attributes', 'silv_event_amount', 'silv_data_anomaly_segment',
                               'silv_data_anomaly_invoice', 'silv_membership_events_segments',
                               'fact_membership_events_segments'));
    DECLARE @attribute_rows int = (SELECT COUNT(*) FROM Layercake.silv_member_year_attributes);
    DECLARE @bronze_invoice_rows int = (SELECT COUNT(*) FROM Layercake.brnz_subs_invoice);

    EXEC tSQLt.AssertEquals 'Failed', @run_status, 'The daily run row ends Failed';
    EXEC tSQLt.AssertEquals 0, @segment_rows, 'No segment step is logged';
    EXEC tSQLt.AssertEquals 0, @attribute_rows, 'No attributes are derived';
    EXEC tSQLt.AssertEquals 0, @bronze_invoice_rows, 'No invoice is landed';

    SELECT l.layer, l.step_name, l.status
    INTO #ActualPhase1
    FROM Layercake.etl_run_log AS l
    WHERE l.step_name IN ('phase1_bronze_stub', 'phase1_silver_stub');

    SELECT v.layer, v.step_name, v.status
    INTO #ExpectedPhase1
    FROM (VALUES ('bronze', 'phase1_bronze_stub', 'Success'),
                 ('silver', 'phase1_silver_stub', 'Success')) AS v (layer, step_name, status);

    EXEC tSQLt.AssertEqualsTable '#ExpectedPhase1', '#ActualPhase1', 'Phase 1 steps before the failure';
END;
GO

CREATE PROCEDURE test_MOD023.[test TC-023-009 a segment-only rerun after the daily run logs Success and 0 0 0 for every load]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''daily_count_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''daily_fact_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';

    EXEC Layercake.usp_run_daily_load;

    DECLARE @rerun_id uniqueidentifier = NEWID();
    EXEC Layercake.usp_run_payment_segments @run_id = @rerun_id;

    SELECT v.layer, v.step_name, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #Expected
    FROM (VALUES
        (CAST('run' AS varchar(12)), CAST('usp_run_payment_segments' AS varchar(128)), CAST('Success' AS varchar(10)), CAST(NULL AS int), CAST(NULL AS int), CAST(NULL AS int)),
        ('bronze', 'brnz_subs_invoice', 'Success', 0, 0, 0),
        ('bronze', 'brnz_subs_invoice_line', 'Success', 0, 0, 0),
        ('bronze', 'brnz_corporate_subscription', 'Success', 0, 0, 0),
        ('bronze', 'brnz_concession', 'Success', 0, 0, 0),
        ('silver', 'silv_ref_invoice_line_type', 'Success', 0, 0, 0),
        ('silver', 'silv_ref_currency', 'Success', 0, 0, 0),
        ('silver', 'silv_ref_concession_type', 'Success', 0, 0, 0),
        ('gold', 'dim_payment_method', 'Success', 0, 0, 0),
        ('gold', 'dim_payer_type', 'Success', 0, 0, 0),
        ('gold', 'dim_currency', 'Success', 0, 0, 0),
        ('gold', 'dim_concession_type', 'Success', 0, 0, 0),
        ('silver', 'silv_member_year_attributes', 'Success', 0, 0, 0),
        ('silver', 'silv_event_amount', 'Success', 0, 0, 0),
        ('silver', 'silv_data_anomaly_segment', 'Success', 0, 0, 0),
        ('silver', 'silv_data_anomaly_invoice', 'Success', 0, 0, 0),
        ('silver', 'silv_membership_events_segments', 'Success', 0, 0, 0),
        ('gold', 'fact_membership_events_segments', 'Success', 0, 0, 0)
    ) AS v(layer, step_name, status, rows_inserted, rows_updated, rows_deleted);

    SELECT l.layer, l.step_name, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #Actual
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @rerun_id;

    EXEC tSQLt.AssertEqualsTable @Expected = N'#Expected', @Actual = N'#Actual';
END
GO

CREATE PROCEDURE test_MOD023.[test TC-023-010 a second daily run on unchanged data changes no segment row]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''daily_count_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''daily_fact_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';

    EXEC Layercake.usp_run_daily_load;

    SELECT * INTO #attributes_before FROM Layercake.silv_member_year_attributes;
    SELECT * INTO #event_amount_before FROM Layercake.silv_event_amount;
    SELECT * INTO #events_before FROM Layercake.silv_membership_events;
    SELECT * INTO #facts_before FROM Layercake.fact_membership_events;
    SELECT * INTO #anomalies_before FROM Layercake.silv_data_anomaly;

    EXEC Layercake.usp_run_daily_load;

    SELECT * INTO #attributes_after FROM Layercake.silv_member_year_attributes;
    SELECT * INTO #event_amount_after FROM Layercake.silv_event_amount;
    SELECT * INTO #events_after FROM Layercake.silv_membership_events;
    SELECT * INTO #facts_after FROM Layercake.fact_membership_events;
    SELECT * INTO #anomalies_after FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable @Expected = N'#attributes_before', @Actual = N'#attributes_after', @Message = N'silv_member_year_attributes';
    EXEC tSQLt.AssertEqualsTable @Expected = N'#event_amount_before', @Actual = N'#event_amount_after', @Message = N'silv_event_amount';
    EXEC tSQLt.AssertEqualsTable @Expected = N'#events_before', @Actual = N'#events_after', @Message = N'silv_membership_events';
    EXEC tSQLt.AssertEqualsTable @Expected = N'#facts_before', @Actual = N'#facts_after', @Message = N'fact_membership_events';
    EXEC tSQLt.AssertEqualsTable @Expected = N'#anomalies_before', @Actual = N'#anomalies_after', @Message = N'silv_data_anomaly';

    DECLARE @second_run_id uniqueidentifier = (
        SELECT TOP (1) l.run_id FROM Layercake.etl_run_log AS l
        WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load'
        ORDER BY l.log_id DESC);

    SELECT v.layer, v.step_name, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #Expected
    FROM (VALUES
        (CAST('bronze' AS varchar(12)), CAST('brnz_subs_invoice' AS varchar(128)), CAST('Success' AS varchar(10)), 0, 0, 0),
        ('bronze', 'brnz_subs_invoice_line', 'Success', 0, 0, 0),
        ('bronze', 'brnz_corporate_subscription', 'Success', 0, 0, 0),
        ('bronze', 'brnz_concession', 'Success', 0, 0, 0),
        ('silver', 'silv_ref_invoice_line_type', 'Success', 0, 0, 0),
        ('silver', 'silv_ref_currency', 'Success', 0, 0, 0),
        ('silver', 'silv_ref_concession_type', 'Success', 0, 0, 0),
        ('gold', 'dim_payment_method', 'Success', 0, 0, 0),
        ('gold', 'dim_payer_type', 'Success', 0, 0, 0),
        ('gold', 'dim_currency', 'Success', 0, 0, 0),
        ('gold', 'dim_concession_type', 'Success', 0, 0, 0),
        ('silver', 'silv_member_year_attributes', 'Success', 0, 0, 0),
        ('silver', 'silv_event_amount', 'Success', 0, 0, 0),
        ('silver', 'silv_data_anomaly_segment', 'Success', 0, 0, 0),
        ('silver', 'silv_data_anomaly_invoice', 'Success', 0, 0, 0),
        ('silver', 'silv_membership_events_segments', 'Success', 0, 0, 0),
        ('gold', 'fact_membership_events_segments', 'Success', 0, 0, 0)
    ) AS v(layer, step_name, status, rows_inserted, rows_updated, rows_deleted);

    SELECT l.layer, l.step_name, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #Actual
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @second_run_id
      AND l.layer <> 'run'
      AND l.step_name NOT LIKE 'phase1[_]%'
      AND l.step_name NOT IN ('daily_count_stub', 'daily_fact_stub');

    EXEC tSQLt.AssertEqualsTable @Expected = N'#Expected', @Actual = N'#Actual', @Message = N'second run segment load rows';
END
GO

CREATE PROCEDURE test_MOD023.[test TC-023-011 the segment step leaves the Phase 1 data the difference scripts compare unchanged]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''daily_count_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''daily_fact_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';

    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count';

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count,
         payment_method_id, payer_type_id, concession_type_id)
    VALUES ('2025-06-01', 2025, 'Q3', 'UK', 0, 0, 'election', 1, 1, 1, 1, 0, 0, 0, 0, 5, 2, 1);

    INSERT INTO Layercake.silv_daily_count
        ([date], campaign_year, campaign_quarter, region, grade,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-06-01', 2025, 'Q3', 'UK', 'election', 1, 1, 1, 0, 0, 0, 0);

    SELECT * INTO #detail_before FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_before FROM Layercake.silv_daily_count;
    SELECT * INTO #payments_before FROM Layercake.silv_payment_events;
    SELECT * INTO #status_before FROM Layercake.brnz_subs_status;

    EXEC Layercake.usp_run_daily_load;

    SELECT * INTO #detail_after FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_after FROM Layercake.silv_daily_count;
    SELECT * INTO #payments_after FROM Layercake.silv_payment_events;
    SELECT * INTO #status_after FROM Layercake.brnz_subs_status;

    EXEC tSQLt.AssertEqualsTable @Expected = N'#detail_before', @Actual = N'#detail_after', @Message = N'silv_daily_count_detail';
    EXEC tSQLt.AssertEqualsTable @Expected = N'#daily_before', @Actual = N'#daily_after', @Message = N'silv_daily_count';
    EXEC tSQLt.AssertEqualsTable @Expected = N'#payments_before', @Actual = N'#payments_after', @Message = N'silv_payment_events';
    EXEC tSQLt.AssertEqualsTable @Expected = N'#status_before', @Actual = N'#status_after', @Message = N'brnz_subs_status';

    SELECT v.event_id, v.event_nk, v.event_type, v.event_subtype, v.event_date, v.contact_no, v.grade_id, v.country_id,
           v.gender_id, v.membership_status_id, v.campaign_year, v.campaign_quarter
    INTO #ExpectedSilver
    FROM (VALUES
        (101, CAST(N'RN:P1:2025' AS nvarchar(220)), CAST('Renewal' AS varchar(20)), CAST('Standard' AS varchar(20)), CAST('2024-10-05' AS date), CAST(N'P1' AS nvarchar(200)), 2, 0, 0, 1, 2025, CAST('Q1' AS char(2))),
        (102, N'LA:P1:2026', 'Lapse', 'Standard', CAST('2025-12-31' AS date), N'P1', 2, 0, 0, 1, 2026, CAST('Q1' AS char(2)))
    ) AS v(event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, country_id,
           gender_id, membership_status_id, campaign_year, campaign_quarter);

    SELECT e.event_id, e.event_nk, e.event_type, e.event_subtype, e.event_date, e.contact_no, e.grade_id, e.country_id,
           e.gender_id, e.membership_status_id, e.campaign_year, e.campaign_quarter
    INTO #ActualSilver
    FROM Layercake.silv_membership_events AS e;

    EXEC tSQLt.AssertEqualsTable @Expected = N'#ExpectedSilver', @Actual = N'#ActualSilver', @Message = N'Phase 1 columns of silv_membership_events';

    SELECT v.event_id, v.event_type, v.event_subtype, v.event_date, v.date_id, v.contact_no, v.grade_id, v.country_id,
           v.gender_id, v.membership_status_id, v.campaign_year, v.campaign_quarter
    INTO #ExpectedGold
    FROM (VALUES
        (101, CAST('Renewal' AS varchar(20)), CAST('Standard' AS varchar(20)), CAST('2024-10-05' AS date), 0, CAST(N'P1' AS nvarchar(200)), 2, 0, 0, 1, 2025, CAST('Q1' AS char(2))),
        (102, 'Lapse', 'Standard', CAST('2025-12-31' AS date), 0, N'P1', 2, 0, 0, 1, 2026, CAST('Q1' AS char(2)))
    ) AS v(event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, country_id,
           gender_id, membership_status_id, campaign_year, campaign_quarter);

    SELECT f.event_id, f.event_type, f.event_subtype, f.event_date, f.date_id, f.contact_no, f.grade_id, f.country_id,
           f.gender_id, f.membership_status_id, f.campaign_year, f.campaign_quarter
    INTO #ActualGold
    FROM Layercake.fact_membership_events AS f;

    EXEC tSQLt.AssertEqualsTable @Expected = N'#ExpectedGold', @Actual = N'#ActualGold', @Message = N'Phase 1 columns of fact_membership_events';
END
GO

CREATE PROCEDURE test_MOD023.[test TC-023-012 usp_run_payment_segments still runs alone as a segment-only rerun]
AS
BEGIN
    DECLARE @rerun_id uniqueidentifier = NEWID();
    EXEC Layercake.usp_run_payment_segments @run_id = @rerun_id, @as_of_date = '2026-06-15';

    DECLARE @segment_run_status varchar(10) = (SELECT l.status FROM Layercake.etl_run_log AS l
                                               WHERE l.layer = 'run' AND l.step_name = 'usp_run_payment_segments');
    DECLARE @phase1_rows int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l
                                WHERE l.step_name IN ('usp_run_daily_load', 'phase1_bronze_stub',
                                                      'phase1_silver_stub', 'phase1_gold_stub'));
    DECLARE @other_run_ids int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l WHERE l.run_id <> @rerun_id);

    EXEC tSQLt.AssertEquals 'Success', @segment_run_status, 'The segment-only run ends Success';
    EXEC tSQLt.AssertEquals 0, @phase1_rows, 'No daily run and no Phase 1 step runs';
    EXEC tSQLt.AssertEquals 0, @other_run_ids, 'Every step logs under the run id passed in';

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried, a.payer_type_id,
           a.payer_type_carried, a.corporate_account_ref, a.concession_type_id, a.concession_type_carried,
           a.segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payment_method_carried, v.payer_type_id,
           v.payer_type_carried, v.corporate_account_ref, v.concession_type_id, v.concession_type_carried,
           v.segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'P1', 2025, 5, CAST(0 AS bit), 2, CAST(0 AS bit), N'S-100', 1, CAST(0 AS bit), CAST(5001 AS bigint)),
                 (N'P1', 2026, 5, CAST(1 AS bit), 2, CAST(1 AS bit), N'S-100', 0, CAST(0 AS bit), CAST(NULL AS bigint)))
         AS v (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
               corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD023.[test TC-023-013 a plain daily run asks for no rebuild and FullRebuild stays an optional manual switch]
AS
BEGIN
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @l bigint; DECLARE @received nvarchar(4000) = CONCAT(CAST(@FullRebuild AS varchar(1)), ''|'', ISNULL(CONVERT(varchar(10), @RebuildFrom, 23), ''NULL'')); EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''daily_count_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'', NULL, NULL, NULL, @received;';
    EXEC tSQLt.SpyProcedure @ProcedureName = N'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @l bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''daily_fact_stub'', @l OUTPUT; EXEC Layercake.usp_etl_log_end @l, ''Success'';';

    EXEC Layercake.usp_run_daily_load;
    EXEC Layercake.usp_run_daily_load @FullRebuild = 1;

    DECLARE @stub_rows int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l WHERE l.layer = 'silver' AND l.step_name = 'daily_count_stub');
    DECLARE @stub_run_ids int = (SELECT COUNT(DISTINCT l.run_id) FROM Layercake.etl_run_log AS l WHERE l.layer = 'silver' AND l.step_name = 'daily_count_stub');
    EXEC tSQLt.AssertEquals @Expected = 2, @Actual = @stub_rows, @Message = N'the daily count step is called once per daily run';
    EXEC tSQLt.AssertEquals @Expected = 2, @Actual = @stub_run_ids, @Message = N'the two daily count calls carry different run_ids';

    SELECT v.call_no, v.received
    INTO #Expected
    FROM (VALUES
        (CAST(1 AS bigint), CAST(N'0|NULL' AS nvarchar(4000))),
        (CAST(2 AS bigint), CAST(N'1|NULL' AS nvarchar(4000)))
    ) AS v(call_no, received);

    SELECT ROW_NUMBER() OVER (ORDER BY r.log_id) AS call_no, s.error_message AS received
    INTO #Actual
    FROM Layercake.etl_run_log AS s
    JOIN Layercake.etl_run_log AS r
      ON r.run_id = s.run_id AND r.layer = 'run' AND r.step_name = 'usp_run_daily_load'
    WHERE s.layer = 'silver' AND s.step_name = 'daily_count_stub';

    EXEC tSQLt.AssertEqualsTable @Expected = N'#Expected', @Actual = N'#Actual', @Message = N'FullRebuild and RebuildFrom received by the daily count step, by daily run';

    DECLARE @daily_runs int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load');
    DECLARE @daily_not_success int = (
        SELECT COUNT(*) FROM Layercake.etl_run_log AS l
        WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load' AND ISNULL(l.status, '') <> 'Success');
    EXEC tSQLt.AssertEquals @Expected = 2, @Actual = @daily_runs, @Message = N'two daily run rows';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @daily_not_success, @Message = N'both daily runs succeed';
END
GO
