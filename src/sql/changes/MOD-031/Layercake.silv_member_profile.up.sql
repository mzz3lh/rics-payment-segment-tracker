-- REQ-027: copied from silv_member_base like country_id. Rows stored before deployment take 0
-- and their country_id until the next run. The defaults only fill those rows and are dropped.
ALTER TABLE Layercake.silv_member_profile ADD
    local_group_id     int NOT NULL CONSTRAINT DF_Layercake_silv_member_profile_local_group_id DEFAULT 0,
    contact_country_id int NOT NULL CONSTRAINT DF_Layercake_silv_member_profile_contact_country_id DEFAULT 0;
ALTER TABLE Layercake.silv_member_profile DROP CONSTRAINT DF_Layercake_silv_member_profile_local_group_id;
ALTER TABLE Layercake.silv_member_profile DROP CONSTRAINT DF_Layercake_silv_member_profile_contact_country_id;
-- EXEC: the column is added in this same batch, which SQL Server compiles before the ALTER runs.
EXEC (N'UPDATE Layercake.silv_member_profile SET contact_country_id = country_id;');
