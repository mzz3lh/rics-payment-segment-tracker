# Operational runbook: RICS Payment Segment Tracker

## Components and load order

MOD-001 has no loads. It provides two read-only profiles that are run by hand:

| Component | Run it to | Parameters |
|---|---|---|
| Layercake.usp_profile_custtrans_grain | Profile the grain of synapse_fo.CUSTTRANS_RICS, for open question Q-021 | None |
| Layercake.usp_profile_corp_subscription_status | Profile the status values in Subs.vwCorpSubscriptions, for open question Q-027 | None |

The two profiles do not depend on each other and can be run in either order. They are intended to be run on real data before the invoice build, so their results can answer Q-021 and Q-027 (see Known limitations).

<!-- evidence: docs/design/MP-001.json#MOD-001; docs/design/MP-001.json#so Mike can run them before the invoice build; docs/dev/CN-MOD-001.json#Neither takes parameters; docs/specs/SPEC-001.json#Q-021; docs/specs/SPEC-001.json#Q-027 -->

## Scheduling

The profiles are not part of any scheduled load. Mike runs them on real data when the answers are needed and brings the results back as answers to the open questions.

<!-- evidence: docs/specs/SPEC-001.json#REQ-014; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Mike runs them on real data -->

## Monitoring

The profiles do not record a run in the load log (Layercake.etl_run_log), because they load nothing. Their output is the result set they return, which holds counts only, with no personal data.

<!-- evidence: docs/dev/CN-MOD-001.json#Neither writes anything or logs a load; docs/design/DES-001.json#Every count-only procedure returns aggregates only -->

## Error handling

The profiles only read their sources and write nothing, so there is nothing to undo if one fails: a failed or interrupted run leaves the database exactly as it was.

<!-- evidence: docs/dev/CN-MOD-001.json#Neither writes anything; docs/design/MP-001.json#Builds no tables and changes no existing object -->

## Recovery and reruns

Because a run changes nothing, a profile can simply be run again, as often as needed. Each run reports the source as it stands at that moment.

<!-- evidence: docs/dev/CN-MOD-001.json#Neither writes anything; docs/design/DES-001.json#Layercake.usp_profile_custtrans_grain; docs/design/DES-001.json#Layercake.usp_profile_corp_subscription_status -->

## Deployment and rollback

Every change ships as a numbered migration with an up script and a down (rollback) script. Migrations are recorded in the migration history (etl.MigrationHistory). Deployment to production is done by a person; it is outside the delivered tooling.

MOD-001 is migration MIG-0003:

| Script | What it does |
|---|---|
| src/sql/deploy/MIG-0003_MOD-001_source-profiling-queries.up.sql | Creates the two profile procedures and records the migration as applied |
| src/sql/deploy/MIG-0003_MOD-001_source-profiling-queries.down.sql | Removes them, returning the database to its state before the migration, and records the rollback |

The rollback was tested on the development database on 2026-10-25 and passed every step: the up script applies and is recorded; running it a second time changes nothing; the down script restores the previous schema and is recorded; running it a second time changes nothing; and applying the up script again after a rollback gives the same result as the first time.

Running the profiles needs only EXECUTE permission. The grant script src/sql/grants/MOD-001.sql grants it to a placeholder role, [<analyst_role>], because the analyst's role name is not known. Before running the script, a person must replace the placeholder with the real role. The profiles must be deployed to production before they can be run there.

<!-- evidence: docs/specs/SPEC-001.json#journal etl.MigrationHistory; docs/design/DES-001.json#Deployment: one migration per module; docs/setup/ENVIRONMENTS.md#Humans deploy; docs/dev/CN-MOD-001.json#MIG-0003; docs/dev/CN-MOD-001.json#down restores the pre-migration schema; docs/dev/CN-MOD-001.json#re-apply after rollback matches first apply; docs/dev/CN-MOD-001.json#RPST_Dev; docs/dev/CN-MOD-001.json#src/sql/grants/MOD-001.sql; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Running them needs only EXECUTE; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#they must be deployed to production -->
