-- HUMAN-RUN. Grants for MOD-015: review, replace any <placeholder> role, and run on each environment after the module's migration.
-- Not part of the migrations; agents hold no grant rights.
GRANT EXECUTE ON Layercake.usp_report_payment_method_coverage TO [<analyst_role>];
GRANT EXECUTE ON Layercake.usp_report_invoiced_subtotal_coverage TO [<analyst_role>];
GRANT EXECUTE ON Layercake.usp_report_direct_debit_share TO [<analyst_role>];
GRANT EXECUTE ON Layercake.usp_report_last_full_year_totals TO [<analyst_role>];
