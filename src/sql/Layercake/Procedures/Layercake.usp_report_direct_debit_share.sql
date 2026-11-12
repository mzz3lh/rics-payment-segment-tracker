CREATE OR ALTER PROCEDURE Layercake.usp_report_direct_debit_share
    @as_of_date date = NULL
AS
/*
    Count-only Direct Debit share (REQ-014, RULE-069, AC-014-03): one row for the current Campaign
    Year, the ref_campaign_year_config row covering @as_of_date (NULL = today, ADR-003). The report
    fails (50014, as usp_report_top_employers) if no year covers the date.
    - Partially Paid position: a Layercake.silv_payment_events row for that year with
      invoice_position 'Partially Paid'.
    - Direct Debit: payment method id 1 (seeded 'Direct Debit', MOD-003) in that contact-year's
      silv_member_year_attributes row; no attributes row is 0 Unknown (ASM-007).
    direct_debit_share_pct = direct_debit_positions / partially_paid_positions x 100, rounded to
    1 dp, NULL when there are no Partially Paid positions; the row is still returned (ASM-007).
    Aggregates only (RULE-066).
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @report_date date = ISNULL(@as_of_date, CAST(SYSDATETIME() AS date));
    DECLARE @current_year int;

    SELECT @current_year = cy.campaign_year
    FROM Layercake.ref_campaign_year_config AS cy
    WHERE @report_date BETWEEN cy.campaign_year_start AND cy.campaign_year_end;

    IF @current_year IS NULL
        THROW 50014, N'usp_report_direct_debit_share: no Campaign Year covering @as_of_date in Layercake.ref_campaign_year_config.', 1;

    WITH positions AS (
        SELECT
            COUNT(*) AS partially_paid_positions,
            COUNT(CASE WHEN ya.payment_method_id = 1 THEN 1 END) AS direct_debit_positions
        FROM Layercake.silv_payment_events AS pe
        LEFT JOIN Layercake.silv_member_year_attributes AS ya
            ON ya.contact_no = pe.contact_no
            AND ya.campaign_year = pe.campaign_year
        WHERE pe.campaign_year = @current_year
            AND pe.invoice_position = N'Partially Paid'
    )

    SELECT
        @current_year AS campaign_year,
        p.partially_paid_positions,
        p.direct_debit_positions,
        CAST(
            ROUND(100.0 * p.direct_debit_positions / NULLIF(p.partially_paid_positions, 0), 1) AS decimal(5, 1)
        ) AS direct_debit_share_pct
    FROM positions AS p;
END;
