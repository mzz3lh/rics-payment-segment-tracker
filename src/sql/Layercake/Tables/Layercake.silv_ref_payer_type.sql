CREATE TABLE Layercake.silv_ref_payer_type
(
    id              int          IDENTITY(1, 1) NOT NULL,
    payer_type_name varchar(30)  NOT NULL,
    created_at      datetime2(3) NOT NULL CONSTRAINT DF_Layercake_silv_ref_payer_type_created_at DEFAULT SYSDATETIME(),
    updated_at      datetime2(3) NOT NULL CONSTRAINT DF_Layercake_silv_ref_payer_type_updated_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Layercake_silv_ref_payer_type PRIMARY KEY CLUSTERED (id),
    CONSTRAINT UQ_Layercake_silv_ref_payer_type_payer_type_name UNIQUE (payer_type_name)
);
