/*====================================================================
    Layercake.vw_silv_derived_retirement_date
    One row per contact that has a derived retirement date (RULE-099,
    ADR-005). apuk_retirementdate is entered by hand and is not always
    trustworthy, so the date is taken from the subs history instead:
    among the contact's live brnz_subs_status rows whose
    retired_concession is 'Retired Conc.' and whose Renewal Date is
    known, the row with the LOWEST Campaign Year gives the date (its
    Renewal Date, not Renewal Date Adj) - not the earliest Renewal Date
    across years (Q-041). A 'Retired Conc.' year with no Renewal Date is
    passed over. No row = no derived date (RULE-101); there is no
    fallback to apuk_retirementdate or 'First Retired Year' (Q-040).
    [Contact No.], [Campaign Year] is the table's key, so the lowest
    year per contact is unique and needs no tie-break.
    Read by usp_load_silv_member_base and the retirement comparison.
====================================================================*/
CREATE OR ALTER VIEW Layercake.vw_silv_derived_retirement_date
AS
SELECT
    r.contact_no,
    r.retirement_campaign_year,
    r.derived_retirement_date
FROM (
    SELECT
        s.[Contact No.] AS contact_no,
        s.[Campaign Year] AS retirement_campaign_year,
        s.[Renewal Date] AS derived_retirement_date,
        ROW_NUMBER() OVER (PARTITION BY s.[Contact No.] ORDER BY s.[Campaign Year]) AS rn
    FROM Layercake.brnz_subs_status AS s
    WHERE
        s._is_deleted = 0
        AND s.retired_concession = 'Retired Conc.'
        AND s.[Renewal Date] IS NOT NULL
) AS r
WHERE r.rn = 1;
