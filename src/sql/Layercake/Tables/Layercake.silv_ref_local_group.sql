-- One row per local group, plus the seeded reserved rows 0 Unknown and
-- -2 Not applicable (RULE-170). Insert-and-update by local_group_bk; ids never change.
CREATE TABLE Layercake.silv_ref_local_group
(
    id                      int              IDENTITY(1, 1) NOT NULL,
    local_group_bk          uniqueidentifier NULL,
    local_group_name        nvarchar(100)    NULL,
    local_group_code        nvarchar(100)    NULL,
    country_id              int              NULL,
    region_name             nvarchar(100)    NULL,
    market_reporting_region varchar(15)      NULL,
    statecode               int              NULL,
    is_reportable           bit              NOT NULL CONSTRAINT DF_Layercake_silv_ref_local_group_is_reportable DEFAULT 0,
    dim_country_id          int              NULL,
    load_id                 bigint           NULL,
    created_at              datetime2(3)     NOT NULL CONSTRAINT DF_Layercake_silv_ref_local_group_created_at DEFAULT SYSDATETIME(),
    updated_at              datetime2(3)     NOT NULL CONSTRAINT DF_Layercake_silv_ref_local_group_updated_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Layercake_silv_ref_local_group PRIMARY KEY CLUSTERED (id),
    CONSTRAINT FK_Layercake_silv_ref_local_group_silv_ref_country FOREIGN KEY (country_id) REFERENCES Layercake.silv_ref_country (id)
);

-- The business key is unique where present; the reserved rows have none.
CREATE UNIQUE INDEX IX_silv_ref_local_group_local_group_bk
    ON Layercake.silv_ref_local_group (local_group_bk)
    WHERE local_group_bk IS NOT NULL;
