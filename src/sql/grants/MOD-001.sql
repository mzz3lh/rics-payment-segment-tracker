-- HUMAN-RUN. Grants for MOD-001: review, replace any <placeholder> role, and run on each environment after the module's migration.
-- Not part of the migrations; agents hold no grant rights.
GRANT EXECUTE ON Layercake.usp_profile_custtrans_grain TO [<analyst_role>];
GRANT EXECUTE ON Layercake.usp_profile_corp_subscription_status TO [<analyst_role>];
