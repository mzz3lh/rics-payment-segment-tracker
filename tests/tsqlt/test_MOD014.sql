EXEC tSQLt.NewTestClass 'test_MOD014';
GO

CREATE PROCEDURE test_MOD014.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type';
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type';
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription';
    EXEC tSQLt.FakeTable 'CE.vwCorporateSchemes';
    EXEC tSQLt.FakeTable 'CE.vwContact';
    EXEC tSQLt.FakeTable 'CE.vwAccount';

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name)
    VALUES (0, 'Unknown'), (-1, 'Unrecognised'), (-2, 'Not applicable'), (1, 'Individual'), (2, 'Corporate');

    INSERT INTO Layercake.dim_payer_type (id, payer_type_name, load_id)
    VALUES (0, 'Unknown', 1), (-1, 'Unrecognised', 1), (-2, 'Not applicable', 1), (1, 'Individual', 1), (2, 'Corporate', 1);

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES
        (2023, '2022-10-01', '2023-09-30', '2023-09-30'),
        (2024, '2023-10-01', '2024-09-30', '2024-09-30'),
        (2025, '2024-10-01', '2025-09-30', '2025-09-30'),
        (2026, '2025-10-01', '2026-09-30', '2026-09-30'),
        (2027, '2026-10-01', '2027-09-30', '2027-09-30');
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-001 no employer object or employer column exists]
AS
BEGIN
    DECLARE @employer_objects int;
    DECLARE @employer_columns int;
    DECLARE @named_tables int;

    SELECT @employer_objects = COUNT(*)
    FROM sys.objects AS o
    INNER JOIN sys.schemas AS s
        ON s.schema_id = o.schema_id
    WHERE s.name = N'Layercake'
        AND o.name IN (N'brnz_account', N'brnz_corporate_scheme', N'ref_employer_group', N'dim_employer');

    SELECT @employer_columns = COUNT(*)
    FROM sys.columns AS c
    INNER JOIN sys.objects AS o
        ON o.object_id = c.object_id
    INNER JOIN sys.schemas AS s
        ON s.schema_id = o.schema_id
    WHERE s.name = N'Layercake'
        AND o.type IN ('U', 'V')
        AND c.name IN (N'employer_id', N'employer_carried');

    SELECT @named_tables = COUNT(*)
    FROM sys.objects AS o
    WHERE o.object_id IN (
        OBJECT_ID(N'Layercake.silv_member_year_attributes'),
        OBJECT_ID(N'Layercake.silv_membership_events'),
        OBJECT_ID(N'Layercake.fact_membership_events')
    );

    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @employer_objects, @Message = N'An employer object exists';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @employer_columns, @Message = N'A Layercake table or view has employer_id or employer_carried';
    EXEC tSQLt.AssertEquals @Expected = 3, @Actual = @named_tables, @Message = N'The three event and attribute tables should exist';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-002 ten 2025 paid members give scheme link coverage 80.0 Corporate and 0.0 Individual]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'7002001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7002002', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7002003', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7002004', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7002005', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7002011', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7002012', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7002013', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7002014', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7002015', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'7002001', 2025, 5, 0, 2, 0, N'CS0001', 1, 0),
        (N'7002002', 2025, 5, 0, 2, 0, N'CS0002', 1, 0),
        (N'7002003', 2025, 5, 0, 2, 0, N'CS0003', 1, 0),
        (N'7002004', 2025, 5, 0, 2, 0, N'CS0004', 1, 0),
        (N'7002005', 2025, 5, 0, 2, 0, N'CS0005', 1, 0),
        (N'7002011', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7002012', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7002013', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7002014', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7002015', 2025, 2, 0, 1, 0, NULL, 1, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'7002001', N'CS0001', N'Scheme 1', 2025, N'Active', N'Active', 0),
        (N'7002002', N'CS0002', N'Scheme 2', 2025, N'Active', N'Active', 0),
        (N'7002003', N'CS0003', N'Scheme 3', 2025, N'Active', N'Active', 0),
        (N'7002004', N'CS0004', N'Scheme 4', 2025, N'Active', N'Active', 0),
        (N'7002005', N'CS0005', N'Scheme 5', 2025, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, CorporateSchemeName, apuk_corporate, apuk_onbehalfoforganisationid, AccountNumber, AccountName, Rics_contactno, statecode)
    VALUES
        (N'CS0001', N'Scheme 1', 1, '10000000-0000-0000-0000-000000001001', N'A1001', N'Firm One', N'7002001', 0),
        (N'CS0002', N'Scheme 2', 1, '10000000-0000-0000-0000-000000001002', N'A1002', N'Firm Two', N'7002002', 0),
        (N'CS0003', N'Scheme 3', 1, '10000000-0000-0000-0000-000000001003', N'A1003', N'Firm Three', N'7002003', 0),
        (N'CS0004', N'Scheme 4', 1, '10000000-0000-0000-0000-000000001004', N'A1004', N'Firm Four', N'7002004', 0),
        (N'CS0005', N'Scheme 5', 1, NULL, NULL, NULL, N'7002005', 0);

    CREATE TABLE #Actual
    (
        campaign_year int,
        payer_type_name varchar(30) COLLATE DATABASE_DEFAULT,
        paid_members int,
        scheme_link_employer int,
        contact_record_employer int,
        no_employer int,
        scheme_link_coverage_pct decimal(5,1),
        contact_record_coverage_pct decimal(5,1)
    );

    INSERT INTO #Actual (campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct)
    EXEC Layercake.usp_report_employer_scheme_coverage @as_of_date = '2026-03-01';

    DELETE FROM #Actual WHERE paid_members = 0;

    SELECT v.campaign_year, v.payer_type_name, v.paid_members, v.scheme_link_employer, v.contact_record_employer, v.no_employer,
        CAST(v.scheme_link_coverage_pct AS decimal(5,1)) AS scheme_link_coverage_pct,
        CAST(v.contact_record_coverage_pct AS decimal(5,1)) AS contact_record_coverage_pct
    INTO #Expected
    FROM (VALUES
        (2025, 'Corporate', 5, 4, 0, 1, 80.0, 0.0),
        (2025, 'Individual', 5, 0, 0, 5, 0.0, 0.0)
    ) AS v(campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-003 contact record employer counts only for an account parent and overlaps the scheme link]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'7003001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7003002', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7003003', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7003004', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7003011', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7003012', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7003013', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'7003001', 2025, 5, 0, 2, 0, N'CS0101', 1, 0),
        (N'7003002', 2025, 5, 0, 2, 0, N'CS0102', 1, 0),
        (N'7003003', 2025, 5, 0, 2, 0, N'CS0109', 1, 0),
        (N'7003004', 2025, 5, 0, 2, 0, N'CS0105', 1, 0),
        (N'7003011', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7003012', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7003013', 2025, 2, 0, 1, 0, NULL, 1, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'7003001', N'CS0101', N'Scheme 101', 2025, N'Active', N'Active', 0),
        (N'7003002', N'CS0102', N'Scheme 102', 2025, N'Active', N'Active', 0),
        (N'7003003', N'CS0109', N'Scheme 109', 2025, N'Active', N'Active', 0),
        (N'7003004', N'CS0105', N'Scheme 105', 2025, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, CorporateSchemeName, apuk_corporate, apuk_onbehalfoforganisationid, AccountNumber, AccountName, Rics_contactno, statecode)
    VALUES
        (N'CS0101', N'Scheme 101', 1, '10000000-0000-0000-0000-000000002001', N'A2001', N'Scheme Firm One', N'7003001', 0),
        (N'CS0102', N'Scheme 102', 1, '10000000-0000-0000-0000-000000002002', N'A2002', N'Scheme Firm Two', N'7003002', 0),
        (N'CS0105', N'Scheme 105', 1, NULL, NULL, NULL, N'7003004', 0);

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    VALUES
        ('10000000-0000-0000-0000-000000002001', N'Scheme Firm One', N'A2001'),
        ('10000000-0000-0000-0000-000000002002', N'Scheme Firm Two', N'A2002'),
        ('10000000-0000-0000-0000-000000003001', N'Contact Firm One', N'A3001'),
        ('10000000-0000-0000-0000-000000003003', N'Contact Firm Three', N'A3003'),
        ('10000000-0000-0000-0000-000000003004', N'Contact Firm Four', N'A3004');

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdName, ParentCustomerIdType)
    VALUES
        ('30000000-0000-0000-0000-000000003001', N'7003001', '10000000-0000-0000-0000-000000003001', N'Contact Firm One', N'account'),
        ('30000000-0000-0000-0000-000000003003', N'7003003', '10000000-0000-0000-0000-000000003003', N'Contact Firm Three', N'account'),
        ('30000000-0000-0000-0000-000000003004', N'7003004', NULL, NULL, NULL),
        ('30000000-0000-0000-0000-000000003011', N'7003011', '10000000-0000-0000-0000-000000003004', N'Contact Firm Four', N'account'),
        ('30000000-0000-0000-0000-000000003012', N'7003012', '30000000-0000-0000-0000-000000003099', N'A Person', N'contact');

    CREATE TABLE #Actual
    (
        campaign_year int,
        payer_type_name varchar(30) COLLATE DATABASE_DEFAULT,
        paid_members int,
        scheme_link_employer int,
        contact_record_employer int,
        no_employer int,
        scheme_link_coverage_pct decimal(5,1),
        contact_record_coverage_pct decimal(5,1)
    );

    INSERT INTO #Actual (campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct)
    EXEC Layercake.usp_report_employer_scheme_coverage @as_of_date = '2026-03-01';

    DELETE FROM #Actual WHERE paid_members = 0;

    SELECT v.campaign_year, v.payer_type_name, v.paid_members, v.scheme_link_employer, v.contact_record_employer, v.no_employer,
        CAST(v.scheme_link_coverage_pct AS decimal(5,1)) AS scheme_link_coverage_pct,
        CAST(v.contact_record_coverage_pct AS decimal(5,1)) AS contact_record_coverage_pct
    INTO #Expected
    FROM (VALUES
        (2025, 'Corporate', 4, 2, 2, 1, 50.0, 50.0),
        (2025, 'Individual', 3, 0, 1, 2, 0.0, 33.3)
    ) AS v(campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-004 a subscription that is not live for the year gives no scheme link]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'7004001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7004002', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7004003', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7004004', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7004011', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'7004001', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7004002', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7004003', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7004004', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7004011', 2025, 5, 0, 2, 0, N'CS0205', 1, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'7004001', N'CS0201', N'Scheme 201', 2025, N'Inactive', N'Active', 0),
        (N'7004002', N'CS0202', N'Scheme 202', 2025, N'Active', N'Inactive', 0),
        (N'7004003', N'CS0203', N'Scheme 203', 2025, N'Active', N'Active', 1),
        (N'7004004', N'CS0204', N'Scheme 204', 2024, N'Active', N'Active', 0),
        (N'7004011', N'CS0205', N'Scheme 205', 2025, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, CorporateSchemeName, apuk_corporate, apuk_onbehalfoforganisationid, AccountNumber, AccountName, Rics_contactno, statecode)
    VALUES
        (N'CS0201', N'Scheme 201', 1, '10000000-0000-0000-0000-000000004001', N'A4001', N'Firm 4001', N'7004001', 0),
        (N'CS0202', N'Scheme 202', 1, '10000000-0000-0000-0000-000000004002', N'A4002', N'Firm 4002', N'7004002', 0),
        (N'CS0203', N'Scheme 203', 1, '10000000-0000-0000-0000-000000004003', N'A4003', N'Firm 4003', N'7004003', 0),
        (N'CS0204', N'Scheme 204', 1, '10000000-0000-0000-0000-000000004004', N'A4004', N'Firm 4004', N'7004004', 0),
        (N'CS0205', N'Scheme 205', 1, '10000000-0000-0000-0000-000000004005', N'A4005', N'Firm 4005', N'7004011', 0);

    CREATE TABLE #Actual
    (
        campaign_year int,
        payer_type_name varchar(30) COLLATE DATABASE_DEFAULT,
        paid_members int,
        scheme_link_employer int,
        contact_record_employer int,
        no_employer int,
        scheme_link_coverage_pct decimal(5,1),
        contact_record_coverage_pct decimal(5,1)
    );

    INSERT INTO #Actual (campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct)
    EXEC Layercake.usp_report_employer_scheme_coverage @as_of_date = '2026-03-01';

    DELETE FROM #Actual WHERE paid_members = 0;

    SELECT v.campaign_year, v.payer_type_name, v.paid_members, v.scheme_link_employer, v.contact_record_employer, v.no_employer,
        CAST(v.scheme_link_coverage_pct AS decimal(5,1)) AS scheme_link_coverage_pct,
        CAST(v.contact_record_coverage_pct AS decimal(5,1)) AS contact_record_coverage_pct
    INTO #Expected
    FROM (VALUES
        (2025, 'Corporate', 1, 1, 0, 0, 100.0, 0.0),
        (2025, 'Individual', 4, 0, 0, 4, 0.0, 0.0)
    ) AS v(campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-005 repeated scheme rows and two live subscriptions count a member once]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'7005001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7005002', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'7005001', 2025, 5, 0, 2, 0, N'CS0301', 1, 0),
        (N'7005002', 2025, 5, 0, 2, 0, N'CS0301', 1, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'7005001', N'CS0301', N'Scheme 301', 2025, N'Active', N'Active', 0),
        (N'7005001', N'CS0302', N'Scheme 302', 2025, N'Active', N'Active', 0),
        (N'7005002', N'CS0301', N'Scheme 301', 2025, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, CorporateSchemeName, apuk_corporate, apuk_onbehalfoforganisationid, AccountNumber, AccountName, Rics_contactno, statecode)
    VALUES
        (N'CS0301', N'Scheme 301', 1, '10000000-0000-0000-0000-000000005001', N'A5001', N'Firm 5001', N'7005001', 0),
        (N'CS0301', N'Scheme 301', 1, '10000000-0000-0000-0000-000000005001', N'A5001', N'Firm 5001', N'7005002', 0),
        (N'CS0302', N'Scheme 302', 1, '10000000-0000-0000-0000-000000005002', N'A5002', N'Firm 5002', N'7005001', 0);

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    VALUES
        ('10000000-0000-0000-0000-000000005001', N'Firm 5001', N'A5001'),
        ('10000000-0000-0000-0000-000000005002', N'Firm 5002', N'A5002');

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdName, ParentCustomerIdType)
    VALUES
        ('30000000-0000-0000-0000-000000005001', N'7005001', '10000000-0000-0000-0000-000000005001', N'Firm 5001', N'account');

    CREATE TABLE #Actual
    (
        campaign_year int,
        payer_type_name varchar(30) COLLATE DATABASE_DEFAULT,
        paid_members int,
        scheme_link_employer int,
        contact_record_employer int,
        no_employer int,
        scheme_link_coverage_pct decimal(5,1),
        contact_record_coverage_pct decimal(5,1)
    );

    INSERT INTO #Actual (campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct)
    EXEC Layercake.usp_report_employer_scheme_coverage @as_of_date = '2026-03-01';

    DELETE FROM #Actual WHERE paid_members = 0;

    SELECT v.campaign_year, v.payer_type_name, v.paid_members, v.scheme_link_employer, v.contact_record_employer, v.no_employer,
        CAST(v.scheme_link_coverage_pct AS decimal(5,1)) AS scheme_link_coverage_pct,
        CAST(v.contact_record_coverage_pct AS decimal(5,1)) AS contact_record_coverage_pct
    INTO #Expected
    FROM (VALUES
        (2025, 'Corporate', 2, 2, 1, 0, 100.0, 50.0)
    ) AS v(campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-006 coverage has a row per Campaign Year and payer type with Unknown on its own and unpaid years left out]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'7006001', 2024, '2023-10-15', '2023-10-15', N'Fully Paid'),
        (N'7006001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7006002', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'7006001', 2024, 5, 0, 2, 0, N'CS0401', 1, 0),
        (N'7006001', 2025, 5, 0, 2, 0, N'CS0401', 1, 0),
        (N'7006002', 2025, 0, 0, 0, 0, NULL, 1, 0),
        (N'7006003', 2025, 2, 0, 1, 0, NULL, 1, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'7006001', N'CS0401', N'Scheme 401', 2024, N'Active', N'Active', 0),
        (N'7006001', N'CS0401', N'Scheme 401', 2025, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, CorporateSchemeName, apuk_corporate, apuk_onbehalfoforganisationid, AccountNumber, AccountName, Rics_contactno, statecode)
    VALUES
        (N'CS0401', N'Scheme 401', 1, '10000000-0000-0000-0000-000000006001', N'A6001', N'Firm 6001', N'7006001', 0);

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    VALUES
        ('10000000-0000-0000-0000-000000006001', N'Firm 6001', N'A6001'),
        ('10000000-0000-0000-0000-000000006002', N'Firm 6002', N'A6002');

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdName, ParentCustomerIdType)
    VALUES
        ('30000000-0000-0000-0000-000000006002', N'7006002', '10000000-0000-0000-0000-000000006002', N'Firm 6002', N'account'),
        ('30000000-0000-0000-0000-000000006003', N'7006003', '10000000-0000-0000-0000-000000006002', N'Firm 6002', N'account');

    CREATE TABLE #Actual
    (
        campaign_year int,
        payer_type_name varchar(30) COLLATE DATABASE_DEFAULT,
        paid_members int,
        scheme_link_employer int,
        contact_record_employer int,
        no_employer int,
        scheme_link_coverage_pct decimal(5,1),
        contact_record_coverage_pct decimal(5,1)
    );

    INSERT INTO #Actual (campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct)
    EXEC Layercake.usp_report_employer_scheme_coverage @as_of_date = '2026-03-01';

    DELETE FROM #Actual WHERE paid_members = 0;

    SELECT v.campaign_year, v.payer_type_name, v.paid_members, v.scheme_link_employer, v.contact_record_employer, v.no_employer,
        CAST(v.scheme_link_coverage_pct AS decimal(5,1)) AS scheme_link_coverage_pct,
        CAST(v.contact_record_coverage_pct AS decimal(5,1)) AS contact_record_coverage_pct
    INTO #Expected
    FROM (VALUES
        (2024, 'Corporate', 1, 1, 0, 0, 100.0, 0.0),
        (2025, 'Corporate', 1, 1, 0, 0, 100.0, 0.0),
        (2025, 'Unknown', 1, 0, 1, 0, 0.0, 100.0)
    ) AS v(campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-007 three same firm and one different firm give agreement 75.0]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'7007001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7007002', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7007003', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7007004', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7007005', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7007011', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'7007001', 2025, 5, 0, 2, 0, N'CS0501', 1, 0),
        (N'7007002', 2025, 5, 0, 2, 0, N'CS0502', 1, 0),
        (N'7007003', 2025, 5, 0, 2, 0, N'CS0503', 1, 0),
        (N'7007004', 2025, 5, 0, 2, 0, N'CS0504', 1, 0),
        (N'7007005', 2025, 5, 0, 2, 0, N'CS0505', 1, 0),
        (N'7007011', 2025, 2, 0, 1, 0, NULL, 1, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'7007001', N'CS0501', N'Scheme 501', 2025, N'Active', N'Active', 0),
        (N'7007002', N'CS0502', N'Scheme 502', 2025, N'Active', N'Active', 0),
        (N'7007003', N'CS0503', N'Scheme 503', 2025, N'Active', N'Active', 0),
        (N'7007004', N'CS0504', N'Scheme 504', 2025, N'Active', N'Active', 0),
        (N'7007005', N'CS0505', N'Scheme 505', 2025, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, CorporateSchemeName, apuk_corporate, apuk_onbehalfoforganisationid, AccountNumber, AccountName, Rics_contactno, statecode)
    VALUES
        (N'CS0501', N'Scheme 501', 1, '10000000-0000-0000-0000-000000007001', N'A7001', N'Firm 7001', N'7007001', 0),
        (N'CS0502', N'Scheme 502', 1, '10000000-0000-0000-0000-000000007002', N'A7002', N'Firm 7002', N'7007002', 0),
        (N'CS0503', N'Scheme 503', 1, '10000000-0000-0000-0000-000000007003', N'A7003', N'Firm 7003', N'7007003', 0),
        (N'CS0504', N'Scheme 504', 1, '10000000-0000-0000-0000-000000007004', N'A7004', N'Firm 7004', N'7007004', 0),
        (N'CS0505', N'Scheme 505', 1, '10000000-0000-0000-0000-000000007005', N'A7005', N'Firm 7005', N'7007005', 0);

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    VALUES
        ('10000000-0000-0000-0000-000000007001', N'Firm 7001', N'A7001'),
        ('10000000-0000-0000-0000-000000007002', N'Firm 7002', N'A7002'),
        ('10000000-0000-0000-0000-000000007003', N'Firm 7003', N'A7003'),
        ('10000000-0000-0000-0000-000000007004', N'Firm 7004', N'A7004'),
        ('10000000-0000-0000-0000-000000007005', N'Firm 7005', N'A7005'),
        ('10000000-0000-0000-0000-000000007009', N'Firm 7009', N'A7009'),
        ('10000000-0000-0000-0000-000000007010', N'Firm 7010', N'A7010');

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdName, ParentCustomerIdType)
    VALUES
        ('30000000-0000-0000-0000-000000007001', N'7007001', '10000000-0000-0000-0000-000000007001', N'Firm 7001', N'account'),
        ('30000000-0000-0000-0000-000000007002', N'7007002', '10000000-0000-0000-0000-000000007002', N'Firm 7002', N'account'),
        ('30000000-0000-0000-0000-000000007003', N'7007003', '10000000-0000-0000-0000-000000007003', N'Firm 7003', N'account'),
        ('30000000-0000-0000-0000-000000007004', N'7007004', '10000000-0000-0000-0000-000000007009', N'Firm 7009', N'account'),
        ('30000000-0000-0000-0000-000000007011', N'7007011', '10000000-0000-0000-0000-000000007010', N'Firm 7010', N'account');

    CREATE TABLE #Actual
    (
        campaign_year int,
        both_sources int,
        same_firm int,
        different_firm int,
        agreement_rate_pct decimal(5,1)
    );

    INSERT INTO #Actual (campaign_year, both_sources, same_firm, different_firm, agreement_rate_pct)
    EXEC Layercake.usp_report_employer_source_agreement @as_of_date = '2026-03-01';

    DELETE FROM #Actual WHERE both_sources = 0;

    SELECT v.campaign_year, v.both_sources, v.same_firm, v.different_firm, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES
        (2025, 4, 3, 1, 75.0)
    ) AS v(campaign_year, both_sources, same_firm, different_firm, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-008 agreement compares account ids not firm names]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'7008001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7008002', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'7008001', 2025, 5, 0, 2, 0, N'CS0601', 1, 0),
        (N'7008002', 2025, 5, 0, 2, 0, N'CS0602', 1, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'7008001', N'CS0601', N'Scheme 601', 2025, N'Active', N'Active', 0),
        (N'7008002', N'CS0602', N'Scheme 602', 2025, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, CorporateSchemeName, apuk_corporate, apuk_onbehalfoforganisationid, AccountNumber, AccountName, Rics_contactno, statecode)
    VALUES
        (N'CS0601', N'Scheme 601', 1, '10000000-0000-0000-0000-000000008061', N'A8061', N'Acme Surveyors', N'7008001', 0),
        (N'CS0602', N'Scheme 602', 1, '10000000-0000-0000-0000-000000008063', N'A8063', N'Beta LLP', N'7008002', 0);

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    VALUES
        ('10000000-0000-0000-0000-000000008061', N'Acme Surveyors', N'A8061'),
        ('10000000-0000-0000-0000-000000008062', N'Acme Surveyors', N'A8062'),
        ('10000000-0000-0000-0000-000000008063', N'Beta Ltd', N'A8063');

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdName, ParentCustomerIdType)
    VALUES
        ('30000000-0000-0000-0000-000000008001', N'7008001', '10000000-0000-0000-0000-000000008062', N'Acme Surveyors', N'account'),
        ('30000000-0000-0000-0000-000000008002', N'7008002', '10000000-0000-0000-0000-000000008063', N'Beta Ltd', N'account');

    CREATE TABLE #Actual
    (
        campaign_year int,
        both_sources int,
        same_firm int,
        different_firm int,
        agreement_rate_pct decimal(5,1)
    );

    INSERT INTO #Actual (campaign_year, both_sources, same_firm, different_firm, agreement_rate_pct)
    EXEC Layercake.usp_report_employer_source_agreement @as_of_date = '2026-03-01';

    DELETE FROM #Actual WHERE both_sources = 0;

    SELECT v.campaign_year, v.both_sources, v.same_firm, v.different_firm, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES
        (2025, 2, 1, 1, 50.0)
    ) AS v(campaign_year, both_sources, same_firm, different_firm, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-009 agreement is counted per contact year by Campaign Year and two in three rounds to 66.7]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'7009001', 2024, '2023-10-15', '2023-10-15', N'Fully Paid'),
        (N'7009001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7009002', 2024, '2023-10-15', '2023-10-15', N'Fully Paid'),
        (N'7009003', 2024, '2023-10-15', '2023-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'7009001', 2024, 5, 0, 2, 0, N'CS0701', 1, 0),
        (N'7009001', 2025, 5, 0, 2, 0, N'CS0701', 1, 0),
        (N'7009002', 2024, 5, 0, 2, 0, N'CS0702', 1, 0),
        (N'7009003', 2024, 5, 0, 2, 0, N'CS0703', 1, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'7009001', N'CS0701', N'Scheme 701', 2024, N'Active', N'Active', 0),
        (N'7009001', N'CS0701', N'Scheme 701', 2025, N'Active', N'Active', 0),
        (N'7009002', N'CS0702', N'Scheme 702', 2024, N'Active', N'Active', 0),
        (N'7009003', N'CS0703', N'Scheme 703', 2024, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, CorporateSchemeName, apuk_corporate, apuk_onbehalfoforganisationid, AccountNumber, AccountName, Rics_contactno, statecode)
    VALUES
        (N'CS0701', N'Scheme 701', 1, '10000000-0000-0000-0000-000000009001', N'A9001', N'Firm 9001', N'7009001', 0),
        (N'CS0702', N'Scheme 702', 1, '10000000-0000-0000-0000-000000009002', N'A9002', N'Firm 9002', N'7009002', 0),
        (N'CS0703', N'Scheme 703', 1, '10000000-0000-0000-0000-000000009003', N'A9003', N'Firm 9003', N'7009003', 0);

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    VALUES
        ('10000000-0000-0000-0000-000000009001', N'Firm 9001', N'A9001'),
        ('10000000-0000-0000-0000-000000009002', N'Firm 9002', N'A9002'),
        ('10000000-0000-0000-0000-000000009003', N'Firm 9003', N'A9003'),
        ('10000000-0000-0000-0000-000000009009', N'Firm 9009', N'A9009');

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdName, ParentCustomerIdType)
    VALUES
        ('30000000-0000-0000-0000-000000009001', N'7009001', '10000000-0000-0000-0000-000000009001', N'Firm 9001', N'account'),
        ('30000000-0000-0000-0000-000000009002', N'7009002', '10000000-0000-0000-0000-000000009002', N'Firm 9002', N'account'),
        ('30000000-0000-0000-0000-000000009003', N'7009003', '10000000-0000-0000-0000-000000009009', N'Firm 9009', N'account');

    CREATE TABLE #Actual
    (
        campaign_year int,
        both_sources int,
        same_firm int,
        different_firm int,
        agreement_rate_pct decimal(5,1)
    );

    INSERT INTO #Actual (campaign_year, both_sources, same_firm, different_firm, agreement_rate_pct)
    EXEC Layercake.usp_report_employer_source_agreement @as_of_date = '2026-03-01';

    DELETE FROM #Actual WHERE both_sources = 0;

    SELECT v.campaign_year, v.both_sources, v.same_firm, v.different_firm, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES
        (2024, 3, 2, 1, 66.7),
        (2025, 1, 1, 0, 100.0)
    ) AS v(campaign_year, both_sources, same_firm, different_firm, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-010 the three reports return only aggregate columns and no contact number]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'7010001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7010002', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7010011', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'7010001', 2025, 5, 0, 2, 0, N'CS1001', 1, 0),
        (N'7010002', 2025, 5, 0, 2, 0, N'CS1001', 1, 0),
        (N'7010011', 2025, 2, 0, 1, 0, NULL, 1, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'7010001', N'CS1001', N'Scheme 1001', 2025, N'Active', N'Active', 0),
        (N'7010002', N'CS1001', N'Scheme 1001', 2025, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, CorporateSchemeName, apuk_corporate, apuk_onbehalfoforganisationid, AccountNumber, AccountName, Rics_contactno, statecode)
    VALUES
        (N'CS1001', N'Scheme 1001', 1, '10000000-0000-0000-0000-000000010001', N'D8001', N'Delta Partners', N'7010001', 0),
        (N'CS1001', N'Scheme 1001', 1, '10000000-0000-0000-0000-000000010001', N'D8001', N'Delta Partners', N'7010002', 0);

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    VALUES
        ('10000000-0000-0000-0000-000000010001', N'Delta Partners', N'D8001');

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdName, ParentCustomerIdType)
    VALUES
        ('30000000-0000-0000-0000-000000010001', N'7010001', '10000000-0000-0000-0000-000000010001', N'Delta Partners', N'account'),
        ('30000000-0000-0000-0000-000000010002', N'7010002', '10000000-0000-0000-0000-000000010001', N'Delta Partners', N'account'),
        ('30000000-0000-0000-0000-000000010011', N'7010011', '10000000-0000-0000-0000-000000010001', N'Delta Partners', N'account');

    CREATE TABLE #Coverage
    (
        campaign_year int,
        payer_type_name varchar(30) COLLATE DATABASE_DEFAULT,
        paid_members int,
        scheme_link_employer int,
        contact_record_employer int,
        no_employer int,
        scheme_link_coverage_pct decimal(5,1),
        contact_record_coverage_pct decimal(5,1)
    );

    CREATE TABLE #Agreement
    (
        campaign_year int,
        both_sources int,
        same_firm int,
        different_firm int,
        agreement_rate_pct decimal(5,1)
    );

    CREATE TABLE #Top
    (
        employer_account_number nvarchar(20) COLLATE DATABASE_DEFAULT,
        employer_name nvarchar(160) COLLATE DATABASE_DEFAULT,
        corporate_paid_members int,
        individual_paid_members int,
        paid_members int
    );

    INSERT INTO #Coverage (campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct)
    EXEC Layercake.usp_report_employer_scheme_coverage @as_of_date = '2026-03-01';

    INSERT INTO #Agreement (campaign_year, both_sources, same_firm, different_firm, agreement_rate_pct)
    EXEC Layercake.usp_report_employer_source_agreement @as_of_date = '2026-03-01';

    INSERT INTO #Top (employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members)
    EXEC Layercake.usp_report_top_employers @as_of_date = '2026-03-01';

    DELETE FROM #Coverage WHERE paid_members = 0;
    DELETE FROM #Agreement WHERE both_sources = 0;

    SELECT v.campaign_year, v.payer_type_name, v.paid_members, v.scheme_link_employer, v.contact_record_employer, v.no_employer,
        CAST(v.scheme_link_coverage_pct AS decimal(5,1)) AS scheme_link_coverage_pct,
        CAST(v.contact_record_coverage_pct AS decimal(5,1)) AS contact_record_coverage_pct
    INTO #ExpectedCoverage
    FROM (VALUES
        (2025, 'Corporate', 2, 2, 2, 0, 100.0, 100.0),
        (2025, 'Individual', 1, 0, 1, 0, 0.0, 100.0)
    ) AS v(campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct);

    SELECT v.campaign_year, v.both_sources, v.same_firm, v.different_firm, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #ExpectedAgreement
    FROM (VALUES
        (2025, 2, 2, 0, 100.0)
    ) AS v(campaign_year, both_sources, same_firm, different_firm, agreement_rate_pct);

    SELECT v.employer_account_number, v.employer_name, v.corporate_paid_members, v.individual_paid_members, v.paid_members
    INTO #ExpectedTop
    FROM (VALUES
        (N'D8001', N'Delta Partners', 2, 1, 3)
    ) AS v(employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members);

    SELECT x.text_value
    INTO #ContactValues
    FROM (
        SELECT CAST(c.payer_type_name AS nvarchar(200)) AS text_value FROM #Coverage AS c
        UNION ALL
        SELECT CAST(t.employer_account_number AS nvarchar(200)) FROM #Top AS t
        UNION ALL
        SELECT CAST(t.employer_name AS nvarchar(200)) FROM #Top AS t
    ) AS x
    INNER JOIN Layercake.silv_payment_events AS p
        ON p.contact_no = x.text_value;

    EXEC tSQLt.AssertEqualsTable @Expected = '#ExpectedCoverage', @Actual = '#Coverage';
    EXEC tSQLt.AssertEqualsTable @Expected = '#ExpectedAgreement', @Actual = '#Agreement';
    EXEC tSQLt.AssertEqualsTable @Expected = '#ExpectedTop', @Actual = '#Top';
    EXEC tSQLt.AssertEmptyTable @TableName = '#ContactValues';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-011 top employers count corporate under the scheme firm and individual under the contact record firm]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'7011001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7011002', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7011003', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7011004', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7011011', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7011012', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7011013', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7011014', 2024, '2023-10-15', '2023-10-15', N'Fully Paid'),
        (N'7011015', 2026, '2025-10-15', '2025-10-15', N'Fully Paid'),
        (N'7011021', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'7011001', 2025, 5, 0, 2, 0, N'CS1101', 1, 0),
        (N'7011002', 2025, 5, 0, 2, 0, N'CS1101', 1, 0),
        (N'7011003', 2025, 5, 0, 2, 0, N'CS1109', 1, 0),
        (N'7011004', 2025, 5, 0, 2, 0, N'CS1108', 1, 0),
        (N'7011011', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7011012', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7011013', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7011014', 2024, 2, 0, 1, 0, NULL, 1, 0),
        (N'7011015', 2026, 2, 0, 1, 0, NULL, 1, 0),
        (N'7011021', 2025, 0, 0, 0, 0, NULL, 1, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'7011001', N'CS1101', N'Scheme 1101', 2025, N'Active', N'Active', 0),
        (N'7011002', N'CS1101', N'Scheme 1101', 2025, N'Active', N'Active', 0),
        (N'7011003', N'CS1109', N'Scheme 1109', 2025, N'Active', N'Active', 0),
        (N'7011004', N'CS1108', N'Scheme 1108', 2025, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, CorporateSchemeName, apuk_corporate, apuk_onbehalfoforganisationid, AccountNumber, AccountName, Rics_contactno, statecode)
    VALUES
        (N'CS1101', N'Scheme 1101', 1, '10000000-0000-0000-0000-000000000100', N'A100', N'Alpha Partners', N'7011001', 0),
        (N'CS1101', N'Scheme 1101', 1, '10000000-0000-0000-0000-000000000100', N'A100', N'Alpha Partners', N'7011002', 0);

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    VALUES
        ('10000000-0000-0000-0000-000000000100', N'Alpha Partners', N'A100'),
        ('10000000-0000-0000-0000-000000000200', N'Beta Surveyors', N'B200'),
        ('10000000-0000-0000-0000-000000000300', N'Gamma Estates', N'C300');

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdName, ParentCustomerIdType)
    VALUES
        ('30000000-0000-0000-0000-000000011001', N'7011001', '10000000-0000-0000-0000-000000000300', N'Gamma Estates', N'account'),
        ('30000000-0000-0000-0000-000000011003', N'7011003', '10000000-0000-0000-0000-000000000200', N'Beta Surveyors', N'account'),
        ('30000000-0000-0000-0000-000000011011', N'7011011', '10000000-0000-0000-0000-000000000100', N'Alpha Partners', N'account'),
        ('30000000-0000-0000-0000-000000011012', N'7011012', '10000000-0000-0000-0000-000000000200', N'Beta Surveyors', N'account'),
        ('30000000-0000-0000-0000-000000011013', N'7011013', '10000000-0000-0000-0000-000000000200', N'Beta Surveyors', N'account'),
        ('30000000-0000-0000-0000-000000011014', N'7011014', '10000000-0000-0000-0000-000000000200', N'Beta Surveyors', N'account'),
        ('30000000-0000-0000-0000-000000011015', N'7011015', '10000000-0000-0000-0000-000000000200', N'Beta Surveyors', N'account'),
        ('30000000-0000-0000-0000-000000011021', N'7011021', '10000000-0000-0000-0000-000000000100', N'Alpha Partners', N'account');

    CREATE TABLE #Actual
    (
        employer_account_number nvarchar(20) COLLATE DATABASE_DEFAULT,
        employer_name nvarchar(160) COLLATE DATABASE_DEFAULT,
        corporate_paid_members int,
        individual_paid_members int,
        paid_members int
    );

    INSERT INTO #Actual (employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members)
    EXEC Layercake.usp_report_top_employers @as_of_date = '2026-03-01';

    SELECT v.employer_account_number, v.employer_name, v.corporate_paid_members, v.individual_paid_members, v.paid_members
    INTO #Expected
    FROM (VALUES
        (N'A100', N'Alpha Partners', 2, 1, 3),
        (N'B200', N'Beta Surveyors', 1, 2, 3)
    ) AS v(employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-012 top employers keep the 25 firms with most paid members]
AS
BEGIN
    WITH digits AS (
        SELECT d.n FROM (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) AS d(n)
    ),
    firms AS (
        SELECT tens.n * 10 + units.n AS firm_no
        FROM digits AS tens
        CROSS JOIN digits AS units
        WHERE tens.n * 10 + units.n BETWEEN 1 AND 25
    ),
    members AS (
        SELECT f.firm_no, m.member_no
        FROM firms AS f
        CROSS JOIN (VALUES (1), (2)) AS m(member_no)
        UNION ALL
        SELECT 0, 1
    )
    SELECT
        CAST(7120000 + m.firm_no * 10 + m.member_no AS nvarchar(200)) AS contact_no,
        CAST('10000000-0000-0000-0000-' + RIGHT('000000000000' + CAST(120000 + m.firm_no AS varchar(12)), 12) AS uniqueidentifier) AS account_id,
        CAST(N'E' + RIGHT(N'000' + CAST(m.firm_no AS nvarchar(3)), 3) AS nvarchar(20)) AS account_number,
        m.firm_no
    INTO #Members
    FROM members AS m;

    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    SELECT mb.contact_no, 2025, '2024-10-15', '2024-10-15', N'Fully Paid'
    FROM #Members AS mb;

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    SELECT mb.contact_no, 2025, 2, 0, 1, 0, NULL, 1, 0
    FROM #Members AS mb;

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    SELECT DISTINCT mb.account_id, N'Firm ' + mb.account_number, mb.account_number
    FROM #Members AS mb;

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdName, ParentCustomerIdType)
    SELECT NEWID(), mb.contact_no, mb.account_id, N'Firm ' + mb.account_number, N'account'
    FROM #Members AS mb;

    CREATE TABLE #Actual
    (
        employer_account_number nvarchar(20) COLLATE DATABASE_DEFAULT,
        employer_name nvarchar(160) COLLATE DATABASE_DEFAULT,
        corporate_paid_members int,
        individual_paid_members int,
        paid_members int
    );

    INSERT INTO #Actual (employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members)
    EXEC Layercake.usp_report_top_employers @as_of_date = '2026-03-01';

    DECLARE @rows int = (SELECT COUNT(*) FROM #Actual);
    DECLARE @e000_rows int = (SELECT COUNT(*) FROM #Actual WHERE employer_account_number = N'E000');
    DECLARE @rows_not_two int = (SELECT COUNT(*) FROM #Actual WHERE paid_members <> 2 OR individual_paid_members <> 2 OR corporate_paid_members <> 0);
    DECLARE @total int = (SELECT SUM(paid_members) FROM #Actual);

    EXEC tSQLt.AssertEquals @Expected = 25, @Actual = @rows, @Message = N'Row count';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @e000_rows, @Message = N'E000 has 1 paid member and is 26th';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @rows_not_two, @Message = N'Every listed firm has 2 individual paid members';
    EXEC tSQLt.AssertEquals @Expected = 50, @Actual = @total, @Message = N'Total paid members listed';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-013 a tie at 25th place still gives exactly 25 firms and the same list on every run]
AS
BEGIN
    WITH digits AS (
        SELECT d.n FROM (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) AS d(n)
    ),
    firms AS (
        SELECT tens.n * 10 + units.n AS firm_no
        FROM digits AS tens
        CROSS JOIN digits AS units
        WHERE tens.n * 10 + units.n BETWEEN 1 AND 27
    ),
    members AS (
        SELECT f.firm_no, m.member_no
        FROM firms AS f
        CROSS JOIN (VALUES (1), (2), (3)) AS m(member_no)
        WHERE f.firm_no <= 24 OR m.member_no = 1
    )
    SELECT
        CAST(7130000 + m.firm_no * 10 + m.member_no AS nvarchar(200)) AS contact_no,
        CAST('10000000-0000-0000-0000-' + RIGHT('000000000000' + CAST(130000 + m.firm_no AS varchar(12)), 12) AS uniqueidentifier) AS account_id,
        CAST(CASE WHEN m.firm_no <= 24 THEN N'G' + RIGHT(N'000' + CAST(100 + m.firm_no AS nvarchar(3)), 3) ELSE N'H' + RIGHT(N'000' + CAST(m.firm_no - 24 AS nvarchar(3)), 3) END AS nvarchar(20)) AS account_number
    INTO #Members
    FROM members AS m;

    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    SELECT mb.contact_no, 2025, '2024-10-15', '2024-10-15', N'Fully Paid'
    FROM #Members AS mb;

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    SELECT mb.contact_no, 2025, 2, 0, 1, 0, NULL, 1, 0
    FROM #Members AS mb;

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    SELECT DISTINCT mb.account_id, N'Firm ' + mb.account_number, mb.account_number
    FROM #Members AS mb;

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdName, ParentCustomerIdType)
    SELECT NEWID(), mb.contact_no, mb.account_id, N'Firm ' + mb.account_number, N'account'
    FROM #Members AS mb;

    CREATE TABLE #Run1
    (
        employer_account_number nvarchar(20) COLLATE DATABASE_DEFAULT,
        employer_name nvarchar(160) COLLATE DATABASE_DEFAULT,
        corporate_paid_members int,
        individual_paid_members int,
        paid_members int
    );

    CREATE TABLE #Run2
    (
        employer_account_number nvarchar(20) COLLATE DATABASE_DEFAULT,
        employer_name nvarchar(160) COLLATE DATABASE_DEFAULT,
        corporate_paid_members int,
        individual_paid_members int,
        paid_members int
    );

    INSERT INTO #Run1 (employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members)
    EXEC Layercake.usp_report_top_employers @as_of_date = '2026-03-01';

    INSERT INTO #Run2 (employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members)
    EXEC Layercake.usp_report_top_employers @as_of_date = '2026-03-01';

    DECLARE @rows int = (SELECT COUNT(*) FROM #Run1);
    DECLARE @g_rows int = (SELECT COUNT(*) FROM #Run1 WHERE employer_account_number LIKE N'G%' AND paid_members = 3);
    DECLARE @h_rows int = (SELECT COUNT(*) FROM #Run1 WHERE employer_account_number LIKE N'H%' AND paid_members = 1);

    EXEC tSQLt.AssertEquals @Expected = 25, @Actual = @rows, @Message = N'Row count';
    EXEC tSQLt.AssertEquals @Expected = 24, @Actual = @g_rows, @Message = N'All 24 firms with 3 paid members are listed';
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @h_rows, @Message = N'Exactly one of the three firms tied at 1 is listed';
    EXEC tSQLt.AssertEqualsTable @Expected = '#Run1', @Actual = '#Run2', @Message = N'A second run lists the same firms';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-014 the last full Campaign Year is the one before the year covering the as-of date]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'7014001', 2024, '2023-10-15', '2023-10-15', N'Fully Paid'),
        (N'7014002', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7014003', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'7014001', 2024, 2, 0, 1, 0, NULL, 1, 0),
        (N'7014002', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7014003', 2025, 2, 0, 1, 0, NULL, 1, 0);

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    VALUES ('10000000-0000-0000-0000-000000014100', N'Juniper LLP', N'J100');

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdName, ParentCustomerIdType)
    VALUES
        ('30000000-0000-0000-0000-000000014001', N'7014001', '10000000-0000-0000-0000-000000014100', N'Juniper LLP', N'account'),
        ('30000000-0000-0000-0000-000000014002', N'7014002', '10000000-0000-0000-0000-000000014100', N'Juniper LLP', N'account'),
        ('30000000-0000-0000-0000-000000014003', N'7014003', '10000000-0000-0000-0000-000000014100', N'Juniper LLP', N'account');

    CREATE TABLE #ActualSep
    (
        employer_account_number nvarchar(20) COLLATE DATABASE_DEFAULT,
        employer_name nvarchar(160) COLLATE DATABASE_DEFAULT,
        corporate_paid_members int,
        individual_paid_members int,
        paid_members int
    );

    CREATE TABLE #ActualOct
    (
        employer_account_number nvarchar(20) COLLATE DATABASE_DEFAULT,
        employer_name nvarchar(160) COLLATE DATABASE_DEFAULT,
        corporate_paid_members int,
        individual_paid_members int,
        paid_members int
    );

    INSERT INTO #ActualSep (employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members)
    EXEC Layercake.usp_report_top_employers @as_of_date = '2025-09-30';

    INSERT INTO #ActualOct (employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members)
    EXEC Layercake.usp_report_top_employers @as_of_date = '2025-10-01';

    SELECT v.employer_account_number, v.employer_name, v.corporate_paid_members, v.individual_paid_members, v.paid_members
    INTO #ExpectedSep
    FROM (VALUES
        (N'J100', N'Juniper LLP', 0, 1, 1)
    ) AS v(employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members);

    SELECT v.employer_account_number, v.employer_name, v.corporate_paid_members, v.individual_paid_members, v.paid_members
    INTO #ExpectedOct
    FROM (VALUES
        (N'J100', N'Juniper LLP', 0, 2, 2)
    ) AS v(employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members);

    EXEC tSQLt.AssertEqualsTable @Expected = '#ExpectedSep', @Actual = '#ActualSep', @Message = N'As of 2025-09-30 the last full year is 2024';
    EXEC tSQLt.AssertEqualsTable @Expected = '#ExpectedOct', @Actual = '#ActualOct', @Message = N'As of 2025-10-01 the last full year is 2025';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-015 top employers count a member once despite repeated scheme rows and two live subscriptions]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'7015001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7015002', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'7015001', 2025, 5, 0, 2, 0, N'CS1501', 1, 0),
        (N'7015002', 2025, 5, 0, 2, 0, N'CS1501', 1, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'7015001', N'CS1501', N'Scheme 1501', 2025, N'Active', N'Active', 0),
        (N'7015001', N'CS1502', N'Scheme 1502', 2025, N'Active', N'Active', 0),
        (N'7015002', N'CS1501', N'Scheme 1501', 2025, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, CorporateSchemeName, apuk_corporate, apuk_onbehalfoforganisationid, AccountNumber, AccountName, Rics_contactno, statecode)
    VALUES
        (N'CS1501', N'Scheme 1501', 1, '10000000-0000-0000-0000-000000015100', N'K100', N'Kestrel Group', N'7015001', 0),
        (N'CS1501', N'Scheme 1501', 1, '10000000-0000-0000-0000-000000015100', N'K100', N'Kestrel Group', N'7015002', 0),
        (N'CS1502', N'Scheme 1502', 1, '10000000-0000-0000-0000-000000015100', N'K100', N'Kestrel Group', N'7015001', 0);

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    VALUES ('10000000-0000-0000-0000-000000015100', N'Kestrel Group', N'K100');

    CREATE TABLE #Actual
    (
        employer_account_number nvarchar(20) COLLATE DATABASE_DEFAULT,
        employer_name nvarchar(160) COLLATE DATABASE_DEFAULT,
        corporate_paid_members int,
        individual_paid_members int,
        paid_members int
    );

    INSERT INTO #Actual (employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members)
    EXEC Layercake.usp_report_top_employers @as_of_date = '2026-03-01';

    SELECT v.employer_account_number, v.employer_name, v.corporate_paid_members, v.individual_paid_members, v.paid_members
    INTO #Expected
    FROM (VALUES
        (N'K100', N'Kestrel Group', 2, 0, 2)
    ) AS v(employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014.[test TC-014-016 Unknown payer type is its own coverage row and is left out of top employers]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'7016001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7016011', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7016021', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'7016022', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'7016001', 2025, 5, 0, 2, 0, N'CS1601', 1, 0),
        (N'7016011', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'7016021', 2025, 0, 0, 0, 0, NULL, 1, 0),
        (N'7016022', 2025, 0, 0, 0, 0, NULL, 1, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'7016001', N'CS1601', N'Scheme 1601', 2025, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, CorporateSchemeName, apuk_corporate, apuk_onbehalfoforganisationid, AccountNumber, AccountName, Rics_contactno, statecode)
    VALUES
        (N'CS1601', N'Scheme 1601', 1, '10000000-0000-0000-0000-000000016100', N'L100', N'Lark Partners', N'7016001', 0);

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    VALUES ('10000000-0000-0000-0000-000000016100', N'Lark Partners', N'L100');

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdName, ParentCustomerIdType)
    VALUES
        ('30000000-0000-0000-0000-000000016011', N'7016011', '10000000-0000-0000-0000-000000016100', N'Lark Partners', N'account'),
        ('30000000-0000-0000-0000-000000016021', N'7016021', '10000000-0000-0000-0000-000000016100', N'Lark Partners', N'account'),
        ('30000000-0000-0000-0000-000000016022', N'7016022', '10000000-0000-0000-0000-000000016100', N'Lark Partners', N'account');

    CREATE TABLE #Coverage
    (
        campaign_year int,
        payer_type_name varchar(30) COLLATE DATABASE_DEFAULT,
        paid_members int,
        scheme_link_employer int,
        contact_record_employer int,
        no_employer int,
        scheme_link_coverage_pct decimal(5,1),
        contact_record_coverage_pct decimal(5,1)
    );

    CREATE TABLE #Top
    (
        employer_account_number nvarchar(20) COLLATE DATABASE_DEFAULT,
        employer_name nvarchar(160) COLLATE DATABASE_DEFAULT,
        corporate_paid_members int,
        individual_paid_members int,
        paid_members int
    );

    INSERT INTO #Coverage (campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct)
    EXEC Layercake.usp_report_employer_scheme_coverage @as_of_date = '2026-03-01';

    INSERT INTO #Top (employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members)
    EXEC Layercake.usp_report_top_employers @as_of_date = '2026-03-01';

    DELETE FROM #Coverage WHERE paid_members = 0;

    SELECT v.campaign_year, v.payer_type_name, v.paid_members, v.scheme_link_employer, v.contact_record_employer, v.no_employer,
        CAST(v.scheme_link_coverage_pct AS decimal(5,1)) AS scheme_link_coverage_pct,
        CAST(v.contact_record_coverage_pct AS decimal(5,1)) AS contact_record_coverage_pct
    INTO #ExpectedCoverage
    FROM (VALUES
        (2025, 'Corporate', 1, 1, 0, 0, 100.0, 0.0),
        (2025, 'Individual', 1, 0, 1, 0, 0.0, 100.0),
        (2025, 'Unknown', 2, 0, 2, 0, 0.0, 100.0)
    ) AS v(campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct);

    SELECT v.employer_account_number, v.employer_name, v.corporate_paid_members, v.individual_paid_members, v.paid_members
    INTO #ExpectedTop
    FROM (VALUES
        (N'L100', N'Lark Partners', 1, 1, 2)
    ) AS v(employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members);

    EXEC tSQLt.AssertEqualsTable @Expected = '#ExpectedCoverage', @Actual = '#Coverage';
    EXEC tSQLt.AssertEqualsTable @Expected = '#ExpectedTop', @Actual = '#Top';
END;
GO
