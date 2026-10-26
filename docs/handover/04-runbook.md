# Operational runbook: RICS Payment Segment Tracker

## Components and load order

The solution so far has three loads (MOD-002 and MOD-003) and two read-only profiles (MOD-001):

| Component | What it does | Parameters |
|---|---|---|
| Layercake.usp_load_brnz_subs_invoice | Load: brings Layercake.brnz_subs_invoice up to date with Subs.tblSubsInvoices | None |
| Layercake.usp_load_brnz_subs_invoice_line | Load: brings Layercake.brnz_subs_invoice_line up to date with the in-scope rows of synapse_fo.CUSTTRANS_RICS | None |
| Layercake.usp_load_dim_payment_method | Load: brings Layercake.dim_payment_method into step with the payment method list, Layercake.silv_ref_payment_method | None |
| Layercake.usp_profile_custtrans_grain | Profile: the grain of synapse_fo.CUSTTRANS_RICS, for open question Q-021 | None |
| Layercake.usp_profile_corp_subscription_status | Profile: the status values in Subs.vwCorpSubscriptions, for open question Q-027 | None |

The payment method list and the mapping function, Layercake.fn_map_payment_method, are not run on their own: the list is put in place by its migration, and later modules use the function inside their loads.

None of the three loads reads another load's table: the line load takes its list of invoices directly from Subs.tblSubsInvoices, and the dimension load reads only the payment method list, which no load writes. In the design, all the loads run as part of one run procedure, Layercake.usp_run_payment_segments, which runs every new load in dependency order after the Phase 1 run. That run procedure comes in a later module (MOD-016).

The two profiles do not depend on each other and can be run in either order. They are intended to be run on real data before the invoice build, so their results can answer Q-021 and Q-027 (see Known limitations).

<!-- evidence: docs/dev/CN-MOD-002.json#objects_changed; docs/dev/CN-MOD-003.json#objects_changed; docs/design/MP-001.json#MOD-002; docs/design/MP-001.json#MOD-003; docs/dev/CN-MOD-002.json#Line scope (RULE-077) reads Subs.tblSubsInvoices directly; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/design/DES-001.json#Static list seeded by its migration; docs/answers.md#MOD-003 fn_map_payment_method; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Layercake.usp_run_payment_segments; docs/design/MP-001.json#runs every new load in dependency order after the Phase 1 run; docs/design/MP-001.json#MOD-001; docs/design/MP-001.json#so Mike can run them before the invoice build; docs/dev/CN-MOD-001.json#Neither takes parameters; docs/specs/SPEC-001.json#Q-021; docs/specs/SPEC-001.json#Q-027 -->

## Scheduling

The loads are designed to run after the Phase 1 run, through the run procedure that a person schedules once it is delivered (MOD-016). The schedule itself (when and how often the run happens) is still to be confirmed.

The profiles are not part of any scheduled load. Mike runs them on real data when the answers are needed and brings the results back as answers to the open questions.

<!-- evidence: docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#which a human schedules after the Phase 1 run; docs/design/DES-001.json#runs after the Phase 1 run; docs/specs/SPEC-001.json#REQ-014; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Mike runs them on real data -->

## Monitoring

Each load records one row per run in the load log, Layercake.etl_run_log, with:

- its outcome: 'Success' or 'Failed';
- the numbers of rows inserted, updated and deleted (for the bronze loads, marked as deleted) in its table;
- for a failed run, the error message.

A second run on unchanged data records 0 inserted, 0 updated and 0 deleted. Each bronze load also checks that its table's live rows equal the source rows in scope (RULE-005); a mismatch fails the run, so it shows as 'Failed' in the log. The payment method dimension load never removes rows, so its deleted count is always 0.

The profiles do not record a run in the load log, because they load nothing. Their output is the result set they return, which holds counts only, with no personal data.

<!-- evidence: docs/specs/SPEC-001.json#RULE-005; docs/dev/CN-MOD-002.json#with status 'Success' or 'Failed'; docs/test/TCS-MOD-002.json#TC-002-004; docs/test/TCS-MOD-002.json#TC-002-005; docs/test/TCS-MOD-002.json#TC-002-010; docs/dev/CN-MOD-002.json#A row-count mismatch between live rows and the source (RULE-005) also fails the load; docs/test/TCS-MOD-003.json#TC-003-008; docs/test/TCS-MOD-003.json#TC-003-011; docs/dev/CN-MOD-003.json#rows_deleted is always 0; docs/dev/CN-MOD-001.json#Neither writes anything or logs a load; docs/design/DES-001.json#Every count-only procedure returns aggregates only -->

## Error handling

Each bronze load checks the source data against its table's column types before it writes anything, and makes all its changes in one step. If any value does not fit, the source has two rows with the same key, a write is rejected, or the row-count check fails, the load:

- stops and reports the error to whatever ran it;
- records the run as 'Failed' in Layercake.etl_run_log, with the error message;
- leaves its table exactly as it was before the run.

The payment method dimension load also makes its updates and additions in one step. If any write is rejected, it reports the error, records the run as 'Failed' with the error message (including the error number), and undoes everything the run had done, including any name it had already updated.

In plain terms, a failed load changes nothing, so it can simply be run again once the cause is dealt with.

The profiles only read their sources and write nothing, so a failed or interrupted profile run leaves the database exactly as it was.

<!-- evidence: docs/dev/CN-MOD-002.json#Both loads stage the source in the target's column types before the transaction; docs/dev/CN-MOD-002.json#logged Failed in Layercake.etl_run_log, re-raised, target unchanged; docs/test/TCS-MOD-002.json#TC-002-010; docs/test/TCS-MOD-002.json#TC-002-018; docs/dev/CN-MOD-002.json#test line load fails on a duplicate RECID in the source and leaves the target unchanged; docs/dev/CN-MOD-003.json#The update and insert run in one transaction, so a failure also rolls back an update already made; docs/dev/CN-MOD-003.json#The error message records the error number; docs/test/TCS-MOD-003.json#TC-003-011; docs/dev/CN-MOD-001.json#Neither writes anything; docs/design/MP-001.json#Builds no tables and changes no existing object -->

## Recovery and reruns

After a failed load:

1. Read the error message on the 'Failed' row in Layercake.etl_run_log.
2. Deal with the cause. Where it lies in the source data (for example a duplicate row key, or an amount too large for the table, see Known limitations), the fix goes to the source's owner, because the solution does not change source objects.
3. Run the load again. Because the failed run changed nothing, no clean-up is needed first.

A load can be run again at any time, as often as needed: a run on unchanged data changes nothing, and a run after the source has changed brings the table up to date.

Because a profile run changes nothing, a profile can simply be run again, as often as needed. Each run reports the source as it stands at that moment.

<!-- evidence: docs/dev/CN-MOD-002.json#logged Failed in Layercake.etl_run_log, re-raised, target unchanged; docs/test/TCS-MOD-002.json#non-NULL error_message; PROJECT_STANDARDS.md#Objects owned by other systems (external); docs/test/TCS-MOD-002.json#TC-002-005; docs/test/TCS-MOD-002.json#TC-002-016; docs/test/TCS-MOD-002.json#TC-002-007; docs/test/TCS-MOD-003.json#TC-003-008; docs/test/TCS-MOD-003.json#TC-003-011; docs/dev/CN-MOD-001.json#Neither writes anything; docs/design/DES-001.json#Layercake.usp_profile_custtrans_grain; docs/design/DES-001.json#Layercake.usp_profile_corp_subscription_status -->

## Deployment and rollback

Every change ships as a numbered migration with an up script and a down (rollback) script. Migrations are recorded in the migration history (etl.MigrationHistory). Deployment to production is done by a person; it is outside the delivered tooling.

| Migration | Module | Script | What it does |
|---|---|---|---|
| MIG-0003 | MOD-001 | src/sql/deploy/MIG-0003_MOD-001_source-profiling-queries.up.sql | Creates the two profile procedures and records the migration as applied |
| MIG-0003 | MOD-001 | src/sql/deploy/MIG-0003_MOD-001_source-profiling-queries.down.sql | Removes them, returning the database to its state before the migration, and records the rollback |
| MIG-0004 | MOD-002 | src/sql/deploy/MIG-0004_MOD-002_subscription-invoice-bronze.up.sql | Creates the two bronze tables and their two loads, and records the migration as applied |
| MIG-0004 | MOD-002 | src/sql/deploy/MIG-0004_MOD-002_subscription-invoice-bronze.down.sql | Removes them, returning the database to its state before the migration, and records the rollback |
| MIG-0005 | MOD-003 | src/sql/deploy/MIG-0005_MOD-003_payment-method-reference-and-dimension.up.sql | Creates the payment method list, the mapping function, the payment method dimension and its load; puts the eight rows of the payment method list in place (from src/sql/seed/MOD-003); and records the migration as applied |
| MIG-0005 | MOD-003 | src/sql/deploy/MIG-0005_MOD-003_payment-method-reference-and-dimension.down.sql | Removes exactly those eight rows and the four objects, returning the database to its state before the migration, and records the rollback |

Each rollback was tested on the development database (MIG-0003 on 2026-10-25, MIG-0004 and MIG-0005 on 2026-10-26) and passed every step: the up script applies and is recorded; running it a second time changes nothing; the down script restores the previous schema and is recorded; running it a second time changes nothing; and applying the up script again after a rollback gives the same result as the first time.

Permissions:

- MOD-001: running the profiles needs only EXECUTE permission. The grant script src/sql/grants/MOD-001.sql grants it to a placeholder role, [<analyst_role>], because the analyst's role name is not known. Before running the script, a person must replace the placeholder with the real role. The profiles must be deployed to production before they can be run there.
- MOD-002: no permission script is needed.
- MOD-003: no permission script is needed; the design grants no access to these objects.

<!-- evidence: docs/specs/SPEC-001.json#journal etl.MigrationHistory; docs/design/DES-001.json#Deployment: one migration per module; docs/setup/ENVIRONMENTS.md#Humans deploy; docs/dev/CN-MOD-001.json#MIG-0003; docs/dev/CN-MOD-002.json#MIG-0004; docs/dev/CN-MOD-002.json#src/sql/deploy/MIG-0004_MOD-002_subscription-invoice-bronze.up.sql; docs/dev/CN-MOD-002.json#src/sql/deploy/MIG-0004_MOD-002_subscription-invoice-bronze.down.sql; docs/dev/CN-MOD-003.json#MIG-0005; docs/dev/CN-MOD-003.json#src/sql/deploy/MIG-0005_MOD-003_payment-method-reference-and-dimension.up.sql; docs/dev/CN-MOD-003.json#src/sql/deploy/MIG-0005_MOD-003_payment-method-reference-and-dimension.down.sql; docs/dev/CN-MOD-003.json#the eight seed rows are in src/sql/seed/MOD-003; docs/dev/CN-MOD-003.json#the down script deletes exactly those ids; docs/dev/CN-MOD-001.json#down restores the pre-migration schema; docs/dev/CN-MOD-002.json#down restores the pre-migration schema; docs/dev/CN-MOD-003.json#down restores the pre-migration schema; docs/dev/CN-MOD-003.json#re-apply after rollback matches first apply; docs/dev/CN-MOD-003.json#2026-10-26T15:51:50; docs/dev/CN-MOD-002.json#RPST_Dev; docs/dev/CN-MOD-003.json#RPST_Dev; docs/dev/CN-MOD-001.json#src/sql/grants/MOD-001.sql; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Running them needs only EXECUTE; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#they must be deployed to production; docs/dev/CN-MOD-002.json#No grants are needed; docs/dev/CN-MOD-003.json#No grants: the design asks for no access to these objects -->
