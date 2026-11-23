-- REQ-026 / RULE-164: the three segment keys join the star grain, -2 Not applicable on the rows
-- already stored until the first run's sync splits them (ADR-013). The default only fills those
-- rows and is dropped again. No foreign keys; id stays bigint.
ALTER TABLE Layercake.fact_daily_member_count_detail ADD
    payment_method_id  int NOT NULL CONSTRAINT DF_Layercake_fact_daily_member_count_detail_payment_method_id DEFAULT -2,
    payer_type_id      int NOT NULL CONSTRAINT DF_Layercake_fact_daily_member_count_detail_payer_type_id DEFAULT -2,
    concession_type_id int NOT NULL CONSTRAINT DF_Layercake_fact_daily_member_count_detail_concession_type_id DEFAULT -2;
ALTER TABLE Layercake.fact_daily_member_count_detail DROP CONSTRAINT DF_Layercake_fact_daily_member_count_detail_payment_method_id;
ALTER TABLE Layercake.fact_daily_member_count_detail DROP CONSTRAINT DF_Layercake_fact_daily_member_count_detail_payer_type_id;
ALTER TABLE Layercake.fact_daily_member_count_detail DROP CONSTRAINT DF_Layercake_fact_daily_member_count_detail_concession_type_id;
DROP INDEX cx_fact_daily_member_count_detail ON Layercake.fact_daily_member_count_detail;
CREATE UNIQUE CLUSTERED INDEX cx_fact_daily_member_count_detail
    ON Layercake.fact_daily_member_count_detail
    (date_id, country_id, gender_id, membership_grade_id, membership_status_id,
     payment_method_id, payer_type_id, concession_type_id);
