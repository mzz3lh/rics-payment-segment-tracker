-- REQ-026 / RULE-162: the cell's three segment ids. Every row written before deployment keeps its
-- figures, run_id, load_id and written_at and takes -2 Not applicable, because the segment was not
-- recorded then. The default only fills those rows and is dropped again.
ALTER TABLE Layercake.silv_daily_count_adjustment ADD
    payment_method_id  int NOT NULL CONSTRAINT DF_Layercake_silv_daily_count_adjustment_payment_method_id DEFAULT -2,
    payer_type_id      int NOT NULL CONSTRAINT DF_Layercake_silv_daily_count_adjustment_payer_type_id DEFAULT -2,
    concession_type_id int NOT NULL CONSTRAINT DF_Layercake_silv_daily_count_adjustment_concession_type_id DEFAULT -2;
ALTER TABLE Layercake.silv_daily_count_adjustment DROP CONSTRAINT DF_Layercake_silv_daily_count_adjustment_payment_method_id;
ALTER TABLE Layercake.silv_daily_count_adjustment DROP CONSTRAINT DF_Layercake_silv_daily_count_adjustment_payer_type_id;
ALTER TABLE Layercake.silv_daily_count_adjustment DROP CONSTRAINT DF_Layercake_silv_daily_count_adjustment_concession_type_id;
ALTER TABLE Layercake.silv_daily_count_adjustment
    DROP CONSTRAINT UQ_Layercake_silv_daily_count_adjustment_run_id_date_region_country_id_gender_id_grade_membership_status_id;
ALTER TABLE Layercake.silv_daily_count_adjustment ADD CONSTRAINT UQ_Layercake_silv_daily_count_adjustment_run_id_cell
    UNIQUE (run_id, [date], region, country_id, gender_id, grade, membership_status_id,
            payment_method_id, payer_type_id, concession_type_id);
DROP INDEX IX_silv_daily_count_adjustment_date_written_at ON Layercake.silv_daily_count_adjustment;
CREATE INDEX IX_silv_daily_count_adjustment_date_written_at
    ON Layercake.silv_daily_count_adjustment ([date], written_at)
    INCLUDE (region, country_id, gender_id, grade, membership_status_id,
             payment_method_id, payer_type_id, concession_type_id,
             active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
             event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);
