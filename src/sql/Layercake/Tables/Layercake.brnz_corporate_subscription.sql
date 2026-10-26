CREATE TABLE Layercake.brnz_corporate_subscription
(
    contact_no        nvarchar(100)  NOT NULL,
    scheme_no         nvarchar(100)  NOT NULL,
    scheme_name       nvarchar(4000) NULL,
    sub_campaign_year int            NOT NULL,
    sub_status        nvarchar(350)  NULL,
    sub_user_status   nvarchar(350)  NULL,
    _loaded_at        datetime2(3)   NOT NULL CONSTRAINT DF_Layercake_brnz_corporate_subscription__loaded_at DEFAULT SYSDATETIME(),
    _updated_at       datetime2(3)   NOT NULL CONSTRAINT DF_Layercake_brnz_corporate_subscription__updated_at DEFAULT SYSDATETIME(),
    _is_deleted       bit            NOT NULL CONSTRAINT DF_Layercake_brnz_corporate_subscription__is_deleted DEFAULT 0,
    _deleted_at       datetime2(3)   NULL,
    CONSTRAINT PK_Layercake_brnz_corporate_subscription PRIMARY KEY CLUSTERED (contact_no, scheme_no, sub_campaign_year)
);
