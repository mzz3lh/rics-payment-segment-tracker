/*====================================================================
    Layercake.usp_load_dim_concession_type
    Gold layer - Layercake.silv_ref_concession_type -> Layercake.dim_concession_type
    Mirrors the reference list by id, as usp_load_dim_payer_type does:
    inserts missing ids, updates names and flags that changed, leaves
    unchanged rows untouched. Logged. Never deletes: facts may still point
    at an id that left the list.
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_dim_concession_type
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
        EXEC Layercake.usp_etl_log_start @run_id, 'gold', 'dim_concession_type', @log_id OUTPUT;

        SET @now = SYSDATETIME();

        BEGIN TRANSACTION;

        -- Names compare as bytes: the collation is case-insensitive and '='
        -- ignores trailing spaces, and such a change must still reach the dimension.
        UPDATE d
        SET concession_type_name = s.concession_type_name,
            is_full_concession   = s.is_full_concession,
            is_perpetual         = s.is_perpetual,
            load_id              = @log_id,
            updated_at           = @now
        FROM Layercake.dim_concession_type AS d
        INNER JOIN Layercake.silv_ref_concession_type AS s
            ON s.id = d.id
        WHERE EXISTS (SELECT CAST(s.concession_type_name AS varbinary(200)), s.is_full_concession, s.is_perpetual
                      EXCEPT
                      SELECT CAST(d.concession_type_name AS varbinary(200)), d.is_full_concession, d.is_perpetual);
        SET @upd = @@ROWCOUNT;

        INSERT INTO Layercake.dim_concession_type
            (id, concession_type_name, is_full_concession, is_perpetual, load_id, created_at, updated_at)
        SELECT s.id, s.concession_type_name, s.is_full_concession, s.is_perpetual, @log_id, @now, @now
        FROM Layercake.silv_ref_concession_type AS s
        WHERE NOT EXISTS (SELECT 1 FROM Layercake.dim_concession_type AS d WHERE d.id = s.id);
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
