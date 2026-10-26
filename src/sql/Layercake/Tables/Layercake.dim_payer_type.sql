CREATE TABLE Layercake.dim_payer_type
(
    id              int          NOT NULL,
    payer_type_name varchar(30)  NOT NULL,
    load_id         bigint       NULL,
    created_at      datetime2(3) NOT NULL,
    updated_at      datetime2(3) NOT NULL,
    CONSTRAINT PK_Layercake_dim_payer_type PRIMARY KEY CLUSTERED (id)
);
