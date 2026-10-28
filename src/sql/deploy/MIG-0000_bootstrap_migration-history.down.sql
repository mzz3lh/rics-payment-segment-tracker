-- MIG-0000 (down): removes the migration framework. Refuses to run while any later
-- migration is still applied, and keeps the history by renaming it rather than dropping it.
-- The layer schemas stay: they are environment infrastructure, not part of the history framework.
-- SQLCMD mode.
:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
IF OBJECT_ID(N'Layercake.migration_history', N'U') IS NULL
BEGIN
    PRINT 'MIG-0000 not present; nothing to roll back.';
    SET NOEXEC ON;
END
GO
IF EXISTS (SELECT 1 FROM Layercake.vw_migration_state WHERE migration_id <> 'MIG-0000' AND current_state = 'up')
    THROW 50010, 'Roll back every later migration before MIG-0000.', 1;
GO
BEGIN TRANSACTION;
DROP PROCEDURE IF EXISTS Layercake.usp_record_dbt_deploy;
DROP VIEW IF EXISTS Layercake.vw_dbt_version;
IF OBJECT_ID(N'Layercake.dbt_deploy_history', N'U') IS NOT NULL
    EXEC sp_rename N'Layercake.dbt_deploy_history', N'dbt_deploy_history_rolledback_MIG0000';
DROP PROCEDURE IF EXISTS Layercake.usp_record_migration;
DROP FUNCTION IF EXISTS Layercake.fn_migration_is_applied;
DROP VIEW IF EXISTS Layercake.vw_database_version;
DROP VIEW IF EXISTS Layercake.vw_migration_state;
EXEC sp_rename N'Layercake.migration_history', N'migration_history_rolledback_MIG0000';
COMMIT;
GO
SET NOEXEC OFF;
GO
