-- MIG-0001 (up): load audit framework, not used by this project. Its loads log through its own procedures
-- (conventions.load_logging in config/project.yaml) and it creates no schema, so this migration creates nothing
-- and only records itself: migration numbers stay the same in every project.
-- SQLCMD mode with -v CommitHash=<git sha>. Idempotent: safe to run again.
:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
IF Layercake.fn_migration_is_applied('MIG-0001') = 0
    EXEC Layercake.usp_record_migration @migration_id = 'MIG-0001', @description = N'Load audit framework (not used)',
         @direction = 'up', @script_name = N'MIG-0001_bootstrap_audit-tables.up.sql', @commit_hash = '$(CommitHash)';
GO
