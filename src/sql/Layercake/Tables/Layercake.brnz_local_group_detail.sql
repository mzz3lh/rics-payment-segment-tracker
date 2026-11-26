-- CE.vwLocalGroup landed 1:1 at local group grain (RULE-169, ADR-014), beside the
-- country-grain Phase 1 brnz_local_group, which is unchanged.
CREATE TABLE Layercake.brnz_local_group_detail
(
    apuk_localgroupid       uniqueidentifier NOT NULL,
    apuk_name               nvarchar(100)    NULL,
    apuk_code               nvarchar(100)    NULL,
    apuk_countryid          uniqueidentifier NULL,
    apuk_worldregionid_name nvarchar(100)    NULL,
    market_reporting_region varchar(15)      NULL,
    statecode               int              NULL,
    _loaded_at              datetime2(3)     NOT NULL CONSTRAINT DF_Layercake_brnz_local_group_detail__loaded_at DEFAULT SYSDATETIME(),
    _updated_at             datetime2(3)     NOT NULL CONSTRAINT DF_Layercake_brnz_local_group_detail__updated_at DEFAULT SYSDATETIME(),
    _is_deleted             bit              NOT NULL CONSTRAINT DF_Layercake_brnz_local_group_detail__is_deleted DEFAULT 0,
    _deleted_at             datetime2(3)     NULL,
    CONSTRAINT PK_Layercake_brnz_local_group_detail PRIMARY KEY CLUSTERED (apuk_localgroupid)
);
