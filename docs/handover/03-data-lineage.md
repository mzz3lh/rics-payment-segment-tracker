# Data lineage: RICS Payment Segment Tracker

## Sources

The solution reads objects that other systems own and maintain. It never creates, changes or writes to them; any change one would need goes to its owner. So far it reads three of them:

| Source | What it holds | Read by |
|---|---|---|
| Subs.tblSubsInvoices | Subscription invoices, one row per invoice, from Campaign Year 2022 onward, with payment method, currency, amounts, credits, payment status and concession flags | Layercake.usp_load_brnz_subs_invoice (landed in brnz_subs_invoice); Layercake.usp_load_brnz_subs_invoice_line (to decide which transaction rows are in scope) |
| synapse_fo.CUSTTRANS_RICS | Customer transaction rows, including invoice rows with item codes (productcode) and posting types, credits and payments | Layercake.usp_load_brnz_subs_invoice_line (landed in brnz_subs_invoice_line); Layercake.usp_profile_custtrans_grain |
| Subs.vwCorpSubscriptions | Corporate scheme subscriptions: the contact, scheme and Campaign Year, with each subscription's 'Sub Status' and each subscription user's 'Sub User Status' | Layercake.usp_load_brnz_corporate_subscription (landed in brnz_corporate_subscription); Layercake.usp_profile_corp_subscription_status |

The two profiles read their sources directly and keep nothing. The three bronze loads copy their sources into the bronze tables without changing any value.

The payment method list (MOD-003) and the payer type list (MOD-004) are not read from any source: each is a fixed list put in place by its migration, and each dimension is copied from its list. The line-type mapping and the currency list (MOD-005) are filled from the bronze invoice tables, not read from a source directly.

<!-- evidence: PROJECT_STANDARDS.md#Objects owned by other systems (external); docs/sources/external_catalogue.json#Subs.tblSubsInvoices; docs/sources/external_catalogue.json#synapse_fo.CUSTTRANS_RICS; docs/sources/external_catalogue.json#Subs.vwCorpSubscriptions; docs/specs/SPEC-001.json#Invoice source coverage; docs/sources/external/synapse_fo/synapse_fo.CUSTTRANS_RICS.sql#PostingType_Description; docs/design/MP-001.json#count-only procedures over the external sources; docs/dev/CN-MOD-001.json#Neither writes anything; docs/specs/SPEC-001.json#REQ-002; docs/specs/SPEC-001.json#RULE-004; docs/dev/CN-MOD-002.json#Line scope (RULE-077) reads Subs.tblSubsInvoices directly; docs/design/DES-001.json#1:1 landing of Subs.vwCorpSubscriptions; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Sub Status; docs/design/DES-001.json#Static list seeded by its migration; docs/design/DES-001.json#Reference lists: payment method and payer type are static lists seeded by their migrations; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type; docs/design/DES-001.json#seen in live brnz_subs_invoice_line rows; docs/design/DES-001.json#(brnz_subs_invoice.inv_currency) -->

## Source-to-target mappings

Every bronze mapping is one-to-one (RULE-004): the target column holds the source value unchanged, with no defaults, trimming or change of case. All bronze tables also carry the four audit columns _loaded_at, _updated_at, _is_deleted and _deleted_at, which the load sets (see the Architecture and data model document). The profiles have no target table; their tables show which source columns they use and how they become the counts they return. The payment method mappings show how a source payment mode code becomes a payment method, and how each list reaches its gold dimension. The line-type and currency mappings show how codes on the bronze invoice data reach their lists, and the currency list its dimension.

<!-- evidence: docs/specs/SPEC-001.json#RULE-004; docs/specs/SPEC-001.json#_loaded_at, _updated_at, _is_deleted, _deleted_at (and the same on brnz_subs_invoice_line); docs/answers.md#DES-001 Q-037 bronze audit columns; docs/test/TCS-MOD-002.json#TC-002-003; docs/test/TCS-MOD-004.json#TC-004-012; docs/design/MP-001.json#Builds no tables and changes no existing object; docs/specs/SPEC-001.json#RULE-095; docs/specs/SPEC-001.json#RULE-096; docs/specs/SPEC-001.json#RULE-007; docs/specs/SPEC-001.json#RULE-010; docs/specs/SPEC-001.json#RULE-029; docs/specs/SPEC-001.json#RULE-031 -->

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
| Inv_Currency | inv_currency | Feeds the currency list (silv_ref_currency) |
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

<!-- evidence: docs/specs/SPEC-001.json#Subs.tblSubsInvoices.Rec_ID; docs/specs/SPEC-001.json#1:1. Equals the RICS contact number.; docs/specs/SPEC-001.json#1:1 (F&O PAYMMODE on the invoice); docs/answers.md#brnz_subs_invoice.inv_payment_method; docs/specs/SPEC-001.json#Used to tell a credit note from a zero-value invoice numbered 'CRE' (RULE-014); docs/specs/SPEC-001.json#Subs.tblSubsInvoices.100%_Concession; docs/design/DES-001.json#Source column 100%_Concession; docs/answers.md#the source writes 'N/A' for invoices with no credit; docs/test/TCS-MOD-002.json#TC-002-001; docs/test/TCS-MOD-002.json#TC-002-002; docs/specs/SPEC-001.json#Layercake.brnz_subs_invoice.inv_currency -->

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
| RICINVOICETYPE | ricinvoicetype | Lines of every invoice type are landed. With productcode, feeds the line-type mapping |
| productcode | productcode | Item code, used for the line-type mapping (silv_ref_invoice_line_type) and later for the concession value |
| AMOUNTCUR | amountcur | Amount in the invoice currency |
| AMOUNTMST | amountmst | Amount in GBP, the accounting currency |
| SETTLEAMOUNTCUR | settleamountcur | |
| CURRENCYCODE | currencycode | |
| PAYMMODE | paymmode | Payment mode on payment lines. Later mapped to a payment method by fn_map_payment_method |
| PAYMREFERENCE | paymreference | |
| ORDERNUM | ordernum | |

<!-- evidence: docs/specs/SPEC-001.json#RULE-077; docs/answers.md#RULE-077 settling rows; docs/specs/SPEC-001.json#synapse_fo.CUSTTRANS_RICS.RECID; docs/specs/SPEC-001.json#1:1. The item code used for the line-type mapping and the concession value.; docs/specs/SPEC-001.json#1:1 (invoice currency); docs/specs/SPEC-001.json#1:1 (GBP accounting currency); docs/specs/SPEC-001.json#1:1 (payment mode on payment lines); docs/answers.md#brnz_subs_invoice_line.paymmode; docs/specs/SPEC-001.json#synapse_fo.CUSTTRANS_RICS.ORDERNUM; docs/dev/CN-MOD-002.json#transdate keeps milliseconds; docs/test/TCS-MOD-002.json#TC-002-011; docs/test/TCS-MOD-002.json#TC-002-014; docs/design/DES-001.json#Adds each (productcode, ricinvoicetype) seen in live brnz_subs_invoice_line rows -->

### Corporate subscriptions (Subs.vwCorpSubscriptions to Layercake.brnz_corporate_subscription)

All rows of the source are landed, one row each, identified by contact number, scheme number and Campaign Year together (the source has no row key; see Q-033 in Known limitations).

| Source column | Target column | Note |
|---|---|---|
| Contact No | contact_no | Part of the row's identity; must be present |
| Scheme No | scheme_no | Part of the row's identity; must be present |
| Scheme Name | scheme_name | A missing or blank name is kept as it is |
| Sub Campaign Year | sub_campaign_year | Part of the row's identity; must be present |
| Sub Status | sub_status | The subscription's status, kept exactly as the source has it. Later used, with Sub User Status, to decide whether the subscription is live |
| Sub User Status | sub_user_status | The subscription user's status, kept exactly as the source has it |
| Round | (not landed) | Plays no part in the solution |

<!-- evidence: docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Contact No; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Scheme No; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Scheme Name; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Sub Campaign Year; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Sub Status; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Sub User Status; docs/specs/SPEC-001.json#The live-subscription test uses Layercake.brnz_corporate_subscription; docs/design/DES-001.json#The source has no row key; docs/design/DES-001.json#'Round' is not landed and plays no part; docs/answers.md#MOD-004 NULL matching key; docs/test/TCS-MOD-004.json#TC-004-008; docs/test/TCS-MOD-004.json#TC-004-009; docs/test/TCS-MOD-004.json#TC-004-011; docs/test/TCS-MOD-004.json#TC-004-012 -->

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

### Payer type dimension (Layercake.silv_ref_payer_type to Layercake.dim_payer_type)

Every row of the list is copied, reserved rows included, by usp_load_dim_payer_type.

| Source column (silv_ref_payer_type) | Target column (dim_payer_type) | Note |
|---|---|---|
| id | id | Same id, never changed |
| payer_type_name | payer_type_name | Same name, exactly as in the list |
| (the load's run) | load_id | The load log entry of the load that last wrote the row |

<!-- evidence: docs/design/DES-001.json#Layercake.dim_payer_type; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type; docs/test/TCS-MOD-004.json#TC-004-002; docs/test/TCS-MOD-004.json#TC-004-007; docs/answers.md#DES-001 load_id -->

### Invoice item codes to line types (Layercake.brnz_subs_invoice_line to Layercake.silv_ref_invoice_line_type)

usp_load_silv_ref_invoice_line_type adds each item code and RIC invoice type pair found on live invoice lines that the mapping does not yet hold (RULE-029). Existing rows are never changed.

| Source column (brnz_subs_invoice_line) | Target column (silv_ref_invoice_line_type) | Note |
|---|---|---|
| productcode | item_code | A missing, empty or blank code adds no row. Matched ignoring letter case and trailing spaces |
| ricinvoicetype | ric_invoice_type | A missing type is stored as empty, not skipped. Matched ignoring letter case and trailing spaces |
| (none) | line_type | 'unmapped' for every new pair; a person sets the real line type by hand |
| (the load's run) | load_id | The load log entry of the load that added the row; empty for the starting rows |

The starting rows (the 12 pairs assumed pending Q-034) are not taken from the invoice lines; see the Architecture and data model document.

<!-- evidence: docs/design/DES-001.json#Adds each (productcode, ricinvoicetype) seen in live brnz_subs_invoice_line rows that is not yet mapped, with line type 'unmapped'. Existing rows are never changed. Logged.; docs/specs/SPEC-001.json#RULE-029; docs/specs/SPEC-001.json#Layercake.silv_ref_invoice_line_type.item_code; docs/specs/SPEC-001.json#Layercake.silv_ref_invoice_line_type.ric_invoice_type; docs/specs/SPEC-001.json#Layercake.silv_ref_invoice_line_type.line_type; docs/answers.md#MOD-005 NULL, blank and near-duplicate codes; docs/dev/CN-MOD-005.json#A NULL ricinvoicetype is stored as N''; docs/dev/CN-MOD-005.json#with load_id NULL; docs/dev/CN-MOD-005.json#Q-034; docs/test/TCS-MOD-005.json#TC-005-005; docs/test/TCS-MOD-005.json#TC-005-006; docs/test/TCS-MOD-005.json#TC-005-013 -->

### Invoice currency to currency list and dimension (Layercake.brnz_subs_invoice to Layercake.silv_ref_currency to Layercake.dim_currency)

usp_load_silv_ref_currency adds each currency code found on live invoices that the list does not yet hold, with a new id (RULE-031). usp_load_dim_currency then copies the list to the dimension by id.

| Source | Target | Note |
|---|---|---|
| brnz_subs_invoice.inv_currency | silv_ref_currency.currency_code | A missing, empty or blank currency adds no row. Matched ignoring letter case and trailing spaces |
| (new for each code) | silv_ref_currency.id | Given when the code is added; never changed |
| silv_ref_currency.id | dim_currency.id | Same id |
| silv_ref_currency.currency_code | dim_currency.currency_code | Same code, exactly as in the list |
| (the load's run) | load_id on both tables | The load log entry of the load that last wrote the row |

<!-- evidence: docs/specs/SPEC-001.json#RULE-031; docs/specs/SPEC-001.json#Layercake.silv_ref_currency.currency_code; docs/specs/SPEC-001.json#Layercake.dim_currency.id (with currency_code); docs/design/DES-001.json#Insert-only, identity ids that never change.; docs/design/DES-001.json#Mirrors silv_ref_currency into dim_currency. Logged.; docs/answers.md#usp_load_silv_ref_currency works the same way; docs/dev/CN-MOD-005.json#usp_load_dim_currency mirrors silver by id; docs/test/TCS-MOD-005.json#TC-005-015; docs/test/TCS-MOD-005.json#TC-005-017; docs/test/TCS-MOD-005.json#TC-005-020; docs/answers.md#DES-001 load_id -->

### Grain profile (Layercake.usp_profile_custtrans_grain)

Reads synapse_fo.CUSTTRANS_RICS and returns counts only (RULE-095). No row is stored.

| Source column | How it is used |
|---|---|
| TRANSTYPE | Rows with type 8 or 24, or with no type, are left out |
| INVOICE | Rows whose invoice number contains 'CRE' or 'FTCN', or that have no invoice number, are left out. With ACCOUNTNUM, it identifies an invoice |
| ACCOUNTNUM | With INVOICE, it identifies an invoice |
| productcode | Counted as distinct_productcodes per invoice; a missing item code is not counted |
| PostingType_Description | An invoice with a row of 'Sales tax' counts as has_sales_tax_row '1' |
| (number of rows) | Counted as rows_per_invoice per invoice |

<!-- evidence: docs/specs/SPEC-001.json#RULE-095; docs/dev/CN-MOD-001.json#rows_per_invoice; docs/dev/CN-MOD-001.json#PostingType_Description = 'Sales tax'; docs/dev/CN-MOD-001.json#A NULL productcode adds nothing to distinct_productcodes; docs/dev/CN-MOD-001.json#test grain profile leaves out rows with no TRANSTYPE or no INVOICE; docs/test/TCS-MOD-001.json#TC-001-001; docs/test/TCS-MOD-001.json#TC-001-002; docs/test/TCS-MOD-001.json#TC-001-003 -->

### Corporate status profile (Layercake.usp_profile_corp_subscription_status)

Reads Subs.vwCorpSubscriptions and returns counts only (RULE-096). No row is stored.

| Source column | How it is used |
|---|---|
| Sub Status | Rows counted per value, reported with status_column 'Sub Status' |
| Sub User Status | Rows counted per value, reported with status_column 'Sub User Status' |

<!-- evidence: docs/specs/SPEC-001.json#RULE-096; docs/dev/CN-MOD-001.json#status_column varchar(50); docs/test/TCS-MOD-001.json#TC-001-004; docs/test/TCS-MOD-001.json#TC-001-005 -->
