EXEC tSQLt.NewTestClass 'test_MOD009_dev';
GO

CREATE PROCEDURE test_MOD009_dev.[test no deployed module outside the test classes references payment_source]
AS
BEGIN
    -- a view or procedure still naming the dropped column would fail at run time, not at deploy
    DECLARE @referencing int =
        (SELECT COUNT(*)
         FROM sys.sql_modules AS m
         JOIN sys.objects AS o
           ON o.object_id = m.object_id
         WHERE m.definition LIKE N'%payment[_]source%'
           AND SCHEMA_NAME(o.schema_id) NOT LIKE N'test[_]%'
           AND SCHEMA_NAME(o.schema_id) <> N'tSQLt');

    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @referencing, @Message = N'no module may reference payment_source';
END;
GO

CREATE PROCEDURE test_MOD009_dev.[test payment events load still takes payment_date from settled approved cash transactions]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status';
    EXEC tSQLt.FakeTable 'Layercake.brnz_cust_trans';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_pending_rebuild', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_loaded';

    INSERT INTO Layercake.brnz_subs_status
        ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted)
    VALUES
        (N'9400001', 2025, 'Fully Paid', NULL, '2024-11-01', 0),
        (N'9400002', 2025, 'Fully Paid', NULL, '2024-11-03', 0);

    -- 9400001: invoice due Nov 2024 (Campaign Year 2025) settled in full; 9400002: same but not approved
    INSERT INTO Layercake.brnz_cust_trans
        (recid, accountnum, duedate, transdate, paymreference, amountcur, approved, _is_deleted)
    VALUES
        (1, N'9400001', '2024-11-15', '2024-11-01', N'REF-1',  100.00, 1, 0),
        (2, N'9400001', NULL,         '2024-11-20', N'REF-1', -100.00, 1, 0),
        (3, N'9400002', '2024-11-15', '2024-11-02', N'REF-2',  100.00, 0, 0),
        (4, N'9400002', NULL,         '2024-11-21', N'REF-2', -100.00, 0, 0);

    EXEC Layercake.usp_load_silv_payment_events;

    SELECT p.contact_no, p.campaign_year, p.payment_date, p.renewal_date_adj, p.invoice_position
    INTO #Actual
    FROM Layercake.silv_payment_events AS p;

    SELECT CAST(v.contact_no AS nvarchar(200)) AS contact_no,
           CAST(v.campaign_year AS int) AS campaign_year,
           CAST(v.payment_date AS date) AS payment_date,
           CAST(v.renewal_date_adj AS date) AS renewal_date_adj,
           CAST(v.invoice_position AS nvarchar(64)) AS invoice_position
    INTO #Expected
    FROM (VALUES
            (N'9400001', 2025, '2024-11-01', '2024-11-01', N'Fully Paid'),
            (N'9400002', 2025, NULL,         '2024-11-03', N'Fully Paid')
         ) AS v(contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO
