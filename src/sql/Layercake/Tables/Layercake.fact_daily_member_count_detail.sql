/*====================================================================
    Layercake.fact_daily_member_count_detail
    Gold layer - table, keys and intrinsic indexes
====================================================================*/

----------------------------------------------------
--  Layercake.fact_daily_member_count_detail  (star detail fact)
--  Every key a dim surrogate; identity id kept as a NONCLUSTERED pk, and
--  the natural star grain is the unique CLUSTERED index so the window
--  diff/delete/insert works off a single date_id-leading b-tree.
--  id is bigint (MOD-027, RULE-152, Q-056): kept because the repository
--  cannot show that nothing outside the database reads it.
--  RPST (MOD-028, REQ-026): payment_method_id, payer_type_id and
--  concession_type_id (dim_payment_method / dim_payer_type /
--  dim_concession_type keys, equal to the silver ids) added by change
--  script and part of the star grain. No foreign keys, as on the segment
--  columns of fact_membership_events. A report that wants the old grain
--  SUMs over the three columns (RULE-167).
--  RPST (MOD-031, REQ-027, ADR-015): country_id now holds the dim_country
--  row that gives the member's region BY LOCAL GROUP (a usable group's
--  silv_ref_local_group.dim_country_id, else the own country);
--  local_group_id (dim_local_group) and contact_country_id (dim_country
--  key of the own country) added by change script and part of the star
--  grain, no foreign keys. A report that wants the old grain also SUMs
--  over these two columns (RULE-182).
--
--  PaidMembers vs PaidMembersEvent are two independent readings of the
--  same question, carried side by side so a report can show either or
--  compare them (see silv_daily_count_detail for the rules):
--    PaidMembers      - payment-driven: a paid subs position for the
--                       campaign year, dated on or before the day.
--    PaidMembersEvent - event-driven: Join + Renewal + Readmission,
--                       accumulated from each 1 October. Lapsing does
--                       not deduct.
--  JoinEvents / RenewalEvents / ReadmissionEvents are the daily flows
--  PaidMembersEvent is built from - additive over any date range, and a
--  running total of them reproduces PaidMembersEvent. LapseEvents is
--  reported alongside rather than netted off: members who had paid this
--  campaign year and then lapsed.
----------------------------------------------------
create table Layercake.fact_daily_member_count_detail
(
    id                   bigint identity not null
        constraint pk_fact_daily_member_count_detail primary key nonclustered,
    date_id              int not null,    -- -> dim_date
    country_id           int not null,    -- -> dim_country (region by local group rolls up here)
    gender_id            int not null,    -- -> dim_gender
    membership_grade_id  int not null,    -- -> dim_membership_grade (0 = N/A - incl. daily lapse rows; lapse is event-only)
    membership_status_id int not null,    -- -> dim_membership_status (Practising/Retired; 0 = N/A - incl. daily lapse rows)
    ActiveMembers        int not null,
    PaidMembers          int not null,    -- payment-driven (original)
    PaidMembersEvent     int not null,    -- event-driven (stock)
    JoinEvents           int not null,    -- event-driven components (daily flow)
    RenewalEvents        int not null,
    ReadmissionEvents    int not null,
    LapseEvents          int not null,    -- reported, not deducted from PaidMembersEvent
    payment_method_id    int not null,    -- -> dim_payment_method
    payer_type_id        int not null,    -- -> dim_payer_type
    concession_type_id   int not null,    -- -> dim_concession_type
    local_group_id       int not null,    -- -> dim_local_group (0 = Unknown)
    contact_country_id   int not null     -- -> dim_country (own country and its regions)
);

create unique clustered index cx_fact_daily_member_count_detail
    on Layercake.fact_daily_member_count_detail
    (date_id, country_id, gender_id, membership_grade_id, membership_status_id,
     payment_method_id, payer_type_id, concession_type_id, local_group_id, contact_country_id);
