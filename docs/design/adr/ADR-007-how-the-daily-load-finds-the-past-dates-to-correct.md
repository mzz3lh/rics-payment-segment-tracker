# ADR-007: How the daily load finds the past dates to correct

| | |
|---|---|
| Status | proposed |
| Date | 2026-11-17 |
| Requirement IDs | REQ-018, REQ-019 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
REQ-018 (RULE-106 to RULE-111) requires every run of Layercake.usp_run_daily_load to correct every date from 2020-10-01 whose stored figures in silv_daily_count_detail and silv_daily_count no longer match the current silver data, whatever the cause, including changes to silv_membership_events alone, which log no pending rebuild today. After any run the stored history must equal what usp_load_silver @FullRebuild = 1 produces (RULE-107). The spec leaves the way changed dates are found to the design, and accepts that a run takes longer on days when a change reaches far back. Today Layercake.usp_load_silv_daily_count derives a past date once and marks it in etl_daily_count_loaded. Only today is rebuilt on every run. The producers of silv_member_state_ranges, silv_payment_events, silv_member_profile and the enrolment exceptions log an earliest affected date in etl_daily_count_pending_rebuild, but nothing applies it. The earlier design (DES-001 v3) calls the full recompute from 2020-10-01 the heaviest step in the solution, to be run outside the daily window. REQ-019 then needs every change the correction makes to be written to the adjustment history in the same transaction (RULE-116), and a failed run to resume on the next run with no manual cleanup (RULE-111).

## Options
### Option A: Compare the inputs with a stored basis
A new control table, Layercake.etl_daily_count_input_basis, holds a fingerprint of the daily count's silver inputs as last applied. Each contact gets one fingerprint over its rows in silv_membership_events, silv_member_state_ranges, silv_payment_events and silv_member_profile, using only the columns the Phase 1 daily derivation reads, together with the earliest date those rows can affect. Each reference table the derivation reads gets one whole-table fingerprint. Each run compares the current inputs with the basis. A contact whose fingerprint changed, appeared or disappeared moves the start of the correction back to the earliest date its old or new rows can affect. A changed reference table moves it back to 2020-10-01. The run recomputes every date from that start to today with the unchanged Phase 1 derivation and writes only the differences. The basis is advanced only after every corrected date has committed.

Trade-offs: Run time follows how far back the earliest change reaches, which is the behaviour Mike accepted. The first run after deployment finds an empty basis, so it recomputes from 2020-10-01 and records the drift so far, which is exactly the catch-up RULE-109 asks for. Detection is central and independent of the producers, so event-only changes are caught. It adds one control table and a fingerprint pass over the four silver inputs on every run. Correctness depends on the fingerprint covering every column and table the derivation reads. Missing one would let that cause drift silently, so the column and table list has to be checked against the Phase 1 code, and the tests compare the result with @FullRebuild. One backdated change in any contact recomputes every date from that point, not only that contact's cells.

### Option B: Recompute the whole span on every run
Every run recomputes every date from 2020-10-01 to today with the Phase 1 derivation and writes only the cells whose figures differ, recording each difference in the adjustment history. No change detection and no new control table.

Trade-offs: This is the simplest option and correct by construction: every cause is covered, including ones nobody has thought of, so RULE-107 holds trivially. A failed run resumes simply by running again. The cost is a full recompute on every run, the step the earlier design said must run outside the daily window. Every daily run would take as long as @FullRebuild, whatever changed, and the time grows each day as the spine lengthens. No volumes are given, so it is unknown whether this fits the daily window.

### Option C: Producers log the earliest affected date and the daily run applies it
Extend the existing pending-rebuild mechanism. The events load (usp_load_silv_membership_events) also logs an earliest affected date for added, changed and removed events, and the daily count applies every open etl_daily_count_pending_rebuild row on every run: it recomputes from the earliest open affected_from and marks the rows applied.

Trade-offs: This reuses a mechanism that already exists and needs no new table. But correctness rests on every producer detecting every change that matters. Today four producers do so with their own rules, and their coverage is not verified. Changes to reference tables, and causes that no producer models, would still drift, so 'every cause' (RULE-106) is not guaranteed. It also changes the Phase 1 events load again (it was last changed by MOD-018) and spreads the logic over five procedures, so a missed case is hard to find.

## Recommendation
Option A: Compare the inputs with a stored basis. It meets RULE-106 for every cause, because detection compares the inputs themselves rather than trusting each producer. Its cost follows how far back the changes reach, which is the behaviour Mike accepted. It reuses the Phase 1 derivation unchanged, it does the first-run catch-up with no special step, and a failed run resumes because the basis is advanced only after every corrected date has committed. Recomputing the whole span is the fallback if the run window allows it: it is simpler, but it makes every run as heavy as @FullRebuild. Producer logging cannot guarantee every cause.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
MOD-022 adds Layercake.etl_daily_count_input_basis and changes the Phase 1 Layercake.usp_load_silv_daily_count. The load writes only differences, records each change to a date already loaded in Layercake.silv_daily_count_adjustment (built by MOD-021), and corrects every date from the earliest affected one on every run. etl_daily_count_pending_rebuild stays as a diagnostic: its producers are unchanged, and the daily count marks open rows applied once its correction covers their date, but nothing reads it to decide what to rebuild. The ASM-002 one-off rebuild after deployment is no longer needed and leaves the runbook (MOD-023's documentation update). If the whole-span recompute is chosen instead, MOD-022 builds no basis table: it recomputes from 2020-10-01 on every run, and its tests and the performance note change accordingly. If producer logging is chosen, MOD-022 instead changes usp_load_silv_membership_events and the daily count's use of the pending table.
