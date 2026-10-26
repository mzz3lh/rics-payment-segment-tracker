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
