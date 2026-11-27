/*====================================================================
    Layercake.silv_member_profile
    Silver layer - table, keys and intrinsic indexes
====================================================================*/

----------------------------------------------------
--  Layercake.silv_member_profile
--  Per-contact reporting attributes needed by the DETAIL daily count.
--  Diff-synced so attribute changes are DETECTED - they are logged to
--  etl_daily_count_pending_rebuild rather than triggering a history
--  recompute.
--  RPST MOD-031 (REQ-027): country_id carries the country BY LOCAL
--  GROUP; local_group_id and contact_country_id (the own country) are
--  copied from silv_member_base like country_id, added by change script.
----------------------------------------------------
create table Layercake.silv_member_profile
(
    contact_no         nvarchar(200) not null
        constraint pk_silv_member_profile primary key clustered,
    country_id         int  not null constraint df_silv_member_profile_ctry default 0,  -- -> silv_ref_country (by local group)
    gender_id          int  not null constraint df_silv_member_profile_gen  default 0,  -- -> silv_ref_gender
    retirement_date    date null,                                                       -- drives day-level Practising/Retired
    local_group_id     int  not null,                                                   -- -> silv_ref_local_group (0 = Unknown)
    contact_country_id int  not null                                                    -- -> silv_ref_country (own country)
);
