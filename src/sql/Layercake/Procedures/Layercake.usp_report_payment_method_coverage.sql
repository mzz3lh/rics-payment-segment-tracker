CREATE OR ALTER PROCEDURE Layercake.usp_report_payment_method_coverage
    @as_of_date date = NULL
AS
/*
    Count-only payment method coverage (REQ-014, RULE-067, AC-014-01), one row per Campaign Year
    from 2021 and basis that has at least one row.
    - basis 'Paid position': Layercake.silv_payment_events rows (contact_no, campaign_year), with
      the payment method of that contact-year's silv_member_year_attributes row; no attributes row
      is 0 Unknown (ASM-007).
    - basis = event_type: Layercake.silv_membership_events rows by their own campaign_year, with
      the event's own payment_method_id (ASM-007).
    Covered means payment_method_id > 0, so Unknown (0), Unrecognised (-1) and Not applicable (-2)
    are not covered. coverage_pct = with_method / total x 100, rounded to 1 dp.
    @as_of_date is accepted and ignored: every report takes one (ADR-003); coverage covers every year.
    Aggregates only (RULE-066).
*/
BEGIN
    SET NOCOUNT ON;

    WITH positions AS (
        SELECT
            pe.campaign_year,
            CAST('Paid position' AS varchar(20)) AS basis,
            ISNULL(ya.payment_method_id, 0) AS payment_method_id
        FROM Layercake.silv_payment_events AS pe
        LEFT JOIN Layercake.silv_member_year_attributes AS ya
            ON ya.contact_no = pe.contact_no
            AND ya.campaign_year = pe.campaign_year
        WHERE pe.campaign_year >= 2021

        UNION ALL

        SELECT
            ev.campaign_year,
            CAST(ev.event_type AS varchar(20)) AS basis,
            ev.payment_method_id
        FROM Layercake.silv_membership_events AS ev
        WHERE ev.campaign_year >= 2021
    ),

    basis_counts AS (
        SELECT
            p.campaign_year,
            p.basis,
            COUNT(*) AS total,
            COUNT(CASE WHEN p.payment_method_id > 0 THEN 1 END) AS with_method
        FROM positions AS p
        GROUP BY p.campaign_year, p.basis
    )

    SELECT
        bc.campaign_year,
        bc.basis,
        bc.total,
        bc.with_method,
        CAST(ROUND(100.0 * bc.with_method / bc.total, 1) AS decimal(5, 1)) AS coverage_pct
    FROM basis_counts AS bc
    ORDER BY
        bc.campaign_year,
        CASE bc.basis
            WHEN 'Paid position' THEN 0
            WHEN 'Join' THEN 1
            WHEN 'Readmission' THEN 2
            WHEN 'Renewal' THEN 3
            WHEN 'Change' THEN 4
            WHEN 'Lapse' THEN 5
            ELSE 6
        END,
        bc.basis;
END;
