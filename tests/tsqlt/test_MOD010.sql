EXEC tSQLt.NewTestClass 'test_MOD010';
GO

CREATE PROCEDURE test_MOD010.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_invoice_line_type';
    EXEC tSQLt.FakeTable 'Layercake.silv_event_amount', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_invoice_line_type (item_code, ric_invoice_type, line_type)
    VALUES (N'SUBS_MRICS', N'SUB', 'subscription'),
           (N'RAFEE_MRICS', N'SUB', 'readmission fee'),
           (N'ENROLFEE', N'APP', 'enrolment or application fee'),
           (N'VATUK', N'TAX', 'tax'),
           (N'CONRETIRED', N'SUB', 'concession'),
           (N'CONEXCEPTIONHP', N'SUB', 'concession');
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-001 renewal carries inv total amount not the invoice lines]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (11, N'RN:A1:2025', 'Renewal', '2024-11-05', N'A1', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'A1', 2025, 'Fully Paid', '2024-11-05', 450.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (101, N'A1', 2025, N'INV-A1', N'V101', '2024-10-20', N'DD', N'GBP', 540.00, 540.00, 540.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, currencycode, _is_deleted)
    VALUES (1011, N'A1', N'INV-A1', N'V101', '2024-10-20', N'SUB', N'SUBS_MRICS', 450.00, 450.00, N'GBP', 0),
           (1012, N'A1', N'INV-A1', N'V101', '2024-10-20', N'TAX', N'VATUK', 90.00, 90.00, N'GBP', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:A1:2025', 11, N'A1', 'Renewal', '2024-11-05', 2025, 101, 'Matched', 450.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-002 readmission amount does not add the readmission fee]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (21, N'RA:RA1:2025', 'Readmission', '2025-03-10', N'RA1', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'RA1', 2025, 'Fully Paid', '2025-03-10', 450.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (201, N'RA1', 2025, N'INV-RA1', N'V201', '2025-03-01', N'Card', N'GBP', 550.00, 550.00, 550.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, currencycode, _is_deleted)
    VALUES (2011, N'RA1', N'INV-RA1', N'V201', '2025-03-01', N'SUB', N'SUBS_MRICS', 450.00, 450.00, N'GBP', 0),
           (2012, N'RA1', N'INV-RA1', N'V201', '2025-03-01', N'SUB', N'RAFEE_MRICS', 100.00, 100.00, N'GBP', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RA:RA1:2025', 21, N'RA1', 'Readmission', '2025-03-10', 2025, 201, 'Matched', 450.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-003 join takes the amount of its first paid position year]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (31, N'JR:J3', 'Join', '2024-06-15', N'J3', 2024);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj)
    VALUES (N'J3', 2025, '2024-11-01', '2024-11-01'),
           (N'J3', 2026, '2025-11-01', '2025-11-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'J3', 2025, 'Fully Paid', '2024-11-01', 200.00, 0),
           (N'J3', 2026, 'Fully Paid', '2025-11-01', 210.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (301, N'J3', 2025, N'INV-J3A', N'V301', '2024-10-20', N'DD', N'GBP', 250.00, 250.00, 250.00, N'N', 0),
           (302, N'J3', 2026, N'INV-J3B', N'V302', '2025-10-20', N'DD', N'GBP', 210.00, 210.00, 210.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, currencycode, _is_deleted)
    VALUES (3011, N'J3', N'INV-J3A', N'V301', '2024-10-20', N'SUB', N'SUBS_MRICS', 200.00, 200.00, N'GBP', 0),
           (3012, N'J3', N'INV-J3A', N'V301', '2024-10-20', N'APP', N'ENROLFEE', 50.00, 50.00, N'GBP', 0),
           (3021, N'J3', N'INV-J3B', N'V302', '2025-10-20', N'SUB', N'SUBS_MRICS', 210.00, 210.00, N'GBP', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'JR:J3', 31, N'J3', 'Join', '2024-06-15', 2025, 301, 'Matched', 200.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-004 join with no paid position uses its own campaign year]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (41, N'JR:J4', 'Join', '2024-12-01', N'J4', 2025);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj)
    VALUES (N'J9', 2024, '2023-11-01', '2023-11-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'J4', 2025, 'No Payment', NULL, 450.00, 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'JR:J4', 41, N'J4', 'Join', '2024-12-01', 2025, NULL, 'No eligible invoice', 450.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-005 EUR invoice renewal carries the GBP inv total amount]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (51, N'RN:E1:2025', 'Renewal', '2024-11-05', N'E1', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'E1', 2025, 'Fully Paid', '2024-11-05', 430.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (501, N'E1', 2025, N'INV-E1', N'V501', '2024-10-20', N'DD', N'EUR', 500.00, 430.00, 500.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, currencycode, _is_deleted)
    VALUES (5011, N'E1', N'INV-E1', N'V501', '2024-10-20', N'SUB', N'SUBS_MRICS', 500.00, 430.00, N'EUR', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:E1:2025', 51, N'E1', 'Renewal', '2024-11-05', 2025, 501, 'Matched', 430.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-006 full concession carries 0 not null]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (61, N'RN:F1:2025', 'Renewal', '2024-11-05', N'F1', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'F1', 2025, 'Full Concession', '2024-11-05', 0.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (601, N'F1', 2025, N'INV-F1', N'V601', '2024-10-20', NULL, N'GBP', 0.00, 0.00, 0.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, currencycode, _is_deleted)
    VALUES (6011, N'F1', N'INV-F1', N'V601', '2024-10-20', N'SUB', N'SUBS_MRICS', 450.00, 450.00, N'GBP', 0),
           (6012, N'F1', N'INV-F1', N'V601', '2024-10-20', N'SUB', N'CONRETIRED', -450.00, -450.00, N'GBP', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:F1:2025', 61, N'F1', 'Renewal', '2024-11-05', 2025, 601, 'Matched', 0.00, 'Full Concession')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-007 no live status row or null amount gives No invoice]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (71, N'RN:C1:2025', 'Renewal', '2024-11-05', N'C1', 2025),
           (72, N'RN:C2:2025', 'Renewal', '2024-11-05', N'C2', 2025),
           (73, N'RN:C3:2025', 'Renewal', '2024-11-05', N'C3', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'C2', 2025, 'Fully Paid', '2024-11-05', 450.00, 1),
           (N'C3', 2025, 'Fully Paid', '2024-11-05', NULL, 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:C1:2025', 71, N'C1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', NULL, 'No invoice'),
                 (N'RN:C2:2025', 72, N'C2', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', NULL, 'No invoice'),
                 (N'RN:C3:2025', 73, N'C3', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', NULL, 'No invoice')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-008 status row of another year or another contact supplies no amount]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (81, N'RN:N4:2025', 'Renewal', '2024-11-05', N'N4', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'N4', 2024, 'Fully Paid', '2023-11-05', 300.00, 0),
           (N'N5', 2025, 'Fully Paid', '2024-11-05', 450.00, 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:N4:2025', 81, N'N4', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', NULL, 'No invoice')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-009 fully credited invoice left out of amount and match]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (91, N'RN:V1:2025', 'Renewal', '2024-11-05', N'V1', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'V1', 2025, 'Fully Paid', '2024-11-05', 420.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (901, N'V1', 2025, N'INV-A', N'V901', '2024-10-01', N'DD', N'GBP', 400.00, 400.00, 400.00, N'Y', 0),
           (902, N'V1', 2025, N'INV-B', N'V902', '2024-10-20', N'DD', N'GBP', 420.00, 420.00, 420.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:V1:2025', 91, N'V1', 'Renewal', '2024-11-05', 2025, 902, 'Matched', 420.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-010 corporate funded renewal carries its own status amount]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (101, N'RN:CO1:2025', 'Renewal', '2024-11-05', N'CO1', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'CO1', 2025, 'Fully Paid', '2024-11-05', 380.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (1001, N'CO1', 2025, N'INV-CO1', N'V1001', '2024-10-20', N'Corporate', N'GBP', 450.00, 450.00, 450.00, N'N', 0),
           (1002, N'FIRM01', 2025, N'INV-FIRM', N'V1002', '2024-10-20', N'Corporate', N'GBP', -70.00, -70.00, -70.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:CO1:2025', 101, N'CO1', 'Renewal', '2024-11-05', 2025, 1001, 'Matched', 380.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-011 R1 readmission carries the year amount and each event matches its own invoice]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (111, N'RN:R1:2025', 'Renewal', '2024-11-05', N'R1', 2025),
           (112, N'RA:R1:2025', 'Readmission', '2025-03-10', N'R1', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'R1', 2025, 'Fully Paid', '2024-11-05', 900.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (1101, N'R1', 2025, N'INV-1', N'V1101', '2024-10-20', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 0),
           (1102, N'R1', 2025, N'INV-2', N'V1102', '2025-03-01', N'Card', N'GBP', 550.00, 450.00, 550.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, currencycode, _is_deleted)
    VALUES (11011, N'R1', N'INV-1', N'V1101', '2024-10-20', N'SUB', N'SUBS_MRICS', 450.00, 450.00, N'GBP', 0),
           (11021, N'R1', N'INV-2', N'V1102', '2025-03-01', N'SUB', N'SUBS_MRICS', 450.00, 450.00, N'GBP', 0),
           (11022, N'R1', N'INV-2', N'V1102', '2025-03-01', N'SUB', N'RAFEE_MRICS', 100.00, 100.00, N'GBP', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:R1:2025', 111, N'R1', 'Renewal', '2024-11-05', 2025, 1101, 'Matched', NULL, 'Counted on another event'),
                 (N'RA:R1:2025', 112, N'R1', 'Readmission', '2025-03-10', 2025, 1102, 'Matched', 900.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-012 R2 one invoice two events goes to the readmission and renewal is shortfall]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (121, N'RN:R2:2025', 'Renewal', '2024-11-05', N'R2', 2025),
           (122, N'RA:R2:2025', 'Readmission', '2025-03-10', N'R2', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'R2', 2025, 'Fully Paid', '2024-11-05', 450.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (1201, N'R2', 2025, N'INV-3', N'V1201', '2024-10-25', N'DD', N'GBP', 550.00, 450.00, 550.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, currencycode, _is_deleted)
    VALUES (12011, N'R2', N'INV-3', N'V1201', '2024-10-25', N'SUB', N'SUBS_MRICS', 450.00, 450.00, N'GBP', 0),
           (12012, N'R2', N'INV-3', N'V1201', '2024-10-25', N'SUB', N'RAFEE_MRICS', 100.00, 100.00, N'GBP', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:R2:2025', 121, N'R2', 'Renewal', '2024-11-05', 2025, NULL, 'Invoice shortfall', NULL, 'Counted on another event'),
                 (N'RA:R2:2025', 122, N'R2', 'Readmission', '2025-03-10', 2025, 1201, 'Matched', 450.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-013 R3 one event two invoices carries 820 and matches the latest invoice]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (131, N'RN:R3:2025', 'Renewal', '2024-11-05', N'R3', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'R3', 2025, 'Fully Paid', '2024-10-05', 820.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (1301, N'R3', 2025, N'INV-4', N'V1301', '2024-10-01', N'DD', N'GBP', 400.00, 400.00, 400.00, N'N', 0),
           (1302, N'R3', 2025, N'INV-5', N'V1302', '2024-12-01', N'DD', N'GBP', 420.00, 420.00, 420.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:R3:2025', 131, N'R3', 'Renewal', '2024-11-05', 2025, 1302, 'Matched', 820.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-014 three events two invoices go to readmission and earliest renewal paired by date]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (141, N'RN:S1:2025:1', 'Renewal', '2024-10-15', N'S1', 2025),
           (142, N'RN:S1:2025:2', 'Renewal', '2024-12-01', N'S1', 2025),
           (143, N'RA:S1:2025', 'Readmission', '2025-02-01', N'S1', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'S1', 2025, 'Fully Paid', '2024-10-15', 900.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (1401, N'S1', 2025, N'INV-S1A', N'V1401', '2024-10-01', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 0),
           (1402, N'S1', 2025, N'INV-S1B', N'V1402', '2025-01-15', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:S1:2025:1', 141, N'S1', 'Renewal', '2024-10-15', 2025, 1401, 'Matched', NULL, 'Counted on another event'),
                 (N'RN:S1:2025:2', 142, N'S1', 'Renewal', '2024-12-01', 2025, NULL, 'Invoice shortfall', NULL, 'Counted on another event'),
                 (N'RA:S1:2025', 143, N'S1', 'Readmission', '2025-02-01', 2025, 1402, 'Matched', 900.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-015 two events three invoices pair with the latest invoices by date]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (151, N'RN:S2:2025:1', 'Renewal', '2024-10-15', N'S2', 2025),
           (152, N'RN:S2:2025:2', 'Renewal', '2025-02-01', N'S2', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'S2', 2025, 'Fully Paid', '2024-10-15', 1290.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (1501, N'S2', 2025, N'INV-S2A', N'V1501', '2024-10-01', N'DD', N'GBP', 430.00, 430.00, 430.00, N'N', 0),
           (1502, N'S2', 2025, N'INV-S2B', N'V1502', '2024-11-01', N'DD', N'GBP', 430.00, 430.00, 430.00, N'N', 0),
           (1503, N'S2', 2025, N'INV-S2C', N'V1503', '2025-01-15', N'DD', N'GBP', 430.00, 430.00, 430.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:S2:2025:1', 151, N'S2', 'Renewal', '2024-10-15', 2025, 1502, 'Matched', 1290.00, 'Invoiced'),
                 (N'RN:S2:2025:2', 152, N'S2', 'Renewal', '2025-02-01', 2025, 1503, 'Matched', NULL, 'Counted on another event')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-016 match ties go by event_nk and rec_id while the amount tie goes to lowest event_id]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (161, N'RN:S3:2025', 'Renewal', '2024-11-05', N'S3', 2025),
           (163, N'RN:S4:2025:b', 'Renewal', '2024-11-05', N'S4', 2025),
           (164, N'RN:S4:2025:a', 'Renewal', '2024-11-05', N'S4', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'S3', 2025, 'Fully Paid', '2024-11-05', 450.00, 0),
           (N'S4', 2025, 'Fully Paid', '2024-11-05', 600.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (1601, N'S3', 2025, N'INV-S3A', N'V1601', '2024-10-20', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 0),
           (1602, N'S3', 2025, N'INV-S3B', N'V1602', '2024-10-20', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 0),
           (1611, N'S4', 2025, N'INV-S4A', N'V1611', '2024-10-01', N'DD', N'GBP', 300.00, 300.00, 300.00, N'N', 0),
           (1612, N'S4', 2025, N'INV-S4B', N'V1612', '2024-12-01', N'DD', N'GBP', 300.00, 300.00, 300.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:S3:2025', 161, N'S3', 'Renewal', '2024-11-05', 2025, 1602, 'Matched', 450.00, 'Invoiced'),
                 (N'RN:S4:2025:a', 164, N'S4', 'Renewal', '2024-11-05', 2025, 1611, 'Matched', NULL, 'Counted on another event'),
                 (N'RN:S4:2025:b', 163, N'S4', 'Renewal', '2024-11-05', 2025, 1612, 'Matched', 600.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-017 R4 only invoice fully credited gives 0 and Fully credited]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (171, N'RN:R4:2025', 'Renewal', '2024-11-05', N'R4', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'R4', 2025, 'Fully Credited', NULL, 0.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (1701, N'R4', 2025, N'INV-R4', N'V1701', '2024-10-20', N'DD', N'GBP', 300.00, 300.00, 300.00, N'Y', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:R4:2025', 171, N'R4', 'Renewal', '2024-11-05', 2025, 1701, 'Matched', 0.00, 'Fully credited')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-018 R5 later CRE credit note changes neither amount nor match]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (181, N'RN:R5:2025', 'Renewal', '2024-11-05', N'R5', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'R5', 2025, 'Fully Paid', '2024-11-05', 450.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (1801, N'R5', 2025, N'INV-6', N'V1801', '2024-10-15', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 0),
           (1802, N'R5', 2025, N'CRE-0002', N'V1802', '2024-12-01', N'DD', N'GBP', -100.00, -100.00, -100.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:R5:2025', 181, N'R5', 'Renewal', '2024-11-05', 2025, 1801, 'Matched', 450.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-019 unmapped line code still gives Invoiced]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (191, N'RN:NF1:2025', 'Renewal', '2024-11-05', N'NF1', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'NF1', 2025, 'Fully Paid', '2024-11-05', 450.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (1901, N'NF1', 2025, N'INV-NF1', N'V1901', '2024-10-20', N'DD', N'GBP', 475.00, 475.00, 475.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, currencycode, _is_deleted)
    VALUES (19011, N'NF1', N'INV-NF1', N'V1901', '2024-10-20', N'SUB', N'SUBS_MRICS', 450.00, 450.00, N'GBP', 0),
           (19012, N'NF1', N'INV-NF1', N'V1901', '2024-10-20', N'SUB', N'NEWFEE', 25.00, 25.00, N'GBP', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:NF1:2025', 191, N'NF1', 'Renewal', '2024-11-05', 2025, 1901, 'Matched', 450.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-020 campaign year 2021 events are Before invoice data with no amount or match]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (201, N'RN:P1:2021', 'Renewal', '2020-11-05', N'P1', 2021),
           (202, N'RA:P1:2021', 'Readmission', '2021-03-10', N'P1', 2021);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'P1', 2021, 'Fully Paid', '2020-11-05', 300.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (2001, N'P1', 2021, N'INV-P1', N'V2001', '2020-10-20', N'DD', N'GBP', 300.00, 300.00, 300.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:P1:2021', 201, N'P1', 'Renewal', '2020-11-05', 2021, NULL, 'Before invoice data', NULL, 'Before invoice data'),
                 (N'RA:P1:2021', 202, N'P1', 'Readmission', '2021-03-10', 2021, NULL, 'Before invoice data', NULL, 'Before invoice data')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-021 amount campaign year 2022 is invoice data including a 2021 join paid in 2022]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (211, N'RN:B1:2022', 'Renewal', '2021-11-01', N'B1', 2022),
           (212, N'JR:B2', 'Join', '2021-08-01', N'B2', 2021),
           (213, N'JR:B3', 'Join', '2021-08-01', N'B3', 2021);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj)
    VALUES (N'B2', 2022, '2021-11-01', '2021-11-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'B1', 2022, 'Fully Paid', '2021-11-01', 300.00, 0),
           (N'B2', 2022, 'Fully Paid', '2021-11-01', 250.00, 0),
           (N'B3', 2021, 'No Payment', NULL, 300.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (2101, N'B1', 2022, N'INV-B1', N'V2101', '2021-10-20', N'DD', N'GBP', 300.00, 300.00, 300.00, N'N', 0),
           (2102, N'B2', 2022, N'INV-B2', N'V2102', '2021-10-20', N'DD', N'GBP', 250.00, 250.00, 250.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:B1:2022', 211, N'B1', 'Renewal', '2021-11-01', 2022, 2101, 'Matched', 300.00, 'Invoiced'),
                 (N'JR:B2', 212, N'B2', 'Join', '2021-08-01', 2022, 2102, 'Matched', 250.00, 'Invoiced'),
                 (N'JR:B3', 213, N'B3', 'Join', '2021-08-01', 2021, NULL, 'Before invoice data', NULL, 'Before invoice data')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-022 R1 R2 R3 event amounts total 2170 with one amount event per contact year]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (111, N'RN:R1:2025', 'Renewal', '2024-11-05', N'R1', 2025),
           (112, N'RA:R1:2025', 'Readmission', '2025-03-10', N'R1', 2025),
           (121, N'RN:R2:2025', 'Renewal', '2024-11-05', N'R2', 2025),
           (122, N'RA:R2:2025', 'Readmission', '2025-03-10', N'R2', 2025),
           (131, N'RN:R3:2025', 'Renewal', '2024-11-05', N'R3', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'R1', 2025, 'Fully Paid', '2024-11-05', 900.00, 0),
           (N'R2', 2025, 'Fully Paid', '2024-11-05', 450.00, 0),
           (N'R3', 2025, 'Fully Paid', '2024-10-05', 820.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (1101, N'R1', 2025, N'INV-1', N'V1101', '2024-10-20', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 0),
           (1102, N'R1', 2025, N'INV-2', N'V1102', '2025-03-01', N'Card', N'GBP', 550.00, 450.00, 550.00, N'N', 0),
           (1201, N'R2', 2025, N'INV-3', N'V1201', '2024-10-25', N'DD', N'GBP', 550.00, 450.00, 550.00, N'N', 0),
           (1301, N'R3', 2025, N'INV-4', N'V1301', '2024-10-01', N'DD', N'GBP', 400.00, 400.00, 400.00, N'N', 0),
           (1302, N'R3', 2025, N'INV-5', N'V1302', '2024-12-01', N'DD', N'GBP', 420.00, 420.00, 420.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    DECLARE @ExpectedTotal decimal(19,4) = 2170.00;
    DECLARE @InvoicedTotal decimal(19,4) = (SELECT SUM(invoiced_subtotal_gbp) FROM Layercake.silv_event_amount);
    DECLARE @SubsTotal decimal(19,4) = (SELECT SUM(subs_amount_gbp) FROM Layercake.silv_event_amount);
    DECLARE @AmountEvents int = (SELECT COUNT(*) FROM Layercake.silv_event_amount WHERE invoiced_subtotal_gbp IS NOT NULL);
    DECLARE @BadContactYears int =
        (SELECT COUNT(*)
         FROM (SELECT contact_no, amount_campaign_year
               FROM Layercake.silv_event_amount
               GROUP BY contact_no, amount_campaign_year
               HAVING SUM(CASE WHEN invoiced_subtotal_gbp IS NOT NULL THEN 1 ELSE 0 END) <> 1) AS x);

    EXEC tSQLt.AssertEquals @Expected = @ExpectedTotal, @Actual = @InvoicedTotal, @Message = 'invoiced_subtotal_gbp total';
    EXEC tSQLt.AssertEquals @Expected = @ExpectedTotal, @Actual = @SubsTotal, @Message = 'subs_amount_gbp total';
    EXEC tSQLt.AssertEquals @Expected = 3, @Actual = @AmountEvents, @Message = 'events carrying an amount';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @BadContactYears, @Message = 'contact-years without exactly one amount event';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-023 every join renewal readmission has a status and equal amounts]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (231, N'JR:M1', 'Join', '2024-06-01', N'M1', 2024),
           (232, N'RN:M1:2025', 'Renewal', '2024-11-05', N'M1', 2025),
           (233, N'RN:M2:2021', 'Renewal', '2020-11-05', N'M2', 2021),
           (234, N'RN:M3:2025', 'Renewal', '2024-11-05', N'M3', 2025),
           (235, N'RA:M4:2025', 'Readmission', '2025-03-10', N'M4', 2025),
           (236, N'RN:M5:2025', 'Renewal', '2024-11-05', N'M5', 2025),
           (237, N'CH:M6:2025', 'Change', '2025-01-15', N'M6', 2025),
           (238, N'LP:M6:2025', 'Lapse', '2025-05-01', N'M6', 2025),
           (239, N'RN:M7:2025', 'Renewal', '2024-11-05', N'M7', 2025),
           (240, N'RA:M7:2025', 'Readmission', '2025-03-10', N'M7', 2025);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj)
    VALUES (N'M1', 2025, '2024-11-05', '2024-11-05');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'M1', 2025, 'Fully Paid', '2024-11-05', 450.00, 0),
           (N'M2', 2021, 'Fully Paid', '2020-11-05', 300.00, 0),
           (N'M4', 2025, 'Fully Paid', '2025-03-10', 450.00, 1),
           (N'M5', 2025, 'Fully Paid', '2024-11-05', NULL, 0),
           (N'M6', 2025, 'Fully Paid', '2024-11-05', 450.00, 0),
           (N'M7', 2025, 'Full Concession', '2024-11-05', 0.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (2301, N'M1', 2025, N'INV-M1', N'V2301', '2024-10-20', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    DECLARE @Rows int = (SELECT COUNT(*) FROM Layercake.silv_event_amount);
    DECLARE @NullStatus int = (SELECT COUNT(*) FROM Layercake.silv_event_amount WHERE amount_status IS NULL);
    DECLARE @Mismatch int =
        (SELECT COUNT(*) FROM Layercake.silv_event_amount
         WHERE subs_amount_gbp <> invoiced_subtotal_gbp
            OR (subs_amount_gbp IS NULL AND invoiced_subtotal_gbp IS NOT NULL)
            OR (subs_amount_gbp IS NOT NULL AND invoiced_subtotal_gbp IS NULL));
    DECLARE @MissingEvents int =
        (SELECT COUNT(*) FROM Layercake.silv_membership_events AS e
         WHERE e.event_type IN ('Join', 'Renewal', 'Readmission')
           AND NOT EXISTS (SELECT 1 FROM Layercake.silv_event_amount AS a WHERE a.event_nk = e.event_nk));

    EXEC tSQLt.AssertEquals @Expected = 8, @Actual = @Rows, @Message = 'one row per Join, Renewal and Readmission';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @MissingEvents, @Message = 'Join, Renewal or Readmission events without a row';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @NullStatus, @Message = 'rows with a null amount_status';
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @Mismatch, @Message = 'rows where subs_amount_gbp and invoiced_subtotal_gbp differ';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-024 change and lapse events get no row]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (241, N'CH:CL1:2025', 'Change', '2025-01-15', N'CL1', 2025),
           (242, N'LP:CL1:2025', 'Lapse', '2025-05-01', N'CL1', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'CL1', 2025, 'Fully Paid', '2024-11-05', 450.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (2401, N'CL1', 2025, N'INV-CL1', N'V2401', '2024-10-20', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_event_amount';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-025 R6 same type tie goes to earliest date then lowest event_id]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (502, N'RN:R6:2025:502', 'Renewal', '2024-11-05', N'R6', 2025),
           (501, N'RN:R6:2025:501', 'Renewal', '2024-12-01', N'R6', 2025),
           (503, N'RN:R6:2025:503', 'Renewal', '2024-11-05', N'R6', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'R6', 2025, 'Fully Paid', '2024-11-05', 450.00, 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:R6:2025:502', 502, N'R6', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 450.00, 'Invoiced'),
                 (N'RN:R6:2025:501', 501, N'R6', 'Renewal', '2024-12-01', 2025, NULL, 'No eligible invoice', NULL, 'Counted on another event'),
                 (N'RN:R6:2025:503', 503, N'R6', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', NULL, 'Counted on another event')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-026 R7 renewal beats the join that takes amounts from the same year]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (261, N'JR:R7', 'Join', '2024-06-01', N'R7', 2024),
           (262, N'RN:R7:2025', 'Renewal', '2024-11-05', N'R7', 2025);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj)
    VALUES (N'R7', 2025, '2024-11-05', '2024-11-05');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'R7', 2025, 'Fully Paid', '2024-11-05', 500.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (2601, N'R7', 2025, N'INV-R7', N'V2601', '2024-10-20', N'DD', N'GBP', 500.00, 500.00, 500.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'JR:R7', 261, N'R7', 'Join', '2024-06-01', 2025, NULL, 'Invoice shortfall', NULL, 'Counted on another event'),
                 (N'RN:R7:2025', 262, N'R7', 'Renewal', '2024-11-05', 2025, 2601, 'Matched', 500.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-027 R8 no status row gives No invoice on both events]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (271, N'RN:R8:2025', 'Renewal', '2024-11-05', N'R8', 2025),
           (272, N'RA:R8:2025', 'Readmission', '2025-03-10', N'R8', 2025);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:R8:2025', 271, N'R8', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', NULL, 'No invoice'),
                 (N'RA:R8:2025', 272, N'R8', 'Readmission', '2025-03-10', 2025, NULL, 'No eligible invoice', NULL, 'No invoice')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-028 R9 full concession readmission carries 0 and renewal is counted on another event]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (281, N'RN:R9:2025', 'Renewal', '2024-11-05', N'R9', 2025),
           (282, N'RA:R9:2025', 'Readmission', '2025-03-10', N'R9', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'R9', 2025, 'Full Concession', '2025-03-01', 0.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (2801, N'R9', 2025, N'INV-R9', N'V2801', '2025-03-01', NULL, N'GBP', 0.00, 0.00, 0.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, currencycode, _is_deleted)
    VALUES (28011, N'R9', N'INV-R9', N'V2801', '2025-03-01', N'SUB', N'SUBS_MRICS', 450.00, 450.00, N'GBP', 0),
           (28012, N'R9', N'INV-R9', N'V2801', '2025-03-01', N'SUB', N'CONRETIRED', -450.00, -450.00, N'GBP', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:R9:2025', 281, N'R9', 'Renewal', '2024-11-05', 2025, NULL, 'Invoice shortfall', NULL, 'Counted on another event'),
                 (N'RA:R9:2025', 282, N'R9', 'Readmission', '2025-03-10', 2025, 2801, 'Matched', 0.00, 'Full Concession')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-029 other invoice positions are all Invoiced]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (291, N'RN:Q1:2025', 'Renewal', '2024-11-05', N'Q1', 2025),
           (292, N'RN:Q2:2025', 'Renewal', '2024-11-05', N'Q2', 2025),
           (293, N'RN:Q3:2025', 'Renewal', '2024-11-05', N'Q3', 2025),
           (294, N'RN:Q4:2025', 'Renewal', '2024-11-05', N'Q4', 2025),
           (295, N'RN:Q5:2025', 'Renewal', '2024-11-05', N'Q5', 2025),
           (296, N'RN:Q6:2025', 'Renewal', '2024-11-05', N'Q6', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'Q1', 2025, 'Bad Debt Write Off', NULL, 100.00, 0),
           (N'Q2', 2025, 'Zero Value Invoice', NULL, 0.00, 0),
           (N'Q3', 2025, 'No Payment', NULL, 100.00, 0),
           (N'Q4', 2025, 'Partially Paid', '2024-11-05', 100.00, 0),
           (N'Q5', 2025, 'Pre-Subs Payment', '2024-09-15', 100.00, 0),
           (N'Q6', 2025, 'Fully Paid', '2024-11-05', 100.00, 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:Q1:2025', 291, N'Q1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 100.00, 'Invoiced'),
                 (N'RN:Q2:2025', 292, N'Q2', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 0.00, 'Invoiced'),
                 (N'RN:Q3:2025', 293, N'Q3', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 100.00, 'Invoiced'),
                 (N'RN:Q4:2025', 294, N'Q4', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 100.00, 'Invoiced'),
                 (N'RN:Q5:2025', 295, N'Q5', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 100.00, 'Invoiced'),
                 (N'RN:Q6:2025', 296, N'Q6', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 100.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-030 null invoice position with an amount is Invoiced]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (301, N'RN:QN:2025', 'Renewal', '2024-11-05', N'QN', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'QN', 2025, NULL, NULL, 300.00, 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:QN:2025', 301, N'QN', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 300.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-031 invoice and line amounts never set the event amount even after they change]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (311, N'RN:Z1:2025', 'Renewal', '2024-11-05', N'Z1', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'Z1', 2025, 'Fully Paid', '2024-11-05', 450.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (3101, N'Z1', 2025, N'INV-Z1', N'V3101', '2024-10-20', N'DD', N'GBP', 500.00, 500.00, 500.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, currencycode, _is_deleted)
    VALUES (31011, N'Z1', N'INV-Z1', N'V3101', '2024-10-20', N'SUB', N'SUBS_MRICS', 300.00, 300.00, N'GBP', 0),
           (31012, N'Z1', N'INV-Z1', N'V3101', '2024-10-20', N'SUB', N'SUBS_MRICS', 220.00, 220.00, N'GBP', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    UPDATE Layercake.brnz_subs_invoice
    SET invoice_amount_cur = 999.00, invoice_amount_gbp = 999.00, full_invoice_amount_cur = 999.00
    WHERE rec_id = 3101;
    UPDATE Layercake.brnz_subs_invoice_line SET amountcur = 600.00, amountmst = 600.00 WHERE recid = 31011;
    UPDATE Layercake.brnz_subs_invoice_line SET amountcur = 400.00, amountmst = 400.00 WHERE recid = 31012;

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:Z1:2025', 311, N'Z1', 'Renewal', '2024-11-05', 2025, 3101, 'Matched', 450.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT CAST(v.status AS varchar(10)) AS status, CAST(v.ins AS int) AS rows_inserted, CAST(v.upd AS int) AS rows_updated, CAST(v.del AS int) AS rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1, 0, 0), ('Success', 0, 0, 0)) AS v(status, ins, upd, del);

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-032 concession lines reach the amount only through inv total amount]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (321, N'RN:K1:2025', 'Renewal', '2024-11-05', N'K1', 2025),
           (322, N'RN:K6:2025', 'Renewal', '2024-11-05', N'K6', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'K1', 2025, 'Full Concession', '2024-10-20', 0.00, 0),
           (N'K6', 2025, 'Fully Paid', '2024-11-05', 225.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (3201, N'K1', 2025, N'INV-K1', N'V3201', '2024-10-20', NULL, N'GBP', 0.00, 0.00, 0.00, N'N', 0),
           (3202, N'K6', 2025, N'INV-K6', N'V3202', '2024-10-20', N'DD', N'GBP', 225.00, 225.00, 225.00, N'N', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, transdate, ricinvoicetype, productcode, amountcur, amountmst, currencycode, _is_deleted)
    VALUES (32011, N'K1', N'INV-K1', N'V3201', '2024-10-20', N'SUB', N'SUBS_MRICS', 450.00, 450.00, N'GBP', 0),
           (32012, N'K1', N'INV-K1', N'V3201', '2024-10-20', N'SUB', N'CONRETIRED', -450.00, -450.00, N'GBP', 0),
           (32021, N'K6', N'INV-K6', N'V3202', '2024-10-20', N'SUB', N'SUBS_MRICS', 450.00, 450.00, N'GBP', 0),
           (32022, N'K6', N'INV-K6', N'V3202', '2024-10-20', N'SUB', N'CONEXCEPTIONHP', -225.00, -225.00, N'GBP', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:K1:2025', 321, N'K1', 'Renewal', '2024-11-05', 2025, 3201, 'Matched', 0.00, 'Full Concession'),
                 (N'RN:K6:2025', 322, N'K6', 'Renewal', '2024-11-05', 2025, 3202, 'Matched', 225.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-033 rerun on unchanged data changes nothing and logs 0 0 0]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (231, N'JR:M1', 'Join', '2024-06-01', N'M1', 2024),
           (232, N'RN:M1:2025', 'Renewal', '2024-11-05', N'M1', 2025),
           (233, N'RN:M2:2021', 'Renewal', '2020-11-05', N'M2', 2021),
           (234, N'RN:M3:2025', 'Renewal', '2024-11-05', N'M3', 2025),
           (235, N'RA:M4:2025', 'Readmission', '2025-03-10', N'M4', 2025),
           (236, N'RN:M5:2025', 'Renewal', '2024-11-05', N'M5', 2025),
           (237, N'CH:M6:2025', 'Change', '2025-01-15', N'M6', 2025),
           (238, N'LP:M6:2025', 'Lapse', '2025-05-01', N'M6', 2025),
           (239, N'RN:M7:2025', 'Renewal', '2024-11-05', N'M7', 2025),
           (240, N'RA:M7:2025', 'Readmission', '2025-03-10', N'M7', 2025);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj)
    VALUES (N'M1', 2025, '2024-11-05', '2024-11-05');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'M1', 2025, 'Fully Paid', '2024-11-05', 450.00, 0),
           (N'M2', 2021, 'Fully Paid', '2020-11-05', 300.00, 0),
           (N'M4', 2025, 'Fully Paid', '2025-03-10', 450.00, 1),
           (N'M5', 2025, 'Fully Paid', '2024-11-05', NULL, 0),
           (N'M6', 2025, 'Fully Paid', '2024-11-05', 450.00, 0),
           (N'M7', 2025, 'Full Concession', '2024-11-05', 0.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (2301, N'M1', 2025, N'INV-M1', N'V2301', '2024-10-20', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT * INTO #AfterFirst FROM Layercake.silv_event_amount;

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT * INTO #AfterSecond FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#AfterFirst', '#AfterSecond';

    SELECT CAST(v.status AS varchar(10)) AS status, CAST(v.ins AS int) AS rows_inserted, CAST(v.upd AS int) AS rows_updated, CAST(v.del AS int) AS rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 8, 0, 0), ('Success', 0, 0, 0)) AS v(status, ins, upd, del);

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-034 changed row is updated in place and unchanged row untouched]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (341, N'RN:U1:2025', 'Renewal', '2024-11-05', N'U1', 2025),
           (342, N'RN:U2:2025', 'Renewal', '2024-11-05', N'U2', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'U1', 2025, 'Fully Paid', '2024-11-05', 450.00, 0),
           (N'U2', 2025, 'Fully Paid', '2024-11-05', 300.00, 0);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:U1:2025', 341, N'U1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 400.00, 400.00, 'Invoiced', 7, '2020-01-01T00:00:00', '2020-01-01T00:00:00'),
           (N'RN:U2:2025', 342, N'U2', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 300.00, 300.00, 'Invoiced', 7, '2020-01-01T00:00:00', '2020-01-01T00:00:00');

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp,
           CAST(v.st AS varchar(30)) AS amount_status, CAST(v.ca AS datetime2(3)) AS created_at
    INTO #Expected
    FROM (VALUES (N'RN:U1:2025', 450.00, 'Invoiced', '2020-01-01T00:00:00'),
                 (N'RN:U2:2025', 300.00, 'Invoiced', '2020-01-01T00:00:00')
         ) AS v(nk, amt, st, ca);

    SELECT event_nk, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, created_at
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @LogId bigint = (SELECT MAX(log_id) FROM Layercake.etl_run_log);
    DECLARE @U1Refreshed int =
        (SELECT COUNT(*) FROM Layercake.silv_event_amount
         WHERE event_nk = N'RN:U1:2025' AND load_id = @LogId AND updated_at > '2020-01-01T00:00:00');
    DECLARE @U2Untouched int =
        (SELECT COUNT(*) FROM Layercake.silv_event_amount
         WHERE event_nk = N'RN:U2:2025' AND load_id = 7 AND updated_at = '2020-01-01T00:00:00');
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @U1Refreshed, @Message = 'U1 updated_at and load_id refreshed';
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @U2Untouched, @Message = 'U2 left untouched';

    SELECT CAST(v.status AS varchar(10)) AS status, CAST(v.ins AS int) AS rows_inserted, CAST(v.upd AS int) AS rows_updated, CAST(v.del AS int) AS rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1, 0)) AS v(status, ins, upd, del);

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-035 row for an event that no longer exists is deleted]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (351, N'RN:D1:2025', 'Renewal', '2024-11-05', N'D1', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'D1', 2025, 'Fully Paid', '2024-11-05', 450.00, 0),
           (N'D9', 2025, 'Fully Paid', '2024-11-05', 450.00, 0);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:D9:2025', 359, N'D9', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 450.00, 450.00, 'Invoiced', 7, '2020-01-01T00:00:00', '2020-01-01T00:00:00');

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.id AS int) AS event_id, CAST(v.cn AS nvarchar(200)) AS contact_no,
           CAST(v.et AS varchar(20)) AS event_type, CAST(v.ed AS date) AS event_date, CAST(v.acy AS int) AS amount_campaign_year,
           CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:D1:2025', 351, N'D1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 450.00, 'Invoiced')
         ) AS v(nk, id, cn, et, ed, acy, inv, mo, amt, st);

    SELECT event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT CAST(v.status AS varchar(10)) AS status, CAST(v.ins AS int) AS rows_inserted, CAST(v.upd AS int) AS rows_updated, CAST(v.del AS int) AS rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1, 0, 1)) AS v(status, ins, upd, del);

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD010.[test TC-010-036 first load logs Success with counts and stamps load_id]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (361, N'RN:L1:2025', 'Renewal', '2024-11-05', N'L1', 2025),
           (362, N'RA:L2:2025', 'Readmission', '2025-03-10', N'L2', 2025),
           (363, N'JR:L3', 'Join', '2024-12-01', N'L3', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'L1', 2025, 'Fully Paid', '2024-11-05', 450.00, 0),
           (N'L2', 2025, 'Fully Paid', '2025-03-10', 300.00, 0),
           (N'L3', 2025, 'No Payment', NULL, 200.00, 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.status AS varchar(10)) AS status, CAST(v.ins AS int) AS rows_inserted, CAST(v.upd AS int) AS rows_updated, CAST(v.del AS int) AS rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 3, 0, 0)) AS v(status, ins, upd, del);

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    DECLARE @LogId bigint = (SELECT MAX(log_id) FROM Layercake.etl_run_log);
    DECLARE @Finished int = (SELECT COUNT(*) FROM Layercake.etl_run_log WHERE finished_at IS NOT NULL AND error_message IS NULL);
    DECLARE @Stamped int =
        (SELECT COUNT(*) FROM Layercake.silv_event_amount
         WHERE load_id = @LogId AND created_at IS NOT NULL AND updated_at IS NOT NULL);
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @Finished, @Message = 'run log row finished without an error message';
    EXEC tSQLt.AssertEquals @Expected = 3, @Actual = @Stamped, @Message = 'rows stamped with the run log_id and audit dates';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD010.[test TC-010-037 amount overflowing decimal 19 4 fails logs Failed and changes nothing]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (371, N'RN:X1:2025', 'Renewal', '2024-11-05', N'X1', 2025),
           (372, N'RN:X2:2025', 'Renewal', '2024-11-05', N'X2', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'X1', 2025, 'Fully Paid', '2024-11-05', 10000000000000000.000000, 0),
           (N'X2', 2025, 'Fully Paid', '2024-11-05', 300.00, 0);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:X1:2025', 371, N'X1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 400.00, 400.00, 'Invoiced', 7, '2020-01-01T00:00:00', '2020-01-01T00:00:00');

    SELECT * INTO #Before FROM Layercake.silv_event_amount;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_event_amount;
        EXEC tSQLt.Fail 'The load did not raise an error for an amount that overflows decimal(19,4).';
    END TRY
    BEGIN CATCH
        DECLARE @ErrorNumber int = ERROR_NUMBER();
        IF @ErrorNumber <> 8115
            THROW;
    END CATCH;

    SELECT * INTO #After FROM Layercake.silv_event_amount;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    DECLARE @LogRows int = (SELECT COUNT(*) FROM Layercake.etl_run_log);
    DECLARE @FailedRows int = (SELECT COUNT(*) FROM Layercake.etl_run_log WHERE status = 'Failed' AND error_message IS NOT NULL);
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @LogRows, @Message = 'one run log row';
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @FailedRows, @Message = 'run log row Failed with its error message';
END;
GO
