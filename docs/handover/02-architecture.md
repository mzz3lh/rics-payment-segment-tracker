# Architecture and data model: RICS Payment Segment Tracker

## Architecture overview

The solution extends the Phase 1 Layercake membership solution. All new objects live in the Layercake schema and follow the Phase 1 naming conventions. The design has bronze tables (one-to-one landings of source data), silver tables (reference lists, attributes and matches), gold dimensions and fact columns, and a set of read-only reporting procedures that return aggregates only (counts, sums and rates). Every change ships as a migration with a tested rollback script.

Nine layers are in place so far:

- **Reporting procedures (MOD-001, MOD-013):** two source profiles, named usp_profile_*, and the retirement comparison, usp_report_retirement_comparison. The profiles read two sources owned by other systems (see the Data lineage document); the retirement comparison reads Layercake tables and the derived retirement date view. None of them writes anything or builds tables. The profiles are meant to be run before the invoice build, so that their results can settle two open questions the build depends on (see Known limitations).
- **Bronze (MOD-002, MOD-004, MOD-006):** four tables, each with a load procedure. brnz_subs_invoice and brnz_subs_invoice_line copy subscription invoice data, brnz_corporate_subscription copies the corporate scheme subscriptions, and brnz_concession copies the concession types, from sources already in the warehouse with no change to any value. They carry the same four audit columns as the Phase 1 bronze tables. Each load records its run in the load log, Layercake.etl_run_log.
- **Silver reference (MOD-003 to MOD-006):** the payment method list, silv_ref_payment_method, and the payer type list, silv_ref_payer_type, fixed lists put in place by their migrations; fn_map_payment_method, which turns a source payment mode code into an entry on the payment method list; two lists that grow from the bronze invoice data: the line-type mapping, silv_ref_invoice_line_type, which says what each invoice item code is for, and the currency list, silv_ref_currency; and the concession type list, silv_ref_concession_type, which takes in new concession types and changes to listed ones from the concession bronze table while every type keeps its id. Each of these three has a load that records its run in the load log.
- **Gold dimensions (MOD-003 to MOD-006):** dim_payment_method, dim_payer_type, dim_currency and dim_concession_type, copies of their lists for reporting, each kept in step with its list by its load, which also records its run in the load log.
- **Silver attributes (MOD-007):** the eligible-invoice view, vw_silv_eligible_invoice, which decides once which invoices count and which one sets each contact-year's segments; and the member-year attributes table, silv_member_year_attributes, with its load, which works out each contact's payment method, payer type, corporate scheme number and concession for every Campaign Year. The load reads the bronze tables and lists above and three Phase 1 tables, and records its run in the load log.
- **New columns on the Phase 1 event tables (MOD-007, MOD-012):** silv_membership_events and the gold fact fact_membership_events each gained seventeen columns for the segment keys, carried flags and amounts (MOD-007). MOD-012 removed eight of them, which the member invoice statuses cannot supply, so nine remain. No Phase 1 column, row or event identifier changes.
- **Silver anomalies (MOD-008, MOD-011):** two anomaly loads that record data problems in the existing Phase 1 anomaly table, silv_data_anomaly, whose structure is unchanged. The segment anomaly load, usp_load_silv_data_anomaly_segment, records four kinds of problem with the payer type and concession. The invoice anomaly load, usp_load_silv_data_anomaly_invoice, records six kinds of anomaly linking invoices and events, from the pairing held in the event amounts table. Each anomaly load looks after only its own anomaly types; so that this holds, MOD-008 also changes the Phase 1 anomaly load, usp_load_silv_data_anomaly (see Design decisions). Both new loads record their runs in the load log.
- **Silver event amounts (MOD-010):** the event amounts table, silv_event_amount, with its load, usp_load_silv_event_amount. For every Join, Renewal and Readmission it works out the invoiced amount from the member invoice statuses (the new 'Inv Total Amount' column of brnz_subs_status), placed on one event per contact and Campaign Year, with an amount status, and pairs the event with its own eligible invoice for the invoice checks. The pairing is held once in this table so that the later loads that read it cannot disagree (ADR-002). The load reads the eligible-invoice view, brnz_subs_status and two Phase 1 tables, and records its run in the load log.
- **Segments and amounts on the events (MOD-012):** two loads that fill the nine new columns of the event tables after the Phase 1 run, as ADR-001 recommends. usp_load_silv_membership_events_segments writes them on the silver event table from the member-year attributes and the event amounts table; usp_load_fact_membership_events_segments copies them to the gold event fact, matching events by their identifier, and checks that silver and gold agree. Both record their runs in the load log.

MOD-009 adds no layer. It removes the old text column payment_source from the Phase 1 table of paid positions, silv_payment_events, because the payer type now lives on the member-year attributes (see Data model).

MOD-017 adds no layer either. It extends the Phase 1 bronze table brnz_subs_status, which copies the member invoice statuses from Subs.vwSubsMemberStatuses, with two columns, 'Inv Total Amount' and 'Retired Concession', and changes its Phase 1 load to fill them. That load still runs inside the Phase 1 run, in its bronze step, before any silver load (see Data model).

MOD-018 adds one silver view, vw_silv_derived_retirement_date, which works out each contact's derived retirement date from the member invoice statuses in brnz_subs_status. It changes two Phase 1 loads that run in the silver step of the Phase 1 run: the member base load, which now takes its retirement date from that view instead of the hand-entered apuk_retirementdate, and the events load, which is corrected only so that it runs where the database's temporary storage uses a different collation. The Phase 1 loads that set Practising / Retired then use the derived date, reading the member base as they do today (see Data model).

Later modules build the rest on these objects: the employer findings (MOD-014) and the coverage and totals queries (MOD-015), and the run procedure that runs every new load in order after the Phase 1 run (MOD-016).

<!-- evidence: docs/design/DES-001.json#Extends the Phase 1 Layercake membership solution; docs/design/DES-001.json#reporting queries; docs/design/MP-001.json#Builds no tables and changes no existing object; docs/dev/CN-MOD-001.json#Neither writes anything; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#before the invoice build; docs/design/DES-001.json#1:1 landings of external sources; docs/specs/SPEC-001.json#RULE-004; docs/design/DES-001.json#load logging; docs/design/MP-001.json#Subscription invoice bronze; docs/design/MP-001.json#Payment method reference and dimension; docs/design/MP-001.json#Corporate subscription bronze and payer type reference; docs/design/MP-001.json#Invoice line-type mapping and currency; docs/design/MP-001.json#Concession reference and dimension; docs/design/DES-001.json#1:1 landing of Subs.vwCorpSubscriptions; docs/design/DES-001.json#1:1 landing of CE.vwConcessionType; docs/design/DES-001.json#Static list seeded by its migration; docs/design/DES-001.json#Maps a source payment mode code to a silv_ref_payment_method id; docs/design/DES-001.json#Item-code to line-type mapping, one row per (item_code, ric_invoice_type); docs/design/DES-001.json#Insert-only, identity ids that never change.; docs/design/DES-001.json#Concession type is insert-and-update by business key; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type; docs/design/DES-001.json#Mirrors silv_ref_currency into dim_currency. Logged.; docs/design/DES-001.json#Mirrors silv_ref_concession_type into dim_concession_type. Logged.; docs/design/MP-001.json#Member-year attributes and new event-table columns; docs/design/DES-001.json#eligibility is defined once in vw_silv_eligible_invoice; docs/design/DES-001.json#Layercake.silv_member_year_attributes; docs/answers.md#MOD-007 attributes load; docs/design/MP-001.json#without writing values or changing any Phase 1 column, row, event_nk or event_id; docs/design/DES-001.json#MOD-012 drops eight of them through a change script: subs_amount, fee_amount, invoiced_subtotal, credited_amount, currency_id, fee_amount_gbp, credited_amount_gbp and net_amount_gbp; docs/design/DES-001.json#The nine columns below remain; docs/design/MP-001.json#Segment anomalies; docs/design/MP-001.json#in the existing silv_data_anomaly (structure unchanged); docs/design/DES-001.json#Derives the four segment anomaly types; docs/design/MP-001.json#Invoice and readmission anomalies; docs/design/DES-001.json#Derives the six invoice anomaly types from the match held in silv_event_amount; docs/dev/CN-MOD-011.json#objects_changed; docs/answers.md#Anomaly ownership: each anomaly load resolves only the types it detects; docs/design/MP-001.json#Event amounts and invoice matching; docs/design/DES-001.json#Layercake.silv_event_amount; docs/design/DES-001.json#Layercake.usp_load_silv_event_amount; docs/design/adr/ADR-002-persisting-per-event-invoice-matches-and-amounts.md#Option A: Persisted silver match table; docs/dev/CN-MOD-010.json#objects_changed; docs/test/TCS-MOD-010.json#Standard set-up for every test; docs/dev/CN-MOD-010.json#'silver', 'silv_event_amount'; docs/design/MP-001.json#Segment keys, flags and amounts onto the events; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Option A: Post-Phase-1 enrichment block; docs/design/DES-001.json#Layercake.usp_load_silv_membership_events_segments; docs/design/DES-001.json#Layercake.usp_load_fact_membership_events_segments; docs/dev/CN-MOD-012.json#log via the Phase 1 usp_etl_log_start/usp_etl_log_end; docs/design/MP-001.json#Retire silv_payment_events.payment_source; docs/design/DES-001.json#Its text column payment_source is removed, because payer type now lives on silv_member_year_attributes; docs/design/MP-001.json#Member status bronze extension; docs/design/DES-001.json#and the Phase 1 brnz_subs_status (Subs.vwSubsMemberStatuses) extended with inv_total_amount and retired_concession; docs/design/DES-001.json#The last two run inside the Phase 1 run, bronze before silver; src/sql/Layercake/Procedures/Layercake.usp_load_bronze.sql#usp_load_brnz_subs_status; docs/design/MP-001.json#Derived retirement date; docs/dev/CN-MOD-018.json#objects_changed; docs/design/DES-001.json#Layercake.vw_silv_derived_retirement_date; docs/design/DES-001.json#Changed in one respect only: retirement_date is taken from vw_silv_derived_retirement_date; src/sql/Layercake/Procedures/Layercake.usp_load_silver.sql#exec Layercake.usp_load_silv_member_base; src/sql/Layercake/Procedures/Layercake.usp_load_silver.sql#exec Layercake.usp_load_silv_membership_events; docs/answers.md#MOD-018 events load collation; docs/design/MP-001.json#events, annual rate base, member profile and daily count pick the date up as they read it today; docs/design/MP-001.json#Retirement comparison query; docs/design/MP-001.json#MOD-013; docs/dev/CN-MOD-013.json#objects_changed; docs/design/DES-001.json#Layercake.usp_report_retirement_comparison; docs/dev/CN-MOD-013.json#Derived date: read from Layercake.vw_silv_derived_retirement_date (MOD-018); docs/design/MP-001.json#Employer findings queries; docs/design/MP-001.json#Coverage and totals queries; docs/design/MP-001.json#Run sequence, regression and handover completion -->

## Data model

MOD-001 adds two procedures and no tables. MOD-002 adds two bronze tables and two load procedures. MOD-003 adds a silver reference table, a mapping function, a gold dimension table and its load procedure. MOD-004 adds a bronze table and its load procedure, a silver reference table, and a gold dimension table and its load procedure. MOD-005 adds two silver reference tables and a gold dimension table, each with its load procedure. MOD-006 adds a bronze table, a silver reference table and a gold dimension table, each with its load procedure. MOD-007 adds a silver view, a silver table and its load procedure, and is the first module to change existing objects: it adds seventeen columns to each of the two Phase 1 event tables, Layercake.silv_membership_events and Layercake.fact_membership_events. MOD-008 adds one silver load procedure and changes one existing Phase 1 procedure, Layercake.usp_load_silv_data_anomaly; it writes new anomaly types to the Phase 1 anomaly table, Layercake.silv_data_anomaly, without changing the table's structure. MOD-009 adds no object and changes no procedure: it removes one column, payment_source, from the existing Phase 1 table Layercake.silv_payment_events. MOD-017 adds no object: it adds two columns to the existing Phase 1 bronze table Layercake.brnz_subs_status and changes its Phase 1 load, Layercake.usp_load_brnz_subs_status. MOD-018 adds one silver view and changes two existing Phase 1 procedures, Layercake.usp_load_silv_member_base and Layercake.usp_load_silv_membership_events; no table changes structure. MOD-010 adds one silver table, Layercake.silv_event_amount, and its load procedure, Layercake.usp_load_silv_event_amount, and changes no existing object. MOD-011 adds one silver load procedure, Layercake.usp_load_silv_data_anomaly_invoice, and changes no existing object; it writes six more anomaly types to Layercake.silv_data_anomaly without changing the table's structure. MOD-012 adds two load procedures, Layercake.usp_load_silv_membership_events_segments and Layercake.usp_load_fact_membership_events_segments, and removes eight of the seventeen columns MOD-007 added to the two event tables; it changes no Phase 1 column, row or procedure. MOD-013 adds one reporting procedure, Layercake.usp_report_retirement_comparison, and changes no existing object.

<!-- evidence: docs/design/MP-001.json#Builds no tables and changes no existing object; docs/dev/CN-MOD-002.json#objects_changed; docs/dev/CN-MOD-003.json#objects_changed; docs/dev/CN-MOD-004.json#objects_changed; docs/dev/CN-MOD-005.json#objects_changed; docs/dev/CN-MOD-006.json#objects_changed; docs/dev/CN-MOD-007.json#objects_changed; docs/dev/CN-MOD-007.json#Change scripts adding the 17 columns to silv_membership_events and fact_membership_events; docs/dev/CN-MOD-008.json#objects_changed; docs/dev/CN-MOD-008.json#The silv_data_anomaly table file is unchanged; docs/answers.md#Layercake.silv_data_anomaly stays in MOD-008's objects with its structure unchanged; docs/dev/CN-MOD-009.json#objects_changed; docs/dev/CN-MOD-009.json#No procedure or view changes; docs/dev/CN-MOD-017.json#objects_changed; docs/design/MP-001.json#Adds inv_total_amount numeric(38,6) and retired_concession varchar(17), both nullable, to the existing Phase 1 Layercake.brnz_subs_status through a change script; docs/dev/CN-MOD-018.json#objects_changed; docs/design/adr/ADR-005-where-the-derived-retirement-date-replaces-apuk-retirementda.md#No table changes structure; docs/dev/CN-MOD-010.json#objects_changed; docs/dev/CN-MOD-010.json#"change": "added"; docs/dev/CN-MOD-011.json#objects_changed; docs/dev/CN-MOD-011.json#"change": "added"; docs/design/MP-001.json#Layercake.usp_load_silv_data_anomaly_invoice; docs/dev/CN-MOD-012.json#objects_changed; docs/dev/CN-MOD-012.json#Change scripts drop the eight null-only amount columns; docs/design/MP-001.json#Changes no Phase 1 column, row or procedure; docs/dev/CN-MOD-013.json#objects_changed; docs/dev/CN-MOD-013.json#"change": "added"; docs/design/MP-001.json#Layercake.usp_report_retirement_comparison -->

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

It is used inside the member-year attributes load (MOD-007), not run on its own.

<!-- evidence: docs/design/DES-001.json#Layercake.fn_map_payment_method; docs/design/DES-001.json#Maps a source payment mode code to a silv_ref_payment_method id; docs/answers.md#MOD-003 fn_map_payment_method; docs/answers.md#Compare the code with surrounding spaces trimmed and ignoring case; docs/specs/SPEC-001.json#RULE-007; docs/specs/SPEC-001.json#RULE-008; docs/test/TCS-MOD-003.json#TC-003-013; docs/dev/CN-MOD-003.json#It never matches a reserved row; docs/design/DES-001.json#the segment invoice's inv_payment_method, mapped by fn_map_payment_method -->

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

The line-type mapping (REQ-007, RULE-028): it says what each invoice item code is for. Under the amended specification, line types affect no event amount: they are used for the eligible-invoice test (the member-year attributes load uses them to recognise invoices that carry only an enrolment or application fee) and for the readmission fee check in the invoice anomaly load (MOD-011, RULE-030). One row per item code and RIC invoice type pair, with its line type: subscription, concession, readmission fee, enrolment or application fee, tax, other, or unmapped.

Each row also carries load_id (the load log entry of the load that added it; empty for the starting rows) and its created and updated times.

**Starting content.** As confirmed on 2026-10-27 (Q-034), the mapping starts with exactly the 12 item codes that the existing Subs.usp_Refresh_SubsInvoices names, all with RIC invoice type 'SUB'; no other curated list exists:

| Item codes | Line type |
|---|---|
| RAFEE_ACAND, RAFEE_APCC, RAFEE_ASSOC, RAFEE_FRICS, RAFEE_MRICS, RAFEE_PMU2 | readmission fee |
| CONPWRQ1, CONPWRQ2, CONPWRQ3, CONRETIRED, CONRETIREDFL, CONRETIREDSPECIAL | concession |

Every other code, the subscription codes included, is added as 'unmapped' by the first load.

**Mapping by hand.** A person changes the line type on a row from 'unmapped' to the right value. The load never overwrites an existing row, so a hand mapping is kept on every later run (AC-007-02). After the first load on real data, Damian maps the unmapped codes, following how Subs.usp_Refresh_SubsInvoices classifies them (see Known limitations).

<!-- evidence: docs/design/DES-001.json#Layercake.silv_ref_invoice_line_type; docs/design/DES-001.json#Item-code to line-type mapping, one row per (item_code, ric_invoice_type); docs/specs/SPEC-001.json#RULE-028; docs/specs/SPEC-001.json#RULE-030; docs/specs/SPEC-001.json#Line types no longer affect any event amount or amount_status; docs/design/DES-001.json#Line types serve the eligible-invoice test and the readmission fee check only; docs/design/DES-001.json#typed through silv_ref_invoice_line_type; docs/design/DES-001.json#One of: subscription, concession, readmission fee, enrolment or application fee, tax, other, unmapped (check constraint); docs/answers.md#Each is typed through silv_ref_invoice_line_type; docs/dev/CN-MOD-005.json#test new line type rows carry the load log id and equal created and updated times; docs/answers.md#Q-034 line-type mapping seed; docs/answers.md#No other curated list exists; docs/dev/CN-MOD-005.json#RAFEE_ACAND, RAFEE_APCC, RAFEE_ASSOC, RAFEE_FRICS, RAFEE_MRICS, RAFEE_PMU2; docs/dev/CN-MOD-005.json#CONPWRQ1, CONPWRQ2, CONPWRQ3, CONRETIRED, CONRETIREDFL, CONRETIREDSPECIAL; docs/specs/SPEC-001.json#AC-007-02; docs/answers.md#Damian maps the unmapped codes by hand -->

### Layercake.usp_load_silv_ref_invoice_line_type

The load that adds new item codes to the line-type mapping (RULE-029). On each run it reads the live rows of brnz_subs_invoice_line (rows marked as deleted are ignored) and adds each pair of item code and RIC invoice type not yet listed, with line type 'unmapped'.

- A line with a missing, empty or blank item code adds nothing.
- A line with an item code but no RIC invoice type is not skipped: its code is added with an empty invoice type, so it stays visible and can be mapped like any other.
- Codes are matched ignoring letter case and trailing spaces: a code that differs from a listed pair only in those ways is that pair and adds no row. A code with different leading spaces or characters is a new code.
- When one new code arrives in several spellings in the same run, one row is added, keeping the upper-case spelling first, then the one without trailing spaces (see Known limitations).
- It never changes or removes an existing row.

It makes all its changes in one step and records its run in the load log, with the number of rows added.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_ref_invoice_line_type; docs/specs/SPEC-001.json#RULE-029; docs/answers.md#MOD-005 NULL, blank and near-duplicate codes; docs/answers.md#and the pair can be mapped by hand like any other; docs/test/TCS-MOD-005.json#TC-005-004; docs/test/TCS-MOD-005.json#TC-005-005; docs/test/TCS-MOD-005.json#TC-005-006; docs/test/TCS-MOD-005.json#TC-005-007; docs/test/TCS-MOD-005.json#TC-005-008; docs/test/TCS-MOD-005.json#TC-005-009; docs/test/TCS-MOD-005.json#TC-005-012; docs/dev/CN-MOD-005.json#test line type spellings of one new pair keep the upper case and shortest spelling; docs/dev/CN-MOD-005.json#On error they roll back, log 'Failed' and re-raise. -->

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

### Layercake.vw_silv_eligible_invoice

The eligible-invoice view (REQ-004, RULE-014, RULE-079). It lists the invoices that may set a contact's segments for a Campaign Year, and marks the one that does. The rules are held here once, so the member-year attributes load, the event amount load (MOD-010), which pairs events with invoices for the invoice checks, and the invoice anomaly load (MOD-011), which looks for eligible invoices that no event is paired with, use the same invoices.

Only live invoices in brnz_subs_invoice with an account number and a Campaign Year are considered; the account number is the contact number. An invoice is eligible when all three hold:

1. **It is not a credit note.** A credit note is an invoice whose number contains 'FTCN', or contains 'CRE' unless its full invoice amount is exactly 0. So a 'CRE' document with a missing amount is a credit note, and an invoice with no number is not. This follows the owner's own test in Subs.usp_Refresh_SubsInvoices.
2. **It is not fully credited.** Only the value 'Y' means fully credited; 'N', 'N/A' and a missing value do not.
3. **It is not fee-only.** The invoice's own lines are the live rows of brnz_subs_invoice_line on its account and voucher, each given its line type through the line-type mapping (a missing RIC invoice type is matched as empty, and a line with no mapping row counts as unmapped). An invoice is fee-only when it has at least one enrolment or application fee line and every other own line is tax. An invoice with no own lines is not fee-only.

Where a contact-year has no invoice passing all three, its fully credited invoices that pass the first and third stand in as eligible (assumed, Q-012). A credit note is never eligible.

**The segment invoice.** Of a contact-year's eligible invoices, the latest by transaction date is the segment invoice, which sets the year's payment method, payer type and concession (assumed, Q-012). On equal dates the invoice with the higher row key (rec_id) wins (Q-036), and an invoice with no transaction date counts as earlier than any dated one.

For each eligible invoice the view gives: contact number, Campaign Year, rec_id, invoice number, voucher, transaction date, payment mode, currency, whether it is fully credited, whether it carries a full concession, its position in date order within the contact-year, and whether it is the segment invoice.

<!-- evidence: docs/design/DES-001.json#Layercake.vw_silv_eligible_invoice; docs/design/DES-001.json#eligibility is defined once in vw_silv_eligible_invoice and used by both the attributes load and the invoice match in the event amount load; docs/design/DES-001.json#Derives the six invoice anomaly types from the match held in silv_event_amount (invoice_rec_id, match_outcome) and from vw_silv_eligible_invoice; docs/dev/CN-MOD-011.json#an invoice in vw_silv_eligible_invoice that no event's invoice_rec_id points to; docs/specs/SPEC-001.json#RULE-014; docs/specs/SPEC-001.json#RULE-079; docs/answers.md#Eligible invoice (RULE-014, vw_silv_eligible_invoice); docs/answers.md#A NULL invoice number is not a credit note; docs/answers.md#anything other than 'Y', including NULL, is not fully credited; docs/answers.md#An invoice with no own lines is not fee-only, so it stays eligible; docs/answers.md#Segment invoice: the latest eligible invoice by trans_date, ties to the higher rec_id (Q-036); docs/dev/CN-MOD-007.json#Layercake.vw_silv_eligible_invoice. Columns; docs/test/TCS-MOD-007.json#TC-007-023; docs/test/TCS-MOD-007.json#TC-007-025; docs/test/TCS-MOD-007.json#TC-007-028; docs/test/TCS-MOD-007.json#TC-007-030; docs/test/TCS-MOD-007.json#TC-007-022; docs/dev/CN-MOD-010.json#eligible invoices from vw_silv_eligible_invoice of the amount year -->

### Layercake.silv_member_year_attributes

The member-year attributes table (REQ-004, REQ-006, REQ-011): one row for each contact and each Campaign Year, from the Campaign Year of the contact's first membership event to the current Campaign Year inclusive (RULE-011).

- **Contacts.** Every contact in the Phase 1 event table, Layercake.silv_membership_events. A contact's first-event year is the earliest Campaign Year of their events there. A contact with invoices but no membership event gets no rows, and a contact whose first event is after the current Campaign Year gets none yet.
- **Campaign Years.** Taken from the Phase 1 Campaign Year table, Layercake.ref_campaign_year_config. The current Campaign Year is the one whose start and end dates cover the load's as-of date (by default, the day the load runs).

| Column | Meaning |
|---|---|
| contact_no, campaign_year | The contact and Campaign Year; together they identify the row |
| payment_method_id | The year's payment method, from the payment method list; never empty |
| payment_method_carried | 1 when the payment method was carried forward from an earlier year, else 0 |
| payer_type_id | The year's payer type, from the payer type list; never empty |
| payer_type_carried | 1 when the payer type was carried forward, else 0 |
| corporate_account_ref | The scheme number of the live corporate subscription, for Corporate years only; empty otherwise (assumed, Q-019) |
| concession_type_id | The year's concession type, from the concession type list; never empty |
| concession_type_carried | 1 when the concession was carried forward, else 0 |
| segment_invoice_rec_id | The row key of the year's segment invoice; empty where the year has no eligible invoice. Used for tracing and in anomaly details |
| load_id | The load log entry of the load that last wrote the row |
| created_at, updated_at | When the row was first written and last changed |

The three segment columns must hold a value from their silver lists; the database rejects any other value.

**Years before 2022.** The invoice source starts at Campaign Year 2022, so earlier years get Not applicable (-2) for payment method, payer type and concession, with every carried flag 0, and are never carried into later years (assumed, Q-011).

**Payment method** (RULE-012 to RULE-016, assumed, Q-001). From the segment invoice's payment mode, mapped through fn_map_payment_method:

- A mode the mapping does not know gives Unrecognised (-1), with no fallback.
- Where the invoice's payment mode is missing or blank, the payment lines decide (RULE-013): the live lines on the invoice's own account whose last settlement voucher is the invoice's voucher and which carry a payment mode (the invoice's own lines are not payment lines). The settled amounts are added up per payment method, ignoring their sign; the method covering the largest amount wins; on a tie, the method with the earliest payment wins, then the line with the lowest row key. An unrecognised mode takes part like any other, so if it wins the year gets Unrecognised.
- With no payment mode on the invoice or its payment lines, the year gets Unknown (0), not carried (RULE-015).

**Payer type** (RULE-021 to RULE-026, RULE-082, RULE-083, assumed, Q-002). It uses the same segment invoice as payment method, so the two cannot disagree because of a fee-only invoice. A contact is in a live corporate subscription for a year when brnz_corporate_subscription has a live row for them for that Campaign Year with both Sub Status and Sub User Status 'Active' (assumed, Q-027); Round plays no part.

- **Corporate** when the segment invoice's payment method is Corporate and the contact is in a live corporate subscription that year, with or without a Phase 1 paid position.
- **Double payment:** where the segment invoice is settled both by Corporate and by another method (including an unrecognised one), the year is Corporate if a live corporate subscription exists, otherwise Individual.
- Otherwise **Individual** when the contact has a Phase 1 paid position that year (a row in Layercake.silv_payment_events for the contact and Campaign Year).
- Otherwise **Unknown** (0).

corporate_account_ref holds the live subscription's scheme number for Corporate years; where several live subscriptions exist, the lowest scheme number (Q-036).

**Concession** (RULE-049 to RULE-052, assumed, Q-021). From the segment invoice's own live lines whose item code starts 'CON', matched to the item codes in the concession type list:

- No concession line gives No concession (1).
- Where several lines match known types, the type with the highest discount in brnz_concession wins, then the line with the lowest row key; a known code beats one not in the list.
- Where no concession line matches a known type, the year gets Unrecognised (-1). Each concession code not in the list is also recorded as an anomaly (see Layercake.usp_load_silv_data_anomaly_segment).

**Carrying forward** (RULE-016, RULE-022, RULE-051, assumed, Q-006). A Campaign Year from 2022 with no eligible invoice takes its values from the latest earlier year that has one, with the carried flag set to 1: always for payment method and payer type (with the scheme number carried along with a carried Corporate payer type), and for concession only when that type is perpetual. Where nothing can be carried, including a No concession or non-perpetual concession, the value is Unknown (0) with flag 0. Some carry-forward behaviours were decided during the build (see Known limitations).

<!-- evidence: docs/design/DES-001.json#Layercake.silv_member_year_attributes; docs/specs/SPEC-001.json#RULE-011; docs/answers.md#Contact list and first-event year (RULE-011, Q-030); docs/answers.md#A contact whose first event is after the current Campaign Year gets no rows; docs/answers.md#Current Campaign Year; docs/test/TCS-MOD-007.json#TC-007-005; docs/test/TCS-MOD-007.json#TC-007-002; docs/design/DES-001.json#rec_id of the year's segment invoice; docs/design/DES-001.json#Scheme No of the live corporate subscription for Corporate years; docs/dev/CN-MOD-007.json#silv_member_year_attributes does have foreign keys to the three silver reference lists; docs/specs/SPEC-001.json#RULE-080; docs/test/TCS-MOD-007.json#TC-007-031; docs/test/TCS-MOD-007.json#TC-007-032; docs/specs/SPEC-001.json#RULE-012; docs/specs/SPEC-001.json#RULE-013; docs/specs/SPEC-001.json#RULE-015; docs/answers.md#Payment-line fallback (RULE-013); docs/test/TCS-MOD-007.json#TC-007-012; docs/test/TCS-MOD-007.json#TC-007-013; docs/test/TCS-MOD-007.json#TC-007-014; docs/test/TCS-MOD-007.json#TC-007-015; docs/specs/SPEC-001.json#RULE-021; docs/specs/SPEC-001.json#RULE-082; docs/specs/SPEC-001.json#RULE-083; docs/specs/SPEC-001.json#RULE-026; docs/design/DES-001.json#Attributes, payer type; docs/answers.md#Phase 1 paid position (RULE-021, RULE-017); docs/dev/CN-MOD-007.json#'Another method' is any qualifying payment line whose mapped method is not Corporate; docs/test/TCS-MOD-007.json#TC-007-033; docs/test/TCS-MOD-007.json#TC-007-035; docs/test/TCS-MOD-007.json#TC-007-036; docs/test/TCS-MOD-007.json#TC-007-037; docs/test/TCS-MOD-007.json#TC-007-038; docs/test/TCS-MOD-007.json#TC-007-039; docs/specs/SPEC-001.json#RULE-023; docs/specs/SPEC-001.json#RULE-049; docs/specs/SPEC-001.json#RULE-050; docs/specs/SPEC-001.json#RULE-052; docs/design/DES-001.json#Attributes, concession; docs/dev/CN-MOD-007.json#Two tie-breaks the design leaves open; docs/test/TCS-MOD-007.json#TC-007-043; docs/test/TCS-MOD-007.json#TC-007-044; docs/test/TCS-MOD-007.json#TC-007-046; docs/design/MP-001.json#CONCESSION_NOT_IN_REFERENCE; docs/test/TCS-MOD-008.json#TC-008-018; docs/specs/SPEC-001.json#RULE-016; docs/specs/SPEC-001.json#RULE-022; docs/specs/SPEC-001.json#RULE-051; docs/design/DES-001.json#Attributes, all segments; docs/test/TCS-MOD-007.json#TC-007-006; docs/test/TCS-MOD-007.json#TC-007-034; docs/test/TCS-MOD-007.json#TC-007-045; docs/test/TCS-MOD-007.json#TC-007-047; docs/test/TCS-MOD-007.json#TC-007-048; docs/test/TCS-MOD-007.json#TC-007-049 -->

### Layercake.usp_load_silv_member_year_attributes

The load that keeps silv_member_year_attributes up to date. It takes two optional parameters: a run id, and an as-of date that sets the current Campaign Year (by default, the day it runs, so a scheduled run needs no argument).

On each run it works out every contact-year again from the current data, then, in one step:

- adds rows for new contact-years (for example, every contact's row for a new Campaign Year);
- updates rows whose values have changed, refreshing their updated time and load_id and keeping their created time;
- deletes rows no longer derived (for example, a contact no longer in the event table);
- leaves unchanged rows untouched, so a second run on unchanged data changes nothing and records 0 inserted, 0 updated and 0 deleted.

The scheme number is compared exactly, so a change only in its letter case is written as an update. The load records its run in the load log under the step 'silv_member_year_attributes' with the numbers of rows inserted, updated and deleted. If no Campaign Year covers the as-of date, the load fails with an error naming the date and changes nothing. For what happens when it fails, see the Runbook.

It reads the bronze invoice, invoice line, corporate subscription and concession tables, the line-type mapping, the three segment lists and three Phase 1 tables (silv_membership_events, silv_payment_events and ref_campaign_year_config), and never changes any of them.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_member_year_attributes; docs/design/DES-001.json#Recomputes every contact-year from the rules in the attributes pattern; docs/answers.md#Current Campaign Year; docs/answers.md#so the scheduled run needs no argument; docs/answers.md#Load pattern (DES-001); docs/answers.md#refreshing updated_at and load_id, keeping created_at; docs/answers.md#Logging: the same as the MOD-004 to MOD-006 loads; docs/dev/CN-MOD-007.json#delete, update, insert in one transaction; docs/dev/CN-MOD-007.json#The scheme number is compared as bytes, so a change in case alone is still written; docs/dev/CN-MOD-007.json#raises error 50001, which names the date; docs/test/TCS-MOD-007.json#TC-007-004; docs/test/TCS-MOD-007.json#TC-007-017; docs/test/TCS-MOD-007.json#TC-007-018; docs/test/TCS-MOD-007.json#TC-007-019; docs/test/TCS-MOD-007.json#TC-007-020; docs/test/TCS-MOD-007.json#TC-007-050; docs/test/TCS-MOD-007.json#Standard set-up for every attributes test -->

### Layercake.silv_event_amount

The event amounts table (REQ-008, REQ-009, ADR-002): one row for each Join, Renewal and Readmission in the Phase 1 event table, Layercake.silv_membership_events. Change and Lapse events get no row. For each event it holds the Campaign Year its amount comes from, its invoiced amount and amount status, and the eligible invoice it is paired with for the invoice checks. In the design it is internal to silver: the event column load (MOD-012) copies the amounts onto the event tables, from which reporting reads them, and the invoice anomaly load (MOD-011) reads the pairing to record the invoice anomalies.

| Column | Meaning |
|---|---|
| event_nk | The event's identifier text in the event table, for example 'RN:A1:2025'; identifies the row |
| event_id | The event's number in the event table |
| contact_no, event_type, event_date | The event's contact, type (Join, Renewal or Readmission) and date, as in the event table |
| amount_campaign_year | The Campaign Year the amount and the invoice pairing come from (see below) |
| invoice_rec_id | The row key (rec_id) of the eligible invoice the event is paired with; empty where it has none. Never used for the amount |
| match_outcome | Matched, No eligible invoice, Invoice shortfall or Before invoice data (see below) |
| invoiced_subtotal_gbp | The headline value: the contact-year's Inv Total Amount in GBP, on the one event that carries it; empty otherwise |
| subs_amount_gbp | Always the same value as invoiced_subtotal_gbp, and empty together with it (Q-044) |
| amount_status | One of six values, never empty (see below) |
| load_id | The load log entry of the load that last wrote the row |
| created_at, updated_at | When the row was first written and last changed |

The two amount columns have the same type as the amount columns of the event tables, with 4 decimal places. The database accepts only the six amount status values. The table holds no fee, invoice-currency amount, currency, credited amount or net amount, because the member invoice statuses cannot supply them (Q-038).

**Amount Campaign Year** (RULE-032). A Renewal or Readmission uses its own Campaign Year. A Join uses the Campaign Year of the contact's first paid position (the earliest Campaign Year for the contact in the Phase 1 table Layercake.silv_payment_events), or its own Campaign Year where the contact has no paid position in any year (assumed, Q-029). For example, a Join in Campaign Year 2024 whose contact's first paid position is 2025 takes its amount from 2025, and a Join in 2021 whose first paid position is 2022 takes its 2022 amount and is paired with a 2022 invoice. The first paid position is used even when it is earlier than the Join's own year (see Known limitations).

**Which event carries the amount** (RULE-098, Q-039, Q-047). Within each contact and amount Campaign Year, exactly one event carries the amount: a Readmission first, then a Renewal, then a Join; among events of the same type, the earliest date; among those on the same date, the lowest event_id. Every other event in that contact and year has empty amounts and the status 'Counted on another event'. For example, a Renewal and a Readmission in one year whose Inv Total Amount is 900.00 give the Readmission 900.00 and the Renewal nothing, and a 2024 Join whose amount year is 2025 gives way to a 2025 Renewal. So the event amounts of a contact-year add up to its Inv Total Amount, and no contact-year's amount is counted twice.

**The amount** (RULE-033, RULE-035, RULE-040, RULE-041). The carrying event takes Inv Total Amount, as the source gives it, in GBP, from the live row of Layercake.brnz_subs_status for its contact and amount Campaign Year, and holds it in both invoiced_subtotal_gbp and subs_amount_gbp. No amount is ever taken from the invoices or invoice lines (Q-038, Q-042): an invoice's tax, readmission fee, enrolment fee or unmapped lines, its currency, a later credit note, or a later change to an invoice or line amount make no difference to the event amount; only the member status row does.

- A Full Concession year carries the source's amount, 0.00, not an empty amount.
- The amounts are empty where the amount Campaign Year is before 2022, where the contact and amount Campaign Year has no live status row (a row marked as deleted, or a row for another year or another contact, does not count), or where that row's Inv Total Amount is empty.
- Concessions reach the amount only through Inv Total Amount. For example, invoice lines of 450.00 and an Exceptional Hardship concession of -225.00, with a status row of 225.00, give 225.00 (AC-011-07).
- For a corporate-funded member, the event carries the amount on the member's own status row; firm-level discounts are not spread to individuals (assumed, Q-005).

**Amount status** (RULE-088, Q-045). Every Join, Renewal and Readmission gets exactly one status, the first that applies:

| Amount status | When it applies |
|---|---|
| Before invoice data | The amount Campaign Year is before 2022, even where a status row exists |
| No invoice | The contact and amount Campaign Year has no live status row, or its Inv Total Amount is empty |
| Counted on another event | Another event in the same contact and amount Campaign Year carries the amount |
| Full Concession | The status row's Member Invoice Position is 'Full Concession' |
| Fully credited | The Member Invoice Position is 'Fully Credited' |
| Invoiced | Every other case, including the positions Bad Debt Write Off, Zero Value Invoice, No Payment, Partially Paid, Pre-Subs Payment and Fully Paid, and an empty position |

'Unmapped lines' is no longer an amount status.

**Pairing with invoices, for the invoice checks only** (RULE-084 to RULE-086, RULE-089). For each contact and amount Campaign Year from 2022, the events are paired with the contact's eligible invoices of that year, as listed by vw_silv_eligible_invoice (so only live invoices, with fully credited invoices standing in only where the year has no other):

- Equal numbers of events and invoices: the events in date order take the invoices in date order, earliest with earliest (Q-022).
- More events than invoices: the invoices go to events in the order Readmission, Renewal, Join, then the earliest date; those events are paired with the invoices by date, and every other event gets no invoice and the outcome 'Invoice shortfall'.
- More invoices than events: the events are paired by date with the latest invoices, and the earlier surplus invoices are paired with no event.
- No invoice is paired with more than one event.
- Ties: of two invoices on the same date, the one with the higher row key counts as the later; events on the same date are taken in the order of their identifier text, event_nk (Q-036).

The outcome is 'Matched' where the event has an invoice, 'No eligible invoice' where the contact-year has none, 'Invoice shortfall' as above, and 'Before invoice data' where the amount Campaign Year is before 2022; those events are never paired. The pairing reads no invoice or line amount and never sets an amount. The amount status and the match outcome are independent: an event can be 'Invoiced' with no eligible invoice, and an event 'Counted on another event' is still paired with its own invoice.

<!-- evidence: docs/design/DES-001.json#Layercake.silv_event_amount; docs/design/DES-001.json#One row per Join, Renewal and Readmission event in silv_membership_events (ADR-002); docs/design/DES-001.json#Holds no invoice-currency amount, fee, credit, net amount or currency (Q-038); docs/design/DES-001.json#Same type as silv_membership_events.event_nk; docs/design/DES-001.json#silv_membership_events.event_id; docs/design/DES-001.json#Matched eligible invoice for the REQ-009 checks; docs/design/DES-001.json#Matched, No eligible invoice, Invoice shortfall (more events than invoices, RULE-085), or Before invoice data; docs/design/DES-001.json#Always equal to invoiced_subtotal_gbp; docs/design/DES-001.json#Headline value: brnz_subs_status.inv_total_amount on the amount event; docs/design/DES-001.json#One of the six RULE-088 values (check constraint); docs/design/DES-001.json#The value is held in the events' existing decimal(19,4) columns; docs/dev/CN-MOD-010.json#CK on the six RULE-088 amount_status values; docs/design/adr/ADR-002-persisting-per-event-invoice-matches-and-amounts.md#The table is internal to silver; docs/design/DES-001.json#Join, Renewal and Readmission take subs_amount_gbp, invoiced_subtotal_gbp and amount_status from silv_event_amount by event_nk; docs/design/MP-001.json#from the match held in silv_event_amount; docs/specs/SPEC-001.json#RULE-032; docs/specs/SPEC-001.json#Q-029; docs/dev/CN-MOD-010.json#a Join's = MIN(campaign_year) of the contact in silv_payment_events, else its own; docs/dev/CN-MOD-010.json#RULE-032 read literally, so a paid year before the Join's own year is used; docs/test/TCS-MOD-010.json#TC-010-003; docs/test/TCS-MOD-010.json#TC-010-004; docs/test/TCS-MOD-010.json#TC-010-021; docs/specs/SPEC-001.json#RULE-098; docs/specs/SPEC-001.json#Q-039; docs/specs/SPEC-001.json#Q-047; docs/test/TCS-MOD-010.json#TC-010-011; docs/test/TCS-MOD-010.json#TC-010-022; docs/test/TCS-MOD-010.json#TC-010-025; docs/test/TCS-MOD-010.json#TC-010-026; docs/specs/SPEC-001.json#RULE-033; docs/specs/SPEC-001.json#RULE-035; docs/specs/SPEC-001.json#RULE-040; docs/specs/SPEC-001.json#RULE-041; docs/specs/SPEC-001.json#Q-038; docs/specs/SPEC-001.json#Q-042; docs/specs/SPEC-001.json#Q-044; docs/test/TCS-MOD-010.json#TC-010-001; docs/test/TCS-MOD-010.json#TC-010-002; docs/test/TCS-MOD-010.json#TC-010-005; docs/test/TCS-MOD-010.json#TC-010-006; docs/test/TCS-MOD-010.json#TC-010-007; docs/test/TCS-MOD-010.json#TC-010-008; docs/test/TCS-MOD-010.json#TC-010-018; docs/test/TCS-MOD-010.json#TC-010-019; docs/test/TCS-MOD-010.json#TC-010-031; docs/test/TCS-MOD-010.json#TC-010-032; docs/specs/SPEC-001.json#AC-011-07; docs/specs/SPEC-001.json#RULE-038; docs/specs/SPEC-001.json#Q-005; docs/test/TCS-MOD-010.json#TC-010-010; docs/specs/SPEC-001.json#RULE-088; docs/specs/SPEC-001.json#Q-045; docs/test/TCS-MOD-010.json#TC-010-020; docs/test/TCS-MOD-010.json#TC-010-027; docs/test/TCS-MOD-010.json#TC-010-028; docs/test/TCS-MOD-010.json#TC-010-029; docs/test/TCS-MOD-010.json#TC-010-030; docs/test/TCS-MOD-010.json#TC-010-017; docs/test/TCS-MOD-010.json#TC-010-024; docs/specs/SPEC-001.json#RULE-084; docs/specs/SPEC-001.json#RULE-085; docs/specs/SPEC-001.json#RULE-086; docs/specs/SPEC-001.json#RULE-089; docs/specs/SPEC-001.json#Q-022; docs/design/DES-001.json#Q-036; docs/dev/CN-MOD-010.json#they pair in (event_date, event_nk) order with the latest invoices by the view's invoice_seq (trans_date, rec_id); docs/dev/CN-MOD-010.json#match_outcome: 'Before invoice data' (<2022), 'No eligible invoice', 'Invoice shortfall', 'Matched'; docs/dev/CN-MOD-010.json#No invoice or line amount is read; docs/dev/CN-MOD-010.json#test only live eligible invoices of the amount year are matched; docs/test/TCS-MOD-010.json#TC-010-009; docs/test/TCS-MOD-010.json#TC-010-012; docs/test/TCS-MOD-010.json#TC-010-013; docs/test/TCS-MOD-010.json#TC-010-014; docs/test/TCS-MOD-010.json#TC-010-015; docs/test/TCS-MOD-010.json#TC-010-016; docs/design/DES-001.json#Derives the six invoice anomaly types from the match held in silv_event_amount -->

### Layercake.usp_load_silv_event_amount

The load that keeps silv_event_amount up to date. It takes one optional parameter, a run id, so a scheduled run needs no argument.

On each run it works out every Join, Renewal and Readmission again from the current data, then:

- adds rows for new events;
- updates rows whose values have changed, refreshing their updated time and load_id and keeping their created time; the contact number and event type are compared exactly, so a change only in their letter case is written as an update;
- deletes rows for events no longer in the event table, even where the contact still has a member status row;
- leaves unchanged rows untouched, so a second run on unchanged data changes nothing and records 0 inserted, 0 updated and 0 deleted.

It reads the Phase 1 event table (silv_membership_events), the Phase 1 paid positions (silv_payment_events), the member invoice statuses (brnz_subs_status) and the eligible-invoice view, which itself reads brnz_subs_invoice, brnz_subs_invoice_line and the line-type mapping. It never changes any of them, and it writes nothing to the event tables or to the anomaly table. It records its run in the load log under the layer 'silver' and the step 'silv_event_amount', with the numbers of rows inserted, updated and deleted. An Inv Total Amount too large for the amount columns fails the load, which then changes nothing (see the Runbook and Known limitations).

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_event_amount; docs/design/DES-001.json#Writes only differences: new events inserted, changed rows updated, rows for events that no longer exist deleted. Logged.; docs/dev/CN-MOD-010.json#@run_id uniqueidentifier = NULL; docs/dev/CN-MOD-010.json#usp_etl_log_start @run_id, 'silver', 'silv_event_amount'; docs/dev/CN-MOD-010.json#Writes only differences (EXCEPT comparison, contact_no and event_type as bytes); docs/dev/CN-MOD-010.json#a rerun logs 0, 0, 0.; docs/dev/CN-MOD-010.json#test case only contact_no change is one update; docs/dev/CN-MOD-010.json#test insert update and delete in one run are each counted; docs/dev/CN-MOD-010.json#an overflowing value fails the load (8115), logs Failed and changes nothing; docs/test/TCS-MOD-010.json#TC-010-033; docs/test/TCS-MOD-010.json#TC-010-034; docs/test/TCS-MOD-010.json#TC-010-035; docs/test/TCS-MOD-010.json#TC-010-036; docs/test/TCS-MOD-010.json#TC-010-037; docs/test/TCS-MOD-010.json#Standard set-up for every test; docs/design/MP-001.json#Does not write to the event tables or to silv_data_anomaly -->

### Segment and amount columns on Layercake.silv_membership_events and Layercake.fact_membership_events

The two existing Phase 1 event tables, the silver event table and the gold event fact, carry the same nine columns, with the same types and rules (REQ-005, REQ-006, REQ-008, REQ-011):

| Column | What it holds | Empty allowed |
|---|---|---|
| payment_method_id | The event's payment method, from the payment method list; in gold it points to dim_payment_method | Never empty; 0 (Unknown) by default |
| payment_method_carried | 1 when the event's payment method was carried forward from an earlier year, else 0 | Never empty; 0 by default |
| payer_type_id | The event's payer type, from the payer type list; in gold it points to dim_payer_type | Never empty; 0 (Unknown) by default |
| payer_type_carried | 1 when the payer type was carried forward, else 0 | Never empty; 0 by default |
| concession_type_id | The event's concession type, from the concession type list; in gold it points to dim_concession_type | Never empty; 0 (Unknown) by default |
| concession_type_carried | 1 when the concession was carried forward, else 0 | Never empty; 0 by default |
| invoiced_subtotal_gbp | The headline value: the event's invoiced amount in GBP, on Join, Renewal and Readmission. In gold an additive measure | Can be empty; always empty on Change and Lapse |
| subs_amount_gbp | Always the same value as invoiced_subtotal_gbp, and empty with it (Q-044). In gold an additive measure | Can be empty; always empty on Change and Lapse |
| amount_status | Why a Join, Renewal or Readmission has the amount it has, or none (see Layercake.silv_event_amount) | Can be empty; always empty on Change and Lapse |

The two amount columns hold up to 15 digits before the decimal point and 4 after.

MOD-007 added seventeen columns to each table. Under the amended specification, an event's amount comes only from the member invoice statuses, which cannot supply a subscription and fee split, invoice-currency amounts, a currency, credited amounts or a net amount (Q-038). MOD-012 therefore removes eight of the seventeen from both tables: subs_amount, fee_amount, invoiced_subtotal, credited_amount, currency_id, fee_amount_gbp, credited_amount_gbp and net_amount_gbp. They held only empty values, because no load had written them. Rolling back MOD-012 adds them back, as MOD-007 built them.

The values of the nine columns are written by the two loads below, which run after the Phase 1 run (ADR-001). The Phase 1 loads still add, change and remove events as before and do not write these columns, so an event they add takes the defaults (0 for the keys and flags, empty amounts) until the two loads next run (see Known limitations). The Phase 1 columns, rows, event_nk and event_id of both tables are unchanged, and the membership status is still set by the Phase 1 loads.

No database keys link the columns to the lists or dimensions, because neither Phase 1 table has any, and a key to the payment method dimension would stop the Phase 1 fact load while that dimension is empty (see Known limitations).

<!-- evidence: docs/design/DES-001.json#Layercake.silv_membership_events; docs/design/DES-001.json#Layercake.fact_membership_events; docs/design/DES-001.json#The nine columns below remain: keys and flags not null with default 0; docs/design/DES-001.json#amounts and amount_status nullable and null on Change and Lapse; docs/design/DES-001.json#Equal to invoiced_subtotal_gbp (RULE-035); docs/design/DES-001.json#Resolves to dim_payment_method; docs/design/DES-001.json#Resolves to dim_payer_type; docs/design/DES-001.json#Resolves to dim_concession_type; docs/design/DES-001.json#the two GBP amounts are additive measures; docs/design/DES-001.json#decimal(19,4); docs/test/TCS-MOD-012.json#TC-012-012; docs/specs/SPEC-001.json#AC-008-04; docs/specs/SPEC-001.json#Amounts the view cannot supply are dropped; docs/specs/SPEC-001.json#Q-038; docs/specs/SPEC-001.json#Q-044; docs/specs/SPEC-001.json#RULE-039; docs/design/DES-001.json#MOD-007 added seventeen columns; docs/design/DES-001.json#MOD-012 drops eight of them through a change script: subs_amount, fee_amount, invoiced_subtotal, credited_amount, currency_id, fee_amount_gbp, credited_amount_gbp and net_amount_gbp; docs/design/DES-001.json#They hold only nulls, because no load has written them, and the down script adds them back as MOD-007 built them; docs/design/DES-001.json#Their values are written by usp_load_silv_membership_events_segments; docs/design/DES-001.json#Values are written by usp_load_fact_membership_events_segments; docs/design/DES-001.json#membership_status_id still comes from the Phase 1 gold load; docs/design/DES-001.json#membership_status_id is still set by the Phase 1 load; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#the new columns briefly hold their defaults; docs/test/TCS-MOD-007.json#TC-007-053; docs/test/TCS-MOD-007.json#TC-007-054; src/sql/Layercake/Procedures/Layercake.usp_load_fact_membership_events.sql#rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter); docs/design/MP-001.json#without writing values or changing any Phase 1 column, row, event_nk or event_id; docs/dev/CN-MOD-007.json#No foreign keys were added to the existing silv_membership_events and fact_membership_events -->

### Layercake.usp_load_silv_membership_events_segments

The load that writes the nine columns on silv_membership_events (REQ-005, REQ-006, REQ-008, REQ-011, ADR-001). On each run it works them out again for every event:

- **Segments and carried flags** (RULE-017, RULE-018, RULE-024, RULE-054, RULE-081). Every event takes its payment method, payer type and concession, and the three carried flags, from the member-year attributes row for its contact and its segment Campaign Year. The segment Campaign Year is the event's own Campaign Year for a Change, Lapse, Renewal and Readmission. For a Join it is the same year as its amount: the Campaign Year of the contact's first paid position (the earliest Campaign Year for the contact in the Phase 1 table Layercake.silv_payment_events), or the Join's own Campaign Year where the contact has no paid position in any year (assumed, Q-029). An event with no attributes row for its contact and segment year gets 0 (Unknown) for all three segments and 0 for every flag; a row for another year or another contact does not apply.
- **Amounts** (RULE-033, RULE-035, RULE-039, RULE-088). Each Join, Renewal and Readmission takes invoiced_subtotal_gbp, subs_amount_gbp and amount_status from its row in the event amounts table, Layercake.silv_event_amount, matched on its identifier text (event_nk), empty amounts and 0.00 included. Change and Lapse events get empty amounts and no amount status. So does a Join, Renewal or Readmission that has no row in the event amounts table. A row in the event amounts table for an event that no longer exists adds nothing.

For example, a contact whose attributes give Direct Debit for 2023 and Card for 2024, with 2025 carried from 2024, has a 2023 Join with Direct Debit, a 2024 Change and Renewal with Card, and a 2025 Lapse with Card and payment_method_carried 1 (assumed, Q-006). A Join in Campaign Year 2023 whose contact's first paid position is 2024 takes the 2024 attributes, Direct Debit, rather than its own year's Card. A Renewal in Campaign Year 2021 takes Not applicable (-2) from the 2021 attributes (assumed, Q-011).

It then updates only the events whose values differ, replacing whatever they held before; unchanged events are left untouched, so a second run on unchanged data changes nothing. A change only in the letter case of an amount status is written. The load never adds or removes an event and never changes a Phase 1 column. It makes all its changes in one step and records its run in the load log with the number of events updated; its inserted and deleted counts are always 0. For what happens when it fails, see the Runbook.

It reads the member-year attributes, the event amounts table and the Phase 1 paid positions, silv_payment_events, and changes none of them.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_membership_events_segments; docs/design/DES-001.json#Writes the new columns on silv_membership_events (ADR-001); docs/design/DES-001.json#Keys and carried flags come from the silv_member_year_attributes row for the contact and the event's segment Campaign Year (RULE-017), or 0 where there is no row; docs/design/DES-001.json#Join, Renewal and Readmission take subs_amount_gbp, invoiced_subtotal_gbp and amount_status from silv_event_amount by event_nk; docs/design/DES-001.json#Change and Lapse get nulls; docs/design/DES-001.json#Updates only rows whose new-column values differ. Never inserts or deletes events, and never touches Phase 1 columns; docs/specs/SPEC-001.json#RULE-017; docs/specs/SPEC-001.json#RULE-018; docs/specs/SPEC-001.json#RULE-024; docs/specs/SPEC-001.json#RULE-054; docs/specs/SPEC-001.json#RULE-081; docs/specs/SPEC-001.json#RULE-039; docs/specs/SPEC-001.json#Q-029; docs/dev/CN-MOD-012.json#a Join uses MIN(campaign_year) in silv_payment_events for its contact, else its own year, the same rule as silv_event_amount.amount_campaign_year; docs/dev/CN-MOD-012.json#including an event with no amount row, which clears stale values; docs/dev/CN-MOD-012.json#amount_status compared as bytes, so a case-only change lands; docs/dev/CN-MOD-012.json#with 0 inserted and 0 deleted; docs/dev/CN-MOD-012.json#test join with no amount row takes its first paid year segments and null amounts; docs/dev/CN-MOD-012.json#test silver case only change in amount_status is written and logged as one update; docs/test/TCS-MOD-012.json#TC-012-001; docs/test/TCS-MOD-012.json#TC-012-002; docs/test/TCS-MOD-012.json#TC-012-005; docs/test/TCS-MOD-012.json#TC-012-008; docs/test/TCS-MOD-012.json#TC-012-011; docs/test/TCS-MOD-012.json#TC-012-013; docs/test/TCS-MOD-012.json#TC-012-014; docs/test/TCS-MOD-012.json#TC-012-020; docs/test/TCS-MOD-012.json#TC-012-021; docs/test/TCS-MOD-012.json#TC-012-022; docs/test/TCS-MOD-012.json#Standard set-up for every test -->

### Layercake.usp_load_fact_membership_events_segments

The load that copies the nine columns from silv_membership_events to fact_membership_events, matching the events by their number, event_id (RULE-019, RULE-024, RULE-054). It updates only the gold rows whose values differ from silver, replacing whatever they held before; unchanged rows are left untouched, so a second run on unchanged silver changes nothing. It copies only the nine columns: the membership status and the other Phase 1 columns of the fact keep the values the Phase 1 gold load gave them, even where silver differs, and it does not add or remove fact rows, which the Phase 1 gold load does.

In the same step it then checks that silver and gold agree (the extended silver-to-gold check, RULE-019, AC-008-11):

- the numbers of events by payment method are the same in both tables;
- the numbers of events by amount status are the same;
- the totals of invoiced_subtotal_gbp, and the totals of subs_amount_gbp, are the same.

If any check fails, for example because one table holds an event the other lacks, or only an amount total differs, the load fails and the fact table is left exactly as it was. It records its run in the load log with the number of rows updated; its inserted and deleted counts are always 0. A change only in the letter case of an amount status is copied. For what happens when it fails, see the Runbook.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_fact_membership_events_segments; docs/design/DES-001.json#Copies the new columns from silv_membership_events onto fact_membership_events by event_id, updating only rows that differ; docs/design/DES-001.json#equal row counts by payment_method_id, equal counts by amount_status, and equal sums of subs_amount_gbp and invoiced_subtotal_gbp (RULE-019, AC-008-11). A failed check fails the load; docs/specs/SPEC-001.json#RULE-019; docs/specs/SPEC-001.json#RULE-024; docs/specs/SPEC-001.json#RULE-054; docs/specs/SPEC-001.json#AC-008-11; docs/dev/CN-MOD-012.json#runs the silver-to-gold check (counts by payment_method_id, counts by amount_status, sums of both GBP amounts) inside the transaction; docs/dev/CN-MOD-012.json#a mismatch throws 50001, logs Failed and leaves the fact unchanged; docs/dev/CN-MOD-012.json#test gold check fails when only an amount sum differs; docs/dev/CN-MOD-012.json#test gold check fails with 50001 when gold holds an event silver lacks and leaves the fact unchanged; docs/dev/CN-MOD-012.json#test gold case only change in amount_status is copied and logged with literal zero inserted and deleted; docs/test/TCS-MOD-012.json#TC-012-023; docs/test/TCS-MOD-012.json#TC-012-024; docs/test/TCS-MOD-012.json#TC-012-025; docs/test/TCS-MOD-012.json#TC-012-026; src/sql/Layercake/Procedures/Layercake.usp_load_fact_membership_events.sql#Diff-sync on event_id -->

### Layercake.silv_data_anomaly (segment and invoice anomaly types)

The existing Phase 1 anomaly table, which lists cases where the data does not match the agreed rules. Its structure is unchanged (REQ-006, REQ-009, REQ-011). MOD-008 adds four anomaly types to it, the segment anomalies, and MOD-011 six more, the invoice anomalies. Each anomaly type is looked after by one load only.

The segment anomaly types (MOD-008):

| Anomaly type | Rule | Raised when |
|---|---|---|
| CORPORATE_FLAG_NO_SCHEME | RULE-025 | The segment invoice's payment method is Corporate, but the contact is in no live corporate subscription that Campaign Year (assumed, Q-002 and Q-027) |
| DOUBLE_PAYMENT | RULE-026 | The segment invoice is settled both by Corporate and by another payment method (assumed, Q-002) |
| CONCESSION_NOT_IN_REFERENCE | RULE-052 | A concession item code on the segment invoice is not in the concession type list; one row per code |
| FULL_CONCESSION_NO_CONCESSION | RULE-053 | The contact-year has a Full Concession position, but its segment invoice carries no full-rate concession (a concession type with discount 100) |

The invoice anomaly types (MOD-011), raised only where the amount Campaign Year is 2022 or later (RULE-093):

| Anomaly type | Rule | Raised for |
|---|---|---|
| EVENT_NO_INVOICE | RULE-042 | Each Join, Renewal or Readmission whose contact and amount Campaign Year has no eligible invoice |
| INVOICE_NO_EVENT | RULE-043 | Each eligible invoice in a contact-year where no Join, Renewal or Readmission takes its amount from that year |
| INVOICE_MATCHES_MULTIPLE_EVENTS | RULE-090 | Each event left without an invoice because its contact and amount Campaign Year has more events than eligible invoices; such an event gets this row and no EVENT_NO_INVOICE row |
| EVENT_MATCHES_MULTIPLE_INVOICES | RULE-091 | Each surplus invoice, left unpaired because its contact and amount Campaign Year has more eligible invoices than events; such an invoice gets this row and no INVOICE_NO_EVENT row |
| READMISSION_FREE | RULE-044, RULE-092 | Each Readmission paired with an invoice that has no readmission fee line, when the Readmission falls in the free-readmission window (the second quarter of its Campaign Year) |
| READMISSION_NO_FEE | RULE-044 | Each other Readmission paired with an invoice that has no readmission fee line |

A segment or invoice anomaly row holds:

| Column | Meaning |
|---|---|
| anomaly_type | One of the ten types above |
| contact_no | The contact |
| anomaly_nk | The row's identity. For a segment anomaly: the anomaly type, contact number and Campaign Year joined by colons, with the item code added for CONCESSION_NOT_IN_REFERENCE. For an invoice anomaly: the anomaly type and a colon, followed by the event's identifier text (event_nk) for EVENT_NO_INVOICE, INVOICE_MATCHES_MULTIPLE_EVENTS, READMISSION_FREE and READMISSION_NO_FEE, or by the invoice's row key (rec_id) for INVOICE_NO_EVENT and EVENT_MATCHES_MULTIPLE_INVOICES |
| detail | A description of the case. For a segment anomaly it names the Campaign Year and the segment invoice (its invoice number and row key) |
| first_detected_at, last_seen_at | When the case was first recorded; later runs do not change them |
| resolved_at | Always empty for these types: a segment or invoice case that no longer applies is removed, not marked as resolved |

The Phase 1 anomaly types work differently: a Phase 1 case that stops being detected is kept and marked as resolved, and re-opened if it recurs (see Known limitations).

<!-- evidence: src/sql/Layercake/Tables/Layercake.silv_data_anomaly.sql#Rows where the data does not match the agreed rules; src/sql/Layercake/Tables/Layercake.silv_data_anomaly.sql#Never hard-; src/sql/Layercake/Tables/Layercake.silv_data_anomaly.sql#re-opened (resolved_at cleared) if it recurs; docs/design/DES-001.json#Gains ten anomaly types, each owned by one new procedure; docs/design/MP-001.json#Invoice and readmission anomalies; docs/specs/SPEC-001.json#RULE-025; docs/specs/SPEC-001.json#RULE-026; docs/specs/SPEC-001.json#RULE-052; docs/specs/SPEC-001.json#RULE-053; docs/specs/SPEC-001.json#Q-002; docs/specs/SPEC-001.json#Q-027; docs/specs/SPEC-001.json#RULE-047; docs/specs/SPEC-001.json#RULE-093; docs/specs/SPEC-001.json#RULE-042; docs/specs/SPEC-001.json#RULE-043; docs/specs/SPEC-001.json#RULE-090; docs/specs/SPEC-001.json#RULE-091; docs/specs/SPEC-001.json#RULE-044; docs/specs/SPEC-001.json#RULE-092; docs/dev/CN-MOD-008.json#anomaly_nk is '<type>:<contact_no>:<campaign_year>[:<item_code>]'; docs/dev/CN-MOD-011.json#anomaly_nk is '<type>:<event_nk>' for event types and '<type>:<rec_id>' for invoice types; docs/design/DES-001.json#anomaly_nk is the event_nk for event-level types and the invoice rec_id for invoice-level types; docs/test/TCS-MOD-011.json#TC-011-025; docs/test/TCS-MOD-011.json#TC-011-026; docs/dev/CN-MOD-008.json#detail names the Campaign Year and the segment invoice (number and rec_id); docs/dev/CN-MOD-008.json#leaves first_detected_at and last_seen_at as they were; docs/dev/CN-MOD-011.json#first_detected_at and last_seen_at are kept; docs/test/TCS-MOD-008.json#TC-008-013; docs/test/TCS-MOD-011.json#TC-011-019; docs/design/DES-001.json#inserts new cases, deletes cases that no longer apply; docs/dev/CN-MOD-008.json#test the Phase 1 anomaly load resolves only its own types and leaves segment and invoice types open -->

### Layercake.usp_load_silv_data_anomaly_segment

The load that keeps the four segment anomaly types in silv_data_anomaly up to date (RULE-025, RULE-026, RULE-052, RULE-053). It looks only at contact-years from 2022 that have a segment invoice, as recorded on the member-year attributes, and only while that invoice is live. A year before 2022, a year whose values were only carried forward from an earlier year, and a year whose segment invoice has been marked as deleted raise nothing.

- **Corporate flag with no scheme.** Raised when the segment invoice's payment method is Corporate and the contact has no live corporate subscription for that Campaign Year: none at all, one for another year only, one marked as deleted, or one whose Sub Status or Sub User Status is not 'Active', including a missing status (assumed, Q-002 and Q-027). Only the segment invoice counts: a Corporate invoice earlier in the year that is not the segment invoice raises nothing.
- **Double payment.** Raised when the segment invoice is settled both by Corporate and by another method, whether or not the contact has a live corporate subscription. Only live payment lines on the invoice's own account that settle it take part; the invoice's own lines and payments posted on another account do not, and an unrecognised payment mode counts as another method. A year can have both a corporate flag and a double payment, giving one row of each.
- **Concession not in reference.** Raised for each concession item code on the segment invoice's own lines that is not in the concession type list, even when another line carries a known concession that sets the year's concession. The same code on several lines, or in spellings that differ only in letter case or trailing spaces, is one case; two different unknown codes are two cases.
- **Full Concession with no concession.** Raised when the contact-year has a Full Concession position and its segment invoice carries no full-rate concession: no concession line at all, or only a reduced concession such as Exceptional Hardship. As confirmed on 2026-11-06, a Full Concession year with no segment invoice raises nothing here: that gap is left to the invoice anomaly EVENT_NO_INVOICE, recorded by the invoice anomaly load (MOD-011), so it is not counted twice.

On each run the load works out every case again and then, in one step:

- adds new cases;
- removes cases that no longer apply, for example after the data has been corrected;
- rewrites the detail of a case that still applies when its text has changed, for example when the year's segment invoice is now a different invoice, keeping its first-detected and last-seen times (see Known limitations);
- leaves every other case untouched, so a second run on unchanged data changes nothing and records 0 inserted, 0 updated and 0 deleted.

It never touches rows of any other anomaly type, Phase 1 or invoice, even for the same contact. It records its run in the load log with the numbers of cases added, rewritten and removed. For what happens when it fails, see the Runbook.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_data_anomaly_segment; docs/design/DES-001.json#Derives the four segment anomaly types for contact-years from 2022 (RULE-025, RULE-026, RULE-052, RULE-053); docs/dev/CN-MOD-008.json#For contact-years from 2022 with a live segment invoice; docs/dev/CN-MOD-008.json#test a soft-deleted segment invoice raises nothing and removes its old case; docs/test/TCS-MOD-008.json#TC-008-001; docs/test/TCS-MOD-008.json#TC-008-003; docs/test/TCS-MOD-008.json#TC-008-004; docs/test/TCS-MOD-008.json#TC-008-005; docs/test/TCS-MOD-008.json#TC-008-006; docs/test/TCS-MOD-008.json#TC-008-007; docs/test/TCS-MOD-008.json#TC-008-008; docs/test/TCS-MOD-008.json#TC-008-026; docs/test/TCS-MOD-008.json#TC-008-009; docs/test/TCS-MOD-008.json#TC-008-010; docs/test/TCS-MOD-008.json#TC-008-011; docs/test/TCS-MOD-008.json#TC-008-012; docs/dev/CN-MOD-008.json#test double payment counts an unrecognised mode as another method but not own lines or other accounts; docs/test/TCS-MOD-008.json#TC-008-018; docs/test/TCS-MOD-008.json#TC-008-019; docs/test/TCS-MOD-008.json#TC-008-020; docs/test/TCS-MOD-008.json#TC-008-021; docs/dev/CN-MOD-008.json#test an unknown code is raised beside a recognised one, and case or trailing-space spellings are one case; docs/test/TCS-MOD-008.json#TC-008-022; docs/test/TCS-MOD-008.json#TC-008-023; docs/test/TCS-MOD-008.json#TC-008-024; docs/answers.md#FULL_CONCESSION_NO_CONCESSION (RULE-053) is raised only for a Full Concession position; docs/answers.md#the missing invoice is MOD-011's EVENT_NO_INVOICE; docs/dev/CN-MOD-008.json#test a Full Concession position in a year with no segment invoice raises nothing; docs/design/DES-001.json#inserts new cases, deletes cases that no longer apply and leaves the rest untouched; docs/test/TCS-MOD-008.json#TC-008-014; docs/dev/CN-MOD-008.json#updates detail on a case that is still raised when the text has changed; docs/dev/CN-MOD-008.json#test a still-raised case with a new segment invoice gets the new detail and keeps first_detected_at; docs/test/TCS-MOD-008.json#TC-008-013; docs/test/TCS-MOD-008.json#TC-008-015; docs/test/TCS-MOD-008.json#TC-008-016 -->

### Layercake.usp_load_silv_data_anomaly_invoice

The load that keeps the six invoice anomaly types in silv_data_anomaly up to date (REQ-009). It works from the pairing of events with invoices held in the event amounts table, silv_event_amount (each event's paired invoice and match outcome), and from the eligible-invoice view, and looks only at events and invoices whose amount Campaign Year is 2022 or later (RULE-093). It never reads an event amount (Q-042).

- **Event with no invoice (EVENT_NO_INVOICE).** Raised for each Join, Renewal or Readmission whose match outcome is 'No eligible invoice'. For example, a 2025 Renewal whose contact has no eligible 2025 invoice gets one row. A corrected invoice that is later paired with the event removes the row on the next run.
- **Event left without an invoice (INVOICE_MATCHES_MULTIPLE_EVENTS).** Raised for each event whose match outcome is 'Invoice shortfall'. For example, a contact with a Renewal and a Readmission in one Campaign Year but one invoice: the Readmission takes the invoice, and the Renewal gets this row rather than EVENT_NO_INVOICE.
- **Invoice with no event (INVOICE_NO_EVENT) and surplus invoice (EVENT_MATCHES_MULTIPLE_INVOICES).** An eligible invoice that no event is paired with is a surplus invoice when the contact has a Join, Renewal or Readmission that takes its amount from the invoice's Campaign Year, and an invoice with no event otherwise. For example, a Renewal with two invoices in its year is paired with the later one, and the earlier one gets EVENT_MATCHES_MULTIPLE_INVOICES; two eligible invoices in a year with no event get one INVOICE_NO_EVENT row each. What counts is the amount Campaign Year, not the event's own: a Join dated in Campaign Year 2024 that takes its amount from 2025 leaves the contact's 2024 invoice with no event. Credit notes, invoices marked as deleted and fee-only invoices are not eligible and raise nothing.
- **Readmission with no fee (READMISSION_FREE or READMISSION_NO_FEE).** For each Readmission paired with an invoice, the load looks among that invoice's own live lines (on its account and voucher) for one whose line type in the line-type mapping is 'readmission fee'; a missing RIC invoice type is matched as empty. A fee line is recognised by its mapped line type, not by how its item code looks, so a line whose item code has no mapping does not count. Lines on another account, payment lines that settle the invoice and lines marked as deleted do not count either. A Readmission with no fee line gets READMISSION_FREE when its date falls in the free-readmission window, and READMISSION_NO_FEE otherwise. A Readmission whose invoice has a fee line raises nothing, and the check applies only to Readmissions: a Renewal paired with an invoice that has no fee line raises nothing, even inside the window.

So every Readmission from 2022 that has no paired invoice, or whose invoice has no readmission fee line, has exactly one row explaining why: EVENT_NO_INVOICE or INVOICE_MATCHES_MULTIPLE_EVENTS where it has no invoice, otherwise READMISSION_FREE or READMISSION_NO_FEE (RULE-044). For example, a Readmission whose event amount leaves the fee out raises no readmission row if its invoice has a fee line, and one whose invoice has no fee line raises one whatever its event amount.

**The free-readmission window** (RULE-092, ADR-004). As agreed on 2026-11-10 (Q-023, Q-032), it is the second quarter of the Readmission's Campaign Year: months four to six counted from the Campaign Year's start date in Layercake.ref_campaign_year_config, the same quarter as Phase 1's campaign quarter Q2. For a Campaign Year starting 1 October, that is 1 January to 31 March inclusive, so a Readmission on 14 February 2025 with no fee line gets READMISSION_FREE, while one on 31 December 2024, 1 April 2025 or 12 August 2025 gets READMISSION_NO_FEE. Because the window is counted from the configured start date, it moves with it: for a Campaign Year starting 1 November, it runs from 1 February to 30 April. The specification's earlier wording, calendar 1 April to 30 June, was corrected on the same date. Two behaviours of this check were decided during the build (see Known limitations).

On each run the load works out every case again and then, in one step:

- adds new cases;
- removes cases that no longer apply, for example after a corrected invoice is paired with its event;
- rewrites the detail of a case that still applies when its text has changed, for example when the paired invoice's number changes, keeping its first-detected and last-seen times;
- leaves every other case untouched, so a second run on unchanged data changes nothing and records 0 inserted, 0 updated and 0 deleted.

It never touches rows of any other anomaly type, segment or Phase 1, open or resolved, even for the same contact. It reads the event amounts table, the bronze invoice and invoice line tables, the line-type mapping and the Phase 1 Campaign Year table, ref_campaign_year_config, and never changes any of them. It records its run in the load log with the numbers of cases added, rewritten and removed. For what happens when it fails, see the Runbook.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_data_anomaly_invoice; docs/design/DES-001.json#Derives the six invoice anomaly types from the match held in silv_event_amount (invoice_rec_id, match_outcome) and from vw_silv_eligible_invoice, for amount Campaign Years from 2022 only (RULE-093); docs/design/DES-001.json#they never read the event amount (RULE-044, Q-042); docs/design/MP-001.json#Builds usp_load_silv_data_anomaly_invoice; docs/dev/CN-MOD-011.json#EVENT_NO_INVOICE: silv_event_amount.match_outcome is 'No eligible invoice'; docs/dev/CN-MOD-011.json#INVOICE_MATCHES_MULTIPLE_EVENTS: match_outcome is 'Invoice shortfall'; docs/dev/CN-MOD-011.json#It is a surplus (EVENT_MATCHES_MULTIPLE_INVOICES) when the contact has any event with that amount Campaign Year, and INVOICE_NO_EVENT otherwise; docs/dev/CN-MOD-011.json#a matched Readmission whose invoice has no live own line typed 'readmission fee'; docs/dev/CN-MOD-011.json#Own lines share the invoice's account and voucher; docs/dev/CN-MOD-011.json#with a NULL ricinvoicetype matched as N''; docs/dev/CN-MOD-011.json#The event amount is never read; docs/dev/CN-MOD-011.json#a still-raised case whose detail changed gets the new detail in place; docs/dev/CN-MOD-011.json#Rows of other anomaly types are never touched; docs/dev/CN-MOD-011.json#test changed invoice number updates the detail in place and logs one update; docs/test/TCS-MOD-011.json#TC-011-001; docs/test/TCS-MOD-011.json#TC-011-003; docs/test/TCS-MOD-011.json#TC-011-004; docs/test/TCS-MOD-011.json#TC-011-005; docs/test/TCS-MOD-011.json#TC-011-006; docs/test/TCS-MOD-011.json#TC-011-007; docs/test/TCS-MOD-011.json#TC-011-008; docs/test/TCS-MOD-011.json#TC-011-009; docs/test/TCS-MOD-011.json#TC-011-010; docs/test/TCS-MOD-011.json#TC-011-011; docs/test/TCS-MOD-011.json#TC-011-012; docs/test/TCS-MOD-011.json#TC-011-013; docs/test/TCS-MOD-011.json#TC-011-014; docs/test/TCS-MOD-011.json#TC-011-015; docs/test/TCS-MOD-011.json#TC-011-016; docs/test/TCS-MOD-011.json#TC-011-017; docs/test/TCS-MOD-011.json#TC-011-018; docs/test/TCS-MOD-011.json#TC-011-019; docs/test/TCS-MOD-011.json#TC-011-021; docs/test/TCS-MOD-011.json#TC-011-022; docs/test/TCS-MOD-011.json#TC-011-023; docs/test/TCS-MOD-011.json#TC-011-025; docs/test/TCS-MOD-011.json#TC-011-026; docs/test/TCS-MOD-011.json#TC-011-029; docs/test/TCS-MOD-011.json#Standard set-up for every test (SetUp); docs/specs/SPEC-001.json#RULE-044; docs/specs/SPEC-001.json#RULE-092; docs/specs/SPEC-001.json#Q-023; docs/design/DES-001.json#Q-032; docs/answers.md#MOD-011 free-readmission window; docs/answers.md#The calendar 1 April to 30 June wording in SPEC-001 RULE-092, its assumption and AC-009-05 was wrong and is corrected; docs/design/adr/ADR-004-free-readmission-window.md#Option A: Second quarter of the Campaign Year; docs/design/adr/ADR-004-free-readmission-window.md#reads campaign_year_start from Layercake.ref_campaign_year_config; docs/dev/CN-MOD-011.json#Choices I made that the design doesn't fix -->

### Change to the Phase 1 load Layercake.usp_load_silv_data_anomaly

The Phase 1 anomaly load keeps its rules and its results. Its resolve step, which marks as resolved (resolved_at) the open rows it no longer detects, now applies only to its own eleven Phase 1 types: ELECTION_NO_ENROLMENT, ELECTION_BEFORE_ENROLMENT, RPQ_WITH_ENROLMENT, STALE_LAPSE_IGNORED, NO_RICS_RECORD, NO_TRANSACTIONS, JOIN_NO_PAYMENT, ENROLMENT_AFTER_FIRST_PAID, ELECTION_AFTER_FIRST_PAID, ENROLMENT_BEFORE_FIRST_PAID and ELECTION_BEFORE_FIRST_PAID. The segment anomalies and the invoice anomalies (MOD-011) are left open for their own loads to look after. As confirmed on 2026-11-06, its results for the Phase 1 types are unchanged. Rolling back MOD-008 restores the Phase 1 definition of this load.

<!-- evidence: docs/answers.md#Anomaly ownership: each anomaly load resolves only the types it detects; docs/answers.md#Its results for the Phase 1 types are unchanged; docs/answers.md#The down script restores the Phase 1 definition; docs/dev/CN-MOD-008.json#its resolve step now stamps resolved_at only on open rows of its own eleven Phase 1 types; docs/dev/CN-MOD-008.json#ELECTION_NO_ENROLMENT, ELECTION_BEFORE_ENROLMENT, RPQ_WITH_ENROLMENT, STALE_LAPSE_IGNORED, NO_RICS_RECORD, NO_TRANSACTIONS, JOIN_NO_PAYMENT, ENROLMENT_AFTER_FIRST_PAID, ELECTION_AFTER_FIRST_PAID, ENROLMENT_BEFORE_FIRST_PAID, ELECTION_BEFORE_FIRST_PAID; docs/dev/CN-MOD-008.json#test the Phase 1 anomaly load resolves only its own types and leaves segment and invoice types open; src/sql/Layercake/Procedures/Layercake.usp_load_silv_data_anomaly.sql#stamp resolved_at, keep the row for audit; docs/design/MP-001.json#Also scopes the Phase 1 usp_load_silv_data_anomaly; docs/answers.md#so the ten new types (MOD-008 and MOD-011) are left to their own loads -->

### Change to the Phase 1 table Layercake.silv_payment_events

The Phase 1 table of paid positions: one row per contact and Campaign Year in which the contact has a paid invoice position (Full Concession, Fully Paid, Partially Paid or Pre-Subs Payment). MOD-009 removes its text column payment_source, and that column's default, because the payer type now lives on the member-year attributes (REQ-006, RULE-027). As confirmed on 2026-11-06 (Q-024 and Q-035), nothing downstream reads the column, and Mike approved its removal. The column only ever held its default value, 'Individual', because the Phase 1 load never wrote it.

Nothing else in the table changes. It keeps its other five columns, contact_no, campaign_year, payment_date, renewal_date_adj and invoice_position, with the same types and the same rules on empty values, and its key on the contact and Campaign Year.

The table's only load, the Phase 1 procedure Layercake.usp_load_silv_payment_events, which runs as part of the Phase 1 silver run (Layercake.usp_load_silver), is unchanged: as confirmed on 2026-11-06 (Q-031), it never named the column (see Known limitations). Testing confirmed that, with the column gone, it still:

- adds the paid positions, leaving out unpaid positions and status rows marked as deleted;
- updates a changed position in place, removes a position that is no longer paid and leaves an unchanged one untouched;
- changes nothing on a second run over unchanged data, recording 0 inserted, 0 updated and 0 deleted;
- fills the payment date from settled, approved cash transactions;
- undoes all its changes when a write fails part-way, records the run as 'Failed' with the error message and reports the error.

<!-- evidence: docs/answers.md#That table holds only the paid invoice positions (Full Concession, Fully Paid, Partially Paid, Pre-Subs Payment); docs/design/DES-001.json#Its text column payment_source is removed, because payer type now lives on silv_member_year_attributes (RULE-027, Q-024); docs/dev/CN-MOD-009.json#MIG-0011 drops the default df_silv_payment_events_src and then the column Layercake.silv_payment_events.payment_source; docs/specs/SPEC-001.json#silv_payment_events.payment_source is removed. Payer type lives on silv_member_year_attributes; docs/answers.md#MOD-009 payment events; docs/answers.md#Mike approves dropping Layercake.silv_payment_events.payment_source. Nothing downstream reads it.; docs/dev/CN-MOD-009.json#This was the only value the column could hold, because the Phase 1 load never wrote it; src/sql/Layercake/Tables/Layercake.silv_payment_events.sql#payment_source retired by MOD-009; docs/test/TCS-MOD-009.json#TC-009-001; docs/test/TCS-MOD-009.json#TC-009-002; docs/test/TCS-MOD-009.json#TC-009-003; docs/answers.md#Layercake.usp_load_silv_payment_events, called by Layercake.usp_load_silver, is the only Phase 1 loader of Layercake.silv_payment_events; src/sql/Layercake/Procedures/Layercake.usp_load_silver.sql#usp_load_silv_payment_events; docs/dev/CN-MOD-009.json#so the procedure is left unchanged and the migration changes only the table; docs/test/TCS-MOD-009.json#TC-009-004; docs/test/TCS-MOD-009.json#TC-009-005; docs/test/TCS-MOD-009.json#TC-009-006; docs/test/TCS-MOD-009.json#TC-009-007; docs/dev/CN-MOD-009.json#test payment events load still takes payment_date from settled approved cash transactions -->

### Change to the Phase 1 table Layercake.brnz_subs_status

The Phase 1 bronze copy of the member invoice statuses, Subs.vwSubsMemberStatuses: one row per contact and Campaign Year, identified by the contact number ([Contact No.]) and Campaign Year ([Campaign Year]) together. Before this change it held each contact-year's Member Invoice Position, Renewal Date and Renewal Date Adj, with the four standard bronze audit columns, and a row that leaves the source is marked as deleted rather than removed. MOD-017 adds two columns, copied one-to-one from the source with no change to any value (REQ-002, RULE-103):

| Column | Source column | Meaning |
|---|---|---|
| inv_total_amount | Inv Total Amount | The contact-year's invoiced total in GBP. In the owner's source it is the invoiced amount over the contact-year's invoices that are not fully credited: the subscription lines in GBP, concession lines included, without the readmission fee lines and with no enrolment, application or other non-subscription amount, except where those lines net to a credit. It holds the same number of digits as the source (up to 32 before the decimal point and 6 after), so no value is narrowed. Empty where the source is empty |
| retired_concession | Retired Concession | One of 'No Invoice', 'No Conc.', 'Retired Conc.' or 'Non-Retired Conc.', exactly as the source gives it. In the owner's source, 'Retired Conc.' means at least one of the contact-year's invoices that is not fully credited carries one of the six retired concession item codes |

Both columns can be empty. Rows landed before the change hold empty values in them until the next run of the load fills them. The table's key, its existing columns, their names and its rows are unchanged; the existing columns keep their Phase 1 names, while the two new columns follow the project's naming standard. No second bronze table is created for this source (Q-043).

retired_concession, with the existing Renewal Date, is read by the derived retirement date view (MOD-018; see Layercake.vw_silv_derived_retirement_date below). inv_total_amount, with the existing Member Invoice Position, is read by the event amount load (MOD-010; see Layercake.silv_event_amount above), which takes each event's invoiced amount from it.

<!-- evidence: docs/design/DES-001.json#Layercake.brnz_subs_status; docs/design/DES-001.json#Existing Phase 1 landing of Subs.vwSubsMemberStatuses, one row per ([Contact No.], [Campaign Year]), with the standard bronze audit columns and soft delete; docs/design/DES-001.json#Its key, its existing columns (Contact No., Campaign Year, Member Invoice Position, Renewal Date, Renewal Date Adj and the audit columns), their names and its rows are unchanged; docs/design/DES-001.json#so rows landed before the change hold null until the next bronze load fills them; src/sql/Layercake/Tables/Layercake.brnz_subs_status.sql#constraint pk_brnz_subs_status primary key clustered ([Contact No.], [Campaign Year]); docs/specs/SPEC-001.json#RULE-103; docs/specs/SPEC-001.json#REQ-002; docs/specs/SPEC-001.json#1:1 (new column, GBP). Null where the source is null.; docs/specs/SPEC-001.json#The source writes 'No Invoice', 'No Conc.', 'Retired Conc.' or 'Non-Retired Conc.'.; docs/design/DES-001.json#'Inv Total Amount', 1:1, GBP. Same type as the source, so no value is narrowed; docs/specs/SPEC-001.json#RULE-033; docs/specs/SPEC-001.json#In the owner's source this is the sum of Invoice_Amount_GBP over the contact-year's invoices whose Payment_Status is not 'Fully Credited'; docs/specs/SPEC-001.json#It excludes RAFEE readmission fee lines and adds no APP or other non-SUB amount, except where the non-SUB lines net to a credit; docs/specs/SPEC-001.json#In the owner's source, 'Retired Conc.' means at least one of the contact-year's invoices that is not fully credited carries one of the six retired item codes (RULE-055); docs/test/TCS-MOD-017.json#TC-017-001; docs/test/TCS-MOD-017.json#TC-017-002; docs/test/TCS-MOD-017.json#TC-017-007; docs/answers.md#Revenue and retirement sources: bronze column names; docs/answers.md#The table's existing Phase 1 columns keep their names; docs/answers.md#Q-043 bronze landing; docs/design/MP-001.json#Builds nothing in silver or gold; docs/design/DES-001.json#That event takes inv_total_amount from the live brnz_subs_status row; docs/specs/SPEC-001.json#Layercake.brnz_subs_status.Member Invoice Position; docs/dev/CN-MOD-010.json#it takes brnz_subs_status.inv_total_amount (live row); docs/design/DES-001.json#vw_silv_derived_retirement_date gives each contact the Renewal Date of its earliest live brnz_subs_status Campaign Year with retired_concession 'Retired Conc.' and a Renewal Date; docs/design/MP-001.json#MOD-010; docs/design/MP-001.json#MOD-018 -->

### Change to the Phase 1 load Layercake.usp_load_brnz_subs_status

The Phase 1 load of brnz_subs_status, which runs in the bronze step of the Phase 1 run (Layercake.usp_load_bronze, called by Layercake.usp_run_daily_load), before any silver load. MOD-017 changes it in two ways only:

- it lands 'Inv Total Amount' and 'Retired Concession' one-to-one with the other columns, on new and on existing rows;
- it treats a difference in either new column as a change: the row is updated in place and its _updated_at refreshed, as for the existing columns. A value that becomes empty, or an empty value that gets a value, counts as a change. Retired Concession is compared exactly, so a change only in letter case or trailing spaces is landed too.

Everything else is as in Phase 1, and testing confirmed it is unchanged:

- on every run it compares the source with the table by contact and Campaign Year, adds new rows, updates changed rows, marks rows gone from the source as deleted (keeping their values) and makes reappearing rows live again, with the source's current values; making a deleted row live again counts as one update;
- unchanged rows are left alone, so a second run on unchanged data changes nothing and records 0 inserted, 0 updated and 0 deleted;
- source rows with no contact number or no Campaign Year are not landed, and where the source has two rows for the same contact and Campaign Year, the one with the latest Renewal Date Adj is kept, together with its values for the two new columns;
- it checks that its live rows equal the number of source rows it keeps (RULE-005);
- it makes all its changes in one step and records its run in the load log, under the layer 'bronze' and the step 'brnz_subs_status'. For what happens when it fails, see the Runbook.

The first run after deployment updates every live row once, to fill the two new columns; after that, a run on unchanged data updates nothing. Rolling back MOD-017 removes the two columns and restores the Phase 1 definition of this load.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_brnz_subs_status; docs/design/DES-001.json#Changed to land inv_total_amount and retired_concession 1:1 with the other columns, and to treat a difference in either as a change; docs/design/DES-001.json#Its key, insert, soft-delete and restore behaviour, row-count check and logging are unchanged; docs/design/DES-001.json#The first run after deployment updates every live row once to fill the new columns; src/sql/Layercake/Procedures/Layercake.usp_load_bronze.sql#usp_load_brnz_subs_status; src/sql/Layercake/Procedures/Layercake.usp_run_daily_load.sql#usp_load_bronze; docs/design/DES-001.json#The last two run inside the Phase 1 run, bronze before silver; docs/dev/CN-MOD-017.json#includes them in its EXCEPT change test, so a change to or from NULL counts as a change; docs/dev/CN-MOD-017.json#retired_concession is compared as varbinary(17), so a source change that differs only in case or trailing spaces is landed too; docs/dev/CN-MOD-017.json#The key, the row_number duplicate guard, insert, soft delete and restore, the row-count check and the logging are unchanged; docs/dev/CN-MOD-017.json#test a soft deleted row restored with unchanged values counts as one update and a gone row as one delete; docs/dev/CN-MOD-017.json#test a duplicate source key keeps the row with the latest Renewal Date Adj and its new columns; docs/dev/CN-MOD-017.json#test a case-only or trailing-space change in Retired Concession is landed byte for byte; src/sql/Layercake/Procedures/Layercake.usp_load_brnz_subs_status.sql#Rows with a null contact are; src/sql/Layercake/Procedures/Layercake.usp_load_brnz_subs_status.sql#order by [Renewal Date Adj] desc; src/sql/Layercake/Procedures/Layercake.usp_load_brnz_subs_status.sql#'bronze', 'brnz_subs_status'; docs/specs/SPEC-001.json#RULE-005; docs/test/TCS-MOD-017.json#TC-017-002; docs/test/TCS-MOD-017.json#TC-017-003; docs/test/TCS-MOD-017.json#TC-017-004; docs/test/TCS-MOD-017.json#TC-017-005; docs/test/TCS-MOD-017.json#TC-017-006; docs/test/TCS-MOD-017.json#TC-017-008; docs/test/TCS-MOD-017.json#TC-017-009; docs/dev/CN-MOD-017.json#The first run after deployment updates every live row once to fill the new columns. A rerun on unchanged source then logs 0/0/0.; docs/dev/CN-MOD-017.json#The down script drops both columns and restores the Phase 1 procedure. -->

### Layercake.vw_silv_derived_retirement_date

The derived retirement date (REQ-017, RULE-099). The hand-entered retirement date in the CRM membership record, apuk_retirementdate, is not always trustworthy, so each contact's retirement date is instead taken from the member invoice statuses: the payment date of the contact's first invoice that carries a retired concession, ignoring fully credited invoices.

The view holds no data of its own and gives one row per contact that has a derived date. It reads only the live rows of brnz_subs_status; rows marked as deleted are ignored. Of a contact's live rows whose Retired Concession is 'Retired Conc.' and whose Renewal Date is present, the one with the earliest Campaign Year gives the date:

| Column | Meaning |
|---|---|
| contact_no | The contact; one row per contact |
| retirement_campaign_year | The Campaign Year of the row that gives the date |
| derived_retirement_date | That row's Renewal Date: the contact-year's first payment date or, for a Full Concession invoice, the date the concession settled the invoice, kept inside the Campaign Year (Q-041) |

- The earliest Campaign Year decides, not the earliest date: a later year whose Renewal Date happens to be earlier does not win.
- A retired-concession year with no Renewal Date is passed over, and the next retired-concession year that has one is used (Q-041).
- Renewal Date is used, not Renewal Date Adj.
- A value that differs from 'Retired Conc.' only in letter case or trailing spaces counts as retired. 'No Invoice', 'No Conc.', 'Non-Retired Conc.' and an empty value do not.
- A contact whose only retired-concession rows are marked as deleted or have no Renewal Date, and a contact with none at all, has no row here and so no derived date. As agreed on 2026-11-06 (Q-040), there is no fallback to apuk_retirementdate or to the source's 'First Retired Year' (RULE-101).

The member base load reads the view (see below), and so does the retirement comparison (MOD-013, see Layercake.usp_report_retirement_comparison), so both use one definition.

<!-- evidence: docs/design/DES-001.json#Layercake.vw_silv_derived_retirement_date; docs/design/DES-001.json#One row per contact that has a derived retirement date (RULE-099); docs/design/DES-001.json#Among the contact's live brnz_subs_status rows (_is_deleted = 0) whose retired_concession is 'Retired Conc.' and whose Renewal Date is not null; docs/design/DES-001.json#Campaign Year of the row that gives the date; docs/design/DES-001.json#That row's Renewal Date: the contact-year's first payment, or a Full Concession invoice's settlement date kept inside the Campaign Year (Q-041); docs/design/DES-001.json#Read by usp_load_silv_member_base and usp_report_retirement_comparison, so both use one definition (ADR-005); docs/specs/SPEC-001.json#REQ-017; docs/specs/SPEC-001.json#RULE-099; docs/specs/SPEC-001.json#RULE-101; docs/specs/SPEC-001.json#Q-040; docs/specs/SPEC-001.json#Q-041; docs/answers.md#Retirement date: apuk_retirementdate is entered by hand and is not always trustworthy; docs/answers.md#ignoring fully credited invoices; docs/test/TCS-MOD-018.json#TC-018-001; docs/test/TCS-MOD-018.json#TC-018-002; docs/test/TCS-MOD-018.json#TC-018-003; docs/test/TCS-MOD-018.json#TC-018-004; docs/test/TCS-MOD-018.json#TC-018-005; docs/test/TCS-MOD-018.json#TC-018-006; docs/dev/CN-MOD-018.json#test a case or trailing space variant of Retired Conc counts as retired; docs/dev/CN-MOD-018.json#test a contact whose only Retired Conc rows are deleted or undated has no row; docs/design/MP-001.json#comparing the retired concession with the derived retirement date from vw_silv_derived_retirement_date; docs/dev/CN-MOD-013.json#the same definition usp_load_silv_member_base uses -->

### Change to the Phase 1 load Layercake.usp_load_silv_member_base

The Phase 1 load of the member base, Layercake.silv_member_base, one row per member, which every later Phase 1 derivation reads. It runs in the silver step of the Phase 1 run (Layercake.usp_load_silver), after the paid positions and before the membership events, and works the whole table out again from its sources on every run.

MOD-018 changes it in one respect only (ADR-005): retirement_date now takes the contact's derived retirement date from vw_silv_derived_retirement_date, in place of apuk_retirementdate from the latest CRM membership record (brnz_rics_record). A member with no derived date gets an empty retirement date, even where apuk_retirementdate is filled in, and a member with a derived date gets it even where apuk_retirementdate is empty.

Everything else is as in Phase 1, and testing confirmed it is unchanged: the same members (a contact with a retired concession who is not a member gets no row, and a member with no member status rows keeps a row with an empty retirement date), every other column, the logging, a second run on unchanged sources giving an identical table, and the error handling (see the Runbook). Rolling back MOD-018 restores the Phase 1 definition of this load.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_member_base; docs/design/DES-001.json#Existing Phase 1 full re-derive of silv_member_base (ADR-005); docs/design/DES-001.json#Changed in one respect only: retirement_date is taken from vw_silv_derived_retirement_date; docs/design/DES-001.json#Every other column, the row set and the logging are unchanged; src/sql/Layercake/Procedures/Layercake.usp_load_silver.sql#the per-contact base every derivation below reads; src/sql/Layercake/Procedures/Layercake.usp_load_silver.sql#exec Layercake.usp_load_silv_member_base; docs/assumptions.md#It is set in one place only: Layercake.usp_load_silv_member_base; docs/specs/SPEC-001.json#RULE-100; docs/specs/SPEC-001.json#RULE-101; docs/test/TCS-MOD-018.json#TC-018-007; docs/test/TCS-MOD-018.json#TC-018-008; docs/test/TCS-MOD-018.json#TC-018-009; docs/test/TCS-MOD-018.json#TC-018-010; docs/test/TCS-MOD-018.json#TC-018-011; docs/dev/CN-MOD-018.json#test the derived date is taken even when the latest rics record has no apuk date; docs/design/MP-001.json#The down script restores the Phase 1 procedure and drops the view -->

### How the derived date reaches Practising / Retired

No other Phase 1 logic changes. The Phase 1 status rule is unchanged: a member is Retired from their retirement date, inclusive, and the rest of the status rule is as before (RULE-100). The Phase 1 loads that set Practising / Retired pick up the derived date as they read the member base today (Q-048):

| Phase 1 table | How it gets the date | When it changes |
|---|---|---|
| silv_membership_events, and the gold fact_membership_events copied from it | The events load reads silv_member_base.retirement_date | On the next Phase 1 run, for every event |
| silv_annual_rate_base, and the gold fact_annual_rate_base | The annual rate base load reads silv_member_base.retirement_date and works the whole table out again on every run | On the next Phase 1 run, for every Campaign Year, past years included |
| silv_daily_count_detail, and the gold fact_daily_member_count_detail | The daily count reads the copy of the date that the member profile load keeps in Layercake.silv_member_profile, in step with the member base | For days not yet loaded, on the next Phase 1 run. Days already loaded keep the old split until a person runs a one-off rebuild (see the Runbook) |

The date sets only the membership status (membership_status_id). As confirmed on 2026-11-09 (Q-048), it does not change which membership events exist or their dates, and the tests confirmed the events keep their identifiers. As agreed on 2026-11-06 (Q-046), counts across statuses do not change.

For example, a member with the hand-entered retirement date 1 June 2021 and the derived date 20 November 2023 now has a Renewal on 20 October 2023 counted as Practising and one on 10 October 2024 counted as Retired, where both were Retired before. A member whose derived date is 15 January 2025 is counted as Practising in the daily counts on 14 January 2025 and as Retired from 15 January 2025.

<!-- evidence: docs/design/MP-001.json#No other Phase 1 logic changes: events, annual rate base, member profile and daily count pick the date up as they read it today; docs/specs/SPEC-001.json#RULE-100; docs/specs/SPEC-001.json#The contact is Retired from that date, inclusive. The rest of the status logic is unchanged.; docs/design/DES-001.json#The Phase 1 status rule is unchanged: a contact is Retired from that date, inclusive; docs/design/DES-001.json#The events load and the annual rate base read it directly and correct themselves on the next run; docs/design/DES-001.json#the daily count reads the copy in silv_member_profile; docs/assumptions.md#silv_member_profile.retirement_date is a diff-synced copy of silv_member_base.retirement_date; src/sql/Layercake/Procedures/Layercake.usp_load_silv_annual_rate_base.sql#does pick up retrospective corrections immediately; src/sql/Layercake/Procedures/Layercake.usp_load_silver.sql#rate base always self-correct regardless; src/sql/Layercake/Procedures/Layercake.usp_run_daily_load.sql#Runs bronze -> silver -> gold; docs/design/DES-001.json#Daily history after the retirement change (ASM-002); docs/design/DES-001.json#fact_daily_member_count_detail re-syncs from silver; docs/answers.md#Q-048; docs/design/DES-001.json#Q-048; docs/specs/SPEC-001.json#Q-046; docs/design/DES-001.json#Only membership_status_id and results split by it change; docs/design/DES-001.json#totals across statuses, event rows and event identifiers do not (Q-046); docs/test/TCS-MOD-018.json#TC-018-012; docs/test/TCS-MOD-018.json#TC-018-013; docs/test/TCS-MOD-018.json#TC-018-015; docs/test/TCS-MOD-018.json#TC-018-016; docs/test/TCS-MOD-018.json#TC-018-017; docs/test/TCS-MOD-018.json#TC-018-018; docs/test/TCS-MOD-018.json#TC-018-019; docs/test/TCS-MOD-018.json#TC-018-020; docs/specs/SPEC-001.json#AC-017-05; docs/specs/SPEC-001.json#AC-017-06 -->

### Change to the Phase 1 load Layercake.usp_load_silv_membership_events

The Phase 1 load of the membership events. It failed with a collation error (error 468) wherever the database's temporary storage, tempdb, uses a different collation from the database itself (for example Latin1_General_CI_AS against SQL_Latin1_General_CP1_CI_AS), because the text columns of its working table did not state a collation. As agreed on 2026-11-09, MOD-018 corrects this, and that is the only change: the five text columns of the working table now take the database's collation.

Its event logic, the events it writes and its logging are unchanged, and it still reads the member base's retirement date for the status. Testing confirmed that it writes a Join and two Renewals with the expected statuses, that a second run on unchanged data changes nothing, and that clearing a retirement date updates one event in place, keeping its identifier. Rolling back MOD-018 restores the Phase 1 definition of this load.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_membership_events; docs/design/DES-001.json#so the procedure compiles where tempdb's collation differs from the database's (error 468 against silv_payment_events.contact_no); docs/design/DES-001.json#Its event logic, row set and logging are unchanged, and it still reads silv_member_base.retirement_date for status (ADR-005); docs/answers.md#MOD-018 events load collation; docs/answers.md#Latin1_General_CI_AS against SQL_Latin1_General_CP1_CI_AS; docs/answers.md#the only change is COLLATE DATABASE_DEFAULT on those columns; docs/dev/CN-MOD-018.json#the five string columns of #ev_stage (event_nk, event_type, event_subtype, contact_no, campaign_quarter) are now declared COLLATE DATABASE_DEFAULT; docs/dev/CN-MOD-018.json#test the events load runs where tempdb collation differs and a rerun changes nothing; docs/dev/CN-MOD-018.json#that clearing the date updates one event in place with the same event_id; docs/design/adr/ADR-005-where-the-derived-retirement-date-replaces-apuk-retirementda.md#the down script restores the Phase 1 definition -->

### Layercake.usp_profile_custtrans_grain

A count-only profile of synapse_fo.CUSTTRANS_RICS, to help answer Q-021 (RULE-095, AC-014-07). It takes no parameters, reads only the source and writes nothing.

It looks only at invoice rows: rows with transaction type 8 or 24, and rows whose invoice number contains 'CRE' or 'FTCN', are left out. Each invoice is identified by account number and invoice number together, so one invoice number on two accounts counts as two invoices.

For each invoice it measures the number of rows (rows_per_invoice), the number of different item codes (distinct_productcodes) and whether the invoice has a 'Sales tax' row (has_sales_tax_row). It returns one row per measure and value, with the number of invoices that have that value; for example, how many invoices have 3 rows. It returns counts only, never individual invoices or contacts.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_profile_custtrans_grain; docs/specs/SPEC-001.json#RULE-095; docs/specs/SPEC-001.json#AC-014-07; docs/dev/CN-MOD-001.json#rows_per_invoice; docs/dev/CN-MOD-001.json#Result shape of both procedures is not defined in DES-001; docs/test/TCS-MOD-001.json#TC-001-001; docs/test/TCS-MOD-001.json#TC-001-002; docs/test/TCS-MOD-001.json#TC-001-003; docs/dev/CN-MOD-001.json#Neither takes parameters -->

### Layercake.usp_profile_corp_subscription_status

A count-only profile of Subs.vwCorpSubscriptions, to help answer Q-027 (RULE-096, AC-014-08). It takes no parameters, reads only the source and writes nothing. It counts source rows (not contacts) by each value of 'Sub Status' and by each value of 'Sub User Status', listing every value it finds, and returns one row per status column and value with its row count.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_profile_corp_subscription_status; docs/specs/SPEC-001.json#RULE-096; docs/specs/SPEC-001.json#AC-014-08; docs/test/TCS-MOD-001.json#TC-001-004; docs/test/TCS-MOD-001.json#TC-001-005; docs/dev/CN-MOD-001.json#Result shape of both procedures is not defined in DES-001 -->

### Layercake.usp_report_retirement_comparison

A count-only report that compares, for each Campaign Year, the retired concession with the derived retirement date over the paid positions (REQ-012, RULE-055 to RULE-058). Mike runs it on real data; looking at examples of disagreements is a step for a person. It takes one optional parameter, an as-of date, which it accepts but does not use (ADR-003 gives every report one).

- **Paid positions.** Each row of the Phase 1 table Layercake.silv_payment_events is one paid position, for its contact and Campaign Year. The comparison covers paid positions, not all members (assumed, Q-018).
- **Retired concession.** A paid position has a retired concession when the concession on the contact's member-year attributes for that Campaign Year has one of the six retired item codes in the concession type list: CONPWRQ1, CONPWRQ2, CONPWRQ3, CONRETIRED, CONRETIREDFL or CONRETIREDSPECIAL (RULE-055, assumed, Q-018). Letter case is ignored. Other codes, including look-alikes such as CONRETIREDX and CONPWRQ4, the reserved values and No concession are not retired. A paid position with no attributes row has no retired concession.
- **Derived retirement date.** Taken from vw_silv_derived_retirement_date, the same definition the member base uses. It counts only when it is on or before the end of that Campaign Year (campaign_year_end in Layercake.ref_campaign_year_config), in every group (RULE-056). A date after the year end means the contact first retired in a later Campaign Year, so it does not count for this one (see Known limitations).
- **The hand-entered date plays no part.** As confirmed on 2026-11-11, the report compares the retired concession with the derived date only; it reads neither apuk_retirementdate nor the member base (RULE-058).

Each paid position falls in exactly one of four groups. The result has one row per Campaign Year with at least one paid position, in Campaign Year order:

| Column | Meaning |
|---|---|
| campaign_year | The Campaign Year |
| paid_positions | The number of paid positions that year |
| retired_concession_and_date | A retired concession and a derived retirement date on or before the year end |
| retired_concession_only | A retired concession, but no derived date on or before the year end |
| derived_date_only | A derived date on or before the year end, but no retired concession |
| neither | Neither a retired concession nor a derived date on or before the year end |
| agreement_rate_pct | retired_concession_and_date plus neither, as a percentage of paid_positions, to one decimal place: 70.0 means 70.0% |

For example, ten 2025 paid positions, 4 with both, 1 with a retired concession only, 2 with a derived date only and 3 with neither, give an agreement rate of 70.0 (AC-012-01). A derived date of 30 September 2025 counts for Campaign Year 2025, and one of 1 October 2025 does not. A contact with retired-concession rows in several years still counts once per paid position.

It returns counts and a rate only, with no contact number or other contact-level column (RULE-057, AC-012-02), and changes no status or data: testing confirmed that the member base, the member-year attributes and the paid positions are the same before and after it runs. The layout of the result, and some of these behaviours, were set during the build (see Known limitations).

<!-- evidence: docs/design/DES-001.json#Layercake.usp_report_retirement_comparison; docs/specs/SPEC-001.json#REQ-012; docs/specs/SPEC-001.json#RULE-055; docs/specs/SPEC-001.json#RULE-056; docs/specs/SPEC-001.json#RULE-057; docs/specs/SPEC-001.json#RULE-058; docs/specs/SPEC-001.json#Mike runs it on real data, and examples of disagreements are a human step.; docs/specs/SPEC-001.json#Q-018; docs/specs/SPEC-001.json#Retired concessions are the six retired item codes used by Subs.usp_Refresh_SubsInvoices, and the comparison covers paid positions (Q-018).; docs/answers.md#MOD-013 retirement comparison scope; docs/assumptions.md#One optional parameter, @as_of_date date = NULL, which this report ignores (ADR-003: every report takes one); docs/assumptions.md#agreement_rate_pct decimal(5,1), where 70.0 means 70.0%; docs/assumptions.md#a derived date after the year end says the contact first retired in a later Campaign Year; docs/dev/CN-MOD-013.json#@as_of_date date = NULL (accepted and ignored, ADR-003); docs/dev/CN-MOD-013.json#It returns one row per Campaign Year that has a silv_payment_events row, ordered by campaign_year, with the seven columns from ASM-004; docs/dev/CN-MOD-013.json#Retired concession: the year's silv_member_year_attributes.concession_type_id joined to silv_ref_concession_type.item_code; docs/dev/CN-MOD-013.json#The match uses the database collation, so it ignores case; docs/dev/CN-MOD-013.json#A paid position with no attributes row has no retired concession; docs/dev/CN-MOD-013.json#the same definition usp_load_silv_member_base uses; docs/dev/CN-MOD-013.json#It counts only when it is on or before that year's campaign_year_end, in every group (ASM-005); docs/dev/CN-MOD-013.json#apuk_retirementdate and silv_member_base are not read.; docs/dev/CN-MOD-013.json#Every join is on a unique key, so no position is counted twice; docs/test/TCS-MOD-013.json#TC-013-001; docs/test/TCS-MOD-013.json#TC-013-002; docs/test/TCS-MOD-013.json#TC-013-005; docs/test/TCS-MOD-013.json#TC-013-006; docs/test/TCS-MOD-013.json#TC-013-008; docs/test/TCS-MOD-013.json#TC-013-009; docs/test/TCS-MOD-013.json#TC-013-010; docs/test/TCS-MOD-013.json#TC-013-011; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Read-only procedures with an as-of date -->

## Design decisions

The design records its main decisions in architecture decision records (ADRs):

| Decision | What it means for the client |
|---|---|
| ADR-001 How segment keys and amounts reach the event tables | The Phase 1 loads stay as they are. All new loads run as one block after the Phase 1 run, through a new run procedure, Layercake.usp_run_payment_segments, which a person schedules after the Phase 1 run once a later module (MOD-016) delivers it. This keeps the Phase 1 logic unchanged, which is the main risk to Phase 1 results. The new event columns were added with defaults (MOD-007) and are filled by two new loads (MOD-012), so between the Phase 1 load and those loads they briefly hold their defaults. The recommendation was provisional on Q-031: if a Phase 1 event or fact load rebuilt its table in full each run, the new columns would be written in that load instead. Both Phase 1 loads apply only the changes rather than rebuilding (the silver event load by event_nk, the gold fact load by event_id), and MOD-012 delivers the two new loads for both tables. |
| ADR-002 Persisting per-event invoice matches and amounts | The pairing of events with their invoices is worked out once, in its own silver table, Layercake.silv_event_amount, with its own load (Option A), rather than being repeated inside each load that needs it. The invoice anomalies (MOD-011) and the event columns (MOD-012) both read that one table, so an event's amount status and its invoice anomalies cannot disagree. The cost is one more table, with about one row per Join, Renewal and Readmission, and one more load. The record was written when the amounts were to come from the invoices; under the amended specification the same table holds the amounts taken from the member invoice statuses, and the pairing is kept for the invoice checks only. |
| ADR-003 Delivery of the count-only profiling and findings queries | The profiling and findings queries are built as read-only procedures in Layercake (Option A), rather than views or undeployed scripts, so they can be tested and are deployed and versioned with the solution. Running them needs only EXECUTE permission. They must be deployed to production before Mike can run them there. |
| ADR-004 Free-readmission window | A Readmission with no readmission fee counts as free when its date falls in the second quarter of its Campaign Year, counted from the Campaign Year's start date in Layercake.ref_campaign_year_config (Option A), rather than in calendar April to June (Option B). It follows the Campaign Year if its start date ever moves. As agreed on 2026-11-10 (Q-032), this is 1 January to 31 March for a Campaign Year starting 1 October, and the specification's earlier calendar wording was corrected to match. The window is a single rule in the invoice anomaly load (MOD-011). |
| ADR-005 Where the derived retirement date replaces apuk_retirementdate | The derived date replaces the value at its single source (Option A): only the Phase 1 member base load changes, so every Phase 1 load that sets Practising / Retired uses the derived date, none can be missed, and the change and its rollback stay small. Phase 1's own pending-rebuild mechanism carries the change to the daily counts. The cost is that the member base no longer shows the hand-entered apuk_retirementdate; it is still in the bronze CRM record table, brnz_rics_record, and in the reconciliation diagnostic columns (see Known limitations). The rejected option kept both dates side by side and changed several more Phase 1 tables and procedures. |

ADR-001 says the member-year attributes take their contact list from the Phase 1 event derivation inputs. As confirmed on 2026-10-27, they take it from the Phase 1 event table itself, silv_membership_events, so the attributes load runs after the Phase 1 run, which fits the run order ADR-001 recommends. The event amount load also reads the Phase 1 event table and paid positions, so it too runs after the Phase 1 run, and the invoice anomaly load, which reads the event amounts, runs after it. The silver event column load reads the attributes and the event amounts, so it runs after both, and the gold event column load copies from it, so it runs last.

The amended design changes four Phase 1 procedures:

- the load of silv_payment_events, which the design says stops writing the old payment source column. As confirmed on 2026-11-06 (Q-031), that procedure never wrote the column, so MOD-009 removes the column without changing the procedure (see Data model and Known limitations);
- the Phase 1 anomaly load, which MOD-008 changes, as confirmed on 2026-11-06, so that each anomaly load looks after only its own anomaly types and the Phase 1 load does not mark the new types as resolved (see Data model). Its results for the Phase 1 types are unchanged;
- the load of brnz_subs_status, which MOD-017 changes to land two more columns (see Data model);
- the load of silv_member_base, which MOD-018 changes to take the derived retirement date (ADR-005, see Data model).

As agreed on 2026-11-09, MOD-018 also changes a fifth, the events load, only so that it runs where tempdb's collation differs from the database's; its event logic is unchanged (see Data model and Known limitations). MOD-012 changes no Phase 1 procedure: the segments and amounts reach the event tables through its two new loads.

The member status load and the member base load run inside the Phase 1 run, bronze before silver, so the two new member status columns, and with them the derived retirement date, are current before any Phase 1 status is set, and before any of the new loads that run after the Phase 1 run.

The decision on all five records is still pending, although the question ADR-004 depended on, Q-032, was answered on 2026-11-10 (see Known limitations).

<!-- evidence: docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Layercake.usp_run_payment_segments; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#which a human schedules after the Phase 1 run; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#the new columns briefly hold their defaults; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Q-031; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#if the Phase 1 event or fact load rebuilds its table in full each run, the in-place option should be used for that table; docs/assumptions.md#a diff-sync on event_nk; src/sql/Layercake/Procedures/Layercake.usp_load_fact_membership_events.sql#Diff-sync on event_id; docs/design/MP-001.json#per ADR-001; docs/design/adr/ADR-002-persisting-per-event-invoice-matches-and-amounts.md#Option A: Persisted silver match table; docs/design/adr/ADR-002-persisting-per-event-invoice-matches-and-amounts.md#The pairing runs once and has one tested home; docs/design/adr/ADR-002-persisting-per-event-invoice-matches-and-amounts.md#one more table (about one row per Join, Renewal and Readmission event) and one more load step; docs/design/adr/ADR-002-persisting-per-event-invoice-matches-and-amounts.md#Its amounts and amount_status come from that invoice; docs/design/adr/ADR-002-persisting-per-event-invoice-matches-and-amounts.md#Pending: filled in by a human at the architecture validation gate; docs/design/DES-001.json#kept for the REQ-009 invoice checks only and never used for the amount (Q-042); docs/specs/SPEC-001.json#Q-038; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Option A; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Running them needs only EXECUTE; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#they must be deployed to production before Mike can run them there; docs/design/adr/ADR-004-free-readmission-window.md#Option A: Second quarter of the Campaign Year; docs/design/adr/ADR-004-free-readmission-window.md#Option B: Calendar 1 April to 30 June; docs/design/adr/ADR-004-free-readmission-window.md#follows the Campaign Year if its start date ever moves; docs/design/adr/ADR-004-free-readmission-window.md#The window is a single rule in the invoice anomaly load; docs/design/adr/ADR-004-free-readmission-window.md#Q-032 is answered; docs/design/adr/ADR-004-free-readmission-window.md#Pending: filled in by a human at the architecture validation gate; docs/answers.md#MOD-011 free-readmission window; docs/design/adr/ADR-005-where-the-derived-retirement-date-replaces-apuk-retirementda.md#Option A; docs/design/adr/ADR-005-where-the-derived-retirement-date-replaces-apuk-retirementda.md#it stays in bronze brnz_rics_record and in the reconciliation diagnostic columns; docs/design/adr/ADR-005-where-the-derived-retirement-date-replaces-apuk-retirementda.md#Pending: filled in by a human at the architecture validation gate; docs/answers.md#silv_member_base is not used; docs/answers.md#Contact list and first-event year (RULE-011, Q-030); docs/design/DES-001.json#Run order (ADR-001); docs/design/DES-001.json#the segment and invoice anomalies; docs/design/DES-001.json#the silver event columns; docs/design/DES-001.json#the gold fact columns; docs/design/DES-001.json#Four Phase 1 procedures change; docs/answers.md#MOD-009 payment events; docs/answers.md#Anomaly ownership: each anomaly load resolves only the types it detects; docs/answers.md#MOD-018 events load collation; docs/design/MP-001.json#Changes no Phase 1 column, row or procedure; docs/design/DES-001.json#The last two run inside the Phase 1 run, bronze before silver; docs/test/TCS-MOD-010.json#Standard set-up for every test -->
