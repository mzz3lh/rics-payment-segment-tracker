/*====================================================================
    Layercake.usp_load_silv_ref_invoice_line_type
    Silver layer - Layercake.brnz_subs_invoice_line -> Layercake.silv_ref_invoice_line_type
    Adds each (productcode, ricinvoicetype) seen on live bronze lines that
    is not yet listed, with line type 'unmapped' (RULE-029). Insert-only:
    an existing row, mapped by hand or still 'unmapped', is never changed.
    Logged.
    Codes match as the database collation compares them (case-insensitive,
    trailing spaces ignored); a NULL ricinvoicetype is the empty type N''
    and a NULL, empty or blank productcode adds nothing (answers 2026-10-27).
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_silv_ref_invoice_line_type
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
        EXEC Layercake.usp_etl_log_start @run_id, 'silver', 'silv_ref_invoice_line_type', @log_id OUTPUT;

        SET @now = SYSDATETIME();

        BEGIN TRANSACTION;

        -- Spellings of one new pair that differ only in case or trailing spaces
        -- are one pair: the lowest byte value is kept (upper case, then the
        -- shortest), so every run stores the same spelling.
        -- productcode <> N'' is false for NULL, '' and blanks alike, as '='
        -- ignores trailing spaces.
        INSERT INTO Layercake.silv_ref_invoice_line_type
            (item_code, ric_invoice_type, line_type, load_id, created_at, updated_at)
        SELECT n.item_code, n.ric_invoice_type, 'unmapped', @log_id, @now, @now
        FROM (SELECT l.productcode AS item_code,
                     ISNULL(l.ricinvoicetype, N'') AS ric_invoice_type,
                     ROW_NUMBER() OVER (PARTITION BY l.productcode, ISNULL(l.ricinvoicetype, N'')
                                        ORDER BY CAST(l.productcode AS varbinary(100)),
                                                 CAST(ISNULL(l.ricinvoicetype, N'') AS varbinary(20))) AS spelling_rank
              FROM Layercake.brnz_subs_invoice_line AS l
              WHERE l._is_deleted = 0
                AND l.productcode <> N'') AS n
        WHERE n.spelling_rank = 1
          AND NOT EXISTS (SELECT 1
                          FROM Layercake.silv_ref_invoice_line_type AS t
                          WHERE t.item_code = n.item_code
                            AND t.ric_invoice_type = n.ric_invoice_type);
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
