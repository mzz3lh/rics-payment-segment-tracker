# Architecture and data model: RICS Payment Segment Tracker

## Architecture overview

The solution extends the Phase 1 Layercake membership solution. All new objects live in the Layercake schema and follow the Phase 1 naming conventions. The design has bronze tables (one-to-one landings of source data), silver tables (reference lists, attributes and matches), gold dimensions and fact columns, and a set of read-only reporting procedures that return aggregates only (counts, sums and rates). Every change ships as a migration with a tested rollback script.

Four layers are in place so far:

- **Reporting procedures (MOD-001):** two source profiles, named usp_profile_*. They read two sources owned by other systems (see the Data lineage document), write nothing and build no tables. They are meant to be run before the invoice build, so that their results can settle two open questions the build depends on (see Known limitations).
- **Bronze (MOD-002, MOD-004):** three tables, each with a load procedure. brnz_subs_invoice and brnz_subs_invoice_line copy subscription invoice data, and brnz_corporate_subscription copies the corporate scheme subscriptions, from sources already in the warehouse with no change to any value. They carry the same four audit columns as the Phase 1 bronze tables. Each load records its run in the load log, Layercake.etl_run_log.
- **Silver reference (MOD-003, MOD-004, MOD-005):** the payment method list, silv_ref_payment_method, and the payer type list, silv_ref_payer_type, fixed lists put in place by their migrations; fn_map_payment_method, which turns a source payment mode code into an entry on the payment method list; and two lists that grow from the bronze invoice data: the line-type mapping, silv_ref_invoice_line_type, which says what each invoice item code is for, and the currency list, silv_ref_currency. Each of these two has a load that only adds new codes and records its run in the load log.
- **Gold dimensions (MOD-003, MOD-004, MOD-005):** dim_payment_method, dim_payer_type and dim_currency, copies of their lists for reporting, each kept in step with its list by its load, which also records its run in the load log.

Later modules build the rest of the silver and gold layers on these objects, including working out each contact's payment method and payer type for each Campaign Year and the invoiced amounts on each event.

<!-- evidence: docs/design/DES-001.json#Extends the Phase 1 Layercake membership solution; docs/design/DES-001.json#reporting queries; docs/design/MP-001.json#Builds no tables and changes no existing object; docs/dev/CN-MOD-001.json#Neither writes anything; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#before the invoice build; docs/design/DES-001.json#1:1 landings of external sources; docs/specs/SPEC-001.json#RULE-004; docs/design/DES-001.json#load logging; docs/design/MP-001.json#Subscription invoice bronze; docs/design/MP-001.json#Payment method reference and dimension; docs/design/MP-001.json#Corporate subscription bronze and payer type reference; docs/design/MP-001.json#Invoice line-type mapping and currency; docs/design/DES-001.json#1:1 landing of Subs.vwCorpSubscriptions; docs/design/DES-001.json#Static list seeded by its migration; docs/design/DES-001.json#Maps a source payment mode code to a silv_ref_payment_method id; docs/design/DES-001.json#Item-code to line-type mapping, one row per (item_code, ric_invoice_type); docs/design/DES-001.json#Insert-only, identity ids that never change.; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type; docs/design/DES-001.json#Mirrors silv_ref_currency into dim_currency. Logged.; docs/design/MP-001.json#Does not derive any contact's payment method; docs/design/MP-001.json#Does not compute amounts -->

## Data model

MOD-001 adds two procedures and no tables. MOD-002 adds two bronze tables and two load procedures. MOD-003 adds a silver reference table, a mapping function, a gold dimension table and its load procedure. MOD-004 adds a bronze table and its load procedure, a silver reference table, and a gold dimension table and its load procedure. MOD-005 adds two silver reference tables and a gold dimension table, each with its load procedure. No existing object is changed.

<!-- evidence: docs/design/MP-001.json#Builds no tables and changes no existing object; docs/dev/CN-MOD-002.json#objects_changed; docs/dev/CN-MOD-003.json#objects_changed; docs/dev/CN-MOD-004.json#objects_changed; docs/dev/CN-MOD-005.json#objects_changed -->

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

<!-- evidence: docs/design/DES-001.json#Layercake.brnz_corporate_subscription; docs/design/DES-001.json#1:1 landing of Subs.vwCorpSubscriptions; docs/design/DES-001.json#'Round' is not landed and plays no part; docs/design/DES-001.json#The source has no row key; docs/specs/SPEC-001.json#REQ-006; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Contact No; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Sub User Status; docs/specs/SPEC-001.json#RULE-004; docs/answers.md#Do not use 'Round'; docs/answers.md#MOD-004 NULL matching key; docs/dev/CN-MOD-004.json#PK on contact_no, scheme_no, sub_campaign_year; docs/dev/CN-MOD-004.json#Q-033; docs/test/TCS-MOD-004.json#TC-004-009; docs/test/TCS-MOD-004.json#TC-004-011; docs/test/TCS-MOD-004.json#TC-004-012; docs/test/TCS-MOD-004.json#TC-004-016; docs/test/TCS-MOD-004.json#TC-004-017; docs/answers.md#DES-001 Q-037 bronze audit columns -->

### Layercake.usp_load_brnz_corporate_subscription

The load for brnz_corporate_subscription. It works like the other bronze loads: on every run it compares the whole source with the table, by contact number, scheme number and Campaign Year, and adds new rows, updates changed rows, marks rows gone from the source as deleted and makes a reappearing row live again. A second run on unchanged data changes nothing.

- Every value, the three identifying values included, is compared exactly, so a change only in letter case or trailing spaces is landed as a change. For one of the three identifying values, the row is updated in place.
- A row that differs from the landed row only in 'Round' is not a change.
- Making a deleted row live again counts as an update. A row already marked as deleted that is still missing from the source is left alone and not counted.
- The load checks that its live rows equal the number of source rows (RULE-005).
- A source row with a missing contact number, scheme number or Campaign Year, or two source rows with the same three values, fail the whole load, which changes nothing (see the Runbook and Known limitations).

It records its run in Layercake.etl_run_log in the same way as the other bronze loads.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_brnz_corporate_subscription; docs/test/TCS-MOD-004.json#TC-004-013; docs/test/TCS-MOD-004.json#TC-004-014; docs/test/TCS-MOD-004.json#TC-004-015; docs/test/TCS-MOD-004.json#TC-004-018; docs/test/TCS-MOD-004.json#TC-004-010; docs/test/TCS-MOD-004.json#TC-004-019; docs/dev/CN-MOD-004.json#All string columns, the key columns included, are compared as bytes; docs/dev/CN-MOD-004.json#for a key column that update rewrites the key in place; docs/dev/CN-MOD-004.json#Restoring a soft-deleted row counts as an update; docs/dev/CN-MOD-004.json#A row that is already soft-deleted and still missing from the source is not touched and not counted; docs/dev/CN-MOD-004.json#The live row count is checked against the source count (RULE-005); docs/dev/CN-MOD-004.json#A repeated key fails usp_load_brnz_corporate_subscription with error 2627; docs/answers.md#MOD-004 NULL matching key -->

### Layercake.silv_ref_payment_method

The list of payment methods (REQ-003), put in place by its migration. It holds the three reserved values that every segment list shares, and the five payment methods the dashboard filters on. Ids never change.

| Id | Label | Meaning |
|---|---|---|
| 0 | Unknown | The source has no value |
| -1 | Unrecognised | The source has a value the mapping does not know |
| -2 | Not applicable | No value is expected |

| Payment method | Source payment mode code | Id |
|---|---|---|
| Direct Debit | DD | 1 |
| Card | Card | 2 |
| Bank transfer | Bank | 3 |
| Cheque | Cheque | 4 |
| Corporate | Corporate | 5 |

Each method row carries the source code it maps from, which the mapping function reads. There is no Mixed method, an assumption awaiting Q-015 (see Known limitations). A method added later would take the next id, from 6.

<!-- evidence: docs/design/DES-001.json#Layercake.silv_ref_payment_method; docs/design/DES-001.json#Static list seeded by its migration; docs/specs/SPEC-001.json#RULE-006; docs/specs/SPEC-001.json#RULE-078; docs/specs/SPEC-001.json#Reserved values; docs/specs/SPEC-001.json#There is no Mixed value (assumes Q-015).; docs/test/TCS-MOD-003.json#TC-003-001; docs/test/TCS-MOD-003.json#The five method ids are exactly 1, 2, 3, 4 and 5; docs/test/TCS-MOD-003.json#TC-003-002; docs/test/TCS-MOD-003.json#TC-003-004; docs/dev/CN-MOD-003.json#explicit ids 0, -1, -2 and 1 to 5; docs/dev/CN-MOD-003.json#so the identity continues from 6; docs/design/DES-001.json#source_code -->

### Layercake.fn_map_payment_method

Turns one source payment mode code (from brnz_subs_invoice.inv_payment_method or brnz_subs_invoice_line.paymmode) into a payment method id (RULE-007, RULE-008). It reads the source codes from silv_ref_payment_method, so a method added to the list later maps without a change to the function.

- The code is compared ignoring letter case and spaces before or after it: 'dd', ' DD' and 'Card ' map to their method.
- A missing code, an empty code or one of spaces only maps to 0 Unknown.
- Any other code maps to -1 Unrecognised. Only spaces are ignored: a tab, a line break or a space inside a code makes it Unrecognised (see Known limitations).
- It never returns a reserved value other than Unknown or Unrecognised by matching a code, so Not applicable (-2) is never its result.

Later modules use the function inside their loads; it is not run on its own.

<!-- evidence: docs/design/DES-001.json#Layercake.fn_map_payment_method; docs/design/DES-001.json#Maps a source payment mode code to a silv_ref_payment_method id; docs/answers.md#MOD-003 fn_map_payment_method; docs/answers.md#A code that is empty or only spaces maps to 0 Unknown; docs/specs/SPEC-001.json#RULE-007; docs/specs/SPEC-001.json#Any other source code maps to Unrecognised (-1); docs/test/TCS-MOD-003.json#TC-003-003; docs/test/TCS-MOD-003.json#TC-003-005; docs/test/TCS-MOD-003.json#TC-003-013; docs/dev/CN-MOD-003.json#It never matches a reserved row; docs/dev/CN-MOD-003.json#It trims only spaces: a tab, a line break or a space inside the code gives -1 -->

### Layercake.dim_payment_method

The gold copy of the payment method list for reporting (REQ-003, RULE-010): one row for each row of silv_ref_payment_method, reserved values included, with the same id and the same name. Each row also carries load_id, the load log entry of the load that last wrote it, and its created and updated times. The source payment mode code is not copied. The dimension is not filled by its migration: it stays empty until its load is first run.

<!-- evidence: docs/specs/SPEC-001.json#RULE-010; docs/specs/SPEC-001.json#dim_payment_method holds one row per silv_ref_payment_method row; docs/design/DES-001.json#payment_method_name; docs/answers.md#DES-001 load_id; docs/answers.md#MOD-003 dim_payment_method population; docs/dev/CN-MOD-003.json#keeps created_at; docs/test/TCS-MOD-003.json#TC-003-012 -->

### Layercake.usp_load_dim_payment_method

The load that keeps dim_payment_method in step with silv_ref_payment_method. On each run it:

- adds any id in the list that the dimension lacks;
- corrects a name that differs from the list, including a difference only in letter case or trailing spaces;
- leaves unchanged rows untouched, so a second run changes nothing;
- never removes a row: an id no longer in the list stays in the dimension, because reporting data may still point to it (see Known limitations).

It sets load_id and the updated time only on rows it adds or corrects, and keeps each row's created time. It makes all its changes in one step and records its run in the load log; its deleted count is always 0.

<!-- evidence: docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/design/DES-001.json#inserts missing ids, updates changed names, leaves unchanged rows untouched; docs/test/TCS-MOD-003.json#TC-003-007; docs/test/TCS-MOD-003.json#TC-003-008; docs/test/TCS-MOD-003.json#TC-003-009; docs/test/TCS-MOD-003.json#TC-003-010; docs/dev/CN-MOD-003.json#compares names as bytes; docs/dev/CN-MOD-003.json#It never deletes: a dimension id no longer in silver stays (rows_deleted is always 0), because facts may still point at it; docs/dev/CN-MOD-003.json#The update and insert run in one transaction, so a failure also rolls back an update already made -->

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

<!-- evidence: docs/design/DES-001.json#Layercake.silv_ref_payer_type; docs/specs/SPEC-001.json#RULE-020; docs/dev/CN-MOD-004.json#0 Unknown, -1 Unrecognised, -2 Not applicable, 1 Individual, 2 Corporate; docs/test/TCS-MOD-004.json#TC-004-001; docs/specs/SPEC-001.json#Reserved values -->

### Layercake.dim_payer_type

The gold copy of the payer type list for reporting: one row for each row of silv_ref_payer_type, reserved values included, with the same id and name, and load_id, the load log entry of the load that last wrote the row. Like the payment method dimension, it is not filled by its migration and stays empty until its load is first run.

<!-- evidence: docs/design/DES-001.json#Layercake.dim_payer_type; docs/test/TCS-MOD-004.json#TC-004-007; docs/answers.md#DES-001 load_id; docs/dev/CN-MOD-004.json#dim_payer_type is not seeded -->

### Layercake.usp_load_dim_payer_type

The load that keeps dim_payer_type in step with silv_ref_payer_type. It works the same way as usp_load_dim_payment_method: it adds missing ids, corrects changed names (including changes only in letter case or trailing spaces), leaves unchanged rows untouched, never removes a row, makes all its changes in one step and records its run in the load log.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_dim_payer_type; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type, as the payment method dimension load does.; docs/dev/CN-MOD-004.json#same pattern as usp_load_dim_payment_method; docs/dev/CN-MOD-004.json#The load never deletes from the dimension; docs/test/TCS-MOD-004.json#TC-004-004; docs/test/TCS-MOD-004.json#TC-004-005; docs/test/TCS-MOD-004.json#TC-004-006 -->

### Layercake.silv_ref_invoice_line_type

The line-type mapping (REQ-007, RULE-028): it says what each invoice item code is for, so that a later module (MOD-010) can split an invoice's amount into subscription, fee and other parts. One row per pair of item code (productcode) and RIC invoice type (ricinvoicetype), with its line type. The line type is one of seven values: subscription, concession, readmission fee, enrolment or application fee, tax, other, or unmapped. The table accepts no other value.

Each row also carries load_id (the load log entry of the load that added it; empty for the starting rows) and its created and updated times.

**Starting content.** The curated mapping the design expects is not yet available (Q-034). As a working assumption awaiting Q-034, the mapping starts with only the 12 pairs that the existing Subs.usp_Refresh_SubsInvoices code names exactly, all with RIC invoice type 'SUB':

| Item codes | Line type |
|---|---|
| RAFEE_ACAND, RAFEE_APCC, RAFEE_ASSOC, RAFEE_FRICS, RAFEE_MRICS, RAFEE_PMU2 | readmission fee |
| CONPWRQ1, CONPWRQ2, CONPWRQ3, CONRETIRED, CONRETIREDFL, CONRETIREDSPECIAL | concession |

Every other code, the subscription codes included, is added as 'unmapped' by the first load, and must be mapped by hand (see Known limitations).

**Mapping by hand.** A person changes the line type on a row from 'unmapped' to the right value. The load never overwrites an existing row, so a hand mapping is kept on every later run (AC-007-02). Until a code is mapped, the amounts on its lines are left out of the subscription and fee amounts, and the event is flagged 'Unmapped lines' (RULE-030, as Q-016 was answered), so the lower figure is explained rather than lost unseen.

<!-- evidence: docs/design/DES-001.json#Layercake.silv_ref_invoice_line_type; docs/design/DES-001.json#Item-code to line-type mapping, one row per (item_code, ric_invoice_type); docs/specs/SPEC-001.json#REQ-007; docs/specs/SPEC-001.json#RULE-028; docs/specs/SPEC-001.json#RULE-030; docs/specs/SPEC-001.json#Left out until mapped; docs/specs/SPEC-001.json#AC-007-02; docs/dev/CN-MOD-005.json#PK item_code + ric_invoice_type; docs/dev/CN-MOD-005.json#named CHECK on the seven line types; docs/dev/CN-MOD-005.json#Q-034; docs/dev/CN-MOD-005.json#RAFEE_ACAND; docs/dev/CN-MOD-005.json#CONPWRQ1; docs/dev/CN-MOD-005.json#with load_id NULL; docs/dev/CN-MOD-005.json#must be mapped by hand before MOD-010's amounts are complete; docs/design/DES-001.json#Q-034; docs/answers.md#DES-001 load_id; docs/design/MP-001.json#mapped rows never overwritten; docs/test/TCS-MOD-005.json#TC-005-013 -->

### Layercake.usp_load_silv_ref_invoice_line_type

The load that adds new item codes to the line-type mapping (RULE-029). On each run it reads the live rows of brnz_subs_invoice_line (rows marked as deleted are ignored) and adds each pair of item code and RIC invoice type not yet in the mapping, with line type 'unmapped'. It only adds rows: it never changes or removes an existing one, whether it is mapped, still 'unmapped', or no longer seen on any line.

- A line with no item code (missing, empty or only spaces) adds nothing.
- A line with an item code but no RIC invoice type is not skipped: it is added with an empty RIC invoice type and line type 'unmapped', so the invoice is flagged rather than its amount lost unseen. Later loads that read the mapping treat a missing RIC invoice type as empty in the same way.
- Codes are matched ignoring letter case and trailing spaces: a code that differs from a listed pair only in those ways is that pair and takes its line type. A code with different leading spaces or other characters is a new code and is added as 'unmapped'.
- One code on many lines adds one row per pair; the same code with a different RIC invoice type is a separate pair.
- When one new code arrives in several spellings in the same run, one row is added, and the same spelling is kept on every run: upper case first, then the one without trailing spaces (see Known limitations).

It makes all its changes in one step and records its run in the load log, with the number of rows added.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_ref_invoice_line_type; docs/design/DES-001.json#Existing rows are never changed; docs/specs/SPEC-001.json#RULE-029; docs/answers.md#MOD-005 NULL, blank and near-duplicate codes; docs/answers.md#treats a NULL ricinvoicetype as N''; docs/answers.md#Codes are matched as the database collation compares them; docs/dev/CN-MOD-005.json#A NULL ricinvoicetype is stored as N''; docs/dev/CN-MOD-005.json#the spelling with the lowest byte value is kept; docs/dev/CN-MOD-005.json#are insert-only, read only live (_is_deleted = 0) bronze rows; docs/test/TCS-MOD-005.json#TC-005-003; docs/test/TCS-MOD-005.json#TC-005-005; docs/test/TCS-MOD-005.json#TC-005-006; docs/test/TCS-MOD-005.json#TC-005-007; docs/test/TCS-MOD-005.json#TC-005-008; docs/test/TCS-MOD-005.json#TC-005-009; docs/test/TCS-MOD-005.json#TC-005-012 -->

### Layercake.silv_ref_currency

The currency list (REQ-007, RULE-031): one row per currency code found on the subscription invoices (brnz_subs_invoice.inv_currency), each with its own id, which never changes between loads. Each row also carries load_id and its created time. It has no reserved values and nothing is put in it by its migration; it is filled by its load.

<!-- evidence: docs/design/DES-001.json#Layercake.silv_ref_currency; docs/design/DES-001.json#One row per currency code found on subscription invoices (brnz_subs_invoice.inv_currency). Insert-only, identity ids that never change.; docs/specs/SPEC-001.json#RULE-031; docs/dev/CN-MOD-005.json#identity id, UNIQUE currency_code; docs/test/TCS-MOD-005.json#TC-005-016; docs/answers.md#DES-001 load_id -->

### Layercake.usp_load_silv_ref_currency

The load that adds new currencies to the currency list. It reads the live rows of brnz_subs_invoice and adds each currency code not yet listed, with a new id; listed currencies keep their ids. It only adds rows and never changes or removes one.

- An invoice with no currency (missing, empty or only spaces) adds nothing.
- Codes are matched ignoring letter case and trailing spaces, so 'eur' adds nothing when 'EUR' is listed. A new code arriving in several spellings in one run adds one row, kept in upper case.
- A currency seen only on an invoice marked as deleted adds nothing.

It makes all its changes in one step and records its run in the load log.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_ref_currency; docs/answers.md#usp_load_silv_ref_currency works the same way; docs/dev/CN-MOD-005.json#are insert-only, read only live (_is_deleted = 0) bronze rows; docs/test/TCS-MOD-005.json#TC-005-020; docs/test/TCS-MOD-005.json#TC-005-021; docs/test/TCS-MOD-005.json#TC-005-022; docs/test/TCS-MOD-005.json#TC-005-023; docs/test/TCS-MOD-005.json#TC-005-024; docs/dev/CN-MOD-005.json#test currency spellings of one new code keep the upper case spelling and the load log id -->

### Layercake.dim_currency

The gold copy of the currency list for reporting: one row for each row of silv_ref_currency, with the same id and currency code, and load_id, the load log entry of the load that last wrote the row. It is not filled by its migration and stays empty until the currency list load and then its own load have run.

<!-- evidence: docs/design/DES-001.json#Gold copy of silv_ref_currency.; docs/design/MP-001.json#Layercake.dim_currency; docs/test/TCS-MOD-005.json#TC-005-017; docs/answers.md#DES-001 load_id; docs/dev/CN-MOD-005.json#dim_currency is empty after the migration -->

### Layercake.usp_load_dim_currency

The load that keeps dim_currency in step with silv_ref_currency, matching rows by id. On each run it adds any id the dimension lacks, corrects a code that differs from the list (including a difference only in letter case), and leaves unchanged rows untouched, so a second run changes nothing. It never removes a row (see Known limitations). It makes all its changes in one step, so a failure also undoes a correction already made in that run, and records its run in the load log.

<!-- evidence: docs/design/DES-001.json#Mirrors silv_ref_currency into dim_currency. Logged.; docs/design/MP-001.json#Layercake.usp_load_dim_currency; docs/dev/CN-MOD-005.json#usp_load_dim_currency mirrors silver by id; docs/dev/CN-MOD-005.json#updates a code only when its bytes differ; docs/dev/CN-MOD-005.json#test failed dim_currency insert also rolls back the update made before it; docs/test/TCS-MOD-005.json#TC-005-018; docs/test/TCS-MOD-005.json#TC-005-019 -->

### Layercake.usp_profile_custtrans_grain

A count-only profile of synapse_fo.CUSTTRANS_RICS, to help answer Q-021 (RULE-095, AC-014-07). It takes no parameters, reads only the source and writes nothing.

It looks only at invoice rows: rows of transaction type 8 or 24, rows whose invoice number contains 'CRE' or 'FTCN', and rows with no transaction type or no invoice number are left out. An invoice is identified by its account number and invoice number together, so one invoice number on two accounts counts as two invoices.

For each invoice it measures the number of rows (rows_per_invoice), the number of different item codes (distinct_productcodes) and whether the invoice has a 'Sales tax' row (has_sales_tax_row). It returns one row per measure and value, with the number of invoices that have it: three columns, measure, measure_value and invoice_count. A missing item code is not counted as an item code. With no invoice rows, it returns nothing.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_profile_custtrans_grain; docs/specs/SPEC-001.json#RULE-095; docs/specs/SPEC-001.json#AC-014-07; docs/dev/CN-MOD-001.json#rows_per_invoice; docs/dev/CN-MOD-001.json#Neither takes parameters; docs/dev/CN-MOD-001.json#Neither writes anything; docs/dev/CN-MOD-001.json#PostingType_Description = 'Sales tax'; docs/dev/CN-MOD-001.json#test grain profile leaves out rows with no TRANSTYPE or no INVOICE; docs/dev/CN-MOD-001.json#test grain profile returns no rows when there are no invoice rows; docs/test/TCS-MOD-001.json#TC-001-002; docs/test/TCS-MOD-001.json#TC-001-003 -->

### Layercake.usp_profile_corp_subscription_status

A count-only profile of Subs.vwCorpSubscriptions, to help answer Q-027 (RULE-096, AC-014-08). It takes no parameters, reads only the source and writes nothing. It counts source rows (not contacts) by each value of 'Sub Status' and by each value of 'Sub User Status', and lists every value it finds, a missing status as a value of its own. It returns three columns: status_column, status_value and row_count.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_profile_corp_subscription_status; docs/specs/SPEC-001.json#RULE-096; docs/specs/SPEC-001.json#AC-014-08; docs/dev/CN-MOD-001.json#status_column varchar(50); docs/dev/CN-MOD-001.json#test corporate status profile lists a missing status as its own NULL value; docs/test/TCS-MOD-001.json#TC-001-004; docs/test/TCS-MOD-001.json#TC-001-005 -->

## Design decisions

The main design choices are recorded as architecture decision records (ADR-nnn). Those that shape the modules delivered so far:

| Decision | What it means | Status |
|---|---|---|
| ADR-001 How segment keys and amounts reach the event tables | The Phase 1 loads stay as they are. All new loads run as one block after the Phase 1 run, through a new run procedure, Layercake.usp_run_payment_segments (MOD-016), and two new procedures write the new columns onto the event tables (MOD-012). This keeps the Phase 1 logic unchanged. The recommendation is provisional on Q-031: if a Phase 1 event or fact load rebuilds its table in full each run, that table's load would be extended in place instead. | Recommended; the decision record is still marked as pending (see Known limitations) |
| ADR-003 Delivery of the count-only profiling and findings queries | The profiling and findings queries are built as read-only procedures in Layercake (Option A), rather than views or undeployed scripts, so they can be tested, give fixed results for a given date, and are versioned with the solution. Running them needs only EXECUTE permission, and they must be deployed to production before they can be run there. | Recommended; the decision record is still marked as pending (see Known limitations) |

<!-- evidence: docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Post-Phase-1 enrichment block; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Layercake.usp_run_payment_segments; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#provisional on Q-031; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Pending: filled in by a human at the architecture validation gate; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Read-only procedures with an as-of date; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Running them needs only EXECUTE; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#they must be deployed to production before Mike can run them there; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Pending: filled in by a human at the architecture validation gate -->
