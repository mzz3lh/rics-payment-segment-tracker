/*====================================================================
    Layercake.usp_load_brnz_concession
    Bronze layer - CE.vwConcessionType -> Layercake.brnz_concession
    1:1 landing keyed on apuk_concessiontypeid (Q-008): insert new, update
    changed (and restore reappearing), soft-delete gone; row-count check
    (RULE-005); logged. apuk_dualmembership is not landed (Q-025).
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_brnz_concession
    @run_id uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @run_id IS NULL SET @run_id = NEWID();

    DECLARE @log_id    bigint,
            @ins       int,
            @upd       int,
            @del       int,
            @src_count bigint,
            @tgt_count bigint,
            @err       nvarchar(4000);

    BEGIN TRY
        EXEC Layercake.usp_etl_log_start @run_id, 'bronze', 'brnz_concession', @log_id OUTPUT;

        -- Staged in the target's types with the key NOT NULL and unique: a NULL
        -- key fails the load with 515 and a duplicate key with 2627, before
        -- bronze is touched; no row is skipped (answers 2026-10-27).
        CREATE TABLE #src_concession
        (
            apuk_concessiontypeid      uniqueidentifier NOT NULL PRIMARY KEY CLUSTERED,
            apuk_name                  nvarchar(100)  COLLATE DATABASE_DEFAULT NULL,
            apuk_discount              decimal(38, 2) NULL,
            product_number             nvarchar(4000) COLLATE DATABASE_DEFAULT NULL,
            statecode                  int            NULL,
            apuk_perpetualnonperpetual int            NULL
        );

        INSERT INTO #src_concession
            (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual)
        SELECT ct.apuk_concessiontypeid, ct.apuk_name, ct.apuk_discount, ct.Product_Number,
               ct.statecode, ct.apuk_perpetualnonperpetual
        FROM CE.vwConcessionType AS ct;

        BEGIN TRANSACTION;

        -- Strings compare as bytes so a case-only or trailing-space change in the
        -- source is landed (bronze is byte for byte); EXCEPT treats NULLs as equal.
        UPDATE tgt
        SET apuk_name                  = s.apuk_name,
            apuk_discount              = s.apuk_discount,
            product_number             = s.product_number,
            statecode                  = s.statecode,
            apuk_perpetualnonperpetual = s.apuk_perpetualnonperpetual,
            _is_deleted                = 0,
            _deleted_at                = NULL,
            _updated_at                = SYSDATETIME()
        FROM Layercake.brnz_concession AS tgt
        INNER JOIN #src_concession AS s
            ON s.apuk_concessiontypeid = tgt.apuk_concessiontypeid
        WHERE tgt._is_deleted = 1
           OR EXISTS (SELECT CAST(s.apuk_name AS varbinary(200)), s.apuk_discount,
                             CAST(s.product_number AS varbinary(8000)), s.statecode,
                             s.apuk_perpetualnonperpetual
                      EXCEPT
                      SELECT CAST(tgt.apuk_name AS varbinary(200)), tgt.apuk_discount,
                             CAST(tgt.product_number AS varbinary(8000)), tgt.statecode,
                             tgt.apuk_perpetualnonperpetual);
        SET @upd = @@ROWCOUNT;

        INSERT INTO Layercake.brnz_concession
            (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual)
        SELECT s.apuk_concessiontypeid, s.apuk_name, s.apuk_discount, s.product_number,
               s.statecode, s.apuk_perpetualnonperpetual
        FROM #src_concession AS s
        WHERE NOT EXISTS (SELECT 1
                          FROM Layercake.brnz_concession AS t
                          WHERE t.apuk_concessiontypeid = s.apuk_concessiontypeid);
        SET @ins = @@ROWCOUNT;

        UPDATE tgt
        SET _is_deleted = 1,
            _deleted_at = SYSDATETIME(),
            _updated_at = SYSDATETIME()
        FROM Layercake.brnz_concession AS tgt
        WHERE tgt._is_deleted = 0
          AND NOT EXISTS (SELECT 1
                          FROM #src_concession AS s
                          WHERE s.apuk_concessiontypeid = tgt.apuk_concessiontypeid);
        SET @del = @@ROWCOUNT;

        SELECT @src_count = COUNT_BIG(*) FROM #src_concession;
        SELECT @tgt_count = COUNT_BIG(*) FROM Layercake.brnz_concession WHERE _is_deleted = 0;
        IF @src_count <> @tgt_count
            RAISERROR('Row count mismatch after sync of Layercake.brnz_concession: source %I64d vs active target %I64d.', 16, 1, @src_count, @tgt_count);

        COMMIT TRANSACTION;
        EXEC Layercake.usp_etl_log_end @log_id, 'Success', @ins, @upd, @del;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @err = CONCAT(ERROR_MESSAGE(), ' (error ', ERROR_NUMBER(), ', line ', ERROR_LINE(), ')');
        IF @log_id IS NOT NULL
            EXEC Layercake.usp_etl_log_end @log_id, 'Failed', @ins, @upd, @del, @err;
        THROW;
    END CATCH;
END;
