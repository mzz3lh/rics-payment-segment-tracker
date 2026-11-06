/*====================================================================
    Layercake.silv_payment_events
    Silver layer - table, keys and intrinsic indexes
====================================================================*/

----------------------------------------------------
--  Layercake.silv_payment_events
--  payment_source retired by MOD-009 (RULE-027, Q-024, Q-035):
--  payer type now lives on silv_member_year_attributes.
----------------------------------------------------
create table Layercake.silv_payment_events
(
    contact_no       nvarchar(200) not null,
    campaign_year    int not null,
    payment_date     date null,          -- first cash transaction date from custtrans (informational)
    renewal_date_adj date null,          -- adjusted renewal date - always within the campaign year; drives the day-by-day paid logic
    invoice_position nvarchar(64) null,
    constraint pk_silv_payment_events primary key clustered (contact_no, campaign_year)
);
