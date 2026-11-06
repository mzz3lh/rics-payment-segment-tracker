-- MOD-009: retire payment_source (RULE-027; drop approved by Mike under Q-035 and Q-024).
-- The Phase 1 load never names the column, so it only ever held its default.
alter table Layercake.silv_payment_events drop constraint df_silv_payment_events_src;
alter table Layercake.silv_payment_events drop column payment_source;
