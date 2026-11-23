/*====================================================================
    Layercake.fn_silv_daily_count_detail_as_known_at
    Daily counts at the silv_daily_count_detail grain as they stood at
    @as_known_at (REQ-020, ADR-008, RULE-119 to RULE-121): the stored
    figure (0 where the cell has no stored row) minus the cell's changes
    in silv_daily_count_adjustment written strictly after @as_known_at.
    A change written exactly at @as_known_at is part of the figure
    (Q-049, server local time). A date first loaded after @as_known_at
    gives its first-load figures (Q-050). A cell with no stored row is
    returned only when one of its figures is not 0 at @as_known_at.
    Any NULL parameter returns no rows.
    MOD-028 (REQ-026, RULE-155): the cell includes payment_method_id,
    payer_type_id and concession_type_id. Adjustment rows written before
    deployment, and by the restating run, carry -2, so for a time before
    deployment the figures are exact summed over the three columns but
    not split by segment (RULE-163).
====================================================================*/
CREATE OR ALTER FUNCTION Layercake.fn_silv_daily_count_detail_as_known_at
(
    @date_from   date,
    @date_to     date,
    @as_known_at datetime2(3)
)
RETURNS TABLE
AS
RETURN
    SELECT
        f.[date],
        f.region,
        f.country_id,
        f.gender_id,
        f.grade,
        f.membership_status_id,
        f.payment_method_id,
        f.payer_type_id,
        f.concession_type_id,
        ISNULL(SUM(f.active_count), 0)            AS active_count,
        ISNULL(SUM(f.paid_count), 0)              AS paid_count,
        ISNULL(SUM(f.paid_count_event), 0)        AS paid_count_event,
        ISNULL(SUM(f.event_join_count), 0)        AS event_join_count,
        ISNULL(SUM(f.event_renewal_count), 0)     AS event_renewal_count,
        ISNULL(SUM(f.event_readmission_count), 0) AS event_readmission_count,
        ISNULL(SUM(f.event_lapse_count), 0)       AS event_lapse_count
    FROM (
        SELECT
            d.[date], d.region, d.country_id, d.gender_id, d.grade, d.membership_status_id,
            d.payment_method_id, d.payer_type_id, d.concession_type_id,
            d.active_count, d.paid_count, d.paid_count_event, d.event_join_count,
            d.event_renewal_count, d.event_readmission_count, d.event_lapse_count,
            1 AS is_stored
        FROM Layercake.silv_daily_count_detail AS d
        WHERE d.[date] BETWEEN @date_from AND @date_to
          AND @as_known_at IS NOT NULL

        UNION ALL

        -- Undo every change written after T.
        SELECT
            a.[date], a.region, a.country_id, a.gender_id, a.grade, a.membership_status_id,
            a.payment_method_id, a.payer_type_id, a.concession_type_id,
            -a.active_count_change, -a.paid_count_change, -a.paid_count_event_change, -a.event_join_count_change,
            -a.event_renewal_count_change, -a.event_readmission_count_change, -a.event_lapse_count_change,
            0 AS is_stored
        FROM Layercake.silv_daily_count_adjustment AS a
        WHERE a.[date] BETWEEN @date_from AND @date_to
          AND a.written_at > @as_known_at
    ) AS f
    GROUP BY f.[date], f.region, f.country_id, f.gender_id, f.grade, f.membership_status_id,
             f.payment_method_id, f.payer_type_id, f.concession_type_id
    -- A stored row is always returned, even all zeros; a cell that exists only in the history
    -- (removed after T) is returned only if it had a figure at T.
    HAVING MAX(f.is_stored) = 1
        OR SUM(f.active_count) <> 0
        OR SUM(f.paid_count) <> 0
        OR SUM(f.paid_count_event) <> 0
        OR SUM(f.event_join_count) <> 0
        OR SUM(f.event_renewal_count) <> 0
        OR SUM(f.event_readmission_count) <> 0
        OR SUM(f.event_lapse_count) <> 0;
