-- For each loaded date and silv_daily_count_detail cell, the number of contacts sitting in the
-- cell that day (ADR-011, Q-059): an eighth additive figure kept like the seven measures, so the
-- changed-contacts path can recognise a cell that empties. Rows only for counts above 0.
CREATE TABLE Layercake.etl_daily_count_cell_contacts
(
    [date]               date             NOT NULL,
    region               varchar(12)      NOT NULL,
    country_id           int              NOT NULL,
    gender_id            int              NOT NULL,
    grade                varchar(12)      NOT NULL,
    membership_status_id int              NOT NULL,
    contact_count        int              NOT NULL,
    run_id               uniqueidentifier NOT NULL,
    updated_at           datetime2(3)     NOT NULL,
    CONSTRAINT PK_Layercake_etl_daily_count_cell_contacts
        PRIMARY KEY CLUSTERED ([date], region, country_id, gender_id, grade, membership_status_id),
    CONSTRAINT CK_Layercake_etl_daily_count_cell_contacts_contact_count CHECK (contact_count > 0)
);
