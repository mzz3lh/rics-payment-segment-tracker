CREATE TABLE Layercake.silv_ref_payment_method
(
    id                  int          IDENTITY(1, 1) NOT NULL,
    payment_method_name varchar(30)  NOT NULL,
    source_code         varchar(20)  NULL,
    created_at          datetime2(3) NOT NULL CONSTRAINT DF_Layercake_silv_ref_payment_method_created_at DEFAULT SYSDATETIME(),
    updated_at          datetime2(3) NOT NULL CONSTRAINT DF_Layercake_silv_ref_payment_method_updated_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Layercake_silv_ref_payment_method PRIMARY KEY CLUSTERED (id),
    CONSTRAINT UQ_Layercake_silv_ref_payment_method_payment_method_name UNIQUE (payment_method_name)
);

-- source_code is unique where present: the reserved rows carry none.
CREATE UNIQUE INDEX IX_silv_ref_payment_method_source_code
    ON Layercake.silv_ref_payment_method (source_code)
    WHERE source_code IS NOT NULL;
