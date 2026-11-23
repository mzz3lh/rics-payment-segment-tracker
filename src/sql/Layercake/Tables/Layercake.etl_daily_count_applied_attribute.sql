-- The contact's Layercake.silv_member_year_attributes rows as last applied by the daily count
-- (AMD-007, ADR-011), limited to the columns the daily count reads: campaign_year and the three
-- segment ids. Keyed as the source is. Replaced per contact together with
-- etl_daily_count_applied_contact, so a changed contact's old contribution is worked out under the
-- segments it was last counted in (RULE-160).
CREATE TABLE Layercake.etl_daily_count_applied_attribute
(
    contact_no         nvarchar(200) NOT NULL,
    campaign_year      int           NOT NULL,
    payment_method_id  int           NOT NULL,
    payer_type_id      int           NOT NULL,
    concession_type_id int           NOT NULL,
    CONSTRAINT PK_Layercake_etl_daily_count_applied_attribute PRIMARY KEY CLUSTERED (contact_no, campaign_year),
    CONSTRAINT FK_Layercake_etl_daily_count_applied_attribute_etl_daily_count_applied_contact
        FOREIGN KEY (contact_no) REFERENCES Layercake.etl_daily_count_applied_contact (contact_no)
);
