EXEC tSQLt.NewTestClass 'test_MOD029';
GO

CREATE PROCEDURE test_MOD029.[SetUp]
AS
BEGIN
    -- logging
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;

    -- external sources of the segment loads
    EXEC tSQLt.FakeTable 'Subs.tblSubsInvoices';
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';

    -- segment bronze, reference lists, dimensions, silver
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
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_event_amount', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    -- Phase 1 silver and gold the segment loads and the daily count read or write
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.ref_date_spine';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_status';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_grade';
    EXEC tSQLt.FakeTable 'Layercake.dim_membership_grade';
    EXEC tSQLt.FakeTable 'Layercake.dim_date';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_state_ranges', @Identity = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_profile';

    -- daily count and gold daily fact
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_loaded', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_pending_rebuild', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_input_basis', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_contact', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_state_range', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_payment', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_event', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_attribute', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_cell_contacts', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_daily_member_count_detail', @Identity = 1;

    -- Phase 1 work not owned by MOD-029: the bronze step and the sub-loads of usp_load_silver
    -- and usp_load_gold other than the daily count and the gold daily fact are spied.
    -- Some log a stub step row under the run_id they receive, so calls and order can be read from etl_run_log.
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_bronze',
        @CommandToExecute = N'DECLARE @stub_log bigint; EXEC Layercake.usp_etl_log_start @run_id, ''bronze'', ''phase1_bronze_stub'', @stub_log OUTPUT; EXEC Layercake.usp_etl_log_end @stub_log, ''Success'';';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_ref_assessment_route';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_ref_rpq_variant';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_ref_country';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_ref_lapse_reason';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_ref_date_spine';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_ref_campaign_year_config';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_payment_events';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_ref_enrolment_exception';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_member_base';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_membership_events',
        @CommandToExecute = N'DECLARE @stub_log bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''phase1_events_stub'', @stub_log OUTPUT; EXEC Layercake.usp_etl_log_end @stub_log, ''Success'';';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_data_anomaly';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_member_state_ranges';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_member_profile',
        @CommandToExecute = N'DECLARE @stub_log bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''phase1_profile_stub'', @stub_log OUTPUT; EXEC Layercake.usp_etl_log_end @stub_log, ''Success'';';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_annual_rate_base',
        @CommandToExecute = N'DECLARE @stub_log bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''phase1_rate_base_stub'', @stub_log OUTPUT; EXEC Layercake.usp_etl_log_end @stub_log, ''Success'';';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_membership_grade';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_assessment_route';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_rpq_variant';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_country';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_gender';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_membership_status';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_lapse_reason';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_campaign_year';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_dim_date',
        @CommandToExecute = N'DECLARE @stub_log bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''phase1_dim_date_stub'', @stub_log OUTPUT; EXEC Layercake.usp_etl_log_end @stub_log, ''Success'';';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_fact_membership_events',
        @CommandToExecute = N'DECLARE @stub_log bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''phase1_fact_events_stub'', @stub_log OUTPUT; EXEC Layercake.usp_etl_log_end @stub_log, ''Success'';';
    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_fact_annual_rate_base',
        @CommandToExecute = N'DECLARE @stub_log bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''phase1_fact_rate_base_stub'', @stub_log OUTPUT; EXEC Layercake.usp_etl_log_end @stub_log, ''Success'';';

    -- seeded reference lists
    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code)
    VALUES (0, 'Unknown', NULL), (-1, 'Unrecognised', NULL), (-2, 'Not applicable', NULL),
           (1, 'Direct Debit', 'DD'), (2, 'Card', 'Card'), (3, 'Bank transfer', 'Bank'),
           (4, 'Cheque', 'Cheque'), (5, 'Corporate', 'Corporate');
    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name)
    VALUES (0, 'Unknown'), (-1, 'Unrecognised'), (-2, 'Not applicable'), (1, 'Individual'), (2, 'Corporate');
    INSERT INTO Layercake.silv_ref_concession_type
        (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL),
           (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL),
           (-2, NULL, N'Not applicable', NULL, 0, 0, NULL),
           (1, NULL, N'No concession', NULL, 0, 0, NULL),
           (6, 'C0000000-0000-0000-0000-000000000006', N'Exceptional Hardship', N'CONEXCEPTIONHP', 0, 0, NULL);
    INSERT INTO CE.vwConcessionType
        (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, statuscode, apuk_perpetualnonperpetual)
    VALUES ('E0000000-0000-0000-0000-000000000006', 'C0000000-0000-0000-0000-000000000006',
            N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 1, 200000001);
    INSERT INTO Layercake.silv_ref_membership_status (id, status_name)
    VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');
    INSERT INTO Layercake.silv_ref_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');
    INSERT INTO Layercake.dim_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');

    -- Campaign Years 2020 to 2060, 1 October to 30 September
    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    SELECT n.y, DATEFROMPARTS(n.y - 1, 10, 1), DATEFROMPARTS(n.y, 9, 30), DATEFROMPARTS(n.y, 9, 30)
    FROM (SELECT TOP (41) 2019 + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS y FROM sys.all_objects) AS n;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2023-01-10', 2023, 'Q2'), ('2024-09-30', 2024, 'Q4'), ('2024-10-15', 2025, 'Q1'), ('2025-03-31', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2023-01-10', 2023, 'Q2'), (2, '2024-09-30', 2024, 'Q4'), (3, '2024-10-15', 2025, 'Q1'), (4, '2025-03-31', 2025, 'Q2');

    -- contacts: Y1 and Z1 (country 1), Y10 (country 10), Y11 (country 11); all election, UK, gender 1, Practising
    INSERT INTO Layercake.silv_member_state_ranges (contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (N'Y1', '2023-10-01', NULL, 2024, 'election', 'UK', 1),
           (N'Z1', '2024-10-01', NULL, 2025, 'election', 'UK', 1),
           (N'Y10', '2022-10-01', NULL, 2023, 'election', 'UK', 1),
           (N'Y11', '2024-10-01', NULL, 2025, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'Y1', 1, 1, NULL), (N'Z1', 1, 1, NULL), (N'Y10', 10, 1, NULL), (N'Y11', 11, 1, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'Y1', 2024, '2023-10-10', '2023-10-10', N'Fully Paid'),
           (N'Y1', 2025, '2024-10-10', '2024-10-10', N'Fully Paid'),
           (N'Z1', 2025, '2024-10-10', '2024-10-10', N'Fully Paid'),
           (N'Y10', 2023, '2022-10-10', '2022-10-10', N'Fully Paid'),
           (N'Y10', 2024, '2023-10-10', '2023-10-10', N'Fully Paid'),
           (N'Y11', 2025, '2024-10-10', '2024-10-10', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id,
         assessment_route_id, rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id,
         campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id,
         payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp,
         invoiced_subtotal_gbp, amount_status)
    VALUES (101, N'RN:Y1:2024', 'Renewal', 'Standard', '2023-10-10', NULL, N'Y1', 2, 0, 0, 0, 1, 1, 1, 2024, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (102, N'RN:Y1:2025', 'Renewal', 'Standard', '2024-10-10', NULL, N'Y1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (111, N'RN:Z1:2025', 'Renewal', 'Standard', '2024-10-10', NULL, N'Z1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (121, N'RN:Y10:2023', 'Renewal', 'Standard', '2022-10-10', NULL, N'Y10', 2, 0, 0, 0, 10, 1, 1, 2023, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (122, N'RN:Y10:2024', 'Renewal', 'Standard', '2023-10-10', NULL, N'Y10', 2, 0, 0, 0, 10, 1, 1, 2024, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (131, N'RN:Y11:2025', 'Renewal', 'Standard', '2024-10-10', NULL, N'Y11', 2, 0, 0, 0, 11, 1, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.fact_membership_events
        (event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id,
         rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id,
         concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    SELECT e.event_id, e.event_type, e.event_subtype, e.event_date, 0, e.contact_no, e.grade_id, e.assessment_route_id,
           e.rpq_variant_id, e.hpb_id, e.country_id, e.gender_id, e.membership_status_id, e.campaign_year, e.campaign_quarter,
           0, 0, 0, 0, 0, 0, NULL, NULL, NULL
    FROM Layercake.silv_membership_events AS e;

    -- segment invoices: Y1 2024 DD and 2025 Card, Z1 2025 DD, Y10 2023 and 2024 Card, Y11 2025 Corporate
    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency,
         Exchange_Rate, Full_Invoice_Amount_CUR, Full_Invoice_Amount_GBP, Invoice_Amount_CUR, Invoice_Amount_GBP,
         Fully_Credited, Payment_Status, Has_Concession, [100%_Concession], Last_Settle_Voucher, Retired_Concession,
         APP_Invoice_Flag)
    VALUES (1001, N'Y1', 2024, N'INV-1001', N'V1001', '2023-10-05', N'DD', N'GBP', 1, 450, 450, 450, 450, 'N', N'Fully Paid', 'N', 'N', N'', 'N', 'N'),
           (1002, N'Y1', 2025, N'INV-1002', N'V1002', '2024-10-05', N'Card', N'GBP', 1, 450, 450, 450, 450, 'N', N'Fully Paid', 'N', 'N', N'', 'N', 'N'),
           (1101, N'Z1', 2025, N'INV-1101', N'V1101', '2024-10-05', N'DD', N'GBP', 1, 450, 450, 450, 450, 'N', N'Fully Paid', 'N', 'N', N'', 'N', 'N'),
           (3001, N'Y10', 2023, N'INV-3001', N'V3001', '2022-10-05', N'Card', N'GBP', 1, 450, 450, 450, 450, 'N', N'Fully Paid', 'N', 'N', N'', 'N', 'N'),
           (3002, N'Y10', 2024, N'INV-3002', N'V3002', '2023-10-05', N'Card', N'GBP', 1, 450, 450, 450, 450, 'N', N'Fully Paid', 'N', 'N', N'', 'N', 'N'),
           (4001, N'Y11', 2025, N'INV-4001', N'V4001', '2024-10-05', N'Corporate', N'GBP', 1, 450, 450, 450, 450, 'N', N'Fully Paid', 'N', 'N', N'', 'N', 'N');
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-001 the daily run loads the attributes before the daily count and the gold daily fact once each after it]
AS
BEGIN
    DECLARE @run uniqueidentifier,
            @lid_silver bigint, @lid_gold bigint, @lid_seg bigint, @lid_attr bigint, @lid_dc bigint, @lid_fact bigint,
            @attr_end datetime2(7), @dc_start datetime2(7);

    EXEC Layercake.usp_run_daily_load;

    SELECT @run = run_id FROM Layercake.etl_run_log WHERE layer = 'run' AND step_name = 'usp_run_daily_load';

    SELECT r.layer, r.step_name, r.status, COUNT(*) AS step_rows
    INTO #Actual
    FROM Layercake.etl_run_log AS r
    WHERE r.run_id = @run
      AND r.step_name IN ('usp_run_daily_load', 'phase1_bronze_stub', 'phase1_events_stub', 'phase1_fact_events_stub',
                          'usp_run_payment_segments', 'silv_member_year_attributes', 'silv_daily_count',
                          'fact_daily_member_count_detail')
    GROUP BY r.layer, r.step_name, r.status;

    SELECT v.layer, v.step_name, v.status, v.step_rows
    INTO #Expected
    FROM (VALUES ('run', 'usp_run_daily_load', 'Success', 1),
                 ('bronze', 'phase1_bronze_stub', 'Success', 1),
                 ('silver', 'phase1_events_stub', 'Success', 1),
                 ('gold', 'phase1_fact_events_stub', 'Success', 1),
                 ('run', 'usp_run_payment_segments', 'Success', 1),
                 ('silver', 'silv_member_year_attributes', 'Success', 1),
                 ('silver', 'silv_daily_count', 'Success', 1),
                 ('gold', 'fact_daily_member_count_detail', 'Success', 1)) AS v(layer, step_name, status, step_rows);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @other_runs int = (SELECT COUNT(*) FROM Layercake.etl_run_log WHERE run_id <> @run);
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @other_runs, @Message = N'every step row is under the daily run id';

    SELECT @lid_silver = log_id FROM Layercake.etl_run_log WHERE step_name = 'phase1_events_stub';
    SELECT @lid_gold = log_id FROM Layercake.etl_run_log WHERE step_name = 'phase1_fact_events_stub';
    SELECT @lid_seg = log_id FROM Layercake.etl_run_log WHERE layer = 'run' AND step_name = 'usp_run_payment_segments';
    SELECT @lid_attr = log_id, @attr_end = finished_at FROM Layercake.etl_run_log WHERE step_name = 'silv_member_year_attributes';
    SELECT @lid_dc = log_id, @dc_start = started_at FROM Layercake.etl_run_log WHERE layer = 'silver' AND step_name = 'silv_daily_count';
    SELECT @lid_fact = log_id FROM Layercake.etl_run_log WHERE layer = 'gold' AND step_name = 'fact_daily_member_count_detail';

    SELECT CASE WHEN @lid_silver < @lid_gold THEN 1 ELSE 0 END AS silver_before_gold,
           CASE WHEN @lid_gold < @lid_seg THEN 1 ELSE 0 END AS gold_before_segments,
           CASE WHEN @lid_seg < @lid_attr THEN 1 ELSE 0 END AS attributes_in_segments,
           CASE WHEN @lid_attr < @lid_dc THEN 1 ELSE 0 END AS attributes_before_daily_count,
           CASE WHEN @attr_end <= @dc_start THEN 1 ELSE 0 END AS attributes_finished_before_daily_count_started,
           CASE WHEN @lid_dc < @lid_fact THEN 1 ELSE 0 END AS daily_count_before_daily_fact
    INTO #ActualOrder;

    SELECT 1 AS silver_before_gold, 1 AS gold_before_segments, 1 AS attributes_in_segments,
           1 AS attributes_before_daily_count, 1 AS attributes_finished_before_daily_count_started,
           1 AS daily_count_before_daily_fact
    INTO #ExpectedOrder;

    EXEC tSQLt.AssertEqualsTable '#ExpectedOrder', '#ActualOrder';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-002 a Card to DD change on Y1 2025 invoice moves Y1 to the Direct Debit cell from 1 October in one daily run]
AS
BEGIN
    DECLARE @run2 uniqueidentifier, @recomputed int, @full_path int;

    EXEC Layercake.usp_run_daily_load;
    SELECT * INTO #daily_before FROM Layercake.silv_daily_count;

    UPDATE Subs.tblSubsInvoices SET Inv_Payment_Method = N'DD' WHERE Rec_ID = 1002;

    EXEC Layercake.usp_run_daily_load;

    SELECT TOP (1) @run2 = run_id FROM Layercake.etl_run_log
    WHERE layer = 'run' AND step_name = 'usp_run_daily_load' ORDER BY log_id DESC;

    SELECT @recomputed = p.rows_affected
    FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS r ON r.log_id = p.log_id
    WHERE r.run_id = @run2 AND r.layer = 'silver' AND r.step_name = 'silv_daily_count' AND p.substep = N'contacts_recomputed';
    SELECT @full_path = p.rows_affected
    FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS r ON r.log_id = p.log_id
    WHERE r.run_id = @run2 AND r.layer = 'silver' AND r.step_name = 'silv_daily_count' AND p.substep = N'full_recompute_path';

    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @recomputed, @Message = N'contacts_recomputed';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @full_path, @Message = N'full_recompute_path';

    SELECT d.[date], d.region, d.country_id, d.gender_id, d.grade, d.membership_status_id,
           d.payment_method_id, d.payer_type_id, d.concession_type_id, d.active_count
    INTO #Actual
    FROM Layercake.silv_daily_count_detail AS d
    WHERE d.country_id = 1;

    SELECT CAST(v.[date] AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id, v.active_count
    INTO #Expected
    FROM (VALUES ('2024-09-30', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1),
                 ('2024-10-15', 'UK', 1, 1, 'election', 1, 1, 1, 1, 2),
                 ('2025-03-31', 'UK', 1, 1, 'election', 1, 1, 1, 1, 2))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              payment_method_id, payer_type_id, concession_type_id, active_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT * INTO #daily_after FROM Layercake.silv_daily_count;
    EXEC tSQLt.AssertEqualsTable '#daily_before', '#daily_after';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-003 after the change the daily run leaves the daily tables and fact equal to a full recompute]
AS
BEGIN
    DECLARE @fr uniqueidentifier = NEWID(), @fr_adjustments int;

    EXEC Layercake.usp_run_daily_load;
    UPDATE Subs.tblSubsInvoices SET Inv_Payment_Method = N'DD' WHERE Rec_ID = 1002;
    EXEC Layercake.usp_run_daily_load;

    SELECT * INTO #det_inc FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_inc FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
           concession_type_id, ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents,
           ReadmissionEvents, LapseEvents
    INTO #fact_inc FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silver @run_id = @fr, @FullRebuild = 1;
    EXEC Layercake.usp_load_gold @run_id = @fr;

    SELECT * INTO #det_full FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
           concession_type_id, ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents,
           ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;

    EXEC tSQLt.AssertEqualsTable '#det_full', '#det_inc', @Message = N'silv_daily_count_detail';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_inc', @Message = N'silv_daily_count';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_inc', @Message = N'fact_daily_member_count_detail';

    SELECT @fr_adjustments = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @fr;
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @fr_adjustments, @Message = N'the full recompute finds nothing left to correct';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-004 the run writes Card -1 and Direct Debit +1 adjustment rows with the actual ids from 1 October only]
AS
BEGIN
    DECLARE @run2 uniqueidentifier;

    EXEC Layercake.usp_run_daily_load;
    UPDATE Subs.tblSubsInvoices SET Inv_Payment_Method = N'DD' WHERE Rec_ID = 1002;
    EXEC Layercake.usp_run_daily_load;

    SELECT TOP (1) @run2 = run_id FROM Layercake.etl_run_log
    WHERE layer = 'run' AND step_name = 'usp_run_daily_load' ORDER BY log_id DESC;

    SELECT a.[date], a.region, a.country_id, a.gender_id, a.grade, a.membership_status_id,
           a.payment_method_id, a.payer_type_id, a.concession_type_id, a.active_count_change
    INTO #Actual
    FROM Layercake.silv_daily_count_adjustment AS a
    WHERE a.run_id = @run2;

    SELECT CAST(v.[date] AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id, v.active_count_change
    INTO #Expected
    FROM (VALUES ('2024-10-15', 'UK', 1, 1, 'election', 1, 2, 1, 1, -1),
                 ('2024-10-15', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1),
                 ('2025-03-31', 'UK', 1, 1, 'election', 1, 2, 1, 1, -1),
                 ('2025-03-31', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              payment_method_id, payer_type_id, concession_type_id, active_count_change);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-005 the run adjustment rows equal after minus before for every cell and measure and net to 0 at the daily grain]
AS
BEGIN
    DECLARE @run2 uniqueidentifier, @rows int;

    EXEC Layercake.usp_run_daily_load;
    SELECT * INTO #before FROM Layercake.silv_daily_count_detail;

    UPDATE Subs.tblSubsInvoices SET Inv_Payment_Method = N'DD' WHERE Rec_ID = 1002;
    EXEC Layercake.usp_run_daily_load;
    SELECT * INTO #after FROM Layercake.silv_daily_count_detail;

    SELECT TOP (1) @run2 = run_id FROM Layercake.etl_run_log
    WHERE layer = 'run' AND step_name = 'usp_run_daily_load' ORDER BY log_id DESC;

    SELECT @rows = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @run2;
    EXEC tSQLt.AssertEquals @Expected = 4, @Actual = @rows, @Message = N'adjustment rows written by the run';

    SELECT u.[date], u.region, u.country_id, u.gender_id, u.grade, u.membership_status_id,
           u.payment_method_id, u.payer_type_id, u.concession_type_id
    INTO #mismatch
    FROM (SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id,
                 concession_type_id, active_count AS a, paid_count AS p, paid_count_event AS pe, event_join_count AS j,
                 event_renewal_count AS rn, event_readmission_count AS rd, event_lapse_count AS l
          FROM #after
          UNION ALL
          SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id,
                 concession_type_id, -active_count, -paid_count, -paid_count_event, -event_join_count,
                 -event_renewal_count, -event_readmission_count, -event_lapse_count
          FROM #before
          UNION ALL
          SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id,
                 concession_type_id, -active_count_change, -paid_count_change, -paid_count_event_change,
                 -event_join_count_change, -event_renewal_count_change, -event_readmission_count_change,
                 -event_lapse_count_change
          FROM Layercake.silv_daily_count_adjustment
          WHERE run_id = @run2) AS u
    GROUP BY u.[date], u.region, u.country_id, u.gender_id, u.grade, u.membership_status_id,
             u.payment_method_id, u.payer_type_id, u.concession_type_id
    HAVING SUM(u.a) <> 0 OR SUM(u.p) <> 0 OR SUM(u.pe) <> 0 OR SUM(u.j) <> 0
        OR SUM(u.rn) <> 0 OR SUM(u.rd) <> 0 OR SUM(u.l) <> 0;

    EXEC tSQLt.AssertEmptyTable '#mismatch';

    SELECT a.[date], a.region, a.grade
    INTO #daily_grain_net
    FROM Layercake.silv_daily_count_adjustment AS a
    WHERE a.run_id = @run2
    GROUP BY a.[date], a.region, a.grade
    HAVING SUM(a.active_count_change) <> 0 OR SUM(a.paid_count_change) <> 0 OR SUM(a.paid_count_event_change) <> 0
        OR SUM(a.event_join_count_change) <> 0 OR SUM(a.event_renewal_count_change) <> 0
        OR SUM(a.event_readmission_count_change) <> 0 OR SUM(a.event_lapse_count_change) <> 0;

    EXEC tSQLt.AssertEmptyTable '#daily_grain_net';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-006 Y10 gaining an Exceptional Hardship line on its 2023 invoice moves only its 2023 days to the new concession cell]
AS
BEGIN
    DECLARE @run2 uniqueidentifier, @recomputed int, @full_path int, @fr uniqueidentifier = NEWID();

    EXEC Layercake.usp_run_daily_load;

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, CUSTTRANSRECID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE,
         productcode, AMOUNTCUR, AMOUNTMST, CURRENCYCODE, POSTINGTYPE, ACCOUNTDISPLAYVALUE, DATAAREAID, DATAAREAIDCUST, PARTITION)
    VALUES (930001, 930001, N'Y10', N'INV-3001', N'V3001', NULL, '2022-10-05', 2, 'SUB',
            N'CONEXCEPTIONHP', -225, -225, N'GBP', 31, N'4000-100-CONEXCEPTIONHP', N'rics', N'rics', 1);

    EXEC Layercake.usp_run_daily_load;

    SELECT TOP (1) @run2 = run_id FROM Layercake.etl_run_log
    WHERE layer = 'run' AND step_name = 'usp_run_daily_load' ORDER BY log_id DESC;

    SELECT @recomputed = p.rows_affected
    FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS r ON r.log_id = p.log_id
    WHERE r.run_id = @run2 AND r.layer = 'silver' AND r.step_name = 'silv_daily_count' AND p.substep = N'contacts_recomputed';
    SELECT @full_path = p.rows_affected
    FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS r ON r.log_id = p.log_id
    WHERE r.run_id = @run2 AND r.layer = 'silver' AND r.step_name = 'silv_daily_count' AND p.substep = N'full_recompute_path';

    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @recomputed, @Message = N'contacts_recomputed';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @full_path, @Message = N'full_recompute_path';

    SELECT d.[date], d.region, d.country_id, d.gender_id, d.grade, d.membership_status_id,
           d.payment_method_id, d.payer_type_id, d.concession_type_id, d.active_count
    INTO #Actual
    FROM Layercake.silv_daily_count_detail AS d
    WHERE d.country_id = 10;

    SELECT CAST(v.[date] AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id, v.active_count
    INTO #Expected
    FROM (VALUES ('2023-01-10', 'UK', 10, 1, 'election', 1, 2, 1, 6, 1),
                 ('2024-09-30', 'UK', 10, 1, 'election', 1, 2, 1, 1, 1),
                 ('2024-10-15', 'UK', 10, 1, 'election', 1, 2, 1, 0, 1),
                 ('2025-03-31', 'UK', 10, 1, 'election', 1, 2, 1, 0, 1))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              payment_method_id, payer_type_id, concession_type_id, active_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', @Message = N'Y10 detail cells';

    SELECT a.[date], a.country_id, a.payment_method_id, a.payer_type_id, a.concession_type_id, a.active_count_change
    INTO #ActualAdj
    FROM Layercake.silv_daily_count_adjustment AS a
    WHERE a.run_id = @run2;

    SELECT CAST(v.[date] AS date) AS [date], v.country_id, v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count_change
    INTO #ExpectedAdj
    FROM (VALUES ('2023-01-10', 10, 2, 1, 1, -1),
                 ('2023-01-10', 10, 2, 1, 6, 1))
         AS v([date], country_id, payment_method_id, payer_type_id, concession_type_id, active_count_change);

    EXEC tSQLt.AssertEqualsTable '#ExpectedAdj', '#ActualAdj', @Message = N'adjustment rows of the run';

    SELECT * INTO #det_inc FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_inc FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
           concession_type_id, ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents,
           ReadmissionEvents, LapseEvents
    INTO #fact_inc FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silver @run_id = @fr, @FullRebuild = 1;
    EXEC Layercake.usp_load_gold @run_id = @fr;

    SELECT * INTO #det_full FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
           concession_type_id, ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents,
           ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;

    EXEC tSQLt.AssertEqualsTable '#det_full', '#det_inc', @Message = N'silv_daily_count_detail';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_inc', @Message = N'silv_daily_count';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_inc', @Message = N'fact_daily_member_count_detail';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-007 Y11 gaining a live 2025 corporate subscription moves only its 2025 days to the Corporate payer cell]
AS
BEGIN
    DECLARE @run2 uniqueidentifier, @recomputed int, @full_path int, @fr uniqueidentifier = NEWID();

    EXEC Layercake.usp_run_daily_load;

    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Contact ID], [Scheme No], [Scheme Name], [Sub Start Date], [Sub End Date], [Sub State],
         [Sub Status], [Sub Campaign Year], [Round], [Sub User State], [Sub User Status], [Sub User Created Date],
         [Invalid Member Grade], [Is Lapsed], [Inactive SU Status], [Quote Expected])
    VALUES (N'Y11', 'A0000000-0000-0000-0000-000000000011', N'S-110', N'Scheme 110', '2024-10-01', '2025-09-30', N'Active',
            N'Active', 2025, N'Round 1', N'Active', N'Active', '2024-09-01', 'N', 'N', 'N', 'N');

    EXEC Layercake.usp_run_daily_load;

    SELECT TOP (1) @run2 = run_id FROM Layercake.etl_run_log
    WHERE layer = 'run' AND step_name = 'usp_run_daily_load' ORDER BY log_id DESC;

    SELECT @recomputed = p.rows_affected
    FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS r ON r.log_id = p.log_id
    WHERE r.run_id = @run2 AND r.layer = 'silver' AND r.step_name = 'silv_daily_count' AND p.substep = N'contacts_recomputed';
    SELECT @full_path = p.rows_affected
    FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS r ON r.log_id = p.log_id
    WHERE r.run_id = @run2 AND r.layer = 'silver' AND r.step_name = 'silv_daily_count' AND p.substep = N'full_recompute_path';

    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @recomputed, @Message = N'contacts_recomputed';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @full_path, @Message = N'full_recompute_path';

    SELECT d.[date], d.region, d.country_id, d.gender_id, d.grade, d.membership_status_id,
           d.payment_method_id, d.payer_type_id, d.concession_type_id, d.active_count
    INTO #Actual
    FROM Layercake.silv_daily_count_detail AS d
    WHERE d.country_id = 11;

    SELECT CAST(v.[date] AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id, v.active_count
    INTO #Expected
    FROM (VALUES ('2024-10-15', 'UK', 11, 1, 'election', 1, 5, 2, 1, 1),
                 ('2025-03-31', 'UK', 11, 1, 'election', 1, 5, 2, 1, 1))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              payment_method_id, payer_type_id, concession_type_id, active_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', @Message = N'Y11 detail cells';

    SELECT a.[date], a.country_id, a.payment_method_id, a.payer_type_id, a.concession_type_id, a.active_count_change
    INTO #ActualAdj
    FROM Layercake.silv_daily_count_adjustment AS a
    WHERE a.run_id = @run2;

    SELECT CAST(v.[date] AS date) AS [date], v.country_id, v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count_change
    INTO #ExpectedAdj
    FROM (VALUES ('2024-10-15', 11, 5, 1, 1, -1),
                 ('2024-10-15', 11, 5, 2, 1, 1),
                 ('2025-03-31', 11, 5, 1, 1, -1),
                 ('2025-03-31', 11, 5, 2, 1, 1))
         AS v([date], country_id, payment_method_id, payer_type_id, concession_type_id, active_count_change);

    EXEC tSQLt.AssertEqualsTable '#ExpectedAdj', '#ActualAdj', @Message = N'adjustment rows of the run';

    SELECT * INTO #det_inc FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_inc FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
           concession_type_id, ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents,
           ReadmissionEvents, LapseEvents
    INTO #fact_inc FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silver @run_id = @fr, @FullRebuild = 1;
    EXEC Layercake.usp_load_gold @run_id = @fr;

    SELECT * INTO #det_full FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
           concession_type_id, ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents,
           ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;

    EXEC tSQLt.AssertEqualsTable '#det_full', '#det_inc', @Message = N'silv_daily_count_detail';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_inc', @Message = N'silv_daily_count';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_inc', @Message = N'fact_daily_member_count_detail';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-008 attributes changed by a segment-only run reach the daily count on the next daily run]
AS
BEGIN
    DECLARE @run2 uniqueidentifier, @recomputed int, @full_path int, @pm int, @fr uniqueidentifier = NEWID();

    EXEC Layercake.usp_run_daily_load;
    UPDATE Subs.tblSubsInvoices SET Inv_Payment_Method = N'DD' WHERE Rec_ID = 1002;

    EXEC Layercake.usp_run_payment_segments;

    SELECT @pm = payment_method_id FROM Layercake.silv_member_year_attributes WHERE contact_no = N'Y1' AND campaign_year = 2025;
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @pm, @Message = N'Y1 2025 attributes after the segment-only run';

    SELECT d.[date], d.payment_method_id, d.active_count
    INTO #ActualBetween
    FROM Layercake.silv_daily_count_detail AS d
    WHERE d.country_id = 1 AND d.[date] = '2024-10-15';

    SELECT CAST(v.[date] AS date) AS [date], v.payment_method_id, v.active_count
    INTO #ExpectedBetween
    FROM (VALUES ('2024-10-15', 1, 1), ('2024-10-15', 2, 1)) AS v([date], payment_method_id, active_count);

    EXEC tSQLt.AssertEqualsTable '#ExpectedBetween', '#ActualBetween', @Message = N'daily count before the next daily run';

    EXEC Layercake.usp_run_daily_load;

    SELECT TOP (1) @run2 = run_id FROM Layercake.etl_run_log
    WHERE layer = 'run' AND step_name = 'usp_run_daily_load' ORDER BY log_id DESC;

    SELECT @recomputed = p.rows_affected
    FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS r ON r.log_id = p.log_id
    WHERE r.run_id = @run2 AND r.layer = 'silver' AND r.step_name = 'silv_daily_count' AND p.substep = N'contacts_recomputed';
    SELECT @full_path = p.rows_affected
    FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS r ON r.log_id = p.log_id
    WHERE r.run_id = @run2 AND r.layer = 'silver' AND r.step_name = 'silv_daily_count' AND p.substep = N'full_recompute_path';

    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @recomputed, @Message = N'contacts_recomputed';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @full_path, @Message = N'full_recompute_path';

    SELECT d.[date], d.region, d.country_id, d.gender_id, d.grade, d.membership_status_id,
           d.payment_method_id, d.payer_type_id, d.concession_type_id, d.active_count
    INTO #Actual
    FROM Layercake.silv_daily_count_detail AS d
    WHERE d.country_id = 1;

    SELECT CAST(v.[date] AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id, v.active_count
    INTO #Expected
    FROM (VALUES ('2024-09-30', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1),
                 ('2024-10-15', 'UK', 1, 1, 'election', 1, 1, 1, 1, 2),
                 ('2025-03-31', 'UK', 1, 1, 'election', 1, 1, 1, 1, 2))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              payment_method_id, payer_type_id, concession_type_id, active_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', @Message = N'Y1 and Z1 cells after the next daily run';

    SELECT * INTO #det_inc FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_inc FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
           concession_type_id, ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents,
           ReadmissionEvents, LapseEvents
    INTO #fact_inc FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silver @run_id = @fr, @FullRebuild = 1;
    EXEC Layercake.usp_load_gold @run_id = @fr;

    SELECT * INTO #det_full FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
           concession_type_id, ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents,
           ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;

    EXEC tSQLt.AssertEqualsTable '#det_full', '#det_inc', @Message = N'silv_daily_count_detail';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_inc', @Message = N'silv_daily_count';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_inc', @Message = N'fact_daily_member_count_detail';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD029.[test TC-029-009 a failing segment load fails the daily run with 515 and leaves the daily count and daily fact as before]
AS
BEGIN
    DECLARE @run2 uniqueidentifier, @run_status varchar(10), @run_error nvarchar(4000), @corp_status varchar(10),
            @late_steps int;

    EXEC Layercake.usp_run_daily_load;

    SELECT * INTO #det_before FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #fact_before FROM Layercake.fact_daily_member_count_detail;

    UPDATE Subs.tblSubsInvoices SET Inv_Payment_Method = N'DD' WHERE Rec_ID = 1002;
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Contact ID], [Scheme No], [Scheme Name], [Sub Start Date], [Sub End Date], [Sub State],
         [Sub Status], [Sub Campaign Year], [Round], [Sub User State], [Sub User Status], [Sub User Created Date],
         [Invalid Member Grade], [Is Lapsed], [Inactive SU Status], [Quote Expected])
    VALUES (NULL, 'A0000000-0000-0000-0000-000000000200', N'S-200', N'Scheme 200', '2024-10-01', '2025-09-30', N'Active',
            N'Active', 2025, N'Round 1', N'Active', N'Active', '2024-09-01', 'N', 'N', 'N', 'N');

    BEGIN TRY
        EXEC Layercake.usp_run_daily_load;
        EXEC tSQLt.Fail 'usp_run_daily_load should have failed with error 515';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515 THROW;
    END CATCH;

    SELECT TOP (1) @run2 = run_id, @run_status = status, @run_error = error_message
    FROM Layercake.etl_run_log
    WHERE layer = 'run' AND step_name = 'usp_run_daily_load'
    ORDER BY log_id DESC;

    SELECT @corp_status = status FROM Layercake.etl_run_log
    WHERE run_id = @run2 AND layer = 'bronze' AND step_name = 'brnz_corporate_subscription';

    SELECT @late_steps = COUNT(*) FROM Layercake.etl_run_log
    WHERE run_id = @run2
      AND ((layer = 'silver' AND step_name = 'silv_daily_count')
        OR (layer = 'gold' AND step_name = 'fact_daily_member_count_detail'));

    EXEC tSQLt.AssertEquals @Expected = 'Failed', @Actual = @run_status, @Message = N'daily run row status';
    IF @run_error IS NULL EXEC tSQLt.Fail 'the failed daily run row has no error_message';
    EXEC tSQLt.AssertEquals @Expected = 'Failed', @Actual = @corp_status, @Message = N'corporate subscription step status';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @late_steps, @Message = N'daily count and gold daily fact steps of the failed run';

    SELECT * INTO #det_after FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #fact_after FROM Layercake.fact_daily_member_count_detail;

    EXEC tSQLt.AssertEqualsTable '#det_before', '#det_after', @Message = N'silv_daily_count_detail';
    EXEC tSQLt.AssertEqualsTable '#fact_before', '#fact_after', @Message = N'fact_daily_member_count_detail';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD029.[test TC-029-010 after the source row is corrected the next daily run succeeds and matches a full recompute]
AS
BEGIN
    DECLARE @run3 uniqueidentifier, @run_status varchar(10), @not_success int, @fr uniqueidentifier = NEWID();

    EXEC Layercake.usp_run_daily_load;

    UPDATE Subs.tblSubsInvoices SET Inv_Payment_Method = N'DD' WHERE Rec_ID = 1002;
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Contact ID], [Scheme No], [Scheme Name], [Sub Start Date], [Sub End Date], [Sub State],
         [Sub Status], [Sub Campaign Year], [Round], [Sub User State], [Sub User Status], [Sub User Created Date],
         [Invalid Member Grade], [Is Lapsed], [Inactive SU Status], [Quote Expected])
    VALUES (NULL, 'A0000000-0000-0000-0000-000000000200', N'S-200', N'Scheme 200', '2024-10-01', '2025-09-30', N'Active',
            N'Active', 2025, N'Round 1', N'Active', N'Active', '2024-09-01', 'N', 'N', 'N', 'N');

    BEGIN TRY
        EXEC Layercake.usp_run_daily_load;
        EXEC tSQLt.Fail 'usp_run_daily_load should have failed with error 515';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515 THROW;
    END CATCH;

    DELETE FROM Subs.vwCorpSubscriptions WHERE [Contact No] IS NULL;

    EXEC Layercake.usp_run_daily_load;

    SELECT TOP (1) @run3 = run_id, @run_status = status
    FROM Layercake.etl_run_log
    WHERE layer = 'run' AND step_name = 'usp_run_daily_load'
    ORDER BY log_id DESC;

    SELECT @not_success = COUNT(*) FROM Layercake.etl_run_log WHERE run_id = @run3 AND status <> 'Success';

    EXEC tSQLt.AssertEquals @Expected = 'Success', @Actual = @run_status, @Message = N'recovery run status';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @not_success, @Message = N'steps of the recovery run not Success';

    SELECT d.[date], d.region, d.country_id, d.gender_id, d.grade, d.membership_status_id,
           d.payment_method_id, d.payer_type_id, d.concession_type_id, d.active_count
    INTO #Actual
    FROM Layercake.silv_daily_count_detail AS d
    WHERE d.country_id = 1;

    SELECT CAST(v.[date] AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id, v.active_count
    INTO #Expected
    FROM (VALUES ('2024-09-30', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1),
                 ('2024-10-15', 'UK', 1, 1, 'election', 1, 1, 1, 1, 2),
                 ('2025-03-31', 'UK', 1, 1, 'election', 1, 1, 1, 1, 2))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              payment_method_id, payer_type_id, concession_type_id, active_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', @Message = N'Y1 and Z1 cells after recovery';

    SELECT * INTO #det_inc FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_inc FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
           concession_type_id, ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents,
           ReadmissionEvents, LapseEvents
    INTO #fact_inc FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silver @run_id = @fr, @FullRebuild = 1;
    EXEC Layercake.usp_load_gold @run_id = @fr;

    SELECT * INTO #det_full FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily_full FROM Layercake.silv_daily_count;
    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
           concession_type_id, ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents,
           ReadmissionEvents, LapseEvents
    INTO #fact_full FROM Layercake.fact_daily_member_count_detail;

    EXEC tSQLt.AssertEqualsTable '#det_full', '#det_inc', @Message = N'silv_daily_count_detail';
    EXEC tSQLt.AssertEqualsTable '#daily_full', '#daily_inc', @Message = N'silv_daily_count';
    EXEC tSQLt.AssertEqualsTable '#fact_full', '#fact_inc', @Message = N'fact_daily_member_count_detail';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-011 in the change run unchanged fact cells keep id and values and gold logs 0 inserted 2 updated 2 deleted]
AS
BEGIN
    DECLARE @run2 uniqueidentifier;

    EXEC Layercake.usp_run_daily_load;
    SELECT * INTO #fact1 FROM Layercake.fact_daily_member_count_detail;

    UPDATE Subs.tblSubsInvoices SET Inv_Payment_Method = N'DD' WHERE Rec_ID = 1002;
    EXEC Layercake.usp_run_daily_load;

    SELECT TOP (1) @run2 = run_id FROM Layercake.etl_run_log
    WHERE layer = 'run' AND step_name = 'usp_run_daily_load' ORDER BY log_id DESC;

    -- cells of other contacts: every column, id included, unchanged
    SELECT * INTO #ExpectedOther FROM #fact1 WHERE country_id <> 1;
    SELECT * INTO #ActualOther FROM Layercake.fact_daily_member_count_detail WHERE country_id <> 1;
    EXEC tSQLt.AssertEqualsTable '#ExpectedOther', '#ActualOther', @Message = N'fact rows of unchanged cells';

    -- country 1 (Y1 and Z1): the Direct Debit cells keep their ids; the Card cells are gone
    SELECT f.id, f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
           f.payment_method_id, f.payer_type_id, f.concession_type_id, f.ActiveMembers
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f
    WHERE f.country_id = 1;

    SELECT s.id, s.date_id, s.country_id, s.gender_id, s.membership_grade_id, s.membership_status_id,
           s.payment_method_id, s.payer_type_id, s.concession_type_id, v.ActiveMembers
    INTO #Expected
    FROM (VALUES (2, 1, 1), (3, 1, 2), (4, 1, 2)) AS v(date_id, payment_method_id, ActiveMembers)
    INNER JOIN #fact1 AS s
        ON s.date_id = v.date_id AND s.country_id = 1 AND s.gender_id = 1 AND s.membership_grade_id = 2
       AND s.membership_status_id = 1 AND s.payment_method_id = v.payment_method_id
       AND s.payer_type_id = 1 AND s.concession_type_id = 1;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', @Message = N'country 1 fact rows';

    SELECT r.status, r.rows_inserted, r.rows_updated, r.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS r
    WHERE r.run_id = @run2 AND r.layer = 'gold' AND r.step_name = 'fact_daily_member_count_detail';

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 2, 2)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', @Message = N'gold daily fact step row';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-012 a hand-added fact row differing only in payment method is deleted by the next daily run and nothing else changes]
AS
BEGIN
    DECLARE @run2 uniqueidentifier;

    EXEC Layercake.usp_run_daily_load;
    SELECT * INTO #fact1 FROM Layercake.fact_daily_member_count_detail;

    INSERT INTO Layercake.fact_daily_member_count_detail
        (date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id,
         concession_type_id, ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents,
         ReadmissionEvents, LapseEvents)
    VALUES (2, 1, 1, 2, 1, 3, 1, 1, 1, 0, 0, 0, 0, 0, 0);

    EXEC Layercake.usp_run_daily_load;

    SELECT TOP (1) @run2 = run_id FROM Layercake.etl_run_log
    WHERE layer = 'run' AND step_name = 'usp_run_daily_load' ORDER BY log_id DESC;

    SELECT * INTO #fact2 FROM Layercake.fact_daily_member_count_detail;
    EXEC tSQLt.AssertEqualsTable '#fact1', '#fact2', @Message = N'fact after the run (id included)';

    SELECT r.status, r.rows_inserted, r.rows_updated, r.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS r
    WHERE r.run_id = @run2 AND r.layer = 'gold' AND r.step_name = 'fact_daily_member_count_detail';

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 0, 1)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', @Message = N'gold daily fact step row';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-013 a second daily run on unchanged data recomputes 0 contacts and changes no daily row]
AS
BEGIN
    DECLARE @run2 uniqueidentifier, @recomputed int, @full_path int, @adjustments int;

    EXEC Layercake.usp_run_daily_load;
    SELECT * INTO #det1 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily1 FROM Layercake.silv_daily_count;
    SELECT * INTO #fact1 FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_run_daily_load;

    SELECT TOP (1) @run2 = run_id FROM Layercake.etl_run_log
    WHERE layer = 'run' AND step_name = 'usp_run_daily_load' ORDER BY log_id DESC;

    SELECT @recomputed = p.rows_affected
    FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS r ON r.log_id = p.log_id
    WHERE r.run_id = @run2 AND r.layer = 'silver' AND r.step_name = 'silv_daily_count' AND p.substep = N'contacts_recomputed';
    SELECT @full_path = p.rows_affected
    FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS r ON r.log_id = p.log_id
    WHERE r.run_id = @run2 AND r.layer = 'silver' AND r.step_name = 'silv_daily_count' AND p.substep = N'full_recompute_path';
    SELECT @adjustments = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @run2;

    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @recomputed, @Message = N'contacts_recomputed';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @full_path, @Message = N'full_recompute_path';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @adjustments, @Message = N'adjustment rows';

    SELECT * INTO #det2 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily2 FROM Layercake.silv_daily_count;
    SELECT * INTO #fact2 FROM Layercake.fact_daily_member_count_detail;

    EXEC tSQLt.AssertEqualsTable '#det1', '#det2', @Message = N'silv_daily_count_detail';
    EXEC tSQLt.AssertEqualsTable '#daily1', '#daily2', @Message = N'silv_daily_count';
    EXEC tSQLt.AssertEqualsTable '#fact1', '#fact2', @Message = N'fact_daily_member_count_detail';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-014 FullRebuild on the daily run reaches the daily count which takes the full path and changes nothing]
AS
BEGIN
    DECLARE @run2 uniqueidentifier, @full2 int, @adjustments int;

    EXEC Layercake.usp_run_daily_load;
    SELECT * INTO #det1 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily1 FROM Layercake.silv_daily_count;

    EXEC Layercake.usp_run_daily_load @FullRebuild = 1;

    SELECT TOP (1) @run2 = run_id FROM Layercake.etl_run_log
    WHERE layer = 'run' AND step_name = 'usp_run_daily_load' ORDER BY log_id DESC;

    SELECT @full2 = p.rows_affected
    FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS r ON r.log_id = p.log_id
    WHERE r.run_id = @run2 AND r.layer = 'silver' AND r.step_name = 'silv_daily_count' AND p.substep = N'full_recompute_path';
    SELECT @adjustments = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @run2;

    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @full2, @Message = N'full_recompute_path with FullRebuild = 1';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @adjustments, @Message = N'adjustment rows';

    SELECT * INTO #det2 FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #daily2 FROM Layercake.silv_daily_count;
    EXEC tSQLt.AssertEqualsTable '#det1', '#det2', @Message = N'silv_daily_count_detail';
    EXEC tSQLt.AssertEqualsTable '#daily1', '#daily2', @Message = N'silv_daily_count';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-015 usp_load_silver with SkipDailyCount runs the other silver steps but not the daily count]
AS
BEGIN
    DECLARE @r uniqueidentifier = NEWID();

    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @stub_log bigint; EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''daily_count_stub'', @stub_log OUTPUT; EXEC Layercake.usp_etl_log_end @stub_log, ''Success'';';

    EXEC Layercake.usp_load_silver @run_id = @r, @SkipDailyCount = 1;

    SELECT v.step_name, (SELECT COUNT(*) FROM Layercake.etl_run_log AS r
                         WHERE r.run_id = @r AND r.step_name = v.step_name) AS calls
    INTO #Actual
    FROM (VALUES ('phase1_events_stub'), ('phase1_profile_stub'), ('phase1_rate_base_stub'), ('daily_count_stub')) AS v(step_name);

    SELECT v.step_name, v.calls
    INTO #Expected
    FROM (VALUES ('phase1_events_stub', 1), ('phase1_profile_stub', 1), ('phase1_rate_base_stub', 1),
                 ('daily_count_stub', 0)) AS v(step_name, calls);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-016 usp_load_silver with no switch still runs the daily count with the rebuild arguments it is given]
AS
BEGIN
    DECLARE @r uniqueidentifier = NEWID();

    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_silv_daily_count',
        @CommandToExecute = N'DECLARE @stub_log bigint, @args nvarchar(4000) = CONCAT(@FullRebuild, N''|'', CONVERT(nvarchar(10), @RebuildFrom, 23), N''|'', @DailyCountBatchDays); EXEC Layercake.usp_etl_log_start @run_id, ''silver'', ''daily_count_stub'', @stub_log OUTPUT; EXEC Layercake.usp_etl_log_end @stub_log, ''Success'', NULL, NULL, NULL, @args;';

    EXEC Layercake.usp_load_silver @run_id = @r, @FullRebuild = 1, @RebuildFrom = '2024-10-01', @DailyCountBatchDays = 7;

    SELECT r.step_name, r.error_message AS arguments_received
    INTO #Actual
    FROM Layercake.etl_run_log AS r
    WHERE r.run_id = @r AND r.step_name IN ('daily_count_stub', 'phase1_rate_base_stub');

    SELECT v.step_name, v.arguments_received
    INTO #Expected
    FROM (VALUES ('daily_count_stub', N'1|2024-10-01|7'), ('phase1_rate_base_stub', NULL)) AS v(step_name, arguments_received);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-017 usp_load_gold with SkipDailyFact runs the other gold steps but not the gold daily fact]
AS
BEGIN
    DECLARE @r uniqueidentifier = NEWID();

    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @stub_log bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''daily_fact_stub'', @stub_log OUTPUT; EXEC Layercake.usp_etl_log_end @stub_log, ''Success'';';

    EXEC Layercake.usp_load_gold @run_id = @r, @SkipDailyFact = 1;

    SELECT v.step_name, (SELECT COUNT(*) FROM Layercake.etl_run_log AS r
                         WHERE r.run_id = @r AND r.step_name = v.step_name) AS calls
    INTO #Actual
    FROM (VALUES ('phase1_dim_date_stub'), ('phase1_fact_events_stub'), ('phase1_fact_rate_base_stub'), ('daily_fact_stub')) AS v(step_name);

    SELECT v.step_name, v.calls
    INTO #Expected
    FROM (VALUES ('phase1_dim_date_stub', 1), ('phase1_fact_events_stub', 1), ('phase1_fact_rate_base_stub', 1),
                 ('daily_fact_stub', 0)) AS v(step_name, calls);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-018 usp_load_gold with no switch still runs the gold daily fact with its batch size]
AS
BEGIN
    DECLARE @r uniqueidentifier = NEWID();

    EXEC tSQLt.SpyProcedure 'Layercake.usp_load_fact_daily_member_count_detail',
        @CommandToExecute = N'DECLARE @stub_log bigint; EXEC Layercake.usp_etl_log_start @run_id, ''gold'', ''daily_fact_stub'', @stub_log OUTPUT; EXEC Layercake.usp_etl_log_end @stub_log, ''Success'', @DetailBatchDays;';

    EXEC Layercake.usp_load_gold @run_id = @r, @DetailBatchDays = 5;

    SELECT r.step_name, r.rows_inserted AS batch_days_received
    INTO #Actual
    FROM Layercake.etl_run_log AS r
    WHERE r.run_id = @r AND r.step_name = 'daily_fact_stub';

    SELECT v.step_name, v.batch_days_received
    INTO #Expected
    FROM (VALUES ('daily_fact_stub', 5)) AS v(step_name, batch_days_received);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-019 after one daily run the fact holds exactly the silver cells on the star grain with the three segment ids]
AS
BEGIN
    EXEC Layercake.usp_run_daily_load;

    SELECT f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id,
           f.payment_method_id, f.payer_type_id, f.concession_type_id, f.ActiveMembers
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id, v.ActiveMembers
    INTO #Expected
    FROM (VALUES (1, 10, 1, 2, 1, 2, 1, 1, 1),
                 (2, 1, 1, 2, 1, 1, 1, 1, 1),
                 (2, 10, 1, 2, 1, 2, 1, 1, 1),
                 (3, 1, 1, 2, 1, 2, 1, 1, 1),
                 (3, 1, 1, 2, 1, 1, 1, 1, 1),
                 (3, 10, 1, 2, 1, 2, 1, 0, 1),
                 (3, 11, 1, 2, 1, 5, 1, 1, 1),
                 (4, 1, 1, 2, 1, 2, 1, 1, 1),
                 (4, 1, 1, 2, 1, 1, 1, 1, 1),
                 (4, 10, 1, 2, 1, 2, 1, 0, 1),
                 (4, 11, 1, 2, 1, 5, 1, 1, 1))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id,
              payment_method_id, payer_type_id, concession_type_id, ActiveMembers);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', @Message = N'fact cells';

    -- every silver cell (all are election, so Qualified 2) against the fact on all seven measures
    SELECT u.date_id, u.country_id, u.gender_id, u.membership_status_id, u.payment_method_id, u.payer_type_id,
           u.concession_type_id
    INTO #differences
    FROM (SELECT dd.id AS date_id, d.country_id, d.gender_id, d.membership_status_id, d.payment_method_id,
                 d.payer_type_id, d.concession_type_id, d.active_count AS a, d.paid_count AS p, d.paid_count_event AS pe,
                 d.event_join_count AS j, d.event_renewal_count AS rn, d.event_readmission_count AS rd,
                 d.event_lapse_count AS l, 1 AS silver_rows, 0 AS fact_rows
          FROM Layercake.silv_daily_count_detail AS d
          INNER JOIN Layercake.dim_date AS dd ON dd.[date] = d.[date]
          UNION ALL
          SELECT f.date_id, f.country_id, f.gender_id, f.membership_status_id, f.payment_method_id, f.payer_type_id,
                 f.concession_type_id, -f.ActiveMembers, -f.PaidMembers, -f.PaidMembersEvent, -f.JoinEvents,
                 -f.RenewalEvents, -f.ReadmissionEvents, -f.LapseEvents, 0, 1
          FROM Layercake.fact_daily_member_count_detail AS f
          WHERE f.membership_grade_id = 2) AS u
    GROUP BY u.date_id, u.country_id, u.gender_id, u.membership_status_id, u.payment_method_id, u.payer_type_id,
             u.concession_type_id
    HAVING SUM(u.a) <> 0 OR SUM(u.p) <> 0 OR SUM(u.pe) <> 0 OR SUM(u.j) <> 0 OR SUM(u.rn) <> 0
        OR SUM(u.rd) <> 0 OR SUM(u.l) <> 0 OR SUM(u.silver_rows) <> 1 OR SUM(u.fact_rows) <> 1;

    EXEC tSQLt.AssertEmptyTable '#differences';
END;
GO

CREATE PROCEDURE test_MOD029.[test TC-029-020 a fact cell is split by segment so summing over the three ids gives the old grain and the daily totals]
AS
BEGIN
    EXEC Layercake.usp_run_daily_load;

    SELECT f.date_id, f.country_id, COUNT(*) AS fact_rows, SUM(f.ActiveMembers) AS active_members
    INTO #Actual
    FROM Layercake.fact_daily_member_count_detail AS f
    GROUP BY f.date_id, f.country_id;

    SELECT v.date_id, v.country_id, v.fact_rows, v.active_members
    INTO #Expected
    FROM (VALUES (1, 10, 1, 1), (2, 1, 1, 1), (2, 10, 1, 1),
                 (3, 1, 2, 2), (3, 10, 1, 1), (3, 11, 1, 1),
                 (4, 1, 2, 2), (4, 10, 1, 1), (4, 11, 1, 1))
         AS v(date_id, country_id, fact_rows, active_members);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', @Message = N'fact summed over the three segment ids';

    SELECT dc.[date], SUM(dc.active_count) AS active_count
    INTO #ActualDaily
    FROM Layercake.silv_daily_count AS dc
    GROUP BY dc.[date];

    SELECT CAST(v.[date] AS date) AS [date], v.active_count
    INTO #ExpectedDaily
    FROM (VALUES ('2023-01-10', 1), ('2024-09-30', 2), ('2024-10-15', 4), ('2025-03-31', 4)) AS v([date], active_count);

    EXEC tSQLt.AssertEqualsTable '#ExpectedDaily', '#ActualDaily', @Message = N'silv_daily_count active by date';
END;
GO
