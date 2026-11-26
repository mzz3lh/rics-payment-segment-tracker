/*====================================================================
    Layercake.usp_load_dim_local_group
    Gold layer - Layercake.silv_ref_local_group -> Layercake.dim_local_group
    Mirrors the list by id, both reserved rows included, as the other gold
    dimensions do: inserts missing ids, updates changed names, leaves
    unchanged rows untouched. Logged. Never deletes: list ids never leave
    silver, and facts may point at any of them.
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_dim_local_group
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
        EXEC Layercake.usp_etl_log_start @run_id, 'gold', 'dim_local_group', @log_id OUTPUT;

        SET @now = SYSDATETIME();

        BEGIN TRANSACTION;

        -- Names compare as bytes: the collation is case-insensitive and '='
        -- ignores trailing spaces, and such a change must still reach the dimension.
        UPDATE d
        SET local_group_name = s.local_group_name,
            load_id          = @log_id,
            updated_at       = @now
        FROM Layercake.dim_local_group AS d
        INNER JOIN Layercake.silv_ref_local_group AS s
            ON s.id = d.id
        WHERE EXISTS (SELECT CAST(s.local_group_name AS varbinary(200))
                      EXCEPT
                      SELECT CAST(d.local_group_name AS varbinary(200)));
        SET @upd = @@ROWCOUNT;

        INSERT INTO Layercake.dim_local_group (id, local_group_name, load_id, created_at, updated_at)
        SELECT s.id, s.local_group_name, @log_id, @now, @now
        FROM Layercake.silv_ref_local_group AS s
        WHERE NOT EXISTS (SELECT 1 FROM Layercake.dim_local_group AS d WHERE d.id = s.id);
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
