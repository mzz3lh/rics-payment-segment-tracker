-- Back to the AMD-007 grain on the own-country values: region from contact_region and
-- country_id from contact_country_id, then the rows of each old cell are summed into one.
ALTER TABLE Layercake.silv_daily_count_detail DROP CONSTRAINT pk_silv_daily_count_detail;
-- EXEC: the statement names columns this script drops, so a rerun after the drop must not compile it.
EXEC (N'UPDATE Layercake.silv_daily_count_detail SET region = contact_region, country_id = contact_country_id;');
ALTER TABLE Layercake.silv_daily_count_detail DROP COLUMN local_group_id, contact_country_id, contact_region;

WITH ranked AS (
    SELECT active_count, paid_count, paid_count_event, event_join_count, event_renewal_count,
           event_readmission_count, event_lapse_count,
           SUM(active_count) OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id,
                                                payment_method_id, payer_type_id, concession_type_id) AS s_active,
           SUM(paid_count) OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id,
                                              payment_method_id, payer_type_id, concession_type_id) AS s_paid,
           SUM(paid_count_event) OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id,
                                                    payment_method_id, payer_type_id, concession_type_id) AS s_paid_event,
           SUM(event_join_count) OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id,
                                                    payment_method_id, payer_type_id, concession_type_id) AS s_join,
           SUM(event_renewal_count) OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id,
                                                       payment_method_id, payer_type_id, concession_type_id) AS s_renewal,
           SUM(event_readmission_count) OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id,
                                                           payment_method_id, payer_type_id, concession_type_id) AS s_readmission,
           SUM(event_lapse_count) OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id,
                                                     payment_method_id, payer_type_id, concession_type_id) AS s_lapse,
           ROW_NUMBER() OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id,
                                           payment_method_id, payer_type_id, concession_type_id
                              ORDER BY active_count DESC) AS rn
    FROM Layercake.silv_daily_count_detail
)
UPDATE ranked
SET active_count            = s_active,
    paid_count              = s_paid,
    paid_count_event        = s_paid_event,
    event_join_count        = s_join,
    event_renewal_count     = s_renewal,
    event_readmission_count = s_readmission,
    event_lapse_count       = s_lapse
WHERE rn = 1;

WITH ranked AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id,
                                           payment_method_id, payer_type_id, concession_type_id
                              ORDER BY active_count DESC) AS rn
    FROM Layercake.silv_daily_count_detail
)
DELETE FROM ranked WHERE rn > 1;

ALTER TABLE Layercake.silv_daily_count_detail ADD CONSTRAINT pk_silv_daily_count_detail PRIMARY KEY CLUSTERED
    ([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id);

-- silv_daily_count is the sum of the detail, so it follows the detail back to the own-country regions.
DELETE FROM Layercake.silv_daily_count;
INSERT INTO Layercake.silv_daily_count
    ([date], campaign_year, campaign_quarter, region, grade, active_count, paid_count, paid_count_event,
     event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
SELECT [date], campaign_year, campaign_quarter, region, grade, SUM(active_count), SUM(paid_count), SUM(paid_count_event),
       SUM(event_join_count), SUM(event_renewal_count), SUM(event_readmission_count), SUM(event_lapse_count)
FROM Layercake.silv_daily_count_detail
GROUP BY [date], campaign_year, campaign_quarter, region, grade;

-- Remove the marker and empty the whole snapshot (child tables first), so the restored MOD-028
-- load takes its full path once.
DELETE FROM Layercake.etl_daily_count_input_basis WHERE input_name = 'local_group_restatement' AND input_key = N'';
DELETE FROM Layercake.etl_daily_count_applied_attribute;
DELETE FROM Layercake.etl_daily_count_applied_state_range;
DELETE FROM Layercake.etl_daily_count_applied_payment;
DELETE FROM Layercake.etl_daily_count_applied_event;
DELETE FROM Layercake.etl_daily_count_applied_contact;
