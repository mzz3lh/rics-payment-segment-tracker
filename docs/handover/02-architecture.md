# Architecture and data model: RICS Payment Segment Tracker

## Architecture overview

The solution extends the Phase 1 Layercake membership solution. All new objects live in the Layercake schema and follow the Phase 1 naming conventions. The design has bronze tables (one-to-one landings of source data), silver tables (reference lists, attributes and matches), gold dimensions and fact columns, and a set of read-only reporting procedures that return aggregates only (counts, sums and rates). Every change ships as a migration with a tested rollback script.

Four layers are in place so far:

- **Reporting procedures (MOD-001):** two source profiles, named usp_profile_*. They read two sources owned by other systems (see the Data lineage document), write nothing and build no tables. They are meant to be run before the invoice build, so that their results can settle two open questions the build depends on (see Known limitations).
- **Bronze (MOD-002, MOD-004):** three tables, each with a load procedure. brnz_subs_invoice and brnz_subs_invoice_line copy subscription invoice data, and brnz_corporate_subscription copies the corporate scheme subscriptions, from sources already in the warehouse with no change to any value. They carry the same four audit columns as the Phase 1 bronze tables. Each load records its run in the load log, Layercake.etl_run_log.
- **Silver reference (MOD-003, MOD-004):** the payment method list, silv_ref_payment_method, and the payer type list, silv_ref_payer_type, fixed lists put in place by their migrations; and fn_map_payment_method, which turns a source payment mode code into an entry on the payment method list.
- **Gold dimensions (MOD-003, MOD-004):** dim_payment_method and dim_payer_type, copies of the two lists for reporting, each kept in step with its list by its load, which also records its run in the load log.

Later modules build the rest of the silver and gold layers on these objects, including working out each contact's payment method and payer type for each Campaign Year.

<!-- evidence: docs/design/DES-001.json#Extends the Phase 1 Layercake membership solution; docs/design/DES-001.json#reporting queries; docs/design/MP-001.json#Builds no tables and changes no existing object; docs/dev/CN-MOD-001.json#Neither writes anything; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#before the invoice build; docs/design/DES-001.json#1:1 landings of external sources; docs/specs/SPEC-001.json#RULE-004; docs/design/DES-001.json#load logging; docs/design/MP-001.json#Subscription invoice bronze; docs/design/MP-001.json#Payment method reference and dimension; docs/design/MP-001.json#Corporate subscription bronze and payer type reference; docs/design/DES-001.json#1:1 landing of Subs.vwCorpSubscriptions; docs/design/DES-001.json#Static list seeded by its migration; docs/design/DES-001.json#Reference lists: payment method and payer type are static lists seeded by their migrations; docs/design/DES-001.json#Maps a source payment mode code to a silv_ref_payment_method id; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type; docs/design/MP-001.json#Does not derive any contact's payment method; docs/design/MP-001.json#Does not derive payer type. -->

## Data model

MOD-001 adds two procedures and no tables. MOD-002 adds two bronze tables and two load procedures. MOD-003 adds a silver reference table, a mapping function, a gold dimension table and its load procedure. MOD-004 adds a bronze table and its load procedure, a silver reference table, and a gold dimension table and its load procedure. No existing object is changed.

<!-- evidence: docs/design/MP-001.json#Builds no tables and changes no existing object; docs/dev/CN-MOD-002.json#objects_changed; docs/dev/CN-MOD-003.json#objects_changed; docs/dev/CN-MOD-004.json#objects_changed -->

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

The load for brnz_corporate_subscription. It works like the other bronze loads: on every run it compares the whole source with the table, by contact number, scheme number and Campaign Year, and adds new rows, updates changed rows, marks rows gone from the source as deleted and makes reappearing rows live again. A second run on unchanged data changes nothing.

- A change in the scheme name or either status is an update to the existing row; a new scheme or a new Campaign Year for a contact is a new row.
- A change only in letter case or in trailing spaces counts as a change and is landed. This includes the contact number and scheme number: such a change updates the existing row rather than adding a new one.
- A change only in 'Round' is not a change, because Round is not landed.
- Making a deleted row live again counts as an update. A row that is already marked as deleted and is still missing from the source is left alone and not counted.

It checks that its live rows equal the number of source rows (RULE-005) and records one row in Layercake.etl_run_log with its outcome and counts. Before writing anything, it checks every source row: a row with no contact number, scheme number or Campaign Year, or two rows with the same three values, fail the whole load, which then changes nothing (see the Runbook).

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_brnz_corporate_subscription; docs/design/DES-001.json#full comparison with the source on its key on every run; docs/test/TCS-MOD-004.json#TC-004-013; docs/test/TCS-MOD-004.json#TC-004-014; docs/test/TCS-MOD-004.json#TC-004-015; docs/test/TCS-MOD-004.json#TC-004-018; docs/test/TCS-MOD-004.json#TC-004-010; docs/test/TCS-MOD-004.json#TC-004-019; docs/dev/CN-MOD-004.json#All string columns, the key columns included, are compared as bytes; docs/dev/CN-MOD-004.json#for a key column that update rewrites the key in place; docs/dev/CN-MOD-004.json#Restoring a soft-deleted row counts as an update; docs/dev/CN-MOD-004.json#A row that is already soft-deleted and still missing from the source is not touched and not counted; docs/dev/CN-MOD-004.json#The live row count is checked against the source count (RULE-005); docs/specs/SPEC-001.json#RULE-005; docs/answers.md#MOD-004 NULL matching key; docs/dev/CN-MOD-004.json#A repeated key fails usp_load_brnz_corporate_subscription with error 2627 -->

### Layercake.silv_ref_payment_method

The list of payment methods (REQ-003). It is a fixed list, put in place by the module's migration rather than by a load, and its ids never change. It holds exactly eight rows: three reserved values and the five payment methods.

The reserved values have fixed ids and labels, which are to be the same in every segment list: payment method, payer type and concession type (RULE-006, RULE-078).

| Id | Label | Meaning |
|---|---|---|
| 0 | Unknown | The source has no value |
| -1 | Unrecognised | The source has a value the mapping does not know |
| -2 | Not applicable | No value is expected |

The five payment methods have the ids 1 to 5. Each carries the source payment mode code it is mapped from:

| Payment method | Source payment mode code |
|---|---|
| Direct Debit | DD |
| Card | Card |
| Bank transfer | Bank |
| Cheque | Cheque |
| Corporate | Corporate |

There is no Mixed payment method, an assumption awaiting Q-015 (RULE-009, see Known limitations). Each row also records when it was created.

<!-- evidence: docs/design/DES-001.json#Layercake.silv_ref_payment_method; docs/design/DES-001.json#Static list seeded by its migration; docs/design/DES-001.json#Reference lists: payment method and payer type are static lists seeded by their migrations; docs/specs/SPEC-001.json#RULE-006; docs/specs/SPEC-001.json#RULE-078; docs/specs/SPEC-001.json#Reserved values; docs/specs/SPEC-001.json#There is no Mixed value (assumes Q-015).; docs/test/TCS-MOD-003.json#TC-003-001; docs/test/TCS-MOD-003.json#The five method ids are exactly 1, 2, 3, 4 and 5; docs/test/TCS-MOD-003.json#TC-003-002; docs/test/TCS-MOD-003.json#TC-003-004; docs/dev/CN-MOD-003.json#explicit ids 0, -1, -2 and 1 to 5; docs/design/DES-001.json#source_code; docs/design/DES-001.json#created_at -->

### Layercake.fn_map_payment_method

A function that turns one source payment mode code into a payment method id from silv_ref_payment_method (RULE-007 to RULE-009). It is to be used on the payment mode of an invoice (brnz_subs_invoice.inv_payment_method) and of a payment line (brnz_subs_invoice_line.paymmode); later modules apply it.

- The five codes DD, Card, Bank, Cheque and Corporate map to their methods (see the table above). The comparison ignores letter case and any spaces before or after the code, so 'dd', ' DD' and 'Card ' map to their methods.
- A missing code, an empty code, or a code of spaces only maps to 0 Unknown.
- Any other code maps to -1 Unrecognised, so codes the mapping does not know stay visible and separate from missing values. This includes method names used as codes (for example 'Direct Debit'), partial or extended codes (for example 'D' or 'DDX'), 'Mixed', and the reserved labels themselves.

The function reads the codes from the list itself, and never matches a code to a reserved row. Only spaces are removed before the comparison (see Known limitations).

<!-- evidence: docs/design/DES-001.json#Layercake.fn_map_payment_method; docs/design/DES-001.json#Maps a source payment mode code to a silv_ref_payment_method id; docs/answers.md#MOD-003 fn_map_payment_method; docs/answers.md#A code that is empty or only spaces maps to 0 Unknown; docs/specs/SPEC-001.json#RULE-007; docs/specs/SPEC-001.json#Any other source code maps to Unrecognised (-1); docs/test/TCS-MOD-003.json#TC-003-003; docs/test/TCS-MOD-003.json#TC-003-005; docs/test/TCS-MOD-003.json#TC-003-006; docs/test/TCS-MOD-003.json#TC-003-013; docs/dev/CN-MOD-003.json#fn_map_payment_method reads source_code from silv_ref_payment_method; docs/dev/CN-MOD-003.json#It never matches a reserved row -->

### Layercake.dim_payment_method

The gold copy of the payment method list for reporting (REQ-003, RULE-010): one row for each row of silv_ref_payment_method, reserved values included, with the same id and the same name. Each row also records load_id, the load log entry of the load run that last wrote it, and when it was created and last updated. The dimension is not filled by its migration: it is empty until its load is first run (see the Runbook).

<!-- evidence: docs/design/DES-001.json#Layercake.dim_payment_method; docs/specs/SPEC-001.json#RULE-010; docs/specs/SPEC-001.json#dim_payment_method holds one row per silv_ref_payment_method row; docs/test/TCS-MOD-003.json#TC-003-007; docs/test/TCS-MOD-003.json#TC-003-012; docs/answers.md#DES-001 load_id; docs/design/DES-001.json#load_id; docs/answers.md#MOD-003 dim_payment_method population -->

### Layercake.usp_load_dim_payment_method

The load that keeps dim_payment_method in step with silv_ref_payment_method. On each run it:

- adds any id in the list that is missing from the dimension;
- corrects a name that differs from the list's in any way, including only in letter case or trailing spaces, keeping its id;
- leaves unchanged rows alone, so a second run changes nothing;
- never removes a row, even if its id has left the list (see Known limitations).

It sets load_id and the updated time only on rows it adds or corrects, and keeps each row's created time. It makes all its changes in one step and records its run in the load log; its deleted count is always 0.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_dim_payment_method; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method: inserts missing ids, updates changed names, leaves unchanged rows untouched. Logged.; docs/test/TCS-MOD-003.json#TC-003-008; docs/test/TCS-MOD-003.json#TC-003-009; docs/test/TCS-MOD-003.json#TC-003-010; docs/dev/CN-MOD-003.json#compares names as bytes; docs/dev/CN-MOD-003.json#It never deletes; docs/dev/CN-MOD-003.json#rows_deleted is always 0; docs/dev/CN-MOD-003.json#keeps created_at; docs/dev/CN-MOD-003.json#The update and insert run in one transaction -->

### Layercake.silv_ref_payer_type

The list of payer types (REQ-006, RULE-020). Like the payment method list, it is a fixed list put in place by the module's migration, and its ids never change. It holds exactly five rows:

| Id | Label |
|---|---|
| 0 | Unknown |
| -1 | Unrecognised |
| -2 | Not applicable |
| 1 | Individual |
| 2 | Corporate |

The three reserved values have the same ids and labels as in the payment method list (see silv_ref_payment_method above).

<!-- evidence: docs/design/DES-001.json#Layercake.silv_ref_payer_type; docs/design/DES-001.json#Reference lists: payment method and payer type are static lists seeded by their migrations; docs/specs/SPEC-001.json#RULE-020; docs/specs/SPEC-001.json#silv_ref_payer_type holds the reserved rows 0 Unknown, -1 Unrecognised and -2 Not applicable, plus Individual and Corporate.; docs/specs/SPEC-001.json#RULE-078; docs/dev/CN-MOD-004.json#0 Unknown, -1 Unrecognised, -2 Not applicable, 1 Individual, 2 Corporate; docs/test/TCS-MOD-004.json#TC-004-001 -->

### Layercake.dim_payer_type

The gold copy of the payer type list for reporting (REQ-006): one row for each row of silv_ref_payer_type, reserved values included, with the same id and the same name. Like dim_payment_method, each row records load_id and when it was created and last updated, and the dimension is empty until its load is first run (see the Runbook).

<!-- evidence: docs/design/DES-001.json#Layercake.dim_payer_type; docs/design/DES-001.json#Gold copy of silv_ref_payer_type.; docs/specs/SPEC-001.json#AC-006-01; docs/test/TCS-MOD-004.json#TC-004-007; docs/answers.md#DES-001 load_id; docs/dev/CN-MOD-004.json#dim_payer_type is not seeded; docs/answers.md#The same applies to the other gold dimensions over seeded reference lists -->

### Layercake.usp_load_dim_payer_type

The load that keeps dim_payer_type in step with silv_ref_payer_type. It works the same way as usp_load_dim_payment_method: it adds missing ids, corrects changed names (including changes only in letter case or trailing spaces) on their existing ids, leaves unchanged rows alone, never removes a row, makes all its changes in one step and records its run in the load log.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_dim_payer_type; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type, as the payment method dimension load does.; docs/dev/CN-MOD-004.json#same pattern as usp_load_dim_payment_method; docs/dev/CN-MOD-004.json#The load never deletes from the dimension; docs/test/TCS-MOD-004.json#TC-004-003; docs/test/TCS-MOD-004.json#TC-004-004; docs/test/TCS-MOD-004.json#TC-004-005; docs/test/TCS-MOD-004.json#TC-004-006 -->

### Layercake.usp_profile_custtrans_grain

A read-only profile of synapse_fo.CUSTTRANS_RICS, to help answer Q-021 about the source's grain (REQ-014, RULE-095). It looks at invoice rows only, leaving out transaction types 8 and 24 and invoice numbers containing 'CRE' or 'FTCN'. It identifies an invoice by its account number and invoice number together, so one invoice number on two accounts counts as two invoices.

For each invoice it measures the number of rows (rows_per_invoice), the number of different item codes (distinct_productcodes) and whether the invoice has a 'Sales tax' row (has_sales_tax_row). It returns, for each measure and value, the number of invoices (invoice_count). It takes no parameters, returns counts only and writes nothing. The layout of its results is not yet confirmed (see Known limitations).

<!-- evidence: docs/design/DES-001.json#Layercake.usp_profile_custtrans_grain; docs/specs/SPEC-001.json#RULE-095; docs/dev/CN-MOD-001.json#rows_per_invoice; docs/dev/CN-MOD-001.json#Neither takes parameters; docs/test/TCS-MOD-001.json#TC-001-002; docs/test/TCS-MOD-001.json#TC-001-003; docs/dev/CN-MOD-001.json#Result shape of both procedures is not defined in DES-001 -->

### Layercake.usp_profile_corp_subscription_status

A read-only profile of Subs.vwCorpSubscriptions, to help answer Q-027 about which status values mean active (REQ-014, RULE-096). It counts source rows, not contacts, by each value of 'Sub Status' and of 'Sub User Status', and lists every value it finds, with a missing status as its own value. It returns the status column, the status value and the number of rows (status_column, status_value, row_count). It takes no parameters, returns counts only and writes nothing.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_profile_corp_subscription_status; docs/specs/SPEC-001.json#RULE-096; docs/specs/SPEC-001.json#Q-027; docs/dev/CN-MOD-001.json#status_column; docs/test/TCS-MOD-001.json#TC-001-005; docs/dev/CN-MOD-001.json#lists a missing status as its own NULL value -->

## Design decisions

The design records its main choices as architecture decision records (ADR-nnn). Those that affect the modules delivered so far:

| Decision | What was chosen | What it means for the modules delivered so far |
|---|---|---|
| ADR-001 How segment keys and amounts reach the event tables | The Phase 1 loads stay as they are. All new loads run as one block after the Phase 1 run, through a new run procedure, Layercake.usp_run_payment_segments (Option A). | All the new loads, including the two invoice bronze loads (MOD-002), the payment method dimension load (MOD-003), and the corporate subscription load and payer type dimension load (MOD-004), are to run in that block. The run procedure comes in a later module (MOD-016). |
| ADR-003 Delivery of the count-only profiling and findings queries | The profiling and findings queries are built as read-only procedures in Layercake (Option A), rather than views or undeployed scripts. | The two profiles (MOD-001) can be tested, are versioned with the solution and need only EXECUTE permission to run. They must be deployed to production before they can be run there. |

The decision records for both are still marked as pending (see Known limitations).

<!-- evidence: docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Option A: Post-Phase-1 enrichment block; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Layercake.usp_run_payment_segments; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#MOD-016 adds the run procedure; docs/design/DES-001.json#All new loads run as one block after the Phase 1 run (ADR-001); docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Pending: filled in by a human at the architecture validation gate; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Option A: Read-only procedures with an as-of date; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Running them needs only EXECUTE; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#they must be deployed to production; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Pending: filled in by a human at the architecture validation gate; docs/design/MP-001.json#Payment method reference and dimension; docs/design/MP-001.json#Corporate subscription bronze and payer type reference -->
