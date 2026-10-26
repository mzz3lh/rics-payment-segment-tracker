CREATE TABLE Layercake.silv_ref_payment_method
(
    id                  int          IDENTITY(1, 1) NOT NULL,
    payment_method_name varchar(30)  NOT NULL,
    source_code         varchar(20)  NULL,
    created_at          datetime2(3) NOT NULL CONSTRAINT DF_Layercake_silv_ref_payment_method_created_at DEFAULT SYSUTCDATETIME(),
    updated_at          datetime2(3) NOT NULL CONSTRAINT DF_Layercake_silv_ref_payment_method_updated_at DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Layercake_silv_ref_payment_method PRIMARY KEY CLUSTERED (id),
    CONSTRAINT UQ_Layercake_silv_ref_payment_method_payment_method_name UNIQUE (payment_method_name)
);

-- source_code is unique where present: the reserved rows carry none.
CREATE UNIQUE INDEX IX_silv_ref_payment_method_source_code
    ON Layercake.silv_ref_payment_method (source_code)
    WHERE source_code IS NOT NULL;

-- Static list (RULE-006, RULE-078): reserved rows at fixed ids 0, -1 and -2. The five methods
-- are given their identity values 1 to 5 explicitly so every build numbers them the same way;
-- the identity then continues from 6 for any method added later.
SET IDENTITY_INSERT Layercake.silv_ref_payment_method ON;

INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code)
VALUES (0, 'Unknown', NULL),
       (-1, 'Unrecognised', NULL),
       (-2, 'Not applicable', NULL),
       (1, 'Direct Debit', 'DD'),
       (2, 'Card', 'Card'),
       (3, 'Bank transfer', 'Bank'),
       (4, 'Cheque', 'Cheque'),
       (5, 'Corporate', 'Corporate');

SET IDENTITY_INSERT Layercake.silv_ref_payment_method OFF;
