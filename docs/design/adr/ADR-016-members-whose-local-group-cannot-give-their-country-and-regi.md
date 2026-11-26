# ADR-016: Members whose local group cannot give their country and region (provisional)

| | |
|---|---|
| Status | proposed |
| Date | 2026-11-26 |
| Requirement IDs | REQ-027 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
SPEC-001 is inconsistent on this point (Q-068). Its rules RULE-170 to RULE-173 and AC-027-04 apply the restated defaults: an inactive local group is used like any other, a group with no country keeps the member's own country but takes the group's region, and a group with a NULL or blank region value keeps the member's own region in that field only, each member keeping its group's local_group_id. The answer to Q-066 recorded in the same spec says the restated defaults are not what Mike accepted: a member whose local group is missing, unknown, inactive, has no country, or gives no region keeps their own country and own-country region in every field, with local_group_id 0 Unknown, and no field-by-field mixing. RULE-179 and AC-027-13 give pre-deployment adjustment rows local_group_id 0, while the answer to Q-067 gives them -2. The rule has to sit in one place so the answer changes one object.

## Options
### Option A: Option A: Whole-member fallback (Q-066 answer)
A local group is reportable when it is live in bronze, active (statecode 0), its country is in silv_ref_country and both apuk_worldregionid_name and Market_reporting_region are non-blank. A member in a reportable group takes the group's id, country and both regions. Any other member (no group, a group CE does not hold, or a group that is not reportable) takes local_group_id 0 and their own country and own-country regions in every field. Pre-deployment adjustment rows take local_group_id -2 (Q-067 answer).

Trade-offs: Follows the latest recorded human answer; every member's values come wholly from one source, so a region is never paired with a country it does not belong to, and the gold country id depends on the group alone. But N3, N4 and N5 in AC-027-04 then get UK / UK&I and local_group_id 0, and AC-027-13 expects 0 where this gives -2, so both ACs fail as written until the Analyst amends them. Members of inactive groups lose their group in reports.

### Option B: Option B: Field-by-field fallback (rules and ACs as written)
Every group in CE is used, active or not. country_id takes the group's country, or the member's own where the group has none; each region field takes the group's value, or the member's own where the group's value is NULL or blank; local_group_id is always the group's id, 0 only with no group or a group CE does not hold. Pre-deployment adjustment rows take local_group_id 0.

Trade-offs: Matches RULE-170 to RULE-173, RULE-179, AC-027-04 and AC-027-13 as written, so the Tester's expectations hold. But it contradicts the recorded Q-066 and Q-067 answers, can pair a country with another country's region (N3: United Kingdom with MEA), and makes the gold country id depend on the group and the member's own country together, which needs more combination rows (ADR-015 Option A handles it).

## Recommendation
Option A: Option A: Whole-member fallback (Q-066 answer). Provisional until Q-068 is answered. The Q-066 and Q-067 answers are the latest human decisions recorded in the signed-off spec and say explicitly that the restated defaults differ from what Mike accepted, so the design follows them. The rule is held only in Layercake.usp_load_silv_ref_local_group (which group is reportable and its dim_country id) and Layercake.vw_silv_contact_local_group (what each member takes), so Option B can be adopted by changing those two objects and the migration's -2.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
Design: silv_ref_local_group carries is_reportable and dim_country_id; vw_silv_contact_local_group applies the whole-member fallback; MOD-031's migration writes local_group_id -2 on pre-deployment adjustment rows. Module plan: MOD-030 and MOD-031 are blocked on Q-068 for AC-027-04 and AC-027-13; the Analyst amends RULE-170 to RULE-173, RULE-179, AC-027-04 and AC-027-13 to match before those modules are tested, or the human chooses Option B, in which case MOD-030 changes the reportable test and the view, and MOD-031's migration writes 0.
