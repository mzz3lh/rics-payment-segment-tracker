-- HUMAN-RUN. Grants for MOD-013: review, replace any <placeholder> role, and run on each environment after the module's migration.
-- Not part of the migrations; agents hold no grant rights.
GRANT EXECUTE ON Layercake.usp_report_retirement_comparison TO [<analyst_role>];
