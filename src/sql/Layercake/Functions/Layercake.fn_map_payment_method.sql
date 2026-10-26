/*====================================================================
    Layercake.fn_map_payment_method
    Maps a source payment mode code (brnz_subs_invoice.inv_payment_method,
    brnz_subs_invoice_line.paymmode) to a silv_ref_payment_method id
    (RULE-007 to RULE-009). Surrounding spaces are trimmed and case is
    ignored (answers 2026-10-26): null, empty or spaces only give
    0 Unknown; a code matching no method's source_code gives
    -1 Unrecognised.
====================================================================*/
CREATE OR ALTER FUNCTION Layercake.fn_map_payment_method
(
    @code nvarchar(20)
)
RETURNS int
AS
BEGIN
    DECLARE @trimmed nvarchar(20) = LTRIM(RTRIM(@code)),
            @id      int;

    IF @trimmed IS NULL OR @trimmed = N''
        RETURN 0;

    -- Only the five methods carry a source_code; the reserved rows have none.
    -- UPPER on both sides keeps the match case-insensitive under any collation.
    SELECT @id = r.id
    FROM Layercake.silv_ref_payment_method AS r
    WHERE r.id > 0
      AND UPPER(r.source_code) = UPPER(@trimmed);

    RETURN COALESCE(@id, -1);
END;
