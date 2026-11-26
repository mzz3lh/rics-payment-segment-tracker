/*====================================================================
    Layercake.usp_load_brnz_local_group_detail
    Bronze layer - CE.vwLocalGroup -> Layercake.brnz_local_group_detail
    1:1 landing at local group grain, keyed on apuk_localgroupid (RULE-169,
    ADR-014): insert new, update changed (and restore reappearing),
    soft-delete gone; row-count check (RULE-005); logged. Values are not
    transformed. The country-grain brnz_local_group is not touched.
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_brnz_local_group_detail
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
        EXEC Layercake.usp_etl_log_start @run_id, 'bronze', 'brnz_local_group_detail', @log_id OUTPUT;

        -- Staged in the target's types with the key NOT NULL and unique: a NULL
        -- key fails the load with 515 and a duplicate key with 2627, before
        -- bronze is touched; no row is skipped (DES-001, as brnz_concession).
        CREATE TABLE #src_local_group
        (
            apuk_localgroupid       uniqueidentifier NOT NULL PRIMARY KEY CLUSTERED,
            apuk_name               nvarchar(100) COLLATE DATABASE_DEFAULT NULL,
            apuk_code               nvarchar(100) COLLATE DATABASE_DEFAULT NULL,
            apuk_countryid          uniqueidentifier NULL,
            apuk_worldregionid_name nvarchar(100) COLLATE DATABASE_DEFAULT NULL,
            market_reporting_region varchar(15)   COLLATE DATABASE_DEFAULT NULL,
            statecode               int           NULL
        );

        INSERT INTO #src_local_group
            (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name,
             market_reporting_region, statecode)
        SELECT lg.apuk_localgroupid, lg.apuk_name, lg.apuk_code, lg.apuk_countryid,
               lg.apuk_worldregionid_name, lg.Market_reporting_region, lg.statecode
        FROM CE.vwLocalGroup AS lg;

        BEGIN TRANSACTION;

        -- Strings compare as bytes so a case-only or trailing-space change in the
        -- source is landed (bronze is byte for byte); EXCEPT treats NULLs as equal.
        UPDATE tgt
        SET apuk_name               = s.apuk_name,
            apuk_code               = s.apuk_code,
            apuk_countryid          = s.apuk_countryid,
            apuk_worldregionid_name = s.apuk_worldregionid_name,
            market_reporting_region = s.market_reporting_region,
            statecode               = s.statecode,
            _is_deleted             = 0,
            _deleted_at             = NULL,
            _updated_at             = SYSDATETIME()
        FROM Layercake.brnz_local_group_detail AS tgt
        INNER JOIN #src_local_group AS s
            ON s.apuk_localgroupid = tgt.apuk_localgroupid
        WHERE tgt._is_deleted = 1
           OR EXISTS (SELECT CAST(s.apuk_name AS varbinary(200)), CAST(s.apuk_code AS varbinary(200)),
                             s.apuk_countryid, CAST(s.apuk_worldregionid_name AS varbinary(200)),
                             CAST(s.market_reporting_region AS varbinary(15)), s.statecode
                      EXCEPT
                      SELECT CAST(tgt.apuk_name AS varbinary(200)), CAST(tgt.apuk_code AS varbinary(200)),
                             tgt.apuk_countryid, CAST(tgt.apuk_worldregionid_name AS varbinary(200)),
                             CAST(tgt.market_reporting_region AS varbinary(15)), tgt.statecode);
        SET @upd = @@ROWCOUNT;

        INSERT INTO Layercake.brnz_local_group_detail
            (apuk_localgroupid, apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name,
             market_reporting_region, statecode)
        SELECT s.apuk_localgroupid, s.apuk_name, s.apuk_code, s.apuk_countryid, s.apuk_worldregionid_name,
               s.market_reporting_region, s.statecode
        FROM #src_local_group AS s
        WHERE NOT EXISTS (SELECT 1
                          FROM Layercake.brnz_local_group_detail AS t
                          WHERE t.apuk_localgroupid = s.apuk_localgroupid);
        SET @ins = @@ROWCOUNT;

        UPDATE tgt
        SET _is_deleted = 1,
            _deleted_at = SYSDATETIME(),
            _updated_at = SYSDATETIME()
        FROM Layercake.brnz_local_group_detail AS tgt
        WHERE tgt._is_deleted = 0
          AND NOT EXISTS (SELECT 1
                          FROM #src_local_group AS s
                          WHERE s.apuk_localgroupid = tgt.apuk_localgroupid);
        SET @del = @@ROWCOUNT;

        SELECT @src_count = COUNT_BIG(*) FROM #src_local_group;
        SELECT @tgt_count = COUNT_BIG(*) FROM Layercake.brnz_local_group_detail WHERE _is_deleted = 0;
        IF @src_count <> @tgt_count
            RAISERROR('Row count mismatch after sync of Layercake.brnz_local_group_detail: source %I64d vs active target %I64d.', 16, 1, @src_count, @tgt_count);

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
