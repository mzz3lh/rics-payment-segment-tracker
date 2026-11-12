/*====================================================================
    Layercake.usp_run_payment_segments
    Orchestration - runs the payment segment loads in dependency order
    after the Phase 1 run (ADR-001), under one run_id.

    * Each load manages its own transaction and step logging, so the
      run opens no transaction: loads that finished before a failure
      stay committed, and the failed load has already logged 'Failed'.
    * The first failure stops the run: its own row is logged 'Failed'
      and the original error is re-raised to the scheduler.
    * Every load applies only differences, so recovery is simply to
      run this procedure again.
    * @as_of_date goes only to the member-year attributes load, which
      treats NULL as today; tests pass a fixed date.

    A human schedules it after the Phase 1 run, e.g.:
        EXEC Layercake.usp_run_payment_segments;
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_run_payment_segments
    @run_id     uniqueidentifier = NULL,
    @as_of_date date = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @run_id IS NULL SET @run_id = NEWID();

    DECLARE @log_id bigint,
            @err    nvarchar(4000);

    EXEC Layercake.usp_etl_log_start @run_id, 'run', 'usp_run_payment_segments', @log_id OUTPUT;

    BEGIN TRY
        -- 1. Bronze.
        EXEC Layercake.usp_load_brnz_subs_invoice @run_id = @run_id;
        EXEC Layercake.usp_load_brnz_subs_invoice_line @run_id = @run_id;
        EXEC Layercake.usp_load_brnz_corporate_subscription @run_id = @run_id;
        EXEC Layercake.usp_load_brnz_concession @run_id = @run_id;

        -- 2. Silver lists built from bronze.
        EXEC Layercake.usp_load_silv_ref_invoice_line_type @run_id = @run_id;
        EXEC Layercake.usp_load_silv_ref_currency @run_id = @run_id;
        EXEC Layercake.usp_load_silv_ref_concession_type @run_id = @run_id;

        -- 3. Gold dimensions over the silver lists.
        EXEC Layercake.usp_load_dim_payment_method @run_id = @run_id;
        EXEC Layercake.usp_load_dim_payer_type @run_id = @run_id;
        EXEC Layercake.usp_load_dim_currency @run_id = @run_id;
        EXEC Layercake.usp_load_dim_concession_type @run_id = @run_id;

        -- 4. Member-year attributes, 5. event amounts.
        EXEC Layercake.usp_load_silv_member_year_attributes @run_id = @run_id, @as_of_date = @as_of_date;
        EXEC Layercake.usp_load_silv_event_amount @run_id = @run_id;

        -- 6. Anomalies: segment (reads attributes), then invoice (reads event amounts).
        EXEC Layercake.usp_load_silv_data_anomaly_segment @run_id = @run_id;
        EXEC Layercake.usp_load_silv_data_anomaly_invoice @run_id = @run_id;

        -- 7. Silver event columns, 8. gold fact columns copied from silver.
        EXEC Layercake.usp_load_silv_membership_events_segments @run_id = @run_id;
        EXEC Layercake.usp_load_fact_membership_events_segments @run_id = @run_id;

        EXEC Layercake.usp_etl_log_end @log_id, 'Success';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @err = CONCAT(ERROR_MESSAGE(), ' (error ', ERROR_NUMBER(), ', line ', ERROR_LINE(), ')');
        EXEC Layercake.usp_etl_log_end @log_id, 'Failed', NULL, NULL, NULL, @err;
        THROW;
    END CATCH;
END;
