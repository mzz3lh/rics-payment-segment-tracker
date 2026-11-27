-- Back to the Phase 1 five-column grain: each row returns to its own country's dim_country row,
-- and rows that then share a five-column key are added together into the one with the lowest id,
-- so every count summed over the dropped columns is kept (RULE-177). The restored Phase 1 load
-- re-syncs the fact from silver on its next run. EXEC: the statements name columns this script
-- drops, so a rerun after the drop must not compile them.
DROP INDEX ux_fact_annual_rate_base_segment ON Layercake.fact_annual_rate_base;
EXEC (N'UPDATE Layercake.fact_annual_rate_base SET country_id = contact_country_id;');
EXEC (N'WITH g AS (
    SELECT members_start, members_end, members_joined, members_readmitted, members_lapsed, members_renewed,
           SUM(members_start) OVER (PARTITION BY campaign_year, grade_id, membership_status_id, country_id, gender_id) AS sum_start,
           SUM(members_end) OVER (PARTITION BY campaign_year, grade_id, membership_status_id, country_id, gender_id) AS sum_end,
           SUM(members_joined) OVER (PARTITION BY campaign_year, grade_id, membership_status_id, country_id, gender_id) AS sum_joined,
           SUM(members_readmitted) OVER (PARTITION BY campaign_year, grade_id, membership_status_id, country_id, gender_id) AS sum_readmitted,
           SUM(members_lapsed) OVER (PARTITION BY campaign_year, grade_id, membership_status_id, country_id, gender_id) AS sum_lapsed,
           SUM(members_renewed) OVER (PARTITION BY campaign_year, grade_id, membership_status_id, country_id, gender_id) AS sum_renewed,
           ROW_NUMBER() OVER (PARTITION BY campaign_year, grade_id, membership_status_id, country_id, gender_id
                              ORDER BY id) AS rn
    FROM Layercake.fact_annual_rate_base)
UPDATE g
SET members_start = sum_start, members_end = sum_end, members_joined = sum_joined,
    members_readmitted = sum_readmitted, members_lapsed = sum_lapsed, members_renewed = sum_renewed
WHERE rn = 1;');
EXEC (N'WITH g AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY campaign_year, grade_id, membership_status_id, country_id, gender_id
                              ORDER BY id) AS rn
    FROM Layercake.fact_annual_rate_base)
DELETE FROM g WHERE rn > 1;');
ALTER TABLE Layercake.fact_annual_rate_base DROP COLUMN local_group_id, contact_country_id;
CREATE UNIQUE NONCLUSTERED INDEX ux_fact_annual_rate_base_segment
    ON Layercake.fact_annual_rate_base
    (campaign_year, grade_id, membership_status_id, country_id, gender_id);
