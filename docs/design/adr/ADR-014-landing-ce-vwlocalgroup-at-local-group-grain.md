# ADR-014: Landing CE.vwLocalGroup at local group grain

| | |
|---|---|
| Status | proposed |
| Date | 2026-11-26 |
| Requirement IDs | REQ-027 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
REQ-027 (RULE-169, RULE-170) needs CE.vwLocalGroup landed one row per apuk_localgroupid, so each member's local group can give its country and region. The Phase 1 Layercake.brnz_local_group already lands CE.vwLocalGroup, but at country grain: its key is apuk_countryid (NOT NULL) and it holds apuk_countryid_name, apuk_worldregionid_name and market_reporting_region, from which Phase 1 derives each country's own region in silv_ref_country. RULE-169 lets the design choose a new bronze table or a change to brnz_local_group, provided the own-country region values Phase 1 derives today (silv_ref_country.region_name and market_reporting_region) stay unchanged, because they become the own-country region kept beside contact_country_id (RULE-175).

## Options
### Option A: Option A: New bronze table at local group grain
Add Layercake.brnz_local_group_detail, a 1:1 landing of CE.vwLocalGroup keyed on apuk_localgroupid with apuk_name, apuk_code, apuk_countryid, apuk_worldregionid_name, market_reporting_region, statecode and the four standard bronze audit columns, and its own load. The Phase 1 brnz_local_group, its load and the silv_ref_country derivation are left exactly as they are.

Trade-offs: Own-country regions cannot change, because nothing Phase 1 reads is touched, and the down script only drops the new table and load. The source is landed twice per run (a few hundred rows each, so the cost is negligible), and two bronze tables hold the same source at different grains, which the handover must explain.

### Option B: Option B: Change brnz_local_group to local group grain
Re-key the Phase 1 brnz_local_group on apuk_localgroupid and add the extra columns, and change the Phase 1 silv_ref_country load so that it reduces the local groups to one region per country exactly as the country-grain landing does today.

Trade-offs: One landing of the source. But it changes a Phase 1 table's key and the load that sets every country's region, so RULE-169's 'own-country values unchanged' has to be proved by a new derivation of the same result, and any Phase 1 rule for choosing a country's region among several local groups must be reproduced exactly. The down script has to re-key a table holding rows and restore two Phase 1 procedures.

## Recommendation
Option A: Option A: New bronze table at local group grain. RULE-169 makes keeping the own-country regions unchanged a hard condition. Option A meets it by not touching anything Phase 1 reads, at the cost of landing a small source twice. Option B puts the regions of every country at risk to save one small landing.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
Design: adds Layercake.brnz_local_group_detail and Layercake.usp_load_brnz_local_group_detail, called from the Phase 1 bronze step (Layercake.usp_load_bronze); Layercake.silv_ref_local_group is loaded from it. brnz_local_group, its load and silv_ref_country are unchanged. Module plan: MOD-030 builds the table and its load. If Option B is chosen, MOD-030 instead changes brnz_local_group through a change script and changes the Phase 1 silv_ref_country load, and its tests must show silv_ref_country unchanged on the same data.
