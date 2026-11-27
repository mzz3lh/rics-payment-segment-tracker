-- The contact's Layercake.silv_member_state_ranges rows as last applied (ADR-011), limited to
-- the columns the daily derivation reads. Every source row is kept, zero-length and identical
-- rows included. Replaced per contact together with etl_daily_count_applied_contact.
-- MOD-031 (REQ-027): contact_region as last applied, added by change script.
CREATE TABLE Layercake.etl_daily_count_applied_state_range
(
    applied_row_id bigint IDENTITY(1, 1) NOT NULL,
    contact_no     nvarchar(200)         NOT NULL,
    valid_from     date                  NOT NULL,
    valid_to       date                  NULL,
    grade          varchar(12)           NOT NULL,
    region         varchar(12)           NOT NULL,
    contact_region varchar(12)           NOT NULL,
    CONSTRAINT PK_Layercake_etl_daily_count_applied_state_range PRIMARY KEY NONCLUSTERED (applied_row_id),
    CONSTRAINT FK_Layercake_etl_daily_count_applied_state_range_etl_daily_count_applied_contact
        FOREIGN KEY (contact_no) REFERENCES Layercake.etl_daily_count_applied_contact (contact_no)
);

CREATE CLUSTERED INDEX IX_etl_daily_count_applied_state_range_contact_no
    ON Layercake.etl_daily_count_applied_state_range (contact_no);
