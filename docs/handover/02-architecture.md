# Architecture and data model: RICS Payment Segment Tracker

## Architecture overview

The solution extends the Phase 1 Layercake membership solution. All new objects live in the Layercake schema and follow the Phase 1 naming conventions. The design has bronze tables (one-to-one landings of source data), silver tables (reference lists, attributes and matches), gold dimensions and fact columns, and a set of read-only reporting procedures that return aggregates only (counts, sums and rates). Every change ships as a migration with a tested rollback script.

So far only the reporting procedures delivered by MOD-001 are in place: two source profiles, named usp_profile_*. They read two sources owned by other systems (see the Data lineage document), write nothing and build no tables. They are meant to be run before the invoice build, so that their results can settle two open questions the build depends on (see Known limitations).

<!-- evidence: docs/design/DES-001.json#Extends the Phase 1 Layercake membership solution; docs/design/DES-001.json#reporting queries; docs/design/MP-001.json#Builds no tables and changes no existing object; docs/dev/CN-MOD-001.json#Neither writes anything; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#before the invoice build -->

## Data model

MOD-001 adds no tables, views or columns. It adds two procedures. Neither takes parameters, and each returns one result set of counts.

<!-- evidence: docs/design/MP-001.json#Builds no tables and changes no existing object; docs/dev/CN-MOD-001.json#Neither takes parameters -->

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

| Decision | What it means for MOD-001 |
|---|---|
| ADR-003 Delivery of the count-only profiling and findings queries | The profiling and findings queries are built as read-only procedures in Layercake (Option A), rather than views or undeployed scripts. They can be tested automatically on synthetic data, are versioned and deployed with the solution, and need only EXECUTE permission to run. In return, they must be deployed to production before they can be run there. The two source profiles were made a separate early module so they can be deployed and run before the invoice build. |

ADR-003 recommends Option A, and the design built on it was approved on 2026-10-25, but the ADR's own decision record is still marked as pending.

<!-- evidence: docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Option A: Read-only procedures with an as-of date; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Running them needs only EXECUTE; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Pending: filled in by a human at the architecture validation gate; docs/design/DES-001.json#architecture_validation -->
