-- Static list (RULE-020, RULE-078): reserved rows at fixed ids 0, -1 and -2. Individual and
-- Corporate are given their identity values 1 and 2 explicitly so every build numbers them the
-- same way; the identity then continues from 3 for any type added later.
SET IDENTITY_INSERT Layercake.silv_ref_payer_type ON;

INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name)
VALUES (0, 'Unknown'),
       (-1, 'Unrecognised'),
       (-2, 'Not applicable'),
       (1, 'Individual'),
       (2, 'Corporate');

SET IDENTITY_INSERT Layercake.silv_ref_payer_type OFF;
