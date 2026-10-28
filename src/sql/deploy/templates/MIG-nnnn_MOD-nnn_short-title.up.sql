-- MIG-nnnn (up) for MOD-nnn: <what this migration changes>. Requirement IDs: REQ-nnn.
-- Copy this file and its .down.sql partner; replace every MIG-nnnn / MOD-nnn / text placeholder.
-- Run in SQLCMD mode with -v CommitHash=<git sha>. Safe to run twice: a second run does nothing.
:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
IF Layercake.fn_migration_is_applied('MIG-nnnn') = 1
BEGIN
    PRINT 'MIG-nnnn already applied; skipping.';
    SET NOEXEC ON;
END
GO
BEGIN TRANSACTION;
GO
-- ===== changes start =====
-- Tables: guarded CREATE / ALTER. Code objects: CREATE OR ALTER (each in its own batch).
-- ===== changes end =====
GO
EXEC Layercake.usp_record_migration @migration_id = 'MIG-nnnn', @module_id = 'MOD-nnn',
     @description = N'<what this migration changes>', @direction = 'up',
     @script_name = N'MIG-nnnn_MOD-nnn_short-title.up.sql', @commit_hash = '$(CommitHash)';
COMMIT;
GO
SET NOEXEC OFF;
GO
