-- REQ-027 (RULE-178): the profile's local group and own country as last applied. The migration
-- empties the snapshot (silv_daily_count_detail change), so no row needs a value here.
ALTER TABLE Layercake.etl_daily_count_applied_contact ADD
    local_group_id     int NULL,
    contact_country_id int NULL;
