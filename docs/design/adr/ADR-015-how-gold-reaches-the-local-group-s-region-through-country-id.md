# ADR-015: How gold reaches the local group's region through country_id and dim_country

| | |
|---|---|
| Status | proposed |
| Date | 2026-11-26 |
| Requirement IDs | REQ-027 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
RULE-173 and RULE-180: Power BI reads region in gold only through a fact row's country_id and Layercake.dim_country (region_name, market_reporting_region), and no existing gold column may be renamed, retyped or removed. dim_country has one row per country, so a member whose local group's region differs from the region of the group's country (AC-027-02: 'Gulf India', country India, region MEA, where India's own row is APAC) cannot reach the group's region through the country's own row. contact_country_id must still resolve to the country's own row for the own-country region (RULE-175, AC-027-10). Gold therefore needs dim_country rows that pair a country with a local group's regions, and the gold country_id must point at them where needed.

## Options
### Option A: Option A: One extra dim_country row per country and region combination
A new silver list, Layercake.silv_ref_country_region, holds one row per distinct (country, region_name, market_reporting_region) that a reportable local group gives and that differs from that country's own row, with ids from 1000001 that never change. The dim_country load mirrors silv_ref_country as today and adds these rows, with the country's GUID and name and the combination's regions. Each local group records the dim_country id that gives its country and regions (its country's own row when they match). Gold facts take that id as country_id for a member in a reportable group, and the silver country_id otherwise.

Trade-offs: dim_country gains only a handful of rows (most local groups share their country's regions), and for most members the gold country_id equals the silver one, so the dimension looks as it does today. A region change on a group adds a new combination row and re-points the affected fact rows; old rows stay unused. One more silver list and a mapping rule held in one load. Works for either reading of Q-068, because combinations are keyed on values, not on groups.

### Option B: Option B: One extra dim_country row per local group
dim_country gains one row per local group (id offset from the local group id), carrying the group's country GUID and name and the group's regions. Gold facts take the group's row as country_id for every member in a reportable group.

Trade-offs: No combination list: the gold country id follows directly from local_group_id, and a group's region change updates one dimension row in place without touching facts. But dim_country gains a row for every local group, so a country appears many times (every UK local group repeats United Kingdom), and nearly every member's gold country_id changes from today's id, which Power BI relationships and any report listing dim_country rows will see. Under the field-by-field reading of Q-068 a group would need more than one row.

## Recommendation
Option A: Option A: One extra dim_country row per country and region combination. REQ-027 exists so that Power BI needs no change. Option A keeps dim_country and most gold country ids as they are today and adds rows only where a group's region genuinely differs, so the change reports see is the smallest that delivers the local-group regions. It also stays correct whichever answer Q-068 gets.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
Design: adds Layercake.silv_ref_country_region, maintained by Layercake.usp_load_silv_ref_local_group together with silv_ref_local_group.dim_country_id; changes the Phase 1 dim_country load to mirror both silver lists; gold loads of fact_membership_events, fact_annual_rate_base and fact_daily_member_count_detail map country_id through silv_ref_local_group.dim_country_id. dim_country keeps its columns (AC-027-12). If the Phase 1 dim_country carries a unique constraint on its country GUID, that constraint is replaced by one on (country GUID, region_name, market_reporting_region) (Q-069). Module plan: MOD-030 builds the list and the dimension change; MOD-031 and MOD-032 change the gold loads. If Option B is chosen, silv_ref_country_region is not built, MOD-030 adds one dim_country row per local group, and the gold loads map country_id from local_group_id directly.
