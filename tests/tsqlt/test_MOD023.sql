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
    EXEC Layercake.usp_run_daily_load;

    DECLARE @run_ids int = (SELECT COUNT(DISTINCT l.run_id) FROM Layercake.etl_run_log AS l);
    EXEC tSQLt.AssertEquals 1, @run_ids, 'Every row the call logs carries the same run_id';

    SELECT l.layer, l.step_name, l.status, COUNT(*) AS step_rows
    INTO #Actual
    FROM Layercake.etl_run_log AS l
    WHERE NOT (l.layer = 'run' AND l.step_name = 'usp_run_payment_segments')
    GROUP BY l.layer, l.step_name, l.status;

    SELECT v.layer, v.step_name, v.status, v.step_rows
    INTO #Expected
    FROM (VALUES ('run', 'usp_run_daily_load', 'Success', 1),
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
                 ('gold', 'fact_membership_events_segments', 'Success', 1)) AS v (layer, step_name, status, step_rows);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD023.[test TC-023-002 every segment load starts after the Phase 1 gold step]
AS
BEGIN
    EXEC Layercake.usp_run_daily_load;

    DECLARE @gold_log_id bigint = (SELECT l.log_id FROM Layercake.etl_run_log AS l
                                   WHERE l.layer = 'gold' AND l.step_name = 'phase1_gold_stub');

    SELECT l.log_id
    INTO #segment_rows
    FROM Layercake.etl_run_log AS l
    INNER JOIN (VALUES ('bronze', 'brnz_subs_invoice'), ('bronze', 'brnz_subs_invoice_line'),
                       ('bronze', 'brnz_corporate_subscription'), ('bronze', 'brnz_concession'),
                       ('silver', 'silv_ref_invoice_line_type'), ('silver', 'silv_ref_currency'),
                       ('silver', 'silv_ref_concession_type'), ('gold', 'dim_payment_method'),
                       ('gold', 'dim_payer_type'), ('gold', 'dim_currency'), ('gold', 'dim_concession_type'),
                       ('silver', 'silv_member_year_attributes'), ('silver', 'silv_event_amount'),
                       ('silver', 'silv_data_anomaly_segment'), ('silver', 'silv_data_anomaly_invoice'),
                       ('silver', 'silv_membership_events_segments'), ('gold', 'fact_membership_events_segments'))
               AS s (layer, step_name)
        ON  s.layer = l.layer
        AND s.step_name = l.step_name;

    DECLARE @segment_row_count int = (SELECT COUNT(*) FROM #segment_rows);
    DECLARE @logged_before_gold int = (SELECT COUNT(*) FROM #segment_rows AS r WHERE r.log_id < @gold_log_id);
    DECLARE @gold_ran int = CASE WHEN @gold_log_id IS NOT NULL THEN 1 ELSE 0 END;

    EXEC tSQLt.AssertEquals 17, @segment_row_count, 'Each of the 17 segment loads logs one row';
    EXEC tSQLt.AssertEquals 1, @gold_ran, 'The Phase 1 gold step ran';
    EXEC tSQLt.AssertEquals 0, @logged_before_gold, 'No segment load starts before the Phase 1 gold step';
END;
GO

CREATE PROCEDURE test_MOD023.[test TC-023-003 one daily run gives the same segment results as Phase 1 then a separate segment run]
AS
BEGIN
    -- The Phase 1 run followed by a separate usp_run_payment_segments.
    DECLARE @separate_run_id uniqueidentifier = NEWID();
    EXEC Layercake.usp_load_bronze @run_id = @separate_run_id;
    EXEC Layercake.usp_load_silver @run_id = @separate_run_id;
    EXEC Layercake.usp_load_gold @run_id = @separate_run_id;
    EXEC Layercake.usp_run_payment_segments @run_id = @separate_run_id;

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried, a.payer_type_id,
           a.payer_type_carried, a.corporate_account_ref, a.concession_type_id, a.concession_type_carried,
           a.segment_invoice_rec_id
    INTO #separate_attributes
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT e.event_id, e.event_nk, e.payment_method_id, e.payment_method_carried, e.payer_type_id,
           e.payer_type_carried, e.concession_type_id, e.concession_type_carried, e.subs_amount_gbp,
           e.invoiced_subtotal_gbp, e.amount_status
    INTO #separate_events
    FROM Layercake.silv_membership_events AS e;

    SELECT f.event_id, f.payment_method_id, f.payment_method_carried, f.payer_type_id, f.payer_type_carried,
           f.concession_type_id, f.concession_type_carried, f.subs_amount_gbp, f.invoiced_subtotal_gbp,
           f.amount_status
    INTO #separate_facts
    FROM Layercake.fact_membership_events AS f;

    SELECT d.anomaly_nk, d.anomaly_type, d.contact_no, d.detail, d.resolved_at
    INTO #separate_anomalies
    FROM Layercake.silv_data_anomaly AS d;

    -- Back to the starting state: everything either run writes is cleared and the
    -- Phase 1 Renewal is restored with its segment columns at their defaults.
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
    DELETE FROM Layercake.silv_membership_events;
    DELETE FROM Layercake.fact_membership_events;
    DELETE FROM Layercake.etl_run_log;

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

    -- One call of the daily run on the same data.
    EXEC Layercake.usp_run_daily_load;

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried, a.payer_type_id,
           a.payer_type_carried, a.corporate_account_ref, a.concession_type_id, a.concession_type_carried,
           a.segment_invoice_rec_id
    INTO #daily_attributes
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT e.event_id, e.event_nk, e.payment_method_id, e.payment_method_carried, e.payer_type_id,
           e.payer_type_carried, e.concession_type_id, e.concession_type_carried, e.subs_amount_gbp,
           e.invoiced_subtotal_gbp, e.amount_status
    INTO #daily_events
    FROM Layercake.silv_membership_events AS e;

    SELECT f.event_id, f.payment_method_id, f.payment_method_carried, f.payer_type_id, f.payer_type_carried,
           f.concession_type_id, f.concession_type_carried, f.subs_amount_gbp, f.invoiced_subtotal_gbp,
           f.amount_status
    INTO #daily_facts
    FROM Layercake.fact_membership_events AS f;

    SELECT d.anomaly_nk, d.anomaly_type, d.contact_no, d.detail, d.resolved_at
    INTO #daily_anomalies
    FROM Layercake.silv_data_anomaly AS d;

    -- The separate run did populate the segments (so equality is not two empty results).
    DECLARE @corporate_events int = (SELECT COUNT(*) FROM #separate_events AS e WHERE e.payer_type_id = 2);
    DECLARE @separate_anomaly_rows int = (SELECT COUNT(*) FROM #separate_anomalies);
    EXEC tSQLt.AssertEquals 2, @corporate_events, 'The separate run gives both P1 events payer type Corporate';
    EXEC tSQLt.AssertEquals 1, @separate_anomaly_rows, 'The separate run raises the one INVOICE_NO_EVENT case';

    EXEC tSQLt.AssertEqualsTable '#separate_attributes', '#daily_attributes', 'silv_member_year_attributes differs';
    EXEC tSQLt.AssertEqualsTable '#separate_events', '#daily_events', 'silv_membership_events segment columns differ';
    EXEC tSQLt.AssertEqualsTable '#separate_facts', '#daily_facts', 'fact_membership_events segment columns differ';
    EXEC tSQLt.AssertEqualsTable '#separate_anomalies', '#daily_anomalies', 'silv_data_anomaly differs';
END;
GO

CREATE PROCEDURE test_MOD023.[test TC-023-004 a Lapse new in this run carries Corporate carried in silver and gold after one daily run]
AS
BEGIN
    EXEC Layercake.usp_run_daily_load;

    SELECT e.event_id, e.payment_method_id, e.payment_method_carried, e.payer_type_id, e.payer_type_carried,
           e.concession_type_id, e.concession_type_carried, e.subs_amount_gbp, e.invoiced_subtotal_gbp,
           e.amount_status
    INTO #ActualSilver
    FROM Layercake.silv_membership_events AS e;

    SELECT f.event_id, f.payment_method_id, f.payment_method_carried, f.payer_type_id, f.payer_type_carried,
           f.concession_type_id, f.concession_type_carried, f.subs_amount_gbp, f.invoiced_subtotal_gbp,
           f.amount_status
    INTO #ActualGold
    FROM Layercake.fact_membership_events AS f;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried,
           v.concession_type_id, v.concession_type_carried, v.subs_amount_gbp, v.invoiced_subtotal_gbp,
           v.amount_status
    INTO #Expected
    FROM (VALUES (101, 5, CAST(0 AS bit), 2, CAST(0 AS bit), 1, CAST(0 AS bit),
                  CAST(450.0000 AS decimal(19,4)), CAST(450.0000 AS decimal(19,4)), CAST('Invoiced' AS varchar(30))),
                 (102, 5, CAST(1 AS bit), 2, CAST(1 AS bit), 0, CAST(0 AS bit),
                  CAST(NULL AS decimal(19,4)), CAST(NULL AS decimal(19,4)), CAST(NULL AS varchar(30))))
         AS v (event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
               concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSilver', 'silv_membership_events';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualGold', 'fact_membership_events';
END;
GO

CREATE PROCEDURE test_MOD023.[test TC-023-005 the daily run derives attributes up to the Campaign Year of the run date]
AS
BEGIN
    EXEC Layercake.usp_run_daily_load;

    DECLARE @current_year int = (SELECT c.campaign_year
                                 FROM Layercake.ref_campaign_year_config AS c
                                 WHERE CAST(SYSDATETIME() AS date) BETWEEN c.campaign_year_start AND c.campaign_year_end);
    DECLARE @expected_year_rows int = @current_year - 2024;
    DECLARE @first_year int = (SELECT MIN(a.campaign_year) FROM Layercake.silv_member_year_attributes AS a
                               WHERE a.contact_no = N'P1');
    DECLARE @last_year int = (SELECT MAX(a.campaign_year) FROM Layercake.silv_member_year_attributes AS a
                              WHERE a.contact_no = N'P1');
    DECLARE @year_rows int = (SELECT COUNT(*) FROM Layercake.silv_member_year_attributes AS a
                              WHERE a.contact_no = N'P1');
    DECLARE @other_contacts int = (SELECT COUNT(*) FROM Layercake.silv_member_year_attributes AS a
                                   WHERE a.contact_no <> N'P1');
    DECLARE @later_years_not_carried int =
        (SELECT COUNT(*)
         FROM Layercake.silv_member_year_attributes AS a
         WHERE a.contact_no = N'P1'
           AND a.campaign_year > 2025
           AND NOT (a.payment_method_id = 5 AND a.payment_method_carried = 1
                    AND a.payer_type_id = 2 AND a.payer_type_carried = 1
                    AND a.corporate_account_ref = N'S-100'
                    AND a.concession_type_id = 0 AND a.concession_type_carried = 0
                    AND a.segment_invoice_rec_id IS NULL));

    EXEC tSQLt.AssertEquals 2025, @first_year, 'P1 attributes start at its first event year';
    EXEC tSQLt.AssertEquals @current_year, @last_year, 'P1 attributes end at the Campaign Year covering the run date';
    EXEC tSQLt.AssertEquals @expected_year_rows, @year_rows, 'One P1 row per Campaign Year from 2025 to the current year';
    EXEC tSQLt.AssertEquals 0, @other_contacts, 'Only contacts with events get attributes';
    EXEC tSQLt.AssertEquals 0, @later_years_not_carried, 'Every P1 year after 2025 carries Corporate from 2025';

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried, a.payer_type_id,
           a.payer_type_carried, a.corporate_account_ref, a.concession_type_id, a.concession_type_carried,
           a.segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a
    WHERE a.campaign_year <= 2026;

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
CREATE PROCEDURE test_MOD023.[test TC-023-007 after the source row is corrected the next daily run succeeds and fills every segment]
AS
BEGIN
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status], [Round])
    VALUES (NULL, N'S-200', N'Scheme 200', 2025, N'Active', N'Active', N'1');

    DECLARE @error_number int = NULL;

    BEGIN TRY
        EXEC Layercake.usp_run_daily_load;
        EXEC tSQLt.Fail 'The first usp_run_daily_load did not fail on a corporate subscription with no Contact No';
    END TRY
    BEGIN CATCH
        SET @error_number = ERROR_NUMBER();
        IF @error_number <> 515 THROW;
    END CATCH;

    EXEC tSQLt.AssertEquals 515, @error_number, 'The first run fails with 515';

    DELETE FROM Subs.vwCorpSubscriptions WHERE [Contact No] IS NULL;

    EXEC Layercake.usp_run_daily_load;

    DECLARE @second_run_id uniqueidentifier =
        (SELECT TOP (1) l.run_id FROM Layercake.etl_run_log AS l
         WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load'
         ORDER BY l.log_id DESC);
    DECLARE @second_status varchar(10) = (SELECT l.status FROM Layercake.etl_run_log AS l
                                          WHERE l.run_id = @second_run_id
                                            AND l.layer = 'run' AND l.step_name = 'usp_run_daily_load');
    DECLARE @second_not_success int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l
                                       WHERE l.run_id = @second_run_id AND l.status <> 'Success');
    DECLARE @daily_runs int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l
                               WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load');

    EXEC tSQLt.AssertEquals 2, @daily_runs, 'Two daily runs are logged';
    EXEC tSQLt.AssertEquals 'Success', @second_status, 'The second daily run ends Success';
    EXEC tSQLt.AssertEquals 0, @second_not_success, 'Every step of the second run ends Success';

    SELECT e.event_id, e.payment_method_id, e.payment_method_carried, e.payer_type_id, e.payer_type_carried,
           e.concession_type_id, e.concession_type_carried, e.subs_amount_gbp, e.invoiced_subtotal_gbp,
           e.amount_status
    INTO #ActualSilver
    FROM Layercake.silv_membership_events AS e;

    SELECT f.event_id, f.payment_method_id, f.payment_method_carried, f.payer_type_id, f.payer_type_carried,
           f.concession_type_id, f.concession_type_carried, f.subs_amount_gbp, f.invoiced_subtotal_gbp,
           f.amount_status
    INTO #ActualGold
    FROM Layercake.fact_membership_events AS f;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried,
           v.concession_type_id, v.concession_type_carried, v.subs_amount_gbp, v.invoiced_subtotal_gbp,
           v.amount_status
    INTO #Expected
    FROM (VALUES (101, 5, CAST(0 AS bit), 2, CAST(0 AS bit), 1, CAST(0 AS bit),
                  CAST(450.0000 AS decimal(19,4)), CAST(450.0000 AS decimal(19,4)), CAST('Invoiced' AS varchar(30))),
                 (102, 5, CAST(1 AS bit), 2, CAST(1 AS bit), 0, CAST(0 AS bit),
                  CAST(NULL AS decimal(19,4)), CAST(NULL AS decimal(19,4)), CAST(NULL AS varchar(30))))
         AS v (event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
               concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSilver', 'silv_membership_events';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualGold', 'fact_membership_events';

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payer_type_id, a.corporate_account_ref
    INTO #ActualAttributes
    FROM Layercake.silv_member_year_attributes AS a
    WHERE a.campaign_year <= 2026;

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payer_type_id, v.corporate_account_ref
    INTO #ExpectedAttributes
    FROM (VALUES (N'P1', 2025, 5, 2, N'S-100'), (N'P1', 2026, 5, 2, N'S-100'))
         AS v (contact_no, campaign_year, payment_method_id, payer_type_id, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#ExpectedAttributes', '#ActualAttributes', 'silv_member_year_attributes';

    SELECT d.anomaly_type, d.contact_no
    INTO #ActualAnomalies
    FROM Layercake.silv_data_anomaly AS d;

    SELECT v.anomaly_type, v.contact_no
    INTO #ExpectedAnomalies
    FROM (VALUES ('INVOICE_NO_EVENT', N'P2')) AS v (anomaly_type, contact_no);

    EXEC tSQLt.AssertEqualsTable '#ExpectedAnomalies', '#ActualAnomalies', 'silv_data_anomaly';
END;
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
    EXEC Layercake.usp_run_daily_load;

    DECLARE @rerun_id uniqueidentifier = NEWID();
    EXEC Layercake.usp_run_payment_segments @run_id = @rerun_id;

    SELECT l.layer, l.step_name, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #Actual
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @rerun_id;

    SELECT v.layer, v.step_name, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #Expected
    FROM (VALUES ('run', 'usp_run_payment_segments', 'Success', CAST(NULL AS int), CAST(NULL AS int), CAST(NULL AS int)),
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
                 ('gold', 'fact_membership_events_segments', 'Success', 0, 0, 0))
         AS v (layer, step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD023.[test TC-023-010 a second daily run on unchanged data changes no segment row]
AS
BEGIN
    EXEC Layercake.usp_run_daily_load;

    SELECT * INTO #attributes_before FROM Layercake.silv_member_year_attributes;
    SELECT * INTO #amounts_before FROM Layercake.silv_event_amount;
    SELECT * INTO #events_before FROM Layercake.silv_membership_events;
    SELECT * INTO #facts_before FROM Layercake.fact_membership_events;
    SELECT * INTO #anomalies_before FROM Layercake.silv_data_anomaly;

    EXEC Layercake.usp_run_daily_load;

    SELECT * INTO #attributes_after FROM Layercake.silv_member_year_attributes;
    SELECT * INTO #amounts_after FROM Layercake.silv_event_amount;
    SELECT * INTO #events_after FROM Layercake.silv_membership_events;
    SELECT * INTO #facts_after FROM Layercake.fact_membership_events;
    SELECT * INTO #anomalies_after FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#attributes_before', '#attributes_after', 'silv_member_year_attributes changed';
    EXEC tSQLt.AssertEqualsTable '#amounts_before', '#amounts_after', 'silv_event_amount changed';
    EXEC tSQLt.AssertEqualsTable '#events_before', '#events_after', 'silv_membership_events changed';
    EXEC tSQLt.AssertEqualsTable '#facts_before', '#facts_after', 'fact_membership_events changed';
    EXEC tSQLt.AssertEqualsTable '#anomalies_before', '#anomalies_after', 'silv_data_anomaly changed';

    DECLARE @second_run_id uniqueidentifier =
        (SELECT TOP (1) l.run_id FROM Layercake.etl_run_log AS l
         WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load'
         ORDER BY l.log_id DESC);

    SELECT l.layer, l.step_name, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #Actual
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @second_run_id
      AND l.layer <> 'run'
      AND l.step_name NOT LIKE 'phase1[_]%';

    SELECT v.layer, v.step_name, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #Expected
    FROM (VALUES ('bronze', 'brnz_subs_invoice', 'Success', 0, 0, 0),
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
                 ('gold', 'fact_membership_events_segments', 'Success', 0, 0, 0))
         AS v (layer, step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'Second run segment load counts';
END;
GO

CREATE PROCEDURE test_MOD023.[test TC-023-011 the segment step leaves the Phase 1 data the difference scripts compare unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count';

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count,
         event_lapse_count)
    VALUES ('2025-06-01', 2025, 'Q3', 'UK', 0, 0, 'election', 1, 1, 1, 1, 0, 0, 0, 0);

    INSERT INTO Layercake.silv_daily_count
        ([date], campaign_year, campaign_quarter, region, grade, active_count, paid_count, paid_count_event,
         event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2025-06-01', 2025, 'Q3', 'UK', 'election', 1, 1, 1, 0, 0, 0, 0);

    SELECT * INTO #detail_before FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #count_before FROM Layercake.silv_daily_count;
    SELECT * INTO #payments_before FROM Layercake.silv_payment_events;
    SELECT * INTO #status_before FROM Layercake.brnz_subs_status;

    EXEC Layercake.usp_run_daily_load;

    SELECT * INTO #detail_after FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #count_after FROM Layercake.silv_daily_count;
    SELECT * INTO #payments_after FROM Layercake.silv_payment_events;
    SELECT * INTO #status_after FROM Layercake.brnz_subs_status;

    EXEC tSQLt.AssertEqualsTable '#detail_before', '#detail_after', 'silv_daily_count_detail changed';
    EXEC tSQLt.AssertEqualsTable '#count_before', '#count_after', 'silv_daily_count changed';
    EXEC tSQLt.AssertEqualsTable '#payments_before', '#payments_after', 'silv_payment_events changed';
    EXEC tSQLt.AssertEqualsTable '#status_before', '#status_after', 'brnz_subs_status changed';

    SELECT e.event_id, e.event_nk, e.event_type, e.event_subtype, e.event_date, e.contact_no, e.grade_id,
           e.country_id, e.gender_id, e.membership_status_id, e.campaign_year, e.campaign_quarter
    INTO #ActualEvents
    FROM Layercake.silv_membership_events AS e;

    SELECT f.event_id, f.event_type, f.event_subtype, f.event_date, f.date_id, f.contact_no, f.grade_id,
           f.country_id, f.gender_id, f.membership_status_id, f.campaign_year, f.campaign_quarter
    INTO #ActualFacts
    FROM Layercake.fact_membership_events AS f;

    SELECT v.event_id, v.event_nk, v.event_type, v.event_subtype, v.event_date, v.contact_no, v.grade_id,
           v.country_id, v.gender_id, v.membership_status_id, v.campaign_year, v.campaign_quarter
    INTO #ExpectedEvents
    FROM (VALUES (101, N'RN:P1:2025', 'Renewal', 'Standard', CAST('2024-10-05' AS date), N'P1', 2, 0, 0, 1, 2025, 'Q1'),
                 (102, N'LA:P1:2026', 'Lapse', 'Standard', CAST('2025-12-31' AS date), N'P1', 2, 0, 0, 1, 2026, 'Q1'))
         AS v (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, country_id, gender_id,
               membership_status_id, campaign_year, campaign_quarter);

    SELECT v.event_id, v.event_type, v.event_subtype, v.event_date, v.date_id, v.contact_no, v.grade_id,
           v.country_id, v.gender_id, v.membership_status_id, v.campaign_year, v.campaign_quarter
    INTO #ExpectedFacts
    FROM (VALUES (101, 'Renewal', 'Standard', CAST('2024-10-05' AS date), 0, N'P1', 2, 0, 0, 1, 2025, 'Q1'),
                 (102, 'Lapse', 'Standard', CAST('2025-12-31' AS date), 0, N'P1', 2, 0, 0, 1, 2026, 'Q1'))
         AS v (event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, country_id, gender_id,
               membership_status_id, campaign_year, campaign_quarter);

    EXEC tSQLt.AssertEqualsTable '#ExpectedEvents', '#ActualEvents', 'Phase 1 columns of silv_membership_events';
    EXEC tSQLt.AssertEqualsTable '#ExpectedFacts', '#ActualFacts', 'Phase 1 columns of fact_membership_events';
END;
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
    -- Filled by the Phase 1 silver stand-in with the rebuild arguments it receives.
    CREATE TABLE #silver_calls
    (
        call_no      int IDENTITY(1, 1) NOT NULL,
        full_rebuild bit NULL,
        rebuild_from date NULL
    );

    EXEC Layercake.usp_run_daily_load;
    EXEC Layercake.usp_run_daily_load @FullRebuild = 1;

    SELECT c.call_no, c.full_rebuild, c.rebuild_from
    INTO #Actual
    FROM #silver_calls AS c;

    SELECT v.call_no, v.full_rebuild, v.rebuild_from
    INTO #Expected
    FROM (VALUES (1, CAST(0 AS bit), CAST(NULL AS date)),
                 (2, CAST(1 AS bit), CAST(NULL AS date))) AS v (call_no, full_rebuild, rebuild_from);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'Silver step rebuild arguments';

    DECLARE @runs_not_success int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l
                                     WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load'
                                       AND l.status <> 'Success');
    DECLARE @daily_runs int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l
                               WHERE l.layer = 'run' AND l.step_name = 'usp_run_daily_load');

    EXEC tSQLt.AssertEquals 2, @daily_runs, 'Both calls are logged';
    EXEC tSQLt.AssertEquals 0, @runs_not_success, 'Both calls end Success';
END;
GO
