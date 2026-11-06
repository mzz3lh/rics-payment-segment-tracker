EXEC tSQLt.NewTestClass 'test_MOD008';
GO

CREATE PROCEDURE test_MOD008.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_invoice_line_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code)
    VALUES (0, 'Unknown', NULL), (-1, 'Unrecognised', NULL), (-2, 'Not applicable', NULL),
           (1, 'Direct Debit', 'DD'), (2, 'Card', 'Card'), (3, 'Bank transfer', 'Bank'),
           (4, 'Cheque', 'Cheque'), (5, 'Corporate', 'Corporate');

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name)
    VALUES (0, 'Unknown'), (-1, 'Unrecognised'), (-2, 'Not applicable'), (1, 'Individual'), (2, 'Corporate');

    INSERT INTO Layercake.brnz_concession
        (apuk_concessiontypeid, apuk_name, apuk_discount, product_number, statecode, apuk_perpetualnonperpetual, _is_deleted)
    VALUES ('A0000000-0000-0000-0000-000000000001', N'Retired', 100, N'rcsCONRETIRED', 0, 200000000, 0),
           ('A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', 50, N'rcsCONHARDSHIP', 0, 200000001, 0);

    INSERT INTO Layercake.silv_ref_concession_type
        (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL),
           (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL),
           (-2, NULL, N'Not applicable', NULL, 0, 0, NULL),
           (1, NULL, N'No concession', NULL, 0, 0, NULL),
           (2, 'A0000000-0000-0000-0000-000000000001', N'Retired', N'CONRETIRED', 1, 1, 1),
           (3, 'A0000000-0000-0000-0000-000000000002', N'Exceptional Hardship', N'CONHARDSHIP', 0, 0, 1);

    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type, load_id)
    VALUES (N'SUBS', N'SUB', 'subscription', NULL),
           (N'CONRETIRED', N'SUB', 'concession', NULL),
           (N'CONHARDSHIP', N'SUB', 'concession', NULL),
           (N'CONUNKNOWN', N'SUB', 'concession', NULL),
           (N'CONOTHER', N'SUB', 'concession', NULL);

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2021, '2020-10-01', '2021-09-30', '2021-12-31'),
           (2022, '2021-10-01', '2022-09-30', '2022-12-31'),
           (2023, '2022-10-01', '2023-09-30', '2023-12-31'),
           (2024, '2023-10-01', '2024-09-30', '2024-12-31'),
           (2025, '2024-10-01', '2025-09-30', '2025-12-31'),
           (2026, '2025-10-01', '2026-09-30', '2026-12-31');
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-001 Corporate segment invoice without a corporate subscription raises one CORPORATE_FLAG_NO_SCHEME row]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (900301, N'P3', 2025, N'INV-P3-25', N'V-P3-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9003011, N'P3', N'INV-P3-25', N'V-P3-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'P3', N'SCH-003', N'Scheme 3', 2024, N'Active', N'Active', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P3', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P3-2025', 'Renewal', '2024-10-20', N'P3', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P3', 2025, 5, 0, 1, 0, NULL, 1, 0, 900301, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('CORPORATE_FLAG_NO_SCHEME' AS varchar(40)), CAST(N'P3' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-002 anomaly_nk names the contact and year and detail names the year and segment invoice]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (900301, N'P3', 2025, N'INV-P3-25', N'V-P3-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9003011, N'P3', N'INV-P3-25', N'V-P3-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P3', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P3-2025', 'Renewal', '2024-10-20', N'P3', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P3', 2025, 5, 0, 1, 0, NULL, 1, 0, 900301, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    DECLARE @matching int =
        (SELECT COUNT(*)
         FROM Layercake.silv_data_anomaly AS a
         WHERE a.anomaly_type = 'CORPORATE_FLAG_NO_SCHEME'
           AND a.contact_no = N'P3'
           AND a.anomaly_nk LIKE N'%P3%'
           AND a.anomaly_nk LIKE N'%2025%'
           AND a.detail LIKE N'%2025%'
           AND (a.detail LIKE N'%INV-P3-25%' OR a.detail LIKE N'%900301%'));

    EXEC tSQLt.AssertEquals 1, @matching;
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-003 Corporate segment invoice with a live corporate subscription raises no anomaly]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (900101, N'P1', 2025, N'INV-P1-25', N'V-P1-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9001011, N'P1', N'INV-P1-25', N'V-P1-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'P1', N'SCH-001', N'Scheme 1', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P1', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P1-2025', 'Renewal', '2024-10-20', N'P1', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P1', 2025, 5, 0, 2, 0, N'SCH-001', 1, 0, 900101, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-004 soft-deleted corporate subscription is not live and the flag is raised]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (901201, N'P12', 2025, N'INV-P12-25', N'V-P12-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9012011, N'P12', N'INV-P12-25', N'V-P12-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted, _deleted_at)
    VALUES (N'P12', N'SCH-012', N'Scheme 12', 2025, N'Active', N'Active', 1, '2025-01-05T00:00:00');
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P12', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P12-2025', 'Renewal', '2024-10-20', N'P12', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P12', 2025, 5, 0, 1, 0, NULL, 1, 0, 901201, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('CORPORATE_FLAG_NO_SCHEME' AS varchar(40)), CAST(N'P12' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-005 Corporate on an earlier non-segment invoice raises no flag]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (901301, N'P13', 2025, N'INV-P13-25A', N'V-P13-25A', '2024-10-05', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0),
           (901302, N'P13', 2025, N'INV-P13-25B', N'V-P13-25B', '2025-01-10', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9013011, N'P13', N'INV-P13-25A', N'V-P13-25A', NULL, '2024-10-05', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9013021, N'P13', N'INV-P13-25B', N'V-P13-25B', NULL, '2025-01-10', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P13', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P13-2025', 'Renewal', '2024-10-20', N'P13', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P13', 2025, 2, 0, 1, 0, NULL, 1, 0, 901302, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-006 flag is raised for 2022 but not for 2021]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (901421, N'P14', 2021, N'INV-P14-21', N'V-P14-21', '2020-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0),
           (901522, N'P15', 2022, N'INV-P15-22', N'V-P15-22', '2021-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9014211, N'P14', N'INV-P14-21', N'V-P14-21', NULL, '2020-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9015221, N'P15', N'INV-P15-22', N'V-P15-22', NULL, '2021-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P14', 2021, N'Fully Paid'), (N'P15', 2022, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P14-2021', 'Renewal', '2020-10-20', N'P14', 2021),
           (2, N'EV-P15-2022', 'Renewal', '2021-10-20', N'P15', 2022);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P14', 2021, -2, 0, -2, 0, NULL, -2, 0, NULL, 1),
           (N'P15', 2022, 5, 0, 1, 0, NULL, 1, 0, 901522, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('CORPORATE_FLAG_NO_SCHEME' AS varchar(40)), CAST(N'P15' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-007 a carried-forward year with no invoice raises no flag]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (901625, N'P16', 2025, N'INV-P16-25', N'V-P16-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9016251, N'P16', N'INV-P16-25', N'V-P16-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P16', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P16-2025', 'Renewal', '2024-10-20', N'P16', 2025),
           (2, N'EV-P16-2026', 'Lapse', '2025-12-31', N'P16', 2026);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P16', 2025, 5, 0, 1, 0, NULL, 1, 0, 901625, 1),
           (N'P16', 2026, 5, 1, 1, 1, NULL, 0, 0, NULL, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('CORPORATE_FLAG_NO_SCHEME' AS varchar(40)), CAST(N'P16' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @rows_2026 int =
        (SELECT COUNT(*) FROM Layercake.silv_data_anomaly AS a WHERE a.anomaly_nk LIKE N'%2026%');
    EXEC tSQLt.AssertEquals 0, @rows_2026;
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-008 subscription with Sub User Status Inactive is not live and the flag is raised]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (900701, N'P7', 2025, N'INV-P7-25', N'V-P7-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9007011, N'P7', N'INV-P7-25', N'V-P7-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'P7', N'SCH-007', N'Scheme 7', 2025, N'Active', N'Inactive', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P7', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P7-2025', 'Renewal', '2024-10-20', N'P7', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P7', 2025, 5, 0, 1, 0, NULL, 1, 0, 900701, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('CORPORATE_FLAG_NO_SCHEME' AS varchar(40)), CAST(N'P7' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-009 Card and Corporate settlement with a live subscription raises one DOUBLE_PAYMENT row]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (900601, N'P6', 2025, N'INV-P6-25', N'V-P6-25', '2024-10-15', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9006011, N'P6', N'INV-P6-25', N'V-P6-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9006012, N'P6', NULL, N'PAY-P6-1', N'V-P6-25', '2024-11-01', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Card', 0),
           (9006013, N'P6', NULL, N'PAY-P6-2', N'V-P6-25', '2024-11-02', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Corporate', 0);
    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'P6', N'SCH-006', N'Scheme 6', 2025, N'Active', N'Active', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P6', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P6-2025', 'Renewal', '2024-10-20', N'P6', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P6', 2025, 2, 0, 2, 0, N'SCH-006', 1, 0, 900601, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('DOUBLE_PAYMENT' AS varchar(40)), CAST(N'P6' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-010 Card and Corporate settlement without a live subscription raises one DOUBLE_PAYMENT row]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (900801, N'P8', 2025, N'INV-P8-25', N'V-P8-25', '2024-10-15', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9008011, N'P8', N'INV-P8-25', N'V-P8-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9008012, N'P8', NULL, N'PAY-P8-1', N'V-P8-25', '2024-11-01', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Card', 0),
           (9008013, N'P8', NULL, N'PAY-P8-2', N'V-P8-25', '2024-11-02', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Corporate', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P8', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P8-2025', 'Renewal', '2024-10-20', N'P8', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P8', 2025, 2, 0, 1, 0, NULL, 1, 0, 900801, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('DOUBLE_PAYMENT' AS varchar(40)), CAST(N'P8' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-011 single-method settlement and a soft-deleted Corporate payment raise no DOUBLE_PAYMENT]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (901001, N'P10', 2025, N'INV-P10-25', N'V-P10-25', '2024-10-15', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0),
           (901101, N'P11', 2025, N'INV-P11-25', N'V-P11-25', '2024-10-15', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9010011, N'P10', N'INV-P10-25', N'V-P10-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9010012, N'P10', NULL, N'PAY-P10-1', N'V-P10-25', '2024-11-01', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Card', 0),
           (9010013, N'P10', NULL, N'PAY-P10-2', N'V-P10-25', '2024-11-02', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Card', 0),
           (9011011, N'P11', N'INV-P11-25', N'V-P11-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9011012, N'P11', NULL, N'PAY-P11-1', N'V-P11-25', '2024-11-01', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Card', 0),
           (9011013, N'P11', NULL, N'PAY-P11-2', N'V-P11-25', '2024-11-02', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Corporate', 1);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P10', 2025, N'Fully Paid'), (N'P11', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P10-2025', 'Renewal', '2024-10-20', N'P10', 2025),
           (2, N'EV-P11-2025', 'Renewal', '2024-10-20', N'P11', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P10', 2025, 2, 0, 1, 0, NULL, 1, 0, 901001, 1),
           (N'P11', 2025, 2, 0, 1, 0, NULL, 1, 0, 901101, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-012 Corporate invoice settled by Card and Corporate without a subscription raises both types once]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (901701, N'P17', 2025, N'INV-P17-25', N'V-P17-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9017011, N'P17', N'INV-P17-25', N'V-P17-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9017012, N'P17', NULL, N'PAY-P17-1', N'V-P17-25', '2024-11-01', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Card', 0),
           (9017013, N'P17', NULL, N'PAY-P17-2', N'V-P17-25', '2024-11-02', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Corporate', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P17', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P17-2025', 'Renewal', '2024-10-20', N'P17', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P17', 2025, 5, 0, 1, 0, NULL, 1, 0, 901701, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('CORPORATE_FLAG_NO_SCHEME' AS varchar(40)), CAST(N'P17' AS nvarchar(200))),
                 (CAST('DOUBLE_PAYMENT' AS varchar(40)), CAST(N'P17' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @distinct_nk int = (SELECT COUNT(DISTINCT a.anomaly_nk) FROM Layercake.silv_data_anomaly AS a);
    EXEC tSQLt.AssertEquals 2, @distinct_nk;
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-013 rerun on unchanged data leaves every anomaly row untouched and logs 0 0 0]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (900301, N'P3', 2025, N'INV-P3-25', N'V-P3-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0),
           (900801, N'P8', 2025, N'INV-P8-25', N'V-P8-25', '2024-10-15', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0),
           (910401, N'K4', 2025, N'INV-K4-25', N'V-K4-25', '2024-10-15', N'Card', N'GBP', 350.00, N'N', N'Fully Paid', N'Y', N'N', 0),
           (910501, N'K5', 2025, N'INV-K5-25', N'V-K5-25', '2024-10-15', N'Card', N'GBP', 0.00, N'N', N'Full Concession', N'N', N'Y', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9003011, N'P3', N'INV-P3-25', N'V-P3-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9008011, N'P8', N'INV-P8-25', N'V-P8-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9008012, N'P8', NULL, N'PAY-P8-1', N'V-P8-25', '2024-11-01', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Card', 0),
           (9008013, N'P8', NULL, N'PAY-P8-2', N'V-P8-25', '2024-11-02', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Corporate', 0),
           (9104011, N'K4', N'INV-K4-25', N'V-K4-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9104012, N'K4', N'INV-K4-25', N'V-K4-25', NULL, '2024-10-15', N'SUB', N'CONUNKNOWN', -100.00, -100.00, NULL, N'GBP', NULL, 0),
           (9105011, N'K5', N'INV-K5-25', N'V-K5-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P3', 2025, N'Fully Paid'), (N'P8', 2025, N'Fully Paid'), (N'K4', 2025, N'Fully Paid'), (N'K5', 2025, N'Full Concession');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P3-2025', 'Renewal', '2024-10-20', N'P3', 2025),
           (2, N'EV-P8-2025', 'Renewal', '2024-10-20', N'P8', 2025),
           (3, N'EV-K4-2025', 'Renewal', '2024-10-20', N'K4', 2025),
           (4, N'EV-K5-2025', 'Renewal', '2024-10-20', N'K5', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P3', 2025, 5, 0, 1, 0, NULL, 1, 0, 900301, 1),
           (N'P8', 2025, 2, 0, 1, 0, NULL, 1, 0, 900801, 1),
           (N'K4', 2025, 2, 0, 1, 0, NULL, -1, 0, 910401, 1),
           (N'K5', 2025, 2, 0, 1, 0, NULL, 1, 0, 910501, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT * INTO #Before FROM Layercake.silv_data_anomaly;
    DELETE FROM Layercake.etl_run_log;

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT * INTO #After FROM Layercake.silv_data_anomaly;

    DECLARE @before_rows int = (SELECT COUNT(*) FROM #Before);
    EXEC tSQLt.AssertEquals 4, @before_rows;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 0, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-014 a case that no longer applies is removed and a still-valid case is untouched]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (900301, N'P3', 2025, N'INV-P3-25', N'V-P3-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0),
           (900801, N'P8', 2025, N'INV-P8-25', N'V-P8-25', '2024-10-15', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9003011, N'P3', N'INV-P3-25', N'V-P3-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9008011, N'P8', N'INV-P8-25', N'V-P8-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9008012, N'P8', NULL, N'PAY-P8-1', N'V-P8-25', '2024-11-01', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Card', 0),
           (9008013, N'P8', NULL, N'PAY-P8-2', N'V-P8-25', '2024-11-02', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Corporate', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P3', 2025, N'Fully Paid'), (N'P8', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P3-2025', 'Renewal', '2024-10-20', N'P3', 2025),
           (2, N'EV-P8-2025', 'Renewal', '2024-10-20', N'P8', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P3', 2025, 5, 0, 1, 0, NULL, 1, 0, 900301, 1),
           (N'P8', 2025, 2, 0, 1, 0, NULL, 1, 0, 900801, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    -- Correction: P3 now has a live 2025 corporate subscription, and the attributes load has made it Corporate.
    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'P3', N'SCH-003', N'Scheme 3', 2025, N'Active', N'Active', 0);
    UPDATE Layercake.silv_member_year_attributes
    SET payer_type_id = 2, corporate_account_ref = N'SCH-003'
    WHERE contact_no = N'P3' AND campaign_year = 2025;

    SELECT * INTO #P8Before FROM Layercake.silv_data_anomaly WHERE contact_no = N'P8';
    DELETE FROM Layercake.etl_run_log;

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT * INTO #P8After FROM Layercake.silv_data_anomaly WHERE contact_no = N'P8';

    DECLARE @p8_rows int = (SELECT COUNT(*) FROM #P8Before);
    EXEC tSQLt.AssertEquals 1, @p8_rows;
    EXEC tSQLt.AssertEqualsTable '#P8Before', '#P8After';

    DECLARE @p3_rows int = (SELECT COUNT(*) FROM Layercake.silv_data_anomaly WHERE contact_no = N'P3');
    EXEC tSQLt.AssertEquals 0, @p3_rows;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 0, 1)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-015 anomaly rows of other types are left untouched]
AS
BEGIN
    INSERT INTO Layercake.silv_data_anomaly
        (anomaly_nk, anomaly_type, contact_no, source_enr_id, detail, first_detected_at, last_seen_at, resolved_at)
    VALUES (N'NO_TRANSACTIONS:P3', 'NO_TRANSACTIONS', N'P3', NULL, N'Phase 1 row', '2025-01-01T00:00:00', '2025-06-01T00:00:00', NULL),
           (N'EV-P99-2025', 'EVENT_NO_INVOICE', N'P99', NULL, N'Invoice anomaly row', '2025-02-01T00:00:00', '2025-02-01T00:00:00', NULL),
           (N'JOIN_NO_PAYMENT:P98', 'JOIN_NO_PAYMENT', N'P98', NULL, NULL, '2024-01-01T00:00:00', '2024-01-01T00:00:00', '2024-06-01T00:00:00');

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (900301, N'P3', 2025, N'INV-P3-25', N'V-P3-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9003011, N'P3', N'INV-P3-25', N'V-P3-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P3', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P3-2025', 'Renewal', '2024-10-20', N'P3', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P3', 2025, 5, 0, 1, 0, NULL, 1, 0, 900301, 1);

    SELECT * INTO #Before
    FROM Layercake.silv_data_anomaly
    WHERE anomaly_type NOT IN ('CORPORATE_FLAG_NO_SCHEME', 'DOUBLE_PAYMENT', 'CONCESSION_NOT_IN_REFERENCE', 'FULL_CONCESSION_NO_CONCESSION');

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT * INTO #After
    FROM Layercake.silv_data_anomaly
    WHERE anomaly_type NOT IN ('CORPORATE_FLAG_NO_SCHEME', 'DOUBLE_PAYMENT', 'CONCESSION_NOT_IN_REFERENCE', 'FULL_CONCESSION_NO_CONCESSION');

    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    DECLARE @own int =
        (SELECT COUNT(*) FROM Layercake.silv_data_anomaly
         WHERE anomaly_type = 'CORPORATE_FLAG_NO_SCHEME' AND contact_no = N'P3');
    EXEC tSQLt.AssertEquals 1, @own;
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-016 successful run logs Success with the rows inserted]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (900301, N'P3', 2025, N'INV-P3-25', N'V-P3-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0),
           (900801, N'P8', 2025, N'INV-P8-25', N'V-P8-25', '2024-10-15', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9003011, N'P3', N'INV-P3-25', N'V-P3-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9008011, N'P8', N'INV-P8-25', N'V-P8-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9008012, N'P8', NULL, N'PAY-P8-1', N'V-P8-25', '2024-11-01', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Card', 0),
           (9008013, N'P8', NULL, N'PAY-P8-2', N'V-P8-25', '2024-11-02', NULL, NULL, -225.00, -225.00, 225.00, N'GBP', N'Corporate', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P3', 2025, N'Fully Paid'), (N'P8', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P3-2025', 'Renewal', '2024-10-20', N'P3', 2025),
           (2, N'EV-P8-2025', 'Renewal', '2024-10-20', N'P8', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P3', 2025, 5, 0, 1, 0, NULL, 1, 0, 900301, 1),
           (N'P8', 2025, 2, 0, 1, 0, NULL, 1, 0, 900801, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT status, rows_inserted, rows_updated, rows_deleted, error_message,
           CASE WHEN finished_at IS NULL THEN 0 ELSE 1 END AS has_finished
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, rows_inserted, rows_updated, rows_deleted, error_message, has_finished
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 2, 0, 0, CAST(NULL AS nvarchar(4000)), 1))
         AS v(status, rows_inserted, rows_updated, rows_deleted, error_message, has_finished);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD008.[test TC-008-017 failed write rolls back logs Failed and re-raises]
AS
BEGIN
    INSERT INTO Layercake.silv_data_anomaly
        (anomaly_nk, anomaly_type, contact_no, source_enr_id, detail, first_detected_at, last_seen_at, resolved_at)
    VALUES (N'CORPORATE_FLAG_NO_SCHEME:PSTALE:2024', 'CORPORATE_FLAG_NO_SCHEME', N'PSTALE', NULL, N'stale case', '2024-11-01T00:00:00', '2024-11-01T00:00:00', NULL),
           (N'NO_TRANSACTIONS:P3', 'NO_TRANSACTIONS', N'P3', NULL, N'Phase 1 row', '2025-01-01T00:00:00', '2025-06-01T00:00:00', NULL);

    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (900301, N'P3', 2025, N'INV-P3-25', N'V-P3-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0),
           (909901, N'PERR', 2025, N'INV-PERR-25', N'V-PERR-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9003011, N'P3', N'INV-P3-25', N'V-P3-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9099011, N'PERR', N'INV-PERR-25', N'V-PERR-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P3', 2025, N'Fully Paid'), (N'PERR', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P3-2025', 'Renewal', '2024-10-20', N'P3', 2025),
           (2, N'EV-PERR-2025', 'Renewal', '2024-10-20', N'PERR', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P3', 2025, 5, 0, 1, 0, NULL, 1, 0, 900301, 1),
           (N'PERR', 2025, 5, 0, 1, 0, NULL, 1, 0, 909901, 1);

    ALTER TABLE Layercake.silv_data_anomaly
        ADD CONSTRAINT CK_test_MOD008_reject_perr CHECK (contact_no <> N'PERR');

    SELECT * INTO #Before FROM Layercake.silv_data_anomaly;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_data_anomaly_segment;
        EXEC tSQLt.Fail 'Expected the load to raise an error, but it did not.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547
            THROW;
    END CATCH;

    SELECT * INTO #After FROM Layercake.silv_data_anomaly;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT status, CASE WHEN error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT status, has_error_message
    INTO #ExpectedLog
    FROM (VALUES (CAST('Failed' AS varchar(10)), 1)) AS v(status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-018 concession code not in the reference raises one CONCESSION_NOT_IN_REFERENCE row naming the code]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (910401, N'K4', 2025, N'INV-K4-25', N'V-K4-25', '2024-10-15', N'Card', N'GBP', 350.00, N'N', N'Fully Paid', N'Y', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9104011, N'K4', N'INV-K4-25', N'V-K4-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9104012, N'K4', N'INV-K4-25', N'V-K4-25', NULL, '2024-10-15', N'SUB', N'CONUNKNOWN', -100.00, -100.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'K4', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-K4-2025', 'Renewal', '2024-10-20', N'K4', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'K4', 2025, 2, 0, 1, 0, NULL, -1, 0, 910401, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('CONCESSION_NOT_IN_REFERENCE' AS varchar(40)), CAST(N'K4' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @matching int =
        (SELECT COUNT(*)
         FROM Layercake.silv_data_anomaly AS a
         WHERE a.anomaly_nk LIKE N'%K4%'
           AND a.anomaly_nk LIKE N'%2025%'
           AND a.anomaly_nk LIKE N'%CONUNKNOWN%'
           AND a.detail LIKE N'%2025%'
           AND (a.detail LIKE N'%INV-K4-25%' OR a.detail LIKE N'%910401%'));
    EXEC tSQLt.AssertEquals 1, @matching;
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-019 concession codes found in the reference raise no CONCESSION_NOT_IN_REFERENCE]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (910101, N'K1', 2025, N'INV-K1-25', N'V-K1-25', '2024-10-15', N'Card', N'GBP', 0.00, N'N', N'Full Concession', N'Y', N'Y', 0),
           (910301, N'K3', 2025, N'INV-K3-25', N'V-K3-25', '2024-10-15', N'Card', N'GBP', 225.00, N'N', N'Fully Paid', N'Y', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9101011, N'K1', N'INV-K1-25', N'V-K1-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9101012, N'K1', N'INV-K1-25', N'V-K1-25', NULL, '2024-10-15', N'SUB', N'CONRETIRED', -450.00, -450.00, NULL, N'GBP', NULL, 0),
           (9103011, N'K3', N'INV-K3-25', N'V-K3-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9103012, N'K3', N'INV-K3-25', N'V-K3-25', NULL, '2024-10-15', N'SUB', N'CONHARDSHIP', -225.00, -225.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'K1', 2025, N'Full Concession'), (N'K3', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-K1-2025', 'Renewal', '2024-10-20', N'K1', 2025),
           (2, N'EV-K3-2025', 'Renewal', '2024-10-20', N'K3', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'K1', 2025, 2, 0, 1, 0, NULL, 2, 0, 910101, 1),
           (N'K3', 2025, 2, 0, 1, 0, NULL, 3, 0, 910301, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-020 the same unknown code on two lines raises one row]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (910801, N'K8', 2025, N'INV-K8-25', N'V-K8-25', '2024-10-15', N'Card', N'GBP', 350.00, N'N', N'Fully Paid', N'Y', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9108011, N'K8', N'INV-K8-25', N'V-K8-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9108012, N'K8', N'INV-K8-25', N'V-K8-25', NULL, '2024-10-15', N'SUB', N'CONUNKNOWN', -50.00, -50.00, NULL, N'GBP', NULL, 0),
           (9108013, N'K8', N'INV-K8-25', N'V-K8-25', NULL, '2024-10-15', N'SUB', N'CONUNKNOWN', -50.00, -50.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'K8', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-K8-2025', 'Renewal', '2024-10-20', N'K8', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'K8', 2025, 2, 0, 1, 0, NULL, -1, 0, 910801, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('CONCESSION_NOT_IN_REFERENCE' AS varchar(40)), CAST(N'K8' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-021 two different unknown codes on one invoice raise one row per code]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (910901, N'K9', 2025, N'INV-K9-25', N'V-K9-25', '2024-10-15', N'Card', N'GBP', 350.00, N'N', N'Fully Paid', N'Y', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9109011, N'K9', N'INV-K9-25', N'V-K9-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9109012, N'K9', N'INV-K9-25', N'V-K9-25', NULL, '2024-10-15', N'SUB', N'CONUNKNOWN', -50.00, -50.00, NULL, N'GBP', NULL, 0),
           (9109013, N'K9', N'INV-K9-25', N'V-K9-25', NULL, '2024-10-15', N'SUB', N'CONOTHER', -50.00, -50.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'K9', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-K9-2025', 'Renewal', '2024-10-20', N'K9', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'K9', 2025, 2, 0, 1, 0, NULL, -1, 0, 910901, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('CONCESSION_NOT_IN_REFERENCE' AS varchar(40)), CAST(N'K9' AS nvarchar(200))),
                 (CAST('CONCESSION_NOT_IN_REFERENCE' AS varchar(40)), CAST(N'K9' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @unknown int = (SELECT COUNT(*) FROM Layercake.silv_data_anomaly WHERE anomaly_nk LIKE N'%CONUNKNOWN%');
    DECLARE @other int = (SELECT COUNT(*) FROM Layercake.silv_data_anomaly WHERE anomaly_nk LIKE N'%CONOTHER%');
    EXEC tSQLt.AssertEquals 1, @unknown;
    EXEC tSQLt.AssertEquals 1, @other;
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-022 Full Concession position with no concession line raises one FULL_CONCESSION_NO_CONCESSION row]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (910501, N'K5', 2025, N'INV-K5-25', N'V-K5-25', '2024-10-15', N'Card', N'GBP', 0.00, N'N', N'Full Concession', N'N', N'Y', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9105011, N'K5', N'INV-K5-25', N'V-K5-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'K5', 2025, N'Full Concession');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-K5-2025', 'Renewal', '2024-10-20', N'K5', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'K5', 2025, 2, 0, 1, 0, NULL, 1, 0, 910501, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('FULL_CONCESSION_NO_CONCESSION' AS varchar(40)), CAST(N'K5' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @matching int =
        (SELECT COUNT(*)
         FROM Layercake.silv_data_anomaly AS a
         WHERE a.anomaly_nk LIKE N'%K5%'
           AND a.anomaly_nk LIKE N'%2025%'
           AND a.detail LIKE N'%2025%'
           AND (a.detail LIKE N'%INV-K5-25%' OR a.detail LIKE N'%910501%'));
    EXEC tSQLt.AssertEquals 1, @matching;
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-023 Full Concession position with only a reduced concession raises the row]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (910601, N'K6', 2025, N'INV-K6-25', N'V-K6-25', '2024-10-15', N'Card', N'GBP', 0.00, N'N', N'Full Concession', N'Y', N'Y', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9106011, N'K6', N'INV-K6-25', N'V-K6-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9106012, N'K6', N'INV-K6-25', N'V-K6-25', NULL, '2024-10-15', N'SUB', N'CONHARDSHIP', -225.00, -225.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'K6', 2025, N'Full Concession');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-K6-2025', 'Renewal', '2024-10-20', N'K6', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'K6', 2025, 2, 0, 1, 0, NULL, 3, 0, 910601, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('FULL_CONCESSION_NO_CONCESSION' AS varchar(40)), CAST(N'K6' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-024 full-rate concession or a non Full Concession position raises no FULL_CONCESSION_NO_CONCESSION]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (910101, N'K1', 2025, N'INV-K1-25', N'V-K1-25', '2024-10-15', N'Card', N'GBP', 0.00, N'N', N'Full Concession', N'Y', N'Y', 0),
           (910201, N'K2', 2025, N'INV-K2-25', N'V-K2-25', '2024-10-15', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9101011, N'K1', N'INV-K1-25', N'V-K1-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9101012, N'K1', N'INV-K1-25', N'V-K1-25', NULL, '2024-10-15', N'SUB', N'CONRETIRED', -450.00, -450.00, NULL, N'GBP', NULL, 0),
           (9102011, N'K2', N'INV-K2-25', N'V-K2-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'K1', 2025, N'Full Concession'), (N'K2', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-K1-2025', 'Renewal', '2024-10-20', N'K1', 2025),
           (2, N'EV-K2-2025', 'Renewal', '2024-10-20', N'K2', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'K1', 2025, 2, 0, 1, 0, NULL, 2, 0, 910101, 1),
           (N'K2', 2025, 2, 0, 1, 0, NULL, 1, 0, 910201, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-025 every Full Concession position has a full-rate concession or an anomaly row]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (910101, N'K1', 2025, N'INV-K1-25', N'V-K1-25', '2024-10-15', N'Card', N'GBP', 0.00, N'N', N'Full Concession', N'Y', N'Y', 0),
           (910201, N'K2', 2025, N'INV-K2-25', N'V-K2-25', '2024-10-15', N'Card', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0),
           (910501, N'K5', 2025, N'INV-K5-25', N'V-K5-25', '2024-10-15', N'Card', N'GBP', 0.00, N'N', N'Full Concession', N'N', N'Y', 0),
           (910601, N'K6', 2025, N'INV-K6-25', N'V-K6-25', '2024-10-15', N'Card', N'GBP', 0.00, N'N', N'Full Concession', N'Y', N'Y', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9101011, N'K1', N'INV-K1-25', N'V-K1-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9101012, N'K1', N'INV-K1-25', N'V-K1-25', NULL, '2024-10-15', N'SUB', N'CONRETIRED', -450.00, -450.00, NULL, N'GBP', NULL, 0),
           (9102011, N'K2', N'INV-K2-25', N'V-K2-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9105011, N'K5', N'INV-K5-25', N'V-K5-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9106011, N'K6', N'INV-K6-25', N'V-K6-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0),
           (9106012, N'K6', N'INV-K6-25', N'V-K6-25', NULL, '2024-10-15', N'SUB', N'CONHARDSHIP', -225.00, -225.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'K1', 2025, N'Full Concession'), (N'K2', 2025, N'Fully Paid'),
           (N'K5', 2025, N'Full Concession'), (N'K6', 2025, N'Full Concession');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-K1-2025', 'Renewal', '2024-10-20', N'K1', 2025),
           (2, N'EV-K2-2025', 'Renewal', '2024-10-20', N'K2', 2025),
           (3, N'EV-K5-2025', 'Renewal', '2024-10-20', N'K5', 2025),
           (4, N'EV-K6-2025', 'Renewal', '2024-10-20', N'K6', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'K1', 2025, 2, 0, 1, 0, NULL, 2, 0, 910101, 1),
           (N'K2', 2025, 2, 0, 1, 0, NULL, 1, 0, 910201, 1),
           (N'K5', 2025, 2, 0, 1, 0, NULL, 1, 0, 910501, 1),
           (N'K6', 2025, 2, 0, 1, 0, NULL, 3, 0, 910601, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    DECLARE @positions int =
        (SELECT COUNT(*) FROM Layercake.silv_payment_events WHERE invoice_position = N'Full Concession');
    EXEC tSQLt.AssertEquals 3, @positions;

    DECLARE @exceptions int =
        (SELECT COUNT(*)
         FROM Layercake.silv_payment_events AS p
         INNER JOIN Layercake.silv_member_year_attributes AS y
             ON y.contact_no = p.contact_no AND y.campaign_year = p.campaign_year
         INNER JOIN Layercake.silv_ref_concession_type AS c
             ON c.id = y.concession_type_id
         WHERE p.invoice_position = N'Full Concession'
           AND c.is_full_concession = 0
           AND NOT EXISTS (SELECT 1 FROM Layercake.silv_data_anomaly AS a
                           WHERE a.anomaly_type = 'FULL_CONCESSION_NO_CONCESSION'
                             AND a.contact_no = p.contact_no));
    EXEC tSQLt.AssertEquals 0, @exceptions;

    DECLARE @flagged int =
        (SELECT COUNT(*) FROM Layercake.silv_data_anomaly WHERE anomaly_type = 'FULL_CONCESSION_NO_CONCESSION');
    EXEC tSQLt.AssertEquals 2, @flagged;
END;
GO

CREATE PROCEDURE test_MOD008.[test TC-008-026 subscription with a NULL Sub Status is not live and the flag is raised]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice
        (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency,
         full_invoice_amount_cur, fully_credited, payment_status, has_concession, full_concession_flag, _is_deleted)
    VALUES (901801, N'P18', 2025, N'INV-P18-25', N'V-P18-25', '2024-10-15', N'Corporate', N'GBP', 450.00, N'N', N'Fully Paid', N'N', N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, transdate, ricinvoicetype, productcode,
         amountcur, amountmst, settleamountcur, currencycode, paymmode, _is_deleted)
    VALUES (9018011, N'P18', N'INV-P18-25', N'V-P18-25', NULL, '2024-10-15', N'SUB', N'SUBS', 450.00, 450.00, NULL, N'GBP', NULL, 0);
    INSERT INTO Layercake.brnz_corporate_subscription
        (contact_no, scheme_no, scheme_name, sub_campaign_year, sub_status, sub_user_status, _is_deleted)
    VALUES (N'P18', N'SCH-018', N'Scheme 18', 2025, NULL, N'Active', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'P18', 2025, N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'EV-P18-2025', 'Renewal', '2024-10-20', N'P18', 2025);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'P18', 2025, 5, 0, 1, 0, NULL, 1, 0, 901801, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST('CORPORATE_FLAG_NO_SCHEME' AS varchar(40)), CAST(N'P18' AS nvarchar(200)))) AS v(anomaly_type, contact_no);

    SELECT anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
