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
