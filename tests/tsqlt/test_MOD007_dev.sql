EXEC tSQLt.NewTestClass 'test_MOD007_dev';
GO

CREATE PROCEDURE test_MOD007_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_invoice_line_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type';
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2021, '2021-01-01', '2021-12-31', '2021-12-31'),
           (2022, '2022-01-01', '2022-12-31', '2022-12-31'),
           (2023, '2023-01-01', '2023-12-31', '2023-12-31'),
           (2024, '2024-01-01', '2024-12-31', '2024-12-31'),
           (2025, '2025-01-01', '2025-12-31', '2025-12-31');

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (0, 'Unknown', NULL, '2026-01-01', '2026-01-01'),
           (-1, 'Unrecognised', NULL, '2026-01-01', '2026-01-01'),
           (1, 'Direct Debit', 'DD', '2026-01-01', '2026-01-01'),
           (2, 'Card', 'Card', '2026-01-01', '2026-01-01'),
           (5, 'Corporate', 'Corporate', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.brnz_concession (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _is_deleted)
    VALUES ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50.00, N'rcsCONEXCEPTIONHP', 0, 200000001, 0),
           ('A0000000-0000-0000-0000-000000000003', N'Other Hardship', 50.00, N'rcsCONOTHERHP', 0, 200000001, 0);

    INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (1, NULL, N'No concession', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (6, 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', N'CONEXCEPTIONHP', 0, 0, 3, '2026-01-01', '2026-01-01'),
           (7, 'A0000000-0000-0000-0000-000000000003', N'Other Hardship', N'CONOTHERHP', 0, 0, 3, '2026-01-01', '2026-01-01');
END;
GO

CREATE PROCEDURE test_MOD007_dev.[test payment line method whose lines have no transdate loses the earliest-payment tie]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-8000001-2025', 'Renewal', 'Renewal', '2025-01-10', N'8000001', 2025, 'Q1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (800001, N'8000001', 2025, N'INV-800001', N'V800001', '2024-10-15', NULL, 500.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, voucher, lastsettlevoucher, transdate, paymmode, settleamountcur, _is_deleted)
    VALUES (8000012, N'8000001', N'PAY8000012', N'V800001', '2024-12-01', N'Card', 250.00, 0),
           (8000011, N'8000001', N'PAY8000011', N'V800001', NULL, N'DD', 250.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    DECLARE @actual int = (SELECT payment_method_id FROM Layercake.silv_member_year_attributes WHERE contact_no = N'8000001');
    EXEC tSQLt.AssertEquals 2, @actual;
END;
GO

CREATE PROCEDURE test_MOD007_dev.[test recognised concession beats unrecognised and equal discounts go to lowest line recid]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-8000002-2025', 'Renewal', 'Renewal', '2025-01-10', N'8000002', 2025, 'Q1'),
           (2, N'R-8000003-2025', 'Renewal', 'Renewal', '2025-01-10', N'8000003', 2025, 'Q1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (800002, N'8000002', 2025, N'INV-800002', N'V800002', '2024-10-15', N'DD', 225.00, N'N', 0),
           (800003, N'8000003', 2025, N'INV-800003', N'V800003', '2024-10-15', N'DD', 225.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, _is_deleted)
    VALUES (8000021, N'8000002', N'INV-800002', N'V800002', '2024-10-15', N'SUB', N'CONUNKNOWN', -100.00, 0),
           (8000022, N'8000002', N'INV-800002', N'V800002', '2024-10-15', N'SUB', N'CONEXCEPTIONHP', -225.00, 0),
           (8000032, N'8000003', N'INV-800003', N'V800003', '2024-10-15', N'SUB', N'CONEXCEPTIONHP', -225.00, 0),
           (8000031, N'8000003', N'INV-800003', N'V800003', '2024-10-15', N'SUB', N'CONOTHERHP', -225.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT contact_no, CAST(concession_type_id AS int) AS concession_type_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, concession_type_id
    INTO #Expected
    FROM (VALUES (N'8000002', 6), (N'8000003', 7)) AS v(contact_no, concession_type_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007_dev.[test Unknown method of an invoiced year is carried with flag 1]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-8000004', 'Join', 'Join', '2024-02-01', N'8000004', 2024, 'Q1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (800004, N'8000004', 2024, N'INV-800004', N'V800004', '2023-10-15', NULL, 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried,
           CAST(payer_type_id AS int) AS payer_type_id, CAST(payer_type_carried AS int) AS payer_type_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried
    INTO #Expected
    FROM (VALUES (2024, 0, 0, 0, 0), (2025, 0, 1, 0, 1)) AS v(campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007_dev.[test invoice year before the first event year is carried into the first year]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-8000005', 'Join', 'Join', '2024-02-01', N'8000005', 2024, 'Q1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (800005, N'8000005', 2023, N'INV-800005', N'V800005', '2022-10-15', N'DD', 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2024-06-15';

    SELECT campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (2024, 1, 1, CAST(NULL AS bigint))) AS v(campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007_dev.[test pre-2022 invoice sets nothing and is never carried]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-8000006', 'Join', 'Join', '2021-02-01', N'8000006', 2021, 'Q1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (800006, N'8000006', 2021, N'INV-800006', N'V800006', '2020-10-15', N'DD', 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2022-06-15';

    SELECT campaign_year, CAST(payment_method_id AS int) AS payment_method_id,
           CAST(payment_method_carried AS int) AS payment_method_carried, segment_invoice_rec_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id
    INTO #Expected
    FROM (VALUES (2021, -2, 0, CAST(NULL AS bigint)), (2022, 0, 0, CAST(NULL AS bigint))) AS v(campaign_year, payment_method_id, payment_method_carried, segment_invoice_rec_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007_dev.[test double payment without live subscription or paid position is Individual]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-8000007-2025', 'Renewal', 'Renewal', '2025-01-10', N'8000007', 2025, 'Q1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (800007, N'8000007', 2025, N'INV-800007', N'V800007', '2024-10-15', N'Card', 450.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, voucher, lastsettlevoucher, transdate, paymmode, settleamountcur, _is_deleted)
    VALUES (8000071, N'8000007', N'PAY8000071', N'V800007', '2024-11-01', N'Card', 225.00, 0),
           (8000072, N'8000007', N'PAY8000072', N'V800007', '2024-12-01', N'Corporate', 225.00, 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT CAST(payer_type_id AS int) AS payer_type_id, corporate_account_ref
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT 1 AS payer_type_id, CAST(NULL AS nvarchar(100)) AS corporate_account_ref
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD007_dev.[test case-only scheme number change updates the row and logs one update]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'R-8000008-2025', 'Renewal', 'Renewal', '2025-01-10', N'8000008', 2025, 'Q1');
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (800008, N'8000008', 2025, N'INV-800008', N'V800008', '2024-10-15', N'Corporate', 450.00, N'N', 0);
    INSERT INTO Layercake.brnz_corporate_subscription (contact_no, scheme_no, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'8000008', N'SCH-008', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'8000008', 2025, 5, 0, 2, 0, N'sch-008', 1, 0, 800008, 7, '2020-01-01', '2020-01-01');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    DECLARE @ref varbinary(200) = (SELECT CAST(corporate_account_ref AS varbinary(200)) FROM Layercake.silv_member_year_attributes);
    EXEC tSQLt.AssertEquals 0x5300430048002D00300030003800, @ref;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD007_dev.[test eligible invoice view orders a null trans_date first]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (800091, N'8000009', 2025, N'INV-800091', N'V800091', '2024-10-01', N'DD', 450.00, N'N', 0),
           (800092, N'8000009', 2025, N'INV-800092', N'V800092', NULL, N'Card', 450.00, N'N', 0);

    SELECT rec_id, invoice_seq, CAST(is_segment_invoice AS int) AS is_segment_invoice
    INTO #Actual
    FROM Layercake.vw_silv_eligible_invoice;

    SELECT rec_id, invoice_seq, is_segment_invoice
    INTO #Expected
    FROM (VALUES (CAST(800092 AS bigint), CAST(1 AS bigint), 0),
                 (CAST(800091 AS bigint), CAST(2 AS bigint), 1)) AS v(rec_id, invoice_seq, is_segment_invoice);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD007_dev.[test as-of date outside every campaign year raises 50001 logs Failed and changes nothing]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'J-8000010', 'Join', 'Join', '2025-02-01', N'8000010', 2025, 'Q1');
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'7999998', 2025, 2, 0, 1, 0, NULL, 1, 0, 99001, 7, '2020-01-01', '2020-01-01');

    BEGIN TRY
        EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2030-01-15';
        EXEC tSQLt.Fail 'The load did not raise an error for an as-of date no campaign year covers.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 50001
            THROW;
    END CATCH;

    SELECT contact_no, campaign_year, load_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes;

    SELECT contact_no, campaign_year, load_id
    INTO #Expected
    FROM (VALUES (N'7999998', 2025, CAST(7 AS bigint))) AS v(contact_no, campaign_year, load_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT layer, step_name, status,
           CASE WHEN error_message LIKE N'%2030-01-15%' THEN 1 ELSE 0 END AS names_date
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT layer, step_name, status, names_date
    INTO #ExpectedLog
    FROM (VALUES ('silver', 'silv_member_year_attributes', 'Failed', 1)) AS v(layer, step_name, status, names_date);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
