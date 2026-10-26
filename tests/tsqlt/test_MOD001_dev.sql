EXEC tSQLt.NewTestClass 'test_MOD001_dev';
GO

CREATE PROCEDURE test_MOD001_dev.[test grain profile leaves out rows with no TRANSTYPE or no INVOICE]
AS
BEGIN
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';

    INSERT INTO synapse_fo.CUSTTRANS_RICS (ACCOUNTNUM, INVOICE, TRANSTYPE, productcode, PostingType_Description)
    VALUES (N'C0000001', N'INV-A', 2, N'SUBS_MRICS', 'Customer balance'),
           (N'C0000001', N'INV-A', NULL, N'RAFEE_MRICS', 'Customer balance'),
           (N'C0000002', NULL, 2, N'SUBS_MRICS', 'Customer balance');

    CREATE TABLE #Actual (measure varchar(50), measure_value varchar(50), invoice_count int);
    INSERT INTO #Actual (measure, measure_value, invoice_count)
    EXEC Layercake.usp_profile_custtrans_grain;

    CREATE TABLE #Expected (measure varchar(50), measure_value varchar(50), invoice_count int);
    INSERT INTO #Expected (measure, measure_value, invoice_count)
    VALUES ('rows_per_invoice', '1', 1),
           ('distinct_productcodes', '1', 1),
           ('has_sales_tax_row', '0', 1);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD001_dev.[test grain profile counts a missing productcode as no distinct productcode]
AS
BEGIN
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';

    INSERT INTO synapse_fo.CUSTTRANS_RICS (ACCOUNTNUM, INVOICE, TRANSTYPE, productcode, PostingType_Description)
    VALUES (N'C0000001', N'INV-A', 2, NULL, 'Customer balance'),
           (N'C0000001', N'INV-A', 2, NULL, 'Sales tax');

    CREATE TABLE #Actual (measure varchar(50), measure_value varchar(50), invoice_count int);
    INSERT INTO #Actual (measure, measure_value, invoice_count)
    EXEC Layercake.usp_profile_custtrans_grain;

    CREATE TABLE #Expected (measure varchar(50), measure_value varchar(50), invoice_count int);
    INSERT INTO #Expected (measure, measure_value, invoice_count)
    VALUES ('rows_per_invoice', '2', 1),
           ('distinct_productcodes', '0', 1),
           ('has_sales_tax_row', '1', 1);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD001_dev.[test grain profile returns no rows when there are no invoice rows]
AS
BEGIN
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';

    INSERT INTO synapse_fo.CUSTTRANS_RICS (ACCOUNTNUM, INVOICE, TRANSTYPE, productcode, PostingType_Description)
    VALUES (N'C0000001', N'CRE-0001', 2, N'SUBS_MRICS', 'Customer balance');

    CREATE TABLE #Actual (measure varchar(50), measure_value varchar(50), invoice_count int);
    INSERT INTO #Actual (measure, measure_value, invoice_count)
    EXEC Layercake.usp_profile_custtrans_grain;

    EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO

CREATE PROCEDURE test_MOD001_dev.[test corporate status profile lists a missing status as its own NULL value]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Sub Campaign Year], [Sub Status], [Sub User Status])
    VALUES (N'1000001', N'SCH-001', 2025, N'Active', NULL),
           (N'1000002', N'SCH-001', 2025, NULL, N'Active');

    CREATE TABLE #Actual (status_column varchar(50), status_value nvarchar(100), row_count int);
    INSERT INTO #Actual (status_column, status_value, row_count)
    EXEC Layercake.usp_profile_corp_subscription_status;

    CREATE TABLE #Expected (status_column varchar(50), status_value nvarchar(100), row_count int);
    INSERT INTO #Expected (status_column, status_value, row_count)
    VALUES ('Sub Status', NULL, 1),
           ('Sub Status', N'Active', 1),
           ('Sub User Status', NULL, 1),
           ('Sub User Status', N'Active', 1);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
