-- MIG-0000 (up): migration framework. Creates the migration history table, the database version views
-- and the helper objects every later migration uses, in schemas that already exist.
-- Run once per database (RPST_Dev, RPST_Test, and any later environment) before any other migration.
-- SQLCMD mode. Idempotent: safe to run again.
:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
-- This project creates no schema (create_schemas: false in config/project.yaml): every schema it uses
-- must already exist. A database administrator creates them; in dev and test,
-- src/sql/setup/00_create_databases.sql does.
IF SCHEMA_ID(N'Layercake') IS NULL THROW 50015, 'Schema Layercake does not exist: a database administrator creates it before the first migration.', 1;
GO
IF OBJECT_ID(N'Layercake.migration_history', N'U') IS NULL
CREATE TABLE Layercake.migration_history (
    migration_history_id int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Layercake_migration_history PRIMARY KEY,
    migration_id        varchar(10)    NOT NULL,
    module_id           varchar(10)    NULL,
    description        nvarchar(200)  NOT NULL,
    direction          varchar(4)     NOT NULL CONSTRAINT CK_Layercake_migration_history_direction CHECK (direction IN ('up', 'down')),
    script_name         nvarchar(260)  NOT NULL,
    commit_hash         varchar(40)    NULL,
    applied_at          datetime2(3)   NOT NULL CONSTRAINT DF_Layercake_migration_history_applied_at DEFAULT (SYSUTCDATETIME()),
    applied_by          sysname        NOT NULL CONSTRAINT DF_Layercake_migration_history_applied_by DEFAULT (ORIGINAL_LOGIN()),
    CONSTRAINT CK_Layercake_migration_history_migration_id CHECK (migration_id LIKE 'MIG-[0-9][0-9][0-9][0-9]')
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_migration_history_migration_id_applied_at')
CREATE INDEX IX_migration_history_migration_id_applied_at ON Layercake.migration_history (migration_id, migration_history_id DESC);
GO
-- Latest state of every migration: applied ('up') or rolled back ('down').
CREATE OR ALTER VIEW Layercake.vw_migration_state
AS
SELECT h.migration_id, h.module_id, h.description, h.direction AS current_state, h.script_name,
       h.commit_hash, h.applied_at, h.applied_by
FROM (
    SELECT mh.*, ROW_NUMBER() OVER (PARTITION BY mh.migration_id ORDER BY mh.migration_history_id DESC) AS rn
    FROM Layercake.migration_history AS mh
) AS h
WHERE h.rn = 1;
GO
-- The database version is the highest migration currently applied.
CREATE OR ALTER VIEW Layercake.vw_database_version
AS
SELECT TOP (1) s.migration_id AS database_version, s.module_id, s.description, s.applied_at, s.applied_by, s.commit_hash
FROM Layercake.vw_migration_state AS s
WHERE s.current_state = 'up'
ORDER BY s.migration_id DESC;
GO
CREATE OR ALTER FUNCTION Layercake.fn_migration_is_applied (@migration_id varchar(10))
RETURNS bit
AS
BEGIN
    RETURN CASE WHEN EXISTS (SELECT 1 FROM Layercake.vw_migration_state
                             WHERE migration_id = @migration_id AND current_state = 'up')
                THEN 1 ELSE 0 END;
END;
GO
CREATE OR ALTER PROCEDURE Layercake.usp_record_migration
    @migration_id varchar(10),
    @module_id    varchar(10) = NULL,
    @description nvarchar(200),
    @direction   varchar(4),
    @script_name  nvarchar(260),
    @commit_hash  varchar(40) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT Layercake.migration_history (migration_id, module_id, description, direction, script_name, commit_hash)
    VALUES (@migration_id, @module_id, @description, @direction, @script_name, @commit_hash);
END;
GO
-- dbt deployments (base standards 4): a deployment of the dbt models is `dbt build` at a commit, so it is
-- recorded here rather than as a migration. A rollback is `dbt build` at the earlier commit.
IF OBJECT_ID(N'Layercake.dbt_deploy_history', N'U') IS NULL
CREATE TABLE Layercake.dbt_deploy_history (
    dbt_deploy_history_id int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Layercake_dbt_deploy_history PRIMARY KEY,
    direction          varchar(8)     NOT NULL CONSTRAINT CK_Layercake_dbt_deploy_history_direction CHECK (direction IN ('deploy', 'rollback')),
    commit_hash         varchar(40)    NOT NULL,
    selector           nvarchar(400)  NULL,
    model_count         int            NOT NULL,
    status             varchar(7)     NOT NULL CONSTRAINT CK_Layercake_dbt_deploy_history_status CHECK (status IN ('success', 'failed')),
    applied_at          datetime2(3)   NOT NULL CONSTRAINT DF_Layercake_dbt_deploy_history_applied_at DEFAULT (SYSUTCDATETIME()),
    applied_by          sysname        NOT NULL CONSTRAINT DF_Layercake_dbt_deploy_history_applied_by DEFAULT (ORIGINAL_LOGIN())
);
GO
-- The dbt models in the database are those of the last successful deployment or rollback.
CREATE OR ALTER VIEW Layercake.vw_dbt_version
AS
SELECT TOP (1) h.commit_hash, h.direction, h.model_count, h.applied_at, h.applied_by
FROM Layercake.dbt_deploy_history AS h
WHERE h.status = 'success'
ORDER BY h.dbt_deploy_history_id DESC;
GO
CREATE OR ALTER PROCEDURE Layercake.usp_record_dbt_deploy
    @direction  varchar(8),
    @commit_hash varchar(40),
    @selector   nvarchar(400) = NULL,
    @model_count int,
    @status     varchar(7)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT Layercake.dbt_deploy_history (direction, commit_hash, selector, model_count, status)
    VALUES (@direction, @commit_hash, @selector, @model_count, @status);
END;
GO
IF Layercake.fn_migration_is_applied('MIG-0000') = 0
    EXEC Layercake.usp_record_migration @migration_id = 'MIG-0000', @description = N'Migration framework',
         @direction = 'up', @script_name = N'MIG-0000_bootstrap_migration-history.up.sql',
         @commit_hash = '$(CommitHash)';
GO
