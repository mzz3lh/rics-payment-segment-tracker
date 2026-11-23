-- REQ-026 / ADR-013: the three segment ids join the grain. Every stored row takes -2 Not
-- applicable, so every figure stays where it is until the first run restates it. The default
-- only fills the rows already stored and is dropped again: the load always writes the ids.
ALTER TABLE Layercake.silv_daily_count_detail ADD
    payment_method_id  int NOT NULL CONSTRAINT DF_Layercake_silv_daily_count_detail_payment_method_id DEFAULT -2,
    payer_type_id      int NOT NULL CONSTRAINT DF_Layercake_silv_daily_count_detail_payer_type_id DEFAULT -2,
    concession_type_id int NOT NULL CONSTRAINT DF_Layercake_silv_daily_count_detail_concession_type_id DEFAULT -2;
ALTER TABLE Layercake.silv_daily_count_detail DROP CONSTRAINT DF_Layercake_silv_daily_count_detail_payment_method_id;
ALTER TABLE Layercake.silv_daily_count_detail DROP CONSTRAINT DF_Layercake_silv_daily_count_detail_payer_type_id;
ALTER TABLE Layercake.silv_daily_count_detail DROP CONSTRAINT DF_Layercake_silv_daily_count_detail_concession_type_id;
ALTER TABLE Layercake.silv_daily_count_detail DROP CONSTRAINT pk_silv_daily_count_detail;
ALTER TABLE Layercake.silv_daily_count_detail ADD CONSTRAINT pk_silv_daily_count_detail PRIMARY KEY CLUSTERED
    ([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id);

-- ADR-013: empty the changed-contacts snapshot and write the restatement marker, so the first
-- daily count run after deployment takes the full path from 2020-10-01, restates every loaded
-- date at the segment grain and works out that run's adjustments at the old grain.
DELETE FROM Layercake.etl_daily_count_applied_state_range;
DELETE FROM Layercake.etl_daily_count_applied_payment;
DELETE FROM Layercake.etl_daily_count_applied_event;
DELETE FROM Layercake.etl_daily_count_applied_contact;
INSERT INTO Layercake.etl_daily_count_input_basis
    (input_name, input_key, input_fingerprint, earliest_affected_date, run_id, updated_at)
SELECT 'detail_grain_restatement', N'', 0x00, '20201001', '00000000-0000-0000-0000-000000000000', SYSDATETIME()
WHERE NOT EXISTS (SELECT 1 FROM Layercake.etl_daily_count_input_basis
                  WHERE input_name = 'detail_grain_restatement' AND input_key = N'');
