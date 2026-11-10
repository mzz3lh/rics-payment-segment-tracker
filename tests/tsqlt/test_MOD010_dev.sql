EXEC tSQLt.NewTestClass 'test_MOD010_dev';
GO

CREATE PROCEDURE test_MOD010_dev.[SetUp]
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
END;
GO

-- Shortfall between two same-type, same-date events: the invoice goes in event_nk order,
-- while the amount still goes to the lowest event_id.
CREATE PROCEDURE test_MOD010_dev.[test shortfall tie on type and date gives the invoice to the lower event_nk]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:T1:2025:b', 'Renewal', '2024-11-05', N'T1', 2025),
           (2, N'RN:T1:2025:a', 'Renewal', '2024-11-05', N'T1', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'T1', 2025, 'Fully Paid', '2024-11-05', 450.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (10, N'T1', 2025, N'INV-T1', N'VT1', '2024-10-20', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (N'RN:T1:2025:a', 10, 'Matched', NULL, 'Counted on another event'),
                 (N'RN:T1:2025:b', NULL, 'Invoice shortfall', 450.00, 'Invoiced')
         ) AS v(nk, inv, mo, amt, st);

    SELECT event_nk, invoice_rec_id, match_outcome, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

-- RULE-032 read literally: a Join takes the contact's earliest paid position year,
-- even one before the Join's own Campaign Year.
CREATE PROCEDURE test_MOD010_dev.[test join takes the earliest paid year even when it is before its own year]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'JR:T2', 'Join', '2024-06-01', N'T2', 2024);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj)
    VALUES (N'T2', 2023, '2022-11-01', '2022-11-01'),
           (N'T2', 2025, '2024-11-01', '2024-11-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'T2', 2023, 'Fully Paid', '2022-11-01', 300.00, 0),
           (N'T2', 2024, 'Fully Paid', '2023-11-01', 350.00, 0),
           (N'T2', 2025, 'Fully Paid', '2024-11-01', 400.00, 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.acy AS int) AS amount_campaign_year, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS subs_amount_gbp, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.st AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (2023, 'No eligible invoice', 300.00, 'Invoiced')) AS v(acy, mo, amt, st);

    SELECT amount_campaign_year, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

-- An invoice of another Campaign Year, a soft-deleted invoice and a credit note are not
-- this year's eligible invoices, so the event has no eligible invoice.
CREATE PROCEDURE test_MOD010_dev.[test only live eligible invoices of the amount year are matched]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:T3:2025', 'Renewal', '2024-11-05', N'T3', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'T3', 2025, 'Fully Paid', '2024-11-05', 450.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (31, N'T3', 2024, N'INV-T3A', N'VT3A', '2023-10-20', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 0),
           (32, N'T3', 2025, N'INV-T3B', N'VT3B', '2024-10-20', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 1),
           (33, N'T3', 2025, N'CRE-T3', N'VT3C', '2024-12-01', N'DD', N'GBP', -50.00, -50.00, -50.00, N'N', 0);

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp
    INTO #Expected
    FROM (VALUES (NULL, 'No eligible invoice', 450.00)) AS v(inv, mo, amt);

    SELECT invoice_rec_id, match_outcome, invoiced_subtotal_gbp
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD010_dev.[test case only contact_no change is one update]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:T4:2025', 'Renewal', '2024-11-05', N'T4', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'T4', 2025, 'Fully Paid', '2024-11-05', 450.00, 0);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:T4:2025', 1, N't4', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 450.00, 450.00, 'Invoiced', 7, '2020-01-01T00:00:00', '2020-01-01T00:00:00');

    EXEC Layercake.usp_load_silv_event_amount;

    DECLARE @Stored varbinary(400) = (SELECT CAST(contact_no AS varbinary(400)) FROM Layercake.silv_event_amount);
    EXEC tSQLt.AssertEquals @Expected = 0x54003400, @Actual = @Stored, @Message = 'contact_no stored as the event gives it';

    SELECT CAST(v.status AS varchar(10)) AS status, CAST(v.ins AS int) AS rows_inserted, CAST(v.upd AS int) AS rows_updated, CAST(v.del AS int) AS rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1, 0)) AS v(status, ins, upd, del);

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

-- A changed match (a new invoice arrives) is an update like a changed amount; one run
-- that inserts, updates and deletes logs each count.
CREATE PROCEDURE test_MOD010_dev.[test insert update and delete in one run are each counted]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'RN:T5:2025', 'Renewal', '2024-11-05', N'T5', 2025),
           (2, N'RN:T6:2025', 'Renewal', '2024-11-05', N'T6', 2025);
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'T5', 2025, 'Fully Paid', '2024-11-05', 450.00, 0),
           (N'T6', 2025, 'Fully Paid', '2024-11-05', 300.00, 0);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, trans_date, inv_payment_method, inv_currency, invoice_amount_cur, invoice_amount_gbp, full_invoice_amount_cur, fully_credited, _is_deleted)
    VALUES (51, N'T5', 2025, N'INV-T5', N'VT5', '2024-10-20', N'DD', N'GBP', 450.00, 450.00, 450.00, N'N', 0);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:T5:2025', 1, N'T5', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 450.00, 450.00, 'Invoiced', 7, '2020-01-01T00:00:00', '2020-01-01T00:00:00'),
           (N'RN:T9:2025', 9, N'T9', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 100.00, 100.00, 'Invoiced', 7, '2020-01-01T00:00:00', '2020-01-01T00:00:00');

    EXEC Layercake.usp_load_silv_event_amount;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.inv AS bigint) AS invoice_rec_id, CAST(v.mo AS varchar(30)) AS match_outcome,
           CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.ca AS datetime2(3)) AS created_at
    INTO #Expected
    FROM (VALUES (N'RN:T5:2025', 51, 'Matched', 450.00, '2020-01-01T00:00:00'),
                 (N'RN:T6:2025', NULL, 'No eligible invoice', 300.00, NULL)
         ) AS v(nk, inv, mo, amt, ca);

    SELECT event_nk, invoice_rec_id, match_outcome, invoiced_subtotal_gbp,
           CASE WHEN event_nk = N'RN:T5:2025' THEN created_at END AS created_at
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT CAST(v.status AS varchar(10)) AS status, CAST(v.ins AS int) AS rows_inserted, CAST(v.upd AS int) AS rows_updated, CAST(v.del AS int) AS rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 1, 1, 1)) AS v(status, ins, upd, del);

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD010_dev.[test overflowing amount on a join from its paid year fails and leaves the target unchanged]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_date, contact_no, campaign_year)
    VALUES (1, N'JR:T7', 'Join', '2024-06-01', N'T7', 2024),
           (2, N'RN:T8:2025', 'Renewal', '2024-11-05', N'T8', 2025);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj)
    VALUES (N'T7', 2025, '2024-11-01', '2024-11-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], inv_total_amount, _is_deleted)
    VALUES (N'T7', 2025, 'Fully Paid', '2024-11-01', 1000000000000000.000000, 0),
           (N'T8', 2025, 'Fully Paid', '2024-11-05', 300.00, 0);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:T8:2025', 2, N'T8', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 250.00, 250.00, 'Invoiced', 7, '2020-01-01T00:00:00', '2020-01-01T00:00:00');

    BEGIN TRY
        EXEC Layercake.usp_load_silv_event_amount;
        EXEC tSQLt.Fail 'The load did not fail on an amount that overflows decimal(19,4).';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 8115
            THROW;
    END CATCH;

    SELECT CAST(v.nk AS nvarchar(220)) AS event_nk, CAST(v.amt AS decimal(19,4)) AS invoiced_subtotal_gbp,
           CAST(v.lid AS bigint) AS load_id, CAST(v.ua AS datetime2(3)) AS updated_at
    INTO #Expected
    FROM (VALUES (N'RN:T8:2025', 250.00, 7, '2020-01-01T00:00:00')) AS v(nk, amt, lid, ua);

    SELECT event_nk, invoiced_subtotal_gbp, load_id, updated_at
    INTO #Actual
    FROM Layercake.silv_event_amount;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @Failed int =
        (SELECT COUNT(*) FROM Layercake.etl_run_log
         WHERE status = 'Failed' AND finished_at IS NOT NULL AND error_message LIKE N'%(error 8115,%');
    DECLARE @LogRows int = (SELECT COUNT(*) FROM Layercake.etl_run_log);
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @LogRows, @Message = 'one run log row';
    EXEC tSQLt.AssertEquals @Expected = 1, @Actual = @Failed, @Message = 'run log row Failed with error 8115 in its message';
END;
GO
