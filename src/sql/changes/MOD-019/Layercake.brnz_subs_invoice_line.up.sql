-- RULE-104 / ADR-006: land CUSTTRANS_RICS at ledger-distribution grain.
-- Rows already landed get a line_id and NULL ledger columns; the next load
-- soft-deletes them and lands the source rows at the new grain.
ALTER TABLE Layercake.brnz_subs_invoice_line ADD
    postingtype         int           NULL,
    accountdisplayvalue nvarchar(500) NULL,
    mainaccount         nvarchar(20)  NULL,
    costcenter          nvarchar(30)  NULL,
    ricscampaignyear    nvarchar(10)  NULL,
    line_id             bigint        IDENTITY(1,1) NOT NULL;
ALTER TABLE Layercake.brnz_subs_invoice_line DROP CONSTRAINT PK_Layercake_brnz_subs_invoice_line;
ALTER TABLE Layercake.brnz_subs_invoice_line ADD CONSTRAINT PK_Layercake_brnz_subs_invoice_line PRIMARY KEY CLUSTERED (line_id);
ALTER TABLE Layercake.brnz_subs_invoice_line ADD CONSTRAINT UQ_Layercake_brnz_subs_invoice_line_recid_postingtype_accountdisplayvalue
    UNIQUE NONCLUSTERED (recid, postingtype, accountdisplayvalue);
