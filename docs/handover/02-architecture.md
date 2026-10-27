# Architecture and data model: RICS Payment Segment Tracker

## Architecture overview

The solution extends the Phase 1 Layercake membership solution. All new objects live in the Layercake schema and follow the Phase 1 naming conventions. The design has bronze tables (one-to-one landings of source data), silver tables (reference lists, attributes and matches), gold dimensions and fact columns, and a set of read-only reporting procedures that return aggregates only (counts, sums and rates). Every change ships as a migration with a tested rollback script.

Four layers are in place so far:

- **Reporting procedures (MOD-001):** two source profiles, named usp_profile_*. They read two sources owned by other systems (see the Data lineage document), write nothing and build no tables. They are meant to be run before the invoice build, so that their results can settle two open questions the build depends on (see Known limitations).
- **Bronze (MOD-002, MOD-004, MOD-006):** four tables, each with a load procedure. brnz_subs_invoice and brnz_subs_invoice_line copy subscription invoice data, brnz_corporate_subscription copies the corporate scheme subscriptions, and brnz_concession copies the concession types, from sources already in the warehouse with no change to any value. They carry the same four audit columns as the Phase 1 bronze tables. Each load records its run in the load log, Layercake.etl_run_log.
- **Silver reference (MOD-003 to MOD-006):** the payment method list, silv_ref_payment_method, and the payer type list, silv_ref_payer_type, fixed lists put in place by their migrations; fn_map_payment_method, which turns a source payment mode code into an entry on the payment method list; two lists that grow from the bronze invoice data: the line-type mapping, silv_ref_invoice_line_type, which says what each invoice item code is for, and the currency list, silv_ref_currency; and the concession type list, silv_ref_concession_type, which takes in new concession types and changes to listed ones from the concession bronze table while every type keeps its id. Each of these three has a load that records its run in the load log.
- **Gold dimensions (MOD-003 to MOD-006):** dim_payment_method, dim_payer_type, dim_currency and dim_concession_type, copies of their lists for reporting, each kept in step with its list by its load, which also records its run in the load log.

Later modules build the rest of the silver and gold layers on these objects, including working out each contact's payment method, payer type and concession for each Campaign Year and the invoiced amounts on each event.

<!-- evidence: docs/design/DES-001.json#Extends the Phase 1 Layercake membership solution; docs/design/DES-001.json#reporting queries; docs/design/MP-001.json#Builds no tables and changes no existing object; docs/dev/CN-MOD-001.json#Neither writes anything; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#before the invoice build; docs/design/DES-001.json#1:1 landings of external sources; docs/specs/SPEC-001.json#RULE-004; docs/design/DES-001.json#load logging; docs/design/MP-001.json#Subscription invoice bronze; docs/design/MP-001.json#Payment method reference and dimension; docs/design/MP-001.json#Corporate subscription bronze and payer type reference; docs/design/MP-001.json#Invoice line-type mapping and currency; docs/design/MP-001.json#Concession reference and dimension; docs/design/DES-001.json#1:1 landing of Subs.vwCorpSubscriptions; docs/design/DES-001.json#1:1 landing of CE.vwConcessionType; docs/design/DES-001.json#Static list seeded by its migration; docs/design/DES-001.json#Maps a source payment mode code to a silv_ref_payment_method id; docs/design/DES-001.json#Item-code to line-type mapping, one row per (item_code, ric_invoice_type); docs/design/DES-001.json#Insert-only, identity ids that never change.; docs/design/DES-001.json#Concession type is insert-and-update by business key; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type; docs/design/DES-001.json#Mirrors silv_ref_currency into dim_currency. Logged.; docs/design/DES-001.json#Mirrors silv_ref_concession_type into dim_concession_type. Logged.; docs/design/MP-001.json#Does not derive any contact's payment method; docs/design/MP-001.json#payment method, payer type, corporate_account_ref and concession per contact-year; docs/design/MP-001.json#Does not compute amounts -->

## Data model

MOD-001 adds two procedures and no tables. MOD-002 adds two bronze tables and two load procedures. MOD-003 adds a silver reference table, a mapping function, a gold dimension table and its load procedure. MOD-004 adds a bronze table and its load procedure, a silver reference table, and a gold dimension table and its load procedure. MOD-005 adds two silver reference tables and a gold dimension table, each with its load procedure. MOD-006 adds a bronze table, a silver reference table and a gold dimension table, each with its load procedure. No existing object is changed.

<!-- evidence: docs/design/MP-001.json#Builds no tables and changes no existing object; docs/dev/CN-MOD-002.json#objects_changed; docs/dev/CN-MOD-003.json#objects_changed; docs/dev/CN-MOD-004.json#objects_changed; docs/dev/CN-MOD-005.json#objects_changed; docs/dev/CN-MOD-006.json#objects_changed -->

### Layercake.brnz_subs_invoice

A copy of the subscription invoice table Subs.tblSubsInvoices (REQ-002), which holds invoices from Campaign Year 2022 onward. One row per source row, identified by the source's row key (rec_id). Every column holds the source value unchanged: a missing value stays missing, and blanks, spaces and letter case are kept exactly as the source has them. Column types and lengths follow the source, with one deliberate exception for the money columns (see Known limitations).

It holds, for each invoice: the account number (the RICS contact number), Campaign Year, invoice number and voucher, transaction date, the payment method recorded on the invoice, currency and exchange rate, the full invoice amount, the invoice amount in its own currency and in GBP, the credited amount in its own currency and in GBP, whether it is fully credited, its payment status, and its two concession flags. The full column list is in the Data lineage document.

Every row also carries the four standard bronze audit columns:

| Column | Meaning |
|---|---|
| _loaded_at | When the row was first landed |
| _updated_at | When a load last changed the row |
| _is_deleted | 1 when the row is no longer in the source; 0 while it is live |
| _deleted_at | When the row was marked as deleted; empty while it is live |

The table keeps only the latest values of each row: when a source value changes, the row is updated in place. A row that leaves the source is marked as deleted rather than removed, and a deleted row that the source sends again is made live again.

<!-- evidence: docs/design/DES-001.json#Layercake.brnz_subs_invoice; docs/design/DES-001.json#1:1 landing of Subs.tblSubsInvoices (Campaign Year 2022 onward); docs/specs/SPEC-001.json#REQ-002; docs/specs/SPEC-001.json#Invoice source coverage; docs/specs/SPEC-001.json#RULE-004; docs/test/TCS-MOD-002.json#TC-002-003; docs/design/DES-001.json#Standard bronze audit column: when the row was first landed; docs/design/DES-001.json#scd1; docs/test/TCS-MOD-002.json#TC-002-007; docs/test/TCS-MOD-002.json#TC-002-008; docs/test/TCS-MOD-002.json#TC-002-009; docs/dev/CN-MOD-002.json#deviations -->

### Layercake.brnz_subs_invoice_line

A copy of the rows of synapse_fo.CUSTTRANS_RICS (the finance system's customer transactions) that belong to the invoices in Subs.tblSubsInvoices (REQ-002). One row per source row, identified by the source's row key (recid); a source row is landed once even if it belongs to more than one invoice. The grain is assumed to be one row per invoice line, awaiting Q-021 (see Known limitations). Values are copied unchanged, including transaction dates to the millisecond, and the table carries the same four audit columns and the same update, delete and restore behaviour as brnz_subs_invoice.

A source row belongs to an invoice (RULE-077, assumed pending Q-021) when its account number is the invoice's account number and either:

- its voucher is the invoice's voucher (the invoice's own lines, of every invoice type), or
- its last settlement voucher is the invoice's voucher (credits and payments that settle the invoice).

A payment or credit posted on a different customer account is not landed, even when it settles the invoice. The legal entity is not used in the match, because Subs.tblSubsInvoices does not hold one. When an invoice leaves Subs.tblSubsInvoices, its lines fall out of scope and are marked as deleted, even if the transaction rows still exist.

The table holds, for each row: account number, invoice number, voucher, last settlement voucher, transaction date, transaction type, invoice type, item code (productcode), amount in the invoice currency and in GBP, settled amount, currency, payment mode and payment reference (on payment lines), and order number.

<!-- evidence: docs/design/DES-001.json#Layercake.brnz_subs_invoice_line; docs/design/DES-001.json#1:1 landing of the synapse_fo.CUSTTRANS_RICS rows in scope under RULE-077; docs/specs/SPEC-001.json#RULE-077; docs/answers.md#RULE-077 settling rows; docs/dev/CN-MOD-002.json#no DATAAREAID match; docs/dev/CN-MOD-002.json#Each line lands once even when it matches several invoices; docs/test/TCS-MOD-002.json#TC-002-013; docs/test/TCS-MOD-002.json#TC-002-014; docs/test/TCS-MOD-002.json#TC-002-015; docs/dev/CN-MOD-002.json#transdate keeps milliseconds; docs/specs/SPEC-001.json#Q-021 -->

### Layercake.usp_load_brnz_subs_invoice and Layercake.usp_load_brnz_subs_invoice_line

The two loads, one for each bronze table. Each compares the whole source with its table on every run, by row key:

- new source rows are added;
- changed rows are updated, and only they get a new _updated_at;
- rows no longer in the source (or, for lines, no longer in scope) are marked as deleted;
- a deleted row that reappears is made live again, not added a second time;
- unchanged rows are left alone, so a second run on unchanged data changes nothing.

Each load checks that its live rows equal the number of source rows in scope (RULE-005), and fails if they do not. Each records one row in Layercake.etl_run_log with its outcome ('Success' or 'Failed') and the numbers of rows inserted, updated and deleted. For what happens when a load fails, see the Runbook. The line load takes its list of invoices directly from Subs.tblSubsInvoices.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_brnz_subs_invoice; docs/design/DES-001.json#Layercake.usp_load_brnz_subs_invoice_line; docs/design/DES-001.json#full comparison with the source on its key on every run; docs/specs/SPEC-001.json#RULE-005; docs/test/TCS-MOD-002.json#TC-002-019; docs/test/TCS-MOD-002.json#TC-002-005; docs/test/TCS-MOD-002.json#TC-002-004; docs/dev/CN-MOD-002.json#A row-count mismatch between live rows and the source (RULE-005) also fails the load; docs/dev/CN-MOD-002.json#Line scope (RULE-077) reads Subs.tblSubsInvoices directly -->

### Layercake.brnz_corporate_subscription

A copy of the corporate scheme subscriptions in Subs.vwCorpSubscriptions (REQ-006). It holds, for each row: the contact number, the scheme number and scheme name, the subscription's Campaign Year (Sub Campaign Year), the subscription's status (Sub Status) and the subscription user's status (Sub User Status). Every value is copied unchanged: a missing scheme name or status stays missing, and blanks, spaces and letter case are kept exactly as the source has them. The source's 'Round' column is not landed and plays no part in the solution: a round is a tranche of processing corporate records, and later rounds may change it.

The source has no row key, so each row is identified by its contact number, scheme number and Campaign Year together. These three values must always be present. The design assumes no two source rows share them, awaiting the client's confirmation (Q-033, see Known limitations).

The table carries the same four audit columns as the other bronze tables, and keeps only the latest values of each row in the same way: changed rows are updated in place, a row that leaves the source is marked as deleted, and a deleted row that reappears is made live again.

<!-- evidence: docs/design/DES-001.json#Layercake.brnz_corporate_subscription; docs/design/DES-001.json#1:1 landing of Subs.vwCorpSubscriptions; docs/design/DES-001.json#'Round' is not landed and plays no part; docs/design/DES-001.json#The source has no row key; docs/specs/SPEC-001.json#REQ-006; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Contact No; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Sub User Status; docs/answers.md#Do not use 'Round'; docs/answers.md#MOD-004 NULL matching key; docs/dev/CN-MOD-004.json#PK on contact_no, scheme_no, sub_campaign_year; docs/dev/CN-MOD-004.json#Q-033; docs/test/TCS-MOD-004.json#TC-004-009; docs/test/TCS-MOD-004.json#TC-004-011; docs/test/TCS-MOD-004.json#TC-004-012; docs/test/TCS-MOD-004.json#TC-004-016; docs/test/TCS-MOD-004.json#TC-004-017; docs/answers.md#DES-001 Q-037 bronze audit columns -->

### Layercake.usp_load_brnz_corporate_subscription

The load for brnz_corporate_subscription. It works like the other bronze loads: on every run it compares the whole source with the table, by contact number, scheme number and Campaign Year, and adds new rows, updates changed rows, marks rows gone from the source as deleted and makes reappearing rows live again. Unchanged rows are left alone, so a second run on unchanged data changes nothing. In addition:

- Values are compared exactly, so a change only in letter case or trailing spaces counts as a change. For one of the three identifying values, such a change updates the existing row in place.
- A change only in 'Round' is not a change, because Round is not landed.
- Making a deleted row live again counts as an update. A row that is already marked as deleted and is still missing from the source is not touched or counted.
- The load checks that its live rows equal the number of source rows (RULE-005).
- A source row with a missing contact number, scheme number or Campaign Year, or two source rows with the same three values, fails the whole load, which changes nothing; no row is skipped (see the Runbook and Known limitations).

It records its run in the load log like the other bronze loads.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_brnz_corporate_subscription; docs/test/TCS-MOD-004.json#TC-004-013; docs/test/TCS-MOD-004.json#TC-004-014; docs/test/TCS-MOD-004.json#TC-004-015; docs/test/TCS-MOD-004.json#TC-004-018; docs/test/TCS-MOD-004.json#TC-004-010; docs/test/TCS-MOD-004.json#TC-004-019; docs/dev/CN-MOD-004.json#All string columns, the key columns included, are compared as bytes; docs/dev/CN-MOD-004.json#for a key column that update rewrites the key in place; docs/dev/CN-MOD-004.json#Restoring a soft-deleted row counts as an update; docs/dev/CN-MOD-004.json#A row that is already soft-deleted and still missing from the source is not touched and not counted; docs/dev/CN-MOD-004.json#The live row count is checked against the source count (RULE-005); docs/dev/CN-MOD-004.json#A repeated key fails usp_load_brnz_corporate_subscription with error 2627; docs/answers.md#MOD-004 NULL matching key -->

### Layercake.silv_ref_payment_method

The list of payment methods (REQ-003), put in place by its migration. It holds the three reserved values that every segment list shares, and the five payment methods the dashboard filters on. Ids never change.

| Id | Label | Meaning |
|---|---|---|
| 0 | Unknown | The source has no value |
| -1 | Unrecognised | The source has a value the mapping does not know |
| -2 | Not applicable | No value is expected |

The five methods have ids 1 to 5, and each carries the source payment mode code it maps from:

| Payment method | Source code |
|---|---|
| Direct Debit | DD |
| Card | Card |
| Bank transfer | Bank |
| Cheque | Cheque |
| Corporate | Corporate |

The reserved values carry no source code. There is no Mixed value, an assumption awaiting Q-015 (see Known limitations). The reserved values have the same ids and labels in the payer type and concession type lists (RULE-078).

<!-- evidence: docs/design/DES-001.json#Layercake.silv_ref_payment_method; docs/design/DES-001.json#Static list seeded by its migration; docs/specs/SPEC-001.json#RULE-006; docs/specs/SPEC-001.json#RULE-078; docs/specs/SPEC-001.json#Reserved values; docs/design/DES-001.json#DD, Card, Bank, Cheque, Corporate; docs/test/TCS-MOD-003.json#TC-003-001; docs/test/TCS-MOD-003.json#TC-003-002; docs/test/TCS-MOD-003.json#TC-003-004; docs/test/TCS-MOD-006.json#TC-006-029; docs/specs/SPEC-001.json#There is no Mixed value (assumes Q-015). -->

### Layercake.fn_map_payment_method

Turns one source payment mode code (from brnz_subs_invoice.inv_payment_method or brnz_subs_invoice_line.paymmode) into a payment method id (RULE-007, RULE-008). It reads the source codes from silv_ref_payment_method, so the codes are held in one place.

- Letter case and spaces before or after the code are ignored: 'dd', ' DD' and 'Card ' map to their methods.
- A missing code, an empty code or a code of spaces only maps to 0 Unknown.
- Any other code, including 'Mixed', maps to -1 Unrecognised.
- It never returns a reserved value other than Unknown or Unrecognised by matching a code, so Not applicable (-2) is never its result.

It is used inside the loads of later modules, not run on its own.

<!-- evidence: docs/design/DES-001.json#Layercake.fn_map_payment_method; docs/design/DES-001.json#Maps a source payment mode code to a silv_ref_payment_method id; docs/answers.md#MOD-003 fn_map_payment_method; docs/answers.md#Compare the code with surrounding spaces trimmed and ignoring case; docs/specs/SPEC-001.json#RULE-007; docs/specs/SPEC-001.json#RULE-008; docs/test/TCS-MOD-003.json#TC-003-013; docs/dev/CN-MOD-003.json#It never matches a reserved row -->

### Layercake.dim_payment_method

The gold copy of the payment method list for reporting (REQ-003, RULE-010): one row for each row of silv_ref_payment_method, reserved values included, with the same id and the same name. Each row also carries load_id, the load log entry of the load that last wrote it, and its created and updated times. It is not filled by its migration: it stays empty until usp_load_dim_payment_method first runs.

<!-- evidence: docs/design/DES-001.json#Layercake.dim_payment_method; docs/specs/SPEC-001.json#RULE-010; docs/specs/SPEC-001.json#dim_payment_method holds one row per silv_ref_payment_method row; docs/answers.md#DES-001 load_id; docs/answers.md#MOD-003 dim_payment_method population -->

### Layercake.usp_load_dim_payment_method

The load that keeps dim_payment_method in step with silv_ref_payment_method. On each run it:

- adds any id the dimension lacks;
- corrects a name that differs from the list, including a difference only in letter case or trailing spaces;
- leaves unchanged rows untouched, so a second run changes nothing;
- never removes a row, even one whose id has left the list (see Known limitations).

It sets load_id and the updated time only on rows it adds or corrects, and keeps each row's created time. It makes all its changes in one step and records its run in the load log; its deleted count is always 0.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_dim_payment_method; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/test/TCS-MOD-003.json#TC-003-008; docs/test/TCS-MOD-003.json#TC-003-009; docs/test/TCS-MOD-003.json#TC-003-010; docs/dev/CN-MOD-003.json#rows_deleted is always 0; docs/dev/CN-MOD-003.json#The update and insert run in one transaction, so a failure also rolls back an update already made -->

### Layercake.silv_ref_payer_type

The list of payer types (REQ-006, RULE-020), put in place by its migration. Ids never change.

| Id | Label |
|---|---|
| 0 | Unknown |
| -1 | Unrecognised |
| -2 | Not applicable |
| 1 | Individual |
| 2 | Corporate |

The three reserved values have the same ids and labels as in the payment method list.

<!-- evidence: docs/design/DES-001.json#Layercake.silv_ref_payer_type; docs/specs/SPEC-001.json#RULE-020; docs/dev/CN-MOD-004.json#0 Unknown, -1 Unrecognised, -2 Not applicable, 1 Individual, 2 Corporate; docs/test/TCS-MOD-004.json#TC-004-001; docs/specs/SPEC-001.json#RULE-078 -->

### Layercake.dim_payer_type

The gold copy of the payer type list for reporting: one row for each row of silv_ref_payer_type, reserved values included, with the same id and name, and load_id, the load log entry of the load that last wrote the row. It stays empty until usp_load_dim_payer_type first runs.

<!-- evidence: docs/design/DES-001.json#Layercake.dim_payer_type; docs/answers.md#DES-001 load_id; docs/dev/CN-MOD-004.json#dim_payer_type is not seeded -->

### Layercake.usp_load_dim_payer_type

The load that keeps dim_payer_type in step with silv_ref_payer_type. It works the same way as usp_load_dim_payment_method: it adds missing ids, corrects changed names (including changes only in letter case), leaves unchanged rows untouched, never removes a row, makes all its changes in one step and records its run in the load log.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_dim_payer_type; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type, as the payment method dimension load does.; docs/dev/CN-MOD-004.json#same pattern as usp_load_dim_payment_method; docs/dev/CN-MOD-004.json#The load never deletes from the dimension; docs/test/TCS-MOD-004.json#TC-004-004; docs/test/TCS-MOD-004.json#TC-004-005 -->

### Layercake.silv_ref_invoice_line_type

The line-type mapping (REQ-007, RULE-028): it says what each invoice item code is for, so that a later module (MOD-010) can split an invoice's amount into subscription, fee and other parts. One row per item code and RIC invoice type pair, with its line type: subscription, concession, readmission fee, enrolment or application fee, tax, other, or unmapped.

Each row also carries load_id (the load log entry of the load that added it; empty for the starting rows) and its created and updated times.

**Starting content.** As confirmed on 2026-10-27 (Q-034), the mapping starts with exactly the 12 item codes that the existing Subs.usp_Refresh_SubsInvoices names, all with RIC invoice type 'SUB'; no other curated list exists:

| Item codes | Line type |
|---|---|
| RAFEE_ACAND, RAFEE_APCC, RAFEE_ASSOC, RAFEE_FRICS, RAFEE_MRICS, RAFEE_PMU2 | readmission fee |
| CONPWRQ1, CONPWRQ2, CONPWRQ3, CONRETIRED, CONRETIREDFL, CONRETIREDSPECIAL | concession |

Every other code, the subscription codes included, is added as 'unmapped' by the first load.

**Mapping by hand.** A person changes the line type on a row from 'unmapped' to the right value. The load never overwrites an existing row, so a hand mapping is kept on every later run (AC-007-02). After the first load on real data, Damian maps the unmapped codes, following how Subs.usp_Refresh_SubsInvoices classifies them (see Known limitations).

<!-- evidence: docs/design/DES-001.json#Layercake.silv_ref_invoice_line_type; docs/design/DES-001.json#Item-code to line-type mapping, one row per (item_code, ric_invoice_type); docs/specs/SPEC-001.json#RULE-028; docs/design/DES-001.json#One of: subscription, concession, readmission fee, enrolment or application fee, tax, other, unmapped (check constraint); docs/dev/CN-MOD-005.json#test new line type rows carry the load log id and equal created and updated times; docs/answers.md#Q-034 line-type mapping seed; docs/answers.md#No other curated list exists; docs/dev/CN-MOD-005.json#RAFEE_ACAND, RAFEE_APCC, RAFEE_ASSOC, RAFEE_FRICS, RAFEE_MRICS, RAFEE_PMU2; docs/dev/CN-MOD-005.json#CONPWRQ1, CONPWRQ2, CONPWRQ3, CONRETIRED, CONRETIREDFL, CONRETIREDSPECIAL; docs/specs/SPEC-001.json#AC-007-02; docs/answers.md#Damian maps the unmapped codes by hand -->

### Layercake.usp_load_silv_ref_invoice_line_type

The load that adds new item codes to the line-type mapping (RULE-029). On each run it reads the live rows of brnz_subs_invoice_line (rows marked as deleted are ignored) and adds each pair of item code and RIC invoice type not yet listed, with line type 'unmapped'.

- A line with a missing, empty or blank item code adds nothing.
- A line with an item code but no RIC invoice type is not skipped: its code is added with an empty invoice type, so its amount is flagged later rather than lost unseen.
- Codes are matched ignoring letter case and trailing spaces: a code that differs from a listed pair only in those ways is that pair and adds no row. A code with different leading spaces or characters is a new code.
- When one new code arrives in several spellings in the same run, one row is added, keeping the upper-case spelling first, then the one without trailing spaces (see Known limitations).
- It never changes or removes an existing row.

It makes all its changes in one step and records its run in the load log, with the number of rows added.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_ref_invoice_line_type; docs/specs/SPEC-001.json#RULE-029; docs/answers.md#MOD-005 NULL, blank and near-duplicate codes; docs/test/TCS-MOD-005.json#TC-005-004; docs/test/TCS-MOD-005.json#TC-005-005; docs/test/TCS-MOD-005.json#TC-005-006; docs/test/TCS-MOD-005.json#TC-005-007; docs/test/TCS-MOD-005.json#TC-005-008; docs/test/TCS-MOD-005.json#TC-005-009; docs/test/TCS-MOD-005.json#TC-005-012; docs/dev/CN-MOD-005.json#test line type spellings of one new pair keep the upper case and shortest spelling; docs/dev/CN-MOD-005.json#On error they roll back, log 'Failed' and re-raise. -->

### Layercake.silv_ref_currency

The currency list (REQ-007, RULE-031): one row per currency code found on the subscription invoices (brnz_subs_invoice.inv_currency), each with its own id, which never changes between loads. Each row also carries load_id, the load log entry of the load that added it.

<!-- evidence: docs/design/DES-001.json#Layercake.silv_ref_currency; docs/specs/SPEC-001.json#RULE-031; docs/design/DES-001.json#(brnz_subs_invoice.inv_currency); docs/design/DES-001.json#Insert-only, identity ids that never change.; docs/answers.md#DES-001 load_id -->

### Layercake.usp_load_silv_ref_currency

The load that adds new currencies to the currency list. It reads the live rows of brnz_subs_invoice and adds each currency code not yet listed, with a new id; listed currencies keep their ids. It only adds rows and never changes one.

- An invoice with a missing, empty or blank currency adds nothing.
- A code that differs from a listed one only in letter case or trailing spaces adds no row.
- An invoice marked as deleted adds nothing.
- A new currency arriving in several letter cases in one run adds a single row, keeping the upper-case spelling.

It makes all its changes in one step and records its run in the load log.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_ref_currency; docs/answers.md#usp_load_silv_ref_currency works the same way; docs/dev/CN-MOD-005.json#are insert-only; docs/test/TCS-MOD-005.json#TC-005-020; docs/test/TCS-MOD-005.json#TC-005-021; docs/test/TCS-MOD-005.json#TC-005-022; docs/test/TCS-MOD-005.json#TC-005-023; docs/test/TCS-MOD-005.json#TC-005-024; docs/dev/CN-MOD-005.json#test currency spellings of one new code keep the upper case spelling and the load log id -->

### Layercake.dim_currency

The gold copy of the currency list for reporting: one row for each row of silv_ref_currency, with the same id and currency code, and load_id, the load log entry of the load that last wrote the row. It stays empty until usp_load_silv_ref_currency and then usp_load_dim_currency have run.

<!-- evidence: docs/design/DES-001.json#Layercake.dim_currency; docs/design/DES-001.json#Gold copy of silv_ref_currency.; docs/answers.md#DES-001 load_id; docs/dev/CN-MOD-005.json#dim_currency is empty after the migration until usp_load_silv_ref_currency and then usp_load_dim_currency run (by hand until MOD-016) -->

### Layercake.usp_load_dim_currency

The load that keeps dim_currency in step with silv_ref_currency, matching rows by id. On each run it adds any id the dimension lacks, corrects a code that differs from the list (including a difference only in letter case), and leaves unchanged rows untouched. It never removes a row. It makes all its changes in one step, so a failed run also undoes any correction it had already made, and records its run in the load log.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_dim_currency; docs/design/DES-001.json#Mirrors silv_ref_currency into dim_currency. Logged.; docs/test/TCS-MOD-005.json#TC-005-019; docs/dev/CN-MOD-005.json#test dim_currency takes a case only change of a silver code as one update; docs/dev/CN-MOD-005.json#test failed dim_currency insert also rolls back the update made before it; docs/dev/CN-MOD-005.json#never deletes -->

### Layercake.brnz_concession

A copy of the concession reference, CE.vwConcessionType (REQ-010, RULE-045). That this view is the concession reference is an assumption awaiting Q-008 (see Known limitations). One row per source row, identified by the concession type id (apuk_concessiontypeid), which must always be present.

It holds, for each concession type: its id, name, discount, product number, state (statecode) and whether it is perpetual or non-perpetual. Every value is copied unchanged: a missing value stays missing, and blanks, spaces and letter case are kept exactly as the source has them. The source's dual-membership column is not landed and plays no part in this release. The full column list is in the Data lineage document.

The table carries the same four audit columns as the other bronze tables, and keeps only the latest values of each row in the same way: changed rows are updated in place, a row that leaves the source is marked as deleted, and a deleted row that reappears is made live again.

<!-- evidence: docs/design/DES-001.json#Layercake.brnz_concession; docs/design/DES-001.json#1:1 landing of CE.vwConcessionType (working default source, Q-008), keyed on apuk_concessiontypeid; docs/specs/SPEC-001.json#REQ-010; docs/specs/SPEC-001.json#RULE-045; docs/answers.md#brnz_concession keeps apuk_concessiontypeid NOT NULL as its key; docs/answers.md#apuk_dualmembership (v2 Q-025); docs/test/TCS-MOD-006.json#TC-006-001; docs/test/TCS-MOD-006.json#TC-006-002; docs/test/TCS-MOD-006.json#TC-006-004; docs/test/TCS-MOD-006.json#TC-006-005; docs/test/TCS-MOD-006.json#TC-006-006; docs/test/TCS-MOD-006.json#TC-006-009; docs/answers.md#DES-001 Q-037 bronze audit columns -->

### Layercake.usp_load_brnz_concession

The load for brnz_concession. It works like the other bronze loads: on every run it compares the whole source with the table, by concession type id, and adds new rows, updates changed rows, marks rows gone from the source as deleted and makes reappearing rows live again. Unchanged rows are left alone, so a second run on unchanged data changes nothing. In addition:

- Values are compared exactly, so a change only in letter case or trailing spaces counts as one update.
- Making a deleted row live again counts as one update.
- The load checks that its live rows equal the number of source rows (RULE-005).
- A source row with no concession type id, or two source rows with the same id, fails the whole load before the table is touched, so it changes nothing; no row is skipped (see the Runbook and Known limitations).

It records its run in the load log like the other bronze loads.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_brnz_concession; docs/design/DES-001.json#Lands CE.vwConcessionType with the standard insert, update and soft-delete behaviour, row-count check and logging.; docs/test/TCS-MOD-006.json#TC-006-003; docs/test/TCS-MOD-006.json#TC-006-004; docs/test/TCS-MOD-006.json#TC-006-005; docs/test/TCS-MOD-006.json#TC-006-006; docs/test/TCS-MOD-006.json#TC-006-007; docs/test/TCS-MOD-006.json#TC-006-008; docs/dev/CN-MOD-006.json#Bronze and silver compare strings as bytes; docs/dev/CN-MOD-006.json#test trailing space change and restore are each one update in bronze; docs/dev/CN-MOD-006.json#Bronze stages the source in a temp table with the key NOT NULL and as primary key; docs/answers.md#MOD-006 NULL key, duplicate key and missing name -->

### Layercake.silv_ref_concession_type

The concession type list (REQ-010, RULE-046). Its migration puts in place four starting rows with fixed ids: the three reserved values, with the same ids and labels as in the payment method and payer type lists (RULE-078), and one 'No concession' row. Each concession type from the source is added with its own id, which never changes.

| Id | Label | Meaning |
|---|---|---|
| 0 | Unknown | The source has no value |
| -1 | Unrecognised | The source has a value the list does not know |
| -2 | Not applicable | No value is expected |
| 1 | No concession | The member holds no concession |
| 2 onward | (the source type's name) | One row per concession type in the source |

Each row holds:

| Column | Meaning |
|---|---|
| concession_type_bk | The source's concession type id; empty for the four starting rows |
| concession_type_name | The type's name. A source type with a missing, empty or blank name is listed as 'Unnamed concession type' |
| item_code | The code the type's lines carry on invoices: the source product number with any 'rcs' prefix removed (RULE-048), so 'rcsCONRETIRED' gives 'CONRETIRED' |
| is_full_concession | 1 where the source discount is exactly 100, otherwise 0 (RULE-047) |
| is_perpetual | 1 where the source marks the type Perpetual (200000000); 0 for any other value, including Non-Perpetual (200000001) and a missing value (RULE-094) |
| load_id | The load log entry of the load that last wrote the row; empty for the starting rows |

The four starting rows have no item code, and both flags are 0. For example, with the source types Retired (discount 100, perpetual), Exceptional Hardship (discount 50, non-perpetual) and Life Member (discount 100, no perpetual value), the list holds seven rows: Retired and Life Member are full concessions, Exceptional Hardship is not, and only Retired is perpetual.

<!-- evidence: docs/design/DES-001.json#Layercake.silv_ref_concession_type; docs/design/DES-001.json#Concession type list. Reserved rows 0 Unknown, -1 Unrecognised and -2 Not applicable, plus one 'No concession' row, are seeded by the migration with fixed ids.; docs/specs/SPEC-001.json#RULE-046; docs/specs/SPEC-001.json#RULE-078; docs/dev/CN-MOD-006.json#the migration seeds 0 Unknown, -1 Unrecognised, -2 Not applicable and 1 No concession; docs/dev/CN-MOD-006.json#source types get identity ids from 2; docs/design/DES-001.json#null for reserved rows and No concession; docs/answers.md#concession_type_name N'Unnamed concession type'; docs/design/DES-001.json#product_number with any 'rcs' prefix removed (RULE-048); docs/specs/SPEC-001.json#RULE-048; docs/specs/SPEC-001.json#RULE-047; docs/specs/SPEC-001.json#RULE-094; docs/design/DES-001.json#1 where apuk_discount = 100, else 0; docs/design/DES-001.json#1 where apuk_perpetualnonperpetual = 200000000, else 0 (null included); docs/answers.md#DES-001 load_id; docs/test/TCS-MOD-006.json#TC-006-010; docs/test/TCS-MOD-006.json#TC-006-011; docs/test/TCS-MOD-006.json#TC-006-017; docs/test/TCS-MOD-006.json#TC-006-029 -->

### Layercake.usp_load_silv_ref_concession_type

The load that keeps the concession type list up to date from brnz_concession (RULE-046). On each run it reads the live rows of brnz_concession and:

- adds each concession type not yet listed, with a new id;
- updates the name, item code and flags of a listed type where they have changed, on its existing id; values are compared exactly, so a rename only in letter case is an update;
- leaves unchanged rows and every id untouched, so a second run on unchanged data changes nothing;
- does not add a type that is marked as deleted in the bronze table, and keeps a listed type that has left the source unchanged;
- never changes the four starting rows;
- lists a type with a missing, empty or blank name as 'Unnamed concession type', and puts in the real name on the same id once the source gives one.

It sets load_id on the rows it adds or changes. It makes all its changes in one step and records its run in the load log, with the numbers of rows inserted and updated. A type whose item code is longer than the list holds (100 characters) fails the load, which changes nothing, rather than being cut (see Known limitations).

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_ref_concession_type; docs/design/DES-001.json#Inserts new concession types from live brnz_concession rows, updates name, item code and flags where they changed, and leaves unchanged rows and all ids untouched. Logged.; docs/specs/SPEC-001.json#RULE-046; docs/test/TCS-MOD-006.json#TC-006-012; docs/test/TCS-MOD-006.json#TC-006-013; docs/test/TCS-MOD-006.json#TC-006-014; docs/test/TCS-MOD-006.json#TC-006-018; docs/test/TCS-MOD-006.json#TC-006-019; docs/test/TCS-MOD-006.json#TC-006-020; docs/test/TCS-MOD-006.json#TC-006-021; docs/test/TCS-MOD-006.json#TC-006-022; docs/dev/CN-MOD-006.json#Seeded rows and types no longer live in bronze are never changed; docs/dev/CN-MOD-006.json#test soft deleted type and seeded rows are kept and a case only rename is stamped with the log id; docs/dev/CN-MOD-006.json#An item code longer than nvarchar(100) fails the load rather than being cut; docs/answers.md#MOD-006 NULL key, duplicate key and missing name -->

### Layercake.dim_concession_type

The gold copy of the concession type list for reporting: one row for each row of silv_ref_concession_type, the reserved values and 'No concession' included, with the same id, name, full-concession flag and perpetual flag, and load_id, the load log entry of the load that last wrote the row. It is not filled by its migration: it stays empty until usp_load_dim_concession_type first runs.

<!-- evidence: docs/design/DES-001.json#Layercake.dim_concession_type; docs/design/DES-001.json#Gold copy of silv_ref_concession_type.; docs/specs/SPEC-001.json#AC-010-05; docs/test/TCS-MOD-006.json#TC-006-023; docs/answers.md#DES-001 load_id; docs/dev/CN-MOD-006.json#The gold dimension is empty after the migration until usp_load_dim_concession_type runs -->

### Layercake.usp_load_dim_concession_type

The load that keeps dim_concession_type in step with silv_ref_concession_type, matching rows by id. On each run it adds any id the dimension lacks, corrects a name or flag that differs from the list (a change only in a flag counts as one update), and leaves unchanged rows untouched, so a second run changes nothing. It never removes a row, even one whose id has left the list (see Known limitations). It makes all its changes in one step and records its run in the load log; its deleted count is always 0.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_dim_concession_type; docs/design/DES-001.json#Mirrors silv_ref_concession_type into dim_concession_type. Logged.; docs/test/TCS-MOD-006.json#TC-006-024; docs/test/TCS-MOD-006.json#TC-006-025; docs/test/TCS-MOD-006.json#TC-006-026; docs/test/TCS-MOD-006.json#TC-006-028; docs/dev/CN-MOD-006.json#The dimension never deletes an id; docs/dev/CN-MOD-006.json#test dimension keeps an id no longer in silver and counts a flag only change as one update -->

### Layercake.usp_profile_custtrans_grain

A count-only profile of synapse_fo.CUSTTRANS_RICS, to help answer Q-021 (RULE-095, AC-014-07). It takes no parameters, reads only the source and writes nothing.

It looks only at invoice rows: rows with transaction type 8 or 24, and rows whose invoice number contains 'CRE' or 'FTCN', are left out. Each invoice is identified by account number and invoice number together, so one invoice number on two accounts counts as two invoices.

For each invoice it measures the number of rows (rows_per_invoice), the number of different item codes (distinct_productcodes) and whether the invoice has a 'Sales tax' row (has_sales_tax_row). It returns one row per measure and value, with the number of invoices that have that value; for example, how many invoices have 3 rows. It returns counts only, never individual invoices or contacts.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_profile_custtrans_grain; docs/specs/SPEC-001.json#RULE-095; docs/specs/SPEC-001.json#AC-014-07; docs/dev/CN-MOD-001.json#rows_per_invoice; docs/dev/CN-MOD-001.json#Result shape of both procedures is not defined in DES-001; docs/test/TCS-MOD-001.json#TC-001-001; docs/test/TCS-MOD-001.json#TC-001-002; docs/test/TCS-MOD-001.json#TC-001-003; docs/dev/CN-MOD-001.json#Neither takes parameters -->

### Layercake.usp_profile_corp_subscription_status

A count-only profile of Subs.vwCorpSubscriptions, to help answer Q-027 (RULE-096, AC-014-08). It takes no parameters, reads only the source and writes nothing. It counts source rows (not contacts) by each value of 'Sub Status' and by each value of 'Sub User Status', listing every value it finds, and returns one row per status column and value with its row count.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_profile_corp_subscription_status; docs/specs/SPEC-001.json#RULE-096; docs/specs/SPEC-001.json#AC-014-08; docs/test/TCS-MOD-001.json#TC-001-004; docs/test/TCS-MOD-001.json#TC-001-005; docs/dev/CN-MOD-001.json#Result shape of both procedures is not defined in DES-001 -->

## Design decisions

The design records its main decisions in architecture decision records (ADRs):

| Decision | What it means for the client |
|---|---|
| ADR-001 How segment keys and amounts reach the event tables | The Phase 1 loads stay as they are. All new loads run as one block after the Phase 1 run, through a new run procedure, Layercake.usp_run_payment_segments, which a person schedules after the Phase 1 run once a later module (MOD-016) delivers it. This keeps the Phase 1 logic unchanged, which is the main risk to Phase 1 results. The recommendation is provisional on Q-031: if a Phase 1 event or fact load rebuilds its table in full each run, the new columns would be written in that load instead. |
| ADR-003 Delivery of the count-only profiling and findings queries | The profiling and findings queries are built as read-only procedures in Layercake (Option A), rather than views or undeployed scripts, so they can be tested and are deployed and versioned with the solution. Running them needs only EXECUTE permission. They must be deployed to production before Mike can run them there. |

The decision on both records is still pending (see Known limitations).

<!-- evidence: docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Post-Phase-1 enrichment block; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Layercake.usp_run_payment_segments; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#which a human schedules after the Phase 1 run; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#provisional on Q-031; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Pending: filled in by a human at the architecture validation gate; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Read-only procedures with an as-of date; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Running them needs only EXECUTE; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#they must be deployed to production before Mike can run them there; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Pending: filled in by a human at the architecture validation gate -->
