# Operational runbook: RICS Payment Segment Tracker

## Components and load order

The solution so far has twelve loads (MOD-002 to MOD-007) and two read-only profiles (MOD-001):

| Component | What it does | Parameters |
|---|---|---|
| Layercake.usp_load_brnz_subs_invoice | Load: brings Layercake.brnz_subs_invoice up to date with Subs.tblSubsInvoices | None |
| Layercake.usp_load_brnz_subs_invoice_line | Load: brings Layercake.brnz_subs_invoice_line up to date with the in-scope rows of synapse_fo.CUSTTRANS_RICS | None |
| Layercake.usp_load_brnz_corporate_subscription | Load: brings Layercake.brnz_corporate_subscription up to date with Subs.vwCorpSubscriptions | None |
| Layercake.usp_load_brnz_concession | Load: brings Layercake.brnz_concession up to date with the concession reference, CE.vwConcessionType | None |
| Layercake.usp_load_dim_payment_method | Load: brings Layercake.dim_payment_method into step with the payment method list, Layercake.silv_ref_payment_method | None |
| Layercake.usp_load_dim_payer_type | Load: brings Layercake.dim_payer_type into step with the payer type list, Layercake.silv_ref_payer_type | None |
| Layercake.usp_load_silv_ref_invoice_line_type | Load: adds new item codes from Layercake.brnz_subs_invoice_line to the line-type mapping, Layercake.silv_ref_invoice_line_type, as 'unmapped' | None |
| Layercake.usp_load_silv_ref_currency | Load: adds new currency codes from Layercake.brnz_subs_invoice to the currency list, Layercake.silv_ref_currency | None |
| Layercake.usp_load_dim_currency | Load: brings Layercake.dim_currency into step with the currency list | None |
| Layercake.usp_load_silv_ref_concession_type | Load: adds new concession types from Layercake.brnz_concession to the concession type list, Layercake.silv_ref_concession_type, and updates the name, item code and flags of listed types that changed | None |
| Layercake.usp_load_dim_concession_type | Load: brings Layercake.dim_concession_type into step with the concession type list | None |
| Layercake.usp_load_silv_member_year_attributes | Load: brings Layercake.silv_member_year_attributes up to date, working out each contact's payment method, payer type, corporate scheme number and concession for every Campaign Year up to the current one | Both optional: @run_id, and @as_of_date, the date that sets the current Campaign Year (by default, the day the load runs) |
| Layercake.usp_profile_custtrans_grain | Profile: the grain of synapse_fo.CUSTTRANS_RICS, for open question Q-021 | None |
| Layercake.usp_profile_corp_subscription_status | Profile: the status values in Subs.vwCorpSubscriptions, for open question Q-027 | None |

The payment method and payer type lists, the mapping function Layercake.fn_map_payment_method and the eligible-invoice view Layercake.vw_silv_eligible_invoice are not run on their own: the lists are put in place by their migrations, and the function and the view are used inside the attributes load.

Six loads read the output of another load, so they must run after it:

1. usp_load_silv_ref_currency reads brnz_subs_invoice, so it runs after usp_load_brnz_subs_invoice.
2. usp_load_dim_currency reads the currency list, so it runs after usp_load_silv_ref_currency.
3. usp_load_silv_ref_invoice_line_type reads brnz_subs_invoice_line, so it runs after usp_load_brnz_subs_invoice_line.
4. usp_load_silv_ref_concession_type reads brnz_concession, so it runs after usp_load_brnz_concession.
5. usp_load_dim_concession_type reads the concession type list, so it runs after usp_load_silv_ref_concession_type.
6. usp_load_silv_member_year_attributes reads brnz_subs_invoice, brnz_subs_invoice_line, the line-type mapping, brnz_corporate_subscription, brnz_concession and the concession type list, so it runs after usp_load_brnz_subs_invoice, usp_load_brnz_subs_invoice_line, usp_load_silv_ref_invoice_line_type, usp_load_brnz_corporate_subscription, usp_load_brnz_concession and usp_load_silv_ref_concession_type. It also reads the Phase 1 tables silv_membership_events and silv_payment_events, so it runs after the Phase 1 run.

The other loads do not read another load's table: the line load takes its list of invoices directly from Subs.tblSubsInvoices, the corporate subscription and concession bronze loads read only their sources, and the payment method and payer type dimension loads read only their lists, which no load writes. In the design, all the loads run as part of one run procedure, Layercake.usp_run_payment_segments, which runs every new load in dependency order after the Phase 1 run. That run procedure comes in a later module (MOD-016).

The four dimensions are not filled by their migrations. Each stays empty until its load is first run (for the currency and concession type dimensions, after their list loads). Until the run procedure is delivered, the list loads, the four dimension loads and the attributes load are run by hand (see Deployment and rollback).

The two profiles do not depend on each other and can be run in either order. They are intended to be run on real data before the invoice build, so their results can answer Q-021 and Q-027 (see Known limitations).

<!-- evidence: docs/dev/CN-MOD-002.json#objects_changed; docs/dev/CN-MOD-003.json#objects_changed; docs/dev/CN-MOD-004.json#objects_changed; docs/dev/CN-MOD-005.json#objects_changed; docs/dev/CN-MOD-006.json#objects_changed; docs/dev/CN-MOD-007.json#objects_changed; docs/design/MP-001.json#MOD-002; docs/design/MP-001.json#MOD-003; docs/design/MP-001.json#MOD-004; docs/design/MP-001.json#MOD-005; docs/design/MP-001.json#MOD-006; docs/design/MP-001.json#MOD-007; docs/design/DES-001.json#Adds each (productcode, ricinvoicetype) seen in live brnz_subs_invoice_line rows; docs/design/DES-001.json#(brnz_subs_invoice.inv_currency); docs/design/DES-001.json#Mirrors silv_ref_currency into dim_currency. Logged.; docs/design/DES-001.json#Lands CE.vwConcessionType with the standard insert, update and soft-delete behaviour, row-count check and logging.; docs/design/DES-001.json#Inserts new concession types from live brnz_concession rows, updates name, item code and flags where they changed; docs/design/DES-001.json#Mirrors silv_ref_concession_type into dim_concession_type. Logged.; docs/answers.md#Layercake.usp_load_silv_member_year_attributes @run_id uniqueidentifier = NULL, @as_of_date date = NULL; docs/answers.md#Contact list and first-event year (RULE-011, Q-030); docs/answers.md#Phase 1 paid position (RULE-021, RULE-017); docs/answers.md#Eligible invoice (RULE-014, vw_silv_eligible_invoice); docs/test/TCS-MOD-007.json#Standard set-up for every attributes test; docs/design/DES-001.json#eligibility is defined once in vw_silv_eligible_invoice; docs/design/DES-001.json#apuk_discount through the business key; docs/dev/CN-MOD-005.json#dim_currency is empty after the migration until usp_load_silv_ref_currency and then usp_load_dim_currency run (by hand until MOD-016); docs/dev/CN-MOD-006.json#The gold dimension is empty after the migration until usp_load_dim_concession_type runs; docs/dev/CN-MOD-002.json#Line scope (RULE-077) reads Subs.tblSubsInvoices directly; docs/design/DES-001.json#1:1 landing of Subs.vwCorpSubscriptions; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type; docs/design/DES-001.json#Reference lists: payment method and payer type are static lists seeded by their migrations; docs/answers.md#MOD-003 fn_map_payment_method; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Layercake.usp_run_payment_segments; docs/design/MP-001.json#runs every new load in dependency order after the Phase 1 run; docs/design/DES-001.json#Run order (ADR-001); docs/answers.md#MOD-003 dim_payment_method population; docs/answers.md#The same applies to the other gold dimensions over seeded reference lists; docs/dev/CN-MOD-004.json#dim_payer_type is not seeded; docs/design/MP-001.json#MOD-001; docs/design/MP-001.json#so Mike can run them before the invoice build; docs/dev/CN-MOD-001.json#Neither takes parameters; docs/specs/SPEC-001.json#Q-021; docs/specs/SPEC-001.json#Q-027 -->

## Scheduling

The loads are designed to run after the Phase 1 run, through the run procedure that a person schedules once it is delivered (MOD-016). The schedule itself (when and how often the run happens) is still to be confirmed.

The attributes load needs no argument on a scheduled run: its as-of date defaults to the day it runs, so the current Campaign Year moves on by itself when a new Campaign Year starts, as long as Layercake.ref_campaign_year_config has a row covering the date (see Error handling).

The profiles are not part of any scheduled load. Mike runs them on real data when the answers are needed and brings the results back as answers to the open questions.

<!-- evidence: docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#which a human schedules after the Phase 1 run; docs/design/DES-001.json#runs after the Phase 1 run; docs/answers.md#so the scheduled run needs no argument; docs/answers.md#Current Campaign Year; docs/answers.md#If no config row covers @as_of_date, the load fails; docs/specs/SPEC-001.json#REQ-014; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Mike runs them on real data -->

## Monitoring

Each load records one row per run in the load log, Layercake.etl_run_log, with:

- its outcome: 'Success' or 'Failed';
- the numbers of rows inserted, updated and deleted (for the bronze loads, marked as deleted) in its table;
- for a failed run, the error message.

A second run on unchanged data records 0 inserted, 0 updated and 0 deleted. Each bronze load also checks that its table's live rows equal the source rows in scope (RULE-005); a mismatch fails the run, so it shows as 'Failed' in the log. In the corporate subscription and concession bronze loads, making a deleted row live again is counted as an update, and in the concession bronze load a change only in letter case or trailing spaces is also counted as one update. The dimension loads never remove rows, so their deleted count is always 0; in the concession type dimension, a change only in a flag counts as one update. The line-type mapping and currency list loads only add rows, so they record only rows inserted. The concession type list load records rows inserted (new types) and rows updated (types whose name, item code or flags changed).

The attributes load records its run under the layer 'silver' and the step 'silv_member_year_attributes', with the contact-years it added, updated and deleted. A change only in the letter case of a scheme number counts as an update.

New rows in the line-type mapping arrive as 'unmapped'. A run of usp_load_silv_ref_invoice_line_type that records rows inserted means new item codes have appeared that a person needs to map by hand (see Known limitations).

The profiles do not record a run in the load log, because they load nothing. Their output is the result set they return, which holds counts only, with no personal data.

<!-- evidence: docs/specs/SPEC-001.json#RULE-005; docs/dev/CN-MOD-002.json#with status 'Success' or 'Failed'; docs/test/TCS-MOD-002.json#TC-002-004; docs/test/TCS-MOD-002.json#TC-002-005; docs/test/TCS-MOD-002.json#TC-002-010; docs/dev/CN-MOD-002.json#A row-count mismatch between live rows and the source (RULE-005) also fails the load; docs/dev/CN-MOD-004.json#The live row count is checked against the source count (RULE-005); docs/dev/CN-MOD-004.json#Restoring a soft-deleted row counts as an update; docs/test/TCS-MOD-004.json#TC-004-013; docs/test/TCS-MOD-004.json#TC-004-019; docs/dev/CN-MOD-006.json#test trailing space change and restore are each one update in bronze; docs/dev/CN-MOD-006.json#Bronze and silver compare strings as bytes; docs/test/TCS-MOD-006.json#TC-006-003; docs/test/TCS-MOD-006.json#TC-006-005; docs/test/TCS-MOD-003.json#TC-003-008; docs/test/TCS-MOD-003.json#TC-003-011; docs/dev/CN-MOD-003.json#rows_deleted is always 0; docs/dev/CN-MOD-004.json#The load never deletes from the dimension; docs/test/TCS-MOD-004.json#TC-004-003; docs/dev/CN-MOD-005.json#never deletes; docs/dev/CN-MOD-005.json#are insert-only; docs/dev/CN-MOD-006.json#The dimension never deletes an id; docs/dev/CN-MOD-006.json#test dimension keeps an id no longer in silver and counts a flag only change as one update; docs/test/TCS-MOD-006.json#TC-006-011; docs/test/TCS-MOD-006.json#TC-006-012; docs/answers.md#Logging: the same as the MOD-004 to MOD-006 loads; docs/test/TCS-MOD-007.json#TC-007-017; docs/test/TCS-MOD-007.json#TC-007-018; docs/dev/CN-MOD-007.json#test case-only scheme number change updates the row and logs one update; docs/test/TCS-MOD-005.json#TC-005-001; docs/test/TCS-MOD-005.json#TC-005-002; docs/test/TCS-MOD-005.json#TC-005-016; docs/test/TCS-MOD-005.json#TC-005-018; docs/dev/CN-MOD-005.json#must be mapped by hand before MOD-010's amounts are complete; docs/dev/CN-MOD-001.json#Neither writes anything or logs a load; docs/design/DES-001.json#Every count-only procedure returns aggregates only -->

## Error handling

Each bronze load checks the source data against its table's column types before it writes anything, and makes all its changes in one step. If any value does not fit, the source has two rows with the same key, a write is rejected, or the row-count check fails, the load:

- stops and reports the error to whatever ran it;
- records the run as 'Failed' in Layercake.etl_run_log, with the error message;
- leaves its table exactly as it was before the run.

For the corporate subscription load, the key is the contact number, scheme number and Campaign Year together. A source row where any of the three is missing fails the whole load in the same way; no row is skipped. So does a second source row with the same three values as another (see Known limitations).

For the concession bronze load, the key is the concession type id. A source row with no concession type id, or two rows with the same id, fails the whole load in the same way; no row is skipped (see Known limitations).

The dimension loads and the list loads (line-type mapping, currency list and concession type list) also make all their changes in one step. If any write is rejected, the load reports the error, records the run as 'Failed' with the error message, and undoes everything the run had done, including any name, code or flag it had already corrected. A failed line-type mapping or currency list load adds no row at all, not even part of a run. The concession type list load also fails in this way, rather than storing a cut-down code, if a type's item code is longer than the list holds (see Known limitations).

The attributes load makes its additions, updates and deletions in one step too. If any of them fails part-way, it undoes them all, records the run as 'Failed' with the error message, and reports the error. It also fails in this way, before changing anything, when no Campaign Year in Layercake.ref_campaign_year_config covers its as-of date; the error message names the date.

In plain terms, a failed load changes nothing, so it can simply be run again once the cause is dealt with.

The profiles only read their sources and write nothing, so a failed or interrupted profile run leaves the database exactly as it was.

<!-- evidence: docs/dev/CN-MOD-002.json#Both loads stage the source in the target's column types before the transaction; docs/dev/CN-MOD-002.json#logged Failed in Layercake.etl_run_log, re-raised, target unchanged; docs/test/TCS-MOD-002.json#TC-002-010; docs/test/TCS-MOD-002.json#TC-002-018; docs/dev/CN-MOD-002.json#test line load fails on a duplicate RECID in the source and leaves the target unchanged; docs/dev/CN-MOD-004.json#the source is first copied into a temp table with the same types as the target and the key NOT NULL; docs/answers.md#MOD-004 NULL matching key; docs/answers.md#No row is skipped; docs/test/TCS-MOD-004.json#TC-004-020; docs/test/TCS-MOD-004.json#TC-004-021; docs/test/TCS-MOD-004.json#TC-004-022; docs/test/TCS-MOD-004.json#TC-004-023; docs/dev/CN-MOD-004.json#A repeated key fails usp_load_brnz_corporate_subscription with error 2627; docs/answers.md#MOD-006 NULL key, duplicate key and missing name; docs/dev/CN-MOD-006.json#Bronze stages the source in a temp table with the key NOT NULL and as primary key; docs/test/TCS-MOD-006.json#TC-006-007; docs/test/TCS-MOD-006.json#TC-006-008; docs/dev/CN-MOD-003.json#The update and insert run in one transaction, so a failure also rolls back an update already made; docs/dev/CN-MOD-003.json#The error message records the error number; docs/test/TCS-MOD-003.json#TC-003-011; docs/test/TCS-MOD-004.json#TC-004-006; docs/dev/CN-MOD-004.json#same pattern as usp_load_dim_payment_method; docs/dev/CN-MOD-005.json#On error they roll back, log 'Failed' and re-raise.; docs/dev/CN-MOD-005.json#test failed dim_currency insert also rolls back the update made before it; docs/test/TCS-MOD-005.json#TC-005-014; docs/test/TCS-MOD-005.json#TC-005-025; docs/test/TCS-MOD-005.json#TC-005-026; docs/test/TCS-MOD-006.json#TC-006-022; docs/test/TCS-MOD-006.json#TC-006-026; docs/dev/CN-MOD-006.json#An item code longer than nvarchar(100) fails the load rather than being cut; docs/dev/CN-MOD-007.json#delete, update, insert in one transaction; docs/answers.md#On error, CATCH rolls back, logs 'Failed' with the error message and re-raises (THROW); docs/test/TCS-MOD-007.json#TC-007-055; docs/test/TCS-MOD-007.json#TC-007-004; docs/dev/CN-MOD-007.json#raises error 50001, which names the date; docs/answers.md#If no config row covers @as_of_date, the load fails: it logs Failed, re-raises and changes nothing; docs/dev/CN-MOD-001.json#Neither writes anything; docs/design/MP-001.json#Builds no tables and changes no existing object -->

## Recovery and reruns

After a failed load:

1. Read the error message on the 'Failed' row in Layercake.etl_run_log.
2. Deal with the cause. Where it lies in the source data (for example a duplicate row key, an amount too large for the table, a corporate subscription row with a missing contact number, scheme number or Campaign Year, or a concession type with a missing or repeated id, see Known limitations), the fix goes to the source's owner, because the solution does not change source objects. Where the attributes load failed because no Campaign Year covers its as-of date, Layercake.ref_campaign_year_config needs a row whose start and end dates cover that date.
3. Run the load again. Because the failed run changed nothing, no clean-up is needed first. Then run any load that reads its output (see Components and load order).

Until the cause is dealt with, the table keeps the data from its last successful run.

A profile that fails or is interrupted can simply be run again.

<!-- evidence: docs/dev/CN-MOD-002.json#logged Failed in Layercake.etl_run_log, re-raised, target unchanged; docs/test/TCS-MOD-002.json#non-NULL error_message; PROJECT_STANDARDS.md#Objects owned by other systems (external); docs/answers.md#MOD-004 NULL matching key; docs/answers.md#MOD-006 NULL key, duplicate key and missing name; docs/test/TCS-MOD-006.json#TC-006-007; docs/answers.md#Current Campaign Year: the ref_campaign_year_config row whose campaign_year_start <= @as_of_date <= campaign_year_end; docs/dev/CN-MOD-007.json#An as-of date with no row in ref_campaign_year_config raises error 50001; docs/test/TCS-MOD-007.json#TC-007-004; docs/dev/CN-MOD-001.json#Neither writes anything -->

## Deployment and rollback

Every change ships as a numbered migration with an up script and a down (rollback) script, one migration per module. Migrations are recorded in the migration history (etl.MigrationHistory). Deployment to production is done by a person, outside the delivered tooling; when and by whom is still to be confirmed.

| Migration | Module | Script | What it does |
|---|---|---|---|
| MIG-0003 | MOD-001 | src/sql/deploy/MIG-0003_MOD-001_source-profiling-queries.up.sql | Creates the two profile procedures and records the migration as applied |
| MIG-0003 | MOD-001 | src/sql/deploy/MIG-0003_MOD-001_source-profiling-queries.down.sql | Removes them, returning the database to its state before the migration, and records the rollback |
| MIG-0004 | MOD-002 | src/sql/deploy/MIG-0004_MOD-002_subscription-invoice-bronze.up.sql | Creates the two bronze tables and their two loads, and records the migration as applied |
| MIG-0004 | MOD-002 | src/sql/deploy/MIG-0004_MOD-002_subscription-invoice-bronze.down.sql | Removes them, returning the database to its state before the migration, and records the rollback |
| MIG-0005 | MOD-003 | src/sql/deploy/MIG-0005_MOD-003_payment-method-reference-and-dimension.up.sql | Creates the payment method list, the mapping function, the payment method dimension and its load; puts the eight rows in the list; and records the migration as applied |
| MIG-0005 | MOD-003 | src/sql/deploy/MIG-0005_MOD-003_payment-method-reference-and-dimension.down.sql | Removes exactly those eight rows and the four objects, returning the database to its state before the migration, and records the rollback |
| MIG-0006 | MOD-004 | src/sql/deploy/MIG-0006_MOD-004_corporate-subscription-bronze-and-payer.up.sql | Creates the corporate subscription bronze table and its load, the payer type list, the payer type dimension and its load; puts the five rows in the list; and records the migration as applied |
| MIG-0006 | MOD-004 | src/sql/deploy/MIG-0006_MOD-004_corporate-subscription-bronze-and-payer.down.sql | Removes exactly those five rows and the five objects, returning the database to its state before the migration, and records the rollback |
| MIG-0007 | MOD-005 | src/sql/deploy/MIG-0007_MOD-005_invoice-line-type-mapping-and-currency.up.sql | Creates the line-type mapping, the currency list, the currency dimension and their three loads, and records the migration as applied |
| MIG-0007 | MOD-005 | src/sql/deploy/MIG-0007_MOD-005_invoice-line-type-mapping-and-currency.down.sql | Removes them, returning the database to its state before the migration, and records the rollback |
| MIG-0008 | MOD-006 | src/sql/deploy/MIG-0008_MOD-006_concession-reference-and-dimension.up.sql | Creates the concession bronze table and its load, the concession type list and its load, and the concession type dimension and its load; puts the four starting rows (the three reserved values and 'No concession') in the list; and records the migration as applied |
| MIG-0008 | MOD-006 | src/sql/deploy/MIG-0008_MOD-006_concession-reference-and-dimension.down.sql | Removes them, returning the database to its state before the migration, and records the rollback |
| MIG-0009 | MOD-007 | src/sql/deploy/MIG-0009_MOD-007_member-year-attributes-and-new-event-tab.up.sql | Creates the eligible-invoice view, the member-year attributes table and its load; adds the seventeen new columns to the Phase 1 tables silv_membership_events and fact_membership_events, with defaults of 0 for the keys and flags; and records the migration as applied |
| MIG-0009 | MOD-007 | src/sql/deploy/MIG-0009_MOD-007_member-year-attributes-and-new-event-tab.down.sql | Removes the defaults and the seventeen columns from the two event tables, and the new objects, returning the database to its state before the migration, and records the rollback |

The 12 starting rows of the line-type mapping are held in a separate seed script, src/sql/seed/MOD-005/Layercake.silv_ref_invoice_line_type.up.sql, with its matching .down.sql. They are the 12 item codes that Subs.usp_Refresh_SubsInvoices names, as confirmed on 2026-10-27 (Q-034).

Each rollback was tested on the development database (MIG-0003 on 2026-10-25, MIG-0004, MIG-0005 and MIG-0006 on 2026-10-26, MIG-0007, MIG-0008 and MIG-0009 on 2026-10-27) and passed every step: the up script applies and is recorded, a second up changes nothing, the down script restores the database to its state before the migration and is recorded, a second down changes nothing, and applying again after the rollback gives the same result as the first time.

After deploying MIG-0005 and MIG-0006, run Layercake.usp_load_dim_payment_method and Layercake.usp_load_dim_payer_type, so the two dimensions are filled from their lists. After deploying MIG-0007, once the bronze invoice loads have run, run Layercake.usp_load_silv_ref_currency, then Layercake.usp_load_dim_currency, and Layercake.usp_load_silv_ref_invoice_line_type. After deploying MIG-0008, run Layercake.usp_load_brnz_concession, then Layercake.usp_load_silv_ref_concession_type, then Layercake.usp_load_dim_concession_type. After deploying MIG-0009, once the Phase 1 run and the loads it depends on have run (see Components and load order), run Layercake.usp_load_silv_member_year_attributes. Until the run procedure is delivered (MOD-016), these loads are run by hand.

Permissions:

- MOD-001: running the profiles needs only EXECUTE permission. The grant script src/sql/grants/MOD-001.sql grants it to a placeholder role, [<analyst_role>], because the analyst's role name is not known; a person must replace it before running the script (see Known limitations).
- MOD-002: no permission script is needed.
- MOD-003: no permission script is needed; the design grants no access to these objects.
- MOD-004: no permission script is needed.
- MOD-005: no permission script is needed; the design grants no access to these objects.
- MOD-006: no permission script is needed.
- MOD-007: no permission script is needed; the module adds no gold object.

<!-- evidence: docs/specs/SPEC-001.json#journal etl.MigrationHistory; docs/design/DES-001.json#Deployment: one migration per module; docs/setup/ENVIRONMENTS.md#Humans deploy; docs/dev/CN-MOD-001.json#src/sql/deploy/MIG-0003_MOD-001_source-profiling-queries.up.sql; docs/dev/CN-MOD-001.json#src/sql/deploy/MIG-0003_MOD-001_source-profiling-queries.down.sql; docs/dev/CN-MOD-002.json#src/sql/deploy/MIG-0004_MOD-002_subscription-invoice-bronze.up.sql; docs/dev/CN-MOD-002.json#src/sql/deploy/MIG-0004_MOD-002_subscription-invoice-bronze.down.sql; docs/dev/CN-MOD-003.json#src/sql/deploy/MIG-0005_MOD-003_payment-method-reference-and-dimension.up.sql; docs/dev/CN-MOD-003.json#src/sql/deploy/MIG-0005_MOD-003_payment-method-reference-and-dimension.down.sql; docs/dev/CN-MOD-004.json#src/sql/deploy/MIG-0006_MOD-004_corporate-subscription-bronze-and-payer.up.sql; docs/dev/CN-MOD-004.json#src/sql/deploy/MIG-0006_MOD-004_corporate-subscription-bronze-and-payer.down.sql; docs/dev/CN-MOD-005.json#src/sql/deploy/MIG-0007_MOD-005_invoice-line-type-mapping-and-currency.up.sql; docs/dev/CN-MOD-005.json#src/sql/deploy/MIG-0007_MOD-005_invoice-line-type-mapping-and-currency.down.sql; docs/dev/CN-MOD-006.json#src/sql/deploy/MIG-0008_MOD-006_concession-reference-and-dimension.up.sql; docs/dev/CN-MOD-006.json#src/sql/deploy/MIG-0008_MOD-006_concession-reference-and-dimension.down.sql; docs/dev/CN-MOD-007.json#src/sql/deploy/MIG-0009_MOD-007_member-year-attributes-and-new-event-tab.up.sql; docs/dev/CN-MOD-007.json#src/sql/deploy/MIG-0009_MOD-007_member-year-attributes-and-new-event-tab.down.sql; docs/dev/CN-MOD-007.json#Keys and flags have named defaults of 0; docs/dev/CN-MOD-007.json#the down script drops the defaults and the columns; docs/dev/CN-MOD-007.json#down restores the pre-migration schema; docs/dev/CN-MOD-006.json#the migration seeds 0 Unknown, -1 Unrecognised, -2 Not applicable and 1 No concession; docs/dev/CN-MOD-005.json#If a curated list is supplied, the seed file; docs/answers.md#Q-034 line-type mapping seed; docs/dev/CN-MOD-005.json#2026-10-27T10:03:11; docs/dev/CN-MOD-006.json#2026-10-27T13:43:36; docs/dev/CN-MOD-007.json#2026-10-27T15:35:45; docs/dev/CN-MOD-007.json#RPST_Dev; docs/dev/CN-MOD-006.json#second up changes nothing; docs/dev/CN-MOD-006.json#re-apply after rollback matches first apply; docs/dev/CN-MOD-007.json#re-apply after rollback matches first apply; docs/dev/CN-MOD-006.json#The gold dimension is empty after the migration until usp_load_dim_concession_type runs; docs/answers.md#MOD-003 dim_payment_method population; docs/dev/CN-MOD-001.json#[<analyst_role>]; docs/dev/CN-MOD-001.json#A human must replace it before running the script; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Running them needs only EXECUTE; docs/dev/CN-MOD-006.json#No grants are needed; docs/dev/CN-MOD-007.json#No grants are needed: the module adds no gold object -->
