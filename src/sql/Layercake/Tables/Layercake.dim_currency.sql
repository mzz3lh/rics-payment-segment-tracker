CREATE TABLE Layercake.dim_currency
(
    id            int          NOT NULL,
    currency_code nvarchar(3)  NOT NULL,
    load_id       bigint       NULL,
    created_at    datetime2(3) NOT NULL,
    updated_at    datetime2(3) NOT NULL,
    CONSTRAINT PK_Layercake_dim_currency PRIMARY KEY CLUSTERED (id)
);
