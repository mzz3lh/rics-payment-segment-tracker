-- HUMAN-RUN. Grants for MOD-014: review, replace any <placeholder> role, and run on each environment after the module's migration.
-- Not part of the migrations; agents hold no grant rights.
GRANT EXECUTE ON Layercake.usp_report_employer_scheme_coverage TO [<analyst_role>];
GRANT EXECUTE ON Layercake.usp_report_employer_source_agreement TO [<analyst_role>];
GRANT EXECUTE ON Layercake.usp_report_top_employers TO [<analyst_role>];
