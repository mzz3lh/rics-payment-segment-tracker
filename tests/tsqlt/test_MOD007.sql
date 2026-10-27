EXEC tSQLt.NewTestClass 'test_MOD007';
GO

CREATE PROCEDURE test_MOD007.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_invoice_line_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2019, '2019-01-01', '2019-12-31', '2019-12-31'),
           (2020, '2020-01-01', '2020-12-31', '2020-12-31'),
           (2021, '2021-01-01', '2021-12-31', '2021-12-31'),
           (2022, '2022-01-01', '2022-12-31', '2022-12-31'),
           (2023, '2023-01-01', '2023-12-31', '2023-12-31'),
           (2024, '2024-01-01', '2024-12-31', '2024-12-31'),
           (2025, '2025-01-01', '2025-12-31', '2025-12-31'),
           (2026, '2026-01-01', '2026-12-31', '2026-12-31'),
           (2027, '2027-01-01', '2027-12-31', '2027-12-31');

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (0, 'Unknown', NULL, '2026-01-01', '2026-01-01'),
           (-1, 'Unrecognised', NULL, '2026-01-01', '2026-01-01'),
           (-2, 'Not applicable', NULL, '2026-01-01', '2026-01-01'),
           (1, 'Direct Debit', 'DD', '2026-01-01', '2026-01-01'),
           (2, 'Card', 'Card', '2026-01-01', '2026-01-01'),
           (3, 'Bank transfer', 'Bank', '2026-01-01', '2026-01-01'),
           (4, 'Cheque', 'Cheque', '2026-01-01', '2026-01-01'),
           (5, 'Corporate', 'Corporate', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name, created_at, updated_at)
    VALUES (0, 'Unknown', '2026-01-01', '2026-01-01'),
           (-1, 'Unrecognised', '2026-01-01', '2026-01-01'),
           (-2, 'Not applicable', '2026-01-01', '2026-01-01'),
           (1, 'Individual', '2026-01-01', '2026-01-01'),
           (2, 'Corporate', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _is_deleted)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, 0),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, 0);

    INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (-2, NULL, N'Not applicable', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (1, NULL, N'No concession', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (5, 'A0000000-0000-0000-0000-000000000001', N'Retired', N'CONRETIRED', 1, 1, 3, '2026-01-01', '2026-01-01'),
           (6, 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', N'CONEXCEPTIONHP', 0, 0, 3, '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id, created_at, updated_at)
    VALUES (N'SUBS_MRICS', N'SUB', 'subscription', NULL, '2026-01-01', '2026-01-01'),
           (N'CONRETIRED', N'SUB', 'concession', NULL, '2026-01-01', '2026-01-01'),
           (N'CONEXCEPTIONHP', N'SUB', 'concession', NULL, '2026-01-01', '2026-01-01'),
           (N'ENROLFEE', N'APP', 'enrolment or application fee', NULL, '2026-01-01', '2026-01-01'),
           (N'ENROLFEE', N'', 'enrolment or application fee', NULL, '2026-01-01', '2026-01-01'),
           (N'VATUK', N'TAX', 'tax', NULL, '2026-01-01', '2026-01-01');
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-001 one row per contact year from first event to current year]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000101', 'Join', 'Join', '2023-03-01', N'7000101', 2023, 'Q1'),
           (2, N'R-7000101-2024', 'Renewal', 'Renewal', '2024-01-15', N'7000101', 2024, 'Q1'),
           (3, N'R-7000101-2025', 'Renewal', 'Renewal', '2025-01-12', N'7000101', 2025, 'Q1'),
           (4, N'C-7000101-2025', 'Change', 'Change', '2025-02-10', N'7000101', 2025, 'Q1');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';

    SELECT contact_no, campaign_year
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year
    INTO #Expected
    FROM (VALUES (N'7000101', 2023), (N'7000101', 2024), (N'7000101', 2025), (N'7000101', 2026)) AS v(contact_no, campaign_year);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-002 as-of date on campaign year end and first event after current year]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000101', 'Join', 'Join', '2023-03-01', N'7000101', 2023, 'Q1'),
           (2, N'R-7000101-2024', 'Renewal', 'Renewal', '2024-01-15', N'7000101', 2024, 'Q1'),
           (3, N'J-7000103', 'Join', 'Join', '2025-04-01', N'7000103', 2025, 'Q2'),
           (4, N'J-7000102', 'Join', 'Join', '2026-01-05', N'7000102', 2026, 'Q1');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-12-31';

    SELECT contact_no, campaign_year
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year
    INTO #Expected
    FROM (VALUES (N'7000101', 2023), (N'7000101', 2024), (N'7000101', 2025), (N'7000103', 2025)) AS v(contact_no, campaign_year);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-003 as-of date on campaign year start makes that year current]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000104', 'Join', 'Join', '2025-03-01', N'7000104', 2025, 'Q1');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-01-01';

    SELECT contact_no, campaign_year
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year
    INTO #Expected
    FROM (VALUES (N'7000104', 2025), (N'7000104', 2026)) AS v(contact_no, campaign_year);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD007.[test TC-007-004 as-of date outside every campaign year fails and changes nothing]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000101', 'Join', 'Join', '2025-03-01', N'7000101', 2025, 'Q1'),
           (2, N'J-7000107', 'Join', 'Join', '2024-03-01', N'7000107', 2024, 'Q1');

    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'7000101', 2025, 2, 0, 1, 0, NULL, 1, 0, 99001, 7, '2020-01-01', '2020-01-01');

    SELECT * INTO #Before FROM Layercake.silv_member_year_attributes;

    DECLARE @raised bit = 0;
    BEGIN TRY
        EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2030-01-15';
    END TRY
    BEGIN CATCH
        SET @raised = 1;
    END CATCH;

    IF @raised = 0
        EXEC tSQLt.Fail 'The load did not raise an error for an as-of date no campaign year covers.';

    SELECT * INTO #After FROM Layercake.silv_member_year_attributes;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    DECLARE @log_rows int = (SELECT COUNT(*) FROM Layercake.etl_run_log);
    DECLARE @failed_rows int = (SELECT COUNT(*) FROM Layercake.etl_run_log WHERE status = 'Failed' AND error_message IS NOT NULL);
    EXEC tSQLt.AssertEquals 1, @log_rows;
    EXEC tSQLt.AssertEquals 1, @failed_rows;
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-005 contact with invoices but no events gets no rows]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000106', 'Join', 'Join', '2025-03-01', N'7000106', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (10501, N'7000105', 2025, N'INV-10501', N'V10501', '2024-10-15', N'DD', N'GBP', 450.00, N'N', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7000105', 2025, N'Fully Paid');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year
    INTO #Expected
    FROM (VALUES (N'7000106', 2025)) AS v(contact_no, campaign_year);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-006 payment method per year and carried forward to years with no invoice]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000201', 'Join', 'Join', '2023-02-01', N'7000201', 2023, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (20001, N'7000201', 2023, N'INV-20001', N'V20001', '2022-10-15', N'DD', N'GBP', 450.00, N'N', 0),
           (20002, N'7000201', 2024, N'INV-20002', N'V20002', '2023-10-15', N'Card', N'GBP', 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7000201', 2023, 1, 0, CAST(20001 AS bigint)),
                 (N'7000201', 2024, 2, 0, CAST(20002 AS bigint)),
                 (N'7000201', 2025, 2, 1, CAST(NULL AS bigint)),
                 (N'7000201', 2026, 2, 1, CAST(NULL AS bigint))) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-007 contact with no invoices is Unknown and not carried every year]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000301', 'Join', 'Join', '2024-05-01', N'7000301', 2024, 'Q2');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7000301', 2024, 0, 0, CAST(NULL AS bigint)),
                 (N'7000301', 2025, 0, 0, CAST(NULL AS bigint)),
                 (N'7000301', 2026, 0, 0, CAST(NULL AS bigint))) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-008 invoice with null payment mode and no payment lines is Unknown]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000401', 'Join', 'Join', '2024-03-01', N'7000401', 2024, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (40001, N'7000401', 2024, N'INV-40001', N'V40001', '2023-10-15', NULL, N'GBP', 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2024-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7000401', 2024, 0, 0, CAST(40001 AS bigint))) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-009 blank invoice mode and blank payment line modes give Unknown]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000402', 'Join', 'Join', '2024-03-01', N'7000402', 2024, 'Q1'),
           (2, N'J-7000403', 'Join', 'Join', '2024-03-01', N'7000403', 2024, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (40002, N'7000402', 2024, N'INV-40002', N'V40002', '2023-10-15', N'', N'GBP', 450.00, N'N', 0),
           (40003, N'7000403', 2024, N'INV-40003', N'V40003', '2023-10-15', N'   ', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, voucher, lastsettlevoucher, transdate, paymmode, settleamountcur, _is_deleted)
    VALUES (400021, N'7000402', N'PAY400021', N'V40002', '2023-11-01', N'   ', 450.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2024-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7000402', 2024, 0, 0, CAST(40002 AS bigint)),
                 (N'7000403', 2024, 0, 0, CAST(40003 AS bigint))) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-010 fully credited invoice is passed over for the not credited one]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7000501-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000501', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (50001, N'7000501', 2025, N'INV-A', N'V50001', '2024-10-15', N'Card', N'GBP', 450.00, N'Y', 0),
           (50002, N'7000501', 2025, N'INV-B', N'V50002', '2024-11-20', N'DD', N'GBP', 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7000501', 2025, 1, 0, CAST(50002 AS bigint))) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-011 later fully credited invoice does not become the segment invoice]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7000502-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000502', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (50011, N'7000502', 2025, N'INV-50011', N'V50011', '2024-10-15', N'DD', N'GBP', 450.00, N'N', 0),
           (50012, N'7000502', 2025, N'INV-50012', N'V50012', '2024-11-20', N'Card', N'GBP', 450.00, N'Y', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7000502', 2025, 1, 0, CAST(50011 AS bigint))) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-012 payment line fallback takes the largest settled method and earliest on a tie]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7000601-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000601', 2025, 'Q1'),
           (2, N'R-7000602-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000602', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (60001, N'7000601', 2025, N'INV-60001', N'V60001', '2024-10-15', NULL, N'GBP', 500.00, N'N', 0),
           (60002, N'7000602', 2025, N'INV-60002', N'V60002', '2024-10-15', NULL, N'GBP', 500.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, voucher, lastsettlevoucher, transdate, paymmode, settleamountcur, _is_deleted)
    VALUES (600011, N'7000601', N'PAY600011', N'V60001', '2024-11-01', N'Card', 200.00, 0),
           (600012, N'7000601', N'PAY600012', N'V60001', '2024-12-01', N'DD', 300.00, 0),
           (600021, N'7000602', N'PAY600021', N'V60002', '2024-11-01', N'Card', 250.00, 0),
           (600022, N'7000602', N'PAY600022', N'V60002', '2024-12-01', N'DD', 250.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried
    INTO #Expected
    FROM (VALUES (N'7000601', 2025, 1, 0),
                 (N'7000602', 2025, 2, 0)) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-013 payment lines summed as absolute values over live settling lines only]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7000603-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000603', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (60003, N'7000603', 2025, N'INV-60003', N'V60003', '2024-07-15', NULL, N'GBP', 550.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, voucher, lastsettlevoucher, transdate, paymmode, settleamountcur, _is_deleted)
    VALUES (600031, N'7000603', N'PAY600031', N'V60003', '2024-11-05', N'Card', -150.00, 0),
           (600032, N'7000603', N'PAY600032', N'V60003', '2024-11-06', N'Card', -150.00, 0),
           (600033, N'7000603', N'PAY600033', N'V60003', '2024-10-01', N'DD', -250.00, 0),
           (600034, N'7000603', N'PAY600034', N'V60003', '2024-09-01', N'DD', NULL, 0),
           (600035, N'7000603', N'V60003', N'V60003', '2024-08-01', N'Cheque', 900.00, 0),
           (600036, N'7999999', N'PAY600036', N'V60003', '2024-08-01', N'Bank', 1000.00, 0),
           (600037, N'7000603', N'PAY600037', N'V60003', '2024-08-01', N'Bank', 1000.00, 1);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried
    INTO #Expected
    FROM (VALUES (N'7000603', 2025, 2, 0)) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-014 equal sums on the same date go to the lowest recid]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7000604-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000604', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (60004, N'7000604', 2025, N'INV-60004', N'V60004', '2024-10-15', NULL, N'GBP', 500.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, voucher, lastsettlevoucher, transdate, paymmode, settleamountcur, _is_deleted)
    VALUES (600042, N'7000604', N'PAY600042', N'V60004', '2024-11-01T10:00:00', N'Card', 250.00, 0),
           (600041, N'7000604', N'PAY600041', N'V60004', '2024-11-01T10:00:00', N'DD', 250.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id
    INTO #Expected
    FROM (VALUES (N'7000604', 2025, 1)) AS v(contact_no, campaign_year, payment_method_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-015 unrecognised mode on invoice or winning payment line gives Unrecognised]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7000605-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000605', 2025, 'Q1'),
           (2, N'R-7000606-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000606', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (60005, N'7000605', 2025, N'INV-60005', N'V60005', '2024-10-15', N'XYZ', N'GBP', 300.00, N'N', 0),
           (60006, N'7000606', 2025, N'INV-60006', N'V60006', '2024-10-15', NULL, N'GBP', 400.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, voucher, lastsettlevoucher, transdate, paymmode, settleamountcur, _is_deleted)
    VALUES (600051, N'7000605', N'PAY600051', N'V60005', '2024-11-01', N'DD', 300.00, 0),
           (600061, N'7000606', N'PAY600061', N'V60006', '2024-11-01', N'XYZ', 300.00, 0),
           (600062, N'7000606', N'PAY600062', N'V60006', '2024-10-01', N'Card', 100.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried
    INTO #Expected
    FROM (VALUES (N'7000605', 2025, -1, 0),
                 (N'7000606', 2025, -1, 0)) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-016 no duplicate contact years and no null or orphan payment method]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000701', 'Join', 'Join', '2023-02-01', N'7000701', 2023, 'Q1'),
           (2, N'R-7000701-2024', 'Renewal', 'Renewal', '2024-01-10', N'7000701', 2024, 'Q1'),
           (3, N'C-7000701-2024', 'Change', 'Change', '2024-05-10', N'7000701', 2024, 'Q2'),
           (4, N'J-7000702', 'Join', 'Join', '2021-02-01', N'7000702', 2021, 'Q1'),
           (5, N'L-7000702-2025', 'Lapse', 'Lapse', '2025-03-31', N'7000702', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (70001, N'7000701', 2023, N'INV-70001', N'V70001', '2022-10-01', N'DD', N'GBP', 450.00, N'N', 0),
           (70002, N'7000701', 2024, N'INV-70002', N'V70002', '2023-10-01', N'DD', N'GBP', 450.00, N'N', 0),
           (70003, N'7000701', 2024, N'INV-70003', N'V70003', '2023-11-01', N'Card', N'GBP', 450.00, N'N', 0),
           (70004, N'7000701', 2024, N'CRE-0704', N'V70004', '2023-12-01', N'Cheque', N'GBP', -50.00, N'N', 0),
           (70005, N'7000701', 2025, N'INV-70005', N'V70005', '2024-10-01', N'XYZ', N'GBP', 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';

    SELECT contact_no, campaign_year
    INTO #Duplicates
    FROM Layercake.silv_member_year_attributes
    GROUP BY contact_no, campaign_year
    HAVING COUNT(*) > 1;
    EXEC tSQLt.AssertEmptyTable '#Duplicates';

    SELECT a.contact_no, a.campaign_year, a.payment_method_id
    INTO #Orphans
    FROM Layercake.silv_member_year_attributes AS a
    WHERE a.payment_method_id IS NULL
       OR NOT EXISTS (SELECT 1 FROM Layercake.silv_ref_payment_method AS r WHERE r.id = a.payment_method_id);
    EXEC tSQLt.AssertEmptyTable '#Orphans';

    DECLARE @rows int = (SELECT COUNT(*) FROM Layercake.silv_member_year_attributes);
    EXEC tSQLt.AssertEquals 10, @rows;
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-017 rerun on unchanged data changes nothing and logs 0 0 0]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000201', 'Join', 'Join', '2023-02-01', N'7000201', 2023, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (20001, N'7000201', 2023, N'INV-20001', N'V20001', '2022-10-15', N'DD', N'GBP', 450.00, N'N', 0),
           (20002, N'7000201', 2024, N'INV-20002', N'V20002', '2023-10-15', N'Card', N'GBP', 450.00, N'N', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7000201', 2023, N'Fully Paid'), (N'7000201', 2024, N'Fully Paid');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';
    SELECT * INTO #Before FROM Layercake.silv_member_year_attributes;

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';
    SELECT * INTO #After FROM Layercake.silv_member_year_attributes;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT layer, step_name, status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT layer, step_name, status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('silver', 'silv_member_year_attributes', 'Success', 4, 0, 0),
                 ('silver', 'silv_member_year_attributes', 'Success', 0, 0, 0)) AS v(layer, step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-018 first load logs Success with counts and stamps load_id]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000201', 'Join', 'Join', '2023-02-01', N'7000201', 2023, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (20001, N'7000201', 2023, N'INV-20001', N'V20001', '2022-10-15', N'DD', N'GBP', 450.00, N'N', 0),
           (20002, N'7000201', 2024, N'INV-20002', N'V20002', '2023-10-15', N'Card', N'GBP', 450.00, N'N', 0);

    DECLARE @run uniqueidentifier = 'B0000000-0000-0000-0000-000000000018';
    EXEC Layercake.usp_load_silv_member_year_attributes @run_id = @run, @as_of_date = '2026-06-15';

    SELECT run_id, layer, step_name, status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT run_id, layer, step_name, status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('B0000000-0000-0000-0000-000000000018' AS uniqueidentifier), 'silver', 'silv_member_year_attributes', 'Success', 4, 0, 0)) AS v(run_id, layer, step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT a.contact_no, a.campaign_year
    INTO #BadAudit
    FROM Layercake.silv_member_year_attributes AS a
    WHERE a.load_id IS NULL
       OR a.load_id <> (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l)
       OR a.created_at IS NULL
       OR a.updated_at IS NULL;
    EXEC tSQLt.AssertEmptyTable '#BadAudit';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-019 changed row updated in place and unchanged row untouched]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000201', 'Join', 'Join', '2023-02-01', N'7000201', 2023, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (20001, N'7000201', 2023, N'INV-20001', N'V20001', '2022-10-15', N'DD', N'GBP', 450.00, N'N', 0),
           (20002, N'7000201', 2024, N'INV-20002', N'V20002', '2023-10-15', N'Card', N'GBP', 450.00, N'N', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7000201', 2023, N'Fully Paid'), (N'7000201', 2024, N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'7000201', 2023, 1, 0, 1, 0, NULL, 1, 0, 20001, 7, '2020-01-01', '2020-01-01'),
           (N'7000201', 2024, 3, 0, 1, 0, NULL, 1, 0, 20002, 7, '2020-01-01', '2020-01-01');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';

    DECLARE @log_id bigint = (SELECT MAX(log_id) FROM Layercake.etl_run_log);

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id, load_id,
           created_at, CASE WHEN updated_at > '2020-01-01' THEN 1 ELSE 0 END AS updated_later
    INTO #Actual
    FROM Layercake.silv_member_year_attributes
    WHERE campaign_year IN (2023, 2024);

    SELECT contact_no, campaign_year, payment_method_id, load_id, created_at, updated_later
    INTO #Expected
    FROM (VALUES (N'7000201', 2023, 1, CAST(7 AS bigint), CAST('2020-01-01' AS datetime2(3)), 0),
                 (N'7000201', 2024, 2, @log_id, CAST('2020-01-01' AS datetime2(3)), 1)) AS v(contact_no, campaign_year, payment_method_id, load_id, created_at, updated_later);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 2, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-020 rows no longer derived are deleted]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000201', 'Join', 'Join', '2023-02-01', N'7000201', 2023, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (20001, N'7000201', 2023, N'INV-20001', N'V20001', '2022-10-15', N'DD', N'GBP', 450.00, N'N', 0),
           (20002, N'7000201', 2024, N'INV-20002', N'V20002', '2023-10-15', N'Card', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'7009999', 2025, 2, 0, 1, 0, NULL, 1, 0, 99999, 7, '2020-01-01', '2020-01-01'),
           (N'7000201', 2022, 0, 0, 0, 0, NULL, 0, 0, NULL, 7, '2020-01-01', '2020-01-01');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';

    SELECT contact_no, campaign_year
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year
    INTO #Expected
    FROM (VALUES (N'7000201', 2023), (N'7000201', 2024), (N'7000201', 2025), (N'7000201', 2026)) AS v(contact_no, campaign_year);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 4, 0, 2)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-021 latest eligible invoice by trans_date sets the payment method]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7000801-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000801', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (80001, N'7000801', 2025, N'INV-C', N'V80001', '2024-10-20', N'DD', N'GBP', 450.00, N'N', 0),
           (80002, N'7000801', 2025, N'INV-D', N'V80002', '2025-03-01', N'Card', N'GBP', 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7000801', 2025, 2, 0, CAST(80002 AS bigint))) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-022 equal trans_date goes to higher rec_id and null trans_date sorts first]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7000802-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000802', 2025, 'Q1'),
           (2, N'R-7000803-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000803', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (80011, N'7000802', 2025, N'INV-80011', N'V80011', '2024-11-01', N'Card', N'GBP', 450.00, N'N', 0),
           (80012, N'7000802', 2025, N'INV-80012', N'V80012', '2024-11-01', N'DD', N'GBP', 450.00, N'N', 0),
           (80021, N'7000803', 2025, N'INV-80021', N'V80021', '2024-10-01', N'Card', N'GBP', 450.00, N'N', 0),
           (80022, N'7000803', 2025, N'INV-80022', N'V80022', NULL, N'DD', N'GBP', 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7000802', 2025, 1, CAST(80012 AS bigint)),
                 (N'7000803', 2025, 2, CAST(80021 AS bigint))) AS v(contact_no, campaign_year, payment_method_id, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-023 eligible invoice view lists eligible invoices and flags the segment invoice]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (80031, N'7000804', 2025, N'INV-80031', N'V80031', '2024-10-20', N'DD', N'GBP', 450.00, N'N', 0),
           (80032, N'7000804', 2025, N'INV-80032', N'V80032', '2025-03-01', N'Card', N'GBP', 450.00, N'N', 0),
           (80033, N'7000804', 2025, N'CRE-0033', N'V80033', '2025-04-01', N'Cheque', N'GBP', -100.00, N'N', 0),
           (80034, N'7000804', 2025, N'INV-80034', N'V80034', '2025-05-01', N'Cheque', N'GBP', 450.00, N'N', 1),
           (80041, N'7000805', 2025, N'INV-80041', N'V80041', '2024-11-01', N'Card', N'GBP', 450.00, N'Y', 0),
           (80051, NULL, 2025, N'INV-80051', N'V80051', '2024-11-01', N'Card', N'GBP', 450.00, N'N', 0),
           (80052, N'7000804', NULL, N'INV-80052', N'V80052', '2025-06-01', N'Card', N'GBP', 450.00, N'N', 0);

    SELECT rec_id, CAST(is_segment_invoice AS int) AS is_segment_invoice
    INTO #Actual
    FROM Layercake.vw_silv_eligible_invoice
    WHERE rec_id BETWEEN 80031 AND 80059;

    SELECT rec_id, is_segment_invoice
    INTO #Expected
    FROM (VALUES (CAST(80031 AS bigint), 0),
                 (CAST(80032 AS bigint), 1),
                 (CAST(80041 AS bigint), 1)) AS v(rec_id, is_segment_invoice);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-024 later enrolment-fee-only invoice is not the segment invoice]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7000901-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000901', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (90001, N'7000901', 2025, N'INV-90001', N'V90001', '2024-10-10', N'Card', N'GBP', 450.00, N'N', 0),
           (90002, N'7000901', 2025, N'INV-90002', N'V90002', '2024-12-01', N'Corporate', N'GBP', 60.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (900011, N'7000901', N'INV-90001', N'V90001', '2024-10-10', N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0),
           (900021, N'7000901', N'INV-90002', N'V90002', '2024-12-01', N'APP', N'ENROLFEE', 50.00, 50.00, 0),
           (900022, N'7000901', N'INV-90002', N'V90002', '2024-12-01', N'TAX', N'VATUK', 10.00, 10.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7000901', 2025, 2, CAST(90001 AS bigint))) AS v(contact_no, campaign_year, payment_method_id, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-025 fee-only test uses live own lines and treats unmapped and null types as stated]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7000902-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000902', 2025, 'Q1'),
           (2, N'R-7000903-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000903', 2025, 'Q1'),
           (3, N'R-7000904-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000904', 2025, 'Q1'),
           (4, N'R-7000905-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000905', 2025, 'Q1'),
           (5, N'R-7000906-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000906', 2025, 'Q1'),
           (6, N'R-7000907-2025', 'Renewal', 'Renewal', '2025-01-10', N'7000907', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (90011, N'7000902', 2025, N'INV-90011', N'V90011', '2024-10-10', N'DD', N'GBP', 450.00, N'N', 0),
           (90012, N'7000902', 2025, N'INV-90012', N'V90012', '2024-12-01', N'Card', N'GBP', 250.00, N'N', 0),
           (90021, N'7000903', 2025, N'INV-90021', N'V90021', '2024-10-10', N'DD', N'GBP', 450.00, N'N', 0),
           (90022, N'7000903', 2025, N'INV-90022', N'V90022', '2024-12-01', N'Card', N'GBP', 450.00, N'N', 0),
           (90031, N'7000904', 2025, N'INV-90031', N'V90031', '2024-10-10', N'DD', N'GBP', 450.00, N'N', 0),
           (90032, N'7000904', 2025, N'INV-90032', N'V90032', '2024-12-01', N'Card', N'GBP', 75.00, N'N', 0),
           (90041, N'7000905', 2025, N'INV-90041', N'V90041', '2024-10-10', N'DD', N'GBP', 450.00, N'N', 0),
           (90042, N'7000905', 2025, N'INV-90042', N'V90042', '2024-12-01', N'Card', N'GBP', 50.00, N'N', 0),
           (90051, N'7000906', 2025, N'INV-90051', N'V90051', '2024-10-10', N'DD', N'GBP', 450.00, N'N', 0),
           (90052, N'7000906', 2025, N'INV-90052', N'V90052', '2024-12-01', N'Card', N'GBP', 50.00, N'N', 0),
           (90061, N'7000907', 2025, N'INV-90061', N'V90061', '2024-10-10', N'DD', N'GBP', 450.00, N'N', 0),
           (90062, N'7000907', 2025, N'INV-90062', N'V90062', '2024-12-01', N'Card', N'GBP', 10.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (900121, N'7000902', N'INV-90012', N'V90012', '2024-12-01', N'APP', N'ENROLFEE', 50.00, 50.00, 0),
           (900122, N'7000902', N'INV-90012', N'V90012', '2024-12-01', N'SUB', N'SUBS_MRICS', 200.00, 200.00, 0),
           (900321, N'7000904', N'INV-90032', N'V90032', '2024-12-01', N'APP', N'ENROLFEE', 50.00, 50.00, 0),
           (900322, N'7000904', N'INV-90032', N'V90032', '2024-12-01', N'SUB', N'NEWCODE', 25.00, 25.00, 0),
           (900421, N'7000905', N'INV-90042', N'V90042', '2024-12-01', N'APP', N'ENROLFEE', 50.00, 50.00, 0),
           (900422, N'7000905', N'INV-90042', N'V90042', '2024-12-01', N'SUB', N'SUBS_MRICS', 200.00, 200.00, 1),
           (900521, N'7000906', N'INV-90052', N'V90052', '2024-12-01', NULL, N'ENROLFEE', 50.00, 50.00, 0),
           (900621, N'7000907', N'INV-90062', N'V90062', '2024-12-01', N'TAX', N'VATUK', 10.00, 10.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7000902', 2025, 2, CAST(90012 AS bigint)),
                 (N'7000903', 2025, 2, CAST(90022 AS bigint)),
                 (N'7000904', 2025, 2, CAST(90032 AS bigint)),
                 (N'7000905', 2025, 1, CAST(90041 AS bigint)),
                 (N'7000906', 2025, 1, CAST(90051 AS bigint)),
                 (N'7000907', 2025, 2, CAST(90062 AS bigint))) AS v(contact_no, campaign_year, payment_method_id, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-026 year with only a fee-only invoice carries forward]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000908', 'Join', 'Join', '2024-02-01', N'7000908', 2024, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (90071, N'7000908', 2024, N'INV-90071', N'V90071', '2023-10-10', N'DD', N'GBP', 450.00, N'N', 0),
           (90072, N'7000908', 2025, N'INV-90072', N'V90072', '2024-12-01', N'Corporate', N'GBP', 50.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (900721, N'7000908', N'INV-90072', N'V90072', '2024-12-01', N'APP', N'ENROLFEE', 50.00, 50.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7000908', 2024, 1, 0, CAST(90071 AS bigint)),
                 (N'7000908', 2025, 1, 1, CAST(NULL AS bigint))) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-027 later CRE credit note is never the segment invoice]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7001001-2025', 'Renewal', 'Renewal', '2025-01-10', N'7001001', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (100001, N'7001001', 2025, N'INV-100001', N'V100001', '2024-10-10', N'DD', N'GBP', 450.00, N'N', 0),
           (100002, N'7001001', 2025, N'CRE-0001', N'V100002', '2024-12-01', N'Cheque', N'GBP', -450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7001001', 2025, 1, CAST(100001 AS bigint))) AS v(contact_no, campaign_year, payment_method_id, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-028 credit note test on CRE zero and null amounts FTCN and null invoice number]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7001002-2025', 'Renewal', 'Renewal', '2025-01-10', N'7001002', 2025, 'Q1'),
           (2, N'R-7001003-2025', 'Renewal', 'Renewal', '2025-01-10', N'7001003', 2025, 'Q1'),
           (3, N'R-7001004-2025', 'Renewal', 'Renewal', '2025-01-10', N'7001004', 2025, 'Q1'),
           (4, N'R-7001005-2025', 'Renewal', 'Renewal', '2025-01-10', N'7001005', 2025, 'Q1'),
           (5, N'R-7001006-2025', 'Renewal', 'Renewal', '2025-01-10', N'7001006', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (100021, N'7001002', 2025, N'INV-100021', N'V100021', '2024-10-10', N'DD', N'GBP', 450.00, N'N', 0),
           (100022, N'7001002', 2025, N'CRE-0003', N'V100022', '2024-12-01', N'Cheque', N'GBP', 0.00, N'N', 0),
           (100031, N'7001003', 2025, N'INV-100031', N'V100031', '2024-10-10', N'DD', N'GBP', 450.00, N'N', 0),
           (100032, N'7001003', 2025, N'CRE-0004', N'V100032', '2024-12-01', N'Cheque', N'GBP', NULL, N'N', 0),
           (100041, N'7001004', 2025, N'INV-100041', N'V100041', '2024-10-10', N'DD', N'GBP', 450.00, N'N', 0),
           (100042, N'7001004', 2025, N'FTCN-0005', N'V100042', '2024-12-01', N'Cheque', N'GBP', 0.00, N'N', 0),
           (100051, N'7001005', 2025, N'INV-100051', N'V100051', '2024-10-10', N'DD', N'GBP', 450.00, N'N', 0),
           (100052, N'7001005', 2025, NULL, N'V100052', '2024-12-01', N'Cheque', N'GBP', 450.00, N'N', 0),
           (100061, N'7001006', 2025, N'INV-100061', N'V100061', '2024-10-10', N'DD', N'GBP', 450.00, N'N', 0),
           (100062, N'7001006', 2025, N'XCRE9', N'V100062', '2024-12-01', N'Cheque', N'GBP', 120.00, N'N', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7001002', 2025, 4, CAST(100022 AS bigint)),
                 (N'7001003', 2025, 1, CAST(100031 AS bigint)),
                 (N'7001004', 2025, 1, CAST(100041 AS bigint)),
                 (N'7001005', 2025, 4, CAST(100052 AS bigint)),
                 (N'7001006', 2025, 1, CAST(100061 AS bigint))) AS v(contact_no, campaign_year, payment_method_id, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-029 only invoice fully credited still sets the year not carried]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7001101-2025', 'Renewal', 'Renewal', '2025-01-10', N'7001101', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (110001, N'7001101', 2025, N'INV-110001', N'V110001', '2024-10-10', N'Card', N'GBP', 300.00, N'Y', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7001101', 2025, 2, 0, CAST(110001 AS bigint))) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-030 fully_credited other than Y is not credited and fallback skips credit notes]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7001102-2025', 'Renewal', 'Renewal', '2025-01-10', N'7001102', 2025, 'Q1'),
           (2, N'R-7001103-2025', 'Renewal', 'Renewal', '2025-01-10', N'7001103', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (110011, N'7001102', 2025, N'INV-110011', N'V110011', '2024-10-01', N'DD', N'GBP', 450.00, N'N/A', 0),
           (110012, N'7001102', 2025, N'INV-110012', N'V110012', '2024-11-01', N'Card', N'GBP', 450.00, NULL, 0),
           (110021, N'7001103', 2025, N'INV-110021', N'V110021', '2024-10-01', N'Card', N'GBP', 450.00, N'Y', 0),
           (110022, N'7001103', 2025, N'INV-110022', N'V110022', '2024-11-01', N'DD', N'GBP', 450.00, N'Y', 0),
           (110023, N'7001103', 2025, N'CRE-0023', N'V110023', '2024-12-01', N'Cheque', N'GBP', -100.00, N'N', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7001102', 2025, 2, CAST(110012 AS bigint)),
                 (N'7001103', 2025, 1, CAST(110022 AS bigint))) AS v(contact_no, campaign_year, payment_method_id, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-031 years before 2022 are Not applicable for every segment]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7001201', 'Join', 'Join', '2020-03-01', N'7001201', 2020, 'Q1'),
           (2, N'R-7001201-2022', 'Renewal', 'Renewal', '2022-01-10', N'7001201', 2022, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (120001, N'7001201', 2022, N'INV-120001', N'V120001', '2021-10-10', N'DD', N'GBP', 450.00, N'N', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7001201', 2022, N'Fully Paid');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2022-06-15';

    SELECT contact_no, campaign_year,
           CAST(payment_method_id AS int) AS payment_method_id, CAST(payment_method_carried AS int) AS payment_method_carried,
           CAST(payer_type_id AS int) AS payer_type_id, CAST(payer_type_carried AS int) AS payer_type_carried,
           corporate_account_ref,
           CAST(concession_type_id AS int) AS concession_type_id, CAST(concession_type_carried AS int) AS concession_type_carried,
           segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
           corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7001201', 2020, -2, 0, -2, 0, CAST(NULL AS nvarchar(100)), -2, 0, CAST(NULL AS bigint)),
                 (N'7001201', 2021, -2, 0, -2, 0, CAST(NULL AS nvarchar(100)), -2, 0, CAST(NULL AS bigint)),
                 (N'7001201', 2022, 1, 0, 1, 0, CAST(NULL AS nvarchar(100)), 1, 0, CAST(120001 AS bigint)))
         AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
              corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-032 Not applicable is never carried into 2022]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7001202', 'Join', 'Join', '2021-03-01', N'7001202', 2021, 'Q1');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2022-06-15';

    SELECT contact_no, campaign_year,
           CAST(payment_method_id AS int) AS payment_method_id, CAST(payment_method_carried AS int) AS payment_method_carried,
           CAST(payer_type_id AS int) AS payer_type_id, CAST(payer_type_carried AS int) AS payer_type_carried,
           corporate_account_ref,
           CAST(concession_type_id AS int) AS concession_type_id, CAST(concession_type_carried AS int) AS concession_type_carried,
           segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
           corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7001202', 2021, -2, 0, -2, 0, CAST(NULL AS nvarchar(100)), -2, 0, CAST(NULL AS bigint)),
                 (N'7001202', 2022, 0, 0, 0, 0, CAST(NULL AS nvarchar(100)), 0, 0, CAST(NULL AS bigint)))
         AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
              corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-033 Corporate invoice with live corporate subscription is Corporate with scheme]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7002001-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002001', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (200001, N'7002001', 2025, N'INV-200001', N'V200001', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', 0);
    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'7002001', N'SCH-001', N'Alpha Surveyors LLP', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7002001', 2025, N'Fully Paid');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payer_type_id AS int) AS payer_type_id, CAST(payer_type_carried AS int) AS payer_type_carried, corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payer_type_id, payer_type_carried, corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'7002001', 2025, 5, 2, 0, N'SCH-001')) AS v(contact_no, campaign_year, payment_method_id, payer_type_id, payer_type_carried, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-034 Corporate payer type and scheme carried to a year with no invoice]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7002001-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002001', 2025, 'Q1'),
           (2, N'L-7002001-2026', 'Lapse', 'Lapse', '2026-03-31', N'7002001', 2026, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (200001, N'7002001', 2025, N'INV-200001', N'V200001', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', 0);
    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'7002001', N'SCH-001', N'Alpha Surveyors LLP', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7002001', 2025, N'Fully Paid');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried,
           CAST(payer_type_id AS int) AS payer_type_id, CAST(payer_type_carried AS int) AS payer_type_carried, corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'7002001', 2025, 5, 0, 2, 0, N'SCH-001'),
                 (N'7002001', 2026, 5, 1, 2, 1, N'SCH-001')) AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-035 Corporate invoice without a live subscription that year is Individual]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7002002-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002002', 2025, 'Q1'),
           (2, N'R-7002003-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002003', 2025, 'Q1'),
           (3, N'R-7002004-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002004', 2025, 'Q1'),
           (4, N'R-7002005-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002005', 2025, 'Q1'),
           (5, N'R-7002006-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002006', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (200021, N'7002002', 2025, N'INV-200021', N'V200021', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', 0),
           (200031, N'7002003', 2025, N'INV-200031', N'V200031', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', 0),
           (200041, N'7002004', 2025, N'INV-200041', N'V200041', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', 0),
           (200051, N'7002005', 2025, N'INV-200051', N'V200051', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', 0),
           (200061, N'7002006', 2025, N'INV-200061', N'V200061', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'7002002', N'SCH-002', N'Beta Property Ltd', 2024, N'Active', N'Active', 0),
           (N'7002003', N'SCH-003', N'Gamma Valuers', 2025, N'Active', N'Active', 1),
           (N'7002004', N'SCH-004', N'Delta Estates', 2025, N'Active', N'Inactive', 0),
           (N'7002005', N'SCH-005', N'Epsilon LLP', 2025, N'Inactive', N'Active', 0),
           (N'7002006', N'SCH-006', N'Zeta Partners', 2025, NULL, N'Active', 0);

    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7002002', 2025, N'Fully Paid'), (N'7002003', 2025, N'Fully Paid'), (N'7002004', 2025, N'Fully Paid'),
           (N'7002005', 2025, N'Fully Paid'), (N'7002006', 2025, N'Fully Paid');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payer_type_id AS int) AS payer_type_id,
           CAST(payer_type_carried AS int) AS payer_type_carried, corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payer_type_id, payer_type_carried, corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'7002002', 2025, 1, 0, CAST(NULL AS nvarchar(100))),
                 (N'7002003', 2025, 1, 0, CAST(NULL AS nvarchar(100))),
                 (N'7002004', 2025, 1, 0, CAST(NULL AS nvarchar(100))),
                 (N'7002005', 2025, 1, 0, CAST(NULL AS nvarchar(100))),
                 (N'7002006', 2025, 1, 0, CAST(NULL AS nvarchar(100)))) AS v(contact_no, campaign_year, payer_type_id, payer_type_carried, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-036 several live subscriptions give the lowest scheme number and one row]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7002007-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002007', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (200071, N'7002007', 2025, N'INV-200071', N'V200071', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', 0);
    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'7002007', N'SCH-020', N'Theta Group', 2025, N'Active', N'Active', 0),
           (N'7002007', N'SCH-010', N'Iota Holdings', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7002007', 2025, N'Fully Paid');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payer_type_id AS int) AS payer_type_id, corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payer_type_id, corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'7002007', 2025, 2, N'SCH-010')) AS v(contact_no, campaign_year, payer_type_id, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-037 double payment is Corporate with live subscription else Individual]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7002008-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002008', 2025, 'Q1'),
           (2, N'R-7002009-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002009', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (200081, N'7002008', 2025, N'INV-200081', N'V200081', '2024-10-15', N'Card', N'GBP', 450.00, N'N', 0),
           (200091, N'7002009', 2025, N'INV-200091', N'V200091', '2024-10-15', N'Card', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, voucher, lastsettlevoucher, transdate, paymmode, settleamountcur, _is_deleted)
    VALUES (2000811, N'7002008', N'PAY2000811', N'V200081', '2024-11-01', N'Card', 225.00, 0),
           (2000812, N'7002008', N'PAY2000812', N'V200081', '2024-12-01', N'Corporate', 225.00, 0),
           (2000911, N'7002009', N'PAY2000911', N'V200091', '2024-11-01', N'Card', 225.00, 0),
           (2000912, N'7002009', N'PAY2000912', N'V200091', '2024-12-01', N'Corporate', 225.00, 0);

    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'7002008', N'SCH-006', N'Kappa Surveyors', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7002008', 2025, N'Fully Paid'), (N'7002009', 2025, N'Fully Paid');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payer_type_id AS int) AS payer_type_id, CAST(payer_type_carried AS int) AS payer_type_carried, corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payer_type_id, payer_type_carried, corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'7002008', 2025, 2, 2, 0, N'SCH-006'),
                 (N'7002009', 2025, 2, 1, 0, CAST(NULL AS nvarchar(100)))) AS v(contact_no, campaign_year, payment_method_id, payer_type_id, payer_type_carried, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-038 Card invoice with paid position is Individual even with a live subscription]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7002101-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002101', 2025, 'Q1'),
           (2, N'R-7002102-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002102', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (210001, N'7002101', 2025, N'INV-210001', N'V210001', '2024-10-15', N'Card', N'GBP', 450.00, N'N', 0),
           (210002, N'7002102', 2025, N'INV-210002', N'V210002', '2024-10-15', N'Card', N'GBP', 450.00, N'N', 0);
    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'7002102', N'SCH-002', N'Beta Property Ltd', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7002101', 2025, N'Fully Paid'), (N'7002102', 2025, N'Partially Paid');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payer_type_id AS int) AS payer_type_id,
           CAST(payer_type_carried AS int) AS payer_type_carried, corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payer_type_id, payer_type_carried, corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'7002101', 2025, 1, 0, CAST(NULL AS nvarchar(100))),
                 (N'7002102', 2025, 1, 0, CAST(NULL AS nvarchar(100)))) AS v(contact_no, campaign_year, payer_type_id, payer_type_carried, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-039 no paid position that year gives Unknown unless Corporate]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7002103-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002103', 2025, 'Q1'),
           (2, N'R-7002104-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002104', 2025, 'Q1'),
           (3, N'R-7002105-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002105', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (210031, N'7002103', 2025, N'INV-210031', N'V210031', '2024-10-15', N'Card', N'GBP', 450.00, N'N', 0),
           (210041, N'7002104', 2025, N'INV-210041', N'V210041', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', 0),
           (210051, N'7002105', 2025, N'INV-210051', N'V210051', '2024-10-15', N'Card', N'GBP', 450.00, N'N', 0);
    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'7002104', N'SCH-004', N'Delta Estates', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7002105', 2024, N'Fully Paid');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payer_type_id AS int) AS payer_type_id,
           CAST(payer_type_carried AS int) AS payer_type_carried, corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payer_type_id, payer_type_carried, corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'7002103', 2025, 0, 0, CAST(NULL AS nvarchar(100))),
                 (N'7002104', 2025, 2, 0, N'SCH-004'),
                 (N'7002105', 2025, 0, 0, CAST(NULL AS nvarchar(100)))) AS v(contact_no, campaign_year, payer_type_id, payer_type_carried, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-040 no invoice and no paid position gives payer type Unknown not carried]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7002201', 'Join', 'Join', '2025-04-01', N'7002201', 2025, 'Q2');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';

    SELECT contact_no, campaign_year, CAST(payer_type_id AS int) AS payer_type_id,
           CAST(payer_type_carried AS int) AS payer_type_carried, corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payer_type_id, payer_type_carried, corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'7002201', 2025, 0, 0, CAST(NULL AS nvarchar(100))),
                 (N'7002201', 2026, 0, 0, CAST(NULL AS nvarchar(100)))) AS v(contact_no, campaign_year, payer_type_id, payer_type_carried, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-041 Corporate fee-only invoice sets neither payment method nor payer type]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7002301-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002301', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (230001, N'7002301', 2025, N'INV-230001', N'V230001', '2024-10-10', N'Card', N'GBP', 450.00, N'N', 0),
           (230002, N'7002301', 2025, N'INV-230002', N'V230002', '2024-12-01', N'Corporate', N'GBP', 50.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (2300011, N'7002301', N'INV-230001', N'V230001', '2024-10-10', N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0),
           (2300021, N'7002301', N'INV-230002', N'V230002', '2024-12-01', N'APP', N'ENROLFEE', 50.00, 50.00, 0);
    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'7002301', N'SCH-005', N'Epsilon LLP', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7002301', 2025, N'Fully Paid');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payer_type_id AS int) AS payer_type_id, corporate_account_ref, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payment_method_id, payer_type_id, corporate_account_ref, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7002301', 2025, 2, 1, CAST(NULL AS nvarchar(100)), CAST(230001 AS bigint))) AS v(contact_no, campaign_year, payment_method_id, payer_type_id, corporate_account_ref, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-042 reload with unchanged corporate subscription keeps Corporate and SCH-001]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7002001-2025', 'Renewal', 'Renewal', '2025-01-10', N'7002001', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (200001, N'7002001', 2025, N'INV-200001', N'V200001', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', 0);
    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'7002001', N'SCH-001', N'Alpha Surveyors LLP', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7002001', 2025, N'Fully Paid');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';
    SELECT * INTO #Before FROM Layercake.silv_member_year_attributes;

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';
    SELECT * INTO #After FROM Layercake.silv_member_year_attributes;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT contact_no, campaign_year, CAST(payer_type_id AS int) AS payer_type_id, corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, payer_type_id, corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'7002001', 2025, 2, N'SCH-001')) AS v(contact_no, campaign_year, payer_type_id, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @second_run_changes int =
        (SELECT COUNT(*) FROM Layercake.etl_run_log
         WHERE status = 'Success' AND rows_inserted = 0 AND rows_updated = 0 AND rows_deleted = 0);
    EXEC tSQLt.AssertEquals 1, @second_run_changes;
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-043 segment invoice with no concession line is No concession]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7003001-2025', 'Renewal', 'Renewal', '2025-01-10', N'7003001', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (300001, N'7003001', 2025, N'INV-300001', N'V300001', '2024-10-15', N'Card', N'GBP', 450.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (3000011, N'7003001', N'INV-300001', N'V300001', '2024-10-15', N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(concession_type_id AS int) AS concession_type_id,
           CAST(concession_type_carried AS int) AS concession_type_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, concession_type_id, concession_type_carried
    INTO #Expected
    FROM (VALUES (N'7003001', 2025, 1, 0)) AS v(contact_no, campaign_year, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-044 concession comes only from live own lines of the segment invoice]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7003002-2025', 'Renewal', 'Renewal', '2025-01-10', N'7003002', 2025, 'Q1'),
           (2, N'R-7003003-2025', 'Renewal', 'Renewal', '2025-01-10', N'7003003', 2025, 'Q1'),
           (3, N'R-7003004-2025', 'Renewal', 'Renewal', '2025-01-10', N'7003004', 2025, 'Q1'),
           (4, N'R-7003005-2025', 'Renewal', 'Renewal', '2025-01-10', N'7003005', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (300011, N'7003002', 2025, N'INV-300011', N'V300011', '2024-10-01', N'Card', N'GBP', 0.00, N'N', 0),
           (300012, N'7003002', 2025, N'INV-300012', N'V300012', '2024-12-01', N'DD', N'GBP', 450.00, N'N', 0),
           (300021, N'7003003', 2025, N'INV-300021', N'V300021', '2024-10-15', N'Card', N'GBP', 0.00, N'N', 0),
           (300031, N'7003004', 2025, N'INV-300031', N'V300031', '2024-10-15', N'Card', N'GBP', 450.00, N'N', 0),
           (300041, N'7003005', 2025, N'INV-300041', N'V300041', '2024-10-15', N'Card', N'GBP', 450.00, N'N', 0);

    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (3000111, N'7003002', N'INV-300011', N'V300011', '2024-10-01', N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0),
           (3000112, N'7003002', N'INV-300011', N'V300011', '2024-10-01', N'SUB', N'CONRETIRED', -450.00, -450.00, 0),
           (3000121, N'7003002', N'INV-300012', N'V300012', '2024-12-01', N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0),
           (3000211, N'7003003', N'INV-300021', N'V300021', '2024-10-15', N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0),
           (3000212, N'7003003', N'INV-300021', N'V300021', '2024-10-15', N'SUB', N'CONUNKNOWN', -450.00, -450.00, 0),
           (3000311, N'7003004', N'INV-300031', N'V300031', '2024-10-15', N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0),
           (3000312, N'7003004', N'INV-300031', N'V300031', '2024-10-15', N'SUB', N'CONRETIRED', -450.00, -450.00, 1),
           (3000411, N'7003005', N'INV-300041', N'V300041', '2024-10-15', N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0),
           (3000412, N'7003999', N'INV-300041', N'V300041', '2024-10-15', N'SUB', N'CONRETIRED', -450.00, -450.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(concession_type_id AS int) AS concession_type_id,
           CAST(concession_type_carried AS int) AS concession_type_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, concession_type_id, concession_type_carried
    INTO #Expected
    FROM (VALUES (N'7003002', 2025, 1, 0),
                 (N'7003003', 2025, -1, 0),
                 (N'7003004', 2025, 1, 0),
                 (N'7003005', 2025, 1, 0)) AS v(contact_no, campaign_year, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-045 perpetual Retired concession carried to a year with no invoice]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7003101-2025', 'Renewal', 'Renewal', '2025-01-10', N'7003101', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (300101, N'7003101', 2025, N'INV-300101', N'V300101', '2024-10-15', N'DD', N'GBP', 0.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (3001011, N'7003101', N'INV-300101', N'V300101', '2024-10-15', N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0),
           (3001012, N'7003101', N'INV-300101', N'V300101', '2024-10-15', N'SUB', N'CONRETIRED', -450.00, -450.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';

    SELECT contact_no, campaign_year, CAST(concession_type_id AS int) AS concession_type_id,
           CAST(concession_type_carried AS int) AS concession_type_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, concession_type_id, concession_type_carried
    INTO #Expected
    FROM (VALUES (N'7003101', 2025, 5, 0),
                 (N'7003101', 2026, 5, 1)) AS v(contact_no, campaign_year, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-046 highest discount concession line wins]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7003201-2025', 'Renewal', 'Renewal', '2025-01-10', N'7003201', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (300201, N'7003201', 2025, N'INV-300201', N'V300201', '2024-10-15', N'DD', N'GBP', 0.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (3002011, N'7003201', N'INV-300201', N'V300201', '2024-10-15', N'SUB', N'CONRETIRED', -225.00, -225.00, 0),
           (3002012, N'7003201', N'INV-300201', N'V300201', '2024-10-15', N'SUB', N'CONEXCEPTIONHP', -225.00, -225.00, 0),
           (3002013, N'7003201', N'INV-300201', N'V300201', '2024-10-15', N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(concession_type_id AS int) AS concession_type_id,
           CAST(concession_type_carried AS int) AS concession_type_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, concession_type_id, concession_type_carried
    INTO #Expected
    FROM (VALUES (N'7003201', 2025, 5, 0)) AS v(contact_no, campaign_year, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-047 non-perpetual concession is not carried]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7003301-2025', 'Renewal', 'Renewal', '2025-01-10', N'7003301', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (300301, N'7003301', 2025, N'INV-300301', N'V300301', '2024-10-15', N'DD', N'GBP', 225.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (3003011, N'7003301', N'INV-300301', N'V300301', '2024-10-15', N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0),
           (3003012, N'7003301', N'INV-300301', N'V300301', '2024-10-15', N'SUB', N'CONEXCEPTIONHP', -225.00, -225.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';

    SELECT contact_no, campaign_year, CAST(concession_type_id AS int) AS concession_type_id,
           CAST(concession_type_carried AS int) AS concession_type_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, concession_type_id, concession_type_carried
    INTO #Expected
    FROM (VALUES (N'7003301', 2025, 6, 0),
                 (N'7003301', 2026, 0, 0)) AS v(contact_no, campaign_year, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-048 concession carry looks only at the latest earlier invoiced year]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7003302', 'Join', 'Join', '2023-02-01', N'7003302', 2023, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (300321, N'7003302', 2023, N'INV-300321', N'V300321', '2022-10-15', N'DD', N'GBP', 0.00, N'N', 0),
           (300322, N'7003302', 2024, N'INV-300322', N'V300322', '2023-10-15', N'DD', N'GBP', 225.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (3003211, N'7003302', N'INV-300321', N'V300321', '2022-10-15', N'SUB', N'CONRETIRED', -450.00, -450.00, 0),
           (3003221, N'7003302', N'INV-300322', N'V300322', '2023-10-15', N'SUB', N'CONEXCEPTIONHP', -225.00, -225.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, campaign_year, CAST(concession_type_id AS int) AS concession_type_id,
           CAST(concession_type_carried AS int) AS concession_type_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, concession_type_id, concession_type_carried
    INTO #Expected
    FROM (VALUES (N'7003302', 2023, 5, 0),
                 (N'7003302', 2024, 6, 0),
                 (N'7003302', 2025, 0, 0)) AS v(contact_no, campaign_year, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-049 No concession is not carried]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-7003401-2025', 'Renewal', 'Renewal', '2025-01-10', N'7003401', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (300401, N'7003401', 2025, N'INV-300401', N'V300401', '2024-10-15', N'DD', N'GBP', 450.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, _is_deleted)
    VALUES (3004011, N'7003401', N'INV-300401', N'V300401', '2024-10-15', N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';

    SELECT contact_no, campaign_year, CAST(concession_type_id AS int) AS concession_type_id,
           CAST(concession_type_carried AS int) AS concession_type_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, concession_type_id, concession_type_carried
    INTO #Expected
    FROM (VALUES (N'7003401', 2025, 1, 0),
                 (N'7003401', 2026, 0, 0)) AS v(contact_no, campaign_year, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-050 attributes load leaves silv_membership_events unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id, assessment_route_id,
         rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter)
    VALUES (11, N'J-7004001', 'Join', 'Join', '2024-02-01', 'C0000000-0000-0000-0000-000000000001', N'7004001', 3, 2, 1, 4, 44, 1, 2, 2024, 'Q1'),
           (12, N'R-7004001-2025', 'Renewal', 'Renewal', '2025-01-10', NULL, N'7004001', 3, 2, 1, 4, 44, 1, 2, 2025, 'Q1'),
           (13, N'L-7004002-2025', 'Lapse', 'Lapse', '2025-03-31', NULL, N'7004002', 5, 1, 1, 2, 12, 2, 3, 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (400101, N'7004001', 2025, N'INV-400101', N'V400101', '2024-10-15', N'DD', N'GBP', 450.00, N'N', 0);

    SELECT * INTO #Before FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT * INTO #After FROM Layercake.silv_membership_events;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-051 silv_membership_events keeps Phase 1 columns and gains the seventeen columns]
AS
BEGIN
    SELECT c.name COLLATE DATABASE_DEFAULT AS column_name,
           CASE WHEN t.name IN ('nvarchar', 'nchar') THEN t.name + '(' + CAST(c.max_length / 2 AS varchar(10)) + ')'
                WHEN t.name IN ('varchar', 'char') THEN t.name + '(' + CAST(c.max_length AS varchar(10)) + ')'
                WHEN t.name IN ('decimal', 'numeric') THEN t.name + '(' + CAST(c.precision AS varchar(10)) + ',' + CAST(c.scale AS varchar(10)) + ')'
                ELSE t.name
           END COLLATE DATABASE_DEFAULT AS data_type,
           CAST(c.is_nullable AS int) AS is_nullable
    INTO #Actual
    FROM sys.columns AS c
    INNER JOIN sys.types AS t ON t.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(N'Layercake.silv_membership_events');

    SELECT column_name, data_type, is_nullable
    INTO #Expected
    FROM (VALUES ('event_id', 'int', 0), ('event_nk', 'nvarchar(220)', 0), ('event_type', 'varchar(20)', 0),
                 ('event_subtype', 'varchar(20)', 0), ('event_date', 'date', 0), ('source_enr_id', 'uniqueidentifier', 1),
                 ('contact_no', 'nvarchar(200)', 0), ('grade_id', 'int', 0), ('assessment_route_id', 'int', 0),
                 ('rpq_variant_id', 'int', 0), ('hpb_id', 'int', 0), ('country_id', 'int', 0), ('gender_id', 'int', 0),
                 ('membership_status_id', 'int', 0), ('campaign_year', 'int', 0), ('campaign_quarter', 'char(2)', 0),
                 ('payment_method_id', 'int', 0), ('payment_method_carried', 'bit', 0),
                 ('payer_type_id', 'int', 0), ('payer_type_carried', 'bit', 0),
                 ('concession_type_id', 'int', 0), ('concession_type_carried', 'bit', 0),
                 ('subs_amount', 'decimal(19,4)', 1), ('fee_amount', 'decimal(19,4)', 1), ('invoiced_subtotal', 'decimal(19,4)', 1),
                 ('credited_amount', 'decimal(19,4)', 1), ('currency_id', 'int', 1), ('subs_amount_gbp', 'decimal(19,4)', 1),
                 ('fee_amount_gbp', 'decimal(19,4)', 1), ('invoiced_subtotal_gbp', 'decimal(19,4)', 1),
                 ('credited_amount_gbp', 'decimal(19,4)', 1), ('net_amount_gbp', 'decimal(19,4)', 1),
                 ('amount_status', 'varchar(30)', 1)) AS v(column_name, data_type, is_nullable);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-052 fact_membership_events keeps Phase 1 columns and gains the seventeen columns]
AS
BEGIN
    SELECT c.name COLLATE DATABASE_DEFAULT AS column_name,
           CASE WHEN t.name IN ('nvarchar', 'nchar') THEN t.name + '(' + CAST(c.max_length / 2 AS varchar(10)) + ')'
                WHEN t.name IN ('varchar', 'char') THEN t.name + '(' + CAST(c.max_length AS varchar(10)) + ')'
                WHEN t.name IN ('decimal', 'numeric') THEN t.name + '(' + CAST(c.precision AS varchar(10)) + ',' + CAST(c.scale AS varchar(10)) + ')'
                ELSE t.name
           END COLLATE DATABASE_DEFAULT AS data_type,
           CAST(c.is_nullable AS int) AS is_nullable
    INTO #Actual
    FROM sys.columns AS c
    INNER JOIN sys.types AS t ON t.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(N'Layercake.fact_membership_events');

    SELECT column_name, data_type, is_nullable
    INTO #Expected
    FROM (VALUES ('event_id', 'int', 0), ('event_type', 'varchar(20)', 0), ('event_subtype', 'varchar(20)', 0),
                 ('event_date', 'date', 0), ('date_id', 'int', 0), ('contact_no', 'nvarchar(200)', 0),
                 ('grade_id', 'int', 0), ('assessment_route_id', 'int', 0), ('rpq_variant_id', 'int', 0),
                 ('hpb_id', 'int', 0), ('country_id', 'int', 0), ('gender_id', 'int', 0),
                 ('membership_status_id', 'int', 0), ('campaign_year', 'int', 0), ('campaign_quarter', 'char(2)', 0),
                 ('payment_method_id', 'int', 0), ('payment_method_carried', 'bit', 0),
                 ('payer_type_id', 'int', 0), ('payer_type_carried', 'bit', 0),
                 ('concession_type_id', 'int', 0), ('concession_type_carried', 'bit', 0),
                 ('subs_amount', 'decimal(19,4)', 1), ('fee_amount', 'decimal(19,4)', 1), ('invoiced_subtotal', 'decimal(19,4)', 1),
                 ('credited_amount', 'decimal(19,4)', 1), ('currency_id', 'int', 1), ('subs_amount_gbp', 'decimal(19,4)', 1),
                 ('fee_amount_gbp', 'decimal(19,4)', 1), ('invoiced_subtotal_gbp', 'decimal(19,4)', 1),
                 ('credited_amount_gbp', 'decimal(19,4)', 1), ('net_amount_gbp', 'decimal(19,4)', 1),
                 ('amount_status', 'varchar(30)', 1)) AS v(column_name, data_type, is_nullable);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-053 Phase 1 shaped insert into silv_membership_events gets 0 keys and null amounts]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id, assessment_route_id,
         rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter)
    VALUES (21, N'J-7005001', 'Join', 'Join', '2025-02-01', NULL, N'7005001', 1, 1, 1, 1, 1, 1, 1, 2025, 'Q1');

    CREATE TABLE #Actual
    (
        event_id                int NULL,
        payment_method_id       int NULL,
        payment_method_carried  int NULL,
        payer_type_id           int NULL,
        payer_type_carried      int NULL,
        concession_type_id      int NULL,
        concession_type_carried int NULL,
        subs_amount             decimal(19,4) NULL,
        fee_amount              decimal(19,4) NULL,
        invoiced_subtotal       decimal(19,4) NULL,
        credited_amount         decimal(19,4) NULL,
        currency_id             int NULL,
        subs_amount_gbp         decimal(19,4) NULL,
        fee_amount_gbp          decimal(19,4) NULL,
        invoiced_subtotal_gbp   decimal(19,4) NULL,
        credited_amount_gbp     decimal(19,4) NULL,
        net_amount_gbp          decimal(19,4) NULL,
        amount_status           varchar(30) COLLATE DATABASE_DEFAULT NULL
    );

    -- The seventeen columns are added by this module, so they are read through dynamic SQL.
    INSERT INTO #Actual
    EXEC sp_executesql N'
        SELECT event_id,
               CAST(payment_method_id AS int), CAST(payment_method_carried AS int),
               CAST(payer_type_id AS int), CAST(payer_type_carried AS int),
               CAST(concession_type_id AS int), CAST(concession_type_carried AS int),
               subs_amount, fee_amount, invoiced_subtotal, credited_amount, currency_id,
               subs_amount_gbp, fee_amount_gbp, invoiced_subtotal_gbp, credited_amount_gbp, net_amount_gbp, amount_status
        FROM Layercake.silv_membership_events;';

    SELECT 21 AS event_id, 0 AS payment_method_id, 0 AS payment_method_carried, 0 AS payer_type_id, 0 AS payer_type_carried,
           0 AS concession_type_id, 0 AS concession_type_carried,
           CAST(NULL AS decimal(19,4)) AS subs_amount, CAST(NULL AS decimal(19,4)) AS fee_amount,
           CAST(NULL AS decimal(19,4)) AS invoiced_subtotal, CAST(NULL AS decimal(19,4)) AS credited_amount,
           CAST(NULL AS int) AS currency_id,
           CAST(NULL AS decimal(19,4)) AS subs_amount_gbp, CAST(NULL AS decimal(19,4)) AS fee_amount_gbp,
           CAST(NULL AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(NULL AS decimal(19,4)) AS credited_amount_gbp,
           CAST(NULL AS decimal(19,4)) AS net_amount_gbp, CAST(NULL AS varchar(30)) AS amount_status
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007.[test TC-007-054 Phase 1 shaped insert into fact_membership_events gets 0 keys and null amounts]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.fact_membership_events', @Defaults = 1;

    INSERT INTO Layercake.fact_membership_events
        (event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id,
         rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter)
    VALUES (21, 'Join', 'Join', '2025-02-01', 20250201, N'7005001', 1, 1, 1, 1, 1, 1, 1, 2025, 'Q1');

    CREATE TABLE #Actual
    (
        event_id                int NULL,
        payment_method_id       int NULL,
        payment_method_carried  int NULL,
        payer_type_id           int NULL,
        payer_type_carried      int NULL,
        concession_type_id      int NULL,
        concession_type_carried int NULL,
        subs_amount             decimal(19,4) NULL,
        fee_amount              decimal(19,4) NULL,
        invoiced_subtotal       decimal(19,4) NULL,
        credited_amount         decimal(19,4) NULL,
        currency_id             int NULL,
        subs_amount_gbp         decimal(19,4) NULL,
        fee_amount_gbp          decimal(19,4) NULL,
        invoiced_subtotal_gbp   decimal(19,4) NULL,
        credited_amount_gbp     decimal(19,4) NULL,
        net_amount_gbp          decimal(19,4) NULL,
        amount_status           varchar(30) COLLATE DATABASE_DEFAULT NULL
    );

    -- The seventeen columns are added by this module, so they are read through dynamic SQL.
    INSERT INTO #Actual
    EXEC sp_executesql N'
        SELECT event_id,
               CAST(payment_method_id AS int), CAST(payment_method_carried AS int),
               CAST(payer_type_id AS int), CAST(payer_type_carried AS int),
               CAST(concession_type_id AS int), CAST(concession_type_carried AS int),
               subs_amount, fee_amount, invoiced_subtotal, credited_amount, currency_id,
               subs_amount_gbp, fee_amount_gbp, invoiced_subtotal_gbp, credited_amount_gbp, net_amount_gbp, amount_status
        FROM Layercake.fact_membership_events;';

    SELECT 21 AS event_id, 0 AS payment_method_id, 0 AS payment_method_carried, 0 AS payer_type_id, 0 AS payer_type_carried,
           0 AS concession_type_id, 0 AS concession_type_carried,
           CAST(NULL AS decimal(19,4)) AS subs_amount, CAST(NULL AS decimal(19,4)) AS fee_amount,
           CAST(NULL AS decimal(19,4)) AS invoiced_subtotal, CAST(NULL AS decimal(19,4)) AS credited_amount,
           CAST(NULL AS int) AS currency_id,
           CAST(NULL AS decimal(19,4)) AS subs_amount_gbp, CAST(NULL AS decimal(19,4)) AS fee_amount_gbp,
           CAST(NULL AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(NULL AS decimal(19,4)) AS credited_amount_gbp,
           CAST(NULL AS decimal(19,4)) AS net_amount_gbp, CAST(NULL AS varchar(30)) AS amount_status
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD007.[test TC-007-055 failed write rolls back logs Failed and re-raises]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-7000201', 'Join', 'Join', '2023-02-01', N'7000201', 2023, 'Q1'),
           (2, N'J-REJECT-01', 'Join', 'Join', '2025-02-01', N'REJECT-01', 2025, 'Q1');

    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (20001, N'7000201', 2023, N'INV-20001', N'V20001', '2022-10-15', N'DD', N'GBP', 450.00, N'N', 0),
           (20002, N'7000201', 2024, N'INV-20002', N'V20002', '2023-10-15', N'Card', N'GBP', 450.00, N'N', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7000201', 2023, N'Fully Paid'), (N'7000201', 2024, N'Fully Paid');

    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'7000201', 2024, 3, 0, 1, 0, NULL, 1, 0, 20002, 7, '2020-01-01', '2020-01-01');

    ALTER TABLE Layercake.silv_member_year_attributes
        ADD CONSTRAINT ck_test_MOD007_reject CHECK (contact_no <> N'REJECT-01');

    SELECT * INTO #Before FROM Layercake.silv_member_year_attributes;

    DECLARE @raised bit = 0;
    BEGIN TRY
        EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547
            THROW;
        SET @raised = 1;
    END CATCH;

    IF @raised = 0
        EXEC tSQLt.Fail 'The load did not raise the check-constraint error.';

    SELECT * INTO #After FROM Layercake.silv_member_year_attributes;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    DECLARE @log_rows int = (SELECT COUNT(*) FROM Layercake.etl_run_log);
    DECLARE @failed_rows int = (SELECT COUNT(*) FROM Layercake.etl_run_log WHERE status = 'Failed' AND error_message IS NOT NULL);
    EXEC tSQLt.AssertEquals 1, @log_rows;
    EXEC tSQLt.AssertEquals 1, @failed_rows;
END;
GO
