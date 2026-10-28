-- MIG-0001 (down): reverses MIG-0001, which created nothing in this project. Refuses while any later
-- migration is applied. SQLCMD mode with -v CommitHash=<git sha>. Safe to run twice.
:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
IF Layercake.fn_migration_is_applied('MIG-0001') = 0
BEGIN
    PRINT 'MIG-0001 not applied; nothing to roll back.';
    SET NOEXEC ON;
END
GO
IF EXISTS (SELECT 1 FROM Layercake.vw_migration_state WHERE migration_id > 'MIG-0001' AND current_state = 'up')
    THROW 50011, 'Roll back later migrations before MIG-0001.', 1;
GO
EXEC Layercake.usp_record_migration @migration_id = 'MIG-0001', @description = N'Rollback of MIG-0001',
     @direction = 'down', @script_name = N'MIG-0001_bootstrap_audit-tables.down.sql', @commit_hash = '$(CommitHash)';
GO
SET NOEXEC OFF;
GO
