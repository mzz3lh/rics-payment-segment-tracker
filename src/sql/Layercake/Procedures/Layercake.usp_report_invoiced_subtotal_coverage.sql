CREATE OR ALTER PROCEDURE Layercake.usp_report_invoiced_subtotal_coverage
    @as_of_date date = NULL
AS
/*
    Count-only invoiced subtotal coverage (REQ-014, RULE-068, AC-014-02), one row per Campaign Year
    that has a Join, Renewal or Readmission event in Layercake.silv_membership_events (its own
    campaign_year, no lower year bound). Change and Lapse carry no amount and are left out.
    Covered means invoiced_subtotal_gbp IS NOT NULL, so 0.00 is covered.
    coverage_pct = with_invoiced_subtotal / events x 100, rounded to 1 dp.
    Then one count per amount_status value (Q-045, AC-015-04).
    @as_of_date is accepted and ignored: every report takes one (ADR-003); coverage covers every year.
    Aggregates only (RULE-066).
*/
BEGIN
    SET NOCOUNT ON;

    WITH year_counts AS (
        SELECT
            ev.campaign_year,
            COUNT(*) AS events,
            COUNT(ev.invoiced_subtotal_gbp) AS with_invoiced_subtotal,
            COUNT(CASE WHEN ev.amount_status = 'Before invoice data' THEN 1 END) AS before_invoice_data,
            COUNT(CASE WHEN ev.amount_status = 'No invoice' THEN 1 END) AS no_invoice,
            COUNT(CASE WHEN ev.amount_status = 'Counted on another event' THEN 1 END) AS counted_on_another_event,
            COUNT(CASE WHEN ev.amount_status = 'Full Concession' THEN 1 END) AS full_concession,
            COUNT(CASE WHEN ev.amount_status = 'Fully credited' THEN 1 END) AS fully_credited,
            COUNT(CASE WHEN ev.amount_status = 'Invoiced' THEN 1 END) AS invoiced
        FROM Layercake.silv_membership_events AS ev
        WHERE ev.event_type IN ('Join', 'Renewal', 'Readmission')
        GROUP BY ev.campaign_year
    )

    SELECT
        yc.campaign_year,
        yc.events,
        yc.with_invoiced_subtotal,
        CAST(ROUND(100.0 * yc.with_invoiced_subtotal / yc.events, 1) AS decimal(5, 1)) AS coverage_pct,
        yc.before_invoice_data,
        yc.no_invoice,
        yc.counted_on_another_event,
        yc.full_concession,
        yc.fully_credited,
        yc.invoiced
    FROM year_counts AS yc
    ORDER BY yc.campaign_year;
END;
