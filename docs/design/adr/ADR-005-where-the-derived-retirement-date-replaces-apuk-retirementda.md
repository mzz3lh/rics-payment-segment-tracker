# ADR-005: Where the derived retirement date replaces apuk_retirementdate

| | |
|---|---|
| Status | proposed |
| Date | 2026-11-09 |
| Requirement IDs | REQ-017, REQ-012, REQ-001 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
REQ-017 (RULE-099 to RULE-101, AMD-001) makes a derived retirement date, taken from Layercake.brnz_subs_status, replace apuk_retirementdate (Layercake.silv_member_base.retirement_date) wherever Phase 1 sets Practising / Retired: events, annual rate base and daily counts. REQ-001 (RULE-102, Q-046) says nothing else in Phase 1 may change. In Phase 1, silv_member_base.retirement_date is set in one place, Layercake.usp_load_silv_member_base (a full re-derive from the latest brnz_rics_record row). It is read to set membership_status_id by Layercake.usp_load_silv_membership_events (five places) and Layercake.usp_load_silv_annual_rate_base. The daily count reads a copy held in Layercake.silv_member_profile, which Layercake.usp_load_silv_member_profile keeps in step and which registers a pending daily rebuild when the date changes (ASM-002, Q-048). No difference or reconciliation script reads silv_member_base.retirement_date. The design must choose which Phase 1 objects change to put the derived date in front of every status reader.

## Options
### Option A: Replace the value at its single source
A new view, Layercake.vw_silv_derived_retirement_date, gives one row per contact with the derived date (RULE-099). Layercake.usp_load_silv_member_base fills silv_member_base.retirement_date from that view instead of from apuk_retirementdate; a contact with no derived date gets null (RULE-101). No table changes structure, and the events, annual rate base, member profile and daily count procedures are not changed: they pick the new value up as they read it today. The member profile load sees the changed dates and registers the pending daily rebuild as it already does.

Trade-offs: One Phase 1 procedure changes, so the down script and the regression surface are small, and every status reader is consistent by construction: no reader can be missed. The existing pending-rebuild path carries the change to the daily count. Cost: silv_member_base.retirement_date changes meaning, so apuk_retirementdate is no longer visible in silver (it stays in bronze brnz_rics_record and in the reconciliation diagnostic columns). Before-and-after comparisons such as AC-017-07 must compare against a snapshot taken before the change.

### Option B: Add the derived date alongside apuk_retirementdate
silv_member_base keeps retirement_date as apuk_retirementdate and gains a derived_retirement_date column, and silv_member_profile gains the same column. usp_load_silv_member_base fills it from the view, and usp_load_silv_membership_events, usp_load_silv_annual_rate_base and usp_load_silv_member_profile are changed to read the derived column for status. The profile's pending-rebuild trigger is changed to watch the new column. usp_load_silv_daily_count reads the profile's new column.

Trade-offs: Both dates sit side by side in silver, so the source date stays visible for comparisons and diagnostics. Cost: two Phase 1 tables and four or five Phase 1 procedures change (seven places in all), so the change, its down script and the Phase 1 regression are several times larger, and a missed reader would leave one output on the old date. It also leaves a column (retirement_date) that no status logic uses, which invites misuse.

## Recommendation
Option A: Replace the value at its single source. Mike's answer says the derived date replaces silv_member_base.retirement_date for every reader, and Q-048 confirms the column is used only to set membership_status_id. Changing the one procedure that fills it meets RULE-100 everywhere at once, keeps the Phase 1 change and its rollback to one procedure, and reuses Phase 1's own pending-rebuild path for daily counts. The apuk value is still available in bronze for anyone who needs it.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
Adds Layercake.vw_silv_derived_retirement_date and changes Layercake.usp_load_silv_member_base, both in MOD-018, which depends on MOD-017 (brnz_subs_status gains retired_concession and inv_total_amount). MOD-018's down script restores the Phase 1 definition of usp_load_silv_member_base and drops the view. No other Phase 1 procedure changes. The retirement comparison (MOD-013) reads the same view. After the first Phase 1 run on the new definition, a one-off Layercake.usp_load_silver @RebuildFrom (or @FullRebuild = 1) is needed so past daily counts take the new Practising / Retired split; it is a human step in the handover. If the second option is chosen, MOD-018 instead changes silv_member_base, silv_member_profile and the events, annual rate base and member profile loads, and becomes two modules.
