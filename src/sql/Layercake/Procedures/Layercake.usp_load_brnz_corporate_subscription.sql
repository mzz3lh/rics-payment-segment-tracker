/*====================================================================
    Layercake.usp_load_brnz_corporate_subscription
    Bronze layer - Subs.vwCorpSubscriptions -> Layercake.brnz_corporate_subscription
    The source has no row key and is at subscription-user grain, so
    (contact_no, scheme_no, sub_campaign_year) can repeat (Q-033, AMD-004).
    One copy per key is landed (RULE-128, ADR-009); the others are counted in
    the etl_progress_log sub-step 'repeated_key_rows_not_landed' (ADR-010).
    A row with no Sub Campaign Year is not landed and takes no part in the
    choice or the repeat count; it is counted in the sub-step
    'no_campaign_year_rows_not_landed' (AMD-005, RULE-134, RULE-135).
    Rows are matched on that key: insert new, update changed (and restore
    reappearing), soft-delete gone; distinct-key row-count check (RULE-005,
    RULE-130); logged. 'Round' is not landed and plays a part only in the
    choice of copy (answers 2026-10-23, Q-054).
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_brnz_corporate_subscription
    @run_id uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @run_id IS NULL SET @run_id = NEWID();

    -- Q-027: the active value of Sub Status and Sub User Status. Compared as the
    -- readers compare it (database collation), so the copy they look for is kept.
    DECLARE @active_status nvarchar(350) = N'Active';

    DECLARE @log_id         bigint,
            @ins            int,
            @upd            int,
            @del            int,
            @not_landed     int,
            @no_year        int,
            @src_count      bigint,
            @tgt_count      bigint,
            @ts             datetime2(3),
            @err            nvarchar(4000);

    BEGIN TRY
        EXEC Layercake.usp_etl_log_start @run_id, 'bronze', 'brnz_corporate_subscription', @log_id OUTPUT;

        -- Every source row, staged with Contact No and Scheme No NOT NULL: a NULL
        -- in either fails the load with 515 before bronze is touched, whether or
        -- not the row has a Campaign Year (answers 2026-10-26, RULE-137). A NULL
        -- Sub Campaign Year is allowed here and set aside below (AMD-005).
        CREATE TABLE #src_all_rows
        (
            contact_no            nvarchar(100)  COLLATE DATABASE_DEFAULT NOT NULL,
            scheme_no             nvarchar(100)  COLLATE DATABASE_DEFAULT NOT NULL,
            scheme_name           nvarchar(4000) COLLATE DATABASE_DEFAULT NULL,
            sub_campaign_year     int            NULL,
            sub_status            nvarchar(350)  COLLATE DATABASE_DEFAULT NULL,
            sub_user_status       nvarchar(350)  COLLATE DATABASE_DEFAULT NULL,
            sub_user_created_date date           NULL,
            round_number          decimal(38, 0) NULL
        );

        -- Round counts by the whole number at its end (Q-053, Q-054): outer spaces
        -- ignored, the part after the last space (or the whole value), only if it
        -- is all digits; anything else is NULL and ranks lowest.
        INSERT INTO #src_all_rows
            (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status,
             sub_user_created_date, round_number)
        SELECT cs.[Contact No], cs.[Scheme No], cs.[Scheme Name], cs.[Sub Campaign Year],
               cs.[Sub Status], cs.[Sub User Status], cs.[Sub User Created Date],
               CASE
                   WHEN rt.round_tail <> N'' AND rt.round_tail COLLATE Latin1_General_BIN2 NOT LIKE N'%[^0-9]%'
                       THEN TRY_CAST(rt.round_tail AS decimal(38, 0))
               END
        FROM Subs.vwCorpSubscriptions AS cs
        CROSS APPLY (SELECT LTRIM(RTRIM(cs.[Round])) AS round_trimmed) AS r
        CROSS APPLY (SELECT CASE
                                WHEN CHARINDEX(N' ', r.round_trimmed) > 0
                                    THEN RIGHT(r.round_trimmed, CHARINDEX(N' ', REVERSE(r.round_trimmed)) - 1)
                                ELSE r.round_trimmed
                            END AS round_tail) AS rt;

        -- One copy per key, in RULE-128's order: Active/Active, latest created
        -- date (NULL loses), highest Round; then ADR-009's final tie-break on the
        -- landed values in exact order (binary, then length so trailing spaces
        -- count), missing first. The key columns come last because the key itself
        -- matches case-insensitively, so copies still tied land identical values.
        -- Rows with no Campaign Year are left out: the year is never guessed
        -- (RULE-134), so a key whose rows all lose it is soft-deleted below.
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
        SELECT ranked.contact_no, ranked.scheme_no, ranked.scheme_name, ranked.sub_campaign_year,
               ranked.sub_status, ranked.sub_user_status
        FROM (SELECT a.contact_no, a.scheme_no, a.scheme_name, a.sub_campaign_year, a.sub_status, a.sub_user_status,
                     ROW_NUMBER() OVER (
                         PARTITION BY a.contact_no, a.scheme_no, a.sub_campaign_year
                         ORDER BY CASE WHEN a.sub_status = @active_status AND a.sub_user_status = @active_status
                                       THEN 0 ELSE 1 END,
                                  a.sub_user_created_date DESC,
                                  a.round_number DESC,
                                  a.sub_user_status COLLATE Latin1_General_BIN2, DATALENGTH(a.sub_user_status),
                                  a.sub_status COLLATE Latin1_General_BIN2, DATALENGTH(a.sub_status),
                                  a.scheme_name COLLATE Latin1_General_BIN2, DATALENGTH(a.scheme_name),
                                  a.contact_no COLLATE Latin1_General_BIN2, DATALENGTH(a.contact_no),
                                  a.scheme_no COLLATE Latin1_General_BIN2, DATALENGTH(a.scheme_no)) AS copy_rank
              FROM #src_all_rows AS a
              WHERE a.sub_campaign_year IS NOT NULL) AS ranked
        WHERE ranked.copy_rank = 1;

        SELECT @src_count = COUNT_BIG(*) FROM #src_corporate_subscription;
        SELECT @no_year = COUNT(*) FROM #src_all_rows WHERE sub_campaign_year IS NULL;
        SET @not_landed = (SELECT COUNT(*) FROM #src_all_rows WHERE sub_campaign_year IS NOT NULL) - @src_count;
        EXEC Layercake.usp_etl_log_progress @log_id, N'repeated_key_rows_not_landed', @not_landed, @ts OUTPUT;
        EXEC Layercake.usp_etl_log_progress @log_id, N'no_campaign_year_rows_not_landed', @no_year, @ts OUTPUT;

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

        -- RULE-130: distinct keys of the rows with a Campaign Year against live bronze rows.
        SELECT @tgt_count = COUNT_BIG(*) FROM Layercake.brnz_corporate_subscription WHERE _is_deleted = 0;
        IF @src_count <> @tgt_count
            RAISERROR('Row count mismatch after sync of Layercake.brnz_corporate_subscription: distinct source keys %I64d vs active target %I64d.', 16, 1, @src_count, @tgt_count);

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
