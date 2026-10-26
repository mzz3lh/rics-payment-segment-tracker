CREATE TABLE Layercake.dim_payment_method
(
    id                  int          NOT NULL,
    payment_method_name varchar(30)  NOT NULL,
    load_id             int          NULL,
    created_at          datetime2(3) NOT NULL,
    updated_at          datetime2(3) NOT NULL,
    CONSTRAINT PK_Layercake_dim_payment_method PRIMARY KEY CLUSTERED (id)
);
