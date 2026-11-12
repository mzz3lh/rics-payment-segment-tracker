EXEC tSQLt.NewTestClass 'test_MOD016_dev';
GO

CREATE PROCEDURE test_MOD016_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.tblSubsInvoices';
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';

    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status', @Defaults = 1;

    EXEC tSQLt.FakeTable 'Layercake.silv_ref_invoice_line_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_currency', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_event_amount', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';

    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_currency', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_membership_events', @Defaults = 1;

    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code)
    VALUES (0, 'Unknown', NULL), (-1, 'Unrecognised', NULL), (-2, 'Not applicable', NULL), (1, 'Direct Debit', 'DD');

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name)
    VALUES (0, 'Unknown'), (-1, 'Unrecognised'), (-2, 'Not applicable'), (1, 'Individual'), (2, 'Corporate');

    SET IDENTITY_INSERT Layercake.silv_ref_concession_type ON;
    INSERT INTO Layercake.silv_ref_concession_type
        (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL, '20250101', '20250101'),
           (1, NULL, N'No concession', NULL, 0, 0, NULL, '20250101', '20250101');
    SET IDENTITY_INSERT Layercake.silv_ref_concession_type OFF;

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2025, '20241001', '20250930', '20250601');

    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency,
         Exchange_Rate, Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR,
         Inv_Credit_Amount_GBP, Fully_Credited, Payment_Status, Has_Concession, [100%_Concession])
    VALUES (1002, N'C1', 2025, N'INV-1002', N'V1002', '20241001', N'DD', N'GBP', 1, 475, 475, 475, 0, 0, 'N', N'Fully Paid', 'N', 'N');

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id,
         assessment_route_id, rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year,
         campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (102, N'RN:C1:2025', 'Renewal', 'Standard', '20241015', NULL, N'C1', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1',
            0, 0, 0, 0, 0, 0, NULL, NULL, NULL);

    INSERT INTO Layercake.fact_membership_events
        (event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id,
         rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id,
         concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (102, 'Renewal', 'Standard', '20241015', 20241015, N'C1', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1',
            0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
END;
GO

CREATE PROCEDURE test_MOD016_dev.[test a run without a run id logs all 18 steps under one generated run id and its own row has no counts]
AS
BEGIN
    EXEC Layercake.usp_run_payment_segments @as_of_date = '20250615';

    DECLARE @rows int = (SELECT COUNT(*) FROM Layercake.etl_run_log);
    DECLARE @run_ids int = (SELECT COUNT(DISTINCT l.run_id) FROM Layercake.etl_run_log AS l WHERE l.run_id IS NOT NULL);
    DECLARE @null_run_ids int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l WHERE l.run_id IS NULL);

    EXEC tSQLt.AssertEquals 18, @rows;
    EXEC tSQLt.AssertEquals 1, @run_ids;
    EXEC tSQLt.AssertEquals 0, @null_run_ids;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted, l.error_message
    INTO #ActualRun
    FROM Layercake.etl_run_log AS l
    WHERE l.layer = 'run';

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted, v.error_message
    INTO #ExpectedRun
    FROM (VALUES (CAST('Success' AS varchar(10)), CAST(NULL AS int), CAST(NULL AS int), CAST(NULL AS int),
                  CAST(NULL AS nvarchar(4000))))
         AS v (status, rows_inserted, rows_updated, rows_deleted, error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedRun', '#ActualRun';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD016_dev.[test a failing attributes load keeps the earlier loads committed and a rerun recovers]
AS
BEGIN
    DECLARE @run1 uniqueidentifier = NEWID(),
            @run2 uniqueidentifier = NEWID(),
            @error_number int;

    -- No Campaign Year covers 2030-01-01, so usp_load_silv_member_year_attributes fails with 50001.
    BEGIN TRY
        EXEC Layercake.usp_run_payment_segments @run_id = @run1, @as_of_date = '20300101';
        EXEC tSQLt.Fail 'usp_run_payment_segments completed although usp_load_silv_member_year_attributes failed.';
    END TRY
    BEGIN CATCH
        SET @error_number = ERROR_NUMBER();
        IF @error_number <> 50001
            THROW;
    END CATCH;

    EXEC tSQLt.AssertEquals 50001, @error_number;

    -- Steps 1 to 3 succeeded and stay committed; the attributes step and the run failed; nothing later ran.
    DECLARE @succeeded int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l
                              WHERE l.run_id = @run1 AND l.status = 'Success');
    EXEC tSQLt.AssertEquals 11, @succeeded;

    SELECT l.layer, l.step_name, l.status
    INTO #ActualNotSuccess
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @run1
      AND l.status <> 'Success';

    SELECT v.layer, v.step_name, v.status
    INTO #ExpectedNotSuccess
    FROM (VALUES (CAST('silver' AS varchar(12)), CAST('silv_member_year_attributes' AS varchar(128)), CAST('Failed' AS varchar(10))),
                 ('run', 'usp_run_payment_segments', 'Failed'))
         AS v (layer, step_name, status);
    EXEC tSQLt.AssertEqualsTable '#ExpectedNotSuccess', '#ActualNotSuccess';

    DECLARE @run_message nvarchar(4000) =
        (SELECT l.error_message FROM Layercake.etl_run_log AS l WHERE l.run_id = @run1 AND l.layer = 'run');
    DECLARE @message_ok int =
        CASE WHEN @run_message LIKE N'No Campaign Year in Layercake.ref_campaign_year_config covers the as-of date 2030-01-01.%(error 50001, line %)'
             THEN 1 ELSE 0 END;
    EXEC tSQLt.AssertEquals 1, @message_ok;

    DECLARE @bronze_invoices int = (SELECT COUNT(*) FROM Layercake.brnz_subs_invoice);
    DECLARE @dim_methods int = (SELECT COUNT(*) FROM Layercake.dim_payment_method);
    EXEC tSQLt.AssertEquals 1, @bronze_invoices;
    EXEC tSQLt.AssertEquals 4, @dim_methods;
    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_member_year_attributes';
    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_event_amount';

    -- Recovery is to run again: the finished loads change nothing and the rest complete.
    EXEC Layercake.usp_run_payment_segments @run_id = @run2, @as_of_date = '20250615';

    SELECT l.step_name, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualRerun
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @run2
      AND l.step_name IN ('brnz_subs_invoice', 'dim_payment_method', 'silv_member_year_attributes', 'silv_membership_events_segments');

    SELECT v.step_name, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedRerun
    FROM (VALUES (CAST('brnz_subs_invoice' AS varchar(128)), 0, 0, 0),
                 ('dim_payment_method', 0, 0, 0),
                 ('silv_member_year_attributes', 1, 0, 0),
                 ('silv_membership_events_segments', 0, 1, 0))
         AS v (step_name, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedRerun', '#ActualRerun';

    DECLARE @run2_status varchar(10) =
        (SELECT l.status FROM Layercake.etl_run_log AS l WHERE l.run_id = @run2 AND l.layer = 'run');
    EXEC tSQLt.AssertEqualsString 'Success', @run2_status;
END;
GO
