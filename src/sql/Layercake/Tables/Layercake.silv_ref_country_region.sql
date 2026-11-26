-- Country and region combinations a reportable local group gives that differ from
-- the country's own silv_ref_country row (ADR-015). Ids from 1000001 so they never
-- meet a silv_ref_country id in dim_country. Insert-only.
CREATE TABLE Layercake.silv_ref_country_region
(
    id                      int           IDENTITY(1000001, 1) NOT NULL,
    country_ref_id          int           NOT NULL,
    region_name             nvarchar(200) NOT NULL,
    market_reporting_region varchar(15)   NOT NULL,
    load_id                 bigint        NULL,
    created_at              datetime2(3)  NOT NULL CONSTRAINT DF_Layercake_silv_ref_country_region_created_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Layercake_silv_ref_country_region PRIMARY KEY CLUSTERED (id),
    CONSTRAINT UQ_Layercake_silv_ref_country_region_country_ref_id_region_name_market_reporting_region
        UNIQUE (country_ref_id, region_name, market_reporting_region),
    CONSTRAINT FK_Layercake_silv_ref_country_region_silv_ref_country FOREIGN KEY (country_ref_id) REFERENCES Layercake.silv_ref_country (id)
);
