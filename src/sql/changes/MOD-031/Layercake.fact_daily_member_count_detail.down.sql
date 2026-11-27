-- Back to the AMD-007 grain with contact_country_id as country_id. The lowest id of each old cell
-- takes the sums and is kept; the other rows go.
DROP INDEX cx_fact_daily_member_count_detail ON Layercake.fact_daily_member_count_detail;
-- EXEC: the statement names a column this script drops, so a rerun after the drop must not compile it.
EXEC (N'UPDATE Layercake.fact_daily_member_count_detail SET country_id = contact_country_id;');
ALTER TABLE Layercake.fact_daily_member_count_detail DROP COLUMN local_group_id, contact_country_id;

WITH ranked AS (
    SELECT ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents,
           SUM(ActiveMembers) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id,
                                                 payment_method_id, payer_type_id, concession_type_id) AS s_active,
           SUM(PaidMembers) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id,
                                               payment_method_id, payer_type_id, concession_type_id) AS s_paid,
           SUM(PaidMembersEvent) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id,
                                                    payment_method_id, payer_type_id, concession_type_id) AS s_paid_event,
           SUM(JoinEvents) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id,
                                              payment_method_id, payer_type_id, concession_type_id) AS s_join,
           SUM(RenewalEvents) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id,
                                                 payment_method_id, payer_type_id, concession_type_id) AS s_renewal,
           SUM(ReadmissionEvents) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id,
                                                     payment_method_id, payer_type_id, concession_type_id) AS s_readmission,
           SUM(LapseEvents) OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id,
                                               payment_method_id, payer_type_id, concession_type_id) AS s_lapse,
           ROW_NUMBER() OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id,
                                           payment_method_id, payer_type_id, concession_type_id
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
    SELECT ROW_NUMBER() OVER (PARTITION BY date_id, country_id, gender_id, membership_grade_id, membership_status_id,
                                           payment_method_id, payer_type_id, concession_type_id
                              ORDER BY id) AS rn
    FROM Layercake.fact_daily_member_count_detail
)
DELETE FROM ranked WHERE rn > 1;

CREATE UNIQUE CLUSTERED INDEX cx_fact_daily_member_count_detail
    ON Layercake.fact_daily_member_count_detail
    (date_id, country_id, gender_id, membership_grade_id, membership_status_id,
     payment_method_id, payer_type_id, concession_type_id);
