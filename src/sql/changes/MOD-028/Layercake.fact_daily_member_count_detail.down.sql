-- ADR-013: sum the fact back to the old grain over the three segment keys. The lowest id of each
-- old cell takes the sums and is kept; the other rows go.
WITH ranked AS (
    SELECT ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents,
           SUM(ActiveMembers) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id) AS s_active,
           SUM(PaidMembers) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id) AS s_paid,
           SUM(PaidMembersEvent) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id) AS s_paid_event,
           SUM(JoinEvents) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id) AS s_join,
           SUM(RenewalEvents) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id) AS s_renewal,
           SUM(ReadmissionEvents) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id) AS s_readmission,
           SUM(LapseEvents) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id) AS s_lapse,
           ROW_NUMBER() OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id
                              ORDER BY id) AS rn
    FROM Layercake.fact_daily_member_count_detail
)
UPDATE ranked
SET ActiveMembers     = s_active,
    PaidMembers       = s_paid,
    PaidMembersEvent  = s_paid_event,
    JoinEvents        = s_join,
    RenewalEvents     = s_renewal,
    ReadmissionEvents = s_readmission,
    LapseEvents       = s_lapse
WHERE rn = 1;

WITH ranked AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id
                              ORDER BY id) AS rn
    FROM Layercake.fact_daily_member_count_detail
)
DELETE FROM ranked WHERE rn > 1;

DROP INDEX cx_fact_daily_member_count_detail ON Layercake.fact_daily_member_count_detail;
ALTER TABLE Layercake.fact_daily_member_count_detail DROP COLUMN payment_method_id, payer_type_id, concession_type_id;
CREATE UNIQUE CLUSTERED INDEX cx_fact_daily_member_count_detail
    ON Layercake.fact_daily_member_count_detail
    (date_id, country_id, gender_id, membership_grade_id, membership_status_id);
