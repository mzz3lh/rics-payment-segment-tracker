EXEC tSQLt.NewTestClass 'test_MOD020_dev';
GO

CREATE PROCEDURE test_MOD020_dev.[SetUp]
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

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2024, '2023-10-01', '2024-09-30', '2024-09-30'),
           (2025, '2024-10-01', '2025-09-30', '2025-09-30');

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (0, 'Unknown', NULL, '2026-01-01', '2026-01-01'),
           (-1, 'Unrecognised', NULL, '2026-01-01', '2026-01-01'),
           (-2, 'Not applicable', NULL, '2026-01-01', '2026-01-01'),
           (1, 'Direct Debit', 'DD', '2026-01-01', '2026-01-01'),
           (2, 'Card', 'Card', '2026-01-01', '2026-01-01'),
           (5, 'Corporate', 'Corporate', '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.silv_ref_concession_type
        (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (-2, NULL, N'Not applicable', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01'),
           (1, NULL, N'No concession', NULL, 0, 0, NULL, '2026-01-01', '2026-01-01');

    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id, created_at, updated_at)
    VALUES (N'SUBS_MRICS', N'SUB', 'subscription', NULL, '2026-01-01', '2026-01-01');
END;
GO

-- A transaction's mode, date and amount repeat on its lines; if the lines ever disagree, the
-- qualifying line with the lowest line_id speaks for the whole transaction (choice in this module).
CREATE PROCEDURE test_MOD020_dev.[test a payment transaction whose lines disagree takes its mode and amount from the lowest line_id]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020901:2025', 'Renewal', '2024-11-05', N'7020901', 2025);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2090001, N'7020901', 2025, N'INV-2090001', N'V2090001', '2024-10-10', NULL, N'GBP', 700.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (line_id, recid, accountnum, voucher, lastsettlevoucher, transdate, settleamountcur, paymmode,
         postingtype, accountdisplayvalue, _is_deleted)
    VALUES (12, 9101, N'7020901', N'P9101', N'V2090001', '2024-11-01', 400.00, N'DD', 15, N'110100-CC20-UK--2025', 0),
           (11, 9101, N'7020901', N'P9101', N'V2090001', '2024-11-01', 400.00, N'Card', 15, N'110100-CC10-UK--2025', 0),
           (13, 9102, N'7020901', N'P9102', N'V2090001', '2024-12-01', 300.00, N'DD', 15, N'110100-CC10-UK--2025', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.payment_method_id, v.payment_method_carried
    INTO #Expected
    FROM (VALUES (N'7020901', 2025, 2, CAST(0 AS bit)))
         AS v(contact_no, campaign_year, payment_method_id, payment_method_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD020_dev.[test a blank-mode line of a payment transaction does not drop its other lines]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020902:2025', 'Renewal', '2024-11-05', N'7020902', 2025);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2090002, N'7020902', 2025, N'INV-2090002', N'V2090002', '2024-10-10', N'  ', N'GBP', 450.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (line_id, recid, accountnum, voucher, lastsettlevoucher, transdate, settleamountcur, paymmode,
         postingtype, accountdisplayvalue, _is_deleted)
    VALUES (21, 9111, N'7020902', N'P9111', N'V2090002', '2024-11-01', 250.00, N' ', 15, N'110100-CC10-UK--2025', 0),
           (22, 9111, N'7020902', N'P9111', N'V2090002', '2024-11-01', 250.00, N'Card', 15, N'110100-CC20-UK--2025', 0),
           (23, 9112, N'7020902', N'P9112', N'V2090002', '2024-10-15', 200.00, N'DD', 15, N'110100-CC10-UK--2025', 0);

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    SELECT a.contact_no, a.campaign_year, a.payment_method_id
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.campaign_year, v.payment_method_id
    INTO #Expected
    FROM (VALUES (N'7020902', 2025, 2)) AS v(contact_no, campaign_year, payment_method_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

-- The row written by the per-line sum (Card) is corrected to DD in place: one update, plus one
-- insert and one delete, all logged; created_at is kept and load_id set to this run's log id.
CREATE PROCEDURE test_MOD020_dev.[test correcting a split payment result logs one insert one update and one delete]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:7020903:2025', 'Renewal', '2024-11-05', N'7020903', 2025),
           (2, N'RN:7020904:2025', 'Renewal', '2024-11-05', N'7020904', 2025);
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, full_concession_flag, _is_deleted)
    VALUES (2090003, N'7020903', 2025, N'INV-2090003', N'V2090003', '2024-10-10', NULL, N'GBP', 900.00, N'N', N'Fully Paid', N'N', 0),
           (2090004, N'7020904', 2025, N'INV-2090004', N'V2090004', '2024-10-10', N'DD', N'GBP', 450.00, N'N', N'Fully Paid', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (line_id, recid, accountnum, voucher, lastsettlevoucher, transdate, settleamountcur, paymmode,
         postingtype, accountdisplayvalue, _is_deleted)
    VALUES (31, 9121, N'7020903', N'P9121', N'V2090003', '2024-11-01', 400.00, N'Card', 15, N'110100-CC10-UK--2025', 0),
           (32, 9121, N'7020903', N'P9121', N'V2090003', '2024-11-01', 400.00, N'Card', 15, N'110100-CC10-UK--2026', 0),
           (33, 9122, N'7020903', N'P9122', N'V2090003', '2024-12-01', 500.00, N'DD', 15, N'110100-CC10-UK--2025', 0);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'7020903', 2025, 2, 0, 0, 0, NULL, 1, 0, 2090003, 7, '2020-01-01', '2020-01-01'),
           (N'7029999', 2025, 1, 0, 0, 0, NULL, 1, 0, 2099999, 7, '2020-01-01', '2020-01-01');

    EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';

    DECLARE @log_id bigint = (SELECT MAX(l.log_id) FROM Layercake.etl_run_log AS l);

    SELECT a.contact_no, a.payment_method_id, a.load_id, a.created_at,
           CASE WHEN a.updated_at > '2020-01-01' THEN 1 ELSE 0 END AS updated_at_refreshed
    INTO #Actual
    FROM Layercake.silv_member_year_attributes AS a;

    SELECT v.contact_no, v.payment_method_id, v.load_id, v.created_at, v.updated_at_refreshed
    INTO #Expected
    FROM (VALUES (N'7020903', 1, @log_id, CAST('2020-01-01' AS datetime2(3)), 1),
                 (N'7020904', 1, @log_id, NULL, 1))
         AS v(contact_no, payment_method_id, load_id, created_at, updated_at_refreshed);

    -- created_at of the inserted row is the run time; compare it only for the updated row.
    UPDATE a SET created_at = NULL FROM #Actual AS a WHERE a.contact_no = N'7020904';

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT l.layer, l.step_name, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.layer, v.step_name, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('silver', 'silv_member_year_attributes', 'Success', 1, 1, 1))
         AS v(layer, step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

-- Error path forced through the data: an event with no contact_no cannot become a contact-year
-- (NOT NULL key of the load's working table), error 515.
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD020_dev.[test an event without a contact number fails the load logs Failed and leaves the target unchanged]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:NULL:2025', 'Renewal', '2024-11-05', NULL, 2025);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (line_id, recid, accountnum, voucher, lastsettlevoucher, transdate, settleamountcur, paymmode,
         postingtype, accountdisplayvalue, _is_deleted)
    VALUES (41, 9131, N'7020905', N'P9131', N'V2090005', '2024-11-01', 400.00, N'Card', 15, N'110100-CC10-UK--2025', 0),
           (42, 9131, N'7020905', N'P9131', N'V2090005', '2024-11-01', 400.00, N'Card', 15, N'110100-CC10-UK--2026', 0);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'7020905', 2025, 2, 0, 1, 0, NULL, 1, 0, 2090005, 7, '2020-01-01', '2020-01-01');

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried, a.payer_type_id,
           a.payer_type_carried, a.corporate_account_ref, a.concession_type_id, a.concession_type_carried,
           a.segment_invoice_rec_id, a.load_id, a.created_at, a.updated_at
    INTO #Before
    FROM Layercake.silv_member_year_attributes AS a;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_member_year_attributes @as_of_date = '2025-06-15';
        EXEC tSQLt.Fail 'The load raised no error for an event without a contact number.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515 THROW;
    END CATCH;

    SELECT a.contact_no, a.campaign_year, a.payment_method_id, a.payment_method_carried, a.payer_type_id,
           a.payer_type_carried, a.corporate_account_ref, a.concession_type_id, a.concession_type_carried,
           a.segment_invoice_rec_id, a.load_id, a.created_at, a.updated_at
    INTO #After
    FROM Layercake.silv_member_year_attributes AS a;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT l.layer, l.step_name, l.status,
           CASE WHEN l.error_message LIKE N'%error 515%' THEN 1 ELSE 0 END AS has_error_515
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT v.layer, v.step_name, v.status, v.has_error_515
    INTO #ExpectedLog
    FROM (VALUES ('silver', 'silv_member_year_attributes', 'Failed', 1))
         AS v(layer, step_name, status, has_error_515);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
