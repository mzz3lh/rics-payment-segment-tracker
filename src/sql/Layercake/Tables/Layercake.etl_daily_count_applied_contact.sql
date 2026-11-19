-- Snapshot header for the daily count's changed-contacts path (ADR-011): one row per contact
-- whose daily count inputs are held as last applied, with the silv_member_profile columns the
-- derivation reads. Written only by Layercake.usp_load_silv_daily_count. A contact with a
-- 'contact' basis row in etl_daily_count_input_basis and no row here, or the reverse, makes
-- the next run take the full-recompute path.
CREATE TABLE Layercake.etl_daily_count_applied_contact
(
    contact_no      nvarchar(200)    NOT NULL,
    profile_found   bit              NOT NULL,
    country_id      int              NULL,
    gender_id       int              NULL,
    retirement_date date             NULL,
    run_id          uniqueidentifier NOT NULL,
    updated_at      datetime2(3)     NOT NULL,
    CONSTRAINT PK_Layercake_etl_daily_count_applied_contact PRIMARY KEY CLUSTERED (contact_no)
);
