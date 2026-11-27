DROP INDEX ix_contact_no_valid_from_to_grade ON Layercake.silv_member_state_ranges;
-- Own-country region back in region before the column goes (EXEC: names a column this script drops).
EXEC (N'UPDATE Layercake.silv_member_state_ranges SET region = contact_region;');
ALTER TABLE Layercake.silv_member_state_ranges DROP COLUMN contact_region;
CREATE UNIQUE NONCLUSTERED INDEX ix_contact_no_valid_from_to_grade
    ON Layercake.silv_member_state_ranges (contact_no, valid_from, valid_to, grade)
    INCLUDE (campaign_year_from, region);
