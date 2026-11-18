/*====================================================================
    Layercake.vw_silv_daily_count_adjustment_review
    The daily count adjustments for review (RULE-122, Q-051): one row per
    silv_daily_count_adjustment row and measure whose change is not 0,
    keeping the cell's grain columns. Not summed to date level, so
    changes that cancel out across cells stay visible. measure_name is
    the silv_daily_count_detail column name.
====================================================================*/
CREATE OR ALTER VIEW Layercake.vw_silv_daily_count_adjustment_review
AS
SELECT
    a.adjustment_id,
    a.run_id,
    a.written_at,
    a.[date],
    a.region,
    a.country_id,
    a.gender_id,
    a.grade,
    a.membership_status_id,
    -- ISNULL only makes the column NOT NULL, as designed: a VALUES column is always reported nullable.
    ISNULL(m.measure_name, '') AS measure_name,
    m.change_value
FROM Layercake.silv_daily_count_adjustment AS a
CROSS APPLY (
    VALUES (CAST('active_count' AS varchar(30)), a.active_count_change),
           ('paid_count', a.paid_count_change),
           ('paid_count_event', a.paid_count_event_change),
           ('event_join_count', a.event_join_count_change),
           ('event_renewal_count', a.event_renewal_count_change),
           ('event_readmission_count', a.event_readmission_count_change),
           ('event_lapse_count', a.event_lapse_count_change)
) AS m (measure_name, change_value)
WHERE m.change_value <> 0;
