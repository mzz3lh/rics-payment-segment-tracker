CREATE TABLE Layercake.brnz_concession
(
    apuk_concessiontypeid      uniqueidentifier NOT NULL,
    apuk_name                  nvarchar(100)    NULL,
    apuk_discount              decimal(38, 2)   NULL,
    product_number             nvarchar(4000)   NULL,
    statecode                  int              NULL,
    apuk_perpetualnonperpetual int              NULL,
    _loaded_at                 datetime2(3)     NOT NULL CONSTRAINT DF_Layercake_brnz_concession__loaded_at DEFAULT SYSDATETIME(),
    _updated_at                datetime2(3)     NOT NULL CONSTRAINT DF_Layercake_brnz_concession__updated_at DEFAULT SYSDATETIME(),
    _is_deleted                bit              NOT NULL CONSTRAINT DF_Layercake_brnz_concession__is_deleted DEFAULT 0,
    _deleted_at                datetime2(3)     NULL,
    CONSTRAINT PK_Layercake_brnz_concession PRIMARY KEY CLUSTERED (apuk_concessiontypeid)
);
