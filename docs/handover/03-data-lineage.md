# Data lineage: RICS Payment Segment Tracker

## Sources

The solution reads objects that other systems own and maintain. It never creates, changes or writes to them; any change one would need goes to its owner. So far it reads four of them:

| Source | What it holds | Read by |
|---|---|---|
| Subs.tblSubsInvoices | Subscription invoices, one row per invoice, from Campaign Year 2022 onward, with payment method, currency, amounts, credits, payment status and concession flags | Layercake.usp_load_brnz_subs_invoice (landed in brnz_subs_invoice); Layercake.usp_load_brnz_subs_invoice_line (to decide which transaction rows are in scope) |
| synapse_fo.CUSTTRANS_RICS | Customer transaction rows, including invoice rows with item codes (productcode) and posting types, credits and payments | Layercake.usp_load_brnz_subs_invoice_line (landed in brnz_subs_invoice_line); Layercake.usp_profile_custtrans_grain |
| Subs.vwCorpSubscriptions | Corporate scheme subscriptions: the contact, scheme and Campaign Year, with each subscription's 'Sub Status' and each subscription user's 'Sub User Status' | Layercake.usp_load_brnz_corporate_subscription (landed in brnz_corporate_subscription); Layercake.usp_profile_corp_subscription_status |
| CE.vwConcessionType | The concession reference (assumed, Q-008): one row per concession type, with its name, discount, product number, state and whether it is perpetual | Layercake.usp_load_brnz_concession (landed in brnz_concession) |

The two profiles read their sources directly and keep nothing. The four bronze loads copy their sources into the bronze tables without changing any value.

The payment method list (MOD-003) and the payer type list (MOD-004) are not read from any source: each is a fixed list put in place by its migration, and each dimension is copied from its list. The line-type mapping and the currency list (MOD-005) are filled from the bronze invoice tables, and the concession type list (MOD-006) from the concession bronze table, not read from a source directly. The concession type list's four starting rows (the three reserved values and 'No concession') are put in place by its migration.

<!-- evidence: PROJECT_STANDARDS.md#Objects owned by other systems (external); docs/sources/external_catalogue.json#Subs.tblSubsInvoices; docs/sources/external_catalogue.json#synapse_fo.CUSTTRANS_RICS; docs/sources/external_catalogue.json#Subs.vwCorpSubscriptions; docs/sources/external_catalogue.json#CE.vwConcessionType; docs/specs/SPEC-001.json#Invoice source coverage; docs/sources/external/synapse_fo/synapse_fo.CUSTTRANS_RICS.sql#PostingType_Description; docs/design/MP-001.json#count-only procedures over the external sources; docs/dev/CN-MOD-001.json#Neither writes anything; docs/specs/SPEC-001.json#REQ-002; docs/specs/SPEC-001.json#RULE-004; docs/dev/CN-MOD-002.json#Line scope (RULE-077) reads Subs.tblSubsInvoices directly; docs/design/DES-001.json#1:1 landing of Subs.vwCorpSubscriptions; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Sub Status; docs/design/DES-001.json#1:1 landing of CE.vwConcessionType (working default source, Q-008); docs/specs/SPEC-001.json#CE.vwConcessionType.apuk_discount; docs/specs/SPEC-001.json#CE.vwConcessionType.apuk_perpetualnonperpetual; docs/design/DES-001.json#Static list seeded by its migration; docs/design/DES-001.json#Reference lists: payment method and payer type are static lists seeded by their migrations; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type; docs/design/DES-001.json#seen in live brnz_subs_invoice_line rows; docs/design/DES-001.json#(brnz_subs_invoice.inv_currency); docs/design/DES-001.json#Inserts new concession types from live brnz_concession rows; docs/dev/CN-MOD-006.json#the migration seeds 0 Unknown, -1 Unrecognised, -2 Not applicable and 1 No concession -->

## Source-to-target mappings

Every bronze mapping is one-to-one (RULE-004): the target column holds the source value unchanged, with no defaults, trimming or change of case. All bronze tables also carry the four audit columns _loaded_at, _updated_at, _is_deleted and _deleted_at, which the load sets (see the Architecture and data model document). The profiles have no target table; their tables show which source columns they use and how they become the counts they return. The payment method mappings show how a source payment mode code becomes a payment method, and how each list reaches its gold dimension. The line-type and currency mappings show how codes on the bronze invoice data reach their lists, and the currency list its dimension. The concession mappings show how the concession reference reaches the bronze table, the concession type list and its dimension.

<!-- evidence: docs/specs/SPEC-001.json#RULE-004; docs/specs/SPEC-001.json#_loaded_at, _updated_at, _is_deleted, _deleted_at (and the same on brnz_subs_invoice_line); docs/answers.md#DES-001 Q-037 bronze audit columns; docs/test/TCS-MOD-002.json#TC-002-003; docs/test/TCS-MOD-004.json#TC-004-012; docs/test/TCS-MOD-006.json#TC-006-002; docs/design/MP-001.json#Builds no tables and changes no existing object; docs/specs/SPEC-001.json#RULE-095; docs/specs/SPEC-001.json#RULE-096; docs/specs/SPEC-001.json#RULE-007; docs/specs/SPEC-001.json#RULE-010; docs/specs/SPEC-001.json#RULE-029; docs/specs/SPEC-001.json#RULE-031; docs/specs/SPEC-001.json#RULE-045; docs/specs/SPEC-001.json#RULE-046 -->

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

### Concession types (CE.vwConcessionType to Layercake.brnz_concession)

All rows of the source are landed, one row each, identified by the concession type id (apuk_concessiontypeid), which must be present and must not repeat (RULE-045, assumed pending Q-008).

| Source column | Target column | Note |
|---|---|---|
| apuk_concessiontypeid | apuk_concessiontypeid | The concession type's id; the row's identity; must be present |
| apuk_name | apuk_name | The type's name; a missing or untrimmed name is kept as it is |
| apuk_discount | apuk_discount | The discount; later decides whether the type is a full concession |
| Product_Number | product_number | Kept exactly as the source has it; later gives the type's item code |
| statecode | statecode | |
| apuk_perpetualnonperpetual | apuk_perpetualnonperpetual | Perpetual (200000000) or Non-Perpetual (200000001); later decides whether the type is perpetual |
| apuk_dualmembership | (not landed) | Plays no part in this release |

<!-- evidence: docs/specs/SPEC-001.json#CE.vwConcessionType.apuk_concessiontypeid; docs/specs/SPEC-001.json#CE.vwConcessionType.apuk_name; docs/specs/SPEC-001.json#CE.vwConcessionType.apuk_discount; docs/specs/SPEC-001.json#CE.vwConcessionType.Product_Number; docs/specs/SPEC-001.json#CE.vwConcessionType.statecode; docs/specs/SPEC-001.json#CE.vwConcessionType.apuk_perpetualnonperpetual; docs/specs/SPEC-001.json#RULE-045; docs/design/DES-001.json#apuk_dualmembership is not landed (Q-025); docs/answers.md#apuk_dualmembership (v2 Q-025); docs/answers.md#MOD-006 NULL key, duplicate key and missing name; docs/test/TCS-MOD-006.json#TC-006-001; docs/test/TCS-MOD-006.json#TC-006-002; docs/test/TCS-MOD-006.json#TC-006-009 -->

### Concession type list (Layercake.brnz_concession to Layercake.silv_ref_concession_type)

usp_load_silv_ref_concession_type adds each live concession type not yet listed and updates a listed type whose name, item code or flags have changed; ids never change (RULE-046). Types marked as deleted in the bronze table are not added. The four starting rows are not taken from the bronze table.

| Source column (brnz_concession) | Target column (silv_ref_concession_type) | Note |
|---|---|---|
| (new type) | id | A new id for each new type, never changed; the starting rows have fixed ids |
| apuk_concessiontypeid | concession_type_bk | Identifies the type; empty for the four starting rows |
| apuk_name | concession_type_name | Updated when the source name changes. A missing, empty or blank name becomes 'Unnamed concession type' |
| product_number | item_code | Any 'rcs' prefix removed (RULE-048): 'rcsCONRETIRED' gives 'CONRETIRED' |
| apuk_discount | is_full_concession | 1 where the discount is exactly 100, otherwise 0 (RULE-047) |
| apuk_perpetualnonperpetual | is_perpetual | 1 where the value is 200000000 (Perpetual); 0 for any other value, including 200000001 and missing (RULE-094) |
| (the load's run) | load_id | The load log entry of the load that last wrote the row; empty for the starting rows |

<!-- evidence: docs/specs/SPEC-001.json#RULE-046; docs/specs/SPEC-001.json#Layercake.brnz_concession.apuk_concessiontypeid; docs/design/DES-001.json#null for reserved rows and No concession; docs/design/DES-001.json#Fixed for reserved rows and No concession; docs/specs/SPEC-001.json#Updated when the source name changes. Fixed names for the reserved rows and No concession.; docs/answers.md#concession_type_name N'Unnamed concession type'; docs/design/DES-001.json#product_number with any 'rcs' prefix removed (RULE-048); docs/specs/SPEC-001.json#A source Product_Number of 'rcsCONRETIRED' gives item_code 'CONRETIRED'.; docs/design/DES-001.json#1 where apuk_discount = 100, else 0; docs/design/DES-001.json#1 where apuk_perpetualnonperpetual = 200000000, else 0 (null included); docs/test/TCS-MOD-006.json#TC-006-010; docs/test/TCS-MOD-006.json#TC-006-011; docs/test/TCS-MOD-006.json#TC-006-016; docs/test/TCS-MOD-006.json#TC-006-017; docs/test/TCS-MOD-006.json#TC-006-018 -->

### Concession type dimension (Layercake.silv_ref_concession_type to Layercake.dim_concession_type)

Every row of the list is copied, the reserved rows and 'No concession' included, by usp_load_dim_concession_type.

| Source column (silv_ref_concession_type) | Target column (dim_concession_type) | Note |
|---|---|---|
| id | id | Same id, never changed |
| concession_type_name | concession_type_name | Corrected when the list's name changes |
| is_full_concession | is_full_concession | Corrected when the list's flag changes |
| is_perpetual | is_perpetual | Corrected when the list's flag changes |
| (the load's run) | load_id | The load log entry of the load that last wrote the row |

<!-- evidence: docs/design/DES-001.json#Gold copy of silv_ref_concession_type.; docs/design/DES-001.json#Mirrors silv_ref_concession_type into dim_concession_type. Logged.; docs/specs/SPEC-001.json#AC-010-05; docs/test/TCS-MOD-006.json#TC-006-023; docs/test/TCS-MOD-006.json#TC-006-025; docs/answers.md#DES-001 load_id -->

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
| payment_method_name | payment_method_name | Corrected when the list's name changes, including a change only in letter case |
| (the load's run) | load_id | The load log entry of the load that last wrote the row |

<!-- evidence: docs/specs/SPEC-001.json#RULE-010; docs/specs/SPEC-001.json#Layercake.dim_payment_method.payment_method_name; docs/design/DES-001.json#payment_method_name; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/test/TCS-MOD-003.json#TC-003-009; docs/test/TCS-MOD-003.json#TC-003-010; docs/answers.md#DES-001 load_id -->

### Payer type dimension (Layercake.silv_ref_payer_type to Layercake.dim_payer_type)

Every row of the list is copied, reserved rows included, by usp_load_dim_payer_type.

| Source column (silv_ref_payer_type) | Target column (dim_payer_type) | Note |
|---|---|---|
| id | id | Same id, never changed |
| payer_type_name | payer_type_name | Corrected when the list's name changes, including a change only in letter case |
| (the load's run) | load_id | The load log entry of the load that last wrote the row |

<!-- evidence: docs/design/DES-001.json#payer_type_name; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type; docs/test/TCS-MOD-004.json#TC-004-004; docs/test/TCS-MOD-004.json#TC-004-005; docs/answers.md#DES-001 load_id -->

### Invoice item codes to line types (Layercake.brnz_subs_invoice_line to Layercake.silv_ref_invoice_line_type)

usp_load_silv_ref_invoice_line_type adds each item code and RIC invoice type pair found on the live invoice lines that is not yet listed (RULE-029). It never changes a row already listed.

| Source column (brnz_subs_invoice_line) | Target column (silv_ref_invoice_line_type) | Note |
|---|---|---|
| productcode | item_code | A missing, empty or blank item code adds no row |
| ricinvoicetype | ric_invoice_type | A missing invoice type is stored as empty |
| (new pair) | line_type | Always 'unmapped' when added; a person sets the line type by hand |
| (the load's run) | load_id | The load log entry of the load that added the row; empty for the starting rows |

The 12 starting rows (the item codes that Subs.usp_Refresh_SubsInvoices names, confirmed under Q-034) are not taken from the invoice lines; see the Architecture and data model document.

<!-- evidence: docs/design/DES-001.json#Adds each (productcode, ricinvoicetype) seen in live brnz_subs_invoice_line rows that is not yet mapped, with line type 'unmapped'. Existing rows are never chan; docs/design/DES-001.json#brnz_subs_invoice_line.productcode; docs/design/DES-001.json#brnz_subs_invoice_line.ricinvoicetype; docs/answers.md#MOD-005 NULL, blank and near-duplicate codes; docs/test/TCS-MOD-005.json#TC-005-005; docs/test/TCS-MOD-005.json#TC-005-006; docs/answers.md#Q-034 line-type mapping seed -->

### Invoice currency to currency list and dimension (Layercake.brnz_subs_invoice to Layercake.silv_ref_currency to Layercake.dim_currency)

usp_load_silv_ref_currency adds each currency found on the live invoices that is not yet listed, with a new id (RULE-031); usp_load_dim_currency then copies the list to the dimension.

| Source column | Target column | Note |
|---|---|---|
| brnz_subs_invoice.inv_currency | silv_ref_currency.currency_code | A missing, empty or blank currency adds no row; a code that differs from a listed one only in letter case or trailing spaces adds no row |
| (new code) | silv_ref_currency.id | A new id, never changed |
| silv_ref_currency.id | dim_currency.id | Same id |
| silv_ref_currency.currency_code | dim_currency.currency_code | Corrected when the list's code changes |
| (the load's run) | load_id on both tables | The load log entry of the load that last wrote the row |

<!-- evidence: docs/specs/SPEC-001.json#RULE-031; docs/design/DES-001.json#(brnz_subs_invoice.inv_currency); docs/design/DES-001.json#currency_code; docs/answers.md#usp_load_silv_ref_currency works the same way; docs/test/TCS-MOD-005.json#TC-005-020; docs/test/TCS-MOD-005.json#TC-005-021; docs/test/TCS-MOD-005.json#TC-005-023; docs/design/DES-001.json#Mirrors silv_ref_currency into dim_currency. Logged.; docs/answers.md#DES-001 load_id -->

### Grain profile (Layercake.usp_profile_custtrans_grain)

The profile counts invoices in synapse_fo.CUSTTRANS_RICS (RULE-095). It has no target table.

| Source column | How it is used |
|---|---|
| TRANSTYPE | Rows of type 8 or 24 are left out; rows with no type are left out |
| INVOICE | Rows whose invoice number contains 'CRE' or 'FTCN' are left out; rows with no invoice number are left out. With ACCOUNTNUM, identifies an invoice |
| ACCOUNTNUM | With INVOICE, identifies an invoice, so one invoice number on two accounts counts as two invoices |
| productcode | Counted as distinct_productcodes per invoice; a row with no item code adds nothing |
| PostingType_Description | 'Sales tax' marks a tax row, counted as has_sales_tax_row |
| (number of rows) | Counted as rows_per_invoice per invoice |

<!-- evidence: docs/specs/SPEC-001.json#RULE-095; docs/dev/CN-MOD-001.json#rows_per_invoice; docs/dev/CN-MOD-001.json#PostingType_Description = 'Sales tax'; docs/dev/CN-MOD-001.json#The design does not settle these cases; docs/test/TCS-MOD-001.json#TC-001-002; docs/test/TCS-MOD-001.json#TC-001-003 -->

### Corporate status profile (Layercake.usp_profile_corp_subscription_status)

The profile counts rows of Subs.vwCorpSubscriptions (RULE-096). It has no target table.

| Source column | How it is used |
|---|---|
| Sub Status | Rows counted by each value found |
| Sub User Status | Rows counted by each value found |

It counts source rows, not contacts.

<!-- evidence: docs/specs/SPEC-001.json#RULE-096; docs/specs/SPEC-001.json#The corporate status profile returns row counts of Subs.vwCorpSubscriptions by 'Sub Status' and 'Sub User Status' value.; docs/test/TCS-MOD-001.json#TC-001-004; docs/test/TCS-MOD-001.json#TC-001-005 -->
