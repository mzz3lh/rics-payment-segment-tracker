-- Q-038: Subs.vwSubsMemberStatuses cannot supply these; no load has written them, so they hold only nulls.
ALTER TABLE Layercake.silv_membership_events DROP COLUMN
    subs_amount,
    fee_amount,
    invoiced_subtotal,
    credited_amount,
    currency_id,
    fee_amount_gbp,
    credited_amount_gbp,
    net_amount_gbp;
