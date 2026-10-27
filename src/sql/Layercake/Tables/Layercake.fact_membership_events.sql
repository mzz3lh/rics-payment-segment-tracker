/*====================================================================
    Layercake.fact_membership_events
    Gold layer - table, keys and intrinsic indexes
====================================================================*/

/*====================================================================
    8. GOLD - facts
    ------------------------------------------------------------------
    NOTE: fact_daily_member_count (the old natural-key headline fact) is
    retired and is deliberately NOT in this baseline. The star detail
    fact fact_daily_member_count_detail covers everything it reported -
    the daily headline is SUM(detail), region rolls up from dim_country,
    grade from dim_membership_grade.
    RPST (MOD-007): segment keys, carried flags and amount measures added
    by change script, copied from silver by
    usp_load_fact_membership_events_segments.
====================================================================*/

create table Layercake.fact_membership_events
(
    event_id             int not null constraint pk_fact_membership_events primary key,
    event_type           varchar(20) not null,
    event_subtype        varchar(20) not null,
    event_date           date not null,          -- kept as an attribute: pre-spine events can't resolve via dim_date
    date_id              int not null            -- -> dim_date (0 = pre-spine 'NA' member)
        constraint df_fact_membership_events_date_id default 0,
    contact_no           nvarchar(200) not null,
    grade_id             int not null,          -- -> dim_membership_grade
    assessment_route_id  int not null,          -- -> dim_assessment_route
    rpq_variant_id       int not null,          -- -> dim_rpq_variant
    hpb_id               int not null,
    country_id           int not null,          -- -> dim_country
    gender_id            int not null,          -- -> dim_gender
    membership_status_id int not null,          -- -> dim_membership_status
    campaign_year        int not null,          -- -> dim_campaign_year (kept: pre-spine events)
    campaign_quarter     char(2) not null,
    payment_method_id       int not null constraint DF_Layercake_fact_membership_events_payment_method_id default 0,            -- -> dim_payment_method
    payment_method_carried  bit not null constraint DF_Layercake_fact_membership_events_payment_method_carried default 0,
    payer_type_id           int not null constraint DF_Layercake_fact_membership_events_payer_type_id default 0,                -- -> dim_payer_type
    payer_type_carried      bit not null constraint DF_Layercake_fact_membership_events_payer_type_carried default 0,
    concession_type_id      int not null constraint DF_Layercake_fact_membership_events_concession_type_id default 0,           -- -> dim_concession_type
    concession_type_carried bit not null constraint DF_Layercake_fact_membership_events_concession_type_carried default 0,
    subs_amount             decimal(19, 4) null,    -- additive measures: Join / Renewal / Readmission only
    fee_amount              decimal(19, 4) null,
    invoiced_subtotal       decimal(19, 4) null,
    credited_amount         decimal(19, 4) null,
    currency_id             int null,               -- -> dim_currency
    subs_amount_gbp         decimal(19, 4) null,
    fee_amount_gbp          decimal(19, 4) null,
    invoiced_subtotal_gbp   decimal(19, 4) null,
    credited_amount_gbp     decimal(19, 4) null,
    net_amount_gbp          decimal(19, 4) null,
    amount_status           varchar(30) null
);
