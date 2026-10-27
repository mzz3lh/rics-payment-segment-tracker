/*====================================================================
    Layercake.usp_load_dim_currency
    Gold layer - Layercake.silv_ref_currency -> Layercake.dim_currency
    Mirrors the currency list by id, as usp_load_dim_payer_type does:
    inserts missing ids, updates codes that changed, leaves unchanged rows
    untouched. Logged. Never deletes: facts may still point at an id that
    left the list.
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_dim_currency
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
        EXEC Layercake.usp_etl_log_start @run_id, 'gold', 'dim_currency', @log_id OUTPUT;

        SET @now = SYSDATETIME();

        BEGIN TRANSACTION;

        -- Codes compare as bytes: the collation is case-insensitive, and a
        -- case-only change in silver must still reach the dimension.
        UPDATE d
        SET currency_code = s.currency_code,
            load_id       = @log_id,
            updated_at    = @now
        FROM Layercake.dim_currency AS d
        INNER JOIN Layercake.silv_ref_currency AS s
            ON s.id = d.id
        WHERE CAST(s.currency_code AS varbinary(6)) <> CAST(d.currency_code AS varbinary(6));
        SET @upd = @@ROWCOUNT;

        INSERT INTO Layercake.dim_currency (id, currency_code, load_id, created_at, updated_at)
        SELECT s.id, s.currency_code, @log_id, @now, @now
        FROM Layercake.silv_ref_currency AS s
        WHERE NOT EXISTS (SELECT 1 FROM Layercake.dim_currency AS d WHERE d.id = s.id);
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
