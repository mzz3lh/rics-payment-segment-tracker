EXEC tSQLt.NewTestClass 'test_MOD012';
GO

CREATE PROCEDURE test_MOD012.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_event_amount', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1;

    INSERT INTO Layercake.dim_payment_method (id, payment_method_name)
    VALUES (0, 'Unknown'), (-1, 'Unrecognised'), (-2, 'Not applicable'), (1, 'Direct Debit'),
           (2, 'Card'), (3, 'Bank transfer'), (4, 'Cheque'), (5, 'Corporate');
    INSERT INTO Layercake.dim_payer_type (id, payer_type_name)
    VALUES (0, 'Unknown'), (-1, 'Unrecognised'), (-2, 'Not applicable'), (1, 'Individual'), (2, 'Corporate');
    INSERT INTO Layercake.dim_concession_type (id, concession_type_name, is_full_concession, is_perpetual)
    VALUES (0, N'Unknown', 0, 0), (-1, N'Unrecognised', 0, 0), (-2, N'Not applicable', 0, 0),
           (1, N'No concession', 0, 0), (2, N'Retired', 1, 1), (3, N'Exceptional Hardship', 0, 0);
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-001 C1 events take payment method and flags from their segment year attributes]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'C1', 2023, 1, 0, 1, 0, NULL, 1, 0, 10001, 1, '2026-01-01', '2026-01-01'),
           (N'C1', 2024, 2, 0, 1, 0, NULL, 1, 0, 10002, 1, '2026-01-01', '2026-01-01'),
           (N'C1', 2025, 2, 1, 1, 1, NULL, 0, 0, NULL, 1, '2026-01-01', '2026-01-01'),
           (N'C1', 2026, 2, 1, 1, 1, NULL, 0, 0, NULL, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'C1', 2023, '2022-11-15', '2022-11-15', N'Fully Paid'),
           (N'C1', 2024, '2023-10-20', '2023-10-20', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (101, N'JR:C1', 'Join', 'Direct Entry', '2022-11-15', N'C1', 2, 1, 2023, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (102, N'CH:C1:2024', 'Change', 'Grade', '2024-01-10', N'C1', 2, 1, 2024, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (103, N'RN:C1:2024', 'Renewal', 'Standard', '2023-10-20', N'C1', 2, 1, 2024, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (104, N'LP:C1:2025', 'Lapse', 'Standard', '2025-05-01', N'C1', 2, 1, 2025, 'Q3', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'JR:C1', 101, N'C1', 'Join', '2022-11-15', 2023, 10001, 'Matched', 400.0000, 400.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01'),
           (N'RN:C1:2024', 103, N'C1', 'Renewal', '2023-10-20', 2024, 10002, 'Matched', 420.0000, 420.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_silv_membership_events_segments;

    SELECT event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried
    INTO #Actual
    FROM Layercake.silv_membership_events;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried, v.concession_type_id, v.concession_type_carried
    INTO #Expected
    FROM (VALUES (101, 1, 0, 1, 0, 1, 0),
                 (102, 2, 0, 1, 0, 1, 0),
                 (103, 2, 0, 1, 0, 1, 0),
                 (104, 2, 1, 1, 1, 0, 0)) AS v(event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-002 event with no attributes row for its contact and year gets 0 keys and 0 flags]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'N1', 2024, 1, 0, 1, 0, NULL, 1, 0, 20001, 1, '2026-01-01', '2026-01-01'),
           (N'N2', 2025, 2, 0, 1, 0, NULL, 2, 0, 20002, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (201, N'RN:N1:2025', 'Renewal', 'Standard', '2024-11-05', N'N1', 2, 1, 2025, 'Q1', 2, 1, 1, 1, 2, 1, NULL, NULL, NULL),
           (202, N'CH:N3:2025', 'Change', 'Grade', '2025-02-01', N'N3', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:N1:2025', 201, N'N1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', NULL, NULL, 'No invoice', 1, '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_silv_membership_events_segments;

    SELECT event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried
    INTO #Actual
    FROM Layercake.silv_membership_events;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried, v.concession_type_id, v.concession_type_carried
    INTO #Expected
    FROM (VALUES (201, 0, 0, 0, 0, 0, 0),
                 (202, 0, 0, 0, 0, 0, 0)) AS v(event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-003 no null payment method and every value resolves to dim_payment_method in silver and gold]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'D1', 2025, 1, 0, 1, 0, NULL, 1, 0, 30001, 1, '2026-01-01', '2026-01-01'),
           (N'D2', 2025, 5, 0, 2, 0, N'SCH-002', 1, 0, 30002, 1, '2026-01-01', '2026-01-01'),
           (N'D4', 2021, -2, 0, -2, 0, NULL, -2, 0, NULL, 1, '2026-01-01', '2026-01-01'),
           (N'D5', 2025, -1, 0, 1, 0, NULL, 1, 0, 30005, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (301, N'RN:D1:2025', 'Renewal', 'Standard', '2024-11-05', N'D1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (302, N'RN:D2:2025', 'Renewal', 'Standard', '2024-11-05', N'D2', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (303, N'CH:D3:2025', 'Change', 'Grade', '2025-02-01', N'D3', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (304, N'RN:D4:2021', 'Renewal', 'Standard', '2020-11-05', N'D4', 2, 1, 2021, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (305, N'RN:D5:2025', 'Renewal', 'Standard', '2024-11-05', N'D5', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    SELECT event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_membership_events_segments;
    EXEC Layercake.usp_load_fact_membership_events_segments;

    DECLARE @silver_bad int, @gold_bad int;
    SELECT @silver_bad = COUNT(*)
    FROM Layercake.silv_membership_events AS e
    LEFT JOIN Layercake.dim_payment_method AS d ON d.id = e.payment_method_id
    WHERE e.payment_method_id IS NULL OR d.id IS NULL;
    SELECT @gold_bad = COUNT(*)
    FROM Layercake.fact_membership_events AS f
    LEFT JOIN Layercake.dim_payment_method AS d ON d.id = f.payment_method_id
    WHERE f.payment_method_id IS NULL OR d.id IS NULL;
    EXEC tSQLt.AssertEquals 0, @silver_bad, 'silver events with a null or orphan payment_method_id';
    EXEC tSQLt.AssertEquals 0, @gold_bad, 'gold events with a null or orphan payment_method_id';

    SELECT event_id, payment_method_id
    INTO #Actual
    FROM Layercake.fact_membership_events;

    SELECT v.event_id, v.payment_method_id
    INTO #Expected
    FROM (VALUES (301, 1), (302, 5), (303, 0), (304, -2), (305, -1)) AS v(event_id, payment_method_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-004 gold counts by payment method equal silver counts]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'E1', 2025, 1, 0, 1, 0, NULL, 1, 0, 40001, 1, '2026-01-01', '2026-01-01'),
           (N'E2', 2025, 1, 0, 1, 0, NULL, 1, 0, 40002, 1, '2026-01-01', '2026-01-01'),
           (N'E3', 2025, 2, 0, 1, 0, NULL, 1, 0, 40003, 1, '2026-01-01', '2026-01-01'),
           (N'E4', 2025, 2, 1, 1, 1, NULL, 0, 0, NULL, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (401, N'RN:E1:2025', 'Renewal', 'Standard', '2024-11-05', N'E1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (402, N'RN:E2:2025', 'Renewal', 'Standard', '2024-11-05', N'E2', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (403, N'RN:E3:2025', 'Renewal', 'Standard', '2024-11-05', N'E3', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (404, N'CH:E3:2025', 'Change', 'Grade', '2025-02-01', N'E3', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (405, N'LP:E4:2025', 'Lapse', 'Standard', '2025-05-01', N'E4', 2, 1, 2025, 'Q3', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (406, N'RN:E5:2025', 'Renewal', 'Standard', '2024-11-05', N'E5', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    SELECT event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_membership_events_segments;
    EXEC Layercake.usp_load_fact_membership_events_segments;

    SELECT v.payment_method_id, v.event_count
    INTO #Expected
    FROM (VALUES (0, 1), (1, 2), (2, 3)) AS v(payment_method_id, event_count);

    SELECT payment_method_id, COUNT(*) AS event_count
    INTO #ActualSilver
    FROM Layercake.silv_membership_events
    GROUP BY payment_method_id;

    SELECT payment_method_id, COUNT(*) AS event_count
    INTO #ActualGold
    FROM Layercake.fact_membership_events
    GROUP BY payment_method_id;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSilver', 'silver counts by payment_method_id';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualGold', 'gold counts by payment_method_id';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-005 C7 join takes Direct Debit from its first paid position year not its own year]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'C7', 2023, 2, 0, 0, 0, NULL, 0, 0, 50001, 1, '2026-01-01', '2026-01-01'),
           (N'C7', 2024, 1, 0, 1, 0, NULL, 1, 0, 50002, 1, '2026-01-01', '2026-01-01'),
           (N'C7', 2025, 3, 0, 1, 0, NULL, 3, 0, 50003, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'C7', 2024, '2023-10-25', '2023-10-25', N'Fully Paid'),
           (N'C7', 2025, '2024-10-25', '2024-10-25', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (501, N'JR:C7', 'Join', 'Direct Entry', '2023-03-01', N'C7', 1, 1, 2023, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'JR:C7', 501, N'C7', 'Join', '2023-03-01', 2024, 50002, 'Matched', 450.0000, 450.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_silv_membership_events_segments;

    SELECT event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried
    INTO #Actual
    FROM Layercake.silv_membership_events;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried, v.concession_type_id, v.concession_type_carried
    INTO #Expected
    FROM (VALUES (501, 1, 0, 1, 0, 1, 0)) AS v(event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-006 C1 renewal carried 0 and lapse carried 1 in silver and gold]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'C1', 2023, 1, 0, 1, 0, NULL, 1, 0, 10001, 1, '2026-01-01', '2026-01-01'),
           (N'C1', 2024, 2, 0, 1, 0, NULL, 1, 0, 10002, 1, '2026-01-01', '2026-01-01'),
           (N'C1', 2025, 2, 1, 1, 1, NULL, 0, 0, NULL, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'C1', 2023, '2022-11-15', '2022-11-15', N'Fully Paid'),
           (N'C1', 2024, '2023-10-20', '2023-10-20', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (103, N'RN:C1:2024', 'Renewal', 'Standard', '2023-10-20', N'C1', 2, 1, 2024, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (104, N'LP:C1:2025', 'Lapse', 'Standard', '2025-05-01', N'C1', 2, 1, 2025, 'Q3', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:C1:2024', 103, N'C1', 'Renewal', '2023-10-20', 2024, 10002, 'Matched', 420.0000, 420.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    SELECT event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_membership_events_segments;
    EXEC Layercake.usp_load_fact_membership_events_segments;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried
    INTO #Expected
    FROM (VALUES (103, 2, 0), (104, 2, 1)) AS v(event_id, payment_method_id, payment_method_carried);

    SELECT event_id, payment_method_id, payment_method_carried
    INTO #ActualSilver
    FROM Layercake.silv_membership_events;

    SELECT event_id, payment_method_id, payment_method_carried
    INTO #ActualGold
    FROM Layercake.fact_membership_events;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSilver', 'silver';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualGold', 'gold';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-007 each carried flag on events equals the same flag on the attributes row in silver and gold]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'F1', 2025, 2, 1, 1, 0, NULL, 2, 1, NULL, 1, '2026-01-01', '2026-01-01'),
           (N'F2', 2025, 1, 0, 2, 1, N'SCH-F2', 1, 0, NULL, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (701, N'RN:F1:2025', 'Renewal', 'Standard', '2024-11-05', N'F1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (702, N'CH:F1:2025', 'Change', 'Grade', '2025-02-01', N'F1', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (703, N'RN:F2:2025', 'Renewal', 'Standard', '2024-11-05', N'F2', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (704, N'CH:F3:2025', 'Change', 'Grade', '2025-02-01', N'F3', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    SELECT event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_membership_events_segments;
    EXEC Layercake.usp_load_fact_membership_events_segments;

    SELECT v.event_id, v.payment_method_carried, v.payer_type_carried, v.concession_type_carried
    INTO #Expected
    FROM (VALUES (701, 1, 0, 1), (702, 1, 0, 1), (703, 0, 1, 0), (704, 0, 0, 0)) AS v(event_id, payment_method_carried, payer_type_carried, concession_type_carried);

    SELECT event_id, payment_method_carried, payer_type_carried, concession_type_carried
    INTO #ActualSilver
    FROM Layercake.silv_membership_events;

    SELECT event_id, payment_method_carried, payer_type_carried, concession_type_carried
    INTO #ActualGold
    FROM Layercake.fact_membership_events;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSilver', 'silver';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualGold', 'gold';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-008 C13 join with no paid position takes Card from its own campaign year]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'C13', 2024, 2, 0, 0, 0, NULL, 1, 0, 80001, 1, '2026-01-01', '2026-01-01'),
           (N'C13', 2025, 1, 1, 0, 0, NULL, 0, 0, NULL, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'C99', 2023, '2022-10-20', '2022-10-20', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (801, N'JR:C13', 'Join', 'Direct Entry', '2024-02-01', N'C13', 1, 1, 2024, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'JR:C13', 801, N'C13', 'Join', '2024-02-01', 2024, 80001, 'Matched', NULL, NULL, 'No invoice', 1, '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_silv_membership_events_segments;

    SELECT event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried
    INTO #Actual
    FROM Layercake.silv_membership_events;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried, v.concession_type_id, v.concession_type_carried
    INTO #Expected
    FROM (VALUES (801, 2, 0, 0, 0, 1, 0)) AS v(event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-009 P1 2026 lapse carries Corporate with payer_type_carried 1 in silver and gold]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'P1', 2025, 5, 0, 2, 0, N'SCH-001', 1, 0, 90001, 1, '2026-01-01', '2026-01-01'),
           (N'P1', 2026, 5, 1, 2, 1, N'SCH-001', 0, 0, NULL, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (901, N'RN:P1:2025', 'Renewal', 'Standard', '2024-10-15', N'P1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (902, N'LP:P1:2026', 'Lapse', 'Standard', '2026-03-01', N'P1', 2, 1, 2026, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:P1:2025', 901, N'P1', 'Renewal', '2024-10-15', 2025, 90001, 'Matched', 450.0000, 450.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    SELECT event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_membership_events_segments;
    EXEC Layercake.usp_load_fact_membership_events_segments;

    SELECT v.event_id, v.payer_type_id, v.payer_type_carried
    INTO #Expected
    FROM (VALUES (901, 2, 0), (902, 2, 1)) AS v(event_id, payer_type_id, payer_type_carried);

    SELECT event_id, payer_type_id, payer_type_carried
    INTO #ActualSilver
    FROM Layercake.silv_membership_events;

    SELECT event_id, payer_type_id, payer_type_carried
    INTO #ActualGold
    FROM Layercake.fact_membership_events;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSilver', 'silver';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualGold', 'gold';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-010 no null payer type and every value resolves to dim_payer_type in silver and gold]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'G1', 2025, 2, 0, 1, 0, NULL, 1, 0, 100001, 1, '2026-01-01', '2026-01-01'),
           (N'G2', 2025, 5, 0, 2, 0, N'SCH-G2', 1, 0, 100002, 1, '2026-01-01', '2026-01-01'),
           (N'G4', 2021, -2, 0, -2, 0, NULL, -2, 0, NULL, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1001, N'RN:G1:2025', 'Renewal', 'Standard', '2024-11-05', N'G1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1002, N'RN:G2:2025', 'Renewal', 'Standard', '2024-11-05', N'G2', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1003, N'CH:G3:2025', 'Change', 'Grade', '2025-02-01', N'G3', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1004, N'RN:G4:2021', 'Renewal', 'Standard', '2020-11-05', N'G4', 2, 1, 2021, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    SELECT event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_membership_events_segments;
    EXEC Layercake.usp_load_fact_membership_events_segments;

    DECLARE @silver_bad int, @gold_bad int;
    SELECT @silver_bad = COUNT(*)
    FROM Layercake.silv_membership_events AS e
    LEFT JOIN Layercake.dim_payer_type AS d ON d.id = e.payer_type_id
    WHERE e.payer_type_id IS NULL OR d.id IS NULL;
    SELECT @gold_bad = COUNT(*)
    FROM Layercake.fact_membership_events AS f
    LEFT JOIN Layercake.dim_payer_type AS d ON d.id = f.payer_type_id
    WHERE f.payer_type_id IS NULL OR d.id IS NULL;
    EXEC tSQLt.AssertEquals 0, @silver_bad, 'silver events with a null or orphan payer_type_id';
    EXEC tSQLt.AssertEquals 0, @gold_bad, 'gold events with a null or orphan payer_type_id';

    SELECT event_id, payer_type_id
    INTO #Actual
    FROM Layercake.fact_membership_events;

    SELECT v.event_id, v.payer_type_id
    INTO #Expected
    FROM (VALUES (1001, 1), (1002, 2), (1003, 0), (1004, -2)) AS v(event_id, payer_type_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-011 P9 2021 renewal has payer type Not applicable]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'P9', 2021, -2, 0, -2, 0, NULL, -2, 0, NULL, 1, '2026-01-01', '2026-01-01'),
           (N'P9', 2022, 2, 0, 1, 0, NULL, 1, 0, 110001, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1101, N'RN:P9:2021', 'Renewal', 'Standard', '2020-11-01', N'P9', 2, 1, 2021, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:P9:2021', 1101, N'P9', 'Renewal', '2020-11-01', 2021, NULL, 'Before invoice data', NULL, NULL, 'Before invoice data', 1, '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_silv_membership_events_segments;

    SELECT event_id, payment_method_id, payer_type_id, payer_type_carried, concession_type_id
    INTO #Actual
    FROM Layercake.silv_membership_events;

    SELECT v.event_id, v.payment_method_id, v.payer_type_id, v.payer_type_carried, v.concession_type_id
    INTO #Expected
    FROM (VALUES (1101, -2, -2, 0, -2)) AS v(event_id, payment_method_id, payer_type_id, payer_type_carried, concession_type_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-012 event tables drop the eight unsupplied amount columns and keep the nine segment and amount columns]
AS
BEGIN
    -- SetUp fakes both event tables; read the real (renamed) tables through their logged ObjectId.
    SELECT t.table_name, COALESCE(r.ObjectId, OBJECT_ID(N'Layercake.' + t.table_name)) AS object_id
    INTO #Tables
    FROM (VALUES (N'silv_membership_events'), (N'fact_membership_events')) AS t(table_name)
    OUTER APPLY (
        SELECT TOP (1) l.ObjectId
        FROM tSQLt.Private_RenamedObjectLog AS l
        WHERE PARSENAME(l.OriginalName, 1) = t.table_name
          AND OBJECT_SCHEMA_NAME(l.ObjectId) = N'Layercake'
        ORDER BY l.Id
    ) AS r;

    SELECT t.table_name
    INTO #Missing
    FROM #Tables AS t
    WHERE t.object_id IS NULL;

    EXEC tSQLt.AssertEmptyTable '#Missing', 'event table not found';

    SELECT t.table_name COLLATE DATABASE_DEFAULT AS table_name, c.name COLLATE DATABASE_DEFAULT AS column_name
    INTO #Dropped
    FROM #Tables AS t
    JOIN sys.columns AS c ON c.object_id = t.object_id
    WHERE c.name IN (N'subs_amount', N'fee_amount', N'invoiced_subtotal', N'credited_amount', N'currency_id', N'fee_amount_gbp', N'credited_amount_gbp', N'net_amount_gbp');

    EXEC tSQLt.AssertEmptyTable '#Dropped', 'dropped amount columns still present';

    SELECT t.table_name COLLATE DATABASE_DEFAULT AS table_name,
           c.name COLLATE DATABASE_DEFAULT AS column_name,
           CAST(TYPE_NAME(c.user_type_id) AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS data_type,
           CAST(CASE WHEN TYPE_NAME(c.user_type_id) IN (N'decimal', N'numeric') THEN CONCAT(c.precision, ',', c.scale)
                     WHEN TYPE_NAME(c.user_type_id) IN (N'varchar', N'char') THEN CAST(c.max_length AS varchar(10))
                     WHEN TYPE_NAME(c.user_type_id) IN (N'nvarchar', N'nchar') THEN CAST(c.max_length / 2 AS varchar(10))
                     ELSE '' END AS varchar(20)) COLLATE DATABASE_DEFAULT AS type_detail,
           c.is_nullable
    INTO #Actual
    FROM #Tables AS t
    JOIN sys.columns AS c ON c.object_id = t.object_id
    WHERE c.name IN (N'payment_method_id', N'payment_method_carried', N'payer_type_id', N'payer_type_carried', N'concession_type_id', N'concession_type_carried', N'subs_amount_gbp', N'invoiced_subtotal_gbp', N'amount_status');

    SELECT v.table_name, v.column_name, CAST(v.data_type AS nvarchar(128)) AS data_type, CAST(v.type_detail AS varchar(20)) AS type_detail, CAST(v.is_nullable AS bit) AS is_nullable
    INTO #Expected
    FROM (VALUES
        (N'silv_membership_events', N'payment_method_id', N'int', '', 0),
        (N'silv_membership_events', N'payment_method_carried', N'bit', '', 0),
        (N'silv_membership_events', N'payer_type_id', N'int', '', 0),
        (N'silv_membership_events', N'payer_type_carried', N'bit', '', 0),
        (N'silv_membership_events', N'concession_type_id', N'int', '', 0),
        (N'silv_membership_events', N'concession_type_carried', N'bit', '', 0),
        (N'silv_membership_events', N'subs_amount_gbp', N'decimal', '19,4', 1),
        (N'silv_membership_events', N'invoiced_subtotal_gbp', N'decimal', '19,4', 1),
        (N'silv_membership_events', N'amount_status', N'varchar', '30', 1),
        (N'fact_membership_events', N'payment_method_id', N'int', '', 0),
        (N'fact_membership_events', N'payment_method_carried', N'bit', '', 0),
        (N'fact_membership_events', N'payer_type_id', N'int', '', 0),
        (N'fact_membership_events', N'payer_type_carried', N'bit', '', 0),
        (N'fact_membership_events', N'concession_type_id', N'int', '', 0),
        (N'fact_membership_events', N'concession_type_carried', N'bit', '', 0),
        (N'fact_membership_events', N'subs_amount_gbp', N'decimal', '19,4', 1),
        (N'fact_membership_events', N'invoiced_subtotal_gbp', N'decimal', '19,4', 1),
        (N'fact_membership_events', N'amount_status', N'varchar', '30', 1)
    ) AS v(table_name, column_name, data_type, type_detail, is_nullable);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'kept segment and amount columns';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-013 change and lapse events have null amounts and amount_status in silver and gold]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'L1', 2025, 2, 0, 1, 0, NULL, 1, 0, 130001, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1301, N'RN:L1:2025', 'Renewal', 'Standard', '2024-11-05', N'L1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1302, N'CH:L1:2025', 'Change', 'Grade', '2025-02-01', N'L1', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, 100.0000, 100.0000, 'Invoiced'),
           (1303, N'LP:L1:2025', 'Lapse', 'Standard', '2025-05-01', N'L1', 2, 1, 2025, 'Q3', 0, 0, 0, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:L1:2025', 1301, N'L1', 'Renewal', '2024-11-05', 2025, 130001, 'Matched', 450.0000, 450.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    SELECT event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_membership_events_segments;
    EXEC Layercake.usp_load_fact_membership_events_segments;

    SELECT v.event_id, CAST(v.subs_amount_gbp AS decimal(19,4)) AS subs_amount_gbp, CAST(v.invoiced_subtotal_gbp AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.amount_status AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (1301, 450.0000, 450.0000, 'Invoiced'),
                 (1302, NULL, NULL, NULL),
                 (1303, NULL, NULL, NULL)) AS v(event_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status);

    SELECT event_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #ActualSilver
    FROM Layercake.silv_membership_events;

    SELECT event_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #ActualGold
    FROM Layercake.fact_membership_events;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSilver', 'silver';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualGold', 'gold';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-014 join renewal and readmission take amounts and amount_status from silv_event_amount by event_nk]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'J3', 2025, '2024-10-20', '2024-10-20', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1401, N'RN:R1:2025', 'Renewal', 'Standard', '2024-11-05', N'R1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1402, N'RA:R1:2025', 'Readmission', 'Standard', '2025-03-10', N'R1', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1403, N'RN:F1:2025', 'Renewal', 'Standard', '2024-11-05', N'F1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1404, N'RN:N8:2025', 'Renewal', 'Standard', '2024-11-05', N'N8', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, 999.0000, 999.0000, 'Invoiced'),
           (1405, N'RN:B1:2021', 'Renewal', 'Standard', '2020-11-05', N'B1', 2, 1, 2021, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1406, N'JR:J3', 'Join', 'Direct Entry', '2024-06-15', N'J3', 1, 1, 2024, 'Q3', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:R1:2025', 1401, N'R1', 'Renewal', '2024-11-05', 2025, 140101, 'Matched', NULL, NULL, 'Counted on another event', 1, '2026-01-01', '2026-01-01'),
           (N'RA:R1:2025', 1402, N'R1', 'Readmission', '2025-03-10', 2025, 140102, 'Matched', 900.0000, 900.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01'),
           (N'RN:F1:2025', 1403, N'F1', 'Renewal', '2024-11-05', 2025, 140301, 'Matched', 0.0000, 0.0000, 'Full Concession', 1, '2026-01-01', '2026-01-01'),
           (N'RN:N8:2025', 1404, N'N8', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', NULL, NULL, 'No invoice', 1, '2026-01-01', '2026-01-01'),
           (N'RN:B1:2021', 1405, N'B1', 'Renewal', '2020-11-05', 2021, NULL, 'Before invoice data', NULL, NULL, 'Before invoice data', 1, '2026-01-01', '2026-01-01'),
           (N'JR:J3', 1406, N'J3', 'Join', '2024-06-15', 2025, 140601, 'Matched', 200.0000, 200.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01'),
           (N'RN:GONE:2025', 1499, N'GONE', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 300.0000, 300.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_silv_membership_events_segments;

    SELECT event_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_membership_events;

    SELECT v.event_id, CAST(v.subs_amount_gbp AS decimal(19,4)) AS subs_amount_gbp, CAST(v.invoiced_subtotal_gbp AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.amount_status AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (1401, NULL, NULL, 'Counted on another event'),
                 (1402, 900.0000, 900.0000, 'Invoiced'),
                 (1403, 0.0000, 0.0000, 'Full Concession'),
                 (1404, NULL, NULL, 'No invoice'),
                 (1405, NULL, NULL, 'Before invoice data'),
                 (1406, 200.0000, 200.0000, 'Invoiced')) AS v(event_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-015 R1 R2 R3 amount sums and amount_status counts agree in silver and gold]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1501, N'RN:R1:2025', 'Renewal', 'Standard', '2024-11-05', N'R1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1502, N'RA:R1:2025', 'Readmission', 'Standard', '2025-03-10', N'R1', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1503, N'RN:R2:2025', 'Renewal', 'Standard', '2024-11-05', N'R2', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1504, N'RA:R2:2025', 'Readmission', 'Standard', '2025-03-10', N'R2', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1505, N'RN:R3:2025', 'Renewal', 'Standard', '2024-11-05', N'R3', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1506, N'CH:R3:2025', 'Change', 'Grade', '2025-02-01', N'R3', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:R1:2025', 1501, N'R1', 'Renewal', '2024-11-05', 2025, 150101, 'Matched', NULL, NULL, 'Counted on another event', 1, '2026-01-01', '2026-01-01'),
           (N'RA:R1:2025', 1502, N'R1', 'Readmission', '2025-03-10', 2025, 150102, 'Matched', 900.0000, 900.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01'),
           (N'RN:R2:2025', 1503, N'R2', 'Renewal', '2024-11-05', 2025, NULL, 'Invoice shortfall', NULL, NULL, 'Counted on another event', 1, '2026-01-01', '2026-01-01'),
           (N'RA:R2:2025', 1504, N'R2', 'Readmission', '2025-03-10', 2025, 150301, 'Matched', 450.0000, 450.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01'),
           (N'RN:R3:2025', 1505, N'R3', 'Renewal', '2024-11-05', 2025, 150502, 'Matched', 820.0000, 820.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    SELECT event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_membership_events_segments;
    EXEC Layercake.usp_load_fact_membership_events_segments;

    SELECT CAST('silver' AS varchar(10)) AS layer, SUM(subs_amount_gbp) AS subs_total, SUM(invoiced_subtotal_gbp) AS invoiced_total, COUNT(*) AS event_count
    INTO #ActualTotals
    FROM Layercake.silv_membership_events;
    INSERT INTO #ActualTotals (layer, subs_total, invoiced_total, event_count)
    SELECT 'gold', SUM(subs_amount_gbp), SUM(invoiced_subtotal_gbp), COUNT(*)
    FROM Layercake.fact_membership_events;

    SELECT CAST(v.layer AS varchar(10)) AS layer, CAST(v.subs_total AS decimal(38,4)) AS subs_total, CAST(v.invoiced_total AS decimal(38,4)) AS invoiced_total, v.event_count
    INTO #ExpectedTotals
    FROM (VALUES ('silver', 2170.0000, 2170.0000, 6),
                 ('gold', 2170.0000, 2170.0000, 6)) AS v(layer, subs_total, invoiced_total, event_count);

    EXEC tSQLt.AssertEqualsTable '#ExpectedTotals', '#ActualTotals', 'amount totals and row counts';

    SELECT CAST('silver' AS varchar(10)) AS layer, amount_status, COUNT(*) AS event_count
    INTO #ActualStatus
    FROM Layercake.silv_membership_events
    GROUP BY amount_status;
    INSERT INTO #ActualStatus (layer, amount_status, event_count)
    SELECT 'gold', amount_status, COUNT(*)
    FROM Layercake.fact_membership_events
    GROUP BY amount_status;

    SELECT CAST(v.layer AS varchar(10)) AS layer, CAST(v.amount_status AS varchar(30)) AS amount_status, v.event_count
    INTO #ExpectedStatus
    FROM (VALUES ('silver', 'Invoiced', 3), ('silver', 'Counted on another event', 2), ('silver', NULL, 1),
                 ('gold', 'Invoiced', 3), ('gold', 'Counted on another event', 2), ('gold', NULL, 1)) AS v(layer, amount_status, event_count);

    EXEC tSQLt.AssertEqualsTable '#ExpectedStatus', '#ActualStatus', 'counts by amount_status';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-016 R1 renewal and readmission both carry Card from the 2025 attributes row in silver and gold]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'R1', 2025, 2, 0, 1, 0, NULL, 1, 0, 160102, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1601, N'RN:R1:2025', 'Renewal', 'Standard', '2024-11-05', N'R1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1602, N'RA:R1:2025', 'Readmission', 'Standard', '2025-03-10', N'R1', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:R1:2025', 1601, N'R1', 'Renewal', '2024-11-05', 2025, 160101, 'Matched', NULL, NULL, 'Counted on another event', 1, '2026-01-01', '2026-01-01'),
           (N'RA:R1:2025', 1602, N'R1', 'Readmission', '2025-03-10', 2025, 160102, 'Matched', 900.0000, 900.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    SELECT event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_membership_events_segments;
    EXEC Layercake.usp_load_fact_membership_events_segments;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried
    INTO #Expected
    FROM (VALUES (1601, 2, 0), (1602, 2, 0)) AS v(event_id, payment_method_id, payment_method_carried);

    SELECT event_id, payment_method_id, payment_method_carried
    INTO #ActualSilver
    FROM Layercake.silv_membership_events;

    SELECT event_id, payment_method_id, payment_method_carried
    INTO #ActualGold
    FROM Layercake.fact_membership_events;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSilver', 'silver';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualGold', 'gold';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-017 K1 2025 events carry Retired concession carried 0 in silver and gold]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'K1', 2025, 2, 0, 1, 0, NULL, 2, 0, 170001, 1, '2026-01-01', '2026-01-01'),
           (N'K1', 2026, 2, 1, 1, 1, NULL, 2, 1, NULL, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1701, N'RN:K1:2025', 'Renewal', 'Standard', '2024-11-05', N'K1', 2, 2, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1702, N'CH:K1:2025', 'Change', 'Grade', '2025-05-01', N'K1', 2, 2, 2025, 'Q3', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1703, N'LP:K1:2026', 'Lapse', 'Standard', '2026-05-01', N'K1', 2, 2, 2026, 'Q3', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:K1:2025', 1701, N'K1', 'Renewal', '2024-11-05', 2025, 170001, 'Matched', 0.0000, 0.0000, 'Full Concession', 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    SELECT event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_membership_events_segments;
    EXEC Layercake.usp_load_fact_membership_events_segments;

    SELECT v.event_id, v.concession_type_id, v.concession_type_carried
    INTO #Expected
    FROM (VALUES (1701, 2, 0), (1702, 2, 0), (1703, 2, 1)) AS v(event_id, concession_type_id, concession_type_carried);

    SELECT event_id, concession_type_id, concession_type_carried
    INTO #ActualSilver
    FROM Layercake.silv_membership_events;

    SELECT event_id, concession_type_id, concession_type_carried
    INTO #ActualGold
    FROM Layercake.fact_membership_events;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualSilver', 'silver';
    EXEC tSQLt.AssertEqualsTable '#Expected', '#ActualGold', 'gold';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-018 no null concession type and every value resolves to dim_concession_type in silver and gold]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'M1', 2025, 2, 0, 1, 0, NULL, 1, 0, 180001, 1, '2026-01-01', '2026-01-01'),
           (N'M2', 2025, 2, 0, 1, 0, NULL, 2, 0, 180002, 1, '2026-01-01', '2026-01-01'),
           (N'M3', 2025, 2, 0, 1, 0, NULL, 3, 0, 180003, 1, '2026-01-01', '2026-01-01'),
           (N'M5', 2021, -2, 0, -2, 0, NULL, -2, 0, NULL, 1, '2026-01-01', '2026-01-01'),
           (N'M6', 2025, 2, 0, 1, 0, NULL, -1, 0, 180006, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1801, N'RN:M1:2025', 'Renewal', 'Standard', '2024-11-05', N'M1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1802, N'RN:M2:2025', 'Renewal', 'Standard', '2024-11-05', N'M2', 2, 2, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1803, N'RN:M3:2025', 'Renewal', 'Standard', '2024-11-05', N'M3', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1804, N'CH:M4:2025', 'Change', 'Grade', '2025-02-01', N'M4', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1805, N'RN:M5:2021', 'Renewal', 'Standard', '2020-11-05', N'M5', 2, 1, 2021, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (1806, N'RN:M6:2025', 'Renewal', 'Standard', '2024-11-05', N'M6', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    SELECT event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_membership_events_segments;
    EXEC Layercake.usp_load_fact_membership_events_segments;

    DECLARE @silver_bad int, @gold_bad int;
    SELECT @silver_bad = COUNT(*)
    FROM Layercake.silv_membership_events AS e
    LEFT JOIN Layercake.dim_concession_type AS d ON d.id = e.concession_type_id
    WHERE e.concession_type_id IS NULL OR d.id IS NULL;
    SELECT @gold_bad = COUNT(*)
    FROM Layercake.fact_membership_events AS f
    LEFT JOIN Layercake.dim_concession_type AS d ON d.id = f.concession_type_id
    WHERE f.concession_type_id IS NULL OR d.id IS NULL;
    EXEC tSQLt.AssertEquals 0, @silver_bad, 'silver events with a null or orphan concession_type_id';
    EXEC tSQLt.AssertEquals 0, @gold_bad, 'gold events with a null or orphan concession_type_id';

    SELECT event_id, concession_type_id
    INTO #Actual
    FROM Layercake.fact_membership_events;

    SELECT v.event_id, v.concession_type_id
    INTO #Expected
    FROM (VALUES (1801, 1), (1802, 2), (1803, 3), (1804, 0), (1805, -2), (1806, -1)) AS v(event_id, concession_type_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-019 K9 2021 renewal has concession type Not applicable]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'K9', 2021, -2, 0, -2, 0, NULL, -2, 0, NULL, 1, '2026-01-01', '2026-01-01'),
           (N'K9', 2022, 2, 0, 1, 0, NULL, 2, 0, 190001, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1901, N'RN:K9:2021', 'Renewal', 'Standard', '2020-11-01', N'K9', 2, 1, 2021, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:K9:2021', 1901, N'K9', 'Renewal', '2020-11-01', 2021, NULL, 'Before invoice data', NULL, NULL, 'Before invoice data', 1, '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_silv_membership_events_segments;

    SELECT event_id, concession_type_id, concession_type_carried
    INTO #Actual
    FROM Layercake.silv_membership_events;

    SELECT v.event_id, v.concession_type_id, v.concession_type_carried
    INTO #Expected
    FROM (VALUES (1901, -2, 0)) AS v(event_id, concession_type_id, concession_type_carried);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-020 silver rerun on unchanged data changes nothing and logs 0 updated]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'F1', 2025, 2, 1, 1, 0, NULL, 2, 1, NULL, 1, '2026-01-01', '2026-01-01'),
           (N'F2', 2025, 1, 0, 2, 1, N'SCH-F2', 1, 0, NULL, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2001, N'RN:F1:2025', 'Renewal', 'Standard', '2024-11-05', N'F1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (2002, N'CH:F1:2025', 'Change', 'Grade', '2025-02-01', N'F1', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (2003, N'RN:F2:2025', 'Renewal', 'Standard', '2024-11-05', N'F2', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (2004, N'CH:F3:2025', 'Change', 'Grade', '2025-02-01', N'F3', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:F1:2025', 2001, N'F1', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 450.0000, 450.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01'),
           (N'RN:F2:2025', 2003, N'F2', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 380.0000, 380.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_silv_membership_events_segments;

    SELECT * INTO #AfterFirst FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_membership_events_segments;

    SELECT * INTO #AfterSecond FROM Layercake.silv_membership_events;

    EXEC tSQLt.AssertEqualsTable '#AfterFirst', '#AfterSecond', 'second run changed silv_membership_events';

    SELECT l.status, ISNULL(l.rows_inserted, 0) AS rows_inserted, l.rows_updated, ISNULL(l.rows_deleted, 0) AS rows_deleted,
           ROW_NUMBER() OVER (ORDER BY l.log_id) AS run_no
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT CAST(v.status AS varchar(10)) AS status, v.rows_inserted, v.rows_updated, v.rows_deleted, CAST(v.run_no AS bigint) AS run_no
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 3, 0, 1), ('Success', 0, 0, 0, 2)) AS v(status, rows_inserted, rows_updated, rows_deleted, run_no);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log rows';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-021 silver load updates only differing rows and never inserts deletes or touches Phase 1 columns]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'H1', 2025, 2, 0, 1, 0, NULL, 1, 0, 210001, 1, '2026-01-01', '2026-01-01'),
           (N'H2', 2025, 1, 0, 1, 0, NULL, 3, 0, 210002, 1, '2026-01-01', '2026-01-01'),
           (N'H3', 2025, 4, 1, 1, 1, NULL, 0, 0, NULL, 1, '2026-01-01', '2026-01-01'),
           (N'H9', 2025, 2, 0, 1, 0, NULL, 1, 0, 210009, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2101, N'RN:H1:2025', 'Renewal', 'Standard', '2024-11-05', N'H1', 2, 1, 2025, 'Q1', 2, 0, 1, 0, 1, 0, 450.0000, 450.0000, 'Invoiced'),
           (2102, N'RN:H2:2025', 'Renewal', 'Standard', '2024-11-05', N'H2', 1, 2, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (2103, N'CH:H3:2025', 'Change', 'Grade', '2025-02-01', N'H3', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, 100.0000, 100.0000, 'Invoiced');
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:H1:2025', 2101, N'H1', 'Renewal', '2024-11-05', 2025, 210001, 'Matched', 450.0000, 450.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01'),
           (N'RN:H2:2025', 2102, N'H2', 'Renewal', '2024-11-05', 2025, 210002, 'Matched', 300.0000, 300.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01');

    SELECT event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter
    INTO #Phase1Before
    FROM Layercake.silv_membership_events;

    EXEC Layercake.usp_load_silv_membership_events_segments;

    SELECT event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter
    INTO #Phase1After
    FROM Layercake.silv_membership_events;

    EXEC tSQLt.AssertEqualsTable '#Phase1Before', '#Phase1After', 'Phase 1 columns or row set changed';

    SELECT event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_membership_events;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried, v.concession_type_id, v.concession_type_carried,
           CAST(v.subs_amount_gbp AS decimal(19,4)) AS subs_amount_gbp, CAST(v.invoiced_subtotal_gbp AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.amount_status AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (2101, 2, 0, 1, 0, 1, 0, 450.0000, 450.0000, 'Invoiced'),
                 (2102, 1, 0, 1, 0, 3, 0, 300.0000, 300.0000, 'Invoiced'),
                 (2103, 4, 1, 1, 1, 0, 0, NULL, NULL, NULL)) AS v(event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'new columns';

    SELECT l.status, ISNULL(l.rows_inserted, 0) AS rows_inserted, l.rows_updated, ISNULL(l.rows_deleted, 0) AS rows_deleted,
           CASE WHEN l.finished_at IS NULL THEN 0 ELSE 1 END AS has_finished_at,
           CASE WHEN l.error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT CAST(v.status AS varchar(10)) AS status, v.rows_inserted, v.rows_updated, v.rows_deleted, v.has_finished_at, v.has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 2, 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted, has_finished_at, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD012.[test TC-012-022 silver write the target rejects re-raises logs Failed and changes nothing]
AS
BEGIN
    ALTER TABLE Layercake.silv_membership_events ADD CONSTRAINT CK_test_MOD012_reject_99 CHECK (payment_method_id <> 99);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'X1', 2025, 2, 0, 1, 0, NULL, 1, 0, 220001, 1, '2026-01-01', '2026-01-01'),
           (N'XERR', 2025, 99, 0, 1, 0, NULL, 1, 0, 220002, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2201, N'RN:X1:2025', 'Renewal', 'Standard', '2024-11-05', N'X1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (2202, N'RN:XERR:2025', 'Renewal', 'Standard', '2024-11-05', N'XERR', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:X1:2025', 2201, N'X1', 'Renewal', '2024-11-05', 2025, 220001, 'Matched', 450.0000, 450.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01'),
           (N'RN:XERR:2025', 2202, N'XERR', 'Renewal', '2024-11-05', 2025, 220002, 'Matched', 300.0000, 300.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01');

    SELECT * INTO #Before FROM Layercake.silv_membership_events;

    DECLARE @raised bit = 0, @errno int = NULL;
    BEGIN TRY
        EXEC Layercake.usp_load_silv_membership_events_segments;
    END TRY
    BEGIN CATCH
        SET @raised = 1;
        SET @errno = ERROR_NUMBER();
    END CATCH;

    IF @raised = 0
        EXEC tSQLt.Fail 'usp_load_silv_membership_events_segments did not raise the rejected write';
    EXEC tSQLt.AssertEquals 547, @errno, 'error number reaching the caller';

    SELECT * INTO #After FROM Layercake.silv_membership_events;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'silv_membership_events changed by a failed load';

    SELECT l.status, CASE WHEN l.error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT CAST(v.status AS varchar(10)) AS status, v.has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-023 gold load copies only the new columns and updates only differing rows]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2301, N'RN:W1:2025', 'Renewal', 'Standard', '2024-11-05', N'W1', 2, 2, 2025, 'Q1', 5, 0, 2, 0, 2, 0, 380.0000, 380.0000, 'Invoiced'),
           (2302, N'RN:W2:2025', 'Renewal', 'Standard', '2024-11-05', N'W2', 2, 1, 2025, 'Q1', 1, 0, 1, 0, 1, 0, 450.0000, 450.0000, 'Invoiced');
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2301, 'Renewal', 'Standard', '2024-11-05', N'W1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (2302, 'Renewal', 'Standard', '2024-11-05', N'W2', 2, 1, 2025, 'Q1', 1, 0, 1, 0, 1, 0, 450.0000, 450.0000, 'Invoiced');

    SELECT event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter
    INTO #Phase1Before
    FROM Layercake.fact_membership_events;

    EXEC Layercake.usp_load_fact_membership_events_segments;

    SELECT event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter
    INTO #Phase1After
    FROM Layercake.fact_membership_events;

    EXEC tSQLt.AssertEqualsTable '#Phase1Before', '#Phase1After', 'Phase 1 fact columns or row set changed';

    SELECT event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.fact_membership_events;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried, v.concession_type_id, v.concession_type_carried,
           CAST(v.subs_amount_gbp AS decimal(19,4)) AS subs_amount_gbp, CAST(v.invoiced_subtotal_gbp AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.amount_status AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (2301, 5, 0, 2, 0, 2, 0, 380.0000, 380.0000, 'Invoiced'),
                 (2302, 1, 0, 1, 0, 1, 0, 450.0000, 450.0000, 'Invoiced')) AS v(event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'fact new columns';

    SELECT l.status, ISNULL(l.rows_inserted, 0) AS rows_inserted, l.rows_updated, ISNULL(l.rows_deleted, 0) AS rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT CAST(v.status AS varchar(10)) AS status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-024 gold rerun on unchanged data changes nothing and logs 0 updated]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2401, N'RN:V1:2025', 'Renewal', 'Standard', '2024-11-05', N'V1', 2, 1, 2025, 'Q1', 2, 0, 1, 0, 1, 0, 450.0000, 450.0000, 'Invoiced'),
           (2402, N'LP:V1:2026', 'Lapse', 'Standard', '2026-05-01', N'V1', 2, 1, 2026, 'Q3', 2, 1, 1, 1, 0, 0, NULL, NULL, NULL);
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2401, 'Renewal', 'Standard', '2024-11-05', N'V1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (2402, 'Lapse', 'Standard', '2026-05-01', N'V1', 2, 1, 2026, 'Q3', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);

    EXEC Layercake.usp_load_fact_membership_events_segments;

    SELECT * INTO #AfterFirst FROM Layercake.fact_membership_events;

    EXEC Layercake.usp_load_fact_membership_events_segments;

    SELECT * INTO #AfterSecond FROM Layercake.fact_membership_events;

    EXEC tSQLt.AssertEqualsTable '#AfterFirst', '#AfterSecond', 'second run changed fact_membership_events';

    SELECT l.status, ISNULL(l.rows_inserted, 0) AS rows_inserted, l.rows_updated, ISNULL(l.rows_deleted, 0) AS rows_deleted,
           ROW_NUMBER() OVER (ORDER BY l.log_id) AS run_no
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT CAST(v.status AS varchar(10)) AS status, v.rows_inserted, v.rows_updated, v.rows_deleted, CAST(v.run_no AS bigint) AS run_no
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 2, 0, 1), ('Success', 0, 0, 0, 2)) AS v(status, rows_inserted, rows_updated, rows_deleted, run_no);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log rows';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD012.[test TC-012-025 gold check failure when silver and gold row sets differ re-raises logs Failed and changes nothing]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2501, N'RN:Y1:2025', 'Renewal', 'Standard', '2024-11-05', N'Y1', 2, 1, 2025, 'Q1', 2, 0, 1, 0, 1, 0, 450.0000, 450.0000, 'Invoiced'),
           (2502, N'RN:Y2:2025', 'Renewal', 'Standard', '2024-11-05', N'Y2', 2, 1, 2025, 'Q1', 1, 0, 1, 0, 1, 0, 300.0000, 300.0000, 'Invoiced');
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2501, 'Renewal', 'Standard', '2024-11-05', N'Y1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);

    SELECT * INTO #Before FROM Layercake.fact_membership_events;

    DECLARE @raised bit = 0, @errno int = NULL;
    BEGIN TRY
        EXEC Layercake.usp_load_fact_membership_events_segments;
    END TRY
    BEGIN CATCH
        SET @raised = 1;
        SET @errno = ERROR_NUMBER();
    END CATCH;

    IF @raised = 0
        EXEC tSQLt.Fail 'usp_load_fact_membership_events_segments did not fail its silver-to-gold check';
    IF @errno IN (201, 207, 208, 2812)
        EXEC tSQLt.Fail 'the load failed for a reason other than its check: missing object, column or parameter';

    SELECT * INTO #After FROM Layercake.fact_membership_events;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'fact_membership_events changed by a failed load';

    SELECT l.status, CASE WHEN l.error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT CAST(v.status AS varchar(10)) AS status, v.has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO

CREATE PROCEDURE test_MOD012.[test TC-012-026 gold copies all nine new column values from silver by event_id]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2601, N'RA:Z1:2025', 'Readmission', 'Standard', '2025-03-10', N'Z1', 2, 1, 2025, 'Q2', 5, 1, 2, 1, 2, 1, 425.5000, 425.5000, 'Invoiced'),
           (2602, N'RN:Z1:2025', 'Renewal', 'Standard', '2024-11-05', N'Z1', 2, 1, 2025, 'Q1', 5, 1, 2, 1, 2, 1, NULL, NULL, 'Counted on another event'),
           (2603, N'RN:Z2:2025', 'Renewal', 'Standard', '2024-11-05', N'Z2', 2, 1, 2025, 'Q1', 3, 0, 1, 0, 3, 0, 0.0000, 0.0000, 'Fully credited');
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (2601, 'Readmission', 'Standard', '2025-03-10', N'Z1', 2, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (2602, 'Renewal', 'Standard', '2024-11-05', N'Z1', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, 100.0000, 100.0000, 'Invoiced'),
           (2603, 'Renewal', 'Standard', '2024-11-05', N'Z2', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);

    EXEC Layercake.usp_load_fact_membership_events_segments;

    SELECT event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.fact_membership_events;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried, v.concession_type_id, v.concession_type_carried,
           CAST(v.subs_amount_gbp AS decimal(19,4)) AS subs_amount_gbp, CAST(v.invoiced_subtotal_gbp AS decimal(19,4)) AS invoiced_subtotal_gbp, CAST(v.amount_status AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (2601, 5, 1, 2, 1, 2, 1, 425.5000, 425.5000, 'Invoiced'),
                 (2602, 5, 1, 2, 1, 2, 1, NULL, NULL, 'Counted on another event'),
                 (2603, 3, 0, 1, 0, 3, 0, 0.0000, 0.0000, 'Fully credited')) AS v(event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
