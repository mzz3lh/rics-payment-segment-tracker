/*====================================================================
    Layercake.vw_silv_eligible_invoice
    Silver layer - one row per eligible subscription invoice (RULE-014),
    shared by the attributes load and the event amount load so both use
    the same eligibility. Only live invoices with an account_num and a
    campaign_year count; contact_no = account_num.
      (a) credit note: invoice LIKE '%FTCN%', or LIKE '%CRE%' unless
          full_invoice_amount_cur = 0 (a NULL amount is a credit note,
          a NULL invoice number is not)
      (b) fully credited: fully_credited = 'Y' only
      (c) fee-only: at least one live own line typed 'enrolment or
          application fee' and every other live own line 'tax'; a line
          with no mapping row counts as unmapped, and a NULL
          ricinvoicetype is matched as N'' (answers 2026-10-27)
    Where a contact-year has no invoice passing (a) to (c), its fully
    credited invoices passing (a) and (c) are eligible instead.
    invoice_seq is the position in trans_date order (a NULL trans_date
    first, ties by rec_id, Q-036); is_segment_invoice marks the latest
    (RULE-079).
====================================================================*/
CREATE OR ALTER VIEW Layercake.vw_silv_eligible_invoice
AS
WITH own_line AS
(
    SELECT i.rec_id,
           COALESCE(m.line_type, 'unmapped') AS line_type
    FROM Layercake.brnz_subs_invoice AS i
    INNER JOIN Layercake.brnz_subs_invoice_line AS l
        ON  l.accountnum = i.account_num
        AND l.voucher = i.voucher
        AND l._is_deleted = 0
    LEFT JOIN Layercake.silv_ref_invoice_line_type AS m
        ON  m.item_code = l.productcode
        AND m.ric_invoice_type = ISNULL(l.ricinvoicetype, N'')
    WHERE i._is_deleted = 0
),
fee_only AS
(
    SELECT o.rec_id
    FROM own_line AS o
    GROUP BY o.rec_id
    HAVING SUM(CASE WHEN o.line_type = 'enrolment or application fee' THEN 1 ELSE 0 END) > 0
       AND SUM(CASE WHEN o.line_type IN ('enrolment or application fee', 'tax') THEN 0 ELSE 1 END) = 0
),
candidate AS
(
    SELECT i.account_num AS contact_no,
           i.campaign_year,
           i.rec_id,
           i.invoice,
           i.voucher,
           i.trans_date,
           i.inv_payment_method,
           i.inv_currency,
           CASE WHEN i.fully_credited = N'Y' THEN 1 ELSE 0 END AS fully_credited_flag,
           CASE WHEN i.full_concession_flag = N'Y' THEN 1 ELSE 0 END AS full_concession_flag
    FROM Layercake.brnz_subs_invoice AS i
    WHERE i._is_deleted = 0
      AND i.account_num IS NOT NULL
      AND i.campaign_year IS NOT NULL
      -- A NULL invoice number falls through to 0: it is not a credit note.
      AND CASE WHEN i.invoice LIKE N'%FTCN%' THEN 1
               WHEN i.invoice LIKE N'%CRE%'
                    AND (i.full_invoice_amount_cur <> 0 OR i.full_invoice_amount_cur IS NULL) THEN 1
               ELSE 0
          END = 0
      AND NOT EXISTS (SELECT 1 FROM fee_only AS f WHERE f.rec_id = i.rec_id)
),
eligible AS
(
    SELECT c.contact_no,
           c.campaign_year,
           c.rec_id,
           c.invoice,
           c.voucher,
           c.trans_date,
           c.inv_payment_method,
           c.inv_currency,
           c.fully_credited_flag,
           c.full_concession_flag,
           MIN(c.fully_credited_flag) OVER (PARTITION BY c.contact_no, c.campaign_year) AS all_fully_credited
    FROM candidate AS c
)
SELECT e.contact_no,
       e.campaign_year,
       e.rec_id,
       e.invoice,
       e.voucher,
       e.trans_date,
       e.inv_payment_method,
       e.inv_currency,
       CAST(e.fully_credited_flag AS bit) AS is_fully_credited,
       CAST(e.full_concession_flag AS bit) AS is_full_concession,
       ROW_NUMBER() OVER (PARTITION BY e.contact_no, e.campaign_year
                          ORDER BY e.trans_date, e.rec_id) AS invoice_seq,
       CAST(CASE WHEN ROW_NUMBER() OVER (PARTITION BY e.contact_no, e.campaign_year
                                         ORDER BY e.trans_date DESC, e.rec_id DESC) = 1
                 THEN 1 ELSE 0 END AS bit) AS is_segment_invoice
FROM eligible AS e
-- Fully credited invoices stand in only where the contact-year has no other.
WHERE e.fully_credited_flag = 0
   OR e.all_fully_credited = 1;
