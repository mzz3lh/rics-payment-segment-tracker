EXEC tSQLt.NewTestClass 'test_MOD005_dev';
GO

CREATE PROCEDURE test_MOD005_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_invoice_line_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_currency', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_currency', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
END;
GO

CREATE PROCEDURE test_MOD005_dev.[test line type spellings of one new pair keep the upper case and shortest spelling]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (9001, N'C0000901', N'INV-9001', N'V-9001', N'abcfee', N'inv', 0),
           (9002, N'C0000901', N'INV-9001', N'V-9001', N'ABCFEE  ', N'INV ', 0),
           (9003, N'C0000901', N'INV-9001', N'V-9001', N'ABCFEE', N'INV', 0),
           (9004, N'C0000901', N'INV-9001', N'V-9001', N'AbcFee', N'Inv', 0);

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    SELECT CAST(t.item_code AS varbinary(100)) AS item_code_bytes,
           CAST(t.ric_invoice_type AS varbinary(20)) AS ric_invoice_type_bytes,
           CAST(t.line_type AS varbinary(40)) AS line_type_bytes
    INTO #Actual
    FROM Layercake.silv_ref_invoice_line_type AS t;

    SELECT v.item_code_bytes, v.ric_invoice_type_bytes, v.line_type_bytes
    INTO #Expected
    FROM (VALUES (CAST(N'ABCFEE' AS varbinary(100)), CAST(N'INV' AS varbinary(20)), CAST('unmapped' AS varbinary(40)))
         ) AS v(item_code_bytes, ric_invoice_type_bytes, line_type_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD005_dev.[test new line type rows carry the load log id and equal created and updated times]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (9011, N'C0000902', N'INV-9011', N'V-9011', N'NEWFEE', N'INV', 0);

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    DECLARE @LogId bigint = (SELECT log_id FROM Layercake.etl_run_log);

    SELECT t.item_code, t.load_id,
           CASE WHEN t.created_at IS NOT NULL AND t.created_at = t.updated_at THEN 1 ELSE 0 END AS times_set
    INTO #Actual
    FROM Layercake.silv_ref_invoice_line_type AS t;

    SELECT v.item_code, v.load_id, v.times_set
    INTO #Expected
    FROM (VALUES (CAST(N'NEWFEE' AS nvarchar(50)), @LogId, 1)) AS v(item_code, load_id, times_set);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @StepName varchar(128) = (SELECT step_name FROM Layercake.etl_run_log);
    EXEC tSQLt.AssertEqualsString 'silv_ref_invoice_line_type', @StepName;
END;
GO

CREATE PROCEDURE test_MOD005_dev.[test currency spellings of one new code keep the upper case spelling and the load log id]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_currency, _is_deleted)
    VALUES (9101, N'C0000911', 2025, N'INV-9101', N'V-9101', N'usd', 0),
           (9102, N'C0000912', 2025, N'INV-9102', N'V-9102', N'Usd', 0),
           (9103, N'C0000913', 2025, N'INV-9103', N'V-9103', N'USD', 0);

    EXEC Layercake.usp_load_silv_ref_currency;

    DECLARE @LogId bigint = (SELECT log_id FROM Layercake.etl_run_log);

    SELECT CAST(c.currency_code AS varbinary(6)) AS currency_code_bytes, c.load_id
    INTO #Actual
    FROM Layercake.silv_ref_currency AS c;

    SELECT v.currency_code_bytes, v.load_id
    INTO #Expected
    FROM (VALUES (CAST(N'USD' AS varbinary(6)), @LogId)) AS v(currency_code_bytes, load_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD005_dev.[test dim_currency takes a case only change of a silver code as one update]
AS
BEGIN
    SET IDENTITY_INSERT Layercake.silv_ref_currency ON;
    INSERT INTO Layercake.silv_ref_currency (id, currency_code, load_id, created_at)
    VALUES (1, N'gbp', 7, '2026-02-01T10:00:00');
    SET IDENTITY_INSERT Layercake.silv_ref_currency OFF;

    INSERT INTO Layercake.dim_currency (id, currency_code, load_id, created_at, updated_at)
    VALUES (1, N'GBP', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    EXEC Layercake.usp_load_dim_currency;

    DECLARE @LogId bigint = (SELECT log_id FROM Layercake.etl_run_log);

    SELECT d.id, CAST(d.currency_code AS varbinary(6)) AS currency_code_bytes, d.load_id, d.created_at,
           CASE WHEN d.updated_at > '2026-02-01T10:00:00' THEN 1 ELSE 0 END AS updated_later
    INTO #Actual
    FROM Layercake.dim_currency AS d;

    SELECT v.id, v.currency_code_bytes, v.load_id, v.created_at, v.updated_later
    INTO #Expected
    FROM (VALUES (1, CAST(N'gbp' AS varbinary(6)), @LogId, CAST('2026-02-01T10:00:00' AS datetime2(3)), 1)
         ) AS v(id, currency_code_bytes, load_id, created_at, updated_later);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD005_dev.[test failed dim_currency insert also rolls back the update made before it]
AS
BEGIN
    ALTER TABLE Layercake.dim_currency
        ADD CONSTRAINT ck_test_MOD005_dev_reject CHECK (currency_code <> N'XXX');

    SET IDENTITY_INSERT Layercake.silv_ref_currency ON;
    INSERT INTO Layercake.silv_ref_currency (id, currency_code, load_id, created_at)
    VALUES (1, N'gbp', 7, '2026-02-01T10:00:00'),
           (9, N'XXX', 7, '2026-02-01T10:00:00');
    SET IDENTITY_INSERT Layercake.silv_ref_currency OFF;

    INSERT INTO Layercake.dim_currency (id, currency_code, load_id, created_at, updated_at)
    VALUES (1, N'GBP', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    BEGIN TRY
        EXEC Layercake.usp_load_dim_currency;
        EXEC tSQLt.Fail 'usp_load_dim_currency did not raise the expected error 547.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    SELECT d.id, CAST(d.currency_code AS varbinary(6)) AS currency_code_bytes, d.load_id, d.created_at, d.updated_at
    INTO #Actual
    FROM Layercake.dim_currency AS d;

    SELECT v.id, v.currency_code_bytes, v.load_id, v.created_at, v.updated_at
    INTO #Expected
    FROM (VALUES (1, CAST(N'GBP' AS varbinary(6)), CAST(7 AS bigint),
                  CAST('2026-02-01T10:00:00' AS datetime2(3)), CAST('2026-02-01T10:00:00' AS datetime2(3)))
         ) AS v(id, currency_code_bytes, load_id, created_at, updated_at);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, CASE WHEN l.error_message LIKE N'%error 547%' THEN 1 ELSE 0 END AS has_error
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.has_error
    INTO #ExpectedLog
    FROM (VALUES (CAST('Failed' AS varchar(10)), 1)) AS v(status, has_error);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
