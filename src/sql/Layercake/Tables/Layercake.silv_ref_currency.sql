CREATE TABLE Layercake.silv_ref_currency
(
    id            int          IDENTITY(1, 1) NOT NULL,
    currency_code nvarchar(3)  NOT NULL,
    load_id       bigint       NULL,
    created_at    datetime2(3) NOT NULL CONSTRAINT DF_Layercake_silv_ref_currency_created_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Layercake_silv_ref_currency PRIMARY KEY CLUSTERED (id),
    CONSTRAINT UQ_Layercake_silv_ref_currency_currency_code UNIQUE (currency_code)
);
