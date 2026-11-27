-- Back to the AMD-007 grain on the own-country values, summing the counts of each old cell into
-- the row written most recently (it keeps its run_id and updated_at).
ALTER TABLE Layercake.etl_daily_count_cell_contacts DROP CONSTRAINT PK_Layercake_etl_daily_count_cell_contacts;
-- EXEC: the statement names columns this script drops, so a rerun after the drop must not compile it.
EXEC (N'UPDATE Layercake.etl_daily_count_cell_contacts SET region = contact_region, country_id = contact_country_id;');
ALTER TABLE Layercake.etl_daily_count_cell_contacts DROP COLUMN local_group_id, contact_country_id, contact_region;

WITH ranked AS (
    SELECT contact_count,
           SUM(contact_count) OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id,
                                                 payment_method_id, payer_type_id, concession_type_id) AS s_count,
           ROW_NUMBER() OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id,
                                           payment_method_id, payer_type_id, concession_type_id
                              ORDER BY updated_at DESC, run_id) AS rn
    FROM Layercake.etl_daily_count_cell_contacts
)
UPDATE ranked SET contact_count = s_count WHERE rn = 1;

WITH ranked AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id,
                                           payment_method_id, payer_type_id, concession_type_id
                              ORDER BY updated_at DESC, run_id) AS rn
    FROM Layercake.etl_daily_count_cell_contacts
)
DELETE FROM ranked WHERE rn > 1;

ALTER TABLE Layercake.etl_daily_count_cell_contacts ADD CONSTRAINT PK_Layercake_etl_daily_count_cell_contacts PRIMARY KEY CLUSTERED
    ([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id);
