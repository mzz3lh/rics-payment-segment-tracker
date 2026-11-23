/*====================================================================
    Layercake.usp_load_silv_daily_count
    Silver layer - loads one table
====================================================================*/

/*====================================================================
    13. Layercake.silv_daily_count_detail + Layercake.silv_daily_count
        (two tables, one module: see the file header)
    ------------------------------------------------------------------
    WHAT THIS MODULE LOADS (MOD-022 ADR-007, MOD-026 ADR-011): the
    daily counts, written as DIFFERENCES only. After any completed run
    the stored history, the cell counts and the adjustment rows equal
    what @FullRebuild = 1 produces on the same data.

    SEGMENT GRAIN (MOD-028, REQ-026, RULE-155 to RULE-161): a detail
    cell is [date] x region x country x gender x grade x status x
    payment method x payer type x concession type. A contact-day takes
    the three ids from its silv_member_year_attributes row for the
    day's Campaign Year (the spine's campaign_year), carried or not,
    for every grade and measure, and 0 Unknown where it has no row.
    The attributes are one row per contact and Campaign Year, so a
    contact still sits in one cell per day. silv_daily_count keeps its
    grain: it is the sum over the detail as before.

    GUARD (RULE-145): before anything is written, every run checks that
    no contact holds two overlapping non-zero-length state ranges
    ([valid_from, valid_to), a null valid_to open-ended). If one does,
    the run fails naming the first such contact and writes nothing:
    the count rule below relies on one cell per contact per day.

    INPUTS: per contact, its rows in silv_membership_events,
    silv_member_state_ranges, silv_payment_events, silv_member_profile
    and (MOD-028) silv_member_year_attributes, limited to the columns
    read below, are fingerprinted and compared with
    Layercake.etl_daily_count_input_basis (the inputs as last applied).
    A change to any of the three attribute ids in any Campaign Year
    makes the contact a changed contact (RULE-160). The reference
    tables (ref_date_spine and ref_campaign_year_config up to the
    latest loaded date, silv_ref_membership_status in full) get one
    fingerprint each. The segment reference lists are not inputs
    (RULE-161).

    RESTATEMENT (MOD-028, ADR-013, Q-061): while the basis holds the
    'detail_grain_restatement' marker (written by the MOD-028
    migration), the run takes the full-recompute path from 2020-10-01
    and works out its adjustment rows at the OLD grain: per [date],
    region, country, gender, grade and status, the new figures summed
    over the three ids minus the stored ones, written with -2 in the
    three ids. A change of grain alone therefore writes nothing. The
    marker goes in the final transaction of the first run that
    completes; a run that fails part way keeps it.

    TWO PATHS. Every run logs the etl_progress_log sub-steps
    'contacts_recomputed' and 'full_recompute_path' (RULE-153).
      FULL-RECOMPUTE PATH (the MOD-022 behaviour) for @FullRebuild,
      @RebuildFrom, a changed reference table, the restatement marker,
      or a snapshot not in step with the basis (some contact has a
      'contact' basis row but no etl_daily_count_applied_contact row, or
      the reverse: after deployment, or after a run that did not
      finish). Every spine date from the START DATE to today is derived
      from all contacts and written as differences. The START DATE is
      the earliest of the changed contacts' earliest affected dates (the
      start of the Campaign Year of the earliest input row, old or new,
      never before 2020-10-01), 2020-10-01 for a changed reference
      table, the marker or a snapshot out of step, the first date not
      yet loaded, today, and @RebuildFrom (2020-10-01 for @FullRebuild).
      CHANGED-CONTACTS PATH (a normal run): on the dates already loaded
      that a changed contact's inputs can reach, its contribution
      worked out from its snapshot (the etl_daily_count_applied_*
      tables) is taken out and the one from its current inputs added.
      The same derivation gives both. A cell whose contact count
      (etl_daily_count_cell_contacts) rises from 0 is inserted, one that
      falls to 0 is deleted (Q-059), and the touched silv_daily_count
      rows are brought to the sum of their detail. Dates not yet loaded
      are first-loaded from all contacts as on the full path.

    WRITES: date-ordered batches of @DailyCountBatchDays dates (default
    31), each ONE transaction with its detail and main differences, its
    adjustment rows (one per detail cell whose figures change on a date
    ALREADY MARKED in etl_daily_count_loaded, new minus old, a missing
    cell counting as 0), its cell counts and its loaded marks. A first
    load writes no adjustment. The first batch transaction also
    withdraws the changed contacts' snapshot rows (an appeared contact
    gets a header of its own instead), so a run that does not finish
    leaves the snapshot out of step and the next run takes the full
    path, which finds no differences where batches committed.

    FINAL TRANSACTION: after the last batch, the basis and the snapshot
    of the contacts this run applied (and of any out of step) are
    brought into line with the inputs the run used, the restatement
    marker is removed, and open etl_daily_count_pending_rebuild rows
    whose affected_from the start date covers are stamped applied. That
    table is a diagnostic only.

    FAILURE: committed batches stay committed and the error is
    re-raised. No cleanup.

    COUNT DERIVATION: ONE join builds the DETAIL cells, and the main
    silv_daily_count is a plain SUM over it. Each measure is the SUM of
    the contacts' 0-or-1 contributions (RULE-144, RULE-146): a contact
    occupies at most one detail cell per day (the guard, and one
    attributes row per contact and Campaign Year) and every join below
    is 1:1 against the range row, so the sums equal the Phase 1
    distinct counts. A contact contributes a contact count of 1 to its
    cell on each day it sits there, whatever its measures.

    COUNT RULE: a member counts in the LATEST state they held on any
    given day. The half-open interval join [valid_from, valid_to)
    implements this: a same-day transition leaves a zero-length range
    (matches no date), so the day lands on the last state opened that
    day - state_seq guarantees that is the last event in the
    enrolment -> election -> lapse order.

    STATUS RULE: 'election' rows split by day-level status - Retired
    from the retirement date onward, else Practising (a null retirement
    date -> Practising). 'enrolment' and 'lapse' rows carry status N/A.

    v2-parity: open-ended ranges count through today; lapsed members
    never count as Active.

    ------------------------------------------------------------------
    TWO PAID MEASURES, SIDE BY SIDE
    ------------------------------------------------------------------
    Both count contacts, both are gated by the same state-range join as
    the active count (so every driver exclusion on the active side
    removes the contact from both paid numbers too), and both are
    attributed to the cell the contact occupies on the day. They are
    NOT expected to agree - carrying both is the point.

    paid_count (PAYMENT-driven, the original, unchanged)
      A payment event for the day's campaign year whose adjusted renewal
      date is on or before the day. Reads silv_payment_events, i.e. the
      subs invoice position.

    paid_count_event (EVENT-driven, added alongside)
      Reads silv_membership_events instead: joins + renewals +
      readmissions. A contact is PAID IN from the earliest Join /
      Renewal / Readmission event in the campaign year (step e picks
      exactly one - they are already mutually exclusive per contact per
      year, since module 9 excludes the Join year and the Readmission
      years from Renewal; the tie-break only makes that deterministic),
      and stays counted for the rest of that year. Keyed on campaign
      year, so the measure resets to zero on each 1 October and builds
      through the year: on any day it is how many members have paid so
      far this campaign year.

      LAPSING DOES NOT DEDUCT. A member who paid and then lapsed still
      paid, and this measure is a count of that. Lapses are still
      derived and still reported - event_lapse_count below - they just
      do not come back off the number. That makes paid_count_event
      monotonic within a campaign year, and it is the one place it parts
      company with every other count in this module (the active count,
      and paid_count through its state-range gate, both stop at a
      lapse).

      Join here is the Join EVENT (enrolment-dated for Candidates,
      election-dated for RPQ direct entries), not a payment - which is
      the substantive difference from paid_count and the reason the two
      diverge in a member's first year.

    event_join_count / event_renewal_count / event_readmission_count are
    the daily FLOWS behind paid_count_event: the contacts whose paid-in
    fell on that day. They reconcile with the stock by construction - a
    running total of (join + renewal + readmission) from the campaign
    year start reproduces paid_count_event exactly, at the day level.
    That holds on the TOTAL, not cell by cell: the stock is attributed
    to the cell the contact sits in on the day being counted, the flow
    to the cell they sat in on the event day, and a member who moves
    country or is elected moves cell in between.

    event_lapse_count sits alongside them as a FOURTH flow, reported but
    NOT part of that identity - it is the contacts who had paid in this
    campaign year and then lapsed on that day. Two things it is not: it
    is not deducted from paid_count_event (see above), and it is not
    every lapse - a member bulk-lapsed on 1 June for never paying at all
    has no paid-in behind them and does not appear. fact_membership_
    events carries every Lapse event if the unfiltered number is wanted.

    Parameters:
      @FullRebuild         - 1 recomputes the WHOLE spine (from
                             2020-10-01) on the full-recompute path.
                             Changes are written as differences and
                             recorded as adjustments.
      @RebuildFrom         - full-recompute path from this date at the
                             latest. It can only move the start date
                             earlier. Ignored when @FullRebuild = 1.
      @DailyCountBatchDays - batch size, and the resume granularity
                             (default 31; minimum 1).
====================================================================*/
create or alter procedure Layercake.usp_load_silv_daily_count
    @run_id              uniqueidentifier = null,
    @FullRebuild         bit  = 0,
    @RebuildFrom         date = null,
    @DailyCountBatchDays int  = 31
as
begin
    set nocount on;
    set xact_abort on;

    if @run_id is null set @run_id = newid();
    -- null-safe: the batched walk is driven by a work list, so a null/zero
    -- batch size would select no dates and never make progress
    if isnull(@DailyCountBatchDays, 0) < 1 set @DailyCountBatchDays = 31;

    declare @log_id        bigint,
            @ins           int,
            @upd           int,
            @del           int,
            @adj           int,
            @rc            int,
            @pend          int,
            @note          nvarchar(256),
            @substep_ts    datetime2(3),
            @err           nvarchar(4000),
            @today         date = cast(getdate() as date),
            @spine_from    date = '20201001',
            -- a contact with no dated input row (a profile alone) can affect no date
            @no_date       date = '99991231',
            -- ADR-013: the basis row the MOD-028 migration writes until the
            -- stored history is restated at the segment grain
            @marker_name   varchar(64) = 'detail_grain_restatement',
            @restate       bit = 0,
            @rebuild_from  date = null,
            @start         date,
            @basis_to_now  date,
            @basis_to_end  date,
            @contacts_chg  int,
            @refs_chg      int,
            @snap_out      int,
            @full          bit = 0,
            @recomputed    int,
            @chg_from      date,
            @withdrawn     bit = 0,
            @mode          char(1),
            @guard_n       int,
            @guard_first   nvarchar(200),
            @guard_msg     nvarchar(2048),
            @win_from      date,
            @win_to        date,
            @marked        int,
            @todo_days     int,
            @todo_min      date,
            @todo_max      date;

    begin try
        exec Layercake.usp_etl_log_start @run_id, 'silver', 'silv_daily_count', @log_id output;
        set @substep_ts = sysdatetime();

        select @ins = 0, @upd = 0, @del = 0, @adj = 0;

        /* ---- a. deliberate rebuild request ----------------------------
           @FullRebuild / @RebuildFrom take the full-recompute path and
           only move the start date earlier. No loaded marker is cleared:
           the marks decide which changes are adjustments, and a rebuild
           records its changes like any run.
           ------------------------------------------------------------- */
        if @FullRebuild = 1
            set @rebuild_from = @spine_from;
        else if @RebuildFrom is not null
            set @rebuild_from = @RebuildFrom;

        if @rebuild_from < @spine_from
            set @rebuild_from = @spine_from;

        /* ---- b. the inputs, as they stand now --------------------------
           Staged once, side 'C'. The same staging later takes the changed
           contacts' snapshot as side 'O', so one derivation (step f)
           works out both their old and their new contribution. Only the
           rows and columns the derivation reads, so a change to segment
           or amount columns on events, or to audit columns, is not an
           input change. region stays nullable here: a bad range fails its
           batch, as it always has, not the whole run.
           ------------------------------------------------------------- */
        create table #rng
        (
            rn         int identity(1, 1) not null,
            side       char(1) not null,
            contact_no nvarchar(200) collate database_default not null,
            valid_from date not null,
            valid_to   date null,
            grade      varchar(12) collate database_default null,
            region     varchar(12) collate database_default null,
            w          int not null,        -- +1 current inputs, -1 as last applied
            pick_d     bit not null         -- read by the changed-contacts batches
        );

        insert into #rng (side, contact_no, valid_from, valid_to, grade, region, w, pick_d)
        select 'C', r.contact_no, r.valid_from, r.valid_to, r.grade, r.region, 1, 0
        from Layercake.silv_member_state_ranges r;

        create clustered index cx_rng on #rng (side, contact_no);

        create table #prof
        (
            side            char(1) not null,
            contact_no      nvarchar(200) collate database_default not null,
            country_id      int null,
            gender_id       int null,
            retirement_date date null,
            primary key clustered (side, contact_no)
        );

        insert into #prof (side, contact_no, country_id, gender_id, retirement_date)
        select 'C', pr.contact_no, pr.country_id, pr.gender_id, pr.retirement_date
        from Layercake.silv_member_profile pr;

        create table #pay
        (
            side             char(1) not null,
            contact_no       nvarchar(200) collate database_default not null,
            campaign_year    int not null,
            payment_date     date null,
            renewal_date_adj date null,
            primary key clustered (side, contact_no, campaign_year)
        );

        insert into #pay (side, contact_no, campaign_year, payment_date, renewal_date_adj)
        select 'C', p.contact_no, p.campaign_year, p.payment_date, p.renewal_date_adj
        from Layercake.silv_payment_events p;

        create table #evt
        (
            side          char(1) not null,
            contact_no    nvarchar(200) collate database_default not null,
            campaign_year int null,
            event_type    varchar(20) collate database_default not null,
            event_date    date null,
            event_id      int null
        );

        insert into #evt (side, contact_no, campaign_year, event_type, event_date, event_id)
        select 'C', e.contact_no, e.campaign_year, e.event_type, e.event_date, e.event_id
        from Layercake.silv_membership_events e
        where e.event_type in ('Join', 'Renewal', 'Readmission', 'Lapse');

        create clustered index cx_evt on #evt (side, contact_no, campaign_year);

        -- MOD-028: the segment ids a contact-day takes, one row per contact and
        -- Campaign Year as the source is keyed (the carried flags, the
        -- corporate account and the audit columns are not read)
        create table #attr
        (
            side               char(1) not null,
            contact_no         nvarchar(200) collate database_default not null,
            campaign_year      int not null,
            payment_method_id  int not null,
            payer_type_id      int not null,
            concession_type_id int not null,
            primary key clustered (side, contact_no, campaign_year)
        );

        insert into #attr (side, contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
        select 'C', a.contact_no, a.campaign_year, a.payment_method_id, a.payer_type_id, a.concession_type_id
        from Layercake.silv_member_year_attributes a;

        /* ---- the overlapping range guard (RULE-145, Q-055) -------------
           Before anything is written, on every path. Two non-zero-length
           ranges of one contact overlap when each starts before the other
           ends; ranges that meet, and zero-length ranges, never do.
           ------------------------------------------------------------- */
        select @guard_n     = count(distinct a.contact_no),
               @guard_first = min(a.contact_no)
        from #rng a
        inner join #rng b
            on  b.side       = a.side
            and b.contact_no = a.contact_no
            and b.rn         > a.rn
        where a.side = 'C'
          and (a.valid_to is null or a.valid_to > a.valid_from)
          and (b.valid_to is null or b.valid_to > b.valid_from)
          and a.valid_from < isnull(b.valid_to, @no_date)
          and b.valid_from < isnull(a.valid_to, @no_date);

        if @guard_n > 0
        begin
            set @guard_msg = concat(N'Overlapping state ranges: contact ', @guard_first,
                                    N' holds two overlapping non-zero-length ranges in Layercake.silv_member_state_ranges (',
                                    @guard_n, N' contact(s) affected). The daily count wrote nothing; correct the ranges and rerun.');
            throw 50026, @guard_msg, 1;
        end

        create table #in_row
        (
            contact_no nvarchar(200) collate database_default not null,
            row_text   nvarchar(400) collate database_default not null,
            row_date   date null            -- the earliest date the row refers to
        );

        insert into #in_row (contact_no, row_text, row_date)
        select e.contact_no,
               concat(N'E|', e.event_type,
                      N'|', isnull(convert(nchar(10), e.event_date, 23), N'~'),
                      N'|', isnull(convert(nvarchar(11), e.campaign_year), N'~')),
               case when y.cy_start < e.event_date or e.event_date is null then y.cy_start else e.event_date end
        from #evt e
        left join Layercake.ref_campaign_year_config cfg
            on  cfg.campaign_year = e.campaign_year
        cross apply (select isnull(cfg.campaign_year_start, datefromparts(e.campaign_year - 1, 10, 1)) as cy_start) y
        where e.side = 'C'
        union all
        select r.contact_no,
               concat(N'R|', isnull(convert(nchar(10), r.valid_from, 23), N'~'),
                      N'|', isnull(convert(nchar(10), r.valid_to, 23), N'~'),
                      N'|', isnull(r.grade, N'~'),
                      N'|', isnull(r.region, N'~')),
               r.valid_from
        from #rng r
        where r.side = 'C'
        union all
        -- payment_date is not read by the derivation, but it is one of the
        -- payment's dates, so it can only move the earliest date back
        select p.contact_no,
               concat(N'P|', isnull(convert(nvarchar(11), p.campaign_year), N'~'),
                      N'|', isnull(convert(nchar(10), p.renewal_date_adj, 23), N'~')),
               (select min(v.d)
                from (values (p.renewal_date_adj), (p.payment_date),
                             (isnull(cfg.campaign_year_start, datefromparts(p.campaign_year - 1, 10, 1)))) v(d))
        from #pay p
        left join Layercake.ref_campaign_year_config cfg
            on  cfg.campaign_year = p.campaign_year
        where p.side = 'C'
        union all
        select pr.contact_no,
               concat(N'F|', isnull(convert(nvarchar(11), pr.country_id), N'~'),
                      N'|', isnull(convert(nvarchar(11), pr.gender_id), N'~'),
                      N'|', isnull(convert(nchar(10), pr.retirement_date, 23), N'~')),
               null
        from #prof pr
        where pr.side = 'C'
        union all
        -- MOD-028 (RULE-160): the attributes rows, dated by the Campaign Year
        -- they refer to
        select a.contact_no,
               concat(N'A|', a.campaign_year, N'|', a.payment_method_id,
                      N'|', a.payer_type_id, N'|', a.concession_type_id),
               isnull(cfg.campaign_year_start, datefromparts(a.campaign_year - 1, 10, 1))
        from #attr a
        left join Layercake.ref_campaign_year_config cfg
            on  cfg.campaign_year = a.campaign_year
        where a.side = 'C';
        set @rc = @@rowcount;

        -- one fingerprint per contact; sorted bytewise so the hash is the
        -- same on every run whatever the collation makes of the row text
        create table #in_cur
        (
            contact_no             nvarchar(200) collate database_default not null primary key clustered,
            input_fingerprint      varbinary(32) not null,
            earliest_affected_date date not null
        );

        insert into #in_cur (contact_no, input_fingerprint, earliest_affected_date)
        select c.contact_no,
               c.input_fingerprint,
               -- the start of the Campaign Year of the earliest input row,
               -- never before 2020-10-01 (the ranges gate every figure, so a
               -- contact with no dated row can affect no date)
               case when c.first_date is null        then @no_date
                    when c.first_date < @spine_from then @spine_from
                    else isnull((select min(cfg.campaign_year_start)
                                 from Layercake.ref_campaign_year_config cfg
                                 where c.first_date between cfg.campaign_year_start and cfg.campaign_year_end),
                                datefromparts(year(c.first_date) - iif(month(c.first_date) < 10, 1, 0), 10, 1))
               end
        from (
            select x.contact_no,
                   cast(hashbytes('SHA2_256',
                        cast(string_agg(cast(x.row_text as nvarchar(max)), nchar(30))
                             within group (order by x.row_text collate Latin1_General_BIN2) as nvarchar(max)))
                        as varbinary(32)) as input_fingerprint,
                   min(x.row_date) as first_date
            from #in_row x
            group by x.contact_no
        ) c;

        -- the reference tables. The spine and the Campaign Year list are
        -- compared only up to the latest loaded date, so the daily extension
        -- of the spine is not a change. fp_now is compared with the basis;
        -- fp_end is what the basis will hold once this run has loaded every
        -- spine date up to today.
        select @basis_to_now = isnull(max(l.[date]), '00010101')
        from Layercake.etl_daily_count_loaded l;

        select @basis_to_end = max(x.d)
        from (select max(s.[date]) as d
              from Layercake.ref_date_spine s
              where s.[date] between @spine_from and @today
              union all
              select max(l.[date])
              from Layercake.etl_daily_count_loaded l
              where l.[date] <= @today) x;
        set @basis_to_end = isnull(@basis_to_end, '00010101');

        create table #ref_cur
        (
            input_name varchar(64) collate database_default not null primary key clustered,
            fp_now     varbinary(32) not null,
            fp_end     varbinary(32) not null
        );

        insert into #ref_cur (input_name, fp_now, fp_end)
        select v.input_name,
               cast(hashbytes('SHA2_256', isnull(cast(
                    string_agg(case when v.ref_date <= @basis_to_now then cast(v.row_text as nvarchar(max)) end, nchar(30))
                    within group (order by v.sort_key) as nvarchar(max)), N'')) as varbinary(32)),
               cast(hashbytes('SHA2_256', isnull(cast(
                    string_agg(case when v.ref_date <= @basis_to_end then cast(v.row_text as nvarchar(max)) end, nchar(30))
                    within group (order by v.sort_key) as nvarchar(max)), N'')) as varbinary(32))
        from (
            -- one sort key for both aggregates (they must share an ordering)
            select u.input_name, u.ref_date, u.row_text, u.row_text collate Latin1_General_BIN2 as sort_key
            from (
                select cast('ref_date_spine' as varchar(64)),
                       s.[date],
                       concat(convert(nchar(10), s.[date], 23), N'|', s.campaign_year, N'|', s.campaign_quarter)
                from Layercake.ref_date_spine s
                where s.[date] >= @spine_from
                union all
                select 'ref_campaign_year_config',
                       c.campaign_year_start,
                       concat(c.campaign_year, N'|', convert(nchar(10), c.campaign_year_start, 23),
                              N'|', convert(nchar(10), c.campaign_year_end, 23))
                from Layercake.ref_campaign_year_config c
                union all
                -- read in full: dated before any cutoff
                select 'silv_ref_membership_status',
                       cast('00010101' as date),
                       concat(ms.id, N'|', ms.status_name)
                from Layercake.silv_ref_membership_status ms
            ) u (input_name, ref_date, row_text)
        ) v
        group by v.input_name;

        set @note = concat(N'inputs fingerprinted: ', @rc, N' input row(s), ',
                           (select count(*) from #in_cur), N' contact(s)');
        exec Layercake.usp_etl_log_progress @log_id, @note, @rc, @substep_ts output;

        /* ---- c. changed inputs, the path and the start date ------------ */
        -- a contact whose inputs changed, appeared or disappeared, with the
        -- earlier of its old and new earliest affected dates
        create table #chg
        (
            contact_no    nvarchar(200) collate database_default not null primary key clustered,
            in_basis      bit not null,
            affected_from date not null
        );

        insert into #chg (contact_no, in_basis, affected_from)
        select isnull(c.contact_no, b.input_key),
               iif(b.input_key is null, 0, 1),
               case when b.input_key is null   then c.earliest_affected_date
                    when c.contact_no is null  then b.earliest_affected_date
                    when b.earliest_affected_date < c.earliest_affected_date then b.earliest_affected_date
                    else c.earliest_affected_date
               end
        from #in_cur c
        full join (select ib.input_key, ib.input_fingerprint, ib.earliest_affected_date
                   from Layercake.etl_daily_count_input_basis ib
                   where ib.input_name = 'contact') b
            on  b.input_key = c.contact_no
        where b.input_key is null
           or c.contact_no is null
           or b.input_fingerprint <> c.input_fingerprint;
        set @contacts_chg = @@rowcount;

        select @chg_from = min(ch.affected_from) from #chg ch;

        -- a changed reference table reaches every date (the restatement
        -- marker is not a reference table)
        select @refs_chg = count(*)
        from #ref_cur r
        full join (select ib.input_name, ib.input_fingerprint
                   from Layercake.etl_daily_count_input_basis ib
                   where ib.input_name <> 'contact'
                     and ib.input_name <> @marker_name) b
            on  b.input_name = r.input_name
        where b.input_name is null
           or r.input_name is null
           or b.input_fingerprint <> r.fp_now;

        -- ADR-013: stored history not yet restated at the segment grain
        if exists (select 1 from Layercake.etl_daily_count_input_basis ib where ib.input_name = @marker_name)
            set @restate = 1;

        -- the snapshot is in step with the basis when both hold the same
        -- contacts; otherwise the stored figures may not be what the
        -- snapshot describes, and only a full recompute is safe
        create table #snap_out (contact_no nvarchar(200) collate database_default not null primary key clustered);

        insert into #snap_out (contact_no)
        select b.input_key
        from Layercake.etl_daily_count_input_basis b
        where b.input_name = 'contact'
          and not exists (select 1 from Layercake.etl_daily_count_applied_contact h where h.contact_no = b.input_key)
        union
        select h.contact_no
        from Layercake.etl_daily_count_applied_contact h
        where not exists (select 1 from Layercake.etl_daily_count_input_basis b
                          where b.input_name = 'contact'
                            and b.input_key  = h.contact_no);
        set @snap_out = @@rowcount;

        if @rebuild_from is not null or @refs_chg > 0 or @snap_out > 0 or @restate = 1
            set @full = 1;

        select @start = min(x.d)
        from (select @chg_from as d
              union all
              select @spine_from where @refs_chg > 0 or @snap_out > 0 or @restate = 1
              union all
              -- the first date not yet loaded (a new day, or a gap left behind)
              select min(s.[date])
              from Layercake.ref_date_spine s
              where s.[date] between @spine_from and @today
                and not exists (select 1 from Layercake.etl_daily_count_loaded l
                                where l.[date] = s.[date])
              union all
              select @today
              union all
              select @rebuild_from) x;

        if @start < @spine_from
            set @start = @spine_from;

        set @note = concat(N'changed inputs: ', @contacts_chg, N' contact(s), ', @refs_chg, N' reference table(s), ',
                           @snap_out, N' contact(s) out of step with the snapshot',
                           iif(@restate = 1, N'; restating at the segment grain', N''),
                           iif(@rebuild_from is not null,
                               concat(N'; rebuild requested from ', convert(nvarchar(10), @rebuild_from, 23)), N''));
        exec Layercake.usp_etl_log_progress @log_id, @note, @contacts_chg, @substep_ts output;

        -- RULE-153: on the full path every contact with inputs, current or as
        -- last applied, is recomputed
        if @full = 1
            select @recomputed = count(*)
            from (select c.contact_no from #in_cur c
                  union
                  select b.input_key from Layercake.etl_daily_count_input_basis b where b.input_name = 'contact'
                  union
                  select h.contact_no from Layercake.etl_daily_count_applied_contact h) x;
        else
            set @recomputed = @contacts_chg;

        exec Layercake.usp_etl_log_progress @log_id, N'contacts_recomputed', @recomputed, @substep_ts output;
        set @rc = cast(@full as int);
        exec Layercake.usp_etl_log_progress @log_id, N'full_recompute_path', @rc, @substep_ts output;

        /* ---- d. the work list ------------------------------------------
           mode 'F': derived from all contacts and written as differences
           (every date of the full path, and first loads on the normal
           path); mode 'D': a loaded date the changed contacts can reach.
           ------------------------------------------------------------- */
        create table #dc_todo ([date] date not null primary key clustered, mode char(1) not null);

        if @full = 1
            insert into #dc_todo ([date], mode)
            select s.[date], 'F'
            from Layercake.ref_date_spine s
            where s.[date] >= @start
              and s.[date] <= @today;
        else
            insert into #dc_todo ([date], mode)
            select s.[date], iif(l.[date] is null, 'F', 'D')
            from Layercake.ref_date_spine s
            left join Layercake.etl_daily_count_loaded l
                on  l.[date] = s.[date]
            where s.[date] between @spine_from and @today
              and (l.[date] is null or s.[date] >= @chg_from);
        set @todo_days = @@rowcount;

        select @todo_min = min([date]), @todo_max = max([date]) from #dc_todo;

        set @note = concat(iif(@full = 1, concat(N'full recompute from ', convert(nvarchar(10), @start, 23)),
                               N'changed contacts'),
                           N': ', @todo_days, N' date(s)',
                           iif(@todo_days > 0,
                               concat(N' ', convert(nvarchar(10), @todo_min, 23), N' -> ',
                                      convert(nvarchar(10), @todo_max, 23),
                                      N' in ', @DailyCountBatchDays, N'-day batches'), N''));
        exec Layercake.usp_etl_log_progress @log_id, @note, @todo_days, @substep_ts output;

        -- housekeeping: the spine runs two years ahead, so make sure nothing
        -- beyond today survives from an earlier run (and no marker with it).
        -- A removed row of a loaded date is an adjustment like any other
        -- (at the old grain, with -2, while restating).
        begin tran;
        insert into Layercake.silv_daily_count_adjustment
        (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
         payment_method_id, payer_type_id, concession_type_id,
         active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
         event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
        select @run_id, @log_id, sysdatetime(), d.[date], d.region, d.country_id, d.gender_id, d.grade, d.membership_status_id,
               iif(@restate = 1, -2, d.payment_method_id), iif(@restate = 1, -2, d.payer_type_id),
               iif(@restate = 1, -2, d.concession_type_id),
               -sum(d.active_count), -sum(d.paid_count), -sum(d.paid_count_event), -sum(d.event_join_count),
               -sum(d.event_renewal_count), -sum(d.event_readmission_count), -sum(d.event_lapse_count)
        from Layercake.silv_daily_count_detail d
        where d.[date] > @today
          and exists (select 1 from Layercake.etl_daily_count_loaded l where l.[date] = d.[date])
        group by d.[date], d.region, d.country_id, d.gender_id, d.grade, d.membership_status_id,
                 iif(@restate = 1, -2, d.payment_method_id), iif(@restate = 1, -2, d.payer_type_id),
                 iif(@restate = 1, -2, d.concession_type_id)
        having sum(d.active_count) <> 0 or sum(d.paid_count) <> 0 or sum(d.paid_count_event) <> 0
            or sum(d.event_join_count) <> 0 or sum(d.event_renewal_count) <> 0
            or sum(d.event_readmission_count) <> 0 or sum(d.event_lapse_count) <> 0;
        set @adj = @adj + @@rowcount;
        delete from Layercake.silv_daily_count_detail where [date] > @today;
        set @del = @del + @@rowcount;
        delete from Layercake.silv_daily_count        where [date] > @today;
        set @del = @del + @@rowcount;
        delete from Layercake.etl_daily_count_cell_contacts where [date] > @today;
        delete from Layercake.etl_daily_count_loaded  where [date] > @today;
        commit;

        -- the changed contacts' inputs as last applied, side 'O' (normal
        -- path only: the full path derives from the current inputs alone)
        if @full = 0 and @contacts_chg > 0
        begin
            update r
            set pick_d = 1
            from #rng r
            inner join #chg k
                on  k.contact_no = r.contact_no
            where r.side = 'C';

            insert into #rng (side, contact_no, valid_from, valid_to, grade, region, w, pick_d)
            select 'O', a.contact_no, a.valid_from, a.valid_to, a.grade, a.region, -1, 1
            from Layercake.etl_daily_count_applied_state_range a
            inner join #chg k
                on  k.contact_no = a.contact_no;

            insert into #prof (side, contact_no, country_id, gender_id, retirement_date)
            select 'O', h.contact_no, h.country_id, h.gender_id, h.retirement_date
            from Layercake.etl_daily_count_applied_contact h
            inner join #chg k
                on  k.contact_no = h.contact_no
            where h.profile_found = 1;

            insert into #pay (side, contact_no, campaign_year, payment_date, renewal_date_adj)
            select 'O', a.contact_no, a.campaign_year, null, a.renewal_date_adj
            from Layercake.etl_daily_count_applied_payment a
            inner join #chg k
                on  k.contact_no = a.contact_no;

            insert into #evt (side, contact_no, campaign_year, event_type, event_date, event_id)
            select 'O', a.contact_no, a.campaign_year, a.event_type, a.event_date, null
            from Layercake.etl_daily_count_applied_event a
            inner join #chg k
                on  k.contact_no = a.contact_no;

            insert into #attr (side, contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
            select 'O', a.contact_no, a.campaign_year, a.payment_method_id, a.payer_type_id, a.concession_type_id
            from Layercake.etl_daily_count_applied_attribute a
            inner join #chg k
                on  k.contact_no = a.contact_no;
        end

        /* ---- e. event-driven paid: per-contact staging -----------------
           Built ONCE for the whole run, for both sides, and read by every
           batch. Two work tables: #ev_paid is the STOCK (one row per
           contact per campaign year: the date they became paid, plus the
           date they later lapsed if they did), and #ev_day is those same
           two dates re-shaped as the daily FLOW. See the module header for
           the rule they implement - note in particular that the lapse date
           is carried for REPORTING only and never deducts from the stock.
           ------------------------------------------------------------- */

        -- e1. the paid-in event: the earliest Join / Renewal / Readmission
        -- in the campaign year. Ties on the same date break
        -- Join -> Readmission -> Renewal so the winner is deterministic
        -- across runs; in practice module 9 already makes the three
        -- mutually exclusive per contact per year. A tie of one type on
        -- one date gives the same row whichever wins, which is why the
        -- snapshot can leave event_id out.
        select v.side,
               v.contact_no,
               v.campaign_year,
               v.event_type,
               -- clamped to the campaign year start: a Renewal event falls
               -- back to the cash transaction date when renewal_date_adj is
               -- null, and that date can sit outside the year the subs
               -- position assigns it to. Clamping lands the FLOW on 1 October
               -- rather than in the previous campaign year; it cannot change
               -- the stock, which already counts such a contact from day one.
               iif(v.event_date < cfg.campaign_year_start, cfg.campaign_year_start, v.event_date) as paid_in_date
        into #ev_paid_in
        from (
            select e.side,
                   e.contact_no,
                   e.campaign_year,
                   e.event_type,
                   e.event_date,
                   row_number() over (partition by e.side, e.contact_no, e.campaign_year
                                      order by e.event_date,
                                               case e.event_type
                                                   when 'Join'        then 1
                                                   when 'Readmission' then 2
                                                   else 3                       -- Renewal
                                               end,
                                               e.event_id) as rn
            from #evt e
            where e.event_type in ('Join', 'Renewal', 'Readmission')
        ) v
        -- left joined: campaign years before the spine (CY2021) have no config
        -- row, and both tests below are written to pass when it is missing
        left join Layercake.ref_campaign_year_config cfg
            on  cfg.campaign_year = v.campaign_year
        where v.rn = 1
          -- an event dated after the campaign year ended cannot be that year's
          -- paid-in. Dropped from stock AND flow together, so the two still
          -- reconcile.
          and (cfg.campaign_year_end is null or v.event_date <= cfg.campaign_year_end);
        set @rc = @@rowcount;

        create unique clustered index cx_ev_paid_in on #ev_paid_in (side, contact_no, campaign_year);
        exec Layercake.usp_etl_log_progress @log_id, N'stage #ev_paid_in (event-driven paid: paid-in events)', @rc, @substep_ts output;

        -- e2. the lapse that follows it. Feeds event_lapse_count only - it does
        -- not end the paid count. Module 9 keys Lapse events 'LA:' + contact_no,
        -- so there is at most one per contact - aggregated anyway so the join
        -- below stays 1:1 whatever the source does.
        select e.side,
               e.contact_no,
               e.campaign_year,
               min(e.event_date) as lapse_date
        into #ev_lapse
        from #evt e
        where e.event_type = 'Lapse'
        group by e.side, e.contact_no, e.campaign_year;
        set @rc = @@rowcount;

        create unique clustered index cx_ev_lapse on #ev_lapse (side, contact_no, campaign_year);
        exec Layercake.usp_etl_log_progress @log_id, N'stage #ev_lapse (event-driven paid: lapse events)', @rc, @substep_ts output;

        -- e3. the STOCK table the day-by-day count reads.
        select i.side,
               i.contact_no,
               i.campaign_year,
               i.event_type,
               i.paid_in_date,
               -- REPORTED, NOT DEDUCTED (see the module header): a lapse in the
               -- same campaign year dated on or after the paid-in event. The
               -- ordering test is what makes this "paid, then lapsed" rather
               -- than any lapse at all - a member bulk-lapsed for never paying
               -- has no paid-in behind them and nulls out here. A CASE, not a
               -- join predicate: the contact row has to survive either way.
               case when l.lapse_date >= i.paid_in_date then l.lapse_date end as lapse_date
        into #ev_paid
        from #ev_paid_in i
        left join #ev_lapse l
            on  l.side          = i.side
            and l.contact_no    = i.contact_no
            and l.campaign_year = i.campaign_year;

        create unique clustered index cx_ev_paid on #ev_paid (side, contact_no, campaign_year);

        -- e4. the FLOW table: those same two dates as one row per contact per
        -- day. Derived from #ev_paid rather than re-read from the events, so
        -- the components can only ever describe the stock above. A contact who
        -- paid in and lapsed on the same day collapses into a single row
        -- carrying both flags - paid-in and lapse are reported independently,
        -- so neither cancels the other.
        select f.side,
               f.contact_no,
               f.event_date,
               max(f.join_flag)        as join_flag,
               max(f.renewal_flag)     as renewal_flag,
               max(f.readmission_flag) as readmission_flag,
               max(f.lapse_flag)       as lapse_flag
        into #ev_day
        from (
            select p.side,
                   p.contact_no,
                   p.paid_in_date as event_date,
                   iif(p.event_type = 'Join', 1, 0)        as join_flag,
                   iif(p.event_type = 'Renewal', 1, 0)     as renewal_flag,
                   iif(p.event_type = 'Readmission', 1, 0) as readmission_flag,
                   0                                       as lapse_flag
            from #ev_paid p
            union all
            select p.side, p.contact_no, p.lapse_date, 0, 0, 0, 1
            from #ev_paid p
            where p.lapse_date is not null
        ) f
        group by f.side, f.contact_no, f.event_date;
        set @rc = @@rowcount;

        create unique clustered index cx_ev_day on #ev_day (side, contact_no, event_date);
        exec Layercake.usp_etl_log_progress @log_id, N'stage #ev_paid + #ev_day (event-driven paid: stock and daily flow)', @rc, @substep_ts output;

        /* ---- f. the batched walk -------------------------------------- */
        create table #dc_chunk ([date] date not null primary key clustered);

        -- a batch's cells as derived now (mode F), or the changed contacts'
        -- new minus old contributions (mode D), in the target tables' shape
        create table #dc_new
        (
            [date]                  date not null,
            campaign_year           int not null,
            campaign_quarter        char(2) collate database_default not null,
            region                  varchar(12) collate database_default not null,
            country_id              int not null,
            gender_id               int not null,
            grade                   varchar(12) collate database_default not null,
            membership_status_id    int not null,
            payment_method_id       int not null,
            payer_type_id           int not null,
            concession_type_id      int not null,
            active_count            int not null,
            paid_count              int not null,
            paid_count_event        int not null,
            event_join_count        int not null,
            event_renewal_count     int not null,
            event_readmission_count int not null,
            event_lapse_count       int not null,
            contact_count           int not null,
            primary key clustered ([date], region, country_id, gender_id, grade, membership_status_id,
                                   payment_method_id, payer_type_id, concession_type_id)
        );

        create table #dc_new_main
        (
            [date]                  date not null,
            campaign_year           int not null,
            campaign_quarter        char(2) collate database_default not null,
            region                  varchar(12) collate database_default not null,
            grade                   varchar(12) collate database_default not null,
            active_count            int not null,
            paid_count              int not null,
            paid_count_event        int not null,
            event_join_count        int not null,
            event_renewal_count     int not null,
            event_readmission_count int not null,
            event_lapse_count       int not null,
            primary key clustered ([date], region, grade)
        );

        -- mode D: each touched cell, stored before and after the change
        create table #dc_apply
        (
            [date]               date not null,
            campaign_year        int not null,
            campaign_quarter     char(2) collate database_default not null,
            region               varchar(12) collate database_default not null,
            country_id           int not null,
            gender_id            int not null,
            grade                varchar(12) collate database_default not null,
            membership_status_id int not null,
            payment_method_id    int not null,
            payer_type_id        int not null,
            concession_type_id   int not null,
            detail_found         bit not null,
            count_found          bit not null,
            contact_count        int not null,
            old_active           int not null,
            old_paid             int not null,
            old_paid_event       int not null,
            old_join             int not null,
            old_renewal          int not null,
            old_readmission      int not null,
            old_lapse            int not null,
            new_active           int not null,
            new_paid             int not null,
            new_paid_event       int not null,
            new_join             int not null,
            new_renewal          int not null,
            new_readmission      int not null,
            new_lapse            int not null,
            primary key clustered ([date], region, country_id, gender_id, grade, membership_status_id,
                                   payment_method_id, payer_type_id, concession_type_id)
        );

        create table #dc_touch
        (
            [date] date not null,
            region varchar(12) collate database_default not null,
            grade  varchar(12) collate database_default not null,
            primary key clustered ([date], region, grade)
        );

        while exists (select 1 from #dc_todo)
        begin
            delete from #dc_chunk;

            -- one mode per batch, dates in order
            select top (1) @mode = t.mode from #dc_todo t order by t.[date];

            insert into #dc_chunk ([date])
            select top (@DailyCountBatchDays) t.[date]
            from #dc_todo t
            where t.mode = @mode
            order by t.[date];

            -- forward-progress guard: a batch that picked up nothing would
            -- delete nothing from #dc_todo and spin forever
            if @@rowcount = 0 break;

            select @win_from = min([date]), @win_to = max([date]) from #dc_chunk;

            -- ---- derive the batch (the Phase 1 derivation, unchanged) ----
            -- the batch's dates drive one row per day per populated cell,
            -- joining the state ranges active on that day (set-based - no
            -- cursor). Profile left-joined: every ranged contact has a
            -- profile row (both derive from silv_member_base), the isnulls
            -- are belt and braces for a mid-deploy state. Each measure is the
            -- sum of the contacts' 0-or-1 contributions, weighted -1 for a
            -- changed contact's inputs as last applied (mode D). The segment
            -- ids come from the attributes row of the day's Campaign Year,
            -- 0 Unknown where there is none (MOD-028, RULE-156).
            truncate table #dc_new;

            insert into #dc_new
            ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
             payment_method_id, payer_type_id, concession_type_id,
             active_count, paid_count, paid_count_event,
             event_join_count, event_renewal_count, event_readmission_count, event_lapse_count, contact_count)
            select
                s.[date],
                s.campaign_year,
                s.campaign_quarter,
                r.region,
                isnull(pr.country_id, 0)          as country_id,
                isnull(pr.gender_id, 0)           as gender_id,
                r.grade,
                isnull(ms.id, 0)                  as membership_status_id,
                isnull(ya.payment_method_id, 0)  as payment_method_id,
                isnull(ya.payer_type_id, 0)      as payer_type_id,
                isnull(ya.concession_type_id, 0) as concession_type_id,
                -- v2 parity: lapsed members NEVER count as active - the lapse
                -- rows remain (carrying paid counts) but contribute 0 to
                -- the active count from the lapse date onward
                sum(r.w * iif(r.grade = 'lapse', 0, 1)) as active_count,
                -- PAYMENT-driven paid: a payment event exists for the campaign
                -- year with an adjusted renewal date on or before this date (the
                -- adjusted date is always inside the campaign year, which is
                -- what makes day-by-day processing valid)
                sum(r.w * iif(p.renewal_date_adj <= s.[date], 1, 0)) as paid_count,
                -- EVENT-driven paid (STOCK): paid from the campaign year's
                -- paid-in event, and counted for the rest of that year. A later
                -- lapse does NOT take it back off - the lapse date staged in
                -- step e reaches event_lapse_count below and nothing else. See
                -- the module header.
                sum(r.w * iif(ep.paid_in_date <= s.[date], 1, 0)) as paid_count_event,
                -- ...and the daily FLOWS it is built from, one per contact per
                -- day (#ev_day is unique on contact and date)
                sum(r.w * isnull(ed.join_flag, 0))        as event_join_count,
                sum(r.w * isnull(ed.renewal_flag, 0))     as event_renewal_count,
                sum(r.w * isnull(ed.readmission_flag, 0)) as event_readmission_count,
                -- reported, but deliberately NOT part of the stock above
                sum(r.w * isnull(ed.lapse_flag, 0))       as event_lapse_count,
                sum(r.w)                                  as contact_count
            from #dc_chunk c
            inner join Layercake.ref_date_spine s
                on  s.[date] = c.[date]
            inner join #rng r
                -- LATEST-STATE-PER-DAY rule: half-open interval
                -- [valid_from, valid_to). Open-ended ranges (valid_to null,
                -- i.e. currently-active members) count through today.
                -- Zero-length ranges (same-day transitions, ordered by
                -- state_seq) match no date at all.
                on  s.[date] >= r.valid_from
                and s.[date] <  isnull(r.valid_to, dateadd(day, 1, @today))
            left join #prof pr
                on  pr.side       = r.side
                and pr.contact_no = r.contact_no
            -- day-level status: Qualified members are Retired from the
            -- retirement date onward, else Practising (null retirement ->
            -- Practising via the IIF); Candidate/Lapsed rows are N/A (id 0)
            left join Layercake.silv_ref_membership_status ms
                on  ms.status_name = case when r.grade = 'election'
                                          then iif(pr.retirement_date <= s.[date], 'Retired', 'Practising')
                                          else 'N/A' end
            left join #pay p
                on  p.side          = r.side
                and p.contact_no    = r.contact_no
                and p.campaign_year = s.campaign_year
            -- event-driven paid, both halves keyed 1:1 against the range row
            -- (step e indexes them uniquely), so neither can fan the join out
            left join #ev_paid ep
                on  ep.side          = r.side
                and ep.contact_no    = r.contact_no
                and ep.campaign_year = s.campaign_year
            left join #ev_day ed
                on  ed.side       = r.side
                and ed.contact_no = r.contact_no
                and ed.event_date = s.[date]
            -- the day's segment cell: keyed 1:1 on contact and Campaign Year
            left join #attr ya
                on  ya.side          = r.side
                and ya.contact_no    = r.contact_no
                and ya.campaign_year = s.campaign_year
            where (@mode = 'F' and r.side = 'C')
               or (@mode = 'D' and r.pick_d = 1)
            group by
                s.[date], s.campaign_year, s.campaign_quarter,
                r.region, isnull(pr.country_id, 0), isnull(pr.gender_id, 0),
                r.grade, isnull(ms.id, 0),
                isnull(ya.payment_method_id, 0), isnull(ya.payer_type_id, 0), isnull(ya.concession_type_id, 0)
            -- mode D keeps only the cells the changed contacts change
            having @mode = 'F'
                or sum(r.w) <> 0
                or sum(r.w * iif(r.grade = 'lapse', 0, 1)) <> 0
                or sum(r.w * iif(p.renewal_date_adj <= s.[date], 1, 0)) <> 0
                or sum(r.w * iif(ep.paid_in_date <= s.[date], 1, 0)) <> 0
                or sum(r.w * isnull(ed.join_flag, 0)) <> 0
                or sum(r.w * isnull(ed.renewal_flag, 0)) <> 0
                or sum(r.w * isnull(ed.readmission_flag, 0)) <> 0
                or sum(r.w * isnull(ed.lapse_flag, 0)) <> 0
            option (recompile);
            set @rc = @@rowcount;

            begin tran;

            -- ---- the first batch transaction withdraws the snapshot ------
            -- of the contacts this run applies: from now until the final
            -- transaction the snapshot is out of step with the basis, so a
            -- run that does not finish sends the next one down the full path.
            -- A contact that appeared has nothing to withdraw; a header of its
            -- own, with no basis row yet, puts the snapshot out of step the
            -- same way.
            if @withdrawn = 0
            begin
                delete a
                from Layercake.etl_daily_count_applied_state_range a
                inner join #chg k on k.contact_no = a.contact_no;

                delete a
                from Layercake.etl_daily_count_applied_payment a
                inner join #chg k on k.contact_no = a.contact_no;

                delete a
                from Layercake.etl_daily_count_applied_event a
                inner join #chg k on k.contact_no = a.contact_no;

                delete a
                from Layercake.etl_daily_count_applied_attribute a
                inner join #chg k on k.contact_no = a.contact_no;

                delete h
                from Layercake.etl_daily_count_applied_contact h
                inner join #chg k on k.contact_no = h.contact_no;

                insert into Layercake.etl_daily_count_applied_contact
                (contact_no, profile_found, country_id, gender_id, retirement_date, run_id, updated_at)
                select k.contact_no, iif(pr.contact_no is null, 0, 1), pr.country_id, pr.gender_id, pr.retirement_date,
                       @run_id, sysdatetime()
                from #chg k
                left join #prof pr
                    on  pr.side       = 'C'
                    and pr.contact_no = k.contact_no
                where k.in_basis = 0;
            end

            if @mode = 'F'
            begin
                -- main: plain aggregate of the batch's detail (additive: one
                -- detail cell per contact per day - see header)
                truncate table #dc_new_main;

                insert into #dc_new_main
                ([date], campaign_year, campaign_quarter, region, grade,
                 active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
                select
                    n.[date], n.campaign_year, n.campaign_quarter, n.region, n.grade,
                    sum(n.active_count), sum(n.paid_count), sum(n.paid_count_event),
                    sum(n.event_join_count), sum(n.event_renewal_count),
                    sum(n.event_readmission_count), sum(n.event_lapse_count)
                from #dc_new n
                group by n.[date], n.campaign_year, n.campaign_quarter, n.region, n.grade;

                -- ---- adjustment history (REQ-019) -----------------------
                -- one row per detail cell whose figures change on a date
                -- already marked loaded; a missing cell counts as 0 on its
                -- side. While restating (ADR-013, Q-061) both sides are summed
                -- over the three segment ids and the row carries -2 in them,
                -- so the change of grain alone records nothing.
                insert into Layercake.silv_daily_count_adjustment
                (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
                 payment_method_id, payer_type_id, concession_type_id,
                 active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
                 event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
                select @run_id, @log_id, sysdatetime(),
                       x.[date], x.region, x.country_id, x.gender_id, x.grade, x.membership_status_id,
                       x.payment_method_id, x.payer_type_id, x.concession_type_id,
                       x.active_change, x.paid_change, x.paid_event_change, x.join_change,
                       x.renewal_change, x.readmission_change, x.lapse_change
                from (
                    select isnull(n.[date], o.[date])                             as [date],
                           isnull(n.region, o.region)                             as region,
                           isnull(n.country_id, o.country_id)                     as country_id,
                           isnull(n.gender_id, o.gender_id)                       as gender_id,
                           isnull(n.grade, o.grade)                               as grade,
                           isnull(n.membership_status_id, o.membership_status_id) as membership_status_id,
                           isnull(n.payment_method_id, o.payment_method_id)       as payment_method_id,
                           isnull(n.payer_type_id, o.payer_type_id)               as payer_type_id,
                           isnull(n.concession_type_id, o.concession_type_id)     as concession_type_id,
                           isnull(n.active_count, 0)            - isnull(o.active_count, 0)            as active_change,
                           isnull(n.paid_count, 0)              - isnull(o.paid_count, 0)              as paid_change,
                           isnull(n.paid_count_event, 0)        - isnull(o.paid_count_event, 0)        as paid_event_change,
                           isnull(n.event_join_count, 0)        - isnull(o.event_join_count, 0)        as join_change,
                           isnull(n.event_renewal_count, 0)     - isnull(o.event_renewal_count, 0)     as renewal_change,
                           isnull(n.event_readmission_count, 0) - isnull(o.event_readmission_count, 0) as readmission_change,
                           isnull(n.event_lapse_count, 0)       - isnull(o.event_lapse_count, 0)       as lapse_change
                    from (select b.[date], b.region, b.country_id, b.gender_id, b.grade, b.membership_status_id,
                                 iif(@restate = 1, -2, b.payment_method_id)  as payment_method_id,
                                 iif(@restate = 1, -2, b.payer_type_id)      as payer_type_id,
                                 iif(@restate = 1, -2, b.concession_type_id) as concession_type_id,
                                 sum(b.active_count) as active_count, sum(b.paid_count) as paid_count,
                                 sum(b.paid_count_event) as paid_count_event, sum(b.event_join_count) as event_join_count,
                                 sum(b.event_renewal_count) as event_renewal_count,
                                 sum(b.event_readmission_count) as event_readmission_count,
                                 sum(b.event_lapse_count) as event_lapse_count
                          from #dc_new b
                          group by b.[date], b.region, b.country_id, b.gender_id, b.grade, b.membership_status_id,
                                   iif(@restate = 1, -2, b.payment_method_id), iif(@restate = 1, -2, b.payer_type_id),
                                   iif(@restate = 1, -2, b.concession_type_id)) n
                    full join (select d.[date], d.region, d.country_id, d.gender_id, d.grade, d.membership_status_id,
                                      iif(@restate = 1, -2, d.payment_method_id)  as payment_method_id,
                                      iif(@restate = 1, -2, d.payer_type_id)      as payer_type_id,
                                      iif(@restate = 1, -2, d.concession_type_id) as concession_type_id,
                                      sum(d.active_count) as active_count, sum(d.paid_count) as paid_count,
                                      sum(d.paid_count_event) as paid_count_event, sum(d.event_join_count) as event_join_count,
                                      sum(d.event_renewal_count) as event_renewal_count,
                                      sum(d.event_readmission_count) as event_readmission_count,
                                      sum(d.event_lapse_count) as event_lapse_count
                               from Layercake.silv_daily_count_detail d
                               inner join #dc_chunk c on c.[date] = d.[date]
                               group by d.[date], d.region, d.country_id, d.gender_id, d.grade, d.membership_status_id,
                                        iif(@restate = 1, -2, d.payment_method_id), iif(@restate = 1, -2, d.payer_type_id),
                                        iif(@restate = 1, -2, d.concession_type_id)) o
                        on  o.[date]               = n.[date]
                        and o.region               = n.region
                        and o.country_id           = n.country_id
                        and o.gender_id            = n.gender_id
                        and o.grade                = n.grade
                        and o.membership_status_id = n.membership_status_id
                        and o.payment_method_id    = n.payment_method_id
                        and o.payer_type_id        = n.payer_type_id
                        and o.concession_type_id   = n.concession_type_id
                ) x
                where exists (select 1 from Layercake.etl_daily_count_loaded l where l.[date] = x.[date])
                  and (x.active_change <> 0 or x.paid_change <> 0 or x.paid_event_change <> 0 or x.join_change <> 0
                       or x.renewal_change <> 0 or x.readmission_change <> 0 or x.lapse_change <> 0);
                set @adj = @adj + @@rowcount;

                -- ---- detail: differences only ---------------------------
                -- restricted to the batch's OWN dates (not the from/to range)
                delete d
                from Layercake.silv_daily_count_detail d
                inner join #dc_chunk c
                    on  c.[date] = d.[date]
                where not exists (select 1 from #dc_new n
                                  where n.[date]               = d.[date]
                                    and n.region               = d.region
                                    and n.country_id           = d.country_id
                                    and n.gender_id            = d.gender_id
                                    and n.grade                = d.grade
                                    and n.membership_status_id = d.membership_status_id
                                    and n.payment_method_id    = d.payment_method_id
                                    and n.payer_type_id        = d.payer_type_id
                                    and n.concession_type_id   = d.concession_type_id);
                set @del = @del + @@rowcount;

                update d
                set campaign_year           = n.campaign_year,
                    campaign_quarter        = n.campaign_quarter,
                    active_count            = n.active_count,
                    paid_count              = n.paid_count,
                    paid_count_event        = n.paid_count_event,
                    event_join_count        = n.event_join_count,
                    event_renewal_count     = n.event_renewal_count,
                    event_readmission_count = n.event_readmission_count,
                    event_lapse_count       = n.event_lapse_count
                from Layercake.silv_daily_count_detail d
                inner join #dc_new n
                    on  n.[date]               = d.[date]
                    and n.region               = d.region
                    and n.country_id           = d.country_id
                    and n.gender_id            = d.gender_id
                    and n.grade                = d.grade
                    and n.membership_status_id = d.membership_status_id
                    and n.payment_method_id    = d.payment_method_id
                    and n.payer_type_id        = d.payer_type_id
                    and n.concession_type_id   = d.concession_type_id
                where d.campaign_year           <> n.campaign_year
                   or d.campaign_quarter        <> n.campaign_quarter
                   or d.active_count            <> n.active_count
                   or d.paid_count              <> n.paid_count
                   or d.paid_count_event        <> n.paid_count_event
                   or d.event_join_count        <> n.event_join_count
                   or d.event_renewal_count     <> n.event_renewal_count
                   or d.event_readmission_count <> n.event_readmission_count
                   or d.event_lapse_count       <> n.event_lapse_count;
                set @upd = @upd + @@rowcount;

                insert into Layercake.silv_daily_count_detail
                ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
                 payment_method_id, payer_type_id, concession_type_id,
                 active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
                select n.[date], n.campaign_year, n.campaign_quarter, n.region, n.country_id, n.gender_id, n.grade,
                       n.membership_status_id, n.payment_method_id, n.payer_type_id, n.concession_type_id,
                       n.active_count, n.paid_count, n.paid_count_event,
                       n.event_join_count, n.event_renewal_count, n.event_readmission_count, n.event_lapse_count
                from #dc_new n
                where not exists (select 1 from Layercake.silv_daily_count_detail d
                                  where d.[date]               = n.[date]
                                    and d.region               = n.region
                                    and d.country_id           = n.country_id
                                    and d.gender_id            = n.gender_id
                                    and d.grade                = n.grade
                                    and d.membership_status_id = n.membership_status_id
                                    and d.payment_method_id    = n.payment_method_id
                                    and d.payer_type_id        = n.payer_type_id
                                    and d.concession_type_id   = n.concession_type_id);
                set @ins = @ins + @@rowcount;

                -- ---- cell contact counts: differences only --------------
                delete cc
                from Layercake.etl_daily_count_cell_contacts cc
                inner join #dc_chunk c
                    on  c.[date] = cc.[date]
                where not exists (select 1 from #dc_new n
                                  where n.[date]               = cc.[date]
                                    and n.region               = cc.region
                                    and n.country_id           = cc.country_id
                                    and n.gender_id            = cc.gender_id
                                    and n.grade                = cc.grade
                                    and n.membership_status_id = cc.membership_status_id
                                    and n.payment_method_id    = cc.payment_method_id
                                    and n.payer_type_id        = cc.payer_type_id
                                    and n.concession_type_id   = cc.concession_type_id);

                update cc
                set contact_count = n.contact_count,
                    run_id        = @run_id,
                    updated_at    = sysdatetime()
                from Layercake.etl_daily_count_cell_contacts cc
                inner join #dc_new n
                    on  n.[date]               = cc.[date]
                    and n.region               = cc.region
                    and n.country_id           = cc.country_id
                    and n.gender_id            = cc.gender_id
                    and n.grade                = cc.grade
                    and n.membership_status_id = cc.membership_status_id
                    and n.payment_method_id    = cc.payment_method_id
                    and n.payer_type_id        = cc.payer_type_id
                    and n.concession_type_id   = cc.concession_type_id
                where cc.contact_count <> n.contact_count;

                insert into Layercake.etl_daily_count_cell_contacts
                ([date], region, country_id, gender_id, grade, membership_status_id,
                 payment_method_id, payer_type_id, concession_type_id, contact_count, run_id, updated_at)
                select n.[date], n.region, n.country_id, n.gender_id, n.grade, n.membership_status_id,
                       n.payment_method_id, n.payer_type_id, n.concession_type_id,
                       n.contact_count, @run_id, sysdatetime()
                from #dc_new n
                where not exists (select 1 from Layercake.etl_daily_count_cell_contacts cc
                                  where cc.[date]               = n.[date]
                                    and cc.region               = n.region
                                    and cc.country_id           = n.country_id
                                    and cc.gender_id            = n.gender_id
                                    and cc.grade                = n.grade
                                    and cc.membership_status_id = n.membership_status_id
                                    and cc.payment_method_id    = n.payment_method_id
                                    and cc.payer_type_id        = n.payer_type_id
                                    and cc.concession_type_id   = n.concession_type_id);

                -- ---- main: differences only -----------------------------
                delete t
                from Layercake.silv_daily_count t
                inner join #dc_chunk c
                    on  c.[date] = t.[date]
                where not exists (select 1 from #dc_new_main n
                                  where n.[date] = t.[date]
                                    and n.region = t.region
                                    and n.grade  = t.grade);
                set @del = @del + @@rowcount;

                update t
                set campaign_year           = n.campaign_year,
                    campaign_quarter        = n.campaign_quarter,
                    active_count            = n.active_count,
                    paid_count              = n.paid_count,
                    paid_count_event        = n.paid_count_event,
                    event_join_count        = n.event_join_count,
                    event_renewal_count     = n.event_renewal_count,
                    event_readmission_count = n.event_readmission_count,
                    event_lapse_count       = n.event_lapse_count
                from Layercake.silv_daily_count t
                inner join #dc_new_main n
                    on  n.[date] = t.[date]
                    and n.region = t.region
                    and n.grade  = t.grade
                where t.campaign_year           <> n.campaign_year
                   or t.campaign_quarter        <> n.campaign_quarter
                   or t.active_count            <> n.active_count
                   or t.paid_count              <> n.paid_count
                   or t.paid_count_event        <> n.paid_count_event
                   or t.event_join_count        <> n.event_join_count
                   or t.event_renewal_count     <> n.event_renewal_count
                   or t.event_readmission_count <> n.event_readmission_count
                   or t.event_lapse_count       <> n.event_lapse_count;
                set @upd = @upd + @@rowcount;

                insert into Layercake.silv_daily_count
                ([date], campaign_year, campaign_quarter, region, grade,
                 active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
                select n.[date], n.campaign_year, n.campaign_quarter, n.region, n.grade,
                       n.active_count, n.paid_count, n.paid_count_event,
                       n.event_join_count, n.event_renewal_count, n.event_readmission_count, n.event_lapse_count
                from #dc_new_main n
                where not exists (select 1 from Layercake.silv_daily_count t
                                  where t.[date] = n.[date]
                                    and t.region = n.region
                                    and t.grade  = n.grade);
                set @ins = @ins + @@rowcount;

                -- ---- mark the batch loaded (ATOMIC with its data) -------
                -- today included: its first load is a first load, and every
                -- later reload of today records its changes (RULE-114)
                insert into Layercake.etl_daily_count_loaded ([date], run_id, batch_from, batch_to)
                select c.[date], @run_id, @win_from, @win_to
                from #dc_chunk c
                where not exists (select 1 from Layercake.etl_daily_count_loaded l
                                  where l.[date] = c.[date]);
                set @marked = @@rowcount;
            end
            else
            begin
                -- ---- mode D: add new minus old to the touched cells ------
                -- A cell exists while a contact sits in it (Q-059): one whose
                -- contact count falls to 0 is removed, whatever its measures.
                truncate table #dc_apply;

                insert into #dc_apply
                ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
                 payment_method_id, payer_type_id, concession_type_id,
                 detail_found, count_found, contact_count,
                 old_active, old_paid, old_paid_event, old_join, old_renewal, old_readmission, old_lapse,
                 new_active, new_paid, new_paid_event, new_join, new_renewal, new_readmission, new_lapse)
                select n.[date], n.campaign_year, n.campaign_quarter, n.region, n.country_id, n.gender_id, n.grade,
                       n.membership_status_id, n.payment_method_id, n.payer_type_id, n.concession_type_id,
                       iif(d.[date] is null, 0, 1),
                       iif(cc.[date] is null, 0, 1),
                       k.cnt,
                       isnull(d.active_count, 0), isnull(d.paid_count, 0), isnull(d.paid_count_event, 0),
                       isnull(d.event_join_count, 0), isnull(d.event_renewal_count, 0),
                       isnull(d.event_readmission_count, 0), isnull(d.event_lapse_count, 0),
                       iif(k.cnt > 0, isnull(d.active_count, 0)            + n.active_count, 0),
                       iif(k.cnt > 0, isnull(d.paid_count, 0)              + n.paid_count, 0),
                       iif(k.cnt > 0, isnull(d.paid_count_event, 0)        + n.paid_count_event, 0),
                       iif(k.cnt > 0, isnull(d.event_join_count, 0)        + n.event_join_count, 0),
                       iif(k.cnt > 0, isnull(d.event_renewal_count, 0)     + n.event_renewal_count, 0),
                       iif(k.cnt > 0, isnull(d.event_readmission_count, 0) + n.event_readmission_count, 0),
                       iif(k.cnt > 0, isnull(d.event_lapse_count, 0)       + n.event_lapse_count, 0)
                from #dc_new n
                left join Layercake.silv_daily_count_detail d
                    on  d.[date]               = n.[date]
                    and d.region               = n.region
                    and d.country_id           = n.country_id
                    and d.gender_id            = n.gender_id
                    and d.grade                = n.grade
                    and d.membership_status_id = n.membership_status_id
                    and d.payment_method_id    = n.payment_method_id
                    and d.payer_type_id        = n.payer_type_id
                    and d.concession_type_id   = n.concession_type_id
                left join Layercake.etl_daily_count_cell_contacts cc
                    on  cc.[date]               = n.[date]
                    and cc.region               = n.region
                    and cc.country_id           = n.country_id
                    and cc.gender_id            = n.gender_id
                    and cc.grade                = n.grade
                    and cc.membership_status_id = n.membership_status_id
                    and cc.payment_method_id    = n.payment_method_id
                    and cc.payer_type_id        = n.payer_type_id
                    and cc.concession_type_id   = n.concession_type_id
                cross apply (select isnull(cc.contact_count, 0) + n.contact_count as cnt) k;

                -- ---- adjustment history (REQ-019): stored new minus old --
                insert into Layercake.silv_daily_count_adjustment
                (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
                 payment_method_id, payer_type_id, concession_type_id,
                 active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
                 event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
                select @run_id, @log_id, sysdatetime(),
                       a.[date], a.region, a.country_id, a.gender_id, a.grade, a.membership_status_id,
                       a.payment_method_id, a.payer_type_id, a.concession_type_id,
                       a.new_active - a.old_active, a.new_paid - a.old_paid, a.new_paid_event - a.old_paid_event,
                       a.new_join - a.old_join, a.new_renewal - a.old_renewal,
                       a.new_readmission - a.old_readmission, a.new_lapse - a.old_lapse
                from #dc_apply a
                where exists (select 1 from Layercake.etl_daily_count_loaded l where l.[date] = a.[date])
                  and (a.new_active <> a.old_active or a.new_paid <> a.old_paid or a.new_paid_event <> a.old_paid_event
                       or a.new_join <> a.old_join or a.new_renewal <> a.old_renewal
                       or a.new_readmission <> a.old_readmission or a.new_lapse <> a.old_lapse);
                set @adj = @adj + @@rowcount;

                -- ---- detail ---------------------------------------------
                delete d
                from Layercake.silv_daily_count_detail d
                inner join #dc_apply a
                    on  a.[date]               = d.[date]
                    and a.region               = d.region
                    and a.country_id           = d.country_id
                    and a.gender_id            = d.gender_id
                    and a.grade                = d.grade
                    and a.membership_status_id = d.membership_status_id
                    and a.payment_method_id    = d.payment_method_id
                    and a.payer_type_id        = d.payer_type_id
                    and a.concession_type_id   = d.concession_type_id
                where a.contact_count <= 0;
                set @del = @del + @@rowcount;

                update d
                set campaign_year           = a.campaign_year,
                    campaign_quarter        = a.campaign_quarter,
                    active_count            = a.new_active,
                    paid_count              = a.new_paid,
                    paid_count_event        = a.new_paid_event,
                    event_join_count        = a.new_join,
                    event_renewal_count     = a.new_renewal,
                    event_readmission_count = a.new_readmission,
                    event_lapse_count       = a.new_lapse
                from Layercake.silv_daily_count_detail d
                inner join #dc_apply a
                    on  a.[date]               = d.[date]
                    and a.region               = d.region
                    and a.country_id           = d.country_id
                    and a.gender_id            = d.gender_id
                    and a.grade                = d.grade
                    and a.membership_status_id = d.membership_status_id
                    and a.payment_method_id    = d.payment_method_id
                    and a.payer_type_id        = d.payer_type_id
                    and a.concession_type_id   = d.concession_type_id
                where a.contact_count > 0
                  and (d.campaign_year           <> a.campaign_year
                       or d.campaign_quarter        <> a.campaign_quarter
                       or d.active_count            <> a.new_active
                       or d.paid_count              <> a.new_paid
                       or d.paid_count_event        <> a.new_paid_event
                       or d.event_join_count        <> a.new_join
                       or d.event_renewal_count     <> a.new_renewal
                       or d.event_readmission_count <> a.new_readmission
                       or d.event_lapse_count       <> a.new_lapse);
                set @upd = @upd + @@rowcount;

                insert into Layercake.silv_daily_count_detail
                ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
                 payment_method_id, payer_type_id, concession_type_id,
                 active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
                select a.[date], a.campaign_year, a.campaign_quarter, a.region, a.country_id, a.gender_id, a.grade,
                       a.membership_status_id, a.payment_method_id, a.payer_type_id, a.concession_type_id,
                       a.new_active, a.new_paid, a.new_paid_event,
                       a.new_join, a.new_renewal, a.new_readmission, a.new_lapse
                from #dc_apply a
                where a.contact_count > 0
                  and a.detail_found = 0;
                set @ins = @ins + @@rowcount;

                -- ---- cell contact counts --------------------------------
                delete cc
                from Layercake.etl_daily_count_cell_contacts cc
                inner join #dc_apply a
                    on  a.[date]               = cc.[date]
                    and a.region               = cc.region
                    and a.country_id           = cc.country_id
                    and a.gender_id            = cc.gender_id
                    and a.grade                = cc.grade
                    and a.membership_status_id = cc.membership_status_id
                    and a.payment_method_id    = cc.payment_method_id
                    and a.payer_type_id        = cc.payer_type_id
                    and a.concession_type_id   = cc.concession_type_id
                where a.contact_count <= 0;

                update cc
                set contact_count = a.contact_count,
                    run_id        = @run_id,
                    updated_at    = sysdatetime()
                from Layercake.etl_daily_count_cell_contacts cc
                inner join #dc_apply a
                    on  a.[date]               = cc.[date]
                    and a.region               = cc.region
                    and a.country_id           = cc.country_id
                    and a.gender_id            = cc.gender_id
                    and a.grade                = cc.grade
                    and a.membership_status_id = cc.membership_status_id
                    and a.payment_method_id    = cc.payment_method_id
                    and a.payer_type_id        = cc.payer_type_id
                    and a.concession_type_id   = cc.concession_type_id
                where a.contact_count > 0
                  and cc.contact_count <> a.contact_count;

                insert into Layercake.etl_daily_count_cell_contacts
                ([date], region, country_id, gender_id, grade, membership_status_id,
                 payment_method_id, payer_type_id, concession_type_id, contact_count, run_id, updated_at)
                select a.[date], a.region, a.country_id, a.gender_id, a.grade, a.membership_status_id,
                       a.payment_method_id, a.payer_type_id, a.concession_type_id,
                       a.contact_count, @run_id, sysdatetime()
                from #dc_apply a
                where a.contact_count > 0
                  and a.count_found = 0;

                -- ---- main: the touched rows, as the sum of their detail ---
                truncate table #dc_touch;

                insert into #dc_touch ([date], region, grade)
                select distinct a.[date], a.region, a.grade
                from #dc_apply a;

                truncate table #dc_new_main;

                insert into #dc_new_main
                ([date], campaign_year, campaign_quarter, region, grade,
                 active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
                select
                    d.[date], d.campaign_year, d.campaign_quarter, d.region, d.grade,
                    sum(d.active_count), sum(d.paid_count), sum(d.paid_count_event),
                    sum(d.event_join_count), sum(d.event_renewal_count),
                    sum(d.event_readmission_count), sum(d.event_lapse_count)
                from Layercake.silv_daily_count_detail d
                inner join #dc_touch x
                    on  x.[date] = d.[date]
                    and x.region = d.region
                    and x.grade  = d.grade
                group by d.[date], d.campaign_year, d.campaign_quarter, d.region, d.grade;

                delete t
                from Layercake.silv_daily_count t
                inner join #dc_touch x
                    on  x.[date] = t.[date]
                    and x.region = t.region
                    and x.grade  = t.grade
                where not exists (select 1 from #dc_new_main n
                                  where n.[date] = t.[date]
                                    and n.region = t.region
                                    and n.grade  = t.grade);
                set @del = @del + @@rowcount;

                update t
                set campaign_year           = n.campaign_year,
                    campaign_quarter        = n.campaign_quarter,
                    active_count            = n.active_count,
                    paid_count              = n.paid_count,
                    paid_count_event        = n.paid_count_event,
                    event_join_count        = n.event_join_count,
                    event_renewal_count     = n.event_renewal_count,
                    event_readmission_count = n.event_readmission_count,
                    event_lapse_count       = n.event_lapse_count
                from Layercake.silv_daily_count t
                inner join #dc_new_main n
                    on  n.[date] = t.[date]
                    and n.region = t.region
                    and n.grade  = t.grade
                where t.campaign_year           <> n.campaign_year
                   or t.campaign_quarter        <> n.campaign_quarter
                   or t.active_count            <> n.active_count
                   or t.paid_count              <> n.paid_count
                   or t.paid_count_event        <> n.paid_count_event
                   or t.event_join_count        <> n.event_join_count
                   or t.event_renewal_count     <> n.event_renewal_count
                   or t.event_readmission_count <> n.event_readmission_count
                   or t.event_lapse_count       <> n.event_lapse_count;
                set @upd = @upd + @@rowcount;

                insert into Layercake.silv_daily_count
                ([date], campaign_year, campaign_quarter, region, grade,
                 active_count, paid_count, paid_count_event,
                 event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
                select n.[date], n.campaign_year, n.campaign_quarter, n.region, n.grade,
                       n.active_count, n.paid_count, n.paid_count_event,
                       n.event_join_count, n.event_renewal_count, n.event_readmission_count, n.event_lapse_count
                from #dc_new_main n
                where not exists (select 1 from Layercake.silv_daily_count t
                                  where t.[date] = n.[date]
                                    and t.region = n.region
                                    and t.grade  = n.grade);
                set @ins = @ins + @@rowcount;

                set @marked = 0;
            end

            commit;    -- one transaction per batch: small, quick, resumable
            set @withdrawn = 1;

            set @note = concat(N'batch ', @mode, N' ', convert(nvarchar(10), @win_from, 23),
                               N' -> ',   convert(nvarchar(10), @win_to,  23),
                               N' (', @rc, N' detail cells derived, ', @marked, N' date(s) newly marked loaded)');
            exec Layercake.usp_etl_log_progress @log_id, @note, @rc, @substep_ts output;

            -- done with these dates
            delete t
            from #dc_todo t
            where exists (select 1 from #dc_chunk c where c.[date] = t.[date]);
        end

        /* ---- g. advance the basis and the snapshot ---------------------
           Only now, with every batch committed: a run that died mid-walk
           leaves the basis as it was (restatement marker included) and the
           snapshot out of step. The snapshot rows of the contacts this run
           applied, and of any that were out of step, are rewritten from the
           inputs the run used, so every contact's basis row and snapshot
           describe the same inputs. The pending rows the correction covered
           are stamped applied in the same transaction.
           ------------------------------------------------------------- */
        create table #rewrite (contact_no nvarchar(200) collate database_default not null primary key clustered);

        insert into #rewrite (contact_no)
        select k.contact_no from #chg k
        union
        select o.contact_no from #snap_out o;

        begin tran;

        delete b
        from Layercake.etl_daily_count_input_basis b
        where b.input_name = 'contact'
          and not exists (select 1 from #in_cur c where c.contact_no = b.input_key);

        update b
        set input_fingerprint      = c.input_fingerprint,
            earliest_affected_date = c.earliest_affected_date,
            run_id                 = @run_id,
            updated_at             = sysdatetime()
        from Layercake.etl_daily_count_input_basis b
        inner join #in_cur c
            on  b.input_name = 'contact'
            and b.input_key  = c.contact_no
        where b.input_fingerprint      <> c.input_fingerprint
           or b.earliest_affected_date <> c.earliest_affected_date;

        insert into Layercake.etl_daily_count_input_basis
        (input_name, input_key, input_fingerprint, earliest_affected_date, run_id, updated_at)
        select 'contact', c.contact_no, c.input_fingerprint, c.earliest_affected_date, @run_id, sysdatetime()
        from #in_cur c
        where not exists (select 1 from Layercake.etl_daily_count_input_basis b
                          where b.input_name = 'contact'
                            and b.input_key  = c.contact_no);

        -- reference rows that have gone, and the restatement marker: every
        -- loaded date is now at the segment grain (ADR-013)
        delete b
        from Layercake.etl_daily_count_input_basis b
        where b.input_name <> 'contact'
          and not exists (select 1 from #ref_cur r where r.input_name = b.input_name);

        update b
        set input_fingerprint = r.fp_end,
            run_id            = @run_id,
            updated_at        = sysdatetime()
        from Layercake.etl_daily_count_input_basis b
        inner join #ref_cur r
            on  r.input_name = b.input_name
        where b.input_fingerprint <> r.fp_end;

        insert into Layercake.etl_daily_count_input_basis
        (input_name, input_key, input_fingerprint, earliest_affected_date, run_id, updated_at)
        select r.input_name, N'', r.fp_end, @spine_from, @run_id, sysdatetime()
        from #ref_cur r
        where not exists (select 1 from Layercake.etl_daily_count_input_basis b
                          where b.input_name = r.input_name);

        delete a
        from Layercake.etl_daily_count_applied_state_range a
        inner join #rewrite w on w.contact_no = a.contact_no;

        delete a
        from Layercake.etl_daily_count_applied_payment a
        inner join #rewrite w on w.contact_no = a.contact_no;

        delete a
        from Layercake.etl_daily_count_applied_event a
        inner join #rewrite w on w.contact_no = a.contact_no;

        delete a
        from Layercake.etl_daily_count_applied_attribute a
        inner join #rewrite w on w.contact_no = a.contact_no;

        delete h
        from Layercake.etl_daily_count_applied_contact h
        inner join #rewrite w on w.contact_no = h.contact_no;

        insert into Layercake.etl_daily_count_applied_contact
        (contact_no, profile_found, country_id, gender_id, retirement_date, run_id, updated_at)
        select c.contact_no, iif(pr.contact_no is null, 0, 1), pr.country_id, pr.gender_id, pr.retirement_date,
               @run_id, sysdatetime()
        from #in_cur c
        inner join #rewrite w
            on  w.contact_no = c.contact_no
        left join #prof pr
            on  pr.side       = 'C'
            and pr.contact_no = c.contact_no;

        insert into Layercake.etl_daily_count_applied_state_range (contact_no, valid_from, valid_to, grade, region)
        select r.contact_no, r.valid_from, r.valid_to, r.grade, r.region
        from #rng r
        inner join #rewrite w
            on  w.contact_no = r.contact_no
        where r.side = 'C';

        insert into Layercake.etl_daily_count_applied_payment (contact_no, campaign_year, renewal_date_adj)
        select p.contact_no, p.campaign_year, p.renewal_date_adj
        from #pay p
        inner join #rewrite w
            on  w.contact_no = p.contact_no
        where p.side = 'C';

        insert into Layercake.etl_daily_count_applied_event (contact_no, campaign_year, event_type, event_date)
        select e.contact_no, e.campaign_year, e.event_type, e.event_date
        from #evt e
        inner join #rewrite w
            on  w.contact_no = e.contact_no
        where e.side = 'C';

        insert into Layercake.etl_daily_count_applied_attribute
        (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
        select a.contact_no, a.campaign_year, a.payment_method_id, a.payer_type_id, a.concession_type_id
        from #attr a
        inner join #rewrite w
            on  w.contact_no = a.contact_no
        where a.side = 'C';

        update Layercake.etl_daily_count_pending_rebuild
        set applied_at = sysdatetime()
        where applied_at is null
          and affected_from >= @start;
        set @pend = @@rowcount;

        commit;

        set @note = concat(N'input basis and snapshot advanced; ', @adj, N' adjustment row(s) written',
                           iif(@restate = 1, N', restated at the segment grain', N''),
                           iif(@pend > 0, concat(N', ', @pend, N' pending row(s) stamped applied'), N''));
        exec Layercake.usp_etl_log_progress @log_id, @note, @adj, @substep_ts output;

        exec Layercake.usp_etl_log_end @log_id, 'Success', @ins, @upd, @del;
    end try
    begin catch
        if xact_state() <> 0 rollback;
        set @err = concat(error_message(), ' (error ', error_number(), ', line ', error_line(), ')');
        if @log_id is not null
            exec Layercake.usp_etl_log_end @log_id, 'Failed', @ins, @upd, @del, @err;
        throw;
    end catch
end
