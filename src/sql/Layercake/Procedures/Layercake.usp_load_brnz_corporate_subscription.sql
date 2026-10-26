/*====================================================================
    Layercake.usp_load_brnz_corporate_subscription
    Bronze layer - Subs.vwCorpSubscriptions -> Layercake.brnz_corporate_subscription
    1:1 landing. The source has no row key, so rows are matched on
    (contact_no, scheme_no, sub_campaign_year) (Q-033): insert new, update
    changed (and restore reappearing), soft-delete gone; row-count check
    (RULE-005); logged. 'Round' is not landed and plays no part
    (answers 2026-10-23).
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_brnz_corporate_subscription
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
        EXEC Layercake.usp_etl_log_start @run_id, 'bronze', 'brnz_corporate_subscription', @log_id OUTPUT;

        -- Staged in the target's types with the matching key NOT NULL and unique:
        -- a NULL key fails the load with 515 (answers 2026-10-26, no row is skipped)
        -- and a duplicate key fails it with 2627 (Q-033), before bronze is touched.
        CREATE TABLE #src_corporate_subscription
        (
            contact_no        nvarchar(100)  COLLATE DATABASE_DEFAULT NOT NULL,
            scheme_no         nvarchar(100)  COLLATE DATABASE_DEFAULT NOT NULL,
            scheme_name       nvarchar(4000) COLLATE DATABASE_DEFAULT NULL,
            sub_campaign_year int            NOT NULL,
            sub_status        nvarchar(350)  COLLATE DATABASE_DEFAULT NULL,
            sub_user_status   nvarchar(350)  COLLATE DATABASE_DEFAULT NULL,
            PRIMARY KEY CLUSTERED (contact_no, scheme_no, sub_campaign_year)
        );

        INSERT INTO #src_corporate_subscription
            (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status)
        SELECT cs.[Contact No], cs.[Scheme No], cs.[Scheme Name], cs.[Sub Campaign Year],
               cs.[Sub Status], cs.[Sub User Status]
        FROM Subs.vwCorpSubscriptions AS cs;

        BEGIN TRANSACTION;

        -- Strings compare as bytes so a case-only or trailing-space change in the
        -- source is landed (bronze is byte for byte); the key columns too, since
        -- the key match itself follows the case-insensitive collation.
        UPDATE tgt
        SET contact_no      = s.contact_no,
            scheme_no       = s.scheme_no,
            scheme_name     = s.scheme_name,
            sub_status      = s.sub_status,
            sub_user_status = s.sub_user_status,
            _is_deleted     = 0,
            _deleted_at     = NULL,
            _updated_at     = SYSDATETIME()
        FROM Layercake.brnz_corporate_subscription AS tgt
        INNER JOIN #src_corporate_subscription AS s
            ON  s.contact_no = tgt.contact_no
            AND s.scheme_no = tgt.scheme_no
            AND s.sub_campaign_year = tgt.sub_campaign_year
        WHERE tgt._is_deleted = 1
           OR EXISTS (SELECT CAST(s.contact_no AS varbinary(200)), CAST(s.scheme_no AS varbinary(200)),
                             CAST(s.scheme_name AS varbinary(8000)), CAST(s.sub_status AS varbinary(700)),
                             CAST(s.sub_user_status AS varbinary(700))
                      EXCEPT
                      SELECT CAST(tgt.contact_no AS varbinary(200)), CAST(tgt.scheme_no AS varbinary(200)),
                             CAST(tgt.scheme_name AS varbinary(8000)), CAST(tgt.sub_status AS varbinary(700)),
                             CAST(tgt.sub_user_status AS varbinary(700)));
        SET @upd = @@ROWCOUNT;

        INSERT INTO Layercake.brnz_corporate_subscription
            (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status)
        SELECT s.contact_no, s.scheme_no, s.scheme_name, s.sub_campaign_year, s.sub_status, s.sub_user_status
        FROM #src_corporate_subscription AS s
        WHERE NOT EXISTS (SELECT 1
                          FROM Layercake.brnz_corporate_subscription AS t
                          WHERE t.contact_no = s.contact_no
                            AND t.scheme_no = s.scheme_no
                            AND t.sub_campaign_year = s.sub_campaign_year);
        SET @ins = @@ROWCOUNT;

        UPDATE tgt
        SET _is_deleted = 1,
            _deleted_at = SYSDATETIME(),
            _updated_at = SYSDATETIME()
        FROM Layercake.brnz_corporate_subscription AS tgt
        WHERE tgt._is_deleted = 0
          AND NOT EXISTS (SELECT 1
                          FROM #src_corporate_subscription AS s
                          WHERE s.contact_no = tgt.contact_no
                            AND s.scheme_no = tgt.scheme_no
                            AND s.sub_campaign_year = tgt.sub_campaign_year);
        SET @del = @@ROWCOUNT;

        SELECT @src_count = COUNT_BIG(*) FROM #src_corporate_subscription;
        SELECT @tgt_count = COUNT_BIG(*) FROM Layercake.brnz_corporate_subscription WHERE _is_deleted = 0;
        IF @src_count <> @tgt_count
            RAISERROR('Row count mismatch after sync of Layercake.brnz_corporate_subscription: source %I64d vs active target %I64d.', 16, 1, @src_count, @tgt_count);

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
