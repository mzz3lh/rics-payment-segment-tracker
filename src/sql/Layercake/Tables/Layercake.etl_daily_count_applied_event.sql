-- The contact's Layercake.silv_membership_events rows (Join, Renewal, Readmission, Lapse) as
-- last applied (ADR-011), limited to the columns the daily derivation reads. event_id is left
-- out: it only breaks ties that cannot change a figure. Every source row is kept. Replaced per
-- contact together with etl_daily_count_applied_contact.
CREATE TABLE Layercake.etl_daily_count_applied_event
(
    applied_row_id bigint IDENTITY(1, 1) NOT NULL,
    contact_no     nvarchar(200)         NOT NULL,
    campaign_year  int                   NOT NULL,
    event_type     varchar(20)           NOT NULL,
    event_date     date                  NOT NULL,
    CONSTRAINT PK_Layercake_etl_daily_count_applied_event PRIMARY KEY NONCLUSTERED (applied_row_id),
    CONSTRAINT FK_Layercake_etl_daily_count_applied_event_etl_daily_count_applied_contact
        FOREIGN KEY (contact_no) REFERENCES Layercake.etl_daily_count_applied_contact (contact_no)
);

CREATE CLUSTERED INDEX IX_etl_daily_count_applied_event_contact_no
    ON Layercake.etl_daily_count_applied_event (contact_no);
