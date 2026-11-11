CREATE OR ALTER PROCEDURE Layercake.usp_report_employer_scheme_coverage
    @as_of_date date = NULL
AS
/*
    Count-only employer coverage (REQ-013, RULE-060), one row per Campaign Year and payer type
    that has a paid member.
    - Paid member: a Layercake.silv_payment_events row (contact_no, campaign_year). Payer type
      from that year's silv_member_year_attributes row; a year with no attributes row is
      0 Unknown, and Unknown is reported as its own row (ASM-006).
    - Scheme-link employer: a live corporate subscription for the same Campaign Year
      (brnz_corporate_subscription, _is_deleted 0, sub_status and sub_user_status 'Active', Q-027)
      whose scheme_no matches a CE.vwCorporateSchemes.apuk_subscriptionnumber row with an
      AccountNumber. Checked for every payer type.
    - Contact-record employer: a CE.vwContact row for the contact whose ParentCustomerId is set
      and whose ParentCustomerIdType is 'account' (ASM-006 (3)).
    A member with both sources counts in both columns; no_employer counts members with neither.
    Coverage = count / paid_members x 100 (answers.md, MOD-014 coverage columns).
    Each member is counted once per year (EXISTS), however many scheme or contact rows match.
    @as_of_date is accepted and ignored: every report takes one (ADR-003); coverage covers every year.
    Aggregates only (RULE-064).
*/
BEGIN
    SET NOCOUNT ON;

    WITH member_years AS (
        SELECT
            pe.campaign_year,
            ISNULL(ya.payer_type_id, 0) AS payer_type_id,
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM Layercake.brnz_corporate_subscription AS cs
                    INNER JOIN CE.vwCorporateSchemes AS sc
                        ON sc.apuk_subscriptionnumber = cs.scheme_no
                    WHERE cs.contact_no = pe.contact_no
                        AND cs.sub_campaign_year = pe.campaign_year
                        AND cs._is_deleted = 0
                        AND cs.sub_status = N'Active'
                        AND cs.sub_user_status = N'Active'
                        AND sc.AccountNumber IS NOT NULL
                ) THEN 1
                ELSE 0
            END AS has_scheme_link,
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM CE.vwContact AS ct
                    WHERE ct.Rics_contactno = pe.contact_no
                        AND ct.ParentCustomerIdType = N'account'
                        AND ct.ParentCustomerId IS NOT NULL
                ) THEN 1
                ELSE 0
            END AS has_contact_record
        FROM Layercake.silv_payment_events AS pe
        LEFT JOIN Layercake.silv_member_year_attributes AS ya
            ON ya.contact_no = pe.contact_no
            AND ya.campaign_year = pe.campaign_year
    ),

    year_counts AS (
        SELECT
            my.campaign_year,
            my.payer_type_id,
            COUNT(*) AS paid_members,
            SUM(my.has_scheme_link) AS scheme_link_employer,
            SUM(my.has_contact_record) AS contact_record_employer,
            SUM((1 - my.has_scheme_link) * (1 - my.has_contact_record)) AS no_employer
        FROM member_years AS my
        GROUP BY my.campaign_year, my.payer_type_id
    )

    SELECT
        yc.campaign_year,
        pt.payer_type_name,
        yc.paid_members,
        yc.scheme_link_employer,
        yc.contact_record_employer,
        yc.no_employer,
        CAST(
            ROUND(100.0 * yc.scheme_link_employer / yc.paid_members, 1) AS decimal(5, 1)
        ) AS scheme_link_coverage_pct,
        CAST(
            ROUND(100.0 * yc.contact_record_employer / yc.paid_members, 1) AS decimal(5, 1)
        ) AS contact_record_coverage_pct
    FROM year_counts AS yc
    INNER JOIN Layercake.silv_ref_payer_type AS pt
        ON pt.id = yc.payer_type_id
    ORDER BY yc.campaign_year, yc.payer_type_id;
END;
