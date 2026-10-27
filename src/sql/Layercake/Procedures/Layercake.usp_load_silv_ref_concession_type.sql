/*====================================================================
    Layercake.usp_load_silv_ref_concession_type
    Silver layer - Layercake.brnz_concession -> Layercake.silv_ref_concession_type
    Insert-and-update from live bronze types (RULE-046): adds new types,
    updates name, item code and flags where they changed, and never changes
    an id. The seeded rows (no business key) and types no longer live in
    bronze are left as they are. Logged.
      item_code          product_number without its 'rcs' prefix (RULE-048)
      is_full_concession 1 where apuk_discount = 100 (RULE-047)
      is_perpetual       1 where apuk_perpetualnonperpetual = 200000000 (RULE-094)
    A type with a NULL, empty or blank name is kept as 'Unnamed concession
    type' (answers 2026-10-27).
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_silv_ref_concession_type
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
        EXEC Layercake.usp_etl_log_start @run_id, 'silver', 'silv_ref_concession_type', @log_id OUTPUT;

        SET @now = SYSDATETIME();

        -- NULLIF(name, N'') is NULL for NULL, '' and blanks alike, as '=' ignores
        -- trailing spaces. An item code longer than the designed nvarchar(100)
        -- fails the load (truncation error) rather than being cut.
        CREATE TABLE #bronze_type
        (
            concession_type_bk   uniqueidentifier NOT NULL PRIMARY KEY CLUSTERED,
            concession_type_name nvarchar(100) COLLATE DATABASE_DEFAULT NOT NULL,
            item_code            nvarchar(100) COLLATE DATABASE_DEFAULT NULL,
            is_full_concession   bit           NOT NULL,
            is_perpetual         bit           NOT NULL
        );

        INSERT INTO #bronze_type
            (concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual)
        SELECT b.apuk_concessiontypeid,
               COALESCE(NULLIF(b.apuk_name, N''), N'Unnamed concession type'),
               CASE WHEN b.product_number LIKE N'rcs%' THEN STUFF(b.product_number, 1, 3, N'')
                    ELSE b.product_number
               END,
               CASE WHEN b.apuk_discount = 100 THEN 1 ELSE 0 END,
               CASE WHEN b.apuk_perpetualnonperpetual = 200000000 THEN 1 ELSE 0 END
        FROM Layercake.brnz_concession AS b
        WHERE b._is_deleted = 0;

        BEGIN TRANSACTION;

        -- Strings compare as bytes: the collation is case-insensitive and '='
        -- ignores trailing spaces, and such a change must still reach the list.
        UPDATE t
        SET concession_type_name = s.concession_type_name,
            item_code            = s.item_code,
            is_full_concession   = s.is_full_concession,
            is_perpetual         = s.is_perpetual,
            load_id              = @log_id,
            updated_at           = @now
        FROM Layercake.silv_ref_concession_type AS t
        INNER JOIN #bronze_type AS s
            ON s.concession_type_bk = t.concession_type_bk
        WHERE EXISTS (SELECT CAST(s.concession_type_name AS varbinary(200)), CAST(s.item_code AS varbinary(200)),
                             s.is_full_concession, s.is_perpetual
                      EXCEPT
                      SELECT CAST(t.concession_type_name AS varbinary(200)), CAST(t.item_code AS varbinary(200)),
                             t.is_full_concession, t.is_perpetual);
        SET @upd = @@ROWCOUNT;

        INSERT INTO Layercake.silv_ref_concession_type
            (concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
        SELECT s.concession_type_bk, s.concession_type_name, s.item_code, s.is_full_concession, s.is_perpetual,
               @log_id, @now, @now
        FROM #bronze_type AS s
        WHERE NOT EXISTS (SELECT 1
                          FROM Layercake.silv_ref_concession_type AS t
                          WHERE t.concession_type_bk = s.concession_type_bk);
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
