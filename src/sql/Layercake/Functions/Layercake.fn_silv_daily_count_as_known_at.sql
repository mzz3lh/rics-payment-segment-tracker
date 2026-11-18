/*====================================================================
    Layercake.fn_silv_daily_count_as_known_at
    Daily counts at the silv_daily_count grain ([date], region, grade)
    as they stood at @as_known_at (REQ-020, ADR-008, RULE-120): the
    detail figures of fn_silv_daily_count_detail_as_known_at summed over
    country_id, gender_id and membership_status_id, as the Phase 1 daily
    count load builds silv_daily_count from silv_daily_count_detail.
    Same parameters and rules; any NULL parameter returns no rows.
====================================================================*/
CREATE OR ALTER FUNCTION Layercake.fn_silv_daily_count_as_known_at
(
    @date_from   date,
    @date_to     date,
    @as_known_at datetime2(3)
)
RETURNS TABLE
AS
RETURN
    SELECT
        d.[date],
        d.region,
        d.grade,
        ISNULL(SUM(d.active_count), 0)            AS active_count,
        ISNULL(SUM(d.paid_count), 0)              AS paid_count,
        ISNULL(SUM(d.paid_count_event), 0)        AS paid_count_event,
        ISNULL(SUM(d.event_join_count), 0)        AS event_join_count,
        ISNULL(SUM(d.event_renewal_count), 0)     AS event_renewal_count,
        ISNULL(SUM(d.event_readmission_count), 0) AS event_readmission_count,
        ISNULL(SUM(d.event_lapse_count), 0)       AS event_lapse_count
    FROM Layercake.fn_silv_daily_count_detail_as_known_at(@date_from, @date_to, @as_known_at) AS d
    GROUP BY d.[date], d.region, d.grade;
