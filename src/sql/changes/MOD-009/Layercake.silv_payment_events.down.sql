-- Restores the Phase 1 column and default; existing rows take the default N'Individual',
-- the only value the Phase 1 load ever left in it.
alter table Layercake.silv_payment_events
    add payment_source nvarchar(64) not null
        constraint df_silv_payment_events_src default N'Individual';
