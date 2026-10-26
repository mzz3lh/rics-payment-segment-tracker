EXEC tSQLt.NewTestClass 'test_MOD003';
GO

CREATE PROCEDURE test_MOD003.[test TC-003-001 seeded payment method list holds the three reserved rows and the five methods]
AS
BEGIN
    -- The list is static, seeded by the module's migration: the deployed table is the object under test.
    SELECT CASE WHEN r.id > 0 THEN 'method' ELSE CAST(r.id AS varchar(6)) END AS id_class,
           CAST(r.payment_method_name AS varbinary(30)) AS name_bytes
    INTO #Actual
    FROM Layercake.silv_ref_payment_method AS r;

    SELECT v.id_class, CAST(v.name AS varbinary(30)) AS name_bytes
    INTO #Expected
    FROM (VALUES ('0', CAST('Unknown' AS varchar(30))),
                 ('-1', CAST('Unrecognised' AS varchar(30))),
                 ('-2', CAST('Not applicable' AS varchar(30))),
                 ('method', CAST('Direct Debit' AS varchar(30))),
                 ('method', CAST('Card' AS varchar(30))),
                 ('method', CAST('Bank transfer' AS varchar(30))),
                 ('method', CAST('Cheque' AS varchar(30))),
                 ('method', CAST('Corporate' AS varchar(30)))) AS v(id_class, name);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT r.id
    INTO #ActualMethodIds
    FROM Layercake.silv_ref_payment_method AS r
    WHERE r.id > 0;

    SELECT v.id
    INTO #ExpectedMethodIds
    FROM (VALUES (1), (2), (3), (4), (5)) AS v(id);

    EXEC tSQLt.AssertEqualsTable '#ExpectedMethodIds', '#ActualMethodIds';
END;
GO

CREATE PROCEDURE test_MOD003.[test TC-003-002 seeded payment method list has no Mixed value]
AS
BEGIN
    SELECT r.id, r.payment_method_name
    INTO #Actual
    FROM Layercake.silv_ref_payment_method AS r
    WHERE r.payment_method_name LIKE '%Mixed%';

    EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO

CREATE PROCEDURE test_MOD003.[test TC-003-003 the five codes map to their methods and null or empty string to Unknown]
AS
BEGIN
    CREATE TABLE #Input (case_no int NOT NULL, code nvarchar(20) NULL);
    INSERT INTO #Input (case_no, code)
    VALUES (1, N'DD'), (2, N'Card'), (3, N'Bank'), (4, N'Cheque'), (5, N'Corporate'), (6, NULL), (7, N'');

    SELECT i.case_no,
           CASE WHEN m.mapped_id > 0 THEN 'method' ELSE CAST(m.mapped_id AS varchar(6)) END AS id_class,
           r.payment_method_name
    INTO #Actual
    FROM #Input AS i
    CROSS APPLY (SELECT Layercake.fn_map_payment_method(i.code) AS mapped_id) AS m
    LEFT JOIN Layercake.silv_ref_payment_method AS r
        ON r.id = m.mapped_id;

    SELECT v.case_no, v.id_class, v.payment_method_name
    INTO #Expected
    FROM (VALUES (1, 'method', CAST('Direct Debit' AS varchar(30))),
                 (2, 'method', CAST('Card' AS varchar(30))),
                 (3, 'method', CAST('Bank transfer' AS varchar(30))),
                 (4, 'method', CAST('Cheque' AS varchar(30))),
                 (5, 'method', CAST('Corporate' AS varchar(30))),
                 (6, '0', CAST('Unknown' AS varchar(30))),
                 (7, '0', CAST('Unknown' AS varchar(30)))) AS v(case_no, id_class, payment_method_name);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD003.[test TC-003-004 each method row carries its source payment mode code]
AS
BEGIN
    SELECT r.payment_method_name, r.source_code
    INTO #Actual
    FROM Layercake.silv_ref_payment_method AS r
    WHERE r.id > 0;

    SELECT v.payment_method_name, v.source_code
    INTO #Expected
    FROM (VALUES (CAST('Direct Debit' AS varchar(30)), CAST('DD' AS varchar(20))),
                 (CAST('Card' AS varchar(30)), CAST('Card' AS varchar(20))),
                 (CAST('Bank transfer' AS varchar(30)), CAST('Bank' AS varchar(20))),
                 (CAST('Cheque' AS varchar(30)), CAST('Cheque' AS varchar(20))),
                 (CAST('Corporate' AS varchar(30)), CAST('Corporate' AS varchar(20)))) AS v(payment_method_name, source_code);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD003.[test TC-003-005 code XYZ maps to Unrecognised not Unknown]
AS
BEGIN
    DECLARE @actual int = Layercake.fn_map_payment_method(N'XYZ');

    EXEC tSQLt.AssertEquals -1, @actual;
END;
GO

CREATE PROCEDURE test_MOD003.[test TC-003-006 names partial codes and Mixed map to Unrecognised]
AS
BEGIN
    CREATE TABLE #Input (case_no int NOT NULL, code nvarchar(20) NULL);
    INSERT INTO #Input (case_no, code)
    VALUES (1, N'Direct Debit'), (2, N'Bank transfer'), (3, N'D'), (4, N'DDX'), (5, N'Mixed'), (6, N'Unknown');

    SELECT i.case_no, Layercake.fn_map_payment_method(i.code) AS mapped_id
    INTO #Actual
    FROM #Input AS i;

    SELECT v.case_no, v.mapped_id
    INTO #Expected
    FROM (VALUES (1, -1), (2, -1), (3, -1), (4, -1), (5, -1), (6, -1)) AS v(case_no, mapped_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD003.[test TC-003-007 first dimension load copies all eight ids and names and logs Success]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (0, 'Unknown', NULL, '2026-01-01', '2026-01-01'),
           (-1, 'Unrecognised', NULL, '2026-01-01', '2026-01-01'),
           (-2, 'Not applicable', NULL, '2026-01-01', '2026-01-01'),
           (1, 'Direct Debit', 'DD', '2026-01-01', '2026-01-01'),
           (2, 'Card', 'Card', '2026-01-01', '2026-01-01'),
           (3, 'Bank transfer', 'Bank', '2026-01-01', '2026-01-01'),
           (4, 'Cheque', 'Cheque', '2026-01-01', '2026-01-01'),
           (5, 'Corporate', 'Corporate', '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_dim_payment_method;

    SELECT d.id, CAST(d.payment_method_name AS varbinary(30)) AS name_bytes
    INTO #Actual
    FROM Layercake.dim_payment_method AS d;

    SELECT v.id, CAST(v.name AS varbinary(30)) AS name_bytes
    INTO #Expected
    FROM (VALUES (0, CAST('Unknown' AS varchar(30))),
                 (-1, CAST('Unrecognised' AS varchar(30))),
                 (-2, CAST('Not applicable' AS varchar(30))),
                 (1, CAST('Direct Debit' AS varchar(30))),
                 (2, CAST('Card' AS varchar(30))),
                 (3, CAST('Bank transfer' AS varchar(30))),
                 (4, CAST('Cheque' AS varchar(30))),
                 (5, CAST('Corporate' AS varchar(30)))) AS v(id, name);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 8, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD003.[test TC-003-008 second dimension load keeps every id and changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (0, 'Unknown', NULL, '2026-01-01', '2026-01-01'),
           (-1, 'Unrecognised', NULL, '2026-01-01', '2026-01-01'),
           (-2, 'Not applicable', NULL, '2026-01-01', '2026-01-01'),
           (1, 'Direct Debit', 'DD', '2026-01-01', '2026-01-01'),
           (2, 'Card', 'Card', '2026-01-01', '2026-01-01'),
           (3, 'Bank transfer', 'Bank', '2026-01-01', '2026-01-01'),
           (4, 'Cheque', 'Cheque', '2026-01-01', '2026-01-01'),
           (5, 'Corporate', 'Corporate', '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_dim_payment_method;

    SELECT *
    INTO #AfterFirst
    FROM Layercake.dim_payment_method;

    EXEC Layercake.usp_load_dim_payment_method;

    SELECT *
    INTO #AfterSecond
    FROM Layercake.dim_payment_method;

    EXEC tSQLt.AssertEqualsTable '#AfterFirst', '#AfterSecond';

    SELECT d.payment_method_name, d.id
    INTO #ActualIds
    FROM Layercake.dim_payment_method AS d;

    SELECT v.payment_method_name, v.id
    INTO #ExpectedIds
    FROM (VALUES (CAST('Unknown' AS varchar(30)), 0),
                 (CAST('Unrecognised' AS varchar(30)), -1),
                 (CAST('Not applicable' AS varchar(30)), -2),
                 (CAST('Direct Debit' AS varchar(30)), 1),
                 (CAST('Card' AS varchar(30)), 2),
                 (CAST('Bank transfer' AS varchar(30)), 3),
                 (CAST('Cheque' AS varchar(30)), 4),
                 (CAST('Corporate' AS varchar(30)), 5)) AS v(payment_method_name, id);

    EXEC tSQLt.AssertEqualsTable '#ExpectedIds', '#ActualIds';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 8, 0, 0),
                 (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD003.[test TC-003-009 dimension load inserts missing ids updates a changed name and leaves unchanged rows untouched]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (0, 'Unknown', NULL, '2026-01-01', '2026-01-01'),
           (-1, 'Unrecognised', NULL, '2026-01-01', '2026-01-01'),
           (-2, 'Not applicable', NULL, '2026-01-01', '2026-01-01'),
           (1, 'Direct Debit', 'DD', '2026-01-01', '2026-01-01'),
           (2, 'Card', 'Card', '2026-01-01', '2026-01-01'),
           (3, 'Bank transfer', 'Bank', '2026-01-01', '2026-01-01'),
           (4, 'Cheque', 'Cheque', '2026-01-01', '2026-01-01'),
           (5, 'Corporate', 'Corporate', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.dim_payment_method (id, payment_method_name, load_id, created_at, updated_at)
    VALUES (0, 'Unknown', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
           (-1, 'Unrecognised', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
           (-2, 'Not applicable', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
           (1, 'Direct Debit', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
           (2, 'Credit card', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00');

    EXEC Layercake.usp_load_dim_payment_method;

    SELECT d.id, d.payment_method_name
    INTO #Actual
    FROM Layercake.dim_payment_method AS d;

    SELECT v.id, v.payment_method_name
    INTO #Expected
    FROM (VALUES (0, CAST('Unknown' AS varchar(30))),
                 (-1, CAST('Unrecognised' AS varchar(30))),
                 (-2, CAST('Not applicable' AS varchar(30))),
                 (1, CAST('Direct Debit' AS varchar(30))),
                 (2, CAST('Card' AS varchar(30))),
                 (3, CAST('Bank transfer' AS varchar(30))),
                 (4, CAST('Cheque' AS varchar(30))),
                 (5, CAST('Corporate' AS varchar(30)))) AS v(id, payment_method_name);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT d.id, d.payment_method_name, d.load_id, d.created_at, d.updated_at
    INTO #ActualUntouched
    FROM Layercake.dim_payment_method AS d
    WHERE d.id IN (0, -1, -2, 1);

    SELECT v.id, v.payment_method_name, v.load_id, CAST(v.created_at AS datetime2(3)) AS created_at, CAST(v.updated_at AS datetime2(3)) AS updated_at
    INTO #ExpectedUntouched
    FROM (VALUES (0, CAST('Unknown' AS varchar(30)), 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
                 (-1, CAST('Unrecognised' AS varchar(30)), 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
                 (-2, CAST('Not applicable' AS varchar(30)), 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
                 (1, CAST('Direct Debit' AS varchar(30)), 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00')) AS v(id, payment_method_name, load_id, created_at, updated_at);

    EXEC tSQLt.AssertEqualsTable '#ExpectedUntouched', '#ActualUntouched';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 3, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD003.[test TC-003-010 dimension load corrects a name that differs only in case]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (0, 'Unknown', NULL, '2026-01-01', '2026-01-01'),
           (2, 'Card', 'Card', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.dim_payment_method (id, payment_method_name, load_id, created_at, updated_at)
    VALUES (0, 'Unknown', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
           (2, 'card', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00');

    EXEC Layercake.usp_load_dim_payment_method;

    SELECT d.id, CAST(d.payment_method_name AS varbinary(30)) AS name_bytes
    INTO #Actual
    FROM Layercake.dim_payment_method AS d;

    SELECT v.id, CAST(v.name AS varbinary(30)) AS name_bytes
    INTO #Expected
    FROM (VALUES (0, CAST('Unknown' AS varchar(30))),
                 (2, CAST('Card' AS varchar(30)))) AS v(id, name);

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
CREATE PROCEDURE test_MOD003.[test TC-003-011 dimension load failing on a row the target rejects re-raises logs Failed and leaves the target unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    -- FakeTable drops NOT NULL; restore the design's NOT NULL on the dimension name so the bad row is rejected.
    ALTER TABLE Layercake.dim_payment_method ALTER COLUMN payment_method_name varchar(30) NOT NULL;

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (0, 'Unknown', NULL, '2026-01-01', '2026-01-01'),
           (1, 'Direct Debit', 'DD', '2026-01-01', '2026-01-01'),
           (9, NULL, 'ZZ', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.dim_payment_method (id, payment_method_name, load_id, created_at, updated_at)
    VALUES (1, 'Direct Debit', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00');

    SELECT *
    INTO #Before
    FROM Layercake.dim_payment_method;

    DECLARE @err int;

    BEGIN TRY
        EXEC Layercake.usp_load_dim_payment_method;
        EXEC tSQLt.Fail 'usp_load_dim_payment_method did not raise an error for a NULL name';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_NUMBER();
        IF @err <> 515
            THROW;
    END CATCH;

    EXEC tSQLt.AssertEquals 515, @err;

    SELECT *
    INTO #After
    FROM Layercake.dim_payment_method;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT l.status, CASE WHEN l.error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.has_error_message
    INTO #ExpectedLog
    FROM (VALUES (CAST('Failed' AS varchar(10)), 1)) AS v(status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD003.[test TC-003-012 dimension loaded from the seeded list has the same ids and names as the list]
AS
BEGIN
    -- Reads the deployed (seeded) silv_ref_payment_method; only the target and the log are faked.
    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    EXEC Layercake.usp_load_dim_payment_method;

    SELECT CASE WHEN d.id > 0 THEN 'method' ELSE CAST(d.id AS varchar(6)) END AS id_class,
           CAST(d.payment_method_name AS varbinary(30)) AS name_bytes
    INTO #Actual
    FROM Layercake.dim_payment_method AS d;

    SELECT v.id_class, CAST(v.name AS varbinary(30)) AS name_bytes
    INTO #Expected
    FROM (VALUES ('0', CAST('Unknown' AS varchar(30))),
                 ('-1', CAST('Unrecognised' AS varchar(30))),
                 ('-2', CAST('Not applicable' AS varchar(30))),
                 ('method', CAST('Direct Debit' AS varchar(30))),
                 ('method', CAST('Card' AS varchar(30))),
                 ('method', CAST('Bank transfer' AS varchar(30))),
                 ('method', CAST('Cheque' AS varchar(30))),
                 ('method', CAST('Corporate' AS varchar(30)))) AS v(id_class, name);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT d.id, CAST(d.payment_method_name AS varbinary(30)) AS name_bytes
    INTO #Unmatched
    FROM Layercake.dim_payment_method AS d
    WHERE NOT EXISTS (SELECT 1
                      FROM Layercake.silv_ref_payment_method AS r
                      WHERE r.id = d.id
                        AND CAST(r.payment_method_name AS varbinary(30)) = CAST(d.payment_method_name AS varbinary(30)));

    EXEC tSQLt.AssertEmptyTable '#Unmatched';
END;
GO

CREATE PROCEDURE test_MOD003.[test TC-003-013 codes differing only in case or surrounding spaces map to their method and whitespace only to Unknown]
AS
BEGIN
    CREATE TABLE #Input (case_no int NOT NULL, code nvarchar(20) NULL);
    INSERT INTO #Input (case_no, code)
    VALUES (1, N'dd'), (2, N' DD'), (3, N'Card '), (4, N'  bank  '), (5, N'CHEQUE'), (6, N' cOrPoRaTe'), (7, N'   '), (8, N' XYZ ');

    SELECT i.case_no,
           CASE WHEN m.mapped_id > 0 THEN 'method' ELSE CAST(m.mapped_id AS varchar(6)) END AS id_class,
           r.payment_method_name
    INTO #Actual
    FROM #Input AS i
    CROSS APPLY (SELECT Layercake.fn_map_payment_method(i.code) AS mapped_id) AS m
    LEFT JOIN Layercake.silv_ref_payment_method AS r
        ON r.id = m.mapped_id;

    SELECT v.case_no, v.id_class, v.payment_method_name
    INTO #Expected
    FROM (VALUES (1, 'method', CAST('Direct Debit' AS varchar(30))),
                 (2, 'method', CAST('Direct Debit' AS varchar(30))),
                 (3, 'method', CAST('Card' AS varchar(30))),
                 (4, 'method', CAST('Bank transfer' AS varchar(30))),
                 (5, 'method', CAST('Cheque' AS varchar(30))),
                 (6, 'method', CAST('Corporate' AS varchar(30))),
                 (7, '0', CAST('Unknown' AS varchar(30))),
                 (8, '-1', CAST('Unrecognised' AS varchar(30)))) AS v(case_no, id_class, payment_method_name);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
