-- The daily count's silver inputs as last applied (ADR-007). Written only by
-- Layercake.usp_load_silv_daily_count, after every corrected date of a run has committed.
--   input_name 'contact'       one row per contact, input_key = contact_no
--   input_name '<table name>'  one row per reference table the derivation reads, input_key N''
CREATE TABLE Layercake.etl_daily_count_input_basis
(
    input_name             varchar(64)      NOT NULL,
    input_key              nvarchar(200)    NOT NULL,
    input_fingerprint      varbinary(32)    NOT NULL,
    earliest_affected_date date             NOT NULL,
    run_id                 uniqueidentifier NOT NULL,
    updated_at             datetime2(3)     NOT NULL,
    CONSTRAINT PK_Layercake_etl_daily_count_input_basis PRIMARY KEY CLUSTERED (input_name, input_key)
);
