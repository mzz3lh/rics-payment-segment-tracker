EXEC tSQLt.NewTestClass 'test_MOD003_dev';
GO

CREATE PROCEDURE test_MOD003_dev.[test fn_map_payment_method reads the list and never matches a reserved row]
AS
BEGIN
    -- A method added to the list later maps without a code change; a reserved row is never a match,
    -- even if it were given a source_code.
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (0, 'Unknown', 'UNK', '2026-01-01', '2026-01-01'),
           (1, 'Direct Debit', 'DD', '2026-01-01', '2026-01-01'),
           (6, 'Wallet', 'Wallet', '2026-01-01', '2026-01-01');

    CREATE TABLE #Input (case_no int NOT NULL, code nvarchar(20) NULL);
    INSERT INTO #Input (case_no, code)
    VALUES (1, N'DD'), (2, N'wallet'), (3, N'UNK'), (4, N'Card');

    SELECT i.case_no, Layercake.fn_map_payment_method(i.code) AS mapped_id
    INTO #Actual
    FROM #Input AS i;

    SELECT v.case_no, v.mapped_id
    INTO #Expected
    FROM (VALUES (1, 1), (2, 6), (3, -1), (4, -1)) AS v(case_no, mapped_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD003_dev.[test fn_map_payment_method trims only surrounding spaces]
AS
BEGIN
    -- Only spaces are trimmed (answers 2026-10-26): an inner space, a tab or a line break
    -- leaves the code different, so it is Unrecognised; a full-width 20-character code is handled.
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (1, 'Direct Debit', 'DD', '2026-01-01', '2026-01-01'),
           (3, 'Bank transfer', 'Bank', '2026-01-01', '2026-01-01');

    CREATE TABLE #Input (case_no int NOT NULL, code nvarchar(20) NULL);
    INSERT INTO #Input (case_no, code)
    VALUES (1, N'D D'),
           (2, N'DD' + NCHAR(9)),
           (3, NCHAR(13) + NCHAR(10) + N'DD'),
           (4, N'                Bank'),
           (5, N'Bank                ');

    SELECT i.case_no, Layercake.fn_map_payment_method(i.code) AS mapped_id
    INTO #Actual
    FROM #Input AS i;

    SELECT v.case_no, v.mapped_id
    INTO #Expected
    FROM (VALUES (1, -1), (2, -1), (3, -1), (4, 3), (5, 3)) AS v(case_no, mapped_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD003_dev.[test usp_load_dim_payment_method stamps inserted and updated rows with the load and keeps created_at]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (0, 'Unknown', NULL, '2026-01-01', '2026-01-01'),
           (2, 'Card', 'Card', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.dim_payment_method (id, payment_method_name, load_id, created_at, updated_at)
    VALUES (2, 'Credit card', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00');

    EXEC Layercake.usp_load_dim_payment_method;

    DECLARE @log_id bigint = (SELECT l.log_id FROM Layercake.etl_run_log AS l);

    SELECT d.id,
           d.payment_method_name,
           CASE WHEN d.load_id = @log_id THEN 1 ELSE 0 END AS stamped_with_load,
           CASE WHEN d.created_at = '2026-02-01 10:00:00' THEN 1 ELSE 0 END AS created_at_kept,
           CASE WHEN d.updated_at > '2026-02-01 10:00:00' THEN 1 ELSE 0 END AS updated_at_moved,
           CASE WHEN d.created_at = d.updated_at THEN 1 ELSE 0 END AS created_equals_updated
    INTO #Actual
    FROM Layercake.dim_payment_method AS d;

    SELECT v.id, v.payment_method_name, v.stamped_with_load, v.created_at_kept, v.updated_at_moved, v.created_equals_updated
    INTO #Expected
    FROM (VALUES (0, CAST('Unknown' AS varchar(30)), 1, 0, 1, 1),
                 (2, CAST('Card' AS varchar(30)), 1, 1, 1, 0)) AS v(id, payment_method_name, stamped_with_load, created_at_kept, updated_at_moved, created_equals_updated);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.layer, l.step_name, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted,
           CASE WHEN l.finished_at IS NULL THEN 0 ELSE 1 END AS finished
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.layer, v.step_name, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted, v.finished
    INTO #ExpectedLog
    FROM (VALUES (CAST('gold' AS varchar(12)), CAST('dim_payment_method' AS varchar(128)), CAST('Success' AS varchar(10)), 1, 1, 0, 1)) AS v(layer, step_name, status, rows_inserted, rows_updated, rows_deleted, finished);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD003_dev.[test usp_load_dim_payment_method corrects a trailing-space change and keeps a row gone from silver]
AS
BEGIN
    -- '=' ignores trailing spaces, so the byte comparison is what catches 'Card ' -> 'Card'.
    -- The dimension is never deleted from: facts may still point at an id that left the list.
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (2, 'Card', 'Card', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.dim_payment_method (id, payment_method_name, load_id, created_at, updated_at)
    VALUES (2, 'Card ', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00'),
           (8, 'Retired method', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00');

    EXEC Layercake.usp_load_dim_payment_method;

    SELECT d.id, CAST(d.payment_method_name AS varbinary(30)) AS name_bytes, d.load_id, d.updated_at
    INTO #Actual
    FROM Layercake.dim_payment_method AS d
    WHERE d.id = 8
       OR CAST(d.payment_method_name AS varbinary(30)) = CAST('Card' AS varbinary(30));

    SELECT v.id, CAST(v.name AS varbinary(30)) AS name_bytes, v.load_id, CAST(v.updated_at AS datetime2(3)) AS updated_at
    INTO #ExpectedRetired
    FROM (VALUES (8, CAST('Retired method' AS varchar(30)), 7, '2026-02-01 10:00:00')) AS v(id, name, load_id, updated_at);

    SELECT a.id, a.name_bytes, a.load_id, a.updated_at
    INTO #ActualRetired
    FROM #Actual AS a
    WHERE a.id = 8;

    EXEC tSQLt.AssertEqualsTable '#ExpectedRetired', '#ActualRetired';

    DECLARE @card_rows int = (SELECT COUNT(*) FROM #Actual AS a WHERE a.id = 2);
    EXEC tSQLt.AssertEquals 1, @card_rows;

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
CREATE PROCEDURE test_MOD003_dev.[test usp_load_dim_payment_method failure rolls back a name update made earlier in the same run]
AS
BEGIN
    -- The update runs before the insert; when the insert fails, the corrected name must be rolled back too.
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    ALTER TABLE Layercake.dim_payment_method ALTER COLUMN payment_method_name varchar(30) NOT NULL;

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (2, 'Card', 'Card', '2026-01-01', '2026-01-01'),
           (9, NULL, 'ZZ', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.dim_payment_method (id, payment_method_name, load_id, created_at, updated_at)
    VALUES (2, 'Credit card', 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00');

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

    SELECT d.id, d.payment_method_name, d.load_id, d.created_at, d.updated_at
    INTO #Actual
    FROM Layercake.dim_payment_method AS d;

    SELECT v.id, v.payment_method_name, v.load_id, CAST(v.created_at AS datetime2(3)) AS created_at, CAST(v.updated_at AS datetime2(3)) AS updated_at
    INTO #Expected
    FROM (VALUES (2, CAST('Credit card' AS varchar(30)), 7, '2026-02-01 10:00:00', '2026-02-01 10:00:00')) AS v(id, payment_method_name, load_id, created_at, updated_at);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.status,
           CASE WHEN l.error_message LIKE '%(error 515,%' THEN 1 ELSE 0 END AS error_515_recorded,
           CASE WHEN l.finished_at IS NULL THEN 0 ELSE 1 END AS finished
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.error_515_recorded, v.finished
    INTO #ExpectedLog
    FROM (VALUES (CAST('Failed' AS varchar(10)), 1, 1)) AS v(status, error_515_recorded, finished);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
