-- REQ-027 (RULE-176, RULE-179): the local group, the own country and its region join the grain.
-- Every stored row takes local_group_id 0, contact_country_id equal to its country_id and
-- contact_region equal to its region, so every figure stays where it is until the first run
-- restates it. The defaults only fill those rows and are dropped again.
ALTER TABLE Layercake.silv_daily_count_detail ADD
    local_group_id     int         NOT NULL CONSTRAINT DF_Layercake_silv_daily_count_detail_local_group_id DEFAULT 0,
    contact_country_id int         NOT NULL CONSTRAINT DF_Layercake_silv_daily_count_detail_contact_country_id DEFAULT 0,
    contact_region     varchar(12) NOT NULL CONSTRAINT DF_Layercake_silv_daily_count_detail_contact_region DEFAULT '';
ALTER TABLE Layercake.silv_daily_count_detail DROP CONSTRAINT DF_Layercake_silv_daily_count_detail_local_group_id;
ALTER TABLE Layercake.silv_daily_count_detail DROP CONSTRAINT DF_Layercake_silv_daily_count_detail_contact_country_id;
ALTER TABLE Layercake.silv_daily_count_detail DROP CONSTRAINT DF_Layercake_silv_daily_count_detail_contact_region;
-- EXEC: the columns are added in this same batch, which SQL Server compiles before the ALTER runs.
EXEC (N'UPDATE Layercake.silv_daily_count_detail SET contact_country_id = country_id, contact_region = region;');
ALTER TABLE Layercake.silv_daily_count_detail DROP CONSTRAINT pk_silv_daily_count_detail;
ALTER TABLE Layercake.silv_daily_count_detail ADD CONSTRAINT pk_silv_daily_count_detail PRIMARY KEY CLUSTERED
    ([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
     local_group_id, contact_country_id, contact_region);

-- Restatement by local group: empty the changed-contacts snapshot (child tables first) and write
-- the marker, so the first daily count run after deployment takes the full path from 2020-10-01,
-- restates every loaded date at the local group values and works out that run's adjustments at
-- the own-country grain.
DELETE FROM Layercake.etl_daily_count_applied_attribute;
DELETE FROM Layercake.etl_daily_count_applied_state_range;
DELETE FROM Layercake.etl_daily_count_applied_payment;
DELETE FROM Layercake.etl_daily_count_applied_event;
DELETE FROM Layercake.etl_daily_count_applied_contact;
INSERT INTO Layercake.etl_daily_count_input_basis
    (input_name, input_key, input_fingerprint, earliest_affected_date, run_id, updated_at)
SELECT 'local_group_restatement', N'', 0x00, '20201001', '00000000-0000-0000-0000-000000000000', SYSDATETIME()
WHERE NOT EXISTS (SELECT 1 FROM Layercake.etl_daily_count_input_basis
                  WHERE input_name = 'local_group_restatement' AND input_key = N'');
