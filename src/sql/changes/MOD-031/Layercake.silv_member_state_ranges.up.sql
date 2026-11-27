-- REQ-027 (RULE-175): the own country's region. Rows stored before deployment take their region
-- (still the own country's) until the next run. The default only fills those rows and is dropped.
ALTER TABLE Layercake.silv_member_state_ranges ADD
    contact_region varchar(12) NOT NULL CONSTRAINT DF_Layercake_silv_member_state_ranges_contact_region DEFAULT '';
ALTER TABLE Layercake.silv_member_state_ranges DROP CONSTRAINT DF_Layercake_silv_member_state_ranges_contact_region;
-- EXEC: the column is added in this same batch, which SQL Server compiles before the ALTER runs.
EXEC (N'UPDATE Layercake.silv_member_state_ranges SET contact_region = region;');
-- The natural-key index keeps covering the load's stage-vs-target comparison.
DROP INDEX ix_contact_no_valid_from_to_grade ON Layercake.silv_member_state_ranges;
CREATE UNIQUE NONCLUSTERED INDEX ix_contact_no_valid_from_to_grade
    ON Layercake.silv_member_state_ranges (contact_no, valid_from, valid_to, grade)
    INCLUDE (campaign_year_from, region, contact_region);
