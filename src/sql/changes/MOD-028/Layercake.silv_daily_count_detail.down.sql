-- ADR-013: sum the stored cells back to the old grain over the three segment ids, drop the
-- columns and write the old cells back. No statement names a segment column, so the script
-- still compiles when it is run again after the columns have gone.
SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
       SUM(active_count) AS active_count, SUM(paid_count) AS paid_count, SUM(paid_count_event) AS paid_count_event,
       SUM(event_join_count) AS event_join_count, SUM(event_renewal_count) AS event_renewal_count,
       SUM(event_readmission_count) AS event_readmission_count, SUM(event_lapse_count) AS event_lapse_count
INTO #mig0030_detail_old_grain
FROM Layercake.silv_daily_count_detail
GROUP BY [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id;

DELETE FROM Layercake.silv_daily_count_detail;

ALTER TABLE Layercake.silv_daily_count_detail DROP CONSTRAINT pk_silv_daily_count_detail;
ALTER TABLE Layercake.silv_daily_count_detail DROP COLUMN payment_method_id, payer_type_id, concession_type_id;
ALTER TABLE Layercake.silv_daily_count_detail ADD CONSTRAINT pk_silv_daily_count_detail PRIMARY KEY CLUSTERED
    ([date], region, country_id, gender_id, grade, membership_status_id);

INSERT INTO Layercake.silv_daily_count_detail
    ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
     active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
       active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
FROM #mig0030_detail_old_grain;

-- Remove the marker and empty the whole snapshot, so the restored MOD-026 load takes its full
-- path once. The attribute snapshot goes first: its rows reference the snapshot headers.
DELETE FROM Layercake.etl_daily_count_input_basis WHERE input_name = 'detail_grain_restatement' AND input_key = N'';
IF OBJECT_ID(N'Layercake.etl_daily_count_applied_attribute', N'U') IS NOT NULL
    DELETE FROM Layercake.etl_daily_count_applied_attribute;
DELETE FROM Layercake.etl_daily_count_applied_state_range;
DELETE FROM Layercake.etl_daily_count_applied_payment;
DELETE FROM Layercake.etl_daily_count_applied_event;
DELETE FROM Layercake.etl_daily_count_applied_contact;
