-- HUMAN-RUN. Grants for MOD-030: review, replace any <placeholder> role, and run on each environment after the module's migration.
-- Not part of the migrations; agents hold no grant rights.
GRANT SELECT ON Layercake.dim_local_group TO [<reporting_role>];
