-- MIG-nnnn (down) for MOD-nnn: reverses MIG-nnnn_MOD-nnn_short-title.up.sql exactly.
-- Rules (PROJECT_STANDARDS.md 3.1):
--  * Returns the schema to the state before the up script ran.
--  * Never silently destroys data: a table with rows is renamed to <Table>_rolledback_MIGnnnn,
--    unless an ADR records that the data may be dropped.
--  * Refuses to run while any later migration is still applied (rollback in reverse order).
-- Run in SQLCMD mode with -v CommitHash=<git sha>. Safe to run twice.
:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
IF Layercake.fn_migration_is_applied('MIG-nnnn') = 0
BEGIN
    PRINT 'MIG-nnnn not applied; nothing to roll back.';
    SET NOEXEC ON;
END
GO
-- Rollbacks run in reverse order: refuse while any later migration is still applied.
IF EXISTS (SELECT 1 FROM Layercake.vw_migration_state WHERE migration_id > 'MIG-nnnn' AND current_state = 'up')
    THROW 50011, 'Roll back later migrations before MIG-nnnn.', 1;
GO
BEGIN TRANSACTION;
GO
-- ===== reversal start (reverse order of the up script) =====
-- ===== reversal end =====
GO
EXEC Layercake.usp_record_migration @migration_id = 'MIG-nnnn', @module_id = 'MOD-nnn',
     @description = N'Rollback of MIG-nnnn', @direction = 'down',
     @script_name = N'MIG-nnnn_MOD-nnn_short-title.down.sql', @commit_hash = '$(CommitHash)';
COMMIT;
GO
SET NOEXEC OFF;
GO
