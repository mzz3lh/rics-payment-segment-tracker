EXEC tSQLt.NewTestClass 'test_MOD001';
GO

CREATE PROCEDURE test_MOD001.[test TC-001-001 grain profile counts invoices by rows, distinct productcodes and Sales tax row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';

    INSERT INTO synapse_fo.CUSTTRANS_RICS (ACCOUNTNUM, INVOICE, TRANSTYPE, productcode, PostingType_Description)
    VALUES (N'C0000001', N'INV-A', 2, N'SUBS_MRICS', 'Customer balance'),
           (N'C0000001', N'INV-A', 2, N'RAFEE_MRICS', 'Customer balance'),
           (N'C0000001', N'INV-A', 2, N'SUBS_MRICS', 'Sales tax'),
           (N'C0000002', N'INV-B', 2, N'SUBS_MRICS', 'Customer balance');

    CREATE TABLE #Actual (measure varchar(50), measure_value varchar(50), invoice_count int);
    INSERT INTO #Actual (measure, measure_value, invoice_count)
    EXEC Layercake.usp_profile_custtrans_grain;

    CREATE TABLE #Expected (measure varchar(50), measure_value varchar(50), invoice_count int);
    INSERT INTO #Expected (measure, measure_value, invoice_count)
    VALUES ('rows_per_invoice', '1', 1),
           ('rows_per_invoice', '3', 1),
           ('distinct_productcodes', '1', 1),
           ('distinct_productcodes', '2', 1),
           ('has_sales_tax_row', '0', 1),
           ('has_sales_tax_row', '1', 1);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD001.[test TC-001-002 grain profile excludes TRANSTYPE 8 and 24 and CRE and FTCN invoice rows]
AS
BEGIN
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';

    INSERT INTO synapse_fo.CUSTTRANS_RICS (ACCOUNTNUM, INVOICE, TRANSTYPE, productcode, PostingType_Description)
    VALUES (N'C0000002', N'INV-B', 2, N'SUBS_MRICS', 'Customer balance'),
           (N'C0000002', N'INV-B', 8, N'SUBS_MRICS', 'Sales tax'),
           (N'C0000002', N'INV-B', 24, N'RAFEE_MRICS', 'Customer balance'),
           (N'C0000003', N'CRE-0001', 2, N'SUBS_MRICS', 'Customer balance'),
           (N'C0000003', N'CRE-0001', 2, N'RAFEE_MRICS', 'Sales tax'),
           (N'C0000004', N'FTCN-0001', 2, N'SUBS_MRICS', 'Customer balance'),
           (N'C0000005', N'INV-P', 8, N'SUBS_MRICS', 'Customer balance'),
           (N'C0000006', N'INV-Q', 24, N'SUBS_MRICS', 'Customer balance');

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

CREATE PROCEDURE test_MOD001.[test TC-001-003 grain profile counts one invoice number on two accounts as two invoices]
AS
BEGIN
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';

    INSERT INTO synapse_fo.CUSTTRANS_RICS (ACCOUNTNUM, INVOICE, TRANSTYPE, productcode, PostingType_Description)
    VALUES (N'C0000007', N'INV-X', 2, N'SUBS_MRICS', 'Customer balance'),
           (N'C0000008', N'INV-X', 2, N'RAFEE_MRICS', 'Customer balance');

    CREATE TABLE #Actual (measure varchar(50), measure_value varchar(50), invoice_count int);
    INSERT INTO #Actual (measure, measure_value, invoice_count)
    EXEC Layercake.usp_profile_custtrans_grain;

    CREATE TABLE #Expected (measure varchar(50), measure_value varchar(50), invoice_count int);
    INSERT INTO #Expected (measure, measure_value, invoice_count)
    VALUES ('rows_per_invoice', '1', 2),
           ('distinct_productcodes', '1', 2),
           ('has_sales_tax_row', '0', 2);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD001.[test TC-001-004 corporate status profile counts rows by Sub Status and by Sub User Status]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Sub Campaign Year], [Sub Status], [Sub User Status])
    VALUES (N'1000001', N'SCH-001', 2025, N'Active', N'Active'),
           (N'1000002', N'SCH-001', 2025, N'Active', N'Active'),
           (N'1000003', N'SCH-002', 2025, N'Active', N'Inactive'),
           (N'1000004', N'SCH-002', 2025, N'Inactive', N'Inactive');

    CREATE TABLE #Actual (status_column varchar(50), status_value nvarchar(100), row_count int);
    INSERT INTO #Actual (status_column, status_value, row_count)
    EXEC Layercake.usp_profile_corp_subscription_status;

    CREATE TABLE #Expected (status_column varchar(50), status_value nvarchar(100), row_count int);
    INSERT INTO #Expected (status_column, status_value, row_count)
    VALUES ('Sub Status', N'Active', 3),
           ('Sub Status', N'Inactive', 1),
           ('Sub User Status', N'Active', 2),
           ('Sub User Status', N'Inactive', 2);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD001.[test TC-001-005 corporate status profile counts rows not contacts]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';

    INSERT INTO Subs.vwCorpSubscriptions ([Contact No], [Scheme No], [Sub Campaign Year], [Sub Status], [Sub User Status])
    VALUES (N'1000001', N'SCH-001', 2024, N'Active', N'Active'),
           (N'1000001', N'SCH-001', 2025, N'Active', N'Active'),
           (N'1000001', N'SCH-002', 2025, N'Cancelled', N'Active');

    CREATE TABLE #Actual (status_column varchar(50), status_value nvarchar(100), row_count int);
    INSERT INTO #Actual (status_column, status_value, row_count)
    EXEC Layercake.usp_profile_corp_subscription_status;

    CREATE TABLE #Expected (status_column varchar(50), status_value nvarchar(100), row_count int);
    INSERT INTO #Expected (status_column, status_value, row_count)
    VALUES ('Sub Status', N'Active', 2),
           ('Sub Status', N'Cancelled', 1),
           ('Sub User Status', N'Active', 3);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
