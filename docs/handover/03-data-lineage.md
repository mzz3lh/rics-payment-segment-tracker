# Data lineage: RICS Payment Segment Tracker

## Sources

The solution reads objects that other systems own and maintain. It never creates, changes or writes to them; any change one would need goes to its owner. So far it reads three of them:

| Source | What it holds | Read by |
|---|---|---|
| Subs.tblSubsInvoices | Subscription invoices, one row per invoice, from Campaign Year 2022 onward, with payment method, currency, amounts, credits, payment status and concession flags | Layercake.usp_load_brnz_subs_invoice (landed in brnz_subs_invoice); Layercake.usp_load_brnz_subs_invoice_line (to decide which transaction rows are in scope) |
| synapse_fo.CUSTTRANS_RICS | Customer transaction rows, including invoice rows with item codes (productcode) and posting types, credits and payments | Layercake.usp_load_brnz_subs_invoice_line (landed in brnz_subs_invoice_line); Layercake.usp_profile_custtrans_grain |
| Subs.vwCorpSubscriptions | Corporate subscriptions, with each subscription's 'Sub Status' and each subscription user's 'Sub User Status' | Layercake.usp_profile_corp_subscription_status |

The two profiles read their sources directly and keep nothing. The two bronze loads copy their sources into the bronze tables without changing any value.

The payment method list (MOD-003) is not read from any source: it is a fixed list put in place by its migration, and the payment method dimension is copied from it.

<!-- evidence: PROJECT_STANDARDS.md#Objects owned by other systems (external); docs/sources/external_catalogue.json#Subs.tblSubsInvoices; docs/sources/external_catalogue.json#synapse_fo.CUSTTRANS_RICS; docs/sources/external_catalogue.json#Subs.vwCorpSubscriptions; docs/specs/SPEC-001.json#Invoice source coverage; docs/sources/external/synapse_fo/synapse_fo.CUSTTRANS_RICS.sql#PostingType_Description; docs/design/MP-001.json#count-only procedures over the external sources; docs/dev/CN-MOD-001.json#Neither writes anything; docs/specs/SPEC-001.json#REQ-002; docs/specs/SPEC-001.json#RULE-004; docs/dev/CN-MOD-002.json#Line scope (RULE-077) reads Subs.tblSubsInvoices directly; docs/design/DES-001.json#Static list seeded by its migration; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method -->

## Source-to-target mappings

Every bronze mapping is one-to-one (RULE-004): the target column holds the source value unchanged, with no defaults, trimming or change of case. Both bronze tables also carry the four audit columns _loaded_at, _updated_at, _is_deleted and _deleted_at, which the load sets (see the Architecture and data model document). The profiles have no target table; their tables show which source columns they use and how they become the counts they return. The payment method mappings show how a source payment mode code becomes a payment method, and how the list reaches the gold dimension.

<!-- evidence: docs/specs/SPEC-001.json#RULE-004; docs/specs/SPEC-001.json#_loaded_at, _updated_at, _is_deleted, _deleted_at (and the same on brnz_subs_invoice_line); docs/test/TCS-MOD-002.json#TC-002-003; docs/design/MP-001.json#Builds no tables and changes no existing object; docs/specs/SPEC-001.json#RULE-095; docs/specs/SPEC-001.json#RULE-096; docs/specs/SPEC-001.json#RULE-007; docs/specs/SPEC-001.json#RULE-010 -->

### Subscription invoices (Subs.tblSubsInvoices to Layercake.brnz_subs_invoice)

All rows of the source are landed, one row each, identified by rec_id.

| Source column | Target column | Note |
|---|---|---|
| Rec_ID | rec_id | Source row key |
| Account_Num | account_num | The RICS contact number |
| Campaign_Year | campaign_year | |
| Invoice | invoice | |
| Voucher | voucher | Used to find the invoice's lines and settling rows |
| Trans_Date | trans_date | |
| Inv_Payment_Method | inv_payment_method | Payment mode on the invoice; a missing value stays missing. Later mapped to a payment method by fn_map_payment_method |
| Inv_Currency | inv_currency | |
| Exchange_Rate | exchange_rate | |
| Full_Invoice_Amount_CUR | full_invoice_amount_cur | Later used to tell a credit note from a zero-value invoice numbered 'CRE' (RULE-014) |
| Invoice_Amount_CUR | invoice_amount_cur | |
| Invoice_Amount_GBP | invoice_amount_gbp | |
| Inv_Credit_Amount_CUR | inv_credit_amount_cur | |
| Inv_Credit_Amount_GBP | inv_credit_amount_gbp | |
| Fully_Credited | fully_credited | Includes the source's 'N/A' for invoices with no credit |
| Payment_Status | payment_status | |
| Has_Concession | has_concession | |
| 100%_Concession | full_concession_flag | |

<!-- evidence: docs/specs/SPEC-001.json#Subs.tblSubsInvoices.Rec_ID; docs/specs/SPEC-001.json#1:1. Equals the RICS contact number.; docs/specs/SPEC-001.json#1:1 (F&O PAYMMODE on the invoice); docs/answers.md#brnz_subs_invoice.inv_payment_method; docs/specs/SPEC-001.json#Used to tell a credit note from a zero-value invoice numbered 'CRE' (RULE-014); docs/specs/SPEC-001.json#Subs.tblSubsInvoices.100%_Concession; docs/design/DES-001.json#Source column 100%_Concession; docs/answers.md#the source writes 'N/A' for invoices with no credit; docs/test/TCS-MOD-002.json#TC-002-001; docs/test/TCS-MOD-002.json#TC-002-002 -->

### Invoice lines (synapse_fo.CUSTTRANS_RICS to Layercake.brnz_subs_invoice_line)

Only rows that belong to an invoice in Subs.tblSubsInvoices are landed (RULE-077, assumed pending Q-021): the account number must match the invoice's, and either the voucher or the last settlement voucher must be the invoice's voucher. Each row is landed once, identified by recid.

| Source column | Target column | Note |
|---|---|---|
| RECID | recid | Source row key |
| ACCOUNTNUM | accountnum | Must equal the invoice's Account_Num |
| INVOICE | invoice | |
| VOUCHER | voucher | Matches the invoice's voucher for the invoice's own lines |
| LASTSETTLEVOUCHER | lastsettlevoucher | Matches the invoice's voucher for credits and payments settling it |
| TRANSDATE | transdate | Kept to the millisecond |
| TRANSTYPE | transtype | |
| RICINVOICETYPE | ricinvoicetype | Lines of every invoice type are landed |
| productcode | productcode | Item code, later used for the line-type mapping and the concession value |
| AMOUNTCUR | amountcur | Amount in the invoice currency |
| AMOUNTMST | amountmst | Amount in GBP, the accounting currency |
| SETTLEAMOUNTCUR | settleamountcur | |
| CURRENCYCODE | currencycode | |
| PAYMMODE | paymmode | Payment mode on payment lines. Later mapped to a payment method by fn_map_payment_method |
| PAYMREFERENCE | paymreference | |
| ORDERNUM | ordernum | |

<!-- evidence: docs/specs/SPEC-001.json#RULE-077; docs/answers.md#RULE-077 settling rows; docs/specs/SPEC-001.json#synapse_fo.CUSTTRANS_RICS.RECID; docs/specs/SPEC-001.json#1:1. The item code used for the line-type mapping and the concession value.; docs/specs/SPEC-001.json#1:1 (invoice currency); docs/specs/SPEC-001.json#1:1 (GBP accounting currency); docs/specs/SPEC-001.json#1:1 (payment mode on payment lines); docs/answers.md#brnz_subs_invoice_line.paymmode; docs/specs/SPEC-001.json#synapse_fo.CUSTTRANS_RICS.ORDERNUM; docs/dev/CN-MOD-002.json#transdate keeps milliseconds; docs/test/TCS-MOD-002.json#TC-002-011; docs/test/TCS-MOD-002.json#TC-002-014 -->

### Payment mode code to payment method (Layercake.fn_map_payment_method, using Layercake.silv_ref_payment_method)

The function takes one payment mode code, from brnz_subs_invoice.inv_payment_method or brnz_subs_invoice_line.paymmode, and returns a payment method id from silv_ref_payment_method (RULE-007, RULE-008). Letter case and spaces before or after the code are ignored.

| Source payment mode code | Payment method | Id |
|---|---|---|
| DD | Direct Debit | 1 to 5 (one id per method) |
| Card | Card | |
| Bank | Bank transfer | |
| Cheque | Cheque | |
| Corporate | Corporate | |
| Missing, empty or spaces only | Unknown | 0 |
| Any other code, including 'Mixed' | Unrecognised | -1 |

Not applicable (-2) is never the result of this mapping. There is no Mixed payment method, an assumption awaiting Q-015 (see Known limitations).

<!-- evidence: docs/specs/SPEC-001.json#Source payment mode codes map as follows; docs/specs/SPEC-001.json#Any other source code maps to Unrecognised (-1); docs/specs/SPEC-001.json#Layercake.silv_ref_payment_method.source_code; docs/answers.md#MOD-003 fn_map_payment_method; docs/test/TCS-MOD-003.json#TC-003-003; docs/test/TCS-MOD-003.json#TC-003-006; docs/test/TCS-MOD-003.json#TC-003-013; docs/dev/CN-MOD-003.json#It never matches a reserved row; docs/specs/SPEC-001.json#There is no Mixed value (assumes Q-015). -->

### Payment method dimension (Layercake.silv_ref_payment_method to Layercake.dim_payment_method)

Every row of the list is copied, reserved rows included, by usp_load_dim_payment_method (RULE-010).

| Source column (silv_ref_payment_method) | Target column (dim_payment_method) | Note |
|---|---|---|
| id | id | Same id, never changed |
| payment_method_name | payment_method_name | Same name, exactly as in the list |
| (the load's run) | load_id | The load log entry of the load that last wrote the row |

The source payment mode code is not copied to the dimension.

<!-- evidence: docs/specs/SPEC-001.json#RULE-010; docs/specs/SPEC-001.json#Layercake.dim_payment_method.id; docs/specs/SPEC-001.json#Layercake.dim_payment_method.payment_method_name; docs/design/DES-001.json#payment_method_name; docs/test/TCS-MOD-003.json#TC-003-007; docs/test/TCS-MOD-003.json#TC-003-012; docs/answers.md#DES-001 load_id -->

### Grain profile (Layercake.usp_profile_custtrans_grain)

| Source column (synapse_fo.CUSTTRANS_RICS) | Use in the profile |
|---|---|
| TRANSTYPE | Rows with type 8 or 24, or with no type, are left out |
| INVOICE | Rows whose invoice number contains 'CRE' or 'FTCN', or that have no invoice number, are left out. With ACCOUNTNUM, it identifies an invoice |
| ACCOUNTNUM | With INVOICE, it identifies an invoice |
| productcode | Counted as distinct_productcodes per invoice; a missing item code is not counted |
| PostingType_Description | An invoice with a row of 'Sales tax' counts as has_sales_tax_row '1' |
| (number of rows) | Counted as rows_per_invoice per invoice |

Output: for each measure and value, the number of invoices (invoice_count).

<!-- evidence: docs/specs/SPEC-001.json#RULE-095; docs/design/DES-001.json#Layercake.usp_profile_custtrans_grain; docs/dev/CN-MOD-001.json#PostingType_Description = 'Sales tax'; docs/dev/CN-MOD-001.json#invoice_count; docs/test/TCS-MOD-001.json#TC-001-001 -->

### Corporate status profile (Layercake.usp_profile_corp_subscription_status)

| Source column (Subs.vwCorpSubscriptions) | Use in the profile |
|---|---|
| Sub Status | Rows counted per value, reported with status_column 'Sub Status' |
| Sub User Status | Rows counted per value, reported with status_column 'Sub User Status' |

Output: for each status column and value (status_value), the number of source rows (row_count). A missing status is reported as its own value.

<!-- evidence: docs/specs/SPEC-001.json#RULE-096; docs/design/DES-001.json#Layercake.usp_profile_corp_subscription_status; docs/dev/CN-MOD-001.json#row_count; docs/test/TCS-MOD-001.json#TC-001-004 -->
