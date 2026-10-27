EXEC tSQLt.NewTestClass 'test_MOD005';
GO

CREATE PROCEDURE test_MOD005.[SetUp]
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

/* ===================== AC-007-01: new item codes added as unmapped ===================== */

CREATE PROCEDURE test_MOD005.[test TC-005-001 new item code NEWFEE is added once as unmapped and listed pairs are kept]
AS
BEGIN
    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id, created_at, updated_at)
    VALUES (N'SUBS_MRICS', N'SUB', 'subscription', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (5001, N'C0000001', N'INV-5001', N'V-5001', N'SUBS_MRICS', N'SUB', 0),
           (5002, N'C0000001', N'INV-5001', N'V-5001', N'NEWFEE', N'INV', 0);

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    SELECT CAST(t.item_code AS varbinary(100)) AS item_code_bytes,
           CAST(t.ric_invoice_type AS varbinary(20)) AS ric_invoice_type_bytes,
           CAST(t.line_type AS varbinary(40)) AS line_type_bytes
    INTO #Actual
    FROM Layercake.silv_ref_invoice_line_type AS t;

    SELECT v.item_code_bytes, v.ric_invoice_type_bytes, v.line_type_bytes
    INTO #Expected
    FROM (VALUES (CAST(N'SUBS_MRICS' AS varbinary(100)), CAST(N'SUB' AS varbinary(20)), CAST('subscription' AS varbinary(40))),
                 (CAST(N'NEWFEE' AS varbinary(100)), CAST(N'INV' AS varbinary(20)), CAST('unmapped' AS varbinary(40)))
         ) AS v(item_code_bytes, ric_invoice_type_bytes, line_type_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 1, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-002 second line type load leaves exactly one NEWFEE row and changes nothing]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (5011, N'C0000002', N'INV-5011', N'V-5011', N'NEWFEE', N'INV', 0);

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    SELECT * INTO #AfterFirst FROM Layercake.silv_ref_invoice_line_type;

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    EXEC tSQLt.AssertEqualsTable '#AfterFirst', 'Layercake.silv_ref_invoice_line_type';

    DECLARE @NewFeeRows int = (SELECT COUNT(*) FROM Layercake.silv_ref_invoice_line_type WHERE item_code = N'NEWFEE');
    EXEC tSQLt.AssertEquals 1, @NewFeeRows;

    DECLARE @LineTypeBytes varbinary(40) = (SELECT CAST(line_type AS varbinary(40)) FROM Layercake.silv_ref_invoice_line_type WHERE item_code = N'NEWFEE');
    EXEC tSQLt.AssertEquals 0x756E6D6170706564, @LineTypeBytes;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 1, 0, 0),
                 (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-003 a code repeated on many lines adds one row per item code and RIC invoice type pair]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (5021, N'C0000003', N'INV-5021', N'V-5021', N'NEWFEE', N'INV', 0),
           (5022, N'C0000004', N'INV-5022', N'V-5022', N'NEWFEE', N'INV', 0),
           (5023, N'C0000005', N'INV-5023', N'V-5023', N'NEWFEE', N'INV', 0),
           (5024, N'C0000005', N'INV-5024', N'V-5024', N'NEWFEE', N'CRN', 0);

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    SELECT CAST(t.item_code AS varbinary(100)) AS item_code_bytes,
           CAST(t.ric_invoice_type AS varbinary(20)) AS ric_invoice_type_bytes,
           CAST(t.line_type AS varbinary(40)) AS line_type_bytes
    INTO #Actual
    FROM Layercake.silv_ref_invoice_line_type AS t;

    SELECT v.item_code_bytes, v.ric_invoice_type_bytes, v.line_type_bytes
    INTO #Expected
    FROM (VALUES (CAST(N'NEWFEE' AS varbinary(100)), CAST(N'INV' AS varbinary(20)), CAST('unmapped' AS varbinary(40))),
                 (CAST(N'NEWFEE' AS varbinary(100)), CAST(N'CRN' AS varbinary(20)), CAST('unmapped' AS varbinary(40)))
         ) AS v(item_code_bytes, ric_invoice_type_bytes, line_type_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 2, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-004 two new codes differing only in case in one load add a single unmapped row]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (5031, N'C0000006', N'INV-5031', N'V-5031', N'ABCFEE', N'INV', 0),
           (5032, N'C0000007', N'INV-5032', N'V-5032', N'abcfee', N'inv', 0);

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    DECLARE @Rows int = (SELECT COUNT(*) FROM Layercake.silv_ref_invoice_line_type);
    EXEC tSQLt.AssertEquals 1, @Rows;

    DECLARE @MatchingRows int = (SELECT COUNT(*) FROM Layercake.silv_ref_invoice_line_type
                                 WHERE item_code = N'ABCFEE' AND ric_invoice_type = N'INV'
                                   AND CAST(line_type AS varbinary(40)) = CAST('unmapped' AS varbinary(40)));
    EXEC tSQLt.AssertEquals 1, @MatchingRows;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 1, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-005 lines with a NULL empty or blank productcode add no mapping row]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (5041, N'C0000008', N'INV-5041', N'V-5041', NULL, N'INV', 0),
           (5042, N'C0000008', N'INV-5041', N'V-5041', N'', N'INV', 0),
           (5043, N'C0000008', N'INV-5041', N'V-5041', N'   ', N'INV', 0),
           (5044, N'C0000008', N'INV-5041', N'V-5041', NULL, NULL, 0);

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_ref_invoice_line_type';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-006 a NULL ricinvoicetype is added as the empty RIC invoice type and matches a listed empty type]
AS
BEGIN
    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id, created_at, updated_at)
    VALUES (N'SUBS_MRICS', N'', 'subscription', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (5051, N'C0000009', N'INV-5051', N'V-5051', N'NULLTYPE', NULL, 0),
           (5052, N'C0000009', N'INV-5051', N'V-5051', N'NULLTYPE', N'', 0),
           (5053, N'C0000009', N'INV-5051', N'V-5051', N'SUBS_MRICS', NULL, 0);

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    SELECT CAST(t.item_code AS varbinary(100)) AS item_code_bytes,
           CAST(t.ric_invoice_type AS varbinary(20)) AS ric_invoice_type_bytes,
           CAST(t.line_type AS varbinary(40)) AS line_type_bytes
    INTO #Actual
    FROM Layercake.silv_ref_invoice_line_type AS t;

    SELECT v.item_code_bytes, v.ric_invoice_type_bytes, v.line_type_bytes
    INTO #Expected
    FROM (VALUES (CAST(N'SUBS_MRICS' AS varbinary(100)), CAST(N'' AS varbinary(20)), CAST('subscription' AS varbinary(40))),
                 (CAST(N'NULLTYPE' AS varbinary(100)), CAST(N'' AS varbinary(20)), CAST('unmapped' AS varbinary(40)))
         ) AS v(item_code_bytes, ric_invoice_type_bytes, line_type_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @NullTypeRows int = (SELECT COUNT(*) FROM Layercake.silv_ref_invoice_line_type WHERE ric_invoice_type IS NULL);
    EXEC tSQLt.AssertEquals 0, @NullTypeRows;

    DECLARE @ListedLoadId bigint = (SELECT load_id FROM Layercake.silv_ref_invoice_line_type WHERE item_code = N'SUBS_MRICS');
    EXEC tSQLt.AssertEquals 7, @ListedLoadId;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 1, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-007 a code seen only on a soft deleted line adds no mapping row]
AS
BEGIN
    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id, created_at, updated_at)
    VALUES (N'SUBS_MRICS', N'SUB', 'subscription', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted, _deleted_at)
    VALUES (5061, N'C0000010', N'INV-5061', N'V-5061', N'SUBS_MRICS', N'SUB', 0, NULL),
           (5062, N'C0000010', N'INV-5062', N'V-5062', N'GONEFEE', N'INV', 1, '2026-03-01T10:00:00');

    SELECT * INTO #Before FROM Layercake.silv_ref_invoice_line_type;

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    EXEC tSQLt.AssertEqualsTable '#Before', 'Layercake.silv_ref_invoice_line_type';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-008 codes differing from a listed pair only in case or trailing spaces add no row]
AS
BEGIN
    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id, created_at, updated_at)
    VALUES (N'NEWFEE', N'INV', 'unmapped', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (5071, N'C0000011', N'INV-5071', N'V-5071', N'newfee', N'inv', 0),
           (5072, N'C0000011', N'INV-5071', N'V-5071', N'NEWFEE  ', N'INV', 0),
           (5073, N'C0000011', N'INV-5071', N'V-5071', N'NewFee', N'INV  ', 0);

    SELECT * INTO #Before FROM Layercake.silv_ref_invoice_line_type;

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    EXEC tSQLt.AssertEqualsTable '#Before', 'Layercake.silv_ref_invoice_line_type';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-009 a code with a leading space or other characters is a new unmapped code]
AS
BEGIN
    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id, created_at, updated_at)
    VALUES (N'NEWFEE', N'INV', 'unmapped', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (5081, N'C0000012', N'INV-5081', N'V-5081', N' NEWFEE', N'INV', 0),
           (5082, N'C0000012', N'INV-5081', N'V-5081', N'NEWFEE2', N'INV', 0);

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    SELECT CAST(t.item_code AS varbinary(100)) AS item_code_bytes,
           CAST(t.ric_invoice_type AS varbinary(20)) AS ric_invoice_type_bytes,
           CAST(t.line_type AS varbinary(40)) AS line_type_bytes
    INTO #Actual
    FROM Layercake.silv_ref_invoice_line_type AS t;

    SELECT v.item_code_bytes, v.ric_invoice_type_bytes, v.line_type_bytes
    INTO #Expected
    FROM (VALUES (CAST(N'NEWFEE' AS varbinary(100)), CAST(N'INV' AS varbinary(20)), CAST('unmapped' AS varbinary(40))),
                 (CAST(N' NEWFEE' AS varbinary(100)), CAST(N'INV' AS varbinary(20)), CAST('unmapped' AS varbinary(40))),
                 (CAST(N'NEWFEE2' AS varbinary(100)), CAST(N'INV' AS varbinary(20)), CAST('unmapped' AS varbinary(40)))
         ) AS v(item_code_bytes, ric_invoice_type_bytes, line_type_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 2, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

/* ===================== AC-007-02: mapped rows never overwritten ===================== */

CREATE PROCEDURE test_MOD005.[test TC-005-010 a code mapped by hand to readmission fee keeps its line type after the next load]
AS
BEGIN
    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id, created_at, updated_at)
    VALUES (N'RAFEE_MRICS', N'INV', 'readmission fee', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (5101, N'C0000013', N'INV-5101', N'V-5101', N'RAFEE_MRICS', N'INV', 0);

    SELECT * INTO #Before FROM Layercake.silv_ref_invoice_line_type;

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    EXEC tSQLt.AssertEqualsTable '#Before', 'Layercake.silv_ref_invoice_line_type';

    DECLARE @LineTypeBytes varbinary(40) = (SELECT CAST(line_type AS varbinary(40)) FROM Layercake.silv_ref_invoice_line_type WHERE item_code = N'RAFEE_MRICS');
    EXEC tSQLt.AssertEquals 0x726561646D697373696F6E20666565, @LineTypeBytes;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-011 a line differing from a hand mapped pair only in case or trailing spaces leaves it unchanged]
AS
BEGIN
    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id, created_at, updated_at)
    VALUES (N'RAFEE_MRICS', N'INV', 'readmission fee', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (5111, N'C0000014', N'INV-5111', N'V-5111', N'rafee_mrics ', N'inv', 0),
           (5112, N'C0000014', N'INV-5111', N'V-5111', N'Rafee_Mrics', N'INV ', 0);

    SELECT * INTO #Before FROM Layercake.silv_ref_invoice_line_type;

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    EXEC tSQLt.AssertEqualsTable '#Before', 'Layercake.silv_ref_invoice_line_type';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-012 existing rows are kept unchanged while a new code is added including rows with no live line]
AS
BEGIN
    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id, created_at, updated_at)
    VALUES (N'RAFEE_MRICS', N'INV', 'readmission fee', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00'),
           (N'OLDCODE', N'INV', 'other', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00'),
           (N'WAITING', N'INV', 'unmapped', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (5121, N'C0000015', N'INV-5121', N'V-5121', N'WAITING', N'INV', 0),
           (5122, N'C0000015', N'INV-5121', N'V-5121', N'NEWFEE', N'INV', 0);

    SELECT * INTO #Before FROM Layercake.silv_ref_invoice_line_type;

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    SELECT t.item_code, t.ric_invoice_type, t.line_type, t.load_id, t.created_at, t.updated_at
    INTO #ActualExisting
    FROM Layercake.silv_ref_invoice_line_type AS t
    WHERE t.item_code <> N'NEWFEE';

    EXEC tSQLt.AssertEqualsTable '#Before', '#ActualExisting';

    DECLARE @NewRows int = (SELECT COUNT(*) FROM Layercake.silv_ref_invoice_line_type
                            WHERE item_code = N'NEWFEE' AND ric_invoice_type = N'INV'
                              AND CAST(line_type AS varbinary(40)) = CAST('unmapped' AS varbinary(40)));
    EXEC tSQLt.AssertEquals 1, @NewRows;

    DECLARE @TotalRows int = (SELECT COUNT(*) FROM Layercake.silv_ref_invoice_line_type);
    EXEC tSQLt.AssertEquals 4, @TotalRows;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 1, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-013 NEWFEE added as unmapped then mapped by hand stays readmission fee after the next load]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (5131, N'C0000016', N'INV-5131', N'V-5131', N'NEWFEE', N'INV', 0);

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    UPDATE Layercake.silv_ref_invoice_line_type
    SET line_type = 'readmission fee'
    WHERE item_code = N'NEWFEE' AND ric_invoice_type = N'INV';

    SELECT * INTO #AfterHandMapping FROM Layercake.silv_ref_invoice_line_type;

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    EXEC tSQLt.AssertEqualsTable '#AfterHandMapping', 'Layercake.silv_ref_invoice_line_type';

    SELECT CAST(t.item_code AS varbinary(100)) AS item_code_bytes,
           CAST(t.ric_invoice_type AS varbinary(20)) AS ric_invoice_type_bytes,
           CAST(t.line_type AS varbinary(40)) AS line_type_bytes
    INTO #Actual
    FROM Layercake.silv_ref_invoice_line_type AS t;

    SELECT v.item_code_bytes, v.ric_invoice_type_bytes, v.line_type_bytes
    INTO #Expected
    FROM (VALUES (CAST(N'NEWFEE' AS varbinary(100)), CAST(N'INV' AS varbinary(20)), CAST('readmission fee' AS varbinary(40)))
         ) AS v(item_code_bytes, ric_invoice_type_bytes, line_type_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 1, 0, 0),
                 (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD005.[test TC-005-014 failed line type load re-raises logs Failed and leaves the mapping unchanged]
AS
BEGIN
    ALTER TABLE Layercake.silv_ref_invoice_line_type
        ADD CONSTRAINT ck_test_MOD005_014_reject CHECK (item_code <> N'REJECTME');

    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id, created_at, updated_at)
    VALUES (N'SUBS_MRICS', N'SUB', 'subscription', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (5141, N'C0000017', N'INV-5141', N'V-5141', N'GOODNEW', N'INV', 0),
           (5142, N'C0000017', N'INV-5141', N'V-5141', N'REJECTME', N'INV', 0);

    SELECT * INTO #Before FROM Layercake.silv_ref_invoice_line_type;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_ref_invoice_line_type;
        EXEC tSQLt.Fail 'usp_load_silv_ref_invoice_line_type did not raise the expected error 547.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    EXEC tSQLt.AssertEqualsTable '#Before', 'Layercake.silv_ref_invoice_line_type';

    DECLARE @LogRows int = (SELECT COUNT(*) FROM Layercake.etl_run_log);
    EXEC tSQLt.AssertEquals 1, @LogRows;

    DECLARE @FailedWithMessage int = (SELECT COUNT(*) FROM Layercake.etl_run_log
                                      WHERE status = 'Failed' AND error_message IS NOT NULL);
    EXEC tSQLt.AssertEquals 1, @FailedWithMessage;
END;
GO

/* ===================== AC-007-03: currency list and dimension ===================== */

CREATE PROCEDURE test_MOD005.[test TC-005-015 invoices in GBP EUR and HKD give exactly those three currency codes]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_currency, _is_deleted)
    VALUES (6001, N'C0000101', 2025, N'INV-6001', N'V-6001', N'GBP', 0),
           (6002, N'C0000102', 2025, N'INV-6002', N'V-6002', N'EUR', 0),
           (6003, N'C0000103', 2025, N'INV-6003', N'V-6003', N'HKD', 0),
           (6004, N'C0000104', 2025, N'INV-6004', N'V-6004', N'GBP', 0);

    EXEC Layercake.usp_load_silv_ref_currency;

    SELECT CAST(c.currency_code AS varbinary(6)) AS currency_code_bytes
    INTO #Actual
    FROM Layercake.silv_ref_currency AS c;

    SELECT v.currency_code_bytes
    INTO #Expected
    FROM (VALUES (CAST(N'GBP' AS varbinary(6))), (CAST(N'EUR' AS varbinary(6))), (CAST(N'HKD' AS varbinary(6)))
         ) AS v(currency_code_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @DistinctIds int = (SELECT COUNT(DISTINCT id) FROM Layercake.silv_ref_currency WHERE id IS NOT NULL);
    EXEC tSQLt.AssertEquals 3, @DistinctIds;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 3, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-016 second currency load keeps every id and changes nothing]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_currency, _is_deleted)
    VALUES (6011, N'C0000111', 2025, N'INV-6011', N'V-6011', N'GBP', 0),
           (6012, N'C0000112', 2025, N'INV-6012', N'V-6012', N'EUR', 0),
           (6013, N'C0000113', 2025, N'INV-6013', N'V-6013', N'HKD', 0);

    EXEC Layercake.usp_load_silv_ref_currency;

    SELECT * INTO #AfterFirst FROM Layercake.silv_ref_currency;

    EXEC Layercake.usp_load_silv_ref_currency;

    EXEC tSQLt.AssertEqualsTable '#AfterFirst', 'Layercake.silv_ref_currency';

    DECLARE @Rows int = (SELECT COUNT(*) FROM Layercake.silv_ref_currency);
    EXEC tSQLt.AssertEquals 3, @Rows;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 3, 0, 0),
                 (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-017 dim_currency loaded after the currency list has the same id and code pairs]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_currency, _is_deleted)
    VALUES (6021, N'C0000121', 2025, N'INV-6021', N'V-6021', N'GBP', 0),
           (6022, N'C0000122', 2025, N'INV-6022', N'V-6022', N'EUR', 0),
           (6023, N'C0000123', 2025, N'INV-6023', N'V-6023', N'HKD', 0);

    EXEC Layercake.usp_load_silv_ref_currency;
    EXEC Layercake.usp_load_dim_currency;

    SELECT s.id, CAST(s.currency_code AS varbinary(6)) AS currency_code_bytes
    INTO #Silver
    FROM Layercake.silv_ref_currency AS s;

    SELECT d.id, CAST(d.currency_code AS varbinary(6)) AS currency_code_bytes
    INTO #Dim
    FROM Layercake.dim_currency AS d;

    EXEC tSQLt.AssertEqualsTable '#Silver', '#Dim';

    SELECT CAST(d.currency_code AS varbinary(6)) AS currency_code_bytes
    INTO #ActualCodes
    FROM Layercake.dim_currency AS d;

    SELECT v.currency_code_bytes
    INTO #ExpectedCodes
    FROM (VALUES (CAST(N'GBP' AS varbinary(6))), (CAST(N'EUR' AS varbinary(6))), (CAST(N'HKD' AS varbinary(6)))
         ) AS v(currency_code_bytes);

    EXEC tSQLt.AssertEqualsTable '#ExpectedCodes', '#ActualCodes';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 3, 0, 0),
                 (CAST('Success' AS varchar(10)), 3, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-018 second dim_currency load keeps every pair and changes nothing]
AS
BEGIN
    SET IDENTITY_INSERT Layercake.silv_ref_currency ON;
    INSERT INTO Layercake.silv_ref_currency (id, currency_code, load_id, created_at)
    VALUES (1, N'GBP', 7, '2026-02-01T10:00:00'),
           (2, N'EUR', 7, '2026-02-01T10:00:00'),
           (3, N'HKD', 7, '2026-02-01T10:00:00');
    SET IDENTITY_INSERT Layercake.silv_ref_currency OFF;

    EXEC Layercake.usp_load_dim_currency;

    SELECT * INTO #AfterFirst FROM Layercake.dim_currency;

    EXEC Layercake.usp_load_dim_currency;

    EXEC tSQLt.AssertEqualsTable '#AfterFirst', 'Layercake.dim_currency';

    SELECT d.id, CAST(d.currency_code AS varbinary(6)) AS currency_code_bytes
    INTO #Actual
    FROM Layercake.dim_currency AS d;

    SELECT v.id, v.currency_code_bytes
    INTO #Expected
    FROM (VALUES (1, CAST(N'GBP' AS varbinary(6))), (2, CAST(N'EUR' AS varbinary(6))), (3, CAST(N'HKD' AS varbinary(6)))
         ) AS v(id, currency_code_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 3, 0, 0),
                 (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-019 dim_currency load adds missing ids and leaves an existing row untouched]
AS
BEGIN
    SET IDENTITY_INSERT Layercake.silv_ref_currency ON;
    INSERT INTO Layercake.silv_ref_currency (id, currency_code, load_id, created_at)
    VALUES (1, N'GBP', 7, '2026-02-01T10:00:00'),
           (2, N'EUR', 7, '2026-02-01T10:00:00'),
           (3, N'HKD', 7, '2026-02-01T10:00:00');
    SET IDENTITY_INSERT Layercake.silv_ref_currency OFF;

    INSERT INTO Layercake.dim_currency (id, currency_code, load_id, created_at, updated_at)
    VALUES (1, N'GBP', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    EXEC Layercake.usp_load_dim_currency;

    SELECT d.id, CAST(d.currency_code AS varbinary(6)) AS currency_code_bytes
    INTO #Actual
    FROM Layercake.dim_currency AS d;

    SELECT v.id, v.currency_code_bytes
    INTO #Expected
    FROM (VALUES (1, CAST(N'GBP' AS varbinary(6))), (2, CAST(N'EUR' AS varbinary(6))), (3, CAST(N'HKD' AS varbinary(6)))
         ) AS v(id, currency_code_bytes);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT d.id, d.load_id, d.created_at, d.updated_at
    INTO #ActualExisting
    FROM Layercake.dim_currency AS d
    WHERE d.id = 1;

    SELECT v.id, v.load_id, v.created_at, v.updated_at
    INTO #ExpectedExisting
    FROM (VALUES (1, CAST(7 AS bigint), CAST('2026-02-01T10:00:00' AS datetime2(3)), CAST('2026-02-01T10:00:00' AS datetime2(3)))
         ) AS v(id, load_id, created_at, updated_at);

    EXEC tSQLt.AssertEqualsTable '#ExpectedExisting', '#ActualExisting';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 2, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-020 invoices with a NULL empty or blank currency add no currency row]
AS
BEGIN
    SET IDENTITY_INSERT Layercake.silv_ref_currency ON;
    INSERT INTO Layercake.silv_ref_currency (id, currency_code, load_id, created_at)
    VALUES (1, N'GBP', 7, '2026-02-01T10:00:00');
    SET IDENTITY_INSERT Layercake.silv_ref_currency OFF;

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_currency, _is_deleted)
    VALUES (6031, N'C0000131', 2025, N'INV-6031', N'V-6031', NULL, 0),
           (6032, N'C0000132', 2025, N'INV-6032', N'V-6032', N'', 0),
           (6033, N'C0000133', 2025, N'INV-6033', N'V-6033', N'   ', 0),
           (6034, N'C0000134', 2025, N'INV-6034', N'V-6034', N'GBP', 0);

    SELECT * INTO #Before FROM Layercake.silv_ref_currency;

    EXEC Layercake.usp_load_silv_ref_currency;

    EXEC tSQLt.AssertEqualsTable '#Before', 'Layercake.silv_ref_currency';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-021 a currency differing from a listed code only in case adds no row]
AS
BEGIN
    SET IDENTITY_INSERT Layercake.silv_ref_currency ON;
    INSERT INTO Layercake.silv_ref_currency (id, currency_code, load_id, created_at)
    VALUES (2, N'EUR', 7, '2026-02-01T10:00:00');
    SET IDENTITY_INSERT Layercake.silv_ref_currency OFF;

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_currency, _is_deleted)
    VALUES (6041, N'C0000141', 2025, N'INV-6041', N'V-6041', N'eur', 0),
           (6042, N'C0000142', 2025, N'INV-6042', N'V-6042', N'Eur', 0);

    SELECT * INTO #Before FROM Layercake.silv_ref_currency;

    EXEC Layercake.usp_load_silv_ref_currency;

    EXEC tSQLt.AssertEqualsTable '#Before', 'Layercake.silv_ref_currency';

    DECLARE @CodeBytes varbinary(6) = (SELECT CAST(currency_code AS varbinary(6)) FROM Layercake.silv_ref_currency WHERE id = 2);
    EXEC tSQLt.AssertEquals 0x450055005200, @CodeBytes;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-022 a currency seen only on a soft deleted invoice adds no row]
AS
BEGIN
    SET IDENTITY_INSERT Layercake.silv_ref_currency ON;
    INSERT INTO Layercake.silv_ref_currency (id, currency_code, load_id, created_at)
    VALUES (1, N'GBP', 7, '2026-02-01T10:00:00');
    SET IDENTITY_INSERT Layercake.silv_ref_currency OFF;

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_currency, _is_deleted, _deleted_at)
    VALUES (6051, N'C0000151', 2025, N'INV-6051', N'V-6051', N'GBP', 0, NULL),
           (6052, N'C0000152', 2025, N'INV-6052', N'V-6052', N'USD', 1, '2026-03-01T10:00:00');

    SELECT * INTO #Before FROM Layercake.silv_ref_currency;

    EXEC Layercake.usp_load_silv_ref_currency;

    EXEC tSQLt.AssertEqualsTable '#Before', 'Layercake.silv_ref_currency';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-023 a new currency gets a new id and listed currencies keep theirs]
AS
BEGIN
    SET IDENTITY_INSERT Layercake.silv_ref_currency ON;
    INSERT INTO Layercake.silv_ref_currency (id, currency_code, load_id, created_at)
    VALUES (1, N'GBP', 7, '2026-02-01T10:00:00'),
           (2, N'EUR', 7, '2026-02-01T10:00:00');
    SET IDENTITY_INSERT Layercake.silv_ref_currency OFF;

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_currency, _is_deleted)
    VALUES (6061, N'C0000161', 2025, N'INV-6061', N'V-6061', N'GBP', 0),
           (6062, N'C0000162', 2025, N'INV-6062', N'V-6062', N'EUR', 0),
           (6063, N'C0000163', 2025, N'INV-6063', N'V-6063', N'HKD', 0);

    SELECT * INTO #Before FROM Layercake.silv_ref_currency;

    EXEC Layercake.usp_load_silv_ref_currency;

    SELECT c.id, c.currency_code, c.load_id, c.created_at
    INTO #ActualExisting
    FROM Layercake.silv_ref_currency AS c
    WHERE c.id IN (1, 2);

    EXEC tSQLt.AssertEqualsTable '#Before', '#ActualExisting';

    DECLARE @HkdRows int = (SELECT COUNT(*) FROM Layercake.silv_ref_currency
                            WHERE currency_code = N'HKD' AND id IS NOT NULL AND id NOT IN (1, 2));
    EXEC tSQLt.AssertEquals 1, @HkdRows;

    DECLARE @TotalRows int = (SELECT COUNT(*) FROM Layercake.silv_ref_currency);
    EXEC tSQLt.AssertEquals 3, @TotalRows;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 1, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD005.[test TC-005-024 a new currency in several cases in one load adds a single row]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_currency, _is_deleted)
    VALUES (6071, N'C0000171', 2025, N'INV-6071', N'V-6071', N'USD', 0),
           (6072, N'C0000172', 2025, N'INV-6072', N'V-6072', N'usd', 0),
           (6073, N'C0000173', 2025, N'INV-6073', N'V-6073', N'Usd', 0);

    EXEC Layercake.usp_load_silv_ref_currency;

    DECLARE @Rows int = (SELECT COUNT(*) FROM Layercake.silv_ref_currency);
    EXEC tSQLt.AssertEquals 1, @Rows;

    DECLARE @UsdRows int = (SELECT COUNT(*) FROM Layercake.silv_ref_currency WHERE currency_code = N'USD' AND id IS NOT NULL);
    EXEC tSQLt.AssertEquals 1, @UsdRows;

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 1, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD005.[test TC-005-025 failed currency load re-raises logs Failed and leaves the currency list unchanged]
AS
BEGIN
    ALTER TABLE Layercake.silv_ref_currency
        ADD CONSTRAINT ck_test_MOD005_025_reject CHECK (currency_code <> N'XXX');

    SET IDENTITY_INSERT Layercake.silv_ref_currency ON;
    INSERT INTO Layercake.silv_ref_currency (id, currency_code, load_id, created_at)
    VALUES (2, N'EUR', 7, '2026-02-01T10:00:00');
    SET IDENTITY_INSERT Layercake.silv_ref_currency OFF;

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_currency, _is_deleted)
    VALUES (6081, N'C0000181', 2025, N'INV-6081', N'V-6081', N'GBP', 0),
           (6082, N'C0000182', 2025, N'INV-6082', N'V-6082', N'XXX', 0),
           (6083, N'C0000183', 2025, N'INV-6083', N'V-6083', N'EUR', 0);

    SELECT * INTO #Before FROM Layercake.silv_ref_currency;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_ref_currency;
        EXEC tSQLt.Fail 'usp_load_silv_ref_currency did not raise the expected error 547.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    EXEC tSQLt.AssertEqualsTable '#Before', 'Layercake.silv_ref_currency';

    DECLARE @LogRows int = (SELECT COUNT(*) FROM Layercake.etl_run_log);
    EXEC tSQLt.AssertEquals 1, @LogRows;

    DECLARE @FailedWithMessage int = (SELECT COUNT(*) FROM Layercake.etl_run_log
                                      WHERE status = 'Failed' AND error_message IS NOT NULL);
    EXEC tSQLt.AssertEquals 1, @FailedWithMessage;
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD005.[test TC-005-026 failed dim_currency load re-raises logs Failed and leaves the dimension unchanged]
AS
BEGIN
    ALTER TABLE Layercake.dim_currency
        ADD CONSTRAINT ck_test_MOD005_026_reject CHECK (currency_code <> N'XXX');

    SET IDENTITY_INSERT Layercake.silv_ref_currency ON;
    INSERT INTO Layercake.silv_ref_currency (id, currency_code, load_id, created_at)
    VALUES (1, N'GBP', 7, '2026-02-01T10:00:00'),
           (2, N'EUR', 7, '2026-02-01T10:00:00'),
           (9, N'XXX', 7, '2026-02-01T10:00:00');
    SET IDENTITY_INSERT Layercake.silv_ref_currency OFF;

    INSERT INTO Layercake.dim_currency (id, currency_code, load_id, created_at, updated_at)
    VALUES (1, N'GBP', 7, '2026-02-01T10:00:00', '2026-02-01T10:00:00');

    SELECT * INTO #Before FROM Layercake.dim_currency;

    BEGIN TRY
        EXEC Layercake.usp_load_dim_currency;
        EXEC tSQLt.Fail 'usp_load_dim_currency did not raise the expected error 547.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    EXEC tSQLt.AssertEqualsTable '#Before', 'Layercake.dim_currency';

    DECLARE @LogRows int = (SELECT COUNT(*) FROM Layercake.etl_run_log);
    EXEC tSQLt.AssertEquals 1, @LogRows;

    DECLARE @FailedWithMessage int = (SELECT COUNT(*) FROM Layercake.etl_run_log
                                      WHERE status = 'Failed' AND error_message IS NOT NULL);
    EXEC tSQLt.AssertEquals 1, @FailedWithMessage;
END;
GO
