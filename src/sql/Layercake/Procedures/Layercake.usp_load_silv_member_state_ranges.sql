/*====================================================================
    Layercake.usp_load_silv_member_state_ranges
    Silver layer - loads one table
====================================================================*/

/*====================================================================
    11. Layercake.silv_member_state_ranges
    ------------------------------------------------------------------
    Full re-derive into #rng_stage, then a per-contact diff-sync: only
    contacts whose range set actually changed are deleted + re-inserted.

    P2-14: the ranges derive ENTIRELY from silv_membership_events.
    Events are the single source of business rules; the ranges are just
    those events pivoted into from/to periods, so daily counts and
    event-level reporting reconcile by construction.

    State mapping:
      Join/Candidate -> 'enrolment'   Join/RPQ, Change -> 'election'
      Lapse          -> 'lapse'       Readmission -> the grade held
                                                     at readmission
      Join/Subscription -> 'enrolment'. The payment-derived Join always
      carries grade N/A (module 9: the contact has neither date), so it
      opens the non-qualified active state and orders with Candidate,
      not with the elected Joins the catch-all arm covers.

    v6 SAME-DAY ORDERING: events on the same date order as
    enrolment -> election -> lapse (-> readmission), and that per-contact
    sequence is PERSISTED in state_seq.

    REGION BY LOCAL GROUP (MOD-031, REQ-027, RULE-173, RULE-175): region
    is the member's world region (the flavour Phase 1 uses) from
    Layercake.vw_silv_contact_local_group: the usable local group's
    region, else the own country's. contact_region is always the own
    country's world region. An unknown own country (country 0) gives
    'N/K', as Phase 1 does: in contact_region always, and in region
    when the member has no usable local group (a usable group still
    gives its own region). A contact the view does not hold (no live
    brnz_contact row) keeps the Phase 1 rule from the event's country in
    both columns. A region longer than varchar(12) fails the load with
    an error naming the value; it is never cut short.

    The earliest date the changed contacts could affect goes to the
    RETRO-CHANGE LOG - it does not rebuild history.
====================================================================*/
create or alter procedure Layercake.usp_load_silv_member_state_ranges
    @run_id uniqueidentifier = null
as
begin
    set nocount on;
    set xact_abort on;

    if @run_id is null set @run_id = newid();

    declare @log_id          bigint,
            @ins             int,
            @del             int,
            @rc              int,
            @substep_ts      datetime2(3),
            @err             nvarchar(4000),
            @rng_recalc_from date,
            @long_value      nvarchar(200),
            @long_contact    nvarchar(200),
            @long_n          int,
            @long_msg        nvarchar(2048);

    begin try
        exec Layercake.usp_etl_log_start @run_id, 'silver', 'silv_member_state_ranges', @log_id output;
        set @substep_ts = sysdatetime();
        begin tran;

        -- MOD-031: each contact's regions, one row per contact number. The view
        -- has one row per live brnz_contact row; a contact number held twice is
        -- stopped downstream (the events and profile loads fail on it), and the
        -- lowest ContactId keeps this stage deterministic meanwhile.
        select v.contact_no,
               iif(v.local_group_id = 0 and v.contact_country_id = 0, N'N/K', v.region_name) as region,
               iif(v.contact_country_id = 0, N'N/K', v.contact_region_name)                 as contact_region
        into #clg
        from (
            select l.contact_no, l.local_group_id, l.contact_country_id, l.region_name, l.contact_region_name,
                   row_number() over (partition by l.contact_no order by l.contact_id) as rn
            from Layercake.vw_silv_contact_local_group l
            where l.contact_no is not null
        ) v
        where v.rn = 1;

        create unique clustered index cx_clg on #clg (contact_no);

        -- one row per contact per state, with valid_from/valid_to bounding the
        -- period in that state. Retirement is NOT a range: Practising/Retired
        -- is a sub-status of Qualified, so retirement doesn't end an active range.
        with ev as (
            select
                e.contact_no,
                e.event_date,
                case
                    when e.event_type = 'Join' and e.event_subtype = 'Candidate' then 'enrolment'
                    -- a payment-derived Join (module 9) opens the NON-QUALIFIED
                    -- active state: it carries grade N/A by construction - the
                    -- contact has neither an enrolment nor an election date -
                    -- so the catch-all Join arm below, which reads every other
                    -- Join as an election, would assert a grade the source
                    -- does not support
                    when e.event_type = 'Join' and e.event_subtype = 'Subscription' then 'enrolment'
                    when e.event_type = 'Join'                                   then 'election'
                    when e.event_type = 'Change'                                 then 'election'
                    -- a readmitted member re-opens at the grade held at readmission
                    when e.event_type = 'Readmission' then iif(mg.grade_name = 'Qualified', 'election', 'enrolment')
                    when e.event_type = 'Lapse'                                  then 'lapse'
                end as grade,
                -- v2 parity: Region is the WORLD region name (as Gold Layer v2
                -- uses), not market_reporting_region - both stay available on
                -- silv_ref_country / dim_country. MOD-031: by local group, from
                -- the view (see the header); Phase 1's rule where it has no row.
                case when clg.contact_no is not null then clg.region
                     else iif(e.country_id = 0, 'N/K', ctry.region_name) end as region,
                case when clg.contact_no is not null then clg.contact_region
                     else iif(e.country_id = 0, 'N/K', ctry.region_name) end as contact_region,
                -- same-day ordering: enrolment < election < lapse < readmit,
                -- so a same-day lapse + readmission nets out to an active
                -- state, and a same-day enrolment + election ends the day
                -- elected (the LATEST state wins the day)
                case
                    when e.event_type = 'Join'
                     and e.event_subtype in ('Candidate', 'Subscription')        then 1
                    when e.event_type in ('Join', 'Change')                      then 2
                    when e.event_type = 'Lapse'                                  then 3
                    else 4
                end as ord
            from Layercake.silv_membership_events e
            inner join Layercake.silv_ref_country ctry
                on  e.country_id = ctry.id
            left join Layercake.silv_ref_membership_grade mg
                on  mg.id = e.grade_id
            left join #clg clg
                on  clg.contact_no = e.contact_no
            -- Renewal events don't open or close a state: they drive the paid
            -- count via silv_payment_events, not the active state ranges
            where e.event_type in ('Join', 'Change', 'Lapse', 'Readmission')
        ),
        -- distinct guards against events landing on the same
        -- contact/date/state (they would only produce zero-length duplicate
        -- ranges, but this keeps the stage clean and the diff small)
        date_list as (
            select
                v.contact_no,
                v.event_date,
                v.grade,
                v.region,
                v.contact_region,
                row_number() over (partition by v.contact_no order by v.event_date, v.ord) as id
            from (select distinct contact_no, event_date, grade, region, contact_region, ord from ev) v
        )
        -- each state runs from its own event date to the NEXT event in the
        -- sequence (null = open ended). Same-day transitions produce
        -- zero-length ranges (valid_from = valid_to) which fall out naturally
        -- in the daily-count join (half-open interval) - the day counts the
        -- latest state only.
        select
            a.contact_no,
            a.event_date as valid_from,
            b.event_date as valid_to,
            case when month(a.event_date) >= 10 then year(a.event_date) + 1 else year(a.event_date) end as campaign_year_from,
            a.grade,
            a.region,
            a.id         as state_seq,
            a.contact_region
        into #rng_stage
        from date_list a
        left join date_list b
            on  a.contact_no = b.contact_no
            and a.id = b.id - 1;
        set @rc = @@rowcount;

        create clustered index cx_rng_stage on #rng_stage (contact_no);
        exec Layercake.usp_etl_log_progress @log_id, N'stage #rng_stage (events -> ranges)', @rc, @substep_ts output;

        -- MOD-031: a region that does not fit varchar(12) stops the load with
        -- the whole value named, rather than being cut short on insert
        select @long_n = count(*),
               @long_value = min(v.val),
               @long_contact = min(v.contact_no)
        from (select s.contact_no, s.region as val from #rng_stage s where len(s.region) > 12
              union all
              select s.contact_no, s.contact_region from #rng_stage s where len(s.contact_region) > 12) v;

        if @long_n > 0
        begin
            set @long_msg = concat(N'Region value too long for Layercake.silv_member_state_ranges (varchar(12)): ''',
                                   @long_value, N''' (contact ', @long_contact, N'; ', @long_n,
                                   N' range(s) affected). Nothing was written; correct the local group or country region and rerun.');
            throw 50031, @long_msg, 1;
        end

        -- contacts whose derived range set differs from what's stored
        -- (either direction: new/moved ranges, and ranges that disappeared).
        select contact_no
        into #rng_changed
        from (
            select contact_no from (
                select contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq, contact_region from #rng_stage
                except
                select contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq, contact_region from Layercake.silv_member_state_ranges
            ) a
            union
            select contact_no from (
                select contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq, contact_region from Layercake.silv_member_state_ranges
                except
                select contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq, contact_region from #rng_stage
            ) b
        ) v;
        set @rc = @@rowcount;

        create unique clustered index cx_rng_changed on #rng_changed (contact_no);

        -- earliest calendar date these changes can affect: min valid_from over
        -- BOTH the old rows (about to be removed) and the new rows.
        -- Informational only - it feeds the pending-rebuild log, not a
        -- recompute window.
        set @rng_recalc_from = (
            select min(v.valid_from)
            from (
                select s.valid_from
                from #rng_stage s
                join #rng_changed ch on ch.contact_no = s.contact_no
                union all
                select t.valid_from
                from Layercake.silv_member_state_ranges t
                join #rng_changed ch on ch.contact_no = t.contact_no
            ) v);
        exec Layercake.usp_etl_log_progress @log_id, N'diff: changed contacts', @rc, @substep_ts output;

        -- per-contact replace: cheap, and only touches contacts that changed
        delete tgt
        from Layercake.silv_member_state_ranges tgt
        join #rng_changed ch on ch.contact_no = tgt.contact_no;
        set @del = @@rowcount;
        exec Layercake.usp_etl_log_progress @log_id, N'sync: delete changed contacts', @del, @substep_ts output;

        insert into Layercake.silv_member_state_ranges
        (contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq, contact_region)
        select s.contact_no, s.valid_from, s.valid_to, s.campaign_year_from, s.grade, s.region, s.state_seq, s.contact_region
        from #rng_stage s
        join #rng_changed ch on ch.contact_no = s.contact_no;
        set @ins = @@rowcount;
        exec Layercake.usp_etl_log_progress @log_id, N'sync: insert changed contacts', @ins, @substep_ts output;

        -- retro-change log: only if these changes reach already-loaded dates
        exec Layercake.usp_etl_log_pending_rebuild @run_id, 'state_ranges', @rng_recalc_from, @rc output;
        if @rc > 0
            exec Layercake.usp_etl_log_progress @log_id, N'retro change logged (not rebuilt) - see etl_daily_count_pending_rebuild', @rc, @substep_ts output;

        commit;
        exec Layercake.usp_etl_log_end @log_id, 'Success', @ins, 0, @del;
    end try
    begin catch
        if xact_state() <> 0 rollback;
        set @err = concat(error_message(), ' (error ', error_number(), ', line ', error_line(), ')');
        if @log_id is not null
            exec Layercake.usp_etl_log_end @log_id, 'Failed', @ins, 0, @del, @err;
        throw;
    end catch
end
