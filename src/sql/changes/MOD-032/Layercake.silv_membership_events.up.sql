-- REQ-027 (RULE-172, RULE-175): the local group and the member's own country. Rows stored
-- before deployment take local_group_id 0 and contact_country_id equal to their country_id
-- until the next run. The defaults only fill those rows and are dropped again: the events
-- load always writes both columns.
ALTER TABLE Layercake.silv_membership_events ADD
    local_group_id     int NOT NULL CONSTRAINT DF_Layercake_silv_membership_events_local_group_id DEFAULT 0,
    contact_country_id int NOT NULL CONSTRAINT DF_Layercake_silv_membership_events_contact_country_id DEFAULT 0;
ALTER TABLE Layercake.silv_membership_events DROP CONSTRAINT DF_Layercake_silv_membership_events_local_group_id;
ALTER TABLE Layercake.silv_membership_events DROP CONSTRAINT DF_Layercake_silv_membership_events_contact_country_id;
-- A static statement run through EXEC because the column it fills is added in this same batch,
-- which SQL Server compiles before the ALTER runs.
EXEC (N'UPDATE Layercake.silv_membership_events SET contact_country_id = country_id;');
