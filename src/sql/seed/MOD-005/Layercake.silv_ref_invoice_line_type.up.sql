-- Curated mapping (RULE-028). Q-034 is open: until the curated list is supplied, the seed holds
-- only the item codes the existing Subs code names, all on RICINVOICETYPE 'SUB' as
-- Subs.usp_Refresh_SubsInvoices reads them: the six readmission fee codes and the six retired
-- concession codes. Every other code is added as 'unmapped' by the load and mapped by hand.
INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type)
VALUES (N'RAFEE_ACAND', N'SUB', 'readmission fee'),
       (N'RAFEE_APCC', N'SUB', 'readmission fee'),
       (N'RAFEE_ASSOC', N'SUB', 'readmission fee'),
       (N'RAFEE_FRICS', N'SUB', 'readmission fee'),
       (N'RAFEE_MRICS', N'SUB', 'readmission fee'),
       (N'RAFEE_PMU2', N'SUB', 'readmission fee'),
       (N'CONPWRQ1', N'SUB', 'concession'),
       (N'CONPWRQ2', N'SUB', 'concession'),
       (N'CONPWRQ3', N'SUB', 'concession'),
       (N'CONRETIRED', N'SUB', 'concession'),
       (N'CONRETIREDFL', N'SUB', 'concession'),
       (N'CONRETIREDSPECIAL', N'SUB', 'concession');
