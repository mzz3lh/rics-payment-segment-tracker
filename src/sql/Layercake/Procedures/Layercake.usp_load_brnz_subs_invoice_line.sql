/*====================================================================
    Layercake.usp_load_brnz_subs_invoice_line
    Bronze layer - synapse_fo.CUSTTRANS_RICS (RULE-077 scope)
                   -> Layercake.brnz_subs_invoice_line
    1:1 landing at ledger-distribution grain (RULE-104), keyed on
    (recid, postingtype, accountdisplayvalue) with NULL matching NULL:
    insert new, update changed (and restore reappearing), soft-delete
    rows gone or out of scope; row-count check (RULE-005); logged.
====================================================================*/
CREATE OR ALTER PROCEDURE Layercake.usp_load_brnz_subs_invoice_line
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
        EXEC Layercake.usp_etl_log_start @run_id, 'bronze', 'brnz_subs_invoice_line', @log_id OUTPUT;

        -- Staged in the target's types: a value that does not fit (overflow,
        -- truncation) fails the load here instead of being silently cut.
        -- The unique key compares the row identity as the target's unique
        -- constraint does (database collation, NULL equal to NULL), so two
        -- source rows with one identity fail the load before anything is written.
        CREATE TABLE #src_subs_invoice_line
        (
            recid               bigint        NOT NULL,
            accountnum          nvarchar(20)  COLLATE DATABASE_DEFAULT NULL,
            invoice             nvarchar(20)  COLLATE DATABASE_DEFAULT NULL,
            voucher             nvarchar(20)  COLLATE DATABASE_DEFAULT NULL,
            lastsettlevoucher   nvarchar(20)  COLLATE DATABASE_DEFAULT NULL,
            transdate           datetime2(3)  NULL,
            transtype           int           NULL,
            ricinvoicetype      nvarchar(10)  COLLATE DATABASE_DEFAULT NULL,
            productcode         nvarchar(50)  COLLATE DATABASE_DEFAULT NULL,
            amountcur           numeric(34,6) NULL,
            amountmst           numeric(34,6) NULL,
            settleamountcur     numeric(34,6) NULL,
            currencycode        nvarchar(3)   COLLATE DATABASE_DEFAULT NULL,
            paymmode            nvarchar(20)  COLLATE DATABASE_DEFAULT NULL,
            paymreference       nvarchar(50)  COLLATE DATABASE_DEFAULT NULL,
            ordernum            nvarchar(50)  COLLATE DATABASE_DEFAULT NULL,
            postingtype         int           NULL,
            accountdisplayvalue nvarchar(500) COLLATE DATABASE_DEFAULT NULL,
            mainaccount         nvarchar(20)  COLLATE DATABASE_DEFAULT NULL,
            costcenter          nvarchar(30)  COLLATE DATABASE_DEFAULT NULL,
            ricscampaignyear    nvarchar(10)  COLLATE DATABASE_DEFAULT NULL,
            UNIQUE (recid, postingtype, accountdisplayvalue)
        );

        -- RULE-077: the lines of a Subs.tblSubsInvoices invoice (same account
        -- and voucher, every RICINVOICETYPE), and the rows on the same account
        -- that settle it (LASTSETTLEVOUCHER = the invoice's voucher). EXISTS
        -- lands a row meeting both conditions, or matching several invoices, once.
        INSERT INTO #src_subs_invoice_line
            (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
             amountcur, amountmst, settleamountcur, currencycode, paymmode, paymreference, ordernum,
             postingtype, accountdisplayvalue, mainaccount, costcenter, ricscampaignyear)
        SELECT ct.RECID, ct.ACCOUNTNUM, ct.INVOICE, ct.VOUCHER, ct.LASTSETTLEVOUCHER, ct.TRANSDATE, ct.TRANSTYPE,
               ct.RICINVOICETYPE, ct.productcode, ct.AMOUNTCUR, ct.AMOUNTMST, ct.SETTLEAMOUNTCUR, ct.CURRENCYCODE,
               ct.PAYMMODE, ct.PAYMREFERENCE, ct.ORDERNUM,
               ct.POSTINGTYPE, ct.ACCOUNTDISPLAYVALUE, ct.MainAccount, ct.CostCenter, ct.RICSCAMPAIGNYEAR
        FROM synapse_fo.CUSTTRANS_RICS AS ct
        WHERE EXISTS (SELECT 1
                      FROM Subs.tblSubsInvoices AS si
                      WHERE si.Account_Num = ct.ACCOUNTNUM
                        AND (si.Voucher = ct.VOUCHER OR si.Voucher = ct.LASTSETTLEVOUCHER));

        BEGIN TRANSACTION;

        -- Rows match on the identity under the collation (as the unique
        -- constraint compares it); the other values compare as bytes so a
        -- case-only or trailing-space change in the source is landed (bronze
        -- is byte for byte), including in accountdisplayvalue itself.
        UPDATE tgt
        SET accountnum          = s.accountnum,
            invoice             = s.invoice,
            voucher             = s.voucher,
            lastsettlevoucher   = s.lastsettlevoucher,
            transdate           = s.transdate,
            transtype           = s.transtype,
            ricinvoicetype      = s.ricinvoicetype,
            productcode         = s.productcode,
            amountcur           = s.amountcur,
            amountmst           = s.amountmst,
            settleamountcur     = s.settleamountcur,
            currencycode        = s.currencycode,
            paymmode            = s.paymmode,
            paymreference       = s.paymreference,
            ordernum            = s.ordernum,
            postingtype         = s.postingtype,
            accountdisplayvalue = s.accountdisplayvalue,
            mainaccount         = s.mainaccount,
            costcenter          = s.costcenter,
            ricscampaignyear    = s.ricscampaignyear,
            _is_deleted         = 0,
            _deleted_at         = NULL,
            _updated_at         = SYSDATETIME()
        FROM Layercake.brnz_subs_invoice_line AS tgt
        INNER JOIN #src_subs_invoice_line AS s
            ON  s.recid = tgt.recid
            AND (s.postingtype = tgt.postingtype OR (s.postingtype IS NULL AND tgt.postingtype IS NULL))
            AND (s.accountdisplayvalue = tgt.accountdisplayvalue OR (s.accountdisplayvalue IS NULL AND tgt.accountdisplayvalue IS NULL))
        WHERE tgt._is_deleted = 1
           OR EXISTS (SELECT CAST(s.accountnum AS varbinary(40)), CAST(s.invoice AS varbinary(40)),
                             CAST(s.voucher AS varbinary(40)), CAST(s.lastsettlevoucher AS varbinary(40)), s.transdate,
                             s.transtype, CAST(s.ricinvoicetype AS varbinary(20)), CAST(s.productcode AS varbinary(100)),
                             s.amountcur, s.amountmst, s.settleamountcur, CAST(s.currencycode AS varbinary(6)),
                             CAST(s.paymmode AS varbinary(40)), CAST(s.paymreference AS varbinary(100)),
                             CAST(s.ordernum AS varbinary(100)), CAST(s.accountdisplayvalue AS varbinary(1000)),
                             CAST(s.mainaccount AS varbinary(40)), CAST(s.costcenter AS varbinary(60)),
                             CAST(s.ricscampaignyear AS varbinary(20))
                      EXCEPT
                      SELECT CAST(tgt.accountnum AS varbinary(40)), CAST(tgt.invoice AS varbinary(40)),
                             CAST(tgt.voucher AS varbinary(40)), CAST(tgt.lastsettlevoucher AS varbinary(40)), tgt.transdate,
                             tgt.transtype, CAST(tgt.ricinvoicetype AS varbinary(20)), CAST(tgt.productcode AS varbinary(100)),
                             tgt.amountcur, tgt.amountmst, tgt.settleamountcur, CAST(tgt.currencycode AS varbinary(6)),
                             CAST(tgt.paymmode AS varbinary(40)), CAST(tgt.paymreference AS varbinary(100)),
                             CAST(tgt.ordernum AS varbinary(100)), CAST(tgt.accountdisplayvalue AS varbinary(1000)),
                             CAST(tgt.mainaccount AS varbinary(40)), CAST(tgt.costcenter AS varbinary(60)),
                             CAST(tgt.ricscampaignyear AS varbinary(20)));
        SET @upd = @@ROWCOUNT;

        INSERT INTO Layercake.brnz_subs_invoice_line
            (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
             amountcur, amountmst, settleamountcur, currencycode, paymmode, paymreference, ordernum,
             postingtype, accountdisplayvalue, mainaccount, costcenter, ricscampaignyear)
        SELECT s.recid, s.accountnum, s.invoice, s.voucher, s.lastsettlevoucher, s.transdate, s.transtype,
               s.ricinvoicetype, s.productcode, s.amountcur, s.amountmst, s.settleamountcur, s.currencycode,
               s.paymmode, s.paymreference, s.ordernum,
               s.postingtype, s.accountdisplayvalue, s.mainaccount, s.costcenter, s.ricscampaignyear
        FROM #src_subs_invoice_line AS s
        WHERE NOT EXISTS (SELECT 1
                          FROM Layercake.brnz_subs_invoice_line AS t
                          WHERE t.recid = s.recid
                            AND (t.postingtype = s.postingtype OR (t.postingtype IS NULL AND s.postingtype IS NULL))
                            AND (t.accountdisplayvalue = s.accountdisplayvalue OR (t.accountdisplayvalue IS NULL AND s.accountdisplayvalue IS NULL)));
        SET @ins = @@ROWCOUNT;

        -- Gone from CUSTTRANS_RICS or no longer in the RULE-077 scope; this
        -- includes rows landed at the old recid grain whose identity no source
        -- row has any more.
        UPDATE tgt
        SET _is_deleted = 1,
            _deleted_at = SYSDATETIME(),
            _updated_at = SYSDATETIME()
        FROM Layercake.brnz_subs_invoice_line AS tgt
        WHERE tgt._is_deleted = 0
          AND NOT EXISTS (SELECT 1
                          FROM #src_subs_invoice_line AS s
                          WHERE s.recid = tgt.recid
                            AND (s.postingtype = tgt.postingtype OR (s.postingtype IS NULL AND tgt.postingtype IS NULL))
                            AND (s.accountdisplayvalue = tgt.accountdisplayvalue OR (s.accountdisplayvalue IS NULL AND tgt.accountdisplayvalue IS NULL)));
        SET @del = @@ROWCOUNT;

        SELECT @src_count = COUNT_BIG(*) FROM #src_subs_invoice_line;
        SELECT @tgt_count = COUNT_BIG(*) FROM Layercake.brnz_subs_invoice_line WHERE _is_deleted = 0;
        IF @src_count <> @tgt_count
            RAISERROR('Row count mismatch after sync of Layercake.brnz_subs_invoice_line: source %I64d vs active target %I64d.', 16, 1, @src_count, @tgt_count);

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
