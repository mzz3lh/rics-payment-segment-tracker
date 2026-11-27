-- REQ-027 / RULE-179: the cell's local group, own country and its region. Every row written
-- before deployment keeps its figures, run_id, load_id and written_at, takes local_group_id -2
-- Not applicable (the local group was not recorded then; MOD-030's reserved row), and its own
-- country_id and region as contact_country_id and contact_region. The defaults only fill those
-- rows and are dropped again.
ALTER TABLE Layercake.silv_daily_count_adjustment ADD
    local_group_id     int         NOT NULL CONSTRAINT DF_Layercake_silv_daily_count_adjustment_local_group_id DEFAULT -2,
    contact_country_id int         NOT NULL CONSTRAINT DF_Layercake_silv_daily_count_adjustment_contact_country_id DEFAULT 0,
    contact_region     varchar(12) NOT NULL CONSTRAINT DF_Layercake_silv_daily_count_adjustment_contact_region DEFAULT '';
ALTER TABLE Layercake.silv_daily_count_adjustment DROP CONSTRAINT DF_Layercake_silv_daily_count_adjustment_local_group_id;
ALTER TABLE Layercake.silv_daily_count_adjustment DROP CONSTRAINT DF_Layercake_silv_daily_count_adjustment_contact_country_id;
ALTER TABLE Layercake.silv_daily_count_adjustment DROP CONSTRAINT DF_Layercake_silv_daily_count_adjustment_contact_region;
-- EXEC: the columns are added in this same batch, which SQL Server compiles before the ALTER runs.
EXEC (N'UPDATE Layercake.silv_daily_count_adjustment SET contact_country_id = country_id, contact_region = region;');
ALTER TABLE Layercake.silv_daily_count_adjustment DROP CONSTRAINT UQ_Layercake_silv_daily_count_adjustment_run_id_cell;
ALTER TABLE Layercake.silv_daily_count_adjustment ADD CONSTRAINT UQ_Layercake_silv_daily_count_adjustment_run_id_cell
    UNIQUE (run_id, [date], region, country_id, gender_id, grade, membership_status_id,
            payment_method_id, payer_type_id, concession_type_id, local_group_id, contact_country_id, contact_region);
DROP INDEX IX_silv_daily_count_adjustment_date_written_at ON Layercake.silv_daily_count_adjustment;
CREATE INDEX IX_silv_daily_count_adjustment_date_written_at
    ON Layercake.silv_daily_count_adjustment ([date], written_at)
    INCLUDE (region, country_id, gender_id, grade, membership_status_id,
             payment_method_id, payer_type_id, concession_type_id,
             local_group_id, contact_country_id, contact_region,
             active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
             event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);
