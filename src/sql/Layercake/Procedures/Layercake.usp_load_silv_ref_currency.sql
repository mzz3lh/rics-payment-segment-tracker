/*====================================================================
    Layercake.usp_load_silv_ref_currency
    Silver layer - Layercake.brnz_subs_invoice -> Layercake.silv_ref_currency
    Adds each inv_currency seen on live bronze invoices that is not yet
    listed (RULE-031). Insert-only, so a listed code keeps its id and
    spelling. Logged.
    Codes match as the database collation compares them (case-insensitive,
    trailing spaces ignored); a NULL, empty or blank code adds nothing
    (answers 2026-10-27).
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_silv_ref_currency
    @run_id uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @run_id IS NULL SET @run_id = NEWID();

    DECLARE @log_id bigint,
            @ins    int,
            @now    datetime2(3),
            @err    nvarchar(4000);

    BEGIN TRY
        EXEC Layercake.usp_etl_log_start @run_id, 'silver', 'silv_ref_currency', @log_id OUTPUT;

        SET @now = SYSDATETIME();

        BEGIN TRANSACTION;

        -- Spellings of one new code that differ only in case are one code: the
        -- lowest byte value (upper case) is kept, so every run stores the same.
        -- inv_currency <> N'' is false for NULL, '' and blanks alike.
        INSERT INTO Layercake.silv_ref_currency (currency_code, load_id, created_at)
        SELECT n.currency_code, @log_id, @now
        FROM (SELECT i.inv_currency AS currency_code,
                     ROW_NUMBER() OVER (PARTITION BY i.inv_currency
                                        ORDER BY CAST(i.inv_currency AS varbinary(6))) AS spelling_rank
              FROM Layercake.brnz_subs_invoice AS i
              WHERE i._is_deleted = 0
                AND i.inv_currency <> N'') AS n
        WHERE n.spelling_rank = 1
          AND NOT EXISTS (SELECT 1
                          FROM Layercake.silv_ref_currency AS c
                          WHERE c.currency_code = n.currency_code);
        SET @ins = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC Layercake.usp_etl_log_end @log_id, 'Success', @ins, 0, 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @err = CONCAT(ERROR_MESSAGE(), ' (error ', ERROR_NUMBER(), ', line ', ERROR_LINE(), ')');
        IF @log_id IS NOT NULL
            EXEC Layercake.usp_etl_log_end @log_id, 'Failed', @ins, 0, 0, @err;
        THROW;
    END CATCH;
END;
