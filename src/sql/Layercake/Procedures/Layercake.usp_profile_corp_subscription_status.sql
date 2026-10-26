CREATE OR ALTER PROCEDURE Layercake.usp_profile_corp_subscription_status
AS
/*
    Count-only profile of Subs.vwCorpSubscriptions (RULE-096, Q-027): source rows (not
    contacts or years) by each 'Sub Status' value and by each 'Sub User Status' value,
    every value that occurs, so the active value can be confirmed.
*/
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.status_column,
        s.status_value,
        COUNT(*) AS row_count
    FROM Subs.vwCorpSubscriptions AS cs
    CROSS APPLY (
        VALUES
            (CAST('Sub Status' AS varchar(50)), CAST(cs.[Sub Status] AS nvarchar(100))),
            (CAST('Sub User Status' AS varchar(50)), CAST(cs.[Sub User Status] AS nvarchar(100)))
    ) AS s (status_column, status_value)
    GROUP BY
        s.status_column,
        s.status_value
    ORDER BY
        s.status_column,
        s.status_value;
END;
