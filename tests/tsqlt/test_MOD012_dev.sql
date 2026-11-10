EXEC tSQLt.NewTestClass 'test_MOD012_dev';
GO

-- No fakes here: reads the deployed definitions, which TC-012-012 cannot see because its
-- class SetUp fakes both tables (FakeTable makes every column nullable).
CREATE PROCEDURE test_MOD012_dev.[test deployed event tables hold the nine columns with the designed nullability and none of the eight dropped]
AS
BEGIN
    SELECT c.TABLE_NAME COLLATE DATABASE_DEFAULT AS table_name,
           c.COLUMN_NAME COLLATE DATABASE_DEFAULT AS column_name,
           c.DATA_TYPE COLLATE DATABASE_DEFAULT AS data_type,
           c.IS_NULLABLE COLLATE DATABASE_DEFAULT AS is_nullable
    INTO #Actual
    FROM INFORMATION_SCHEMA.COLUMNS AS c
    WHERE c.TABLE_SCHEMA = 'Layercake'
      AND c.TABLE_NAME IN ('silv_membership_events', 'fact_membership_events')
      AND c.COLUMN_NAME IN ('payment_method_id', 'payment_method_carried', 'payer_type_id', 'payer_type_carried',
                            'concession_type_id', 'concession_type_carried', 'subs_amount_gbp', 'invoiced_subtotal_gbp',
                            'amount_status', 'subs_amount', 'fee_amount', 'invoiced_subtotal', 'credited_amount',
                            'currency_id', 'fee_amount_gbp', 'credited_amount_gbp', 'net_amount_gbp');

    SELECT v.table_name, v.column_name, v.data_type, v.is_nullable
    INTO #Expected
    FROM (VALUES
        (N'silv_membership_events', N'payment_method_id', N'int', 'NO'),
        (N'silv_membership_events', N'payment_method_carried', N'bit', 'NO'),
        (N'silv_membership_events', N'payer_type_id', N'int', 'NO'),
        (N'silv_membership_events', N'payer_type_carried', N'bit', 'NO'),
        (N'silv_membership_events', N'concession_type_id', N'int', 'NO'),
        (N'silv_membership_events', N'concession_type_carried', N'bit', 'NO'),
        (N'silv_membership_events', N'subs_amount_gbp', N'decimal', 'YES'),
        (N'silv_membership_events', N'invoiced_subtotal_gbp', N'decimal', 'YES'),
        (N'silv_membership_events', N'amount_status', N'varchar', 'YES'),
        (N'fact_membership_events', N'payment_method_id', N'int', 'NO'),
        (N'fact_membership_events', N'payment_method_carried', N'bit', 'NO'),
        (N'fact_membership_events', N'payer_type_id', N'int', 'NO'),
        (N'fact_membership_events', N'payer_type_carried', N'bit', 'NO'),
        (N'fact_membership_events', N'concession_type_id', N'int', 'NO'),
        (N'fact_membership_events', N'concession_type_carried', N'bit', 'NO'),
        (N'fact_membership_events', N'subs_amount_gbp', N'decimal', 'YES'),
        (N'fact_membership_events', N'invoiced_subtotal_gbp', N'decimal', 'YES'),
        (N'fact_membership_events', N'amount_status', N'varchar', 'YES')
    ) AS v(table_name, column_name, data_type, is_nullable);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

-- Choice: a Join's segment year comes from silv_payment_events (RULE-032), not from its
-- silv_event_amount row, so it holds even when the amount row is missing; an event with
-- no amount row gets null amounts and status, replacing stale values.
CREATE PROCEDURE test_MOD012_dev.[test join with no amount row takes its first paid year segments and null amounts]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_event_amount', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1;

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, corporate_account_ref, concession_type_id, concession_type_carried, segment_invoice_rec_id, load_id, created_at, updated_at)
    VALUES (N'Q1', 2024, 2, 0, 0, 0, NULL, 0, 0, NULL, 1, '2026-01-01', '2026-01-01'),
           (N'Q1', 2025, 1, 0, 1, 0, NULL, 3, 0, 1, 1, '2026-01-01', '2026-01-01');
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'Q1', 2026, '2025-10-20', '2025-10-20', N'Fully Paid'),
           (N'Q1', 2025, '2024-10-20', '2024-10-20', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1, N'JR:Q1', 'Join', 'Direct Entry', '2024-03-01', N'Q1', 1, 1, 2024, 'Q2', 0, 0, 0, 0, 0, 0, 50.0000, 50.0000, 'Invoiced');

    EXEC Layercake.usp_load_silv_membership_events_segments;

    SELECT event_id, payment_method_id, payer_type_id, concession_type_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Actual
    FROM Layercake.silv_membership_events;

    SELECT v.event_id, v.payment_method_id, v.payer_type_id, v.concession_type_id,
           CAST(v.subs_amount_gbp AS decimal(19,4)) AS subs_amount_gbp, CAST(v.invoiced_subtotal_gbp AS decimal(19,4)) AS invoiced_subtotal_gbp,
           CAST(v.amount_status AS varchar(30)) AS amount_status
    INTO #Expected
    FROM (VALUES (1, 1, 1, 3, NULL, NULL, NULL)) AS v(event_id, payment_method_id, payer_type_id, concession_type_id, subs_amount_gbp, invoiced_subtotal_gbp, amount_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD012_dev.[test silver case only change in amount_status is written and logged as one update]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_event_amount', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1;

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1, N'RN:Q2:2025', 'Renewal', 'Standard', '2024-11-05', N'Q2', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, 450.0000, 450.0000, 'invoiced'),
           (2, N'RN:Q3:2025', 'Renewal', 'Standard', '2024-11-05', N'Q3', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, 300.0000, 300.0000, 'Invoiced');
    INSERT INTO Layercake.silv_event_amount (event_nk, event_id, contact_no, event_type, event_date, amount_campaign_year, invoice_rec_id, match_outcome, subs_amount_gbp, invoiced_subtotal_gbp, amount_status, load_id, created_at, updated_at)
    VALUES (N'RN:Q2:2025', 1, N'Q2', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 450.0000, 450.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01'),
           (N'RN:Q3:2025', 2, N'Q3', 'Renewal', '2024-11-05', 2025, NULL, 'No eligible invoice', 300.0000, 300.0000, 'Invoiced', 1, '2026-01-01', '2026-01-01');

    EXEC Layercake.usp_load_silv_membership_events_segments;

    SELECT event_id, CAST(amount_status AS varbinary(30)) AS amount_status_bytes
    INTO #Actual
    FROM Layercake.silv_membership_events;

    SELECT v.event_id, CAST(CAST(v.amount_status AS varchar(30)) AS varbinary(30)) AS amount_status_bytes
    INTO #Expected
    FROM (VALUES (1, 'Invoiced'), (2, 'Invoiced')) AS v(event_id, amount_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'amount_status bytes';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT CAST(v.status AS varchar(10)) AS status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO

CREATE PROCEDURE test_MOD012_dev.[test gold case only change in amount_status is copied and logged with literal zero inserted and deleted]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1;

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1, N'RN:Q4:2025', 'Renewal', 'Standard', '2024-11-05', N'Q4', 2, 1, 2025, 'Q1', 2, 0, 1, 0, 1, 0, 450.0000, 450.0000, 'Invoiced');
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1, 'Renewal', 'Standard', '2024-11-05', N'Q4', 2, 1, 2025, 'Q1', 2, 0, 1, 0, 1, 0, 450.0000, 450.0000, 'INVOICED');

    EXEC Layercake.usp_load_fact_membership_events_segments;

    SELECT event_id, CAST(amount_status AS varbinary(30)) AS amount_status_bytes
    INTO #Actual
    FROM Layercake.fact_membership_events;

    SELECT v.event_id, CAST(CAST(v.amount_status AS varchar(30)) AS varbinary(30)) AS amount_status_bytes
    INTO #Expected
    FROM (VALUES (1, 'Invoiced')) AS v(event_id, amount_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'amount_status bytes';

    SELECT l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT CAST(v.status AS varchar(10)) AS status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('Success', 0, 1, 0)) AS v(status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD012_dev.[test gold check fails with 50001 when gold holds an event silver lacks and leaves the fact unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1;

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1, N'RN:Q5:2025', 'Renewal', 'Standard', '2024-11-05', N'Q5', 2, 1, 2025, 'Q1', 2, 0, 1, 0, 1, 0, 450.0000, 450.0000, 'Invoiced');
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1, 'Renewal', 'Standard', '2024-11-05', N'Q5', 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (2, 'Lapse', 'Standard', '2025-05-01', N'Q6', 2, 1, 2025, 'Q3', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);

    SELECT event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #Before
    FROM Layercake.fact_membership_events;

    BEGIN TRY
        EXEC Layercake.usp_load_fact_membership_events_segments;
        EXEC tSQLt.Fail 'usp_load_fact_membership_events_segments did not fail its silver-to-gold check';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 50001 THROW;
    END CATCH;

    SELECT event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status
    INTO #After
    FROM Layercake.fact_membership_events;

    EXEC tSQLt.AssertEqualsTable '#Before', '#After', 'fact changed by a failed load';

    SELECT l.status, CASE WHEN l.error_message LIKE N'Silver-to-gold check failed%' THEN 1 ELSE 0 END AS names_check
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT CAST(v.status AS varchar(10)) AS status, v.names_check
    INTO #ExpectedLog
    FROM (VALUES ('Failed', 1)) AS v(status, names_check);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO

-- Gold holds event 3 where silver holds event 2: the counts by payment_method_id and by
-- amount_status agree (2 each), so only the amount sums (750.00 against 550.00) can fail it.
--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD012_dev.[test gold check fails when only an amount sum differs]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1;

    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1, N'RN:Q7:2025', 'Renewal', 'Standard', '2024-11-05', N'Q7', 2, 1, 2025, 'Q1', 2, 0, 1, 0, 1, 0, 450.0000, 450.0000, 'Invoiced'),
           (2, N'RN:Q8:2025', 'Renewal', 'Standard', '2024-11-05', N'Q8', 2, 1, 2025, 'Q1', 2, 0, 1, 0, 1, 0, 100.0000, 100.0000, 'Invoiced');
    INSERT INTO Layercake.fact_membership_events (event_id, event_type, event_subtype, event_date, contact_no, grade_id, membership_status_id, campaign_year, campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (1, 'Renewal', 'Standard', '2024-11-05', N'Q7', 2, 1, 2025, 'Q1', 2, 0, 1, 0, 1, 0, 450.0000, 450.0000, 'Invoiced'),
           (3, 'Renewal', 'Standard', '2024-11-05', N'Q9', 2, 1, 2025, 'Q1', 2, 0, 1, 0, 1, 0, 300.0000, 300.0000, 'Invoiced');

    BEGIN TRY
        EXEC Layercake.usp_load_fact_membership_events_segments;
        EXEC tSQLt.Fail 'usp_load_fact_membership_events_segments did not fail on differing amount sums';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 50001 THROW;
    END CATCH;

    SELECT l.status
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l;

    SELECT CAST(v.status AS varchar(10)) AS status
    INTO #ExpectedLog
    FROM (VALUES ('Failed')) AS v(status);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog', 'etl_run_log row';
END;
GO
