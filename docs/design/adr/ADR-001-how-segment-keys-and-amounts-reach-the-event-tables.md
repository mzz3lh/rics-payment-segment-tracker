# ADR-001: How segment keys and amounts reach the event tables

| | |
|---|---|
| Status | proposed |
| Date | 2026-10-23 |
| Requirement IDs | REQ-001, REQ-005, REQ-006, REQ-008, REQ-011, REQ-016 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
Every row of Layercake.silv_membership_events and Layercake.fact_membership_events must carry payment_method_id, payer_type_id, concession_type_id and the three carried flags (REQ-005, REQ-006, REQ-011, RULE-017 to RULE-019, RULE-081). Join, Renewal and Readmission rows must also carry amounts and amount_status (REQ-008). Phase 1 results must not change (REQ-001, RULE-001, RULE-002), and a second run on unchanged data must change nothing (RULE-075, AC-016-02). Amounts can only be worked out once the events exist, because pairing needs each event's type and date and a Join's first paid position (RULE-032, RULE-084 to RULE-086). The Phase 1 load procedures could not be inspected when this design was written (Q-028), so their names, and whether they rebuild in full or apply only changes, are unconfirmed.

## Options
### Option A: Post-Phase-1 enrichment block
The Phase 1 event and fact loads stay as they are. A new run procedure (Layercake.usp_run_payment_segments) runs after the Phase 1 run completes. It loads the new bronze and reference tables, the member-year attributes and the per-event amounts, then two new procedures write the new columns: one onto silv_membership_events from silv_member_year_attributes and silv_event_amount, and one copying them onto fact_membership_events by event_id. Each changes only rows whose new-column values differ.

Trade-offs: Phase 1 code is untouched apart from the payment_source retirement, so the risk to REQ-001 is lowest and rollback is clean: drop the new procedures and columns. All new work sits in one block that runs after Phase 1, so no Phase 1 procedure needs to know about the new tables. Cost: between the Phase 1 load and the enrichment step the new columns briefly hold their defaults (Unknown, null amounts) within a run. If a Phase 1 load rebuilds its table in full each run, the enrichment rewrites every row each run, which breaks the 0-updated rerun check (AC-016-02) and makes this option unsuitable for that table.

### Option B: Extend the Phase 1 loads in place
Change the existing Phase 1 procedures that load silv_membership_events and fact_membership_events. The event load reads silv_member_year_attributes as it derives each event and then, in a second pass in the same procedure, pairs events with invoices and writes amounts. The fact load copies the new columns with the rest.

Trade-offs: No window where the new columns hold defaults, and it works whether Phase 1 rebuilds or applies changes. But it puts the pairing logic inside a Phase 1 procedure, raising the regression risk to REQ-001. It needs the Phase 1 procedure names and internals first (Q-028), makes each module's down script restore large Phase 1 definitions, and changes Layercake team-owned code in several places.

## Recommendation
Option A: Post-Phase-1 enrichment block. It keeps Phase 1 logic unchanged, which is the main risk REQ-001 guards against. It needs no knowledge of Phase 1 procedure internals, which could not be confirmed, and it gives each module a small, testable unit. The recommendation is provisional on Q-031: if the Phase 1 event or fact load rebuilds its table in full each run, the in-place option should be used for that table.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
Design: adds Layercake.usp_load_silv_membership_events_segments, Layercake.usp_load_fact_membership_events_segments and Layercake.usp_run_payment_segments. The new event columns are added as not-null keys and flags with default 0, and as nullable amount columns. silv_member_year_attributes still takes its contact list from the Phase 1 event derivation inputs, as the spec says. Module plan: MOD-007 adds the columns to both event tables alongside the attributes table; MOD-012 adds the two enrichment procedures; MOD-016 adds the run procedure, which a human schedules after the Phase 1 run. If the in-place option is chosen instead, MOD-012 changes the Phase 1 event and fact procedures (names from Q-031) in place of the two enrichment procedures, and MOD-016 adds the new steps into the Phase 1 run sequence.
