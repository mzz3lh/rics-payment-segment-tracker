CREATE TABLE Layercake.silv_daily_count_adjustment
(
    adjustment_id                  bigint           IDENTITY(1, 1) NOT NULL,
    run_id                         uniqueidentifier NOT NULL,
    load_id                        bigint           NOT NULL,
    written_at                     datetime2(3)     NOT NULL,
    [date]                         date             NOT NULL,
    region                         varchar(12)      NOT NULL,
    country_id                     int              NOT NULL,
    gender_id                      int              NOT NULL,
    grade                          varchar(12)      NOT NULL,
    membership_status_id           int              NOT NULL,
    active_count_change            int              NOT NULL,
    paid_count_change              int              NOT NULL,
    paid_count_event_change        int              NOT NULL,
    event_join_count_change        int              NOT NULL,
    event_renewal_count_change     int              NOT NULL,
    event_readmission_count_change int              NOT NULL,
    event_lapse_count_change       int              NOT NULL,
    -- MOD-028 (REQ-026, RULE-162): the cell's segment ids, added by change script. Rows written
    -- before deployment, and by the restating run, hold -2 Not applicable (ADR-013, Q-061).
    payment_method_id              int              NOT NULL,
    payer_type_id                  int              NOT NULL,
    concession_type_id             int              NOT NULL,
    -- MOD-031 (REQ-027, RULE-176, RULE-179): the cell's local group, own country and its region,
    -- added by change script. Rows written before deployment hold -2 Not applicable in
    -- local_group_id and their own country_id and region; the restating run writes its rows at
    -- the own-country grain with -2.
    local_group_id                 int              NOT NULL,
    contact_country_id             int              NOT NULL,
    contact_region                 varchar(12)      NOT NULL,
    CONSTRAINT PK_Layercake_silv_daily_count_adjustment PRIMARY KEY CLUSTERED (adjustment_id),
    -- One row per run and cell (REQ-019). The name lists the cell as 'cell': the twelve grain
    -- columns would take it past SQL Server's 128-character limit.
    CONSTRAINT UQ_Layercake_silv_daily_count_adjustment_run_id_cell
        UNIQUE (run_id, [date], region, country_id, gender_id, grade, membership_status_id,
                payment_method_id, payer_type_id, concession_type_id,
                local_group_id, contact_country_id, contact_region),
    -- A row records a change: an unchanged cell writes no row, so the review view never shows a 0 change.
    CONSTRAINT CK_Layercake_silv_daily_count_adjustment_any_change CHECK (
        active_count_change <> 0
        OR paid_count_change <> 0
        OR paid_count_event_change <> 0
        OR event_join_count_change <> 0
        OR event_renewal_count_change <> 0
        OR event_readmission_count_change <> 0
        OR event_lapse_count_change <> 0)
);

-- The as-known-at functions read a date range and the changes written after T.
CREATE INDEX IX_silv_daily_count_adjustment_date_written_at
    ON Layercake.silv_daily_count_adjustment ([date], written_at)
    INCLUDE (region, country_id, gender_id, grade, membership_status_id,
             payment_method_id, payer_type_id, concession_type_id,
             local_group_id, contact_country_id, contact_region,
             active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
             event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);
