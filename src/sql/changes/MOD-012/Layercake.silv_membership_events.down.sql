ALTER TABLE Layercake.silv_membership_events ADD
    subs_amount             decimal(19, 4) NULL,
    fee_amount              decimal(19, 4) NULL,
    invoiced_subtotal       decimal(19, 4) NULL,
    credited_amount         decimal(19, 4) NULL,
    currency_id             int          NULL,
    fee_amount_gbp          decimal(19, 4) NULL,
    credited_amount_gbp     decimal(19, 4) NULL,
    net_amount_gbp          decimal(19, 4) NULL;
