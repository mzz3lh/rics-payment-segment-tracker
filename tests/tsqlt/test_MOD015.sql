EXEC tSQLt.NewTestClass 'test_MOD015';
GO
CREATE PROCEDURE test_MOD015.[SetUp]
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
    VALUES (2020, '2019-10-01', '2020-09-30', '2020-09-30'),
           (2021, '2020-10-01', '2021-09-30', '2021-09-30'),
           (2022, '2021-10-01', '2022-09-30', '2022-09-30'),
           (2023, '2022-10-01', '2023-09-30', '2023-09-30'),
           (2024, '2023-10-01', '2024-09-30', '2024-09-30'),
           (2025, '2024-10-01', '2025-09-30', '2025-09-30'),
           (2026, '2025-10-01', '2026-09-30', '2026-09-30'),
           (2027, '2026-10-01', '2027-09-30', '2027-09-30');

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code)
    VALUES (0, 'Unknown', NULL), (-1, 'Unrecognised', NULL), (-2, 'Not applicable', NULL),
           (1, 'Direct Debit', 'DD'), (2, 'Card', 'Card'), (3, 'Bank transfer', 'Bank'),
           (4, 'Cheque', 'Cheque'), (5, 'Corporate', 'Corporate');

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name)
    VALUES (0, 'Unknown'), (-1, 'Unrecognised'), (-2, 'Not applicable'), (1, 'Individual'), (2, 'Corporate');

    INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_name, item_code, is_full_concession, is_perpetual)
    VALUES (0, N'Unknown', NULL, 0, 0), (-1, N'Unrecognised', NULL, 0, 0), (-2, N'Not applicable', NULL, 0, 0),
           (1, N'No concession', NULL, 0, 0), (5, N'Retired', N'CONRETIRED', 1, 1),
           (6, N'Exceptional Hardship', N'CONEXCEPTIONHP', 0, 0);
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-001 eight 2025 paid positions with six methods give coverage 75.0 and Change and Lapse get their own rows]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7150101', 2025, N'Fully Paid'), (N'7150102', 2025, N'Fully Paid'), (N'7150103', 2025, N'Fully Paid'),
           (N'7150104', 2025, N'Fully Paid'), (N'7150105', 2025, N'Fully Paid'), (N'7150106', 2025, N'Partially Paid'),
           (N'7150107', 2025, N'Fully Paid'), (N'7150108', 2025, N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7150101', 2025, 1, 1, 1), (N'7150102', 2025, 2, 1, 1), (N'7150103', 2025, 3, 1, 1),
           (N'7150104', 2025, 4, 1, 1), (N'7150105', 2025, 5, 2, 1), (N'7150106', 2025, 1, 1, 1),
           (N'7150107', 2025, 0, 1, 1), (N'7150108', 2025, -1, 1, 1);

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, payment_method_id)
    VALUES (10101, N'RN:7150101:2025', 'Renewal', 'Standard', '2024-10-10', N'7150101', 2025, 1),
           (10102, N'RN:7150102:2025', 'Renewal', 'Standard', '2024-10-10', N'7150102', 2025, 2),
           (10103, N'RN:7150103:2025', 'Renewal', 'Standard', '2024-10-10', N'7150103', 2025, 3),
           (10104, N'RN:7150104:2025', 'Renewal', 'Standard', '2024-10-10', N'7150104', 2025, 4),
           (10105, N'RN:7150105:2025', 'Renewal', 'Standard', '2024-10-10', N'7150105', 2025, 5),
           (10106, N'RN:7150106:2025', 'Renewal', 'Standard', '2024-10-10', N'7150106', 2025, 1),
           (10107, N'RN:7150107:2025', 'Renewal', 'Standard', '2024-10-10', N'7150107', 2025, 0),
           (10108, N'RN:7150108:2025', 'Renewal', 'Standard', '2024-10-10', N'7150108', 2025, -1),
           (10109, N'CH:7150102:2025', 'Change', 'Standard', '2025-03-01', N'7150102', 2025, 2),
           (10110, N'LP:7150107:2025', 'Lapse', 'Standard', '2025-06-30', N'7150107', 2025, 0);

    CREATE TABLE #Actual (campaign_year int NULL, basis varchar(20) COLLATE DATABASE_DEFAULT NULL, total int NULL, with_method int NULL, coverage_pct decimal(5,1) NULL);
    INSERT INTO #Actual (campaign_year, basis, total, with_method, coverage_pct)
    EXEC Layercake.usp_report_payment_method_coverage @as_of_date = '2026-03-01';

    SELECT campaign_year, basis, total, with_method, coverage_pct
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST('Paid position' AS varchar(20)), CAST(8 AS int), CAST(6 AS int), CAST(75.0 AS decimal(5,1))),
                 (2025, 'Renewal', 8, 6, 75.0),
                 (2025, 'Change', 1, 1, 100.0),
                 (2025, 'Lapse', 1, 0, 0.0)) AS v(campaign_year, basis, total, with_method, coverage_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-002 payment method coverage has one row per event type and rounds two in three to 66.7]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7150201', 2024, N'Fully Paid'), (N'7150202', 2024, N'Fully Paid'), (N'7150203', 2024, N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7150201', 2024, 1, 1, 1), (N'7150202', 2024, 1, 1, 1), (N'7150203', 2024, 0, 0, 1);

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, payment_method_id)
    VALUES (10201, N'JR:7150201', 'Join', 'Direct Entry', '2023-11-01', N'7150201', 2024, 1),
           (10202, N'RA:7150202:2024', 'Readmission', 'Standard', '2023-12-01', N'7150202', 2024, 1),
           (10203, N'RN:7150203:2024', 'Renewal', 'Standard', '2023-10-15', N'7150203', 2024, 0),
           (10204, N'CH:7150201:2024', 'Change', 'Standard', '2024-02-01', N'7150201', 2024, 1),
           (10205, N'CH:7150203:2024', 'Change', 'Standard', '2024-03-01', N'7150203', 2024, 0),
           (10206, N'LP:7150203:2024', 'Lapse', 'Standard', '2024-06-30', N'7150203', 2024, 0);

    CREATE TABLE #Actual (campaign_year int NULL, basis varchar(20) COLLATE DATABASE_DEFAULT NULL, total int NULL, with_method int NULL, coverage_pct decimal(5,1) NULL);
    INSERT INTO #Actual (campaign_year, basis, total, with_method, coverage_pct)
    EXEC Layercake.usp_report_payment_method_coverage @as_of_date = '2026-03-01';

    SELECT campaign_year, basis, total, with_method, coverage_pct
    INTO #Expected
    FROM (VALUES (CAST(2024 AS int), CAST('Paid position' AS varchar(20)), CAST(3 AS int), CAST(2 AS int), CAST(66.7 AS decimal(5,1))),
                 (2024, 'Join', 1, 1, 100.0),
                 (2024, 'Readmission', 1, 1, 100.0),
                 (2024, 'Renewal', 1, 0, 0.0),
                 (2024, 'Change', 2, 1, 50.0),
                 (2024, 'Lapse', 1, 0, 0.0)) AS v(campaign_year, basis, total, with_method, coverage_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-003 payment method coverage starts at 2021 and Not applicable is not covered]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7150301', 2020, N'Fully Paid'), (N'7150301', 2021, N'Fully Paid'), (N'7150301', 2022, N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7150301', 2020, -2, -2, -2), (N'7150301', 2021, -2, -2, -2), (N'7150301', 2022, 2, 1, 1);

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, payment_method_id)
    VALUES (10301, N'RN:7150301:2020', 'Renewal', 'Standard', '2019-10-15', N'7150301', 2020, -2),
           (10302, N'RN:7150301:2021', 'Renewal', 'Standard', '2020-10-15', N'7150301', 2021, -2),
           (10303, N'RN:7150301:2022', 'Renewal', 'Standard', '2021-10-15', N'7150301', 2022, 2);

    CREATE TABLE #Actual (campaign_year int NULL, basis varchar(20) COLLATE DATABASE_DEFAULT NULL, total int NULL, with_method int NULL, coverage_pct decimal(5,1) NULL);
    INSERT INTO #Actual (campaign_year, basis, total, with_method, coverage_pct)
    EXEC Layercake.usp_report_payment_method_coverage @as_of_date = '2026-03-01';

    SELECT campaign_year, basis, total, with_method, coverage_pct
    INTO #Expected
    FROM (VALUES (CAST(2021 AS int), CAST('Paid position' AS varchar(20)), CAST(1 AS int), CAST(0 AS int), CAST(0.0 AS decimal(5,1))),
                 (2021, 'Renewal', 1, 0, 0.0),
                 (2022, 'Paid position', 1, 1, 100.0),
                 (2022, 'Renewal', 1, 1, 100.0)) AS v(campaign_year, basis, total, with_method, coverage_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-004 a paid position with no attributes row is not covered and an attributes row with no paid position is not counted]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7150401', 2025, N'Fully Paid'), (N'7150402', 2025, N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7150401', 2025, 1, 1, 1), (N'7150401', 2024, 2, 1, 1), (N'7150403', 2025, 1, 1, 1);

    CREATE TABLE #Actual (campaign_year int NULL, basis varchar(20) COLLATE DATABASE_DEFAULT NULL, total int NULL, with_method int NULL, coverage_pct decimal(5,1) NULL);
    INSERT INTO #Actual (campaign_year, basis, total, with_method, coverage_pct)
    EXEC Layercake.usp_report_payment_method_coverage @as_of_date = '2026-03-01';

    SELECT campaign_year, basis, total, with_method, coverage_pct
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST('Paid position' AS varchar(20)), CAST(2 AS int), CAST(1 AS int), CAST(50.0 AS decimal(5,1)))) AS v(campaign_year, basis, total, with_method, coverage_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-005 ten 2025 events with nine invoiced subtotals give coverage 90.0 and amount_status counts]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, payment_method_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (10501, N'JR:7150501', 'Join', 'Direct Entry', '2024-11-01', N'7150501', 2025, 1, 450.00, 450.00, 'Invoiced'),
           (10502, N'RA:7150502:2025', 'Readmission', 'Standard', '2024-12-01', N'7150502', 2025, 1, 480.00, 480.00, 'Invoiced'),
           (10503, N'RN:7150503:2025', 'Renewal', 'Standard', '2024-10-10', N'7150503', 2025, 1, 450.00, 450.00, 'Invoiced'),
           (10504, N'RN:7150504:2025', 'Renewal', 'Standard', '2024-10-10', N'7150504', 2025, 2, 430.00, 430.00, 'Invoiced'),
           (10505, N'RN:7150505:2025', 'Renewal', 'Standard', '2024-10-10', N'7150505', 2025, 2, 450.00, 450.00, 'Invoiced'),
           (10506, N'RN:7150506:2025', 'Renewal', 'Standard', '2024-10-10', N'7150506', 2025, 5, 450.00, 450.00, 'Invoiced'),
           (10507, N'RN:7150507:2025', 'Renewal', 'Standard', '2024-10-10', N'7150507', 2025, 1, 0.00, 0.00, 'Full Concession'),
           (10508, N'RN:7150508:2025', 'Renewal', 'Standard', '2024-10-10', N'7150508', 2025, 1, 0.00, 0.00, 'Full Concession'),
           (10509, N'RN:7150509:2025', 'Renewal', 'Standard', '2024-10-10', N'7150509', 2025, 2, 0.00, 0.00, 'Fully credited'),
           (10510, N'RN:7150510:2025', 'Renewal', 'Standard', '2024-10-10', N'7150510', 2025, 0, NULL, NULL, 'No invoice');

    CREATE TABLE #Actual (campaign_year int NULL, events int NULL, with_invoiced_subtotal int NULL, coverage_pct decimal(5,1) NULL,
        before_invoice_data int NULL, no_invoice int NULL, counted_on_another_event int NULL, full_concession int NULL, fully_credited int NULL, invoiced int NULL);
    INSERT INTO #Actual (campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced)
    EXEC Layercake.usp_report_invoiced_subtotal_coverage @as_of_date = '2026-03-01';

    SELECT campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST(10 AS int), CAST(9 AS int), CAST(90.0 AS decimal(5,1)), CAST(0 AS int), CAST(1 AS int), CAST(0 AS int), CAST(2 AS int), CAST(1 AS int), CAST(6 AS int)))
         AS v(campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-006 invoiced subtotal coverage leaves out Change and Lapse and counts null amounts as not covered]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, payment_method_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (10601, N'RN:7150601:2024', 'Renewal', 'Standard', '2023-10-10', N'7150601', 2024, 1, 450.00, 450.00, 'Invoiced'),
           (10602, N'RA:7150601:2024', 'Readmission', 'Standard', '2024-05-10', N'7150601', 2024, 1, NULL, NULL, 'Counted on another event'),
           (10603, N'CH:7150601:2024', 'Change', 'Standard', '2024-02-01', N'7150601', 2024, 1, NULL, NULL, NULL),
           (10604, N'LP:7150602:2024', 'Lapse', 'Standard', '2024-06-30', N'7150602', 2024, 0, NULL, NULL, NULL),
           (10605, N'RN:7150603:2021', 'Renewal', 'Standard', '2020-10-10', N'7150603', 2021, -2, NULL, NULL, 'Before invoice data'),
           (10606, N'CH:7150604:2023', 'Change', 'Standard', '2023-02-01', N'7150604', 2023, 2, NULL, NULL, NULL);

    CREATE TABLE #Actual (campaign_year int NULL, events int NULL, with_invoiced_subtotal int NULL, coverage_pct decimal(5,1) NULL,
        before_invoice_data int NULL, no_invoice int NULL, counted_on_another_event int NULL, full_concession int NULL, fully_credited int NULL, invoiced int NULL);
    INSERT INTO #Actual (campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced)
    EXEC Layercake.usp_report_invoiced_subtotal_coverage @as_of_date = '2026-03-01';

    SELECT campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced
    INTO #Expected
    FROM (VALUES (CAST(2021 AS int), CAST(1 AS int), CAST(0 AS int), CAST(0.0 AS decimal(5,1)), CAST(1 AS int), CAST(0 AS int), CAST(0 AS int), CAST(0 AS int), CAST(0 AS int), CAST(0 AS int)),
                 (2024, 2, 1, 50.0, 0, 0, 1, 0, 0, 1))
         AS v(campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-007 four current year Partially Paid positions three of them Direct Debit give share 75.0]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7150701', 2025, N'Partially Paid'), (N'7150702', 2025, N'Partially Paid'),
           (N'7150703', 2025, N'Partially Paid'), (N'7150704', 2025, N'Partially Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7150701', 2025, 1, 1, 1), (N'7150702', 2025, 1, 1, 1), (N'7150703', 2025, 1, 1, 1), (N'7150704', 2025, 2, 1, 1);

    CREATE TABLE #Actual (campaign_year int NULL, partially_paid_positions int NULL, direct_debit_positions int NULL, direct_debit_share_pct decimal(5,1) NULL);
    INSERT INTO #Actual (campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct)
    EXEC Layercake.usp_report_direct_debit_share @as_of_date = '2025-06-15';

    SELECT campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST(4 AS int), CAST(3 AS int), CAST(75.0 AS decimal(5,1)))) AS v(campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-008 Direct Debit share counts only current year Partially Paid positions]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7150801', 2025, N'Partially Paid'), (N'7150802', 2025, N'Partially Paid'), (N'7150803', 2025, N'Partially Paid'),
           (N'7150804', 2025, N'Fully Paid'), (N'7150805', 2025, N'Pre-Subs Payment'), (N'7150806', 2025, N'Full Concession'),
           (N'7150807', 2024, N'Partially Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7150801', 2025, 1, 1, 1), (N'7150802', 2025, 2, 1, 1),
           (N'7150804', 2025, 1, 1, 1), (N'7150805', 2025, 1, 1, 1), (N'7150806', 2025, 1, 1, 5),
           (N'7150807', 2024, 1, 1, 1), (N'7150808', 2025, 1, 1, 1);

    CREATE TABLE #Actual (campaign_year int NULL, partially_paid_positions int NULL, direct_debit_positions int NULL, direct_debit_share_pct decimal(5,1) NULL);
    INSERT INTO #Actual (campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct)
    EXEC Layercake.usp_report_direct_debit_share @as_of_date = '2025-06-15';

    SELECT campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST(3 AS int), CAST(1 AS int), CAST(33.3 AS decimal(5,1)))) AS v(campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-009 the current Campaign Year for the Direct Debit share is the year covering the as-of date]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7150901', 2025, N'Partially Paid'), (N'7150902', 2025, N'Partially Paid'),
           (N'7150903', 2026, N'Partially Paid'), (N'7150904', 2026, N'Partially Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7150901', 2025, 1, 1, 1), (N'7150902', 2025, 1, 1, 1), (N'7150903', 2026, 1, 1, 1), (N'7150904', 2026, 4, 1, 1);

    CREATE TABLE #Actual1 (campaign_year int NULL, partially_paid_positions int NULL, direct_debit_positions int NULL, direct_debit_share_pct decimal(5,1) NULL);
    INSERT INTO #Actual1 (campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct)
    EXEC Layercake.usp_report_direct_debit_share @as_of_date = '2025-09-30';

    CREATE TABLE #Actual2 (campaign_year int NULL, partially_paid_positions int NULL, direct_debit_positions int NULL, direct_debit_share_pct decimal(5,1) NULL);
    INSERT INTO #Actual2 (campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct)
    EXEC Layercake.usp_report_direct_debit_share @as_of_date = '2025-10-01';

    SELECT campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct
    INTO #Expected1
    FROM (VALUES (CAST(2025 AS int), CAST(2 AS int), CAST(2 AS int), CAST(100.0 AS decimal(5,1)))) AS v(campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct);

    SELECT campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct
    INTO #Expected2
    FROM (VALUES (CAST(2026 AS int), CAST(2 AS int), CAST(1 AS int), CAST(50.0 AS decimal(5,1)))) AS v(campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected1', '#Actual1';
    EXEC tSQLt.AssertEqualsTable '#Expected2', '#Actual2';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-010 one hundred last full year paid members with sixteen Corporate give count 16 and share 16.0]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    SELECT CONCAT(N'71510', RIGHT(CONCAT('000', n.n), 3)), 2025, N'Fully Paid'
    FROM (SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY o.object_id) AS n FROM sys.all_objects AS o) AS n;

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    SELECT CONCAT(N'71510', RIGHT(CONCAT('000', n.n), 3)), 2025,
           CASE WHEN n.n <= 16 THEN 5 ELSE 1 END,
           CASE WHEN n.n <= 16 THEN 2 ELSE 1 END,
           1
    FROM (SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY o.object_id) AS n FROM sys.all_objects AS o) AS n;

    CREATE TABLE #Actual (campaign_year int NULL, measure varchar(40) COLLATE DATABASE_DEFAULT NULL, category nvarchar(100) COLLATE DATABASE_DEFAULT NULL, value decimal(19,4) NULL);
    INSERT INTO #Actual (campaign_year, measure, category, value)
    EXEC Layercake.usp_report_last_full_year_totals @as_of_date = '2026-03-01';

    SELECT campaign_year, measure, category, value
    INTO #ActualSel
    FROM #Actual
    WHERE measure IN ('corporate_paid_members', 'corporate_share_pct', 'paid_members_by_payment_method');

    SELECT campaign_year, measure, category, value
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST('corporate_paid_members' AS varchar(40)), CAST(NULL AS nvarchar(100)), CAST(16 AS decimal(19,4))),
                 (2025, 'corporate_share_pct', NULL, 16.0),
                 (2025, 'paid_members_by_payment_method', N'Corporate', 16),
                 (2025, 'paid_members_by_payment_method', N'Direct Debit', 84)) AS v(campaign_year, measure, category, value);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSel';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-011 corporate count uses payer type and only last full year paid positions]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7151101', 2025, N'Fully Paid'), (N'7151102', 2025, N'Fully Paid'), (N'7151103', 2025, N'Fully Paid'),
           (N'7151104', 2025, N'Fully Paid'), (N'7151105', 2024, N'Fully Paid'), (N'7151106', 2026, N'Partially Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7151101', 2025, 5, 2, 1), (N'7151102', 2025, 1, 2, 1), (N'7151103', 2025, 5, 1, 1),
           (N'7151104', 2025, 0, 0, 1), (N'7151105', 2024, 5, 2, 1), (N'7151106', 2026, 5, 2, 1),
           (N'7151107', 2025, 5, 2, 1);

    CREATE TABLE #Actual (campaign_year int NULL, measure varchar(40) COLLATE DATABASE_DEFAULT NULL, category nvarchar(100) COLLATE DATABASE_DEFAULT NULL, value decimal(19,4) NULL);
    INSERT INTO #Actual (campaign_year, measure, category, value)
    EXEC Layercake.usp_report_last_full_year_totals @as_of_date = '2026-03-01';

    SELECT campaign_year, measure, category, value
    INTO #ActualSel
    FROM #Actual
    WHERE measure IN ('corporate_paid_members', 'corporate_share_pct', 'paid_members_by_payment_method');

    SELECT campaign_year, measure, category, value
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST('corporate_paid_members' AS varchar(40)), CAST(NULL AS nvarchar(100)), CAST(2 AS decimal(19,4))),
                 (2025, 'corporate_share_pct', NULL, 50.0),
                 (2025, 'paid_members_by_payment_method', N'Corporate', 2),
                 (2025, 'paid_members_by_payment_method', N'Direct Debit', 1),
                 (2025, 'paid_members_by_payment_method', N'Unknown', 1)) AS v(campaign_year, measure, category, value);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSel';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-012 the last full Campaign Year is the year before the one covering the as-of date]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7151201', 2024, N'Fully Paid'), (N'7151202', 2024, N'Fully Paid'),
           (N'7151203', 2025, N'Fully Paid'), (N'7151204', 2025, N'Fully Paid'), (N'7151205', 2025, N'Fully Paid'), (N'7151206', 2025, N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7151201', 2024, 5, 2, 1), (N'7151202', 2024, 1, 1, 1),
           (N'7151203', 2025, 5, 2, 1), (N'7151204', 2025, 1, 1, 1), (N'7151205', 2025, 1, 1, 1), (N'7151206', 2025, 1, 1, 1);

    CREATE TABLE #Actual1 (campaign_year int NULL, measure varchar(40) COLLATE DATABASE_DEFAULT NULL, category nvarchar(100) COLLATE DATABASE_DEFAULT NULL, value decimal(19,4) NULL);
    INSERT INTO #Actual1 (campaign_year, measure, category, value)
    EXEC Layercake.usp_report_last_full_year_totals @as_of_date = '2025-09-30';

    CREATE TABLE #Actual2 (campaign_year int NULL, measure varchar(40) COLLATE DATABASE_DEFAULT NULL, category nvarchar(100) COLLATE DATABASE_DEFAULT NULL, value decimal(19,4) NULL);
    INSERT INTO #Actual2 (campaign_year, measure, category, value)
    EXEC Layercake.usp_report_last_full_year_totals @as_of_date = '2025-10-01';

    SELECT campaign_year, measure, category, value INTO #Sel1 FROM #Actual1 WHERE measure IN ('corporate_paid_members', 'corporate_share_pct');
    SELECT campaign_year, measure, category, value INTO #Sel2 FROM #Actual2 WHERE measure IN ('corporate_paid_members', 'corporate_share_pct');

    SELECT campaign_year, measure, category, value
    INTO #Expected1
    FROM (VALUES (CAST(2024 AS int), CAST('corporate_paid_members' AS varchar(40)), CAST(NULL AS nvarchar(100)), CAST(1 AS decimal(19,4))),
                 (2024, 'corporate_share_pct', NULL, 50.0)) AS v(campaign_year, measure, category, value);

    SELECT campaign_year, measure, category, value
    INTO #Expected2
    FROM (VALUES (CAST(2025 AS int), CAST('corporate_paid_members' AS varchar(40)), CAST(NULL AS nvarchar(100)), CAST(1 AS decimal(19,4))),
                 (2025, 'corporate_share_pct', NULL, 25.0)) AS v(campaign_year, measure, category, value);

    EXEC tSQLt.AssertEqualsTable '#Expected1', '#Sel1';
    EXEC tSQLt.AssertEqualsTable '#Expected2', '#Sel2';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-013 last full year Renewals of 450.00 450.00 and 430.00 total 1330.00 for both amount columns]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7151301', 2025, N'Fully Paid'), (N'7151302', 2025, N'Fully Paid'), (N'7151303', 2025, N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7151301', 2025, 1, 1, 1), (N'7151302', 2025, 1, 1, 1), (N'7151303', 2025, 2, 1, 1);

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, payment_method_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (11301, N'RN:7151301:2025', 'Renewal', 'Standard', '2024-10-10', N'7151301', 2025, 1, 450.00, 450.00, 'Invoiced'),
           (11302, N'RN:7151302:2025', 'Renewal', 'Standard', '2024-10-12', N'7151302', 2025, 1, 450.00, 450.00, 'Invoiced'),
           (11303, N'RN:7151303:2025', 'Renewal', 'Standard', '2024-10-20', N'7151303', 2025, 2, 430.00, 430.00, 'Invoiced');

    CREATE TABLE #Actual (campaign_year int NULL, measure varchar(40) COLLATE DATABASE_DEFAULT NULL, category nvarchar(100) COLLATE DATABASE_DEFAULT NULL, value decimal(19,4) NULL);
    INSERT INTO #Actual (campaign_year, measure, category, value)
    EXEC Layercake.usp_report_last_full_year_totals @as_of_date = '2026-03-01';

    SELECT campaign_year, measure, category, value
    INTO #ActualSel
    FROM #Actual
    WHERE measure IN ('invoiced_subtotal_gbp_total', 'subs_amount_gbp_total');

    SELECT campaign_year, measure, category, value
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST('invoiced_subtotal_gbp_total' AS varchar(40)), CAST(NULL AS nvarchar(100)), CAST(1330.00 AS decimal(19,4))),
                 (2025, 'subs_amount_gbp_total', NULL, 1330.00)) AS v(campaign_year, measure, category, value);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSel';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-014 amount totals sum each column over last full year join renewal and readmission events only]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7151401', 2025, N'Fully Paid'), (N'7151402', 2025, N'Fully Paid'), (N'7151403', 2025, N'Full Concession');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7151401', 2025, 1, 1, 1), (N'7151402', 2025, 2, 1, 1), (N'7151403', 2025, 1, 1, 5);

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, payment_method_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (11401, N'JR:7151401', 'Join', 'Direct Entry', '2024-11-01', N'7151401', 2025, 1, 180.00, 200.00, 'Invoiced'),
           (11402, N'RA:7151402:2025', 'Readmission', 'Standard', '2024-12-01', N'7151402', 2025, 2, 300.00, 300.00, 'Invoiced'),
           (11403, N'RN:7151402:2025', 'Renewal', 'Standard', '2024-10-10', N'7151402', 2025, 2, NULL, NULL, 'Counted on another event'),
           (11404, N'RN:7151403:2025', 'Renewal', 'Standard', '2024-10-15', N'7151403', 2025, 1, 0.00, 0.00, 'Full Concession'),
           (11405, N'CH:7151401:2025', 'Change', 'Standard', '2025-02-01', N'7151401', 2025, 1, NULL, NULL, NULL),
           (11406, N'RN:7151404:2024', 'Renewal', 'Standard', '2023-10-10', N'7151404', 2024, 1, 999.00, 999.00, 'Invoiced'),
           (11407, N'RN:7151405:2026', 'Renewal', 'Standard', '2025-10-10', N'7151405', 2026, 1, 888.00, 888.00, 'Invoiced');

    CREATE TABLE #Actual (campaign_year int NULL, measure varchar(40) COLLATE DATABASE_DEFAULT NULL, category nvarchar(100) COLLATE DATABASE_DEFAULT NULL, value decimal(19,4) NULL);
    INSERT INTO #Actual (campaign_year, measure, category, value)
    EXEC Layercake.usp_report_last_full_year_totals @as_of_date = '2026-03-01';

    SELECT campaign_year, measure, category, value
    INTO #ActualSel
    FROM #Actual
    WHERE measure IN ('invoiced_subtotal_gbp_total', 'subs_amount_gbp_total');

    SELECT campaign_year, measure, category, value
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST('invoiced_subtotal_gbp_total' AS varchar(40)), CAST(NULL AS nvarchar(100)), CAST(500.00 AS decimal(19,4))),
                 (2025, 'subs_amount_gbp_total', NULL, 480.00)) AS v(campaign_year, measure, category, value);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSel';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-015 last full year paid members are counted by concession type with no attributes row as Unknown]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7151501', 2025, N'Fully Paid'), (N'7151502', 2025, N'Fully Paid'), (N'7151503', 2025, N'Fully Paid'),
           (N'7151504', 2025, N'Full Concession'), (N'7151505', 2025, N'Full Concession'), (N'7151506', 2025, N'Fully Paid'),
           (N'7151507', 2025, N'Fully Paid'), (N'7151508', 2024, N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7151501', 2025, 1, 1, 1), (N'7151502', 2025, 1, 1, 1), (N'7151503', 2025, 2, 1, 1),
           (N'7151504', 2025, 1, 1, 5), (N'7151505', 2025, 1, 1, 5), (N'7151506', 2025, 1, 1, 6),
           (N'7151508', 2024, 1, 1, 6);

    CREATE TABLE #Actual (campaign_year int NULL, measure varchar(40) COLLATE DATABASE_DEFAULT NULL, category nvarchar(100) COLLATE DATABASE_DEFAULT NULL, value decimal(19,4) NULL);
    INSERT INTO #Actual (campaign_year, measure, category, value)
    EXEC Layercake.usp_report_last_full_year_totals @as_of_date = '2026-03-01';

    SELECT campaign_year, measure, category, value
    INTO #ActualSel
    FROM #Actual
    WHERE measure = 'paid_members_by_concession_type';

    SELECT campaign_year, measure, category, value
    INTO #Expected
    FROM (VALUES (CAST(2025 AS int), CAST('paid_members_by_concession_type' AS varchar(40)), CAST(N'No concession' AS nvarchar(100)), CAST(3 AS decimal(19,4))),
                 (2025, 'paid_members_by_concession_type', N'Retired', 2),
                 (2025, 'paid_members_by_concession_type', N'Exceptional Hardship', 1),
                 (2025, 'paid_members_by_concession_type', N'Unknown', 1)) AS v(campaign_year, measure, category, value);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSel';
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-016 the four reports return only their aggregate columns and no contact number]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7151601', 2025, N'Fully Paid'), (N'7151602', 2025, N'Fully Paid'), (N'7151602', 2026, N'Partially Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7151601', 2025, 5, 2, 1), (N'7151602', 2025, 1, 1, 1), (N'7151602', 2026, 1, 1, 1);

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, payment_method_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (11601, N'RN:7151601:2025', 'Renewal', 'Standard', '2024-10-10', N'7151601', 2025, 5, 450.00, 450.00, 'Invoiced'),
           (11602, N'RN:7151602:2025', 'Renewal', 'Standard', '2024-10-11', N'7151602', 2025, 1, 380.00, 380.00, 'Invoiced');

    CREATE TABLE #Pm (campaign_year int NULL, basis varchar(20) COLLATE DATABASE_DEFAULT NULL, total int NULL, with_method int NULL, coverage_pct decimal(5,1) NULL);
    INSERT INTO #Pm (campaign_year, basis, total, with_method, coverage_pct)
    EXEC Layercake.usp_report_payment_method_coverage @as_of_date = '2026-03-01';

    CREATE TABLE #Inv (campaign_year int NULL, events int NULL, with_invoiced_subtotal int NULL, coverage_pct decimal(5,1) NULL,
        before_invoice_data int NULL, no_invoice int NULL, counted_on_another_event int NULL, full_concession int NULL, fully_credited int NULL, invoiced int NULL);
    INSERT INTO #Inv (campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced)
    EXEC Layercake.usp_report_invoiced_subtotal_coverage @as_of_date = '2026-03-01';

    CREATE TABLE #Dd (campaign_year int NULL, partially_paid_positions int NULL, direct_debit_positions int NULL, direct_debit_share_pct decimal(5,1) NULL);
    INSERT INTO #Dd (campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct)
    EXEC Layercake.usp_report_direct_debit_share @as_of_date = '2026-03-01';

    CREATE TABLE #Tot (campaign_year int NULL, measure varchar(40) COLLATE DATABASE_DEFAULT NULL, category nvarchar(100) COLLATE DATABASE_DEFAULT NULL, value decimal(19,4) NULL);
    INSERT INTO #Tot (campaign_year, measure, category, value)
    EXEC Layercake.usp_report_last_full_year_totals @as_of_date = '2026-03-01';

    SELECT campaign_year, basis, total, with_method, coverage_pct
    INTO #ExpPm
    FROM (VALUES (CAST(2025 AS int), CAST('Paid position' AS varchar(20)), CAST(2 AS int), CAST(2 AS int), CAST(100.0 AS decimal(5,1))),
                 (2025, 'Renewal', 2, 2, 100.0),
                 (2026, 'Paid position', 1, 1, 100.0)) AS v(campaign_year, basis, total, with_method, coverage_pct);

    SELECT campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced
    INTO #ExpInv
    FROM (VALUES (CAST(2025 AS int), CAST(2 AS int), CAST(2 AS int), CAST(100.0 AS decimal(5,1)), CAST(0 AS int), CAST(0 AS int), CAST(0 AS int), CAST(0 AS int), CAST(0 AS int), CAST(2 AS int)))
         AS v(campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced);

    SELECT campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct
    INTO #ExpDd
    FROM (VALUES (CAST(2026 AS int), CAST(1 AS int), CAST(1 AS int), CAST(100.0 AS decimal(5,1)))) AS v(campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct);

    SELECT campaign_year, measure, category, value
    INTO #ExpTot
    FROM (VALUES (CAST(2025 AS int), CAST('paid_members_by_payment_method' AS varchar(40)), CAST(N'Corporate' AS nvarchar(100)), CAST(1 AS decimal(19,4))),
                 (2025, 'paid_members_by_payment_method', N'Direct Debit', 1),
                 (2025, 'corporate_paid_members', NULL, 1),
                 (2025, 'corporate_share_pct', NULL, 50.0),
                 (2025, 'invoiced_subtotal_gbp_total', NULL, 830.00),
                 (2025, 'subs_amount_gbp_total', NULL, 830.00),
                 (2025, 'paid_members_by_concession_type', N'No concession', 2)) AS v(campaign_year, measure, category, value);

    EXEC tSQLt.AssertEqualsTable '#ExpPm', '#Pm';
    EXEC tSQLt.AssertEqualsTable '#ExpInv', '#Inv';
    EXEC tSQLt.AssertEqualsTable '#ExpDd', '#Dd';
    EXEC tSQLt.AssertEqualsTable '#ExpTot', '#Tot';

    DECLARE @contact_values int =
        (SELECT COUNT(*) FROM #Pm WHERE basis IN (N'7151601', N'7151602'))
      + (SELECT COUNT(*) FROM #Tot WHERE measure IN (N'7151601', N'7151602') OR category IN (N'7151601', N'7151602'));
    EXEC tSQLt.AssertEquals 0, @contact_values;
END;
GO
CREATE PROCEDURE test_MOD015.[test TC-015-017 running the reports twice returns the same results and changes no table]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7151701', 2025, N'Partially Paid'), (N'7151702', 2025, N'Fully Paid'), (N'7151702', 2026, N'Partially Paid');

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payer_type_id, concession_type_id)
    VALUES (N'7151701', 2025, 1, 1, 1), (N'7151702', 2025, 5, 2, 5), (N'7151702', 2026, 1, 1, 1);

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, payment_method_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (11701, N'RN:7151701:2025', 'Renewal', 'Standard', '2024-10-10', N'7151701', 2025, 1, 450.00, 450.00, 'Invoiced'),
           (11702, N'RN:7151702:2025', 'Renewal', 'Standard', '2024-10-11', N'7151702', 2025, 5, 0.00, 0.00, 'Full Concession'),
           (11703, N'LP:7151701:2026', 'Lapse', 'Standard', '2026-01-31', N'7151701', 2026, 1, NULL, NULL, NULL);

    SELECT * INTO #PeBefore FROM Layercake.silv_payment_events;
    SELECT * INTO #AtBefore FROM Layercake.silv_member_year_attributes;
    SELECT * INTO #EvBefore FROM Layercake.silv_membership_events;

    CREATE TABLE #Pm1 (campaign_year int NULL, basis varchar(20) COLLATE DATABASE_DEFAULT NULL, total int NULL, with_method int NULL, coverage_pct decimal(5,1) NULL);
    CREATE TABLE #Pm2 (campaign_year int NULL, basis varchar(20) COLLATE DATABASE_DEFAULT NULL, total int NULL, with_method int NULL, coverage_pct decimal(5,1) NULL);
    INSERT INTO #Pm1 (campaign_year, basis, total, with_method, coverage_pct) EXEC Layercake.usp_report_payment_method_coverage @as_of_date = '2026-03-01';
    INSERT INTO #Pm2 (campaign_year, basis, total, with_method, coverage_pct) EXEC Layercake.usp_report_payment_method_coverage @as_of_date = '2026-03-01';

    CREATE TABLE #Inv1 (campaign_year int NULL, events int NULL, with_invoiced_subtotal int NULL, coverage_pct decimal(5,1) NULL,
        before_invoice_data int NULL, no_invoice int NULL, counted_on_another_event int NULL, full_concession int NULL, fully_credited int NULL, invoiced int NULL);
    CREATE TABLE #Inv2 (campaign_year int NULL, events int NULL, with_invoiced_subtotal int NULL, coverage_pct decimal(5,1) NULL,
        before_invoice_data int NULL, no_invoice int NULL, counted_on_another_event int NULL, full_concession int NULL, fully_credited int NULL, invoiced int NULL);
    INSERT INTO #Inv1 (campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced)
    EXEC Layercake.usp_report_invoiced_subtotal_coverage @as_of_date = '2026-03-01';
    INSERT INTO #Inv2 (campaign_year, events, with_invoiced_subtotal, coverage_pct, before_invoice_data, no_invoice, counted_on_another_event, full_concession, fully_credited, invoiced)
    EXEC Layercake.usp_report_invoiced_subtotal_coverage @as_of_date = '2026-03-01';

    CREATE TABLE #Dd1 (campaign_year int NULL, partially_paid_positions int NULL, direct_debit_positions int NULL, direct_debit_share_pct decimal(5,1) NULL);
    CREATE TABLE #Dd2 (campaign_year int NULL, partially_paid_positions int NULL, direct_debit_positions int NULL, direct_debit_share_pct decimal(5,1) NULL);
    INSERT INTO #Dd1 (campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct) EXEC Layercake.usp_report_direct_debit_share @as_of_date = '2026-03-01';
    INSERT INTO #Dd2 (campaign_year, partially_paid_positions, direct_debit_positions, direct_debit_share_pct) EXEC Layercake.usp_report_direct_debit_share @as_of_date = '2026-03-01';

    CREATE TABLE #Tot1 (campaign_year int NULL, measure varchar(40) COLLATE DATABASE_DEFAULT NULL, category nvarchar(100) COLLATE DATABASE_DEFAULT NULL, value decimal(19,4) NULL);
    CREATE TABLE #Tot2 (campaign_year int NULL, measure varchar(40) COLLATE DATABASE_DEFAULT NULL, category nvarchar(100) COLLATE DATABASE_DEFAULT NULL, value decimal(19,4) NULL);
    INSERT INTO #Tot1 (campaign_year, measure, category, value) EXEC Layercake.usp_report_last_full_year_totals @as_of_date = '2026-03-01';
    INSERT INTO #Tot2 (campaign_year, measure, category, value) EXEC Layercake.usp_report_last_full_year_totals @as_of_date = '2026-03-01';

    SELECT * INTO #PeAfter FROM Layercake.silv_payment_events;
    SELECT * INTO #AtAfter FROM Layercake.silv_member_year_attributes;
    SELECT * INTO #EvAfter FROM Layercake.silv_membership_events;

    DECLARE @pm_rows int = (SELECT COUNT(*) FROM #Pm1);
    DECLARE @inv_rows int = (SELECT COUNT(*) FROM #Inv1);
    DECLARE @dd_rows int = (SELECT COUNT(*) FROM #Dd1);
    DECLARE @tot_rows int = (SELECT COUNT(*) FROM #Tot1);
    EXEC tSQLt.AssertEquals 4, @pm_rows;
    EXEC tSQLt.AssertEquals 1, @inv_rows;
    EXEC tSQLt.AssertEquals 1, @dd_rows;
    EXEC tSQLt.AssertEquals 8, @tot_rows;
    EXEC tSQLt.AssertEqualsTable '#Pm1', '#Pm2';
    EXEC tSQLt.AssertEqualsTable '#Inv1', '#Inv2';
    EXEC tSQLt.AssertEqualsTable '#Dd1', '#Dd2';
    EXEC tSQLt.AssertEqualsTable '#Tot1', '#Tot2';
    EXEC tSQLt.AssertEqualsTable '#PeBefore', '#PeAfter';
    EXEC tSQLt.AssertEqualsTable '#AtBefore', '#AtAfter';
    EXEC tSQLt.AssertEqualsTable '#EvBefore', '#EvAfter';
END;
GO
