-- HUMAN-RUN, once, on a database that ALREADY holds the existing solution (a client environment), after
-- MIG-0000 and MIG-0001. Records MIG-0002 as applied without running it, so module migrations
-- (MIG-0003 onwards) apply on top. Never run it on a blank database: run MIG-0002_bootstrap_phase1-layercake.up.sql there instead.
:on error exit
SET NOCOUNT ON;
GO
IF OBJECT_ID(N'Layercake.brnz_contact', N'U') IS NULL
    THROW 50014, 'This database does not hold the existing solution (Layercake.brnz_contact is missing): run the baseline migration instead.', 1;
GO
IF Layercake.fn_migration_is_applied('MIG-0002') = 0
    EXEC Layercake.usp_record_migration @migration_id = 'MIG-0002', @module_id = NULL,
         @description = N'Baseline adopted: existing solution (phase1-layercake)', @direction = 'up',
         @script_name = N'MIG-0002_bootstrap_phase1-layercake.up.sql', @commit_hash = '$(CommitHash)';
GO
