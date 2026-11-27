-- REQ-027: the three local group columns join the grain, with 0, country_id and region on the
-- rows already stored, as on silv_daily_count_detail. The defaults only fill those rows.
ALTER TABLE Layercake.etl_daily_count_cell_contacts ADD
    local_group_id     int         NOT NULL CONSTRAINT DF_Layercake_etl_daily_count_cell_contacts_local_group_id DEFAULT 0,
    contact_country_id int         NOT NULL CONSTRAINT DF_Layercake_etl_daily_count_cell_contacts_contact_country_id DEFAULT 0,
    contact_region     varchar(12) NOT NULL CONSTRAINT DF_Layercake_etl_daily_count_cell_contacts_contact_region DEFAULT '';
ALTER TABLE Layercake.etl_daily_count_cell_contacts DROP CONSTRAINT DF_Layercake_etl_daily_count_cell_contacts_local_group_id;
ALTER TABLE Layercake.etl_daily_count_cell_contacts DROP CONSTRAINT DF_Layercake_etl_daily_count_cell_contacts_contact_country_id;
ALTER TABLE Layercake.etl_daily_count_cell_contacts DROP CONSTRAINT DF_Layercake_etl_daily_count_cell_contacts_contact_region;
-- EXEC: the columns are added in this same batch, which SQL Server compiles before the ALTER runs.
EXEC (N'UPDATE Layercake.etl_daily_count_cell_contacts SET contact_country_id = country_id, contact_region = region;');
ALTER TABLE Layercake.etl_daily_count_cell_contacts DROP CONSTRAINT PK_Layercake_etl_daily_count_cell_contacts;
ALTER TABLE Layercake.etl_daily_count_cell_contacts ADD CONSTRAINT PK_Layercake_etl_daily_count_cell_contacts PRIMARY KEY CLUSTERED
    ([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
     local_group_id, contact_country_id, contact_region);
