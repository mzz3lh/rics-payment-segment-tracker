EXEC tSQLt.NewTestClass 'test_MOD015_dev';
GO
CREATE PROCEDURE test_MOD015_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes';
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type';

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2024, '2023-10-01', '2024-09-30', '2024-09-30'),
           (2025, '2024-10-01', '2025-09-30', '2025-09-30'),
           (2026, '2025-10-01', '2026-09-30', '2026-09-30');

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code)
    VALUES (0, 'Unknown', NULL), (-1, 'Unrecognised', NULL), (-2, 'Not applicable', NULL),
           (1, 'Direct Debit', 'DD'), (2, 'Card', 'Card'), (5, 'Corporate', 'Corporate');

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name)
    VALUES (0, 'Unknown'), (1, 'Individual'), (2, 'Corporate');

    INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_name, item_code, is_full_concession, is_perpetual)
    VALUES (0, N'Unknown', NULL, 0, 0), (-2, N'Not applicable', NULL, 0, 0), (1, N'No concession', NULL, 0, 0);
END;
GO
CREATE PROCEDURE test_MOD015_dev.[test payment method coverage ignores the as-of date and leaves out events before 2021]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'D1', 2025, N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'D1', 2025, 2, 1, 1);

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, payment_method_id)
    VALUES (1, N'JR:D1', 'Join', 'Direct Entry', '2019-11-01', N'D1', 2020, -2),
           (2, N'RN:D1:2025', 'Renewal', 'Standard', '2024-10-10', N'D1', 2025, 2);

    CREATE TABLE #Actual1 (campaign_year int NULL, basis varchar(20) COLLATE DATABASE_DEFAULT NULL, total int NULL, with_method int NULL, coverage_pct decimal(5,1) NULL);
    CREATE TABLE #Actual2 (campaign_year int NULL, basis varchar(20) COLLATE DATABASE_DEFAULT NULL, total int NULL, with_method int NULL, coverage_pct decimal(5,1) NULL);
    INSERT INTO #Actual1 (campaign_year, basis, total, with_method, coverage_pct)
    EXEC Layercake.usp_report_payment_method_coverage @as_of_date = '2024-06-01';
    INSERT INTO #Actual2 (campaign_year, basis, total, with_method, coverage_pct)
    EXEC Layercake.usp_report_payment_method_coverage;

    SELECT campaign_year, basis, total, with_method, coverage_pct
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST('Paid position' AS varchar(20)), CAST(1 AS int), CAST(1 AS int), CAST(100.0 AS decimal(5,1))),
                 (2025, 'Renewal', 1, 1, 100.0)) AS v(campaign_year, basis, total, with_method, coverage_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual1';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual2';
END;
GO
CREATE PROCEDURE test_MOD015_dev.[test invoiced subtotal coverage counts an event with no amount_status in events but in no status column]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, payment_method_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1, N'RN:D1:2025', 'Renewal', 'Standard', '2024-10-10', N'D1', 2025, 1, 450.00, 450.00, 'Invoiced'),
           (2, N'RN:D2:2025', 'Renewal', 'Standard', '2024-10-10', N'D2', 2025, 1, NULL, NULL, NULL),
           (3, N'JR:D3', 'Join', 'Direct Entry', '2024-11-01', N'D3', 2025, 1, 0.00, 0.00, 'Full Concession');

    CREATE TABLE #Actual (campaign_year int NULL, events int NULL, with_invoiced_subtotal int NULL, coverage_pct decimal(5,1) NULL,
        before_invoice_data int NULL, no_invoice int NULL, counted_on_another_event int NULL, full_concession int NULL, fully_credited int NULL, invoiced int NULL);
    INSERT INTO #Actual (campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced)
    EXEC Layercake.usp_report_invoiced_subtotal_coverage;

    SELECT campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST(3 AS int), CAST(2 AS int), CAST(66.7 AS decimal(5,1)), CAST(0 AS int), CAST(0 AS int), CAST(0 AS int), CAST(1 AS int), CAST(0 AS int), CAST(1 AS int)))
         AS v(campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD015_dev.[test Direct Debit share with no Partially Paid positions returns the year with 0 0 and a NULL share]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'D1', 2025, N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'D1', 2025, 1, 1, 1);

    CREATE TABLE #Actual (campaign_year int NULL, partially_paid_positions int NULL, direct_debit_positions int NULL, direct_debit_share_pct decimal(5,1) NULL);
    INSERT INTO #Actual (campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct)
    EXEC Layercake.usp_report_direct_debit_share @as_of_date = '2025-06-15';

    SELECT campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST(0 AS int), CAST(0 AS int), CAST(NULL AS decimal(5,1)))) AS v(campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD015_dev.[test Direct Debit share counts a Partially Paid position with no attributes row as not Direct Debit]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'D1', 2025, N'Partially Paid'), (N'D2', 2025, N'Partially Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'D1', 2025, 1, 1, 1);

    CREATE TABLE #Actual (campaign_year int NULL, partially_paid_positions int NULL, direct_debit_positions int NULL, direct_debit_share_pct decimal(5,1) NULL);
    INSERT INTO #Actual (campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct)
    EXEC Layercake.usp_report_direct_debit_share @as_of_date = '2025-06-15';

    SELECT campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST(2 AS int), CAST(1 AS int), CAST(50.0 AS decimal(5,1)))) AS v(campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD015_dev.[test Direct Debit share fails with 50014 when no Campaign Year covers the as-of date]
AS
BEGIN
    EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50014;

    EXEC Layercake.usp_report_direct_debit_share @as_of_date = '2030-01-01';
END;
GO
CREATE PROCEDURE test_MOD015_dev.[test last full year totals fails with 50014 when the covering year has no earlier year]
AS
BEGIN
    EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50014;

    EXEC Layercake.usp_report_last_full_year_totals @as_of_date = '2024-03-01';
END;
GO
CREATE PROCEDURE test_MOD015_dev.[test last full year totals with no paid members and no events returns the four single measures]
AS
BEGIN
    CREATE TABLE #Actual (campaign_year int NULL, measure varchar(40) COLLATE DATABASE_DEFAULT NULL, category nvarchar(100) COLLATE DATABASE_DEFAULT NULL, value decimal(19,4) NULL);
    INSERT INTO #Actual (campaign_year, measure, category, value)
    EXEC Layercake.usp_report_last_full_year_totals @as_of_date = '2026-03-01';

    SELECT campaign_year, measure, category, value
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST('corporate_paid_members' AS varchar(40)), CAST(NULL AS nvarchar(100)), CAST(0 AS decimal(19,4))),
                 (2025, 'corporate_share_pct', NULL, NULL),
                 (2025, 'invoiced_subtotal_gbp_total', NULL, NULL),
                 (2025, 'subs_amount_gbp_total', NULL, NULL)) AS v(campaign_year, measure, category, value);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD015_dev.[test last full year totals lists reserved Not applicable and no attributes row as their own categories]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'D1', 2025, N'Fully Paid'), (N'D2', 2025, N'Fully Paid'), (N'D3', 2025, N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'D1', 2025, -2, 1, -2), (N'D2', 2025, 2, 2, 1);

    CREATE TABLE #Actual (campaign_year int NULL, measure varchar(40) COLLATE DATABASE_DEFAULT NULL, category nvarchar(100) COLLATE DATABASE_DEFAULT NULL, value decimal(19,4) NULL);
    INSERT INTO #Actual (campaign_year, measure, category, value)
    EXEC Layercake.usp_report_last_full_year_totals @as_of_date = '2026-03-01';

    SELECT campaign_year, measure, category, value
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST('paid_members_by_payment_method' AS varchar(40)), CAST(N'Not applicable' AS nvarchar(100)), CAST(1 AS decimal(19,4))),
                 (2025, 'paid_members_by_payment_method', N'Card', 1),
                 (2025, 'paid_members_by_payment_method', N'Unknown', 1),
                 (2025, 'corporate_paid_members', NULL, 1),
                 (2025, 'corporate_share_pct', NULL, 33.3),
                 (2025, 'invoiced_subtotal_gbp_total', NULL, NULL),
                 (2025, 'subs_amount_gbp_total', NULL, NULL),
                 (2025, 'paid_members_by_concession_type', N'Not applicable', 1),
                 (2025, 'paid_members_by_concession_type', N'No concession', 1),
                 (2025, 'paid_members_by_concession_type', N'Unknown', 1)) AS v(campaign_year, measure, category, value);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
