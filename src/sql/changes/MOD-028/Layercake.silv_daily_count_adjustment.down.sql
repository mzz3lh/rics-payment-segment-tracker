-- ADR-013: sum the rows back to the old grain by run and old cell. The lowest adjustment_id of each
-- takes the sums and keeps its load_id and written_at; a cell whose seven sums are all 0 records
-- no change at the old grain, so all its rows go.
WITH sums AS (
    SELECT SUM(active_count_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_active,
           SUM(paid_count_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_paid,
           SUM(paid_count_event_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_paid_event,
           SUM(event_join_count_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_join,
           SUM(event_renewal_count_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_renewal,
           SUM(event_readmission_count_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_readmission,
           SUM(event_lapse_count_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_lapse
    FROM Layercake.silv_daily_count_adjustment
)
DELETE FROM sums
WHERE s_active = 0 AND s_paid = 0 AND s_paid_event = 0 AND s_join = 0
  AND s_renewal = 0 AND s_readmission = 0 AND s_lapse = 0;

WITH ranked AS (
    SELECT active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
           event_renewal_count_change, event_readmission_count_change, event_lapse_count_change,
           SUM(active_count_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_active,
           SUM(paid_count_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_paid,
           SUM(paid_count_event_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_paid_event,
           SUM(event_join_count_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_join,
           SUM(event_renewal_count_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_renewal,
           SUM(event_readmission_count_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_readmission,
           SUM(event_lapse_count_change) OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id) AS s_lapse,
           ROW_NUMBER() OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id
                              ORDER BY adjustment_id) AS rn
    FROM Layercake.silv_daily_count_adjustment
)
UPDATE ranked
SET active_count_change            = s_active,
    paid_count_change              = s_paid,
    paid_count_event_change        = s_paid_event,
    event_join_count_change        = s_join,
    event_renewal_count_change     = s_renewal,
    event_readmission_count_change = s_readmission,
    event_lapse_count_change       = s_lapse
WHERE rn = 1;

WITH ranked AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY run_id, [date], region, country_id, gender_id, grade, membership_status_id
                              ORDER BY adjustment_id) AS rn
    FROM Layercake.silv_daily_count_adjustment
)
DELETE FROM ranked WHERE rn > 1;

DROP INDEX IX_silv_daily_count_adjustment_date_written_at ON Layercake.silv_daily_count_adjustment;
ALTER TABLE Layercake.silv_daily_count_adjustment DROP CONSTRAINT UQ_Layercake_silv_daily_count_adjustment_run_id_cell;
ALTER TABLE Layercake.silv_daily_count_adjustment DROP COLUMN payment_method_id, payer_type_id, concession_type_id;
ALTER TABLE Layercake.silv_daily_count_adjustment
    ADD CONSTRAINT UQ_Layercake_silv_daily_count_adjustment_run_id_date_region_country_id_gender_id_grade_membership_status_id
    UNIQUE (run_id, [date], region, country_id, gender_id, grade, membership_status_id);
CREATE INDEX IX_silv_daily_count_adjustment_date_written_at
    ON Layercake.silv_daily_count_adjustment ([date], written_at)
    INCLUDE (region, country_id, gender_id, grade, membership_status_id,
             active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
             event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);
