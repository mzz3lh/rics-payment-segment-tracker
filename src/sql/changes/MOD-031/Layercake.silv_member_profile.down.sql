-- Own country back in country_id before the columns go (EXEC: names a column this script drops).
EXEC (N'UPDATE Layercake.silv_member_profile SET country_id = contact_country_id;');
ALTER TABLE Layercake.silv_member_profile DROP COLUMN local_group_id, contact_country_id;
