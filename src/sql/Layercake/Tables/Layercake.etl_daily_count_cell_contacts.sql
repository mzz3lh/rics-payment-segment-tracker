-- For each loaded date and silv_daily_count_detail cell, the number of contacts sitting in the
-- cell that day (ADR-011, Q-059): an eighth additive figure kept like the seven measures, so the
-- changed-contacts path can recognise a cell that empties. Rows only for counts above 0.
-- MOD-028 (REQ-026): the three segment ids join the grain, added by change script with -2 on the
-- rows stored before deployment.
-- MOD-031 (REQ-027): local_group_id, contact_country_id and contact_region join the grain, added
-- by change script with 0, country_id and region on the rows stored before deployment.
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
    payment_method_id    int              NOT NULL,
    payer_type_id        int              NOT NULL,
    concession_type_id   int              NOT NULL,
    local_group_id       int              NOT NULL,
    contact_country_id   int              NOT NULL,
    contact_region       varchar(12)      NOT NULL,
    CONSTRAINT PK_Layercake_etl_daily_count_cell_contacts
        PRIMARY KEY CLUSTERED ([date], region, country_id, gender_id, grade, membership_status_id,
                               payment_method_id, payer_type_id, concession_type_id,
                               local_group_id, contact_country_id, contact_region),
    CONSTRAINT CK_Layercake_etl_daily_count_cell_contacts_contact_count CHECK (contact_count > 0)
);
