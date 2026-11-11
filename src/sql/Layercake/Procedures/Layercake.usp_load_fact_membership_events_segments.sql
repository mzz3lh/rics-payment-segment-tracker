/*====================================================================
    Layercake.usp_load_fact_membership_events_segments
    Gold layer - silv_membership_events -> the RPST columns of
    Layercake.fact_membership_events (ADR-001)
    Copies the nine new columns from silver by event_id, updating only
    rows that differ; Phase 1 fact columns are never written. Then the
    extended silver-to-gold check (RULE-019, AC-008-11): equal counts by
    payment_method_id, equal counts by amount_status and equal sums of
    subs_amount_gbp and invoiced_subtotal_gbp. The check runs inside the
    transaction, so a failed check leaves the fact unchanged. Logged.
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_fact_membership_events_segments
    @run_id uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @run_id IS NULL SET @run_id = NEWID();

    DECLARE @log_id     bigint,
            @upd        int,
            @mismatches int,
            @msg        nvarchar(2048),
            @err        nvarchar(4000);

    BEGIN TRY
        EXEC Layercake.usp_etl_log_start @run_id, 'gold', 'fact_membership_events_segments', @log_id OUTPUT;

        BEGIN TRANSACTION;

        -- amount_status compares as bytes, so a case-only change still lands.
        UPDATE f
        SET payment_method_id       = s.payment_method_id,
            payment_method_carried  = s.payment_method_carried,
            payer_type_id           = s.payer_type_id,
            payer_type_carried      = s.payer_type_carried,
            concession_type_id      = s.concession_type_id,
            concession_type_carried = s.concession_type_carried,
            subs_amount_gbp         = s.subs_amount_gbp,
            invoiced_subtotal_gbp   = s.invoiced_subtotal_gbp,
            amount_status           = s.amount_status
        FROM Layercake.fact_membership_events AS f
        INNER JOIN Layercake.silv_membership_events AS s
            ON s.event_id = f.event_id
        WHERE EXISTS (SELECT s.payment_method_id, s.payment_method_carried, s.payer_type_id, s.payer_type_carried,
                             s.concession_type_id, s.concession_type_carried, s.subs_amount_gbp,
                             s.invoiced_subtotal_gbp, CAST(s.amount_status AS varbinary(30))
                      EXCEPT
                      SELECT f.payment_method_id, f.payment_method_carried, f.payer_type_id, f.payer_type_carried,
                             f.concession_type_id, f.concession_type_carried, f.subs_amount_gbp,
                             f.invoiced_subtotal_gbp, CAST(f.amount_status AS varbinary(30)));
        SET @upd = @@ROWCOUNT;

        -- Silver-to-gold check: one row per measure and value on each side; any row on
        -- only one side is a mismatch. Counts by payment_method_id also cover the row count.
        WITH silver_measures AS
        (
            SELECT CAST('payment_method_id' AS varchar(30)) AS measure,
                   CAST(e.payment_method_id AS varchar(30)) AS item,
                   CAST(COUNT(*) AS decimal(38,4)) AS measure_value
            FROM Layercake.silv_membership_events AS e
            GROUP BY e.payment_method_id
            UNION ALL
            SELECT 'amount_status', e.amount_status, COUNT(*)
            FROM Layercake.silv_membership_events AS e
            GROUP BY e.amount_status
            UNION ALL
            SELECT 'subs_amount_gbp', '', ISNULL(SUM(e.subs_amount_gbp), 0)
            FROM Layercake.silv_membership_events AS e
            UNION ALL
            SELECT 'invoiced_subtotal_gbp', '', ISNULL(SUM(e.invoiced_subtotal_gbp), 0)
            FROM Layercake.silv_membership_events AS e
        ),
        gold_measures AS
        (
            SELECT CAST('payment_method_id' AS varchar(30)) AS measure,
                   CAST(f.payment_method_id AS varchar(30)) AS item,
                   CAST(COUNT(*) AS decimal(38,4)) AS measure_value
            FROM Layercake.fact_membership_events AS f
            GROUP BY f.payment_method_id
            UNION ALL
            SELECT 'amount_status', f.amount_status, COUNT(*)
            FROM Layercake.fact_membership_events AS f
            GROUP BY f.amount_status
            UNION ALL
            SELECT 'subs_amount_gbp', '', ISNULL(SUM(f.subs_amount_gbp), 0)
            FROM Layercake.fact_membership_events AS f
            UNION ALL
            SELECT 'invoiced_subtotal_gbp', '', ISNULL(SUM(f.invoiced_subtotal_gbp), 0)
            FROM Layercake.fact_membership_events AS f
        ),
        differences AS
        (
            SELECT sm.measure, sm.item, sm.measure_value FROM silver_measures AS sm
            EXCEPT
            SELECT gm.measure, gm.item, gm.measure_value FROM gold_measures AS gm
            UNION ALL
            SELECT gd.measure, gd.item, gd.measure_value
            FROM (SELECT gm.measure, gm.item, gm.measure_value FROM gold_measures AS gm
                  EXCEPT
                  SELECT sm.measure, sm.item, sm.measure_value FROM silver_measures AS sm) AS gd
        )
        SELECT @mismatches = COUNT(*) FROM differences;

        IF @mismatches > 0
        BEGIN
            SET @msg = CONCAT(N'Silver-to-gold check failed for fact_membership_events: ', @mismatches,
                              N' measure value(s) differ (counts by payment_method_id, counts by amount_status, amount sums).');
            THROW 50001, @msg, 1;
        END;

        COMMIT TRANSACTION;
        EXEC Layercake.usp_etl_log_end @log_id, 'Success', 0, @upd, 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @err = CONCAT(ERROR_MESSAGE(), ' (error ', ERROR_NUMBER(), ', line ', ERROR_LINE(), ')');
        IF @log_id IS NOT NULL
            EXEC Layercake.usp_etl_log_end @log_id, 'Failed', 0, @upd, 0, @err;
        THROW;
    END CATCH;
END;
