-- ADR-013: sum the counts back to the old grain over the three segment ids, keeping the run_id
-- and updated_at of the cell's most recently written row, drop the columns and write the old
-- cells back. No statement names a segment column, so the script still compiles when it is run
-- again after the columns have gone.
SELECT x.[date], x.region, x.country_id, x.gender_id, x.grade, x.membership_status_id,
       x.contact_count, x.run_id, x.updated_at
INTO #mig0030_cell_contacts_old_grain
FROM (
    SELECT [date], region, country_id, gender_id, grade, membership_status_id, run_id, updated_at,
           SUM(contact_count) OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id) AS contact_count,
           ROW_NUMBER() OVER (PARTITION BY [date], region, country_id, gender_id, grade, membership_status_id
                              ORDER BY updated_at DESC, run_id) AS rn
    FROM Layercake.etl_daily_count_cell_contacts
) AS x
WHERE x.rn = 1;

DELETE FROM Layercake.etl_daily_count_cell_contacts;

ALTER TABLE Layercake.etl_daily_count_cell_contacts DROP CONSTRAINT PK_Layercake_etl_daily_count_cell_contacts;
ALTER TABLE Layercake.etl_daily_count_cell_contacts DROP COLUMN payment_method_id, payer_type_id, concession_type_id;
ALTER TABLE Layercake.etl_daily_count_cell_contacts ADD CONSTRAINT PK_Layercake_etl_daily_count_cell_contacts PRIMARY KEY CLUSTERED
    ([date], region, country_id, gender_id, grade, membership_status_id);

INSERT INTO Layercake.etl_daily_count_cell_contacts
    ([date], region, country_id, gender_id, grade, membership_status_id, contact_count, run_id, updated_at)
SELECT [date], region, country_id, gender_id, grade, membership_status_id, contact_count, run_id, updated_at
FROM #mig0030_cell_contacts_old_grain;
