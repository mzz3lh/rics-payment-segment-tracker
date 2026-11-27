/*====================================================================
    Layercake.fact_annual_rate_base
    Gold layer - table, keys and intrinsic indexes
====================================================================*/

----------------------------------------------------
--  Layercake.fact_annual_rate_base
--  Straight copy of silv_annual_rate_base - the single reporting-facing
--  source for the Growth / Retention / Renewal / Readmission DAX
--  measures. Power BI connects HERE, never to the silver table, so silver
--  can evolve without moving the model.
--
--  id int identity is the clustered PRIMARY KEY, matching the other star
--  facts. The 7-column segment key is still the business grain and is
--  enforced + made seekable by ux_fact_annual_rate_base_segment - the
--  gold load's diff-sync matches on exactly those columns. The identity
--  id is inert to the load (never referenced, assigned on insert) but
--  gives every row a stable single-column handle.
--  RPST (MOD-032, REQ-027, ADR-015): local_group_id and
--  contact_country_id added by change script and joined to the key.
--  country_id is the dim_country row of the member's region BY LOCAL
--  GROUP; contact_country_id reaches the own country's regions. Reports
--  sum over both to get the Phase 1 grain (RULE-182).
----------------------------------------------------
create table Layercake.fact_annual_rate_base
(
    id                   int identity not null constraint pk_fact_annual_rate_base primary key clustered,
    campaign_year        int not null,          -- -> dim_campaign_year
    grade_id             int not null,          -- -> dim_membership_grade
    membership_status_id int not null,          -- -> dim_membership_status
    country_id           int not null,          -- -> dim_country (region BY LOCAL GROUP, MOD-032)
    gender_id            int not null,          -- -> dim_gender
    members_start        int not null,
    members_end          int not null,
    members_joined       int not null,
    members_readmitted   int not null,
    members_lapsed       int not null,
    members_renewed      int not null,
    local_group_id       int not null,          -- -> dim_local_group (MOD-032)
    contact_country_id   int not null           -- -> dim_country: the member's OWN country (MOD-032)
);

create unique nonclustered index ux_fact_annual_rate_base_segment
    on Layercake.fact_annual_rate_base
    (campaign_year, grade_id, membership_status_id, country_id, gender_id, local_group_id, contact_country_id);
