-- REQ-026 / ADR-013: the three segment ids join the grain, -2 on the rows already stored, as on
-- silv_daily_count_detail. The default only fills those rows and is dropped again.
ALTER TABLE Layercake.etl_daily_count_cell_contacts ADD
    payment_method_id  int NOT NULL CONSTRAINT DF_Layercake_etl_daily_count_cell_contacts_payment_method_id DEFAULT -2,
    payer_type_id      int NOT NULL CONSTRAINT DF_Layercake_etl_daily_count_cell_contacts_payer_type_id DEFAULT -2,
    concession_type_id int NOT NULL CONSTRAINT DF_Layercake_etl_daily_count_cell_contacts_concession_type_id DEFAULT -2;
ALTER TABLE Layercake.etl_daily_count_cell_contacts DROP CONSTRAINT DF_Layercake_etl_daily_count_cell_contacts_payment_method_id;
ALTER TABLE Layercake.etl_daily_count_cell_contacts DROP CONSTRAINT DF_Layercake_etl_daily_count_cell_contacts_payer_type_id;
ALTER TABLE Layercake.etl_daily_count_cell_contacts DROP CONSTRAINT DF_Layercake_etl_daily_count_cell_contacts_concession_type_id;
ALTER TABLE Layercake.etl_daily_count_cell_contacts DROP CONSTRAINT PK_Layercake_etl_daily_count_cell_contacts;
ALTER TABLE Layercake.etl_daily_count_cell_contacts ADD CONSTRAINT PK_Layercake_etl_daily_count_cell_contacts PRIMARY KEY CLUSTERED
    ([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id);
