-- The contact's Layercake.silv_payment_events rows as last applied (ADR-011), limited to the
-- columns the daily derivation reads, keyed as the source is. Replaced per contact together
-- with etl_daily_count_applied_contact.
CREATE TABLE Layercake.etl_daily_count_applied_payment
(
    contact_no       nvarchar(200) NOT NULL,
    campaign_year    int           NOT NULL,
    renewal_date_adj date          NULL,
    CONSTRAINT PK_Layercake_etl_daily_count_applied_payment PRIMARY KEY CLUSTERED (contact_no, campaign_year),
    CONSTRAINT FK_Layercake_etl_daily_count_applied_payment_etl_daily_count_applied_contact
        FOREIGN KEY (contact_no) REFERENCES Layercake.etl_daily_count_applied_contact (contact_no)
);
