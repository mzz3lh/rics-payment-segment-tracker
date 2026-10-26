CREATE OR ALTER PROCEDURE Layercake.usp_profile_custtrans_grain
AS
/*
    Count-only grain profile of synapse_fo.CUSTTRANS_RICS (RULE-095, Q-021).
    Invoice rows only: TRANSTYPE not 8 or 24 (rows with no TRANSTYPE are not classed as
    invoice rows), invoice number containing neither 'CRE' nor 'FTCN'. An invoice is
    ACCOUNTNUM + INVOICE, since one invoice number can occur on two accounts.
    Returns one row per measure and value that occurs, with the number of invoices.
*/
BEGIN
    SET NOCOUNT ON;

    WITH invoice_profile AS (
        SELECT
            ct.ACCOUNTNUM,
            ct.INVOICE,
            COUNT(*) AS row_count,
            COUNT(DISTINCT ct.productcode) AS productcode_count,
            MAX(CASE WHEN ct.PostingType_Description = 'Sales tax' THEN 1 ELSE 0 END) AS has_sales_tax_row
        FROM synapse_fo.CUSTTRANS_RICS AS ct
        WHERE ct.TRANSTYPE NOT IN (8, 24)
            AND ct.INVOICE NOT LIKE N'%CRE%'
            AND ct.INVOICE NOT LIKE N'%FTCN%'
        GROUP BY
            ct.ACCOUNTNUM,
            ct.INVOICE
    )

    SELECT
        m.measure,
        m.measure_value,
        COUNT(*) AS invoice_count
    FROM invoice_profile AS ip
    CROSS APPLY (
        VALUES
            (CAST('rows_per_invoice' AS varchar(50)), CAST(ip.row_count AS varchar(50))),
            (CAST('distinct_productcodes' AS varchar(50)), CAST(ip.productcode_count AS varchar(50))),
            (CAST('has_sales_tax_row' AS varchar(50)), CAST(ip.has_sales_tax_row AS varchar(50)))
    ) AS m (measure, measure_value)
    GROUP BY
        m.measure,
        m.measure_value
    ORDER BY
        m.measure,
        m.measure_value;
END;
