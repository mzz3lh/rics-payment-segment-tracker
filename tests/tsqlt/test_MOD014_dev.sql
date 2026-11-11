EXEC tSQLt.NewTestClass 'test_MOD014_dev';
GO

CREATE PROCEDURE test_MOD014_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type';
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription';
    EXEC tSQLt.FakeTable 'CE.vwCorporateSchemes';
    EXEC tSQLt.FakeTable 'CE.vwContact';
    EXEC tSQLt.FakeTable 'CE.vwAccount';

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name)
    VALUES (0, 'Unknown'), (-1, 'Unrecognised'), (-2, 'Not applicable'), (1, 'Individual'), (2, 'Corporate');

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES
        (2024, '2023-10-01', '2024-09-30', '2024-09-30'),
        (2025, '2024-10-01', '2025-09-30', '2025-09-30'),
        (2026, '2025-10-01', '2026-09-30', '2026-09-30');
END;
GO

CREATE PROCEDURE test_MOD014_dev.[test coverage counts a paid year with no attributes row as Unknown and a scheme link for an Individual]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'8001001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'8001002', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES (N'8001002', 2025, 2, 0, 1, 0, NULL, 1, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'8001002', N'CS8001', N'Scheme 8001', 2025, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, AccountNumber, AccountName, apuk_onbehalfoforganisationid)
    VALUES (N'CS8001', N'F8001', N'Firm 8001', '10000000-0000-0000-0000-000000080001');

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

    SELECT v.campaign_year, v.payer_type_name, v.paid_members, v.scheme_link_employer, v.contact_record_employer, v.no_employer,
        CAST(v.scheme_link_coverage_pct AS decimal(5,1)) AS scheme_link_coverage_pct,
        CAST(v.contact_record_coverage_pct AS decimal(5,1)) AS contact_record_coverage_pct
    INTO #Expected
    FROM (VALUES
        (2025, 'Unknown', 1, 0, 0, 1, 0.0, 0.0),
        (2025, 'Individual', 1, 1, 0, 0, 100.0, 0.0)
    ) AS v(campaign_year, payer_type_name, paid_members, scheme_link_employer, contact_record_employer, no_employer, scheme_link_coverage_pct, contact_record_coverage_pct);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014_dev.[test agreement is same firm when any scheme firm equals the contact parent and ignores a scheme row with no AccountNumber]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'8002001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'8002002', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'8002001', N'CS8021', N'Scheme 8021', 2025, N'Active', N'Active', 0),
        (N'8002001', N'CS8022', N'Scheme 8022', 2025, N'Active', N'Active', 0),
        (N'8002002', N'CS8023', N'Scheme 8023', 2025, N'Active', N'Active', 0);

    -- CS8023 names an organisation but has no AccountNumber, so it is no scheme link.
    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, AccountNumber, AccountName, apuk_onbehalfoforganisationid)
    VALUES
        (N'CS8021', N'F8021', N'Firm 8021', '10000000-0000-0000-0000-000000080021'),
        (N'CS8022', N'F8022', N'Firm 8022', '10000000-0000-0000-0000-000000080022'),
        (N'CS8023', NULL, NULL, '10000000-0000-0000-0000-000000080023');

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdType)
    VALUES
        ('30000000-0000-0000-0000-000000080001', N'8002001', '10000000-0000-0000-0000-000000080022', N'account'),
        ('30000000-0000-0000-0000-000000080002', N'8002002', '10000000-0000-0000-0000-000000080023', N'account');

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

    SELECT v.campaign_year, v.both_sources, v.same_firm, v.different_firm, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2025, 1, 1, 0, 100.0)) AS v(campaign_year, both_sources, same_firm, different_firm, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014_dev.[test agreement returns no row for a year with no member holding both sources]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'8003001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdType)
    VALUES ('30000000-0000-0000-0000-000000080031', N'8003001', '10000000-0000-0000-0000-000000080031', N'account');

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

    EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014_dev.[test top employers take the lowest scheme_no firm and the lowest contact firm and count an Individual under its contact firm]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'8004001', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'8004011', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'8004012', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'8004001', 2025, 5, 0, 2, 0, N'CS8041', 1, 0),
        (N'8004011', 2025, 2, 0, 1, 0, NULL, 1, 0),
        (N'8004012', 2025, 2, 0, 1, 0, NULL, 1, 0);

    -- 8004001 has two live schemes of different firms: CS8041 (lower scheme_no, firm Z900) wins.
    -- 8004012 is Individual with a live scheme link to P100; it counts under its contact firm.
    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES
        (N'8004001', N'CS8042', N'Scheme 8042', 2025, N'Active', N'Active', 0),
        (N'8004001', N'CS8041', N'Scheme 8041', 2025, N'Active', N'Active', 0),
        (N'8004012', N'CS8042', N'Scheme 8042', 2025, N'Active', N'Active', 0);

    INSERT INTO CE.vwCorporateSchemes (apuk_subscriptionnumber, AccountNumber, AccountName, apuk_onbehalfoforganisationid)
    VALUES
        (N'CS8041', N'Z900', N'Zeta Group', '10000000-0000-0000-0000-000000000900'),
        (N'CS8042', N'P100', N'Pi Partners', '10000000-0000-0000-0000-000000000101');

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    VALUES
        ('10000000-0000-0000-0000-000000000101', N'Pi Partners', N'P100'),
        ('10000000-0000-0000-0000-000000000201', N'Rho Estates', N'R200'),
        ('10000000-0000-0000-0000-000000000301', N'Sigma LLP', N'S300');

    -- 8004011 has two contact rows: R200 sorts before S300 and wins.
    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdType)
    VALUES
        ('30000000-0000-0000-0000-000000080411', N'8004011', '10000000-0000-0000-0000-000000000301', N'account'),
        ('30000000-0000-0000-0000-000000080412', N'8004011', '10000000-0000-0000-0000-000000000201', N'account'),
        ('30000000-0000-0000-0000-000000080413', N'8004012', '10000000-0000-0000-0000-000000000301', N'account');

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
        (N'R200', N'Rho Estates', 0, 1, 1),
        (N'S300', N'Sigma LLP', 0, 1, 1),
        (N'Z900', N'Zeta Group', 1, 0, 1)
    ) AS v(employer_account_number, employer_name, corporate_paid_members, individual_paid_members, paid_members);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE test_MOD014_dev.[test top employers break a tie at 25th place by the lowest account number and leave out Unrecognised]
AS
BEGIN
    WITH digits AS (
        SELECT d.n FROM (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) AS d(n)
    )
    SELECT
        CAST(8005000 + tens.n * 10 + units.n AS nvarchar(200)) AS contact_no,
        CAST('10000000-0000-0000-0000-' + RIGHT('000000000000' + CAST(805000 + tens.n * 10 + units.n AS varchar(12)), 12) AS uniqueidentifier) AS account_id,
        CAST(N'T' + RIGHT(N'00' + CAST(tens.n * 10 + units.n AS nvarchar(2)), 2) AS nvarchar(20)) AS account_number
    INTO #Members
    FROM digits AS tens
    CROSS JOIN digits AS units
    WHERE tens.n * 10 + units.n BETWEEN 1 AND 26;

    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    SELECT mb.contact_no, 2025, '2024-10-15', '2024-10-15', N'Fully Paid'
    FROM #Members AS mb;

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    SELECT mb.contact_no, 2025, 2, 0, 1, 0, NULL, 1, 0
    FROM #Members AS mb;

    INSERT INTO CE.vwAccount (AccountId, name, AccountNumber)
    SELECT mb.account_id, N'Firm ' + mb.account_number, mb.account_number
    FROM #Members AS mb;

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdType)
    SELECT NEWID(), mb.contact_no, mb.account_id, N'account'
    FROM #Members AS mb;

    -- Two Unrecognised members of T26 would lift it to the top if they counted.
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES
        (N'8005901', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
        (N'8005902', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried)
    VALUES
        (N'8005901', 2025, -1, 0, -1, 0, NULL, 1, 0),
        (N'8005902', 2025, -1, 0, -1, 0, NULL, 1, 0);

    INSERT INTO CE.vwContact (ContactId, Rics_contactno, ParentCustomerId, ParentCustomerIdType)
    VALUES
        ('30000000-0000-0000-0000-000000805901', N'8005901', '10000000-0000-0000-0000-000000805026', N'account'),
        ('30000000-0000-0000-0000-000000805902', N'8005902', '10000000-0000-0000-0000-000000805026', N'account');

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
    DECLARE @t26_rows int = (SELECT COUNT(*) FROM #Actual WHERE employer_account_number = N'T26');
    DECLARE @t25_rows int = (SELECT COUNT(*) FROM #Actual WHERE employer_account_number = N'T25' AND paid_members = 1);

    EXEC tSQLt.AssertEquals @Expected = 25, @Actual = @rows, @Message = N'Row count';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @t26_rows, @Message = N'T26 sorts last on the tie and its Unrecognised members do not count';
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @t25_rows, @Message = N'T25 is the 25th firm';
END;
GO

CREATE PROCEDURE test_MOD014_dev.[test top employers fail when no Campaign Year precedes the one covering the as-of date]
AS
BEGIN
    EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50014;

    -- 2024 is the first configured year, so a date in it has no last full year.
    EXEC Layercake.usp_report_top_employers @as_of_date = '2024-03-01';
END;
GO

CREATE PROCEDURE test_MOD014_dev.[test top employers fail when no Campaign Year covers the as-of date]
AS
BEGIN
    EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50014;

    EXEC Layercake.usp_report_top_employers @as_of_date = '2030-03-01';
END;
GO
