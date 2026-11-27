-- REQ-027 (RULE-176, AC-027-11): the local group and the member's own country join the annual
-- grain. Rows stored before deployment take local_group_id 0 and contact_country_id equal to
-- their country_id until the next run, so the widened key stays unique. The defaults only fill
-- those rows and are dropped again: the annual load always writes both columns.
ALTER TABLE Layercake.silv_annual_rate_base ADD
    local_group_id     int NOT NULL CONSTRAINT DF_Layercake_silv_annual_rate_base_local_group_id DEFAULT 0,
    contact_country_id int NOT NULL CONSTRAINT DF_Layercake_silv_annual_rate_base_contact_country_id DEFAULT 0;
ALTER TABLE Layercake.silv_annual_rate_base DROP CONSTRAINT DF_Layercake_silv_annual_rate_base_local_group_id;
ALTER TABLE Layercake.silv_annual_rate_base DROP CONSTRAINT DF_Layercake_silv_annual_rate_base_contact_country_id;
-- A static statement run through EXEC because the column it fills is added in this same batch,
-- which SQL Server compiles before the ALTER runs.
EXEC (N'UPDATE Layercake.silv_annual_rate_base SET contact_country_id = country_id;');
ALTER TABLE Layercake.silv_annual_rate_base DROP CONSTRAINT pk_silv_annual_rate_base;
ALTER TABLE Layercake.silv_annual_rate_base ADD CONSTRAINT pk_silv_annual_rate_base PRIMARY KEY CLUSTERED
    (campaign_year, grade_id, membership_status_id, country_id, gender_id, local_group_id, contact_country_id);
