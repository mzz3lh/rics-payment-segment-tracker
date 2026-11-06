EXEC tSQLt.NewTestClass 'test_MOD008_dev';
GO

CREATE PROCEDURE test_MOD008_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code)
    VALUES (0, 'Unknown', NULL), (-1, 'Unrecognised', NULL), (-2, 'Not applicable', NULL),
           (1, 'Direct Debit', 'DD'), (2, 'Card', 'Card'), (5, 'Corporate', 'Corporate');

    INSERT INTO Layercake.silv_ref_concession_type
        (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL),
           (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL),
           (1, NULL, N'No concession', NULL, 0, 0, NULL),
           (2, 'A0000000-0000-0000-0000-000000000001', N'Retired', N'CONRETIRED', 1, 1, 1);
END;
GO

CREATE PROCEDURE test_MOD008_dev.[test an unknown code is raised beside a recognised one, and case or trailing-space spellings are one case]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_payment_method, _is_deleted)
    VALUES (1001, N'D1', 2025, N'INV-D1', N'V-D1', N'Card', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (1, N'D1', N'INV-D1', N'V-D1', N'CONRETIRED', N'SUB', 0),
           (2, N'D1', N'INV-D1', N'V-D1', N'CONUNKNOWN', N'SUB', 0),
           (3, N'D1', N'INV-D1', N'V-D1', N'conunknown ', N'SUB', 0),
           (4, N'D1', N'INV-D1', N'V-D1', N'CONGONE', N'SUB', 1);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'D1', 2025, 2, 0, 1, 0, 2, 0, 1001, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_nk, anomaly_type, contact_no
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    SELECT anomaly_nk, anomaly_type, contact_no
    INTO #Expected
    FROM (VALUES (CAST(N'CONCESSION_NOT_IN_REFERENCE:D1:2025:CONUNKNOWN' AS nvarchar(240)),
                  CAST('CONCESSION_NOT_IN_REFERENCE' AS varchar(40)), CAST(N'D1' AS nvarchar(200)))) AS v(anomaly_nk, anomaly_type, contact_no);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008_dev.[test a still-raised case with a new segment invoice gets the new detail and keeps first_detected_at]
AS
BEGIN
    INSERT INTO Layercake.silv_data_anomaly
        (anomaly_nk, anomaly_type, contact_no, source_enr_id, detail, first_detected_at, last_seen_at, resolved_at)
    VALUES (N'CORPORATE_FLAG_NO_SCHEME:D2:2025', 'CORPORATE_FLAG_NO_SCHEME', N'D2', NULL, N'old invoice',
            '2025-01-01T00:00:00', '2025-01-01T00:00:00', NULL);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_payment_method, _is_deleted)
    VALUES (2002, N'D2', 2025, N'INV-D2-NEW', N'V-D2', N'Corporate', 0);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'D2', 2025, 5, 0, 1, 0, 1, 0, 2002, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_nk, detail, first_detected_at, last_seen_at
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    SELECT anomaly_nk, detail, first_detected_at, last_seen_at
    INTO #Expected
    FROM (VALUES (CAST(N'CORPORATE_FLAG_NO_SCHEME:D2:2025' AS nvarchar(240)),
                  CAST(N'Campaign Year 2025: segment invoice INV-D2-NEW (rec_id 2002) has payment method Corporate, but the contact has no live corporate subscription that year.' AS nvarchar(400)),
                  CAST('2025-01-01T00:00:00' AS datetime2(3)), CAST('2025-01-01T00:00:00' AS datetime2(3))))
         AS v(anomaly_nk, detail, first_detected_at, last_seen_at);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log;
    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD008_dev.[test a Full Concession position in a year with no segment invoice raises nothing]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, invoice_position)
    VALUES (N'D3', 2025, N'Full Concession');
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'D3', 2025, 0, 0, 1, 0, 0, 0, NULL, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_nk INTO #Actual FROM Layercake.silv_data_anomaly;
    EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008_dev.[test double payment counts an unrecognised mode as another method but not own lines or other accounts]
AS
BEGIN
    -- D4: Corporate plus an unrecognised mode is a double payment.
    -- D5: Corporate settles it; the Card modes are on the invoice's own line, on another
    -- account and blank, so none of them is another method.
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_payment_method, _is_deleted)
    VALUES (4004, N'D4', 2025, N'INV-D4', N'V-D4', N'Card', 0),
           (5005, N'D5', 2025, N'INV-D5', N'V-D5', N'Card', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line
        (recid, accountnum, invoice, voucher, lastsettlevoucher, productcode, settleamountcur, paymmode, _is_deleted)
    VALUES (41, N'D4', NULL, N'PAY-D4-1', N'V-D4', NULL, 100.00, N'Corporate', 0),
           (42, N'D4', NULL, N'PAY-D4-2', N'V-D4', NULL, 100.00, N'Voucher', 0),
           (51, N'D5', NULL, N'PAY-D5-1', N'V-D5', NULL, 100.00, N'Corporate', 0),
           (52, N'D5', N'INV-D5', N'V-D5', N'V-D5', N'SUBS', NULL, N'Card', 0),
           (53, N'OTHER', NULL, N'PAY-D5-2', N'V-D5', NULL, 100.00, N'Card', 0),
           (54, N'D5', NULL, N'PAY-D5-3', N'V-D5', NULL, 100.00, N'   ', 0);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'D4', 2025, 2, 0, 1, 0, 1, 0, 4004, 1),
           (N'D5', 2025, 2, 0, 1, 0, 1, 0, 5005, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_nk INTO #Actual FROM Layercake.silv_data_anomaly;
    SELECT anomaly_nk INTO #Expected
    FROM (VALUES (CAST(N'DOUBLE_PAYMENT:D4:2025' AS nvarchar(240)))) AS v(anomaly_nk);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD008_dev.[test a soft-deleted segment invoice raises nothing and removes its old case]
AS
BEGIN
    INSERT INTO Layercake.silv_data_anomaly
        (anomaly_nk, anomaly_type, contact_no, source_enr_id, detail, first_detected_at, last_seen_at, resolved_at)
    VALUES (N'CORPORATE_FLAG_NO_SCHEME:D6:2025', 'CORPORATE_FLAG_NO_SCHEME', N'D6', NULL, N'old',
            '2025-01-01T00:00:00', '2025-01-01T00:00:00', NULL);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_payment_method, _is_deleted)
    VALUES (6006, N'D6', 2025, N'INV-D6', N'V-D6', N'Corporate', 1);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (N'D6', 2025, 5, 0, 1, 0, 1, 0, 6006, 1);

    EXEC Layercake.usp_load_silv_data_anomaly_segment;

    SELECT anomaly_nk INTO #Actual FROM Layercake.silv_data_anomaly;
    EXEC tSQLt.AssertEmptyTable '#Actual';

    SELECT status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log;
    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 0, 1)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD008_dev.[test an anomaly key too long for its column fails the load, logs Failed and changes nothing]
AS
BEGIN
    -- 'CONCESSION_NOT_IN_REFERENCE:' + 200-character contact + ':2025:CONUNKNOWN' exceeds nvarchar(240).
    DECLARE @long_contact nvarchar(200) = REPLICATE(N'X', 200);

    INSERT INTO Layercake.silv_data_anomaly
        (anomaly_nk, anomaly_type, contact_no, source_enr_id, detail, first_detected_at, last_seen_at, resolved_at)
    VALUES (N'DOUBLE_PAYMENT:STALE:2024', 'DOUBLE_PAYMENT', N'STALE', NULL, N'stale',
            '2024-11-01T00:00:00', '2024-11-01T00:00:00', NULL);
    INSERT INTO Layercake.brnz_subs_invoice (rec_id, account_num, campaign_year, invoice, voucher, inv_payment_method, _is_deleted)
    VALUES (7007, N'D7', 2025, N'INV-D7', N'V-D7', N'Card', 0);
    INSERT INTO Layercake.brnz_subs_invoice_line (recid, accountnum, invoice, voucher, productcode, ricinvoicetype, _is_deleted)
    VALUES (71, N'D7', N'INV-D7', N'V-D7', N'CONUNKNOWN', N'SUB', 0);
    INSERT INTO Layercake.silv_member_year_attributes
        (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id)
    VALUES (@long_contact, 2025, 2, 0, 1, 0, -1, 0, 7007, 1);

    SELECT anomaly_id, anomaly_nk, anomaly_type, contact_no, detail, first_detected_at, last_seen_at, resolved_at
    INTO #Before
    FROM Layercake.silv_data_anomaly;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_data_anomaly_segment;
        EXEC tSQLt.Fail 'Expected the load to fail on an over-long anomaly_nk, but it did not.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2628, 8152)
            THROW;
    END CATCH;

    SELECT anomaly_id, anomaly_nk, anomaly_type, contact_no, detail, first_detected_at, last_seen_at, resolved_at
    INTO #After
    FROM Layercake.silv_data_anomaly;
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

CREATE PROCEDURE test_MOD008_dev.[test the Phase 1 anomaly load resolves only its own types and leaves segment and invoice types open]
AS
BEGIN
    -- Every Phase 1 source is empty, so no Phase 1 rule fires this run.
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_base';
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact_test_record', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_rics_record', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_cust_trans', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_enrolment_exception';
    EXEC tSQLt.FakeTable 'Layercake.vw_enrolment_base';
    EXEC tSQLt.FakeTable 'Layercake.vw_student_superseded';

    INSERT INTO Layercake.silv_data_anomaly
        (anomaly_nk, anomaly_type, contact_no, source_enr_id, detail, first_detected_at, last_seen_at, resolved_at)
    VALUES (N'NO_RICS_RECORD:E1', 'NO_RICS_RECORD', N'E1', NULL, N'phase 1 open',
            '2025-01-01T00:00:00', '2025-01-01T00:00:00', NULL),
           (N'JOIN_NO_PAYMENT:E2', 'JOIN_NO_PAYMENT', N'E2', NULL, N'phase 1 resolved',
            '2024-01-01T00:00:00', '2024-01-01T00:00:00', '2024-06-01T00:00:00'),
           (N'CORPORATE_FLAG_NO_SCHEME:E3:2025', 'CORPORATE_FLAG_NO_SCHEME', N'E3', NULL, N'segment open',
            '2025-01-01T00:00:00', '2025-01-01T00:00:00', NULL),
           (N'FULL_CONCESSION_NO_CONCESSION:E4:2025', 'FULL_CONCESSION_NO_CONCESSION', N'E4', NULL, N'segment open',
            '2025-01-01T00:00:00', '2025-01-01T00:00:00', NULL),
           (N'EV-E5-2025', 'EVENT_NO_INVOICE', N'E5', NULL, N'invoice open',
            '2025-01-01T00:00:00', '2025-01-01T00:00:00', NULL);

    EXEC Layercake.usp_load_silv_data_anomaly;

    SELECT anomaly_nk, CASE WHEN resolved_at IS NULL THEN 0 ELSE 1 END AS is_resolved
    INTO #Actual
    FROM Layercake.silv_data_anomaly;

    SELECT anomaly_nk, is_resolved
    INTO #Expected
    FROM (VALUES (CAST(N'NO_RICS_RECORD:E1' AS nvarchar(240)), 1),
                 (CAST(N'JOIN_NO_PAYMENT:E2' AS nvarchar(240)), 1),
                 (CAST(N'CORPORATE_FLAG_NO_SCHEME:E3:2025' AS nvarchar(240)), 0),
                 (CAST(N'FULL_CONCESSION_NO_CONCESSION:E4:2025' AS nvarchar(240)), 0),
                 (CAST(N'EV-E5-2025' AS nvarchar(240)), 0)) AS v(anomaly_nk, is_resolved);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    -- The already-resolved Phase 1 row keeps its original stamp.
    DECLARE @expected_resolved datetime2(3) = '2024-06-01T00:00:00';
    DECLARE @e2_resolved datetime2(3) = (SELECT resolved_at FROM Layercake.silv_data_anomaly WHERE anomaly_nk = N'JOIN_NO_PAYMENT:E2');
    EXEC tSQLt.AssertEquals @expected_resolved, @e2_resolved;

    SELECT status, rows_inserted, rows_updated, rows_deleted INTO #ActualLog FROM Layercake.etl_run_log;
    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('Success' AS varchar(10)), 0, 0, 1)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
