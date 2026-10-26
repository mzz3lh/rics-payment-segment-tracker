/*====================================================================
    Layercake.usp_load_dim_payer_type
    Gold layer - Layercake.silv_ref_payer_type -> Layercake.dim_payer_type
    Mirrors the reference list by id, as usp_load_dim_payment_method does:
    inserts missing ids, updates names that changed, leaves unchanged rows
    untouched. Logged. Never deletes: facts may still point at an id that
    left the list.
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_dim_payer_type
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
        EXEC Layercake.usp_etl_log_start @run_id, 'gold', 'dim_payer_type', @log_id OUTPUT;

        SET @now = SYSDATETIME();

        BEGIN TRANSACTION;

        -- Names compare as bytes: the collation is case-insensitive and '='
        -- ignores trailing spaces, and such a change must still reach the dimension.
        UPDATE d
        SET payer_type_name = s.payer_type_name,
            load_id         = @log_id,
            updated_at      = @now
        FROM Layercake.dim_payer_type AS d
        INNER JOIN Layercake.silv_ref_payer_type AS s
            ON s.id = d.id
        WHERE EXISTS (SELECT CAST(s.payer_type_name AS varbinary(30))
                      EXCEPT
                      SELECT CAST(d.payer_type_name AS varbinary(30)));
        SET @upd = @@ROWCOUNT;

        INSERT INTO Layercake.dim_payer_type (id, payer_type_name, load_id, created_at, updated_at)
        SELECT s.id, s.payer_type_name, @log_id, @now, @now
        FROM Layercake.silv_ref_payer_type AS s
        WHERE NOT EXISTS (SELECT 1 FROM Layercake.dim_payer_type AS d WHERE d.id = s.id);
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
