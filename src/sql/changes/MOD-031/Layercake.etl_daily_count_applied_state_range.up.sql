-- REQ-027: the range's own-country region as last applied. The migration empties the snapshot
-- (silv_daily_count_detail change); the default only covers rows still there if this change runs
-- first, and is dropped again.
ALTER TABLE Layercake.etl_daily_count_applied_state_range ADD
    contact_region varchar(12) NOT NULL CONSTRAINT DF_Layercake_etl_daily_count_applied_state_range_contact_region DEFAULT '';
ALTER TABLE Layercake.etl_daily_count_applied_state_range
    DROP CONSTRAINT DF_Layercake_etl_daily_count_applied_state_range_contact_region;
