-- REQ-027 / RULE-176: the local group and the own country join the star grain. Rows already
-- stored take local_group_id 0 and contact_country_id equal to their country_id until the first
-- run's sync. The defaults only fill those rows and are dropped again. No foreign keys.
ALTER TABLE Layercake.fact_daily_member_count_detail ADD
    local_group_id     int NOT NULL CONSTRAINT DF_Layercake_fact_daily_member_count_detail_local_group_id DEFAULT 0,
    contact_country_id int NOT NULL CONSTRAINT DF_Layercake_fact_daily_member_count_detail_contact_country_id DEFAULT 0;
ALTER TABLE Layercake.fact_daily_member_count_detail DROP CONSTRAINT DF_Layercake_fact_daily_member_count_detail_local_group_id;
ALTER TABLE Layercake.fact_daily_member_count_detail DROP CONSTRAINT DF_Layercake_fact_daily_member_count_detail_contact_country_id;
-- EXEC: the column is added in this same batch, which SQL Server compiles before the ALTER runs.
EXEC (N'UPDATE Layercake.fact_daily_member_count_detail SET contact_country_id = country_id;');
DROP INDEX cx_fact_daily_member_count_detail ON Layercake.fact_daily_member_count_detail;
CREATE UNIQUE CLUSTERED INDEX cx_fact_daily_member_count_detail
    ON Layercake.fact_daily_member_count_detail
    (date_id, country_id, gender_id, membership_grade_id, membership_status_id,
     payment_method_id, payer_type_id, concession_type_id, local_group_id, contact_country_id);
