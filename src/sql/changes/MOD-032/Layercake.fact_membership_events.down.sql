-- Put the own country back in country_id before the columns go, so the restored Phase 1 gold
-- load and Power BI see the Phase 1 values straight away (EXEC: the statement names a column this
-- script drops, so a rerun after the drop must not compile it).
EXEC (N'UPDATE Layercake.fact_membership_events SET country_id = contact_country_id;');
ALTER TABLE Layercake.fact_membership_events DROP COLUMN local_group_id, contact_country_id;
