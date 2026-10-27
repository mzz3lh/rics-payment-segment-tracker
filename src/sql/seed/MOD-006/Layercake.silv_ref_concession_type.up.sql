-- Static rows (RULE-046): reserved rows at fixed ids 0, -1 and -2 and the one 'No concession'
-- row, given its identity value 1 explicitly so every build numbers it the same way; source
-- types loaded later take ids from 2. None has a business key, item code or flag.
SET IDENTITY_INSERT Layercake.silv_ref_concession_type ON;

INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id)
VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL),
       (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL),
       (-2, NULL, N'Not applicable', NULL, 0, 0, NULL),
       (1, NULL, N'No concession', NULL, 0, 0, NULL);

SET IDENTITY_INSERT Layercake.silv_ref_concession_type OFF;
