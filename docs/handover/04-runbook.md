# Operational runbook: RICS Payment Segment Tracker

## Components and load order

The solution so far has eight loads (MOD-002 to MOD-005) and two read-only profiles (MOD-001):

| Component | What it does | Parameters |
|---|---|---|
| Layercake.usp_load_brnz_subs_invoice | Load: brings Layercake.brnz_subs_invoice up to date with Subs.tblSubsInvoices | None |
| Layercake.usp_load_brnz_subs_invoice_line | Load: brings Layercake.brnz_subs_invoice_line up to date with the in-scope rows of synapse_fo.CUSTTRANS_RICS | None |
| Layercake.usp_load_brnz_corporate_subscription | Load: brings Layercake.brnz_corporate_subscription up to date with Subs.vwCorpSubscriptions | None |
| Layercake.usp_load_dim_payment_method | Load: brings Layercake.dim_payment_method into step with the payment method list, Layercake.silv_ref_payment_method | None |
| Layercake.usp_load_dim_payer_type | Load: brings Layercake.dim_payer_type into step with the payer type list, Layercake.silv_ref_payer_type | None |
| Layercake.usp_load_silv_ref_invoice_line_type | Load: adds new item codes from Layercake.brnz_subs_invoice_line to the line-type mapping, Layercake.silv_ref_invoice_line_type, as 'unmapped' | None |
| Layercake.usp_load_silv_ref_currency | Load: adds new currency codes from Layercake.brnz_subs_invoice to the currency list, Layercake.silv_ref_currency | None |
| Layercake.usp_load_dim_currency | Load: brings Layercake.dim_currency into step with the currency list | None |
| Layercake.usp_profile_custtrans_grain | Profile: the grain of synapse_fo.CUSTTRANS_RICS, for open question Q-021 | None |
| Layercake.usp_profile_corp_subscription_status | Profile: the status values in Subs.vwCorpSubscriptions, for open question Q-027 | None |

The payment method and payer type lists and the mapping function, Layercake.fn_map_payment_method, are not run on their own: the lists are put in place by their migrations, and later modules use the function inside their loads.

Three of the MOD-005 loads read the output of another load, so they must run after it:

1. usp_load_silv_ref_currency reads brnz_subs_invoice, so it runs after usp_load_brnz_subs_invoice.
2. usp_load_dim_currency reads the currency list, so it runs after usp_load_silv_ref_currency.
3. usp_load_silv_ref_invoice_line_type reads brnz_subs_invoice_line, so it runs after usp_load_brnz_subs_invoice_line.

The other loads do not read another load's table: the line load takes its list of invoices directly from Subs.tblSubsInvoices, the corporate subscription load reads only its source, and the payment method and payer type dimension loads read only their lists, which no load writes. In the design, all the loads run as part of one run procedure, Layercake.usp_run_payment_segments, which runs every new load in dependency order after the Phase 1 run. That run procedure comes in a later module (MOD-016).

The three dimensions are not filled by their migrations. Each stays empty until its load is first run (for the currency dimension, after the currency list load). Until the run procedure is delivered, the MOD-005 loads and the three dimension loads are run by hand (see Deployment and rollback).

The two profiles do not depend on each other and can be run in either order. They are intended to be run on real data before the invoice build, so their results can answer Q-021 and Q-027 (see Known limitations).

<!-- evidence: docs/dev/CN-MOD-002.json#objects_changed; docs/dev/CN-MOD-003.json#objects_changed; docs/dev/CN-MOD-004.json#objects_changed; docs/dev/CN-MOD-005.json#objects_changed; docs/design/MP-001.json#MOD-002; docs/design/MP-001.json#MOD-003; docs/design/MP-001.json#MOD-004; docs/design/MP-001.json#MOD-005; docs/design/DES-001.json#Adds each (productcode, ricinvoicetype) seen in live brnz_subs_invoice_line rows; docs/design/DES-001.json#(brnz_subs_invoice.inv_currency); docs/design/DES-001.json#Mirrors silv_ref_currency into dim_currency. Logged.; docs/dev/CN-MOD-005.json#dim_currency is empty after the migration until usp_load_silv_ref_currency and then usp_load_dim_currency run (by hand until MOD-016); docs/dev/CN-MOD-002.json#Line scope (RULE-077) reads Subs.tblSubsInvoices directly; docs/design/DES-001.json#1:1 landing of Subs.vwCorpSubscriptions; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type; docs/design/DES-001.json#Reference lists: payment method and payer type are static lists seeded by their migrations; docs/answers.md#MOD-003 fn_map_payment_method; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Layercake.usp_run_payment_segments; docs/design/MP-001.json#runs every new load in dependency order after the Phase 1 run; docs/answers.md#MOD-003 dim_payment_method population; docs/answers.md#The same applies to the other gold dimensions over seeded reference lists; docs/dev/CN-MOD-004.json#dim_payer_type is not seeded; docs/design/MP-001.json#MOD-001; docs/design/MP-001.json#so Mike can run them before the invoice build; docs/dev/CN-MOD-001.json#Neither takes parameters; docs/specs/SPEC-001.json#Q-021; docs/specs/SPEC-001.json#Q-027 -->

## Scheduling

The loads are designed to run after the Phase 1 run, through the run procedure that a person schedules once it is delivered (MOD-016). The schedule itself (when and how often the run happens) is still to be confirmed.

The profiles are not part of any scheduled load. Mike runs them on real data when the answers are needed and brings the results back as answers to the open questions.

<!-- evidence: docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#which a human schedules after the Phase 1 run; docs/design/DES-001.json#runs after the Phase 1 run; docs/specs/SPEC-001.json#REQ-014; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Mike runs them on real data -->

## Monitoring

Each load records one row per run in the load log, Layercake.etl_run_log, with:

- its outcome: 'Success' or 'Failed';
- the numbers of rows inserted, updated and deleted (for the bronze loads, marked as deleted) in its table;
- for a failed run, the error message.

A second run on unchanged data records 0 inserted, 0 updated and 0 deleted. Each bronze load also checks that its table's live rows equal the source rows in scope (RULE-005); a mismatch fails the run, so it shows as 'Failed' in the log. In the corporate subscription load, making a deleted row live again is counted as an update. The three dimension loads never remove rows, so their deleted count is always 0. The line-type mapping and currency list loads only add rows, so they record only rows inserted.

New rows in the line-type mapping arrive as 'unmapped'. A run of usp_load_silv_ref_invoice_line_type that records rows inserted means new item codes have appeared that a person needs to map by hand (see Known limitations).

The profiles do not record a run in the load log, because they load nothing. Their output is the result set they return, which holds counts only, with no personal data.

<!-- evidence: docs/specs/SPEC-001.json#RULE-005; docs/dev/CN-MOD-002.json#with status 'Success' or 'Failed'; docs/test/TCS-MOD-002.json#TC-002-004; docs/test/TCS-MOD-002.json#TC-002-005; docs/test/TCS-MOD-002.json#TC-002-010; docs/dev/CN-MOD-002.json#A row-count mismatch between live rows and the source (RULE-005) also fails the load; docs/dev/CN-MOD-004.json#The live row count is checked against the source count (RULE-005); docs/dev/CN-MOD-004.json#Restoring a soft-deleted row counts as an update; docs/test/TCS-MOD-004.json#TC-004-013; docs/test/TCS-MOD-004.json#TC-004-019; docs/test/TCS-MOD-003.json#TC-003-008; docs/test/TCS-MOD-003.json#TC-003-011; docs/dev/CN-MOD-003.json#rows_deleted is always 0; docs/dev/CN-MOD-004.json#The load never deletes from the dimension; docs/test/TCS-MOD-004.json#TC-004-003; docs/dev/CN-MOD-005.json#never deletes; docs/dev/CN-MOD-005.json#are insert-only; docs/test/TCS-MOD-005.json#TC-005-001; docs/test/TCS-MOD-005.json#TC-005-002; docs/test/TCS-MOD-005.json#TC-005-016; docs/test/TCS-MOD-005.json#TC-005-018; docs/dev/CN-MOD-005.json#must be mapped by hand before MOD-010's amounts are complete; docs/dev/CN-MOD-001.json#Neither writes anything or logs a load; docs/design/DES-001.json#Every count-only procedure returns aggregates only -->

## Error handling

Each bronze load checks the source data against its table's column types before it writes anything, and makes all its changes in one step. If any value does not fit, the source has two rows with the same key, a write is rejected, or the row-count check fails, the load:

- stops and reports the error to whatever ran it;
- records the run as 'Failed' in Layercake.etl_run_log, with the error message;
- leaves its table exactly as it was before the run.

For the corporate subscription load, the key is the contact number, scheme number and Campaign Year together. A source row where any of the three is missing fails the whole load in the same way; no row is skipped. So does a second source row with the same three values as another (see Known limitations).

The dimension loads and the MOD-005 list loads also make all their changes in one step. If any write is rejected, the load reports the error, records the run as 'Failed' with the error message, and undoes everything the run had done, including any name or code it had already corrected. A failed line-type mapping or currency list load adds no row at all, not even part of a run.

In plain terms, a failed load changes nothing, so it can simply be run again once the cause is dealt with.

The profiles only read their sources and write nothing, so a failed or interrupted profile run leaves the database exactly as it was.

<!-- evidence: docs/dev/CN-MOD-002.json#Both loads stage the source in the target's column types before the transaction; docs/dev/CN-MOD-002.json#logged Failed in Layercake.etl_run_log, re-raised, target unchanged; docs/test/TCS-MOD-002.json#TC-002-010; docs/test/TCS-MOD-002.json#TC-002-018; docs/dev/CN-MOD-002.json#test line load fails on a duplicate RECID in the source and leaves the target unchanged; docs/dev/CN-MOD-004.json#the source is first copied into a temp table with the same types as the target and the key NOT NULL; docs/answers.md#MOD-004 NULL matching key; docs/answers.md#No row is skipped; docs/test/TCS-MOD-004.json#TC-004-020; docs/test/TCS-MOD-004.json#TC-004-021; docs/test/TCS-MOD-004.json#TC-004-022; docs/test/TCS-MOD-004.json#TC-004-023; docs/dev/CN-MOD-004.json#A repeated key fails usp_load_brnz_corporate_subscription with error 2627; docs/dev/CN-MOD-003.json#The update and insert run in one transaction, so a failure also rolls back an update already made; docs/dev/CN-MOD-003.json#The error message records the error number; docs/test/TCS-MOD-003.json#TC-003-011; docs/test/TCS-MOD-004.json#TC-004-006; docs/dev/CN-MOD-004.json#same pattern as usp_load_dim_payment_method; docs/dev/CN-MOD-005.json#On error they roll back, log 'Failed' and re-raise.; docs/dev/CN-MOD-005.json#test failed dim_currency insert also rolls back the update made before it; docs/test/TCS-MOD-005.json#TC-005-014; docs/test/TCS-MOD-005.json#TC-005-025; docs/test/TCS-MOD-005.json#TC-005-026; docs/dev/CN-MOD-001.json#Neither writes anything; docs/design/MP-001.json#Builds no tables and changes no existing object -->

## Recovery and reruns

After a failed load:

1. Read the error message on the 'Failed' row in Layercake.etl_run_log.
2. Deal with the cause. Where it lies in the source data (for example a duplicate row key, an amount too large for the table, or a corporate subscription row with a missing contact number, scheme number or Campaign Year, see Known limitations), the fix goes to the source's owner, because the solution does not change source objects.
3. Run the load again. Because the failed run changed nothing, no clean-up is needed first. Then run any load that reads its output (see Components and load order).

A load can be run again at any time, as often as needed: a run on unchanged data changes nothing, and a run after the source has changed brings the table up to date. Rerunning the line-type mapping load never undoes a hand mapping, because it never changes an existing row.

Because a profile run changes nothing, a profile can simply be run again, as often as needed. Each run reports the source as it stands at that moment.

<!-- evidence: docs/dev/CN-MOD-002.json#logged Failed in Layercake.etl_run_log, re-raised, target unchanged; docs/test/TCS-MOD-002.json#non-NULL error_message; PROJECT_STANDARDS.md#Objects owned by other systems (external); docs/answers.md#MOD-004 NULL matching key; docs/dev/CN-MOD-004.json#A repeated key fails usp_load_brnz_corporate_subscription with error 2627; docs/test/TCS-MOD-002.json#TC-002-005; docs/test/TCS-MOD-002.json#TC-002-016; docs/test/TCS-MOD-002.json#TC-002-007; docs/test/TCS-MOD-004.json#TC-004-013; docs/test/TCS-MOD-004.json#TC-004-014; docs/test/TCS-MOD-003.json#TC-003-008; docs/test/TCS-MOD-003.json#TC-003-011; docs/test/TCS-MOD-004.json#TC-004-003; docs/test/TCS-MOD-005.json#TC-005-002; docs/test/TCS-MOD-005.json#TC-005-013; docs/test/TCS-MOD-005.json#TC-005-016; docs/test/TCS-MOD-005.json#TC-005-018; docs/dev/CN-MOD-001.json#Neither writes anything; docs/design/DES-001.json#Layercake.usp_profile_custtrans_grain; docs/design/DES-001.json#Layercake.usp_profile_corp_subscription_status -->

## Deployment and rollback

Every change ships as a numbered migration with an up script and a down (rollback) script. Migrations are recorded in the migration history (etl.MigrationHistory). Deployment to production is done by a person; it is outside the delivered tooling.

| Migration | Module | Script | What it does |
|---|---|---|---|
| MIG-0003 | MOD-001 | src/sql/deploy/MIG-0003_MOD-001_source-profiling-queries.up.sql | Creates the two profile procedures and records the migration as applied |
| MIG-0003 | MOD-001 | src/sql/deploy/MIG-0003_MOD-001_source-profiling-queries.down.sql | Removes them, returning the database to its state before the migration, and records the rollback |
| MIG-0004 | MOD-002 | src/sql/deploy/MIG-0004_MOD-002_subscription-invoice-bronze.up.sql | Creates the two bronze tables and their two loads, and records the migration as applied |
| MIG-0004 | MOD-002 | src/sql/deploy/MIG-0004_MOD-002_subscription-invoice-bronze.down.sql | Removes them, returning the database to its state before the migration, and records the rollback |
| MIG-0005 | MOD-003 | src/sql/deploy/MIG-0005_MOD-003_payment-method-reference-and-dimension.up.sql | Creates the payment method list, the mapping function, the payment method dimension and its load; puts the eight list rows in place; and records the migration as applied |
| MIG-0005 | MOD-003 | src/sql/deploy/MIG-0005_MOD-003_payment-method-reference-and-dimension.down.sql | Removes exactly those eight rows and the four objects, returning the database to its state before the migration, and records the rollback |
| MIG-0006 | MOD-004 | src/sql/deploy/MIG-0006_MOD-004_corporate-subscription-bronze-and-payer.up.sql | Creates the corporate subscription bronze table and its load, the payer type list, the payer type dimension and its load; puts the five list rows in place; and records the migration as applied |
| MIG-0006 | MOD-004 | src/sql/deploy/MIG-0006_MOD-004_corporate-subscription-bronze-and-payer.down.sql | Removes exactly those five rows and the five objects, returning the database to its state before the migration, and records the rollback |
| MIG-0007 | MOD-005 | src/sql/deploy/MIG-0007_MOD-005_invoice-line-type-mapping-and-currency.up.sql | Creates the line-type mapping, the currency list, the currency dimension and their three loads, and records the migration as applied |
| MIG-0007 | MOD-005 | src/sql/deploy/MIG-0007_MOD-005_invoice-line-type-mapping-and-currency.down.sql | Removes them, returning the database to its state before the migration, and records the rollback |

The 12 starting rows of the line-type mapping are held in a separate seed script, src/sql/seed/MOD-005/Layercake.silv_ref_invoice_line_type.up.sql, with its matching .down.sql. They rest on the Q-034 assumption, and the seed script will need to change if a curated mapping is supplied (see Known limitations).

Each rollback was tested on the development database (MIG-0003 on 2026-10-25, MIG-0004, MIG-0005 and MIG-0006 on 2026-10-26, MIG-0007 on 2026-10-27) and passed every step: the up script applies and is recorded; running it a second time changes nothing; the down script restores the database to its state before the migration and is recorded; running it a second time changes nothing; and applying the up script again after a rollback gives the same result as the first time.

After deploying MIG-0005 and MIG-0006, run Layercake.usp_load_dim_payment_method and Layercake.usp_load_dim_payer_type, so the two dimensions are filled from their lists. After deploying MIG-0007, once the bronze invoice loads have run, run Layercake.usp_load_silv_ref_invoice_line_type, Layercake.usp_load_silv_ref_currency and then Layercake.usp_load_dim_currency.

Permissions:

- MOD-001: running the profiles needs only EXECUTE permission. The grant script src/sql/grants/MOD-001.sql grants it to a placeholder role, [<analyst_role>], because the analyst's role name is not known. A person must replace the placeholder before running the script (see Known limitations).
- MOD-002: no permission script is needed.
- MOD-003: no permission script is needed; the design grants no access to these objects.
- MOD-004: no permission script is needed.
- MOD-005: no permission script is needed; the design grants no access to these objects.

<!-- evidence: docs/specs/SPEC-001.json#journal etl.MigrationHistory; docs/design/DES-001.json#Deployment: one migration per module; docs/setup/ENVIRONMENTS.md#Humans deploy; docs/dev/CN-MOD-001.json#MIG-0003; docs/dev/CN-MOD-001.json#re-apply after rollback matches first apply; docs/dev/CN-MOD-001.json#2026-10-25T20:29:27; docs/dev/CN-MOD-001.json#[<analyst_role>]; docs/dev/CN-MOD-001.json#A human must replace it before running the script; docs/dev/CN-MOD-002.json#MIG-0004; docs/dev/CN-MOD-002.json#re-apply after rollback matches first apply; docs/dev/CN-MOD-003.json#MIG-0005; docs/dev/CN-MOD-003.json#the down script deletes exactly those ids; docs/dev/CN-MOD-003.json#2026-10-26T15:51:50; docs/dev/CN-MOD-003.json#No grants: the design asks for no access to these objects.; docs/dev/CN-MOD-004.json#MIG-0006; docs/dev/CN-MOD-004.json#the down script deletes exactly these rows; docs/dev/CN-MOD-004.json#2026-10-26T17:13:40; docs/dev/CN-MOD-004.json#No grants are needed by this module.; docs/dev/CN-MOD-005.json#MIG-0007; docs/dev/CN-MOD-005.json#src/sql/deploy/MIG-0007_MOD-005_invoice-line-type-mapping-and-currency.up.sql; docs/dev/CN-MOD-005.json#src/sql/deploy/MIG-0007_MOD-005_invoice-line-type-mapping-and-currency.down.sql; docs/dev/CN-MOD-005.json#2026-10-27T10:03:11; docs/dev/CN-MOD-005.json#re-apply after rollback matches first apply; docs/dev/CN-MOD-005.json#src/sql/seed/MOD-005/Layercake.silv_ref_invoice_line_type.up.sql; docs/dev/CN-MOD-005.json#No grants: the design asks for no access to these objects.; docs/dev/CN-MOD-005.json#dim_currency is empty after the migration; docs/answers.md#MOD-003 dim_payment_method population; docs/answers.md#The same applies to the other gold dimensions over seeded reference lists -->
