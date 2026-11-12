-- Rows at ledger-distribution grain can repeat a recid, so they cannot take
-- the MOD-002 recid key: a table holding rows is kept as
-- brnz_subs_invoice_line_rolledback_MIG0019 and recreated empty at its MOD-002
-- shape (ADR-006, DES-001 deployment). An empty table is altered back.
IF EXISTS (SELECT 1 FROM Layercake.brnz_subs_invoice_line)
BEGIN
    IF OBJECT_ID(N'Layercake.brnz_subs_invoice_line_rolledback_MIG0019', N'U') IS NOT NULL
        THROW 50012, 'Layercake.brnz_subs_invoice_line_rolledback_MIG0019 already exists: move or drop it before rolling back MIG-0019.', 1;
    EXEC sp_rename N'Layercake.DF_Layercake_brnz_subs_invoice_line__loaded_at', N'DF_Layercake_brnz_subs_invoice_line__loaded_at_rolledback_MIG0019', N'OBJECT';
    EXEC sp_rename N'Layercake.DF_Layercake_brnz_subs_invoice_line__updated_at', N'DF_Layercake_brnz_subs_invoice_line__updated_at_rolledback_MIG0019', N'OBJECT';
    EXEC sp_rename N'Layercake.DF_Layercake_brnz_subs_invoice_line__is_deleted', N'DF_Layercake_brnz_subs_invoice_line__is_deleted_rolledback_MIG0019', N'OBJECT';
    EXEC sp_rename N'Layercake.UQ_Layercake_brnz_subs_invoice_line_recid_postingtype_accountdisplayvalue', N'UQ_Layercake_brnz_subs_invoice_line_recid_postingtype_accountdisplayvalue_rolledback_MIG0019', N'OBJECT';
    EXEC sp_rename N'Layercake.PK_Layercake_brnz_subs_invoice_line', N'PK_Layercake_brnz_subs_invoice_line_rolledback_MIG0019', N'OBJECT';
    EXEC sp_rename N'Layercake.brnz_subs_invoice_line', N'brnz_subs_invoice_line_rolledback_MIG0019';
    CREATE TABLE Layercake.brnz_subs_invoice_line
    (
        recid             bigint        NOT NULL,
        accountnum        nvarchar(20)  NULL,
        invoice           nvarchar(20)  NULL,
        voucher           nvarchar(20)  NULL,
        lastsettlevoucher nvarchar(20)  NULL,
        transdate         datetime2(3)  NULL,
        transtype         int           NULL,
        ricinvoicetype    nvarchar(10)  NULL,
        productcode       nvarchar(50)  NULL,
        amountcur         numeric(34,6) NULL,
        amountmst         numeric(34,6) NULL,
        settleamountcur   numeric(34,6) NULL,
        currencycode      nvarchar(3)   NULL,
        paymmode          nvarchar(20)  NULL,
        paymreference     nvarchar(50)  NULL,
        ordernum          nvarchar(50)  NULL,
        _loaded_at        datetime2(3)  NOT NULL CONSTRAINT DF_Layercake_brnz_subs_invoice_line__loaded_at DEFAULT SYSDATETIME(),
        _updated_at       datetime2(3)  NOT NULL CONSTRAINT DF_Layercake_brnz_subs_invoice_line__updated_at DEFAULT SYSDATETIME(),
        _is_deleted       bit           NOT NULL CONSTRAINT DF_Layercake_brnz_subs_invoice_line__is_deleted DEFAULT 0,
        _deleted_at       datetime2(3)  NULL,
        CONSTRAINT PK_Layercake_brnz_subs_invoice_line PRIMARY KEY CLUSTERED (recid)
    );
END
ELSE
BEGIN
    ALTER TABLE Layercake.brnz_subs_invoice_line DROP CONSTRAINT UQ_Layercake_brnz_subs_invoice_line_recid_postingtype_accountdisplayvalue;
    ALTER TABLE Layercake.brnz_subs_invoice_line DROP CONSTRAINT PK_Layercake_brnz_subs_invoice_line;
    ALTER TABLE Layercake.brnz_subs_invoice_line DROP COLUMN line_id, ricscampaignyear, costcenter, mainaccount, accountdisplayvalue, postingtype;
    ALTER TABLE Layercake.brnz_subs_invoice_line ADD CONSTRAINT PK_Layercake_brnz_subs_invoice_line PRIMARY KEY CLUSTERED (recid);
END;
