-- HUMAN-RUN. Grants for MOD-021: review, replace any <placeholder> role, and run on each environment after the module's migration.
-- Not part of the migrations; agents hold no grant rights.
GRANT SELECT ON Layercake.fn_silv_daily_count_detail_as_known_at TO [<reporting_role>];
GRANT SELECT ON Layercake.fn_silv_daily_count_as_known_at TO [<reporting_role>];
GRANT SELECT ON Layercake.vw_silv_daily_count_adjustment_review TO [<reporting_role>];
