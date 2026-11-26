/*====================================================================
    Layercake.usp_load_silv_ref_local_group
    Silver layer - brnz_local_group_detail + silv_ref_country
                   -> Layercake.silv_ref_local_group, silv_ref_country_region
    Insert-and-update by local_group_bk, as silv_ref_country is: new groups
    added, changed values updated, ids never change, unchanged rows
    untouched. The reserved rows 0 Unknown and -2 Not applicable have no
    business key, so the load never matches or changes them.
    is_reportable is the usable test of RULE-171 (ADR-016 Option A, AMD-009):
    live in bronze, statecode 0, a country found in silv_ref_country and both
    region values neither null nor blank. A group gone from bronze keeps its
    row with is_reportable 0.
    dim_country_id (ADR-015): the country's own id where both of the group's
    regions equal the country's own, else the silv_ref_country_region id of
    the combination, which is added first if missing (insert-only).
    Regions are matched as the database collation compares them, so a group
    region differing from its country's only in case or trailing spaces uses
    the country's own row. silv_ref_country is only read.
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_silv_ref_local_group
    @run_id uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @run_id IS NULL SET @run_id = NEWID();

    DECLARE @log_id     bigint,
            @ins        int,
            @upd        int,
            @ins_region int,
            @now        datetime2(3),
            @substep_ts datetime2(3) = SYSDATETIME(),
            @err        nvarchar(4000);

    BEGIN TRY
        EXEC Layercake.usp_etl_log_start @run_id, 'silver', 'silv_ref_local_group', @log_id OUTPUT;

        SET @now = SYSDATETIME();

        -- Every bronze group, live or soft-deleted, with blank regions held as NULL.
        CREATE TABLE #grp
        (
            local_group_bk          uniqueidentifier NOT NULL PRIMARY KEY CLUSTERED,
            local_group_name        nvarchar(100) COLLATE DATABASE_DEFAULT NULL,
            local_group_code        nvarchar(100) COLLATE DATABASE_DEFAULT NULL,
            country_id              int           NULL,
            region_name             nvarchar(100) COLLATE DATABASE_DEFAULT NULL,
            market_reporting_region varchar(15)   COLLATE DATABASE_DEFAULT NULL,
            statecode               int           NULL,
            is_reportable           bit           NOT NULL,
            own_region_name         nvarchar(200) COLLATE DATABASE_DEFAULT NULL,
            own_market_region       varchar(15)   COLLATE DATABASE_DEFAULT NULL,
            dim_country_id          int           NULL
        );

        INSERT INTO #grp
            (local_group_bk, local_group_name, local_group_code, country_id, region_name,
             market_reporting_region, statecode, is_reportable, own_region_name, own_market_region)
        SELECT b.apuk_localgroupid,
               b.apuk_name,
               b.apuk_code,
               c.id,
               r.region_name,
               r.market_reporting_region,
               b.statecode,
               CASE WHEN b._is_deleted = 0
                     AND b.statecode = 0
                     AND c.id IS NOT NULL
                     AND r.region_name IS NOT NULL
                     AND r.market_reporting_region IS NOT NULL
                    THEN 1 ELSE 0 END,
               c.region_name,
               c.market_reporting_region
        FROM Layercake.brnz_local_group_detail AS b
        LEFT JOIN Layercake.silv_ref_country AS c
            ON c.country_id = b.apuk_countryid
        CROSS APPLY (SELECT CASE WHEN LTRIM(RTRIM(b.apuk_worldregionid_name)) = N'' THEN NULL
                                 ELSE b.apuk_worldregionid_name END AS region_name,
                            CASE WHEN LTRIM(RTRIM(b.market_reporting_region)) = '' THEN NULL
                                 ELSE b.market_reporting_region END AS market_reporting_region) AS r;

        BEGIN TRANSACTION;

        -- Combinations a reportable group needs that its country's own row does not give.
        INSERT INTO Layercake.silv_ref_country_region (country_ref_id, region_name, market_reporting_region, load_id, created_at)
        SELECT DISTINCT g.country_id, g.region_name, g.market_reporting_region, @log_id, @now
        FROM #grp AS g
        WHERE g.is_reportable = 1
          AND NOT (g.region_name = g.own_region_name AND g.market_reporting_region = g.own_market_region)
          AND NOT EXISTS (SELECT 1
                          FROM Layercake.silv_ref_country_region AS x
                          WHERE x.country_ref_id = g.country_id
                            AND x.region_name = g.region_name
                            AND x.market_reporting_region = g.market_reporting_region);
        SET @ins_region = @@ROWCOUNT;

        UPDATE g
        SET dim_country_id = CASE WHEN g.region_name = g.own_region_name
                                   AND g.market_reporting_region = g.own_market_region
                                  THEN g.country_id
                                  ELSE x.id END
        FROM #grp AS g
        LEFT JOIN Layercake.silv_ref_country_region AS x
            ON  x.country_ref_id = g.country_id
            AND x.region_name = g.region_name
            AND x.market_reporting_region = g.market_reporting_region
        WHERE g.is_reportable = 1;

        -- Strings compare as bytes: the collation is case-insensitive and '='
        -- ignores trailing spaces, and such a change must still reach the list.
        UPDATE t
        SET local_group_name        = g.local_group_name,
            local_group_code        = g.local_group_code,
            country_id              = g.country_id,
            region_name             = g.region_name,
            market_reporting_region = g.market_reporting_region,
            statecode               = g.statecode,
            is_reportable           = g.is_reportable,
            dim_country_id          = g.dim_country_id,
            load_id                 = @log_id,
            updated_at              = @now
        FROM Layercake.silv_ref_local_group AS t
        INNER JOIN #grp AS g
            ON g.local_group_bk = t.local_group_bk
        WHERE EXISTS (SELECT CAST(g.local_group_name AS varbinary(200)), CAST(g.local_group_code AS varbinary(200)),
                             g.country_id, CAST(g.region_name AS varbinary(200)),
                             CAST(g.market_reporting_region AS varbinary(15)), g.statecode,
                             g.is_reportable, g.dim_country_id
                      EXCEPT
                      SELECT CAST(t.local_group_name AS varbinary(200)), CAST(t.local_group_code AS varbinary(200)),
                             t.country_id, CAST(t.region_name AS varbinary(200)),
                             CAST(t.market_reporting_region AS varbinary(15)), t.statecode,
                             t.is_reportable, t.dim_country_id);
        SET @upd = @@ROWCOUNT;

        -- A group no longer in bronze at all keeps its row and id but gives no member a region.
        UPDATE t
        SET is_reportable  = 0,
            dim_country_id = NULL,
            load_id        = @log_id,
            updated_at     = @now
        FROM Layercake.silv_ref_local_group AS t
        WHERE t.local_group_bk IS NOT NULL
          AND (t.is_reportable = 1 OR t.dim_country_id IS NOT NULL)
          AND NOT EXISTS (SELECT 1 FROM #grp AS g WHERE g.local_group_bk = t.local_group_bk);
        SET @upd = @upd + @@ROWCOUNT;

        INSERT INTO Layercake.silv_ref_local_group
            (local_group_bk, local_group_name, local_group_code, country_id, region_name,
             market_reporting_region, statecode, is_reportable, dim_country_id, load_id, created_at, updated_at)
        SELECT g.local_group_bk, g.local_group_name, g.local_group_code, g.country_id, g.region_name,
               g.market_reporting_region, g.statecode, g.is_reportable, g.dim_country_id, @log_id, @now, @now
        FROM #grp AS g
        WHERE NOT EXISTS (SELECT 1 FROM Layercake.silv_ref_local_group AS t WHERE t.local_group_bk = g.local_group_bk);
        SET @ins = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC Layercake.usp_etl_log_progress @log_id, N'silv_ref_country_region combinations added', @ins_region, @substep_ts OUTPUT;
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
