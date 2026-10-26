/*====================================================================
    Layercake.usp_load_dim_payment_method
    Gold layer - Layercake.silv_ref_payment_method -> Layercake.dim_payment_method
    Mirrors the reference list by id: inserts missing ids, updates names
    that changed, leaves unchanged rows untouched (RULE-010). Logged.
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_dim_payment_method
    @run_id uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @run_id IS NULL SET @run_id = NEWID();

    DECLARE @log_id bigint,
            @ins    int,
            @upd    int,
            @now    datetime2(3),
            @err    nvarchar(4000);

    BEGIN TRY
        EXEC Layercake.usp_etl_log_start @run_id, 'gold', 'dim_payment_method', @log_id OUTPUT;

        SET @now = SYSUTCDATETIME();

        BEGIN TRANSACTION;

        -- Names compare as bytes: the collation is case-insensitive, and a
        -- case-only change must still reach the dimension.
        UPDATE d
        SET payment_method_name = s.payment_method_name,
            load_id             = CAST(@log_id AS int),
            updated_at          = @now
        FROM Layercake.dim_payment_method AS d
        INNER JOIN Layercake.silv_ref_payment_method AS s
            ON s.id = d.id
        WHERE EXISTS (SELECT CAST(s.payment_method_name AS varbinary(30))
                      EXCEPT
                      SELECT CAST(d.payment_method_name AS varbinary(30)));
        SET @upd = @@ROWCOUNT;

        INSERT INTO Layercake.dim_payment_method (id, payment_method_name, load_id, created_at, updated_at)
        SELECT s.id, s.payment_method_name, CAST(@log_id AS int), @now, @now
        FROM Layercake.silv_ref_payment_method AS s
        WHERE NOT EXISTS (SELECT 1 FROM Layercake.dim_payment_method AS d WHERE d.id = s.id);
        SET @ins = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC Layercake.usp_etl_log_end @log_id, 'Success', @ins, @upd, 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @err = CONCAT(ERROR_MESSAGE(), ' (error ', ERROR_NUMBER(), ', line ', ERROR_LINE(), ')');
        IF @log_id IS NOT NULL
            EXEC Layercake.usp_etl_log_end @log_id, 'Failed', @ins, @upd, 0, @err;
        THROW;
    END CATCH;
END;
