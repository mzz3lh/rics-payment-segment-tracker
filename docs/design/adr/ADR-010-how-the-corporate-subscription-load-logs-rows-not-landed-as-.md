# ADR-010: How the corporate subscription load logs rows not landed as repeats

| | |
|---|---|
| Status | proposed |
| Date | 2026-11-18 |
| Requirement IDs | REQ-022 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
RULE-129: a repeated corporate subscription key is not an error and not a data anomaly, but every run must log how many source rows were not landed as repeats (source rows in scope minus distinct keys), including 0. The design picks how. The load already logs through Layercake.usp_etl_log_start and usp_etl_log_end into Layercake.etl_run_log (status, rows inserted, updated and deleted, error message). Phase 1 loads write timed sub-steps with a row count into Layercake.etl_progress_log (log_id, substep, rows_affected) through Layercake.usp_etl_log_progress, under the step's log_id. AC-022-01, AC-022-06 and AC-022-07 test the logged figure (9, 9 and 0).

## Options
### Option A: Sub-step row in etl_progress_log
On every run, the load writes one Layercake.etl_progress_log row through the existing Layercake.usp_etl_log_progress, under the load's own log_id, with substep 'repeated_key_rows_not_landed' and rows_affected set to the count (0 when no key repeats).

Trade-offs: Uses the Phase 1 logging as it is, with no change to a shared table or logging procedure, and the figure is tied to the load's run row by log_id. It is the example the spec gives. Reading it means looking up the progress row by the run row's log_id and the sub-step name, so the name becomes part of the contract the runbook and tests use.

### Option B: New column on etl_run_log
Add a nullable rows_not_landed column to Layercake.etl_run_log and a parameter to Layercake.usp_etl_log_end, and have this load pass the count when it logs Success.

Trade-offs: The figure sits on the run row itself, beside inserted, updated and deleted, so it is easy to query and to show in run reports. But it changes a Phase 1 table and the logging procedure every load calls, for one load's figure. That needs its own change script, a down script and a regression of every caller, and leaves a column that is null on every other step.

## Recommendation
Option A: Sub-step row in etl_progress_log. It meets RULE-129 with the logging Phase 1 already has, changes no shared object, and keeps MOD-024 to one procedure. Looking the figure up by log_id is a small cost, and the runbook names the sub-step.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
DES-001: the Layercake.usp_load_brnz_corporate_subscription description and the corporate subscription repeated keys pattern name the sub-step 'repeated_key_rows_not_landed' with rows_affected as the count, under the load's log_id. MP-001: MOD-024 changes only that procedure, and its tests read the sub-step row. The runbook says where to find the figure. If the second option is chosen, MOD-024 also changes Layercake.etl_run_log and Layercake.usp_etl_log_end through change scripts (both Phase 1 objects, so MOD-024's objects and down script grow), and the full regression of the earlier suites covers every caller of usp_etl_log_end.
