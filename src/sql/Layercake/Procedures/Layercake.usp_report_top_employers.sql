CREATE OR ALTER PROCEDURE Layercake.usp_report_top_employers
    @as_of_date date = NULL
AS
/*
    Count-only top employers (REQ-013, RULE-061, RULE-062; Q-010): paid members per firm in the
    last full Campaign Year, the 25 firms with the most, ties broken by employer_account_number
    (ascending) so the list is the same on every run.
    - Last full Campaign Year: the ref_campaign_year_config year before the one covering
      @as_of_date (NULL = today, ADR-003). The report fails if no year covers the date or none
      precedes it.
    - Paid member: a silv_payment_events row for that year with payer type 2 Corporate or
      1 Individual in silv_member_year_attributes. 0 Unknown (and the other reserved ids) is left
      out, so corporate + individual = paid_members; the coverage report counts them.
    - Corporate member: its scheme-link firm (CE.vwCorporateSchemes AccountNumber / AccountName
      of a live subscription's scheme for that year, Q-027); with no scheme link, its
      contact-record firm, still in the corporate column.
    - Individual member: its contact-record firm (CE.vwContact.ParentCustomerId of type 'account'
      to CE.vwAccount AccountNumber / name).
    - A member counts once: where it has several scheme firms the lowest scheme_no, then the lowest
      AccountNumber, wins (as corporate_account_ref takes the lowest scheme_no, Q-036); where it
      has several contact-record firms the lowest AccountNumber wins.
    A firm's name is the highest of the names its members carry, should the two sources differ.
    A member with no firm is not listed. Aggregates only (RULE-064).
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
        THROW 50014, N'usp_report_top_employers: no Campaign Year before the one covering @as_of_date in Layercake.ref_campaign_year_config.', 1;

    WITH members AS (
        SELECT
            pe.contact_no,
            ya.payer_type_id
        FROM Layercake.silv_payment_events AS pe
        INNER JOIN Layercake.silv_member_year_attributes AS ya
            ON ya.contact_no = pe.contact_no
            AND ya.campaign_year = pe.campaign_year
        WHERE pe.campaign_year = @last_full_year
            AND ya.payer_type_id IN (1, 2)
    ),

    scheme_firms AS (
        SELECT
            cs.contact_no,
            sc.AccountNumber AS account_number,
            sc.AccountName AS account_name,
            ROW_NUMBER() OVER (
                PARTITION BY cs.contact_no
                ORDER BY cs.scheme_no, sc.AccountNumber
            ) AS firm_rank
        FROM Layercake.brnz_corporate_subscription AS cs
        INNER JOIN CE.vwCorporateSchemes AS sc
            ON sc.apuk_subscriptionnumber = cs.scheme_no
        WHERE cs.sub_campaign_year = @last_full_year
            AND cs._is_deleted = 0
            AND cs.sub_status = N'Active'
            AND cs.sub_user_status = N'Active'
            AND sc.AccountNumber IS NOT NULL
    ),

    contact_firms AS (
        SELECT
            ct.Rics_contactno AS contact_no,
            ac.AccountNumber AS account_number,
            ac.name AS account_name,
            ROW_NUMBER() OVER (
                PARTITION BY ct.Rics_contactno
                ORDER BY ac.AccountNumber
            ) AS firm_rank
        FROM CE.vwContact AS ct
        INNER JOIN CE.vwAccount AS ac
            ON ac.AccountId = ct.ParentCustomerId
        WHERE ct.ParentCustomerIdType = N'account'
            AND ac.AccountNumber IS NOT NULL
    ),

    member_firms AS (
        SELECT
            m.payer_type_id,
            CASE
                WHEN sf.account_number IS NOT NULL THEN sf.account_number
                ELSE cf.account_number
            END AS employer_account_number,
            CASE
                WHEN sf.account_number IS NOT NULL THEN sf.account_name
                ELSE cf.account_name
            END AS employer_name
        FROM members AS m
        LEFT JOIN scheme_firms AS sf
            ON sf.contact_no = m.contact_no
            AND sf.firm_rank = 1
            AND m.payer_type_id = 2
        LEFT JOIN contact_firms AS cf
            ON cf.contact_no = m.contact_no
            AND cf.firm_rank = 1
    ),

    firm_counts AS (
        SELECT
            mf.employer_account_number,
            MAX(mf.employer_name) AS employer_name,
            SUM(CASE WHEN mf.payer_type_id = 2 THEN 1 ELSE 0 END) AS corporate_paid_members,
            SUM(CASE WHEN mf.payer_type_id = 1 THEN 1 ELSE 0 END) AS individual_paid_members,
            COUNT(*) AS paid_members
        FROM member_firms AS mf
        WHERE mf.employer_account_number IS NOT NULL
        GROUP BY mf.employer_account_number
    )

    SELECT TOP (25)
        fc.employer_account_number,
        fc.employer_name,
        fc.corporate_paid_members,
        fc.individual_paid_members,
        fc.paid_members
    FROM firm_counts AS fc
    ORDER BY fc.paid_members DESC, fc.employer_account_number ASC;
END;
