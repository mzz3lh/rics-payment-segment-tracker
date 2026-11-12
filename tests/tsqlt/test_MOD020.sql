EXEC tSQLt.NewTestClass 'test_MOD020';
GO

CREATE PROCEDURE test_MOD020.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_invoice_line_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_event_amount';
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    SELECT v.y, DATEFROMPARTS(v.y - 1, 10, 1), DATEFROMPARTS(v.y, 9, 30), DATEFROMPARTS(v.y, 9, 30)
    FROM (VALUES (2019), (2020), (2021), (2022), (2023), (2024), (2025), (2026), (2027)) AS v(y);

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (0, 'Unknown', NULL, '2026-01-01', '2026-01-01'),
           (-1, 'Unrecognised', NULL, '2026-01-01', '2026-01-01'),
           (-2, 'Not applicable', NULL, '2026-01-01', '2026-01-01'),
           (1, 'Direct Debit', 'DD', '2026-01-01', '2026-01-01'),
           (2, 'Card', 'Card', '2026-01-01', '2026-01-01'),
           (3, 'Bank transfer', 'Bank', '2026-01-01', '2026-01-01'),
           (4, 'Cheque', 'Cheque', '2026-01-01', '2026-01-01'),
           (5, 'Corporate', 'Corporate', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.silv_ref_concession_type
        (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (-2, NULL, N'Not applicable', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (1, NULL, N'No concession', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (5, '00000000-0000-0000-0000-000000000501', N'Retired', N'CONRETIRED', 1, 1, 1, '2026-01-01', '2026-01-01'),
           (6, '00000000-0000-0000-0000-000000000502', N'Exceptional Hardship', N'CONEXCEPTIONHP', 0, 0, 1, '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.brnz_concession
        (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000501', N'Retired', 100.00, N'rcsCONRETIRED', 0, 200000000, 0),
           ('00000000-0000-0000-0000-000000000502', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, 0);

    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id, created_at, updated_at)
    VALUES (N'SUBS_MRICS', N'SUB', 'subscription', NULL, '2026-01-01', '2026-01-01'),
           (N'CONRETIRED', N'SUB', 'concession', NULL, '2026-01-01', '2026-01-01'),
           (N'CONEXCEPTIONHP', N'SUB', 'concession', NULL, '2026-01-01', '2026-01-01'),
           (N'RAFEE_MRICS', N'SUB', 'readmission fee', NULL, '2026-01-01', '2026-01-01'),
           (N'ENROLFEE', N'APP', 'enrolment or application fee', NULL, '2026-01-01', '2026-01-01'),
           (N'VATUK', N'TAX', 'tax', NULL, '2026-01-01', '2026-01-01');
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-001 split card payment counts once so direct debit wins]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020101:2025', 'Renewal', '2024-11-05', N'7020101', 2025);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7020101', 2025, N'Fully Paid');
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2010001, N'7020101', 2025, N'INV-2010001', N'V2010001', '2024-10-10', NULL, N'GBP', 900.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2010101, N'7020101', N'INV-2010001', N'V2010001', NULL, '2024-10-10', 2, N'SUB', N'SUBS_MRICS', 900.00, 900.00, 900.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (9001, N'7020101', NULL, N'P9001', N'V2010001', '2024-11-01', 8, NULL, NULL, -200.00, -200.00, 400.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9001, N'7020101', NULL, N'P9001', N'V2010001', '2024-11-01', 8, NULL, NULL, -200.00, -200.00, 400.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2026', N'110100', N'CC10', N'2026', 0),
           (9002, N'7020101', NULL, N'P9002', N'V2010001', '2024-12-01', 8, NULL, NULL, -500.00, -500.00, 500.00, N'GBP', N'DD', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried, a.segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payment_method_carried, v.segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7020101', 2025, 1, CAST(0 AS bit), CAST(2010001 AS bigint)))
         AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-002 tie between per-transaction totals goes to earliest payment then lowest recid]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020102:2025', 'Renewal', '2024-11-05', N'7020102', 2025),
           (2, N'RN:7020103:2025', 'Renewal', '2024-11-05', N'7020103', 2025);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2010002, N'7020102', 2025, N'INV-2010002', N'V2010002', '2024-10-10', NULL, N'GBP', 600.00, N'N', N'Fully Paid', N'N', 0),
           (2010003, N'7020103', 2025, N'INV-2010003', N'V2010003', '2024-10-10', NULL, N'GBP', 500.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (9011, N'7020102', NULL, N'P9011', N'V2010002', '2024-11-01', 8, NULL, NULL, -100.00, -100.00, 300.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9011, N'7020102', NULL, N'P9011', N'V2010002', '2024-11-01', 8, NULL, NULL, -100.00, -100.00, 300.00, N'GBP', N'Card', 15, N'110100-CC20-UK--2025', N'110100', N'CC20', N'2025', 0),
           (9011, N'7020102', NULL, N'P9011', N'V2010002', '2024-11-01', 8, NULL, NULL, -100.00, -100.00, 300.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2026', N'110100', N'CC10', N'2026', 0),
           (9012, N'7020102', NULL, N'P9012', N'V2010002', '2024-10-15', 8, NULL, NULL, -300.00, -300.00, 300.00, N'GBP', N'DD', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9031, N'7020103', NULL, N'P9031', N'V2010003', '2024-11-01 10:00', 8, NULL, NULL, -250.00, -250.00, 250.00, N'GBP', N'DD', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9032, N'7020103', NULL, N'P9032', N'V2010003', '2024-11-01 10:00', 8, NULL, NULL, -125.00, -125.00, 250.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9032, N'7020103', NULL, N'P9032', N'V2010003', '2024-11-01 10:00', 8, NULL, NULL, -125.00, -125.00, 250.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2026', N'110100', N'CC10', N'2026', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payment_method_carried
    INTO #Expected
    FROM (VALUES (N'7020102', 2025, 1, CAST(0 AS bit)),
                 (N'7020103', 2025, 1, CAST(0 AS bit)))
         AS v(contact_no, campaign_year, payment_method_id, payment_method_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-003 separate payments of one method still add up with absolute values]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020104:2025', 'Renewal', '2024-11-05', N'7020104', 2025);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2010004, N'7020104', 2025, N'INV-2010004', N'V2010004', '2024-09-20', NULL, N'GBP', 750.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (9041, N'7020104', NULL, N'P9041', N'V2010004', '2024-11-01 09:00', 8, NULL, NULL, -100.00, -100.00, -200.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9041, N'7020104', NULL, N'P9041', N'V2010004', '2024-11-01 09:00', 8, NULL, NULL, -100.00, -100.00, -200.00, N'GBP', N'Card', 15, N'110100-CC20-UK--2025', N'110100', N'CC20', N'2025', 0),
           (9042, N'7020104', NULL, N'P9042', N'V2010004', '2024-11-01 09:00', 8, NULL, NULL, -200.00, -200.00, 200.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9043, N'7020104', NULL, N'P9043', N'V2010004', '2024-10-01', 8, NULL, NULL, -350.00, -350.00, 350.00, N'GBP', N'DD', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payment_method_carried
    INTO #Expected
    FROM (VALUES (N'7020104', 2025, 2, CAST(0 AS bit)))
         AS v(contact_no, campaign_year, payment_method_id, payment_method_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-004 rerun with split payment lines logs success and changes nothing]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020101:2025', 'Renewal', '2024-11-05', N'7020101', 2025);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7020101', 2025, N'Fully Paid');
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2010001, N'7020101', 2025, N'INV-2010001', N'V2010001', '2024-10-10', NULL, N'GBP', 900.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2010101, N'7020101', N'INV-2010001', N'V2010001', NULL, '2024-10-10', 2, N'SUB', N'SUBS_MRICS', 900.00, 900.00, 900.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (9001, N'7020101', NULL, N'P9001', N'V2010001', '2024-11-01', 8, NULL, NULL, -200.00, -200.00, 400.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9001, N'7020101', NULL, N'P9001', N'V2010001', '2024-11-01', 8, NULL, NULL, -200.00, -200.00, 400.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2026', N'110100', N'CC10', N'2026', 0),
           (9002, N'7020101', NULL, N'P9002', N'V2010001', '2024-12-01', 8, NULL, NULL, -500.00, -500.00, 500.00, N'GBP', N'DD', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';
    SELECT * INTO #AfterFirst FROM Layercake.silv_member_year_attributes;

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';
    SELECT * INTO #AfterSecond FROM Layercake.silv_member_year_attributes;

    EXEC tSQLt.AssertEqualsTable '#AfterFirst', '#AfterSecond';

    SELECT l.layer, l.step_name, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.layer, v.step_name, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('silver', 'silv_member_year_attributes', 'Success', 1, 0, 0),
                 ('silver', 'silv_member_year_attributes', 'Success', 0, 0, 0))
         AS v(layer, step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD020.[test TC-020-005 failed load logs Failed re-raises and leaves the target unchanged]
AS
BEGIN
    DECLARE @err_no int = NULL,
            @err_msg nvarchar(4000) = NULL;

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020101:2025', 'Renewal', '2024-11-05', N'7020101', 2025);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2010001, N'7020101', 2025, N'INV-2010001', N'V2010001', '2024-10-10', NULL, N'GBP', 900.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (9001, N'7020101', NULL, N'P9001', N'V2010001', '2024-11-01', 8, NULL, NULL, -200.00, -200.00, 400.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9001, N'7020101', NULL, N'P9001', N'V2010001', '2024-11-01', 8, NULL, NULL, -200.00, -200.00, 400.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2026', N'110100', N'CC10', N'2026', 0),
           (9002, N'7020101', NULL, N'P9002', N'V2010001', '2024-12-01', 8, NULL, NULL, -500.00, -500.00, 500.00, N'GBP', N'DD', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'7020101', 2025, 2, 0, 1, 0, NULL, 1, 0, 2010001, 7, '2020-01-01', '2020-01-01');

    SELECT * INTO #Before FROM Layercake.silv_member_year_attributes;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_member_year_attributes
            @run_id = 'C0000000-0000-0000-0000-000000020005',
            @as_of_date = '2030-01-15';
    END TRY
    BEGIN CATCH
        SELECT @err_no = ERROR_NUMBER(), @err_msg = ERROR_MESSAGE();
    END CATCH;

    IF @err_no IS NULL
        EXEC tSQLt.Fail 'The load raised no error for an as-of date that no Campaign Year covers.';
    IF @err_no IN (201, 207, 208, 2812, 8144)
        EXEC tSQLt.Fail 'The load failed for an unexpected reason: ', @err_msg;

    SELECT * INTO #After FROM Layercake.silv_member_year_attributes;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT l.layer, l.step_name, l.status,
           CASE WHEN l.error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.layer, v.step_name, v.status, v.has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('silver', 'silv_member_year_attributes', 'Failed', 1))
         AS v(layer, step_name, status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-006 fee-only invoice with split fee lines is still not eligible]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020201:2025', 'Renewal', '2024-10-05', N'7020201', 2025);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2020001, N'7020201', 2025, N'INV-2020001', N'V2020001', '2024-10-05', N'DD', N'GBP', 450.00, N'N', N'Fully Paid', N'N', 0),
           (2020002, N'7020201', 2025, N'INV-2020002', N'V2020002', '2024-12-01', N'Corporate', N'GBP', 60.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2020101, N'7020201', N'INV-2020001', N'V2020001', NULL, '2024-10-05', 2, N'SUB', N'SUBS_MRICS', 450.00, 450.00, 450.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2020201, N'7020201', N'INV-2020002', N'V2020002', NULL, '2024-12-01', 2, N'APP', N'ENROLFEE', 30.00, 30.00, 60.00, N'GBP', NULL, 41, N'400200-CC10-UK-ENROLFEE', N'400200', N'CC10', NULL, 0),
           (2020201, N'7020201', N'INV-2020002', N'V2020002', NULL, '2024-12-01', 2, N'APP', N'ENROLFEE', 20.00, 20.00, 60.00, N'GBP', NULL, 41, N'400200-CC20-UK-ENROLFEE', N'400200', N'CC20', NULL, 0),
           (2020201, N'7020201', N'INV-2020002', N'V2020002', NULL, '2024-12-01', 2, N'TAX', N'VATUK', 10.00, 10.00, 60.00, N'GBP', NULL, 14, N'220100-CC10-UK-VATUK', N'220100', N'CC10', NULL, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried, a.segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payment_method_carried, v.segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7020201', 2025, 1, CAST(0 AS bit), CAST(2020001 AS bigint)))
         AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-007 split fee lines beside a split subscription line do not make an invoice fee-only]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020202:2025', 'Renewal', '2024-10-05', N'7020202', 2025);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2020011, N'7020202', 2025, N'INV-2020011', N'V2020011', '2024-10-05', N'DD', N'GBP', 450.00, N'N', N'Fully Paid', N'N', 0),
           (2020012, N'7020202', 2025, N'INV-2020012', N'V2020012', '2024-12-01', N'Card', N'GBP', 500.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2020111, N'7020202', N'INV-2020011', N'V2020011', NULL, '2024-10-05', 2, N'SUB', N'SUBS_MRICS', 450.00, 450.00, 450.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2020112, N'7020202', N'INV-2020012', N'V2020012', NULL, '2024-12-01', 2, N'APP', N'ENROLFEE', 30.00, 30.00, 500.00, N'GBP', NULL, 41, N'400200-CC10-UK-ENROLFEE', N'400200', N'CC10', NULL, 0),
           (2020112, N'7020202', N'INV-2020012', N'V2020012', NULL, '2024-12-01', 2, N'APP', N'ENROLFEE', 20.00, 20.00, 500.00, N'GBP', NULL, 41, N'400200-CC20-UK-ENROLFEE', N'400200', N'CC20', NULL, 0),
           (2020112, N'7020202', N'INV-2020012', N'V2020012', NULL, '2024-12-01', 2, N'SUB', N'SUBS_MRICS', 300.00, 300.00, 500.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2020112, N'7020202', N'INV-2020012', N'V2020012', NULL, '2024-12-01', 2, N'SUB', N'SUBS_MRICS', 150.00, 150.00, 500.00, N'GBP', NULL, 41, N'400100-CC20-UK-SUBS_MRICS-2025', N'400100', N'CC20', N'2025', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried, a.segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payment_method_carried, v.segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7020202', 2025, 2, CAST(0 AS bit), CAST(2020012 AS bigint)))
         AS v(contact_no, campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-008 eligible invoice view has one row per invoice whatever its line split]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2020021, N'7020203', 2025, N'INV-2020021', N'V2020021', '2024-10-05', N'DD', N'GBP', 540.00, N'N', N'Fully Paid', N'N', 0),
           (2020022, N'7020203', 2025, N'INV-2020022', N'V2020022', '2024-12-01', N'Corporate', N'GBP', 50.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2020121, N'7020203', N'INV-2020021', N'V2020021', NULL, '2024-10-05', 2, N'SUB', N'SUBS_MRICS', 200.00, 200.00, 540.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2020121, N'7020203', N'INV-2020021', N'V2020021', NULL, '2024-10-05', 2, N'SUB', N'SUBS_MRICS', 150.00, 150.00, 540.00, N'GBP', NULL, 41, N'400100-CC20-UK-SUBS_MRICS-2025', N'400100', N'CC20', N'2025', 0),
           (2020121, N'7020203', N'INV-2020021', N'V2020021', NULL, '2024-10-05', 2, N'SUB', N'SUBS_MRICS', 100.00, 100.00, 540.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2026', N'400100', N'CC10', N'2026', 0),
           (2020121, N'7020203', N'INV-2020021', N'V2020021', NULL, '2024-10-05', 2, N'TAX', N'VATUK', 90.00, 90.00, 540.00, N'GBP', NULL, 14, N'220100-CC10-UK-VATUK', N'220100', N'CC10', NULL, 0),
           (2020122, N'7020203', N'INV-2020022', N'V2020022', NULL, '2024-12-01', 2, N'APP', N'ENROLFEE', 25.00, 25.00, 50.00, N'GBP', NULL, 41, N'400200-CC10-UK-ENROLFEE', N'400200', N'CC10', NULL, 0),
           (2020122, N'7020203', N'INV-2020022', N'V2020022', NULL, '2024-12-01', 2, N'APP', N'ENROLFEE', 25.00, 25.00, 50.00, N'GBP', NULL, 41, N'400200-CC20-UK-ENROLFEE', N'400200', N'CC20', NULL, 0);

    SELECT e.contact_no, e.campaign_year, e.rec_id, e.invoice_seq, e.is_segment_invoice
    INTO #Actual
    FROM Layercake.vw_silv_eligible_invoice AS e;

    SELECT v.contact_no, v.campaign_year, v.rec_id, v.invoice_seq, v.is_segment_invoice
    INTO #Expected
    FROM (VALUES (N'7020203', 2025, CAST(2020021 AS bigint), CAST(1 AS bigint), CAST(1 AS bit)))
         AS v(contact_no, campaign_year, rec_id, invoice_seq, is_segment_invoice);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-009 split card payment and corporate payment give one double payment and Corporate]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020301:2025', 'Renewal', '2024-10-10', N'7020301', 2025);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7020301', 2025, N'Fully Paid');
    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'7020301', N'SCH-010', N'Scheme 10', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2030001, N'7020301', 2025, N'INV-2030001', N'V2030001', '2024-10-10', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2030101, N'7020301', N'INV-2030001', N'V2030001', NULL, '2024-10-10', 2, N'SUB', N'SUBS_MRICS', 450.00, 450.00, 450.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (9301, N'7020301', NULL, N'P9301', N'V2030001', '2024-11-01', 8, NULL, NULL, -112.50, -112.50, 225.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9301, N'7020301', NULL, N'P9301', N'V2030001', '2024-11-01', 8, NULL, NULL, -112.50, -112.50, 225.00, N'GBP', N'Card', 15, N'110100-CC20-UK--2025', N'110100', N'CC20', N'2025', 0),
           (9302, N'7020301', NULL, N'P9302', N'V2030001', '2024-12-01', 8, NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Corporate', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';
    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payer_type_id, a.payer_type_carried, a.corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payer_type_id, v.payer_type_carried, v.corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'7020301', 2025, 2, 2, CAST(0 AS bit), N'SCH-010'))
         AS v(contact_no, campaign_year, payment_method_id, payer_type_id, payer_type_carried, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT d.anomaly_type, d.contact_no
    INTO #ActualAnomaly
    FROM Layercake.silv_data_anomaly AS d;

    SELECT v.anomaly_type, v.contact_no
    INTO #ExpectedAnomaly
    FROM (VALUES ('DOUBLE_PAYMENT', N'7020301')) AS v(anomaly_type, contact_no);

    EXEC tSQLt.AssertEqualsTable '#ExpectedAnomaly', '#ActualAnomaly';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-010 one payment method split across lines is not a double payment]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020302:2025', 'Renewal', '2024-10-10', N'7020302', 2025),
           (2, N'RN:7020303:2025', 'Renewal', '2024-10-10', N'7020303', 2025);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7020302', 2025, N'Fully Paid'),
           (N'7020303', 2025, N'Fully Paid');
    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'7020302', N'SCH-011', N'Scheme 11', 2025, N'Active', N'Active', 0),
           (N'7020303', N'SCH-012', N'Scheme 12', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2030002, N'7020302', 2025, N'INV-2030002', N'V2030002', '2024-10-10', NULL, N'GBP', 450.00, N'N', N'Fully Paid', N'N', 0),
           (2030003, N'7020303', 2025, N'INV-2030003', N'V2030003', '2024-10-10', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (9311, N'7020302', NULL, N'P9311', N'V2030002', '2024-11-01', 8, NULL, NULL, -225.00, -225.00, 450.00, N'GBP', N'Corporate', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9311, N'7020302', NULL, N'P9311', N'V2030002', '2024-11-01', 8, NULL, NULL, -225.00, -225.00, 450.00, N'GBP', N'Corporate', 15, N'110100-CC20-UK--2025', N'110100', N'CC20', N'2025', 0),
           (9321, N'7020303', NULL, N'P9321', N'V2030003', '2024-11-01', 8, NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9322, N'7020303', NULL, N'P9322', N'V2030003', '2024-12-01', 8, NULL, NULL, -112.50, -112.50, 225.00, N'GBP', N'Corporate', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9322, N'7020303', NULL, N'P9322', N'V2030003', '2024-12-01', 8, NULL, NULL, -112.50, -112.50, 225.00, N'GBP', N'Corporate', 15, N'110100-CC20-UK--2025', N'110100', N'CC20', N'2025', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';
    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payer_type_id, a.corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payer_type_id, v.corporate_account_ref
    INTO #Expected
    FROM (VALUES (N'7020302', 2025, 5, 2, N'SCH-011'),
                 (N'7020303', 2025, 2, 2, N'SCH-012'))
         AS v(contact_no, campaign_year, payment_method_id, payer_type_id, corporate_account_ref);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT d.anomaly_type, d.contact_no
    INTO #ActualAnomaly
    FROM Layercake.silv_data_anomaly AS d;

    SELECT v.anomaly_type, v.contact_no
    INTO #ExpectedAnomaly
    FROM (VALUES ('DOUBLE_PAYMENT', N'7020303')) AS v(anomaly_type, contact_no);

    EXEC tSQLt.AssertEqualsTable '#ExpectedAnomaly', '#ActualAnomaly';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-011 rerun with split payment lines adds no anomaly row and logs 0 0 0]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020301:2025', 'Renewal', '2024-10-10', N'7020301', 2025);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'7020301', 2025, N'Fully Paid');
    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'7020301', N'SCH-010', N'Scheme 10', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2030001, N'7020301', 2025, N'INV-2030001', N'V2030001', '2024-10-10', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (9301, N'7020301', NULL, N'P9301', N'V2030001', '2024-11-01', 8, NULL, NULL, -112.50, -112.50, 225.00, N'GBP', N'Card', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0),
           (9301, N'7020301', NULL, N'P9301', N'V2030001', '2024-11-01', 8, NULL, NULL, -112.50, -112.50, 225.00, N'GBP', N'Card', 15, N'110100-CC20-UK--2025', N'110100', N'CC20', N'2025', 0),
           (9302, N'7020301', NULL, N'P9302', N'V2030001', '2024-12-01', 8, NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Corporate', 15, N'110100-CC10-UK--2025', N'110100', N'CC10', N'2025', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';
    EXEC Layercake.usp_load_silv_data_anomaly_segment;
    SELECT * INTO #AfterFirst FROM Layercake.silv_data_anomaly;

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';
    EXEC Layercake.usp_load_silv_data_anomaly_segment;
    SELECT * INTO #AfterSecond FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#AfterFirst', '#AfterSecond';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1, 0, 0),
                 ('Success', 1, 0, 0),
                 ('Success', 0, 0, 0),
                 ('Success', 0, 0, 0))
         AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-012 item code split across three lines of one recid adds one unmapped row]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (7401, N'7020801', N'INV-7401', N'V7401', NULL, '2024-10-10', 2, N'SUB', N'NEWFEE2', 100.00, 100.00, 250.00, N'GBP', NULL, 41, N'400100-CC10-UK-NEWFEE2-2025', N'400100', N'CC10', N'2025', 0),
           (7401, N'7020801', N'INV-7401', N'V7401', NULL, '2024-10-10', 2, N'SUB', N'NEWFEE2', 100.00, 100.00, 250.00, N'GBP', NULL, 41, N'400100-CC20-UK-NEWFEE2-2025', N'400100', N'CC20', N'2025', 0),
           (7401, N'7020801', N'INV-7401', N'V7401', NULL, '2024-10-10', 2, N'SUB', N'NEWFEE2', 50.00, 50.00, 250.00, N'GBP', NULL, 41, N'400100-CC10-UK-NEWFEE2-2026', N'400100', N'CC10', N'2026', 0);

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    SELECT t.item_code, t.ric_invoice_type, t.line_type
    INTO #Actual
    FROM Layercake.silv_ref_invoice_line_type AS t;

    SELECT v.item_code, v.ric_invoice_type, v.line_type
    INTO #Expected
    FROM (VALUES (N'SUBS_MRICS', N'SUB', 'subscription'),
                 (N'CONRETIRED', N'SUB', 'concession'),
                 (N'CONEXCEPTIONHP', N'SUB', 'concession'),
                 (N'RAFEE_MRICS', N'SUB', 'readmission fee'),
                 (N'ENROLFEE', N'APP', 'enrolment or application fee'),
                 (N'VATUK', N'TAX', 'tax'),
                 (N'NEWFEE2', N'SUB', 'unmapped'))
         AS v(item_code, ric_invoice_type, line_type);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-013 rerun of the line-type load on split lines adds nothing]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (7401, N'7020801', N'INV-7401', N'V7401', NULL, '2024-10-10', 2, N'SUB', N'NEWFEE2', 100.00, 100.00, 250.00, N'GBP', NULL, 41, N'400100-CC10-UK-NEWFEE2-2025', N'400100', N'CC10', N'2025', 0),
           (7401, N'7020801', N'INV-7401', N'V7401', NULL, '2024-10-10', 2, N'SUB', N'NEWFEE2', 100.00, 100.00, 250.00, N'GBP', NULL, 41, N'400100-CC20-UK-NEWFEE2-2025', N'400100', N'CC20', N'2025', 0),
           (7401, N'7020801', N'INV-7401', N'V7401', NULL, '2024-10-10', 2, N'SUB', N'NEWFEE2', 50.00, 50.00, 250.00, N'GBP', NULL, 41, N'400100-CC10-UK-NEWFEE2-2026', N'400100', N'CC10', N'2026', 0);

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;
    SELECT * INTO #AfterFirst FROM Layercake.silv_ref_invoice_line_type;

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;
    SELECT * INTO #AfterSecond FROM Layercake.silv_ref_invoice_line_type;

    EXEC tSQLt.AssertEqualsTable '#AfterFirst', '#AfterSecond';

    SELECT l.status, l.rows_inserted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1), ('Success', 0)) AS v(status, rows_inserted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-014 split lines spelling one code with different case or trailing spaces add one row]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (7411, N'7020802', N'INV-7411', N'V7411', NULL, '2024-10-10', 2, N'SUB', N'NEWFEE3', 60.00, 60.00, 150.00, N'GBP', NULL, 41, N'400100-CC10-UK-NEWFEE3-2025', N'400100', N'CC10', N'2025', 0),
           (7411, N'7020802', N'INV-7411', N'V7411', NULL, '2024-10-10', 2, N'SUB', N'newfee3', 50.00, 50.00, 150.00, N'GBP', NULL, 41, N'400100-CC20-UK-NEWFEE3-2025', N'400100', N'CC20', N'2025', 0),
           (7411, N'7020802', N'INV-7411', N'V7411', NULL, '2024-10-10', 2, N'SUB', N'NEWFEE3 ', 40.00, 40.00, 150.00, N'GBP', NULL, 41, N'400100-CC10-UK-NEWFEE3-2026', N'400100', N'CC10', N'2026', 0);

    EXEC Layercake.usp_load_silv_ref_invoice_line_type;

    SELECT UPPER(RTRIM(t.item_code)) AS item_code, t.ric_invoice_type, t.line_type
    INTO #Actual
    FROM Layercake.silv_ref_invoice_line_type AS t
    WHERE t.item_code = N'NEWFEE3';

    SELECT v.item_code, v.ric_invoice_type, v.line_type
    INTO #Expected
    FROM (VALUES (N'NEWFEE3', N'SUB', 'unmapped')) AS v(item_code, ric_invoice_type, line_type);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @row_count int = (SELECT COUNT(*) FROM Layercake.silv_ref_invoice_line_type);
    EXEC tSQLt.AssertEquals 7, @row_count;
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-015 readmission fee split across two lines is still a fee]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2040001, N'7020401', 2025, N'INV-2040001', N'V2040001', '2025-08-01', N'Card', N'GBP', 550.00, N'N', N'Fully Paid', N'N', 0),
           (2040002, N'7020402', 2025, N'INV-2040002', N'V2040002', '2025-08-01', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2040101, N'7020401', N'INV-2040001', N'V2040001', NULL, '2025-08-01', 2, N'SUB', N'SUBS_MRICS', 450.00, 450.00, 550.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2040101, N'7020401', N'INV-2040001', N'V2040001', NULL, '2025-08-01', 2, N'SUB', N'RAFEE_MRICS', 60.00, 60.00, 550.00, N'GBP', NULL, 41, N'400300-CC10-UK-RAFEE_MRICS-2025', N'400300', N'CC10', N'2025', 0),
           (2040101, N'7020401', N'INV-2040001', N'V2040001', NULL, '2025-08-01', 2, N'SUB', N'RAFEE_MRICS', 40.00, 40.00, 550.00, N'GBP', NULL, 41, N'400300-CC20-UK-RAFEE_MRICS-2025', N'400300', N'CC20', N'2025', 0),
           (2040102, N'7020402', N'INV-2040002', N'V2040002', NULL, '2025-08-01', 2, N'SUB', N'SUBS_MRICS', 300.00, 300.00, 450.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2040102, N'7020402', N'INV-2040002', N'V2040002', NULL, '2025-08-01', 2, N'SUB', N'SUBS_MRICS', 150.00, 150.00, 450.00, N'GBP', NULL, 41, N'400100-CC20-UK-SUBS_MRICS-2025', N'400100', N'CC20', N'2025', 0);
    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RD:7020401:2025', 4001, N'7020401', 'Readmission', '2025-08-12', 2025, 2040001, 'Matched', 450.00, 450.00, 'Invoiced', 1, '2026-01-01', '2026-01-01'),
           (N'RD:7020402:2025', 4002, N'7020402', 'Readmission', '2025-08-12', 2025, 2040002, 'Matched', 450.00, 450.00, 'Invoiced', 1, '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT d.anomaly_type, d.contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS d;

    SELECT v.anomaly_type, v.contact_no
    INTO #Expected
    FROM (VALUES ('READMISSION_NO_FEE', N'7020402')) AS v(anomaly_type, contact_no);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-016 split readmission fee in the free window raises no READMISSION_FREE]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2040003, N'7020403', 2025, N'INV-2040003', N'V2040003', '2025-02-01', N'Card', N'GBP', 550.00, N'N', N'Fully Paid', N'N', 0),
           (2040004, N'7020404', 2025, N'INV-2040004', N'V2040004', '2025-02-01', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2040103, N'7020403', N'INV-2040003', N'V2040003', NULL, '2025-02-01', 2, N'SUB', N'SUBS_MRICS', 450.00, 450.00, 550.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2040103, N'7020403', N'INV-2040003', N'V2040003', NULL, '2025-02-01', 2, N'SUB', N'RAFEE_MRICS', 60.00, 60.00, 550.00, N'GBP', NULL, 41, N'400300-CC10-UK-RAFEE_MRICS-2025', N'400300', N'CC10', N'2025', 0),
           (2040103, N'7020403', N'INV-2040003', N'V2040003', NULL, '2025-02-01', 2, N'SUB', N'RAFEE_MRICS', 40.00, 40.00, 550.00, N'GBP', NULL, 41, N'400300-CC20-UK-RAFEE_MRICS-2025', N'400300', N'CC20', N'2025', 0),
           (2040104, N'7020404', N'INV-2040004', N'V2040004', NULL, '2025-02-01', 2, N'SUB', N'SUBS_MRICS', 300.00, 300.00, 450.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2040104, N'7020404', N'INV-2040004', N'V2040004', NULL, '2025-02-01', 2, N'SUB', N'SUBS_MRICS', 150.00, 150.00, 450.00, N'GBP', NULL, 41, N'400100-CC20-UK-SUBS_MRICS-2025', N'400100', N'CC20', N'2025', 0);
    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RD:7020403:2025', 4003, N'7020403', 'Readmission', '2025-02-14', 2025, 2040003, 'Matched', 450.00, 450.00, 'Invoiced', 1, '2026-01-01', '2026-01-01'),
           (N'RD:7020404:2025', 4004, N'7020404', 'Readmission', '2025-02-14', 2025, 2040004, 'Matched', 450.00, 450.00, 'Invoiced', 1, '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT d.anomaly_type, d.contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS d;

    SELECT v.anomaly_type, v.contact_no
    INTO #Expected
    FROM (VALUES ('READMISSION_FREE', N'7020404')) AS v(anomaly_type, contact_no);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-017 invoice with four lines across two recids gives one INVOICE_NO_EVENT]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2050001, N'7020501', 2025, N'INV-2050001', N'V2050001', '2024-10-10', N'DD', N'GBP', 540.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2050101, N'7020501', N'INV-2050001', N'V2050001', NULL, '2024-10-10', 2, N'SUB', N'SUBS_MRICS', 300.00, 300.00, 450.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2050101, N'7020501', N'INV-2050001', N'V2050001', NULL, '2024-10-10', 2, N'SUB', N'SUBS_MRICS', 150.00, 150.00, 450.00, N'GBP', NULL, 41, N'400100-CC20-UK-SUBS_MRICS-2025', N'400100', N'CC20', N'2025', 0),
           (2050102, N'7020501', N'INV-2050001', N'V2050001', NULL, '2024-10-10', 2, N'TAX', N'VATUK', 60.00, 60.00, 90.00, N'GBP', NULL, 14, N'220100-CC10-UK-VATUK', N'220100', N'CC10', NULL, 0),
           (2050102, N'7020501', N'INV-2050001', N'V2050001', NULL, '2024-10-10', 2, N'TAX', N'VATUK', 30.00, 30.00, 90.00, N'GBP', NULL, 14, N'220100-CC20-UK-VATUK', N'220100', N'CC20', NULL, 0);

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT d.anomaly_type, d.contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS d;

    SELECT v.anomaly_type, v.contact_no
    INTO #Expected
    FROM (VALUES ('INVOICE_NO_EVENT', N'7020501')) AS v(anomaly_type, contact_no);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-018 surplus invoice with split lines gives one EVENT_MATCHES_MULTIPLE_INVOICES]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2050011, N'7020502', 2025, N'INV-2050011', N'V2050011', '2024-10-05', N'DD', N'GBP', 450.00, N'N', N'Fully Paid', N'N', 0),
           (2050012, N'7020502', 2025, N'INV-2050012', N'V2050012', '2024-12-01', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2050111, N'7020502', N'INV-2050011', N'V2050011', NULL, '2024-10-05', 2, N'SUB', N'SUBS_MRICS', 200.00, 200.00, 450.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2050111, N'7020502', N'INV-2050011', N'V2050011', NULL, '2024-10-05', 2, N'SUB', N'SUBS_MRICS', 150.00, 150.00, 450.00, N'GBP', NULL, 41, N'400100-CC20-UK-SUBS_MRICS-2025', N'400100', N'CC20', N'2025', 0),
           (2050111, N'7020502', N'INV-2050011', N'V2050011', NULL, '2024-10-05', 2, N'SUB', N'SUBS_MRICS', 100.00, 100.00, 450.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2026', N'400100', N'CC10', N'2026', 0),
           (2050112, N'7020502', N'INV-2050012', N'V2050012', NULL, '2024-12-01', 2, N'SUB', N'SUBS_MRICS', 450.00, 450.00, 450.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0);
    INSERT INTO Layercake.silv_event_amount
        (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome,
         subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:7020502:2025', 5001, N'7020502', 'Renewal', '2024-11-05', 2025, 2050012, 'Matched', 900.00, 900.00, 'Invoiced', 1, '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;

    SELECT d.anomaly_type, d.contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS d;

    SELECT v.anomaly_type, v.contact_no
    INTO #Expected
    FROM (VALUES ('EVENT_MATCHES_MULTIPLE_INVOICES', N'7020502')) AS v(anomaly_type, contact_no);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-019 rerun of the invoice anomaly load on split lines changes nothing]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2050001, N'7020501', 2025, N'INV-2050001', N'V2050001', '2024-10-10', N'DD', N'GBP', 540.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2050101, N'7020501', N'INV-2050001', N'V2050001', NULL, '2024-10-10', 2, N'SUB', N'SUBS_MRICS', 300.00, 300.00, 450.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2050101, N'7020501', N'INV-2050001', N'V2050001', NULL, '2024-10-10', 2, N'SUB', N'SUBS_MRICS', 150.00, 150.00, 450.00, N'GBP', NULL, 41, N'400100-CC20-UK-SUBS_MRICS-2025', N'400100', N'CC20', N'2025', 0),
           (2050102, N'7020501', N'INV-2050001', N'V2050001', NULL, '2024-10-10', 2, N'TAX', N'VATUK', 60.00, 60.00, 90.00, N'GBP', NULL, 14, N'220100-CC10-UK-VATUK', N'220100', N'CC10', NULL, 0),
           (2050102, N'7020501', N'INV-2050001', N'V2050001', NULL, '2024-10-10', 2, N'TAX', N'VATUK', 30.00, 30.00, 90.00, N'GBP', NULL, 14, N'220100-CC20-UK-VATUK', N'220100', N'CC20', NULL, 0);

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;
    SELECT * INTO #AfterFirst FROM Layercake.silv_data_anomaly;

    EXEC Layercake.usp_load_silv_data_anomaly_invoice;
    SELECT * INTO #AfterSecond FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#AfterFirst', '#AfterSecond';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1, 0, 0), ('Success', 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-020 retired concession split across two lines sets Retired not carried]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020601:2025', 'Renewal', '2024-10-10', N'7020601', 2025);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2060001, N'7020601', 2025, N'INV-2060001', N'V2060001', '2024-10-10', N'DD', N'GBP', 0.00, N'N', N'Full Concession', N'Y', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2060101, N'7020601', N'INV-2060001', N'V2060001', NULL, '2024-10-10', 2, N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2060101, N'7020601', N'INV-2060001', N'V2060001', NULL, '2024-10-10', 2, N'SUB', N'CONRETIRED', -300.00, -300.00, 0.00, N'GBP', NULL, 41, N'400500-CC10-UK-CONRETIRED-2025', N'400500', N'CC10', N'2025', 0),
           (2060101, N'7020601', N'INV-2060001', N'V2060001', NULL, '2024-10-10', 2, N'SUB', N'CONRETIRED', -150.00, -150.00, 0.00, N'GBP', NULL, 41, N'400500-CC20-UK-CONRETIRED-2025', N'400500', N'CC20', N'2025', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT a.contact_no, a.campaign_year, a.concession_type_id, a.concession_type_carried, a.segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.concession_type_id, v.concession_type_carried, v.segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7020601', 2025, 5, CAST(0 AS bit), CAST(2060001 AS bigint)))
         AS v(contact_no, campaign_year, concession_type_id, concession_type_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-021 split concession lines keep highest discount and perpetual carry forward]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020602:2025', 'Renewal', '2024-10-10', N'7020602', 2025);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2060011, N'7020602', 2025, N'INV-2060011', N'V2060011', '2024-10-10', N'DD', N'GBP', 0.00, N'N', N'Full Concession', N'Y', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2060111, N'7020602', N'INV-2060011', N'V2060011', NULL, '2024-10-10', 2, N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2060111, N'7020602', N'INV-2060011', N'V2060011', NULL, '2024-10-10', 2, N'SUB', N'CONEXCEPTIONHP', -100.00, -100.00, 0.00, N'GBP', NULL, 41, N'400500-CC10-UK-CONEXCEPTIONHP-2025', N'400500', N'CC10', N'2025', 0),
           (2060111, N'7020602', N'INV-2060011', N'V2060011', NULL, '2024-10-10', 2, N'SUB', N'CONEXCEPTIONHP', -125.00, -125.00, 0.00, N'GBP', NULL, 41, N'400500-CC20-UK-CONEXCEPTIONHP-2025', N'400500', N'CC20', N'2025', 0),
           (2060111, N'7020602', N'INV-2060011', N'V2060011', NULL, '2024-10-10', 2, N'SUB', N'CONRETIRED', -150.00, -150.00, 0.00, N'GBP', NULL, 41, N'400500-CC10-UK-CONRETIRED-2025', N'400500', N'CC10', N'2025', 0),
           (2060111, N'7020602', N'INV-2060011', N'V2060011', NULL, '2024-10-10', 2, N'SUB', N'CONRETIRED', -75.00, -75.00, 0.00, N'GBP', NULL, 41, N'400500-CC20-UK-CONRETIRED-2025', N'400500', N'CC20', N'2025', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2026-06-15';

    SELECT a.contact_no, a.campaign_year, a.concession_type_id, a.concession_type_carried, a.segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.concession_type_id, v.concession_type_carried, v.segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (N'7020602', 2025, 5, CAST(0 AS bit), CAST(2060011 AS bigint)),
                 (N'7020602', 2026, 5, CAST(1 AS bit), CAST(NULL AS bigint)))
         AS v(contact_no, campaign_year, concession_type_id, concession_type_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-022 unknown concession code split across two lines gives one CONCESSION_NOT_IN_REFERENCE]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020701:2025', 'Renewal', '2024-10-10', N'7020701', 2025);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2070001, N'7020701', 2025, N'INV-2070001', N'V2070001', '2024-10-10', N'DD', N'GBP', 300.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2070101, N'7020701', N'INV-2070001', N'V2070001', NULL, '2024-10-10', 2, N'SUB', N'SUBS_MRICS', 450.00, 450.00, 300.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2070101, N'7020701', N'INV-2070001', N'V2070001', NULL, '2024-10-10', 2, N'SUB', N'CONUNKNOWN2', -100.00, -100.00, 300.00, N'GBP', NULL, 41, N'400500-CC10-UK-CONUNKNOWN2-2025', N'400500', N'CC10', N'2025', 0),
           (2070101, N'7020701', N'INV-2070001', N'V2070001', NULL, '2024-10-10', 2, N'SUB', N'CONUNKNOWN2', -50.00, -50.00, 300.00, N'GBP', NULL, 41, N'400500-CC20-UK-CONUNKNOWN2-2025', N'400500', N'CC20', N'2025', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';
    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT a.contact_no, a.campaign_year, a.concession_type_id, a.concession_type_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.concession_type_id, v.concession_type_carried
    INTO #Expected
    FROM (VALUES (N'7020701', 2025, -1, CAST(0 AS bit)))
         AS v(contact_no, campaign_year, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT d.anomaly_type, d.contact_no
    INTO #ActualAnomaly
    FROM Layercake.silv_data_anomaly AS d;

    SELECT v.anomaly_type, v.contact_no
    INTO #ExpectedAnomaly
    FROM (VALUES ('CONCESSION_NOT_IN_REFERENCE', N'7020701')) AS v(anomaly_type, contact_no);

    EXEC tSQLt.AssertEqualsTable '#ExpectedAnomaly', '#ActualAnomaly';
END;
GO

CREATE PROCEDURE test_MOD020.[test TC-020-023 one CONCESSION_NOT_IN_REFERENCE per unknown code and none for a split known code]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020702:2025', 'Renewal', '2024-10-10', N'7020702', 2025),
           (2, N'RN:7020703:2025', 'Renewal', '2024-10-10', N'7020703', 2025);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2070002, N'7020702', 2025, N'INV-2070002', N'V2070002', '2024-10-10', N'DD', N'GBP', 250.00, N'N', N'Fully Paid', N'N', 0),
           (2070003, N'7020703', 2025, N'INV-2070003', N'V2070003', '2024-10-10', N'DD', N'GBP', 0.00, N'N', N'Full Concession', N'Y', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, transtype, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, postingtype, accountdisplayvalue,
         mainaccount, costcenter, ricscampaignyear, _is_deleted)
    VALUES (2070102, N'7020702', N'INV-2070002', N'V2070002', NULL, '2024-10-10', 2, N'SUB', N'SUBS_MRICS', 450.00, 450.00, 250.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2070102, N'7020702', N'INV-2070002', N'V2070002', NULL, '2024-10-10', 2, N'SUB', N'CONUNKNOWN3', -60.00, -60.00, 250.00, N'GBP', NULL, 41, N'400500-CC10-UK-CONUNKNOWN3-2025', N'400500', N'CC10', N'2025', 0),
           (2070102, N'7020702', N'INV-2070002', N'V2070002', NULL, '2024-10-10', 2, N'SUB', N'CONUNKNOWN3', -40.00, -40.00, 250.00, N'GBP', NULL, 41, N'400500-CC20-UK-CONUNKNOWN3-2025', N'400500', N'CC20', N'2025', 0),
           (2070102, N'7020702', N'INV-2070002', N'V2070002', NULL, '2024-10-10', 2, N'SUB', N'CONUNKNOWN4', -70.00, -70.00, 250.00, N'GBP', NULL, 41, N'400500-CC10-UK-CONUNKNOWN4-2025', N'400500', N'CC10', N'2025', 0),
           (2070102, N'7020702', N'INV-2070002', N'V2070002', NULL, '2024-10-10', 2, N'SUB', N'CONUNKNOWN4', -30.00, -30.00, 250.00, N'GBP', NULL, 41, N'400500-CC20-UK-CONUNKNOWN4-2025', N'400500', N'CC20', N'2025', 0),
           (2070103, N'7020703', N'INV-2070003', N'V2070003', NULL, '2024-10-10', 2, N'SUB', N'SUBS_MRICS', 450.00, 450.00, 0.00, N'GBP', NULL, 41, N'400100-CC10-UK-SUBS_MRICS-2025', N'400100', N'CC10', N'2025', 0),
           (2070103, N'7020703', N'INV-2070003', N'V2070003', NULL, '2024-10-10', 2, N'SUB', N'CONRETIRED', -300.00, -300.00, 0.00, N'GBP', NULL, 41, N'400500-CC10-UK-CONRETIRED-2025', N'400500', N'CC10', N'2025', 0),
           (2070103, N'7020703', N'INV-2070003', N'V2070003', NULL, '2024-10-10', 2, N'SUB', N'CONRETIRED', -150.00, -150.00, 0.00, N'GBP', NULL, 41, N'400500-CC20-UK-CONRETIRED-2025', N'400500', N'CC20', N'2025', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';
    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT a.contact_no, a.campaign_year, a.concession_type_id, a.concession_type_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.concession_type_id, v.concession_type_carried
    INTO #Expected
    FROM (VALUES (N'7020702', 2025, -1, CAST(0 AS bit)),
                 (N'7020703', 2025, 5, CAST(0 AS bit)))
         AS v(contact_no, campaign_year, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT d.anomaly_type, d.contact_no, COUNT(*) AS row_count
    INTO #ActualAnomaly
    FROM Layercake.silv_data_anomaly AS d
    GROUP BY d.anomaly_type, d.contact_no;

    SELECT v.anomaly_type, v.contact_no, v.row_count
    INTO #ExpectedAnomaly
    FROM (VALUES ('CONCESSION_NOT_IN_REFERENCE', N'7020702', 2)) AS v(anomaly_type, contact_no, row_count);

    EXEC tSQLt.AssertEqualsTable '#ExpectedAnomaly', '#ActualAnomaly';
END;
GO
