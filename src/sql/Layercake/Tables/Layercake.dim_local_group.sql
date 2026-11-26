-- Gold copy of silv_ref_local_group by id, both reserved rows included (RULE-170, AC-027-10).
CREATE TABLE Layercake.dim_local_group
(
    id               int           NOT NULL,
    local_group_name nvarchar(100) NULL,
    load_id          bigint        NULL,
    created_at       datetime2(3)  NOT NULL CONSTRAINT DF_Layercake_dim_local_group_created_at DEFAULT SYSDATETIME(),
    updated_at       datetime2(3)  NOT NULL CONSTRAINT DF_Layercake_dim_local_group_updated_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Layercake_dim_local_group PRIMARY KEY CLUSTERED (id)
);
