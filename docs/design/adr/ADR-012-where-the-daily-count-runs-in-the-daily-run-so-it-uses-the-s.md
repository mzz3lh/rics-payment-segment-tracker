# ADR-012: Where the daily count runs in the daily run, so it uses the same run's attributes

| | |
|---|---|
| Status | proposed |
| Date | 2026-11-23 |
| Requirement IDs | REQ-026, REQ-021, REQ-024 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
REQ-026 (RULE-158, AMD-007) makes the daily count take each contact-day's payment method, payer type and concession from Layercake.silv_member_year_attributes, as loaded earlier in the same Layercake.usp_run_daily_load run. Today the run is: Phase 1 bronze (usp_load_bronze), Phase 1 silver (usp_load_silver, which runs the payment events, member base, membership events, member profile, the daily count and the annual rate base), Phase 1 gold (usp_load_gold, which includes the gold daily fact), then usp_run_payment_segments (segment bronze, reference lists, gold dimensions, attributes, event amounts, anomalies, event columns; MOD-023, ADR-001). So the daily count runs before the attributes of the same run exist. The attributes load reads the Phase 1 silv_membership_events and silv_payment_events (so it must follow those silver loads) and the segment bronze tables (so it must follow the segment bronze loads of the same run). The segment loads that write onto fact_membership_events must follow the Phase 1 gold step (ADR-001). A failure anywhere must still fail the run, and the next run must recover with no manual step (RULE-125, RULE-158). usp_run_payment_segments must stay callable on its own (RULE-159). Mike leaves the exact order to the design.

## Options
### Option A: Hold back the daily count and the gold daily fact until after the segment loads
usp_load_silver and usp_load_gold each gain one optional switch, off by default, that leaves out the daily count (usp_load_silv_daily_count) and the gold daily fact load (usp_load_fact_daily_member_count_detail) respectively. usp_run_daily_load runs: Phase 1 bronze; Phase 1 silver without the daily count; Phase 1 gold without the daily fact; usp_run_payment_segments (unchanged, same run_id, no as-of date); then usp_load_silv_daily_count, given the run's @FullRebuild and @RebuildFrom; then usp_load_fact_daily_member_count_detail. Every load still runs once per run.

Trade-offs: The segment run order stays in one place, usp_run_payment_segments, which is not changed. Phase 1 silver and gold (other than the two daily count loads) commit before any segment load runs, so a segment failure (as in AMD-004 and AMD-005) still leaves the rest of Phase 1 refreshed, as today. Manual calls of usp_load_silver and usp_load_gold with no switch behave exactly as today, including usp_load_silver @RebuildFrom / @FullRebuild. Cost: two more Phase 1 procedures change (one switch each), and a failing segment load now also stops that run's daily count and gold daily fact, which stay as the previous run left them until the next run (the changed-contacts path then catches up, since the basis was not advanced). The MOD-023 tests that assert the rebuild switches reach the silver step are amended to the daily count step.

### Option B: Run the attributes and its segment prerequisites inside the silver step
usp_run_daily_load runs the four segment bronze loads, the three reference lists and the four gold dimensions straight after the Phase 1 bronze step, and usp_load_silver calls usp_load_silv_member_year_attributes after the membership events and before the daily count. After the Phase 1 gold step, usp_run_daily_load runs the remaining segment loads (event amounts, anomalies, silver and gold event columns) one by one instead of calling usp_run_payment_segments. usp_run_payment_segments is unchanged and still runs everything when called alone.

Trade-offs: The daily count and gold daily fact keep their place in the Phase 1 steps, and usp_load_gold does not change. But the segment order is held in two places (usp_run_payment_segments and usp_run_daily_load), which must be kept in step by hand. A segment bronze failure, such as the corporate subscription failures of AMD-004 and AMD-005, would now stop Phase 1 silver and gold too, a larger blast radius than today. A manual usp_load_silver @RebuildFrom also reloads the attributes, which is harmless but couples the Phase 1 silver step to the segment tables.

## Recommendation
Option A: Hold back the daily count and the gold daily fact until after the segment loads. It meets RULE-158 with each load running once, keeps the segment order in its one existing place, and keeps a segment failure from stopping the rest of Phase 1, which matters after the two corporate subscription failures of November. The only behaviour lost is that a failed segment load now delays that day's daily count to the next run, which recovers with no manual step.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
Design: usp_run_daily_load, usp_load_silver and usp_load_gold become entities changed by MOD-029. The run order pattern is restated: bronze; silver without the daily count; gold without the daily fact; usp_run_payment_segments; daily count; gold daily fact. usp_run_payment_segments is unchanged and stays callable alone; if it is run alone and changes attributes, the next daily run's changed-contacts path brings the daily count into line (RULE-159). Module plan: MOD-029 changes the three procedures, and its down script restores the MOD-023 usp_run_daily_load and the Phase 1 usp_load_silver and usp_load_gold. The Tester amends the MOD-023 conditions that assert @FullRebuild and @RebuildFrom reach the silver step, so that they assert those switches reach the daily count step. If the other option is chosen, MOD-029 changes usp_load_silver and usp_run_daily_load only, and the run order pattern lists the segment loads in two groups.
