/*====================================================================
    Layercake.silv_membership_events
    Silver layer - table, keys and intrinsic indexes
====================================================================*/

----------------------------------------------------
--  Layercake.silv_membership_events
--  All five lifecycle event types (Join, Change, Lapse, Readmission,
--  Renewal). Because Lapse/Renewal/Readmission/Change events do not come
--  from a single enrolment record, the incremental diff key is event_nk,
--  a deterministic natural key built per event type (see 02). event_id is
--  stable across runs; source_enr_id stays as informational lineage for
--  Join events only.
--  RPST (MOD-007): segment keys, carried flags and amounts added by change
--  script. Keys and flags default to 0 so Phase 1 inserts keep working;
--  values are written by usp_load_silv_membership_events_segments.
----------------------------------------------------
create table Layercake.silv_membership_events
(
    event_id             int identity not null constraint pk_silv_membership_events primary key,
    event_nk             nvarchar(220) not null,        -- incremental diff key
    event_type           varchar(20) not null,          -- Join / Change / Lapse / Readmission / Renewal
    event_subtype        varchar(20) not null,
    event_date           date not null,
    source_enr_id        uniqueidentifier null,         -- Join events only
    contact_no           nvarchar(200) not null,
    grade_id             int not null,
    assessment_route_id  int not null,
    rpq_variant_id       int not null,
    hpb_id               int not null,
    country_id           int not null,
    gender_id            int not null,
    membership_status_id int not null,
    campaign_year        int not null,
    campaign_quarter     char(2) not null,
    payment_method_id       int not null constraint DF_Layercake_silv_membership_events_payment_method_id default 0,             -- -> silv_ref_payment_method
    payment_method_carried  bit not null constraint DF_Layercake_silv_membership_events_payment_method_carried default 0,
    payer_type_id           int not null constraint DF_Layercake_silv_membership_events_payer_type_id default 0,                 -- -> silv_ref_payer_type
    payer_type_carried      bit not null constraint DF_Layercake_silv_membership_events_payer_type_carried default 0,
    concession_type_id      int not null constraint DF_Layercake_silv_membership_events_concession_type_id default 0,            -- -> silv_ref_concession_type
    concession_type_carried bit not null constraint DF_Layercake_silv_membership_events_concession_type_carried default 0,
    subs_amount             decimal(19, 4) null,        -- amounts: Join / Renewal / Readmission only
    fee_amount              decimal(19, 4) null,
    invoiced_subtotal       decimal(19, 4) null,
    credited_amount         decimal(19, 4) null,
    currency_id             int null,                   -- -> silv_ref_currency
    subs_amount_gbp         decimal(19, 4) null,
    fee_amount_gbp          decimal(19, 4) null,
    invoiced_subtotal_gbp   decimal(19, 4) null,
    credited_amount_gbp     decimal(19, 4) null,
    net_amount_gbp          decimal(19, 4) null,
    amount_status           varchar(30) null
);

-- primary incremental diff key
create unique nonclustered index ux_silv_membership_events_nk
    on Layercake.silv_membership_events (event_nk);

-- guards Join-event uniqueness (one Join event per enrolment record;
-- Join events are per contact and JC/JR are mutually exclusive per contact)
create unique nonclustered index ux_silv_membership_events_enr
    on Layercake.silv_membership_events (source_enr_id)
    where source_enr_id is not null;
