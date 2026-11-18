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
    CONSTRAINT PK_Layercake_silv_daily_count_adjustment PRIMARY KEY CLUSTERED (adjustment_id),
    -- One row per run and cell (REQ-019).
    CONSTRAINT UQ_Layercake_silv_daily_count_adjustment_run_id_date_region_country_id_gender_id_grade_membership_status_id
        UNIQUE (run_id, [date], region, country_id, gender_id, grade, membership_status_id),
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
             active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
             event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);
