# Architecture and data model: RICS Payment Segment Tracker

## Architecture overview

The solution extends the Phase 1 Layercake membership solution. All new objects live in the Layercake schema and follow the Phase 1 naming conventions. The design has bronze tables (one-to-one landings of source data), silver tables (reference lists, attributes and matches), gold dimensions and fact columns, and a set of read-only reporting procedures that return aggregates only (counts, sums and rates). Every change ships as a migration with a tested rollback script.

Two layers are in place so far:

- **Reporting procedures (MOD-001):** two source profiles, named usp_profile_*. They read two sources owned by other systems (see the Data lineage document), write nothing and build no tables. They are meant to be run before the invoice build, so that their results can settle two open questions the build depends on (see Known limitations).
- **Bronze (MOD-002):** two tables, brnz_subs_invoice and brnz_subs_invoice_line, with a load procedure each. They copy subscription invoice data from sources already in the warehouse with no change to any value, and carry the same four audit columns as the Phase 1 bronze tables. Each load records its run in the load log, Layercake.etl_run_log. Later modules build the silver and gold layers on these tables.

<!-- evidence: docs/design/DES-001.json#Extends the Phase 1 Layercake membership solution; docs/design/DES-001.json#reporting queries; docs/design/MP-001.json#Builds no tables and changes no existing object; docs/dev/CN-MOD-001.json#Neither writes anything; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#before the invoice build; docs/design/DES-001.json#1:1 landings of external sources; docs/specs/SPEC-001.json#RULE-004; docs/design/DES-001.json#load logging; docs/design/MP-001.json#Subscription invoice bronze -->

## Data model

MOD-001 adds two procedures and no tables. MOD-002 adds two bronze tables and two load procedures. No existing object is changed.

<!-- evidence: docs/design/MP-001.json#Builds no tables and changes no existing object; docs/dev/CN-MOD-002.json#objects_changed -->

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

### Layercake.usp_profile_custtrans_grain

A count-only profile of the grain of synapse_fo.CUSTTRANS_RICS (RULE-095, for open question Q-021). It takes the invoice rows only: it leaves out rows with transaction type 8 or 24, and rows whose invoice number contains 'CRE' or 'FTCN'. It groups those rows into invoices by account number and invoice number, so the same invoice number on two accounts counts as two invoices. It then counts invoices three ways:

| Measure | Values | What it counts |
|---|---|---|
| rows_per_invoice | the number of rows, for example '1' or '3' | invoices with that many rows |
| distinct_productcodes | the number of different item codes, for example '1' or '2' | invoices with that many different item codes |
| has_sales_tax_row | '1' or '0' | invoices with, or without, a row whose posting type is 'Sales tax' |

Each row of the result gives a measure, a value and the number of invoices with it. Only values that occur are listed.

Rows with no transaction type or no invoice number are not counted as invoice rows, and a row with no item code adds nothing to the count of different item codes. See Known limitations.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_profile_custtrans_grain; docs/specs/SPEC-001.json#RULE-095; docs/specs/SPEC-001.json#Q-021; docs/dev/CN-MOD-001.json#rows_per_invoice; docs/test/TCS-MOD-001.json#TC-001-002; docs/test/TCS-MOD-001.json#TC-001-003 -->

### Layercake.usp_profile_corp_subscription_status

A count-only profile of Subs.vwCorpSubscriptions (RULE-096, for open question Q-027). It returns the number of source rows for each value of 'Sub Status' and, separately, for each value of 'Sub User Status'. It counts rows, not distinct contacts or years. It lists every value it finds, not only Active and Inactive, and a missing status is listed as its own value. Each row of the result gives the status column, the value and the number of rows.

<!-- evidence: docs/design/DES-001.json#Layercake.usp_profile_corp_subscription_status; docs/specs/SPEC-001.json#RULE-096; docs/specs/SPEC-001.json#Q-027; docs/dev/CN-MOD-001.json#status_column; docs/test/TCS-MOD-001.json#TC-001-005; docs/dev/CN-MOD-001.json#lists a missing status as its own NULL value -->

## Design decisions

Design decisions are recorded as ADRs (architecture decision records, ADR-nnn).

| Decision | What it means so far |
|---|---|
| ADR-001 How segment keys and amounts reach the event tables | All the new loads, including the two bronze loads from MOD-002, are to run as one block after the Phase 1 run, through a run procedure (Layercake.usp_run_payment_segments) that a later module (MOD-016) adds. Phase 1 procedures stay as they are, which keeps Phase 1 results unchanged. |
| ADR-003 Delivery of the count-only profiling and findings queries | The profiling and findings queries are built as read-only procedures in Layercake (Option A), rather than views or undeployed scripts. They can be tested automatically on synthetic data, are versioned and deployed with the solution, and need only EXECUTE permission to run. In return, they must be deployed to production before they can be run there. The two source profiles were made a separate early module so they can be deployed and run before the invoice build. |

The design built on both ADRs' recommendations (Option A in each) was approved on 2026-10-25, but each ADR's own decision record is still marked as pending.

<!-- evidence: docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Option A: Post-Phase-1 enrichment block; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#MOD-016 adds the run procedure; docs/design/DES-001.json#All new loads run as one block after the Phase 1 run (ADR-001); docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Pending: filled in by a human at the architecture validation gate; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Option A: Read-only procedures with an as-of date; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Running them needs only EXECUTE; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Pending: filled in by a human at the architecture validation gate; docs/design/DES-001.json#architecture_validation -->
