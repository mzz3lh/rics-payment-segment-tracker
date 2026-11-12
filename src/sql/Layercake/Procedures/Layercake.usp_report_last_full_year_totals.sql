CREATE OR ALTER PROCEDURE Layercake.usp_report_last_full_year_totals
    @as_of_date date = NULL
AS
/*
    Count-only totals for the last full Campaign Year (REQ-014, RULE-070, AC-014-04 to AC-014-06),
    as one long-form result set (campaign_year, measure, category, value), so it can be captured
    with INSERT ... EXEC (ASM-007).
    - Last full Campaign Year: the ref_campaign_year_config year before the one covering
      @as_of_date (NULL = today, ADR-003), as in usp_report_top_employers. The report fails (50014)
      if no year covers the date or none precedes it.
    - Paid member: a Layercake.silv_payment_events row for that year. Payment method, payer type and
      concession come from that contact-year's silv_member_year_attributes row; no attributes row is
      0 Unknown.
    - 'paid_members_by_payment_method' / 'paid_members_by_concession_type': one row per method /
      concession type with at least one paid member, category = its name (reserved ids included).
    - 'corporate_paid_members': payer type 2 Corporate (seeded, MOD-004), not the payment method.
    - 'corporate_share_pct': corporate / paid members x 100, rounded to 1 dp; NULL with no paid members.
    - 'invoiced_subtotal_gbp_total' / 'subs_amount_gbp_total': SUM of each column over that year's
      Join, Renewal and Readmission events in silv_membership_events (NULL when nothing to add).
    The four single measures are always returned, with category NULL. Aggregates only (RULE-066).
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @report_date date = ISNULL(@as_of_date, CAST(SYSDATETIME() AS date));
    DECLARE @last_full_year int;

    SELECT @last_full_year = MAX(prev.campaign_year)
    FROM Layercake.ref_campaign_year_config AS cur
    INNER JOIN Layercake.ref_campaign_year_config AS prev
        ON prev.campaign_year < cur.campaign_year
    WHERE @report_date BETWEEN cur.campaign_year_start AND cur.campaign_year_end;

    IF @last_full_year IS NULL
        THROW 50014, N'usp_report_last_full_year_totals: no Campaign Year before the one covering @as_of_date in Layercake.ref_campaign_year_config.', 1;

    WITH paid_members AS (
        SELECT
            ISNULL(ya.payment_method_id, 0) AS payment_method_id,
            ISNULL(ya.payer_type_id, 0) AS payer_type_id,
            ISNULL(ya.concession_type_id, 0) AS concession_type_id
        FROM Layercake.silv_payment_events AS pe
        LEFT JOIN Layercake.silv_member_year_attributes AS ya
            ON ya.contact_no = pe.contact_no
            AND ya.campaign_year = pe.campaign_year
        WHERE pe.campaign_year = @last_full_year
    ),

    corporate AS (
        SELECT
            COUNT(*) AS paid_members,
            COUNT(CASE WHEN pm.payer_type_id = 2 THEN 1 END) AS corporate_paid_members
        FROM paid_members AS pm
    ),

    amounts AS (
        SELECT
            SUM(ev.invoiced_subtotal_gbp) AS invoiced_subtotal_gbp_total,
            SUM(ev.subs_amount_gbp) AS subs_amount_gbp_total
        FROM Layercake.silv_membership_events AS ev
        WHERE ev.campaign_year = @last_full_year
            AND ev.event_type IN ('Join', 'Renewal', 'Readmission')
    ),

    measures AS (
        SELECT
            1 AS measure_order,
            CAST('paid_members_by_payment_method' AS varchar(40)) AS measure,
            CAST(rpm.payment_method_name AS nvarchar(100)) AS category,
            CAST(COUNT(*) AS decimal(19, 4)) AS value
        FROM paid_members AS pm
        INNER JOIN Layercake.silv_ref_payment_method AS rpm
            ON rpm.id = pm.payment_method_id
        GROUP BY rpm.payment_method_name

        UNION ALL

        SELECT
            2,
            'corporate_paid_members',
            NULL,
            CAST(c.corporate_paid_members AS decimal(19, 4))
        FROM corporate AS c

        UNION ALL

        SELECT
            3,
            'corporate_share_pct',
            NULL,
            CAST(
                ROUND(100.0 * c.corporate_paid_members / NULLIF(c.paid_members, 0), 1) AS decimal(5, 1)
            )
        FROM corporate AS c

        UNION ALL

        SELECT
            4,
            'invoiced_subtotal_gbp_total',
            NULL,
            CAST(a.invoiced_subtotal_gbp_total AS decimal(19, 4))
        FROM amounts AS a

        UNION ALL

        SELECT
            5,
            'subs_amount_gbp_total',
            NULL,
            CAST(a.subs_amount_gbp_total AS decimal(19, 4))
        FROM amounts AS a

        UNION ALL

        SELECT
            6,
            'paid_members_by_concession_type',
            CAST(rct.concession_type_name AS nvarchar(100)),
            CAST(COUNT(*) AS decimal(19, 4))
        FROM paid_members AS pm
        INNER JOIN Layercake.silv_ref_concession_type AS rct
            ON rct.id = pm.concession_type_id
        GROUP BY rct.concession_type_name
    )

    SELECT
        @last_full_year AS campaign_year,
        m.measure,
        m.category,
        m.value
    FROM measures AS m
    ORDER BY m.measure_order, m.category;
END;
