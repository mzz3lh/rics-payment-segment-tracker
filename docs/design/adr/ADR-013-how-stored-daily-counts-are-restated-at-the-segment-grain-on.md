# ADR-013: How stored daily counts are restated at the segment grain on deployment

| | |
|---|---|
| Status | proposed |
| Date | 2026-11-23 |
| Requirement IDs | REQ-026, REQ-019, REQ-020, REQ-024 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
REQ-026 adds payment_method_id, payer_type_id and concession_type_id to the grain of silv_daily_count_detail, etl_daily_count_cell_contacts, silv_daily_count_adjustment and fact_daily_member_count_detail. Their existing rows (about 1.8 million detail cells from 2020-10-01) were stored at the old grain. RULE-162 says they are restated at the new grain, the first run after deployment may take the full-recompute path to do it, the restatement is a change of grain and writes no adjustment rows, and adjustment rows written before deployment keep their figures with -2 Not applicable in the three columns. RULE-163 and AC-026-18 require 'as known at' a time before deployment to stay exact at the silv_daily_count grain and at the old detail grain. REQ-019 still requires every change to a loaded date to be recorded, and the first run after deployment is a normal daily run that also brings in the day's source changes (67 to 394 changed contacts on a normal day, AMD-006). RULE-165 requires the migration and its rollback to be safe on production outside the 06:00 run. On the full-recompute path every changed cell writes an adjustment row (ADR-007), so moving a stored old-grain figure into its new segment cells would write one adjustment row per cell unless the design says otherwise.

## Options
### Option A: Placeholder cells and a one-off restatement run that compares at the old grain
The migration adds the three columns to the four tables, setting -2 on every existing row, so every figure stays where it was and every old-grain total is unchanged straight after deployment. It empties the changed-contacts snapshot tables and writes one marker row in etl_daily_count_input_basis (input_name 'detail_grain_restatement'). While the marker exists, the daily count takes the full-recompute path from 2020-10-01, writes every date's cells at the new grain (the -2 placeholder cells go and the split cells come in), and works out adjustment rows at the old grain: for each old-grain cell, new figures summed over the three columns minus the stored ones, recorded only where non-zero, with -2 in the three columns. The marker is removed in the final transaction of the first run that completes.

Trade-offs: No change of grain writes an adjustment row, yet a real change found by that run (the day's source changes reaching past dates) is still recorded, at the old grain, so stored before plus adjustments still equals stored after at the old grain and 'as known at' stays exact there (RULE-163). Etl_daily_count_loaded keeps its marks. A run that fails part way leaves the marker, and the next run finishes the restatement with no cleanup, because the old-grain comparison holds for dates already split and dates not yet split. Cost: a one-off branch in the daily count load that must be built and tested, and adjustment rows from that one run carry -2 instead of their segment (Q-061).

### Option B: Placeholder cells and a first-load restatement
The migration adds the three columns with -2 on every existing row, as in the first option, empties the snapshot tables and removes every etl_daily_count_loaded mark. The first run then treats every date from 2020-10-01 as a first load, which by RULE-114 writes no adjustment rows, and writes it at the new grain. No new branch is added to the load.

Trade-offs: Simplest to build: the existing first-load rule does the restatement. But a first load records nothing, so every change the run finds to a past date (the day's real source changes, not only the grain) is absorbed with no adjustment row, which breaks REQ-019 for that run and makes 'as known at' for a time before deployment inexact by that day's changes. The loaded marks' original loaded_at, run_id and batch columns are lost, and the down script cannot restore them.

## Recommendation
Option A: Placeholder cells and a one-off restatement run that compares at the old grain. It is the only option that writes no adjustment row for the grain change itself while still recording every real change of that run, so the adjustment history and 'as known at' stay exact at the old grain across the deployment (RULE-162, RULE-163, REQ-019). The migration itself only adds columns, fills a constant and clears internal control rows, so it is short and safe on production outside the 06:00 run (RULE-165). How that run's real changes are recorded is provisional until Q-061 is answered.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
Design: the three new columns are added with -2 on existing rows in silv_daily_count_detail, etl_daily_count_cell_contacts, silv_daily_count_adjustment and fact_daily_member_count_detail. etl_daily_count_input_basis keeps its structure and holds the 'detail_grain_restatement' marker until the first completed run. usp_load_silv_daily_count gains the restatement rule. Straight after deployment the fact holds the old cells under -2 Not applicable, which sum correctly at the old grain until the first run splits them. That first run takes the full path, so it runs about as long as @FullRebuild, and the gold sync deletes and inserts the split cells once. Module plan: MOD-028 builds all of this in one migration, whose down script sums every table back to the old grain over the three columns (adjustment rows by run and old cell), drops the columns and the marker, empties the snapshot so the restored MOD-026 load takes its full path once, and drops etl_daily_count_applied_attribute, renaming it when it holds rows. If the second option is chosen, MOD-028's migration also removes the loaded marks, and the load needs no restatement rule.
