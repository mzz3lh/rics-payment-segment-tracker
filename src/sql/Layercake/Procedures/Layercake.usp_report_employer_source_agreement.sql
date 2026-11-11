CREATE OR ALTER PROCEDURE Layercake.usp_report_employer_source_agreement
    @as_of_date date = NULL
AS
/*
    Count-only agreement between the two employer sources (REQ-013, RULE-060), one row per
    Campaign Year that has a paid member with an employer from both sources.
    - Paid member: a Layercake.silv_payment_events row (contact_no, campaign_year), counted per
      contact-year, any payer type (ASM-006 (4)).
    - Scheme-link firm: apuk_onbehalfoforganisationid of a CE.vwCorporateSchemes row with an
      AccountNumber whose apuk_subscriptionnumber is the scheme_no of a live corporate
      subscription for that year (_is_deleted 0, 'Active'/'Active', Q-027): the same
      scheme link the coverage report counts.
    - Contact-record firm: CE.vwContact.ParentCustomerId where ParentCustomerIdType is 'account'.
    - Same firm: the account GUIDs are equal, never the names (ASM-006 (3)). A member with
      several scheme or contact firms in the year is the same firm when any pair is equal.
    agreement_rate_pct = same_firm / both_sources x 100.
    @as_of_date is accepted and ignored: every report takes one (ADR-003).
    Aggregates only (RULE-064).
*/
BEGIN
    SET NOCOUNT ON;

    WITH scheme_firms AS (
        SELECT DISTINCT
            cs.contact_no,
            cs.sub_campaign_year AS campaign_year,
            sc.apuk_onbehalfoforganisationid AS account_id
        FROM Layercake.brnz_corporate_subscription AS cs
        INNER JOIN CE.vwCorporateSchemes AS sc
            ON sc.apuk_subscriptionnumber = cs.scheme_no
        WHERE cs._is_deleted = 0
            AND cs.sub_status = N'Active'
            AND cs.sub_user_status = N'Active'
            AND sc.AccountNumber IS NOT NULL
    ),

    contact_firms AS (
        SELECT DISTINCT
            ct.Rics_contactno AS contact_no,
            ct.ParentCustomerId AS account_id
        FROM CE.vwContact AS ct
        WHERE ct.ParentCustomerIdType = N'account'
            AND ct.ParentCustomerId IS NOT NULL
    ),

    member_years AS (
        SELECT
            pe.campaign_year,
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM scheme_firms AS sf
                    WHERE sf.contact_no = pe.contact_no
                        AND sf.campaign_year = pe.campaign_year
                )
                AND EXISTS (
                    SELECT 1
                    FROM contact_firms AS cf
                    WHERE cf.contact_no = pe.contact_no
                ) THEN 1
                ELSE 0
            END AS has_both,
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM scheme_firms AS sf
                    INNER JOIN contact_firms AS cf
                        ON cf.contact_no = sf.contact_no
                        AND cf.account_id = sf.account_id
                    WHERE sf.contact_no = pe.contact_no
                        AND sf.campaign_year = pe.campaign_year
                ) THEN 1
                ELSE 0
            END AS is_same_firm
        FROM Layercake.silv_payment_events AS pe
    ),

    year_counts AS (
        SELECT
            my.campaign_year,
            SUM(my.has_both) AS both_sources,
            SUM(my.is_same_firm) AS same_firm
        FROM member_years AS my
        GROUP BY my.campaign_year
        HAVING SUM(my.has_both) > 0
    )

    SELECT
        yc.campaign_year,
        yc.both_sources,
        yc.same_firm,
        yc.both_sources - yc.same_firm AS different_firm,
        CAST(ROUND(100.0 * yc.same_firm / yc.both_sources, 1) AS decimal(5, 1)) AS agreement_rate_pct
    FROM year_counts AS yc
    ORDER BY yc.campaign_year;
END;
