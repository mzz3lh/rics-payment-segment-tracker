EXEC tSQLt.NewTestClass 'test_MOD016';
GO

CREATE PROCEDURE test_MOD016.[SetUp]
AS
BEGIN
    -- External sources the run's bronze loads read (stand-ins in dev and test).
    EXEC tSQLt.FakeTable 'Subs.tblSubsInvoices';
    EXEC tSQLt.FakeTable 'synapse_fo.CUSTTRANS_RICS';
    EXEC tSQLt.FakeTable 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.FakeTable 'CE.vwConcessionType';

    -- Bronze (the loads leave the audit columns to their defaults).
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_invoice_line', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_corporate_subscription', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_concession', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status', @Defaults = 1;

    -- Silver.
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_invoice_line_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_currency', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_event_amount', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_data_anomaly', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';

    -- Gold.
    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_currency', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_membership_events', @Defaults = 1;

    -- Logging.
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;

    -- Seeded reference lists (seed ids).
    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code)
    VALUES (0, 'Unknown', NULL), (-1, 'Unrecognised', NULL), (-2, 'Not applicable', NULL),
           (1, 'Direct Debit', 'DD'), (2, 'Card', 'Card'), (3, 'Bank transfer', 'Bank'),
           (4, 'Cheque', 'Cheque'), (5, 'Corporate', 'Corporate');

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name)
    VALUES (0, 'Unknown'), (-1, 'Unrecognised'), (-2, 'Not applicable'), (1, 'Individual'), (2, 'Corporate');

    SET IDENTITY_INSERT Layercake.silv_ref_concession_type ON;
    INSERT INTO Layercake.silv_ref_concession_type
        (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL, '20250101', '20250101'),
           (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL, '20250101', '20250101'),
           (-2, NULL, N'Not applicable', NULL, 0, 0, NULL, '20250101', '20250101'),
           (1, NULL, N'No concession', NULL, 0, 0, NULL, '20250101', '20250101');
    SET IDENTITY_INSERT Layercake.silv_ref_concession_type OFF;

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2023, '20221001', '20230930', '20230601'),
           (2024, '20231001', '20240930', '20240601'),
           (2025, '20241001', '20250930', '20250601');

    -- Synthetic sources: invoices for C1 (2024 DD, 2025 Card), C2 (2025 Corporate, live scheme),
    -- C5 (2025 Corporate, no scheme) and C6 (2025, no event).
    INSERT INTO Subs.tblSubsInvoices
        (Rec_ID, Account_Num, Campaign_Year, Invoice, Voucher, Trans_Date, Inv_Payment_Method, Inv_Currency,
         Exchange_Rate, Full_Invoice_Amount_CUR, Invoice_Amount_CUR, Invoice_Amount_GBP, Inv_Credit_Amount_CUR,
         Inv_Credit_Amount_GBP, Fully_Credited, Payment_Status, Has_Concession, [100%_Concession])
    VALUES (1001, N'C1', 2024, N'INV-1001', N'V1001', '20231001', N'DD', N'GBP', 1, 450, 450, 450, 0, 0, 'N', N'Fully Paid', 'N', 'N'),
           (1002, N'C1', 2025, N'INV-1002', N'V1002', '20241001', N'Card', N'GBP', 1, 475, 475, 475, 0, 0, 'N', N'Fully Paid', 'N', 'N'),
           (2001, N'C2', 2025, N'INV-2001', N'V2001', '20241002', N'Corporate', N'GBP', 1, 300, 300, 300, 0, 0, 'N', N'Fully Paid', 'N', 'N'),
           (3001, N'C5', 2025, N'INV-3001', N'V3001', '20241003', N'Corporate', N'GBP', 1, 520, 520, 520, 0, 0, 'N', N'Fully Paid', 'N', 'N'),
           (4001, N'C6', 2025, N'INV-4001', N'V4001', '20241005', N'DD', N'GBP', 1, 410, 410, 410, 0, 0, 'N', N'Fully Paid', 'N', 'N');

    INSERT INTO synapse_fo.CUSTTRANS_RICS
        (RECID, ACCOUNTNUM, INVOICE, VOUCHER, LASTSETTLEVOUCHER, TRANSDATE, TRANSTYPE, RICINVOICETYPE, productcode,
         AMOUNTCUR, AMOUNTMST, SETTLEAMOUNTCUR, CURRENCYCODE, PAYMMODE, PAYMREFERENCE, ORDERNUM,
         POSTINGTYPE, ACCOUNTDISPLAYVALUE, MainAccount, CostCenter, RICSCAMPAIGNYEAR)
    VALUES (5001, N'C1', N'INV-1001', N'V1001', NULL, '20231001', 2, 'SUB', N'MRICS', 450, 450, 450, N'GBP', NULL, NULL, NULL,
            41, N'400100-CC10-UK-MRICS-2024', N'400100', N'CC10', N'2024'),
           (5002, N'C1', N'INV-1002', N'V1002', NULL, '20241001', 2, 'SUB', N'MRICS', 475, 475, 475, N'GBP', NULL, NULL, NULL,
            41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025'),
           (5003, N'C2', N'INV-2001', N'V2001', NULL, '20241002', 2, 'SUB', N'FRICS', 300, 300, 300, N'GBP', NULL, NULL, NULL,
            41, N'400100-CC10-UK-FRICS-2025', N'400100', N'CC10', N'2025'),
           (5004, N'C5', N'INV-3001', N'V3001', NULL, '20241003', 2, 'SUB', N'MRICS', 520, 520, 520, N'GBP', NULL, NULL, NULL,
            41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025'),
           (5999, N'C9', N'INV-9999', N'V9999', NULL, '20241004', 2, 'SUB', N'MRICS', 100, 100, 100, N'GBP', NULL, NULL, NULL,
            41, N'400100-CC10-UK-MRICS-2025', N'400100', N'CC10', N'2025');

    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status])
    VALUES (N'C2', N'S-100', N'Acme scheme', 2025, N'Active', N'Active');

    INSERT INTO CE.vwConcessionType
        (Id, apuk_concessiontypeid, apuk_name, apuk_discount, Product_Number, statecode, apuk_perpetualnonperpetual)
    VALUES ('6A1F0000-0000-0000-0000-000000000001', '6A1F0000-0000-0000-0000-000000000001', N'Retired', 100.00,
            N'rcsCONRETIRED', 0, 200000000);

    -- Phase 1 tables the run reads, as the Phase 1 run leaves them.
    INSERT INTO Layercake.brnz_subs_status
        ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj],
         inv_total_amount, retired_concession, _is_deleted)
    VALUES (N'C1', 2024, 'Fully Paid', '20231020', '20231020', 450.000000, 'No Conc.', 0),
           (N'C1', 2025, 'Fully Paid', '20241015', '20241015', 475.000000, 'No Conc.', 0),
           (N'C2', 2025, 'Fully Paid', '20241012', '20241012', 300.000000, 'No Conc.', 0),
           (N'C5', 2025, 'Fully Paid', '20241020', '20241020', 520.000000, 'No Conc.', 0);

    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'C1', 2024, '20231020', '20231020', N'Fully Paid'),
           (N'C1', 2025, '20241015', '20241015', N'Fully Paid'),
           (N'C2', 2025, '20241012', '20241012', N'Fully Paid'),
           (N'C5', 2025, '20241020', '20241020', N'Fully Paid');

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id,
         assessment_route_id, rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year,
         campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (101, N'RN:C1:2024', 'Renewal', 'Standard', '20231020', NULL, N'C1', 2, 0, 0, 0, 0, 0, 1, 2024, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (102, N'RN:C1:2025', 'Renewal', 'Standard', '20241015', NULL, N'C1', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (201, N'RN:C2:2025', 'Renewal', 'Standard', '20241012', NULL, N'C2', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (301, N'JR:C3', 'Join', 'Direct Entry', '20241105', NULL, N'C3', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (401, N'LA:C4', 'Lapse', 'Standard', '20250601', NULL, N'C4', 0, 0, 0, 0, 0, 0, 0, 2025, 'Q3', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
           (501, N'RN:C5:2025', 'Renewal', 'Standard', '20241020', NULL, N'C5', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0, NULL, NULL, NULL);

    INSERT INTO Layercake.fact_membership_events
        (event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id,
         rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id,
         concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    SELECT e.event_id, e.event_type, e.event_subtype, e.event_date,
           CONVERT(int, CONVERT(char(8), e.event_date, 112)), e.contact_no, e.grade_id, e.assessment_route_id,
           e.rpq_variant_id, e.hpb_id, e.country_id, e.gender_id, e.membership_status_id, e.campaign_year,
           e.campaign_quarter, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL
    FROM Layercake.silv_membership_events AS e;

    -- A Phase 1 anomaly the new loads must leave alone.
    INSERT INTO Layercake.silv_data_anomaly
        (anomaly_nk, anomaly_type, contact_no, source_enr_id, detail, first_detected_at, last_seen_at, resolved_at)
    VALUES (N'NO_ELECTION_DATE:C4', 'NO_ELECTION_DATE', N'C4', NULL, N'Phase 1 test row', '20250101', '20250101', NULL);
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-001 one run from empty targets fills the segment and amount columns of every silver event]
AS
BEGIN
    EXEC Layercake.usp_run_payment_segments @as_of_date = '20250615';

    SELECT e.event_id,
           e.payment_method_id,
           CAST(e.payment_method_carried AS int) AS payment_method_carried,
           e.payer_type_id,
           CAST(e.payer_type_carried AS int) AS payer_type_carried,
           e.concession_type_id,
           CAST(e.concession_type_carried AS int) AS concession_type_carried,
           e.subs_amount_gbp,
           e.invoiced_subtotal_gbp,
           e.amount_status
    INTO #Actual
    FROM Layercake.silv_membership_events AS e;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried,
           v.concession_type_id, v.concession_type_carried, v.subs_amount_gbp, v.invoiced_subtotal_gbp, v.amount_status
    INTO #Expected
    FROM (VALUES (101, 1, 0, 1, 0, 1, 0, CAST(450.0000 AS decimal(19,4)), CAST(450.0000 AS decimal(19,4)), CAST('Invoiced' AS varchar(30))),
                 (102, 2, 0, 1, 0, 1, 0, CAST(475.0000 AS decimal(19,4)), CAST(475.0000 AS decimal(19,4)), CAST('Invoiced' AS varchar(30))),
                 (201, 5, 0, 2, 0, 1, 0, CAST(300.0000 AS decimal(19,4)), CAST(300.0000 AS decimal(19,4)), CAST('Invoiced' AS varchar(30))),
                 (301, 0, 0, 0, 0, 0, 0, NULL, NULL, CAST('No invoice' AS varchar(30))),
                 (401, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
                 (501, 5, 0, 1, 0, 1, 0, CAST(520.0000 AS decimal(19,4)), CAST(520.0000 AS decimal(19,4)), CAST('Invoiced' AS varchar(30))))
         AS v (event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
               concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-002 one run copies the new columns onto every gold fact]
AS
BEGIN
    EXEC Layercake.usp_run_payment_segments @as_of_date = '20250615';

    SELECT f.event_id,
           f.payment_method_id,
           CAST(f.payment_method_carried AS int) AS payment_method_carried,
           f.payer_type_id,
           CAST(f.payer_type_carried AS int) AS payer_type_carried,
           f.concession_type_id,
           CAST(f.concession_type_carried AS int) AS concession_type_carried,
           f.subs_amount_gbp,
           f.invoiced_subtotal_gbp,
           f.amount_status
    INTO #Actual
    FROM Layercake.fact_membership_events AS f;

    SELECT v.event_id, v.payment_method_id, v.payment_method_carried, v.payer_type_id, v.payer_type_carried,
           v.concession_type_id, v.concession_type_carried, v.subs_amount_gbp, v.invoiced_subtotal_gbp, v.amount_status
    INTO #Expected
    FROM (VALUES (101, 1, 0, 1, 0, 1, 0, CAST(450.0000 AS decimal(19,4)), CAST(450.0000 AS decimal(19,4)), CAST('Invoiced' AS varchar(30))),
                 (102, 2, 0, 1, 0, 1, 0, CAST(475.0000 AS decimal(19,4)), CAST(475.0000 AS decimal(19,4)), CAST('Invoiced' AS varchar(30))),
                 (201, 5, 0, 2, 0, 1, 0, CAST(300.0000 AS decimal(19,4)), CAST(300.0000 AS decimal(19,4)), CAST('Invoiced' AS varchar(30))),
                 (301, 0, 0, 0, 0, 0, 0, NULL, NULL, CAST('No invoice' AS varchar(30))),
                 (401, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL),
                 (501, 5, 0, 1, 0, 1, 0, CAST(520.0000 AS decimal(19,4)), CAST(520.0000 AS decimal(19,4)), CAST('Invoiced' AS varchar(30))))
         AS v (event_id, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
               concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-003 one run fills the four gold dimensions from their silver lists]
AS
BEGIN
    EXEC Layercake.usp_run_payment_segments @as_of_date = '20250615';

    SELECT d.id, d.payment_method_name INTO #ActualPm FROM Layercake.dim_payment_method AS d;
    SELECT v.id, v.payment_method_name
    INTO #ExpectedPm
    FROM (VALUES (0, CAST('Unknown' AS varchar(30))), (-1, 'Unrecognised'), (-2, 'Not applicable'), (1, 'Direct Debit'),
                 (2, 'Card'), (3, 'Bank transfer'), (4, 'Cheque'), (5, 'Corporate')) AS v (id, payment_method_name);
    EXEC tSQLt.AssertEqualsTable '#ExpectedPm', '#ActualPm';

    SELECT d.id, d.payer_type_name INTO #ActualPt FROM Layercake.dim_payer_type AS d;
    SELECT v.id, v.payer_type_name
    INTO #ExpectedPt
    FROM (VALUES (0, CAST('Unknown' AS varchar(30))), (-1, 'Unrecognised'), (-2, 'Not applicable'), (1, 'Individual'),
                 (2, 'Corporate')) AS v (id, payer_type_name);
    EXEC tSQLt.AssertEqualsTable '#ExpectedPt', '#ActualPt';

    SELECT d.currency_code,
           CASE WHEN EXISTS (SELECT 1 FROM Layercake.silv_ref_currency AS s
                             WHERE s.id = d.id AND s.currency_code = d.currency_code) THEN 1 ELSE 0 END AS same_id_as_silver
    INTO #ActualCur
    FROM Layercake.dim_currency AS d;
    SELECT v.currency_code, v.same_id_as_silver
    INTO #ExpectedCur
    FROM (VALUES (CAST(N'GBP' AS nvarchar(3)), 1)) AS v (currency_code, same_id_as_silver);
    EXEC tSQLt.AssertEqualsTable '#ExpectedCur', '#ActualCur';

    SELECT d.concession_type_name,
           CAST(d.is_full_concession AS int) AS is_full_concession,
           CAST(d.is_perpetual AS int) AS is_perpetual,
           CASE WHEN EXISTS (SELECT 1 FROM Layercake.silv_ref_concession_type AS s
                             WHERE s.id = d.id AND s.concession_type_name = d.concession_type_name) THEN 1 ELSE 0 END AS same_id_as_silver
    INTO #ActualCt
    FROM Layercake.dim_concession_type AS d;
    SELECT v.concession_type_name, v.is_full_concession, v.is_perpetual, v.same_id_as_silver
    INTO #ExpectedCt
    FROM (VALUES (CAST(N'Unknown' AS nvarchar(100)), 0, 0, 1), (N'Unrecognised', 0, 0, 1), (N'Not applicable', 0, 0, 1),
                 (N'No concession', 0, 0, 1), (N'Retired', 1, 1, 1))
         AS v (concession_type_name, is_full_concession, is_perpetual, same_id_as_silver);
    EXEC tSQLt.AssertEqualsTable '#ExpectedCt', '#ActualCt';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-004 one run raises the segment and invoice anomalies and leaves the Phase 1 anomaly untouched]
AS
BEGIN
    EXEC Layercake.usp_run_payment_segments @as_of_date = '20250615';

    SELECT a.anomaly_nk, a.anomaly_type, a.contact_no,
           CASE WHEN a.resolved_at IS NULL THEN 1 ELSE 0 END AS is_open
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a;

    SELECT v.anomaly_nk, v.anomaly_type, v.contact_no, v.is_open
    INTO #Expected
    FROM (VALUES (CAST(N'NO_ELECTION_DATE:C4' AS nvarchar(240)), CAST('NO_ELECTION_DATE' AS varchar(40)), CAST(N'C4' AS nvarchar(200)), 1),
                 (N'EVENT_NO_INVOICE:JR:C3', 'EVENT_NO_INVOICE', N'C3', 1),
                 (N'CORPORATE_FLAG_NO_SCHEME:C5:2025', 'CORPORATE_FLAG_NO_SCHEME', N'C5', 1),
                 (N'INVOICE_NO_EVENT:4001', 'INVOICE_NO_EVENT', N'C6', 1))
         AS v (anomaly_nk, anomaly_type, contact_no, is_open);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @phase1_detail nvarchar(400) =
        (SELECT a.detail FROM Layercake.silv_data_anomaly AS a WHERE a.anomaly_nk = N'NO_ELECTION_DATE:C4');
    EXEC tSQLt.AssertEqualsString N'Phase 1 test row', @phase1_detail;
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-005 one run logs every load as a Success step under the run id]
AS
BEGIN
    DECLARE @run_id uniqueidentifier = NEWID();

    EXEC Layercake.usp_run_payment_segments @run_id = @run_id, @as_of_date = '20250615';

    SELECT l.layer, l.step_name, l.status
    INTO #Actual
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @run_id;

    SELECT v.layer, v.step_name, v.status
    INTO #Expected
    FROM (VALUES (CAST('run' AS varchar(12)), CAST('usp_run_payment_segments' AS varchar(128)), CAST('Success' AS varchar(10))),
                 ('bronze', 'brnz_subs_invoice', 'Success'),
                 ('bronze', 'brnz_subs_invoice_line', 'Success'),
                 ('bronze', 'brnz_corporate_subscription', 'Success'),
                 ('bronze', 'brnz_concession', 'Success'),
                 ('silver', 'silv_ref_invoice_line_type', 'Success'),
                 ('silver', 'silv_ref_currency', 'Success'),
                 ('silver', 'silv_ref_concession_type', 'Success'),
                 ('gold', 'dim_payment_method', 'Success'),
                 ('gold', 'dim_payer_type', 'Success'),
                 ('gold', 'dim_currency', 'Success'),
                 ('gold', 'dim_concession_type', 'Success'),
                 ('silver', 'silv_member_year_attributes', 'Success'),
                 ('silver', 'silv_event_amount', 'Success'),
                 ('silver', 'silv_data_anomaly_segment', 'Success'),
                 ('silver', 'silv_data_anomaly_invoice', 'Success'),
                 ('silver', 'silv_membership_events_segments', 'Success'),
                 ('gold', 'fact_membership_events_segments', 'Success'))
         AS v (layer, step_name, status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @other_runs int = (SELECT COUNT(*) FROM Layercake.etl_run_log AS l WHERE l.run_id <> @run_id);
    EXEC tSQLt.AssertEquals 0, @other_runs;
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-006 a second full run on unchanged data logs 0 0 0 for every load and changes nothing]
AS
BEGIN
    DECLARE @run1 uniqueidentifier = NEWID(),
            @run2 uniqueidentifier = NEWID();

    EXEC Layercake.usp_run_payment_segments @run_id = @run1, @as_of_date = '20250615';

    SELECT * INTO #inv_before FROM Layercake.brnz_subs_invoice;
    SELECT * INTO #line_before FROM Layercake.brnz_subs_invoice_line;
    SELECT * INTO #corp_before FROM Layercake.brnz_corporate_subscription;
    SELECT * INTO #conc_before FROM Layercake.brnz_concession;
    SELECT * INTO #lt_before FROM Layercake.silv_ref_invoice_line_type;
    SELECT * INTO #cur_before FROM Layercake.silv_ref_currency;
    SELECT * INTO #ct_before FROM Layercake.silv_ref_concession_type;
    SELECT * INTO #attr_before FROM Layercake.silv_member_year_attributes;
    SELECT * INTO #amt_before FROM Layercake.silv_event_amount;
    SELECT * INTO #anom_before FROM Layercake.silv_data_anomaly;
    SELECT * INTO #ev_before FROM Layercake.silv_membership_events;
    SELECT * INTO #fact_before FROM Layercake.fact_membership_events;
    SELECT * INTO #dpm_before FROM Layercake.dim_payment_method;
    SELECT * INTO #dpt_before FROM Layercake.dim_payer_type;
    SELECT * INTO #dcur_before FROM Layercake.dim_currency;
    SELECT * INTO #dct_before FROM Layercake.dim_concession_type;

    EXEC Layercake.usp_run_payment_segments @run_id = @run2, @as_of_date = '20250615';

    SELECT l.layer, l.step_name, l.status, l.rows_inserted, l.rows_updated, l.rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @run2
      AND l.layer <> 'run';

    SELECT v.layer, v.step_name, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES (CAST('bronze' AS varchar(12)), CAST('brnz_subs_invoice' AS varchar(128)), CAST('Success' AS varchar(10)), 0, 0, 0),
                 ('bronze', 'brnz_subs_invoice_line', 'Success', 0, 0, 0),
                 ('bronze', 'brnz_corporate_subscription', 'Success', 0, 0, 0),
                 ('bronze', 'brnz_concession', 'Success', 0, 0, 0),
                 ('silver', 'silv_ref_invoice_line_type', 'Success', 0, 0, 0),
                 ('silver', 'silv_ref_currency', 'Success', 0, 0, 0),
                 ('silver', 'silv_ref_concession_type', 'Success', 0, 0, 0),
                 ('gold', 'dim_payment_method', 'Success', 0, 0, 0),
                 ('gold', 'dim_payer_type', 'Success', 0, 0, 0),
                 ('gold', 'dim_currency', 'Success', 0, 0, 0),
                 ('gold', 'dim_concession_type', 'Success', 0, 0, 0),
                 ('silver', 'silv_member_year_attributes', 'Success', 0, 0, 0),
                 ('silver', 'silv_event_amount', 'Success', 0, 0, 0),
                 ('silver', 'silv_data_anomaly_segment', 'Success', 0, 0, 0),
                 ('silver', 'silv_data_anomaly_invoice', 'Success', 0, 0, 0),
                 ('silver', 'silv_membership_events_segments', 'Success', 0, 0, 0),
                 ('gold', 'fact_membership_events_segments', 'Success', 0, 0, 0))
         AS v (layer, step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    DECLARE @anomaly_rows int = (SELECT COUNT(*) FROM Layercake.silv_data_anomaly);
    EXEC tSQLt.AssertEquals 4, @anomaly_rows;

    EXEC tSQLt.AssertEqualsTable '#inv_before', 'Layercake.brnz_subs_invoice';
    EXEC tSQLt.AssertEqualsTable '#line_before', 'Layercake.brnz_subs_invoice_line';
    EXEC tSQLt.AssertEqualsTable '#corp_before', 'Layercake.brnz_corporate_subscription';
    EXEC tSQLt.AssertEqualsTable '#conc_before', 'Layercake.brnz_concession';
    EXEC tSQLt.AssertEqualsTable '#lt_before', 'Layercake.silv_ref_invoice_line_type';
    EXEC tSQLt.AssertEqualsTable '#cur_before', 'Layercake.silv_ref_currency';
    EXEC tSQLt.AssertEqualsTable '#ct_before', 'Layercake.silv_ref_concession_type';
    EXEC tSQLt.AssertEqualsTable '#attr_before', 'Layercake.silv_member_year_attributes';
    EXEC tSQLt.AssertEqualsTable '#amt_before', 'Layercake.silv_event_amount';
    EXEC tSQLt.AssertEqualsTable '#anom_before', 'Layercake.silv_data_anomaly';
    EXEC tSQLt.AssertEqualsTable '#ev_before', 'Layercake.silv_membership_events';
    EXEC tSQLt.AssertEqualsTable '#fact_before', 'Layercake.fact_membership_events';
    EXEC tSQLt.AssertEqualsTable '#dpm_before', 'Layercake.dim_payment_method';
    EXEC tSQLt.AssertEqualsTable '#dpt_before', 'Layercake.dim_payer_type';
    EXEC tSQLt.AssertEqualsTable '#dcur_before', 'Layercake.dim_currency';
    EXEC tSQLt.AssertEqualsTable '#dct_before', 'Layercake.dim_concession_type';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD016.[test TC-016-007 a failing load stops the run re-raises its error and no later load runs]
AS
BEGIN
    DECLARE @run_id uniqueidentifier = NEWID(),
            @error_number int;

    -- A corporate subscription row with no Contact No fails usp_load_brnz_corporate_subscription with 515.
    INSERT INTO Subs.vwCorpSubscriptions
        ([Contact No], [Scheme No], [Scheme Name], [Sub Campaign Year], [Sub Status], [Sub User Status])
    VALUES (NULL, N'S-200', N'No contact scheme', 2025, N'Active', N'Active');

    BEGIN TRY
        EXEC Layercake.usp_run_payment_segments @run_id = @run_id, @as_of_date = '20250615';
        EXEC tSQLt.Fail 'usp_run_payment_segments completed although usp_load_brnz_corporate_subscription failed.';
    END TRY
    BEGIN CATCH
        SET @error_number = ERROR_NUMBER();
        IF @error_number <> 515
            THROW;
    END CATCH;

    EXEC tSQLt.AssertEquals 515, @error_number;

    SELECT l.layer, l.step_name, l.status,
           CASE WHEN l.error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualFailed
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @run_id
      AND l.status <> 'Success';

    SELECT v.layer, v.step_name, v.status, v.has_error_message
    INTO #ExpectedFailed
    FROM (VALUES (CAST('bronze' AS varchar(12)), CAST('brnz_corporate_subscription' AS varchar(128)), CAST('Failed' AS varchar(10)), 1),
                 ('run', 'usp_run_payment_segments', 'Failed', 1))
         AS v (layer, step_name, status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedFailed', '#ActualFailed';

    SELECT l.layer, l.step_name
    INTO #LaterSteps
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @run_id
      AND l.layer IN ('silver', 'gold');
    EXEC tSQLt.AssertEmptyTable '#LaterSteps';

    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_member_year_attributes';
    EXEC tSQLt.AssertEmptyTable 'Layercake.silv_event_amount';
    EXEC tSQLt.AssertEmptyTable 'Layercake.dim_payment_method';

    SELECT e.event_id
    INTO #ChangedEvents
    FROM Layercake.silv_membership_events AS e
    WHERE e.payment_method_id <> 0 OR e.payer_type_id <> 0 OR e.concession_type_id <> 0
       OR e.invoiced_subtotal_gbp IS NOT NULL OR e.amount_status IS NOT NULL;
    EXEC tSQLt.AssertEmptyTable '#ChangedEvents';

    SELECT a.anomaly_nk
    INTO #NewAnomalies
    FROM Layercake.silv_data_anomaly AS a
    WHERE a.anomaly_type <> 'NO_ELECTION_DATE';
    EXEC tSQLt.AssertEmptyTable '#NewAnomalies';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-008 the run leaves silv_daily_count and silv_daily_count_detail unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';

    INSERT INTO Layercake.silv_daily_count
        ([date], campaign_year, campaign_quarter, region, grade, active_count, paid_count, paid_count_event,
         event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('20241015', 2025, 'Q1', 'UK', 'election', 3, 2, 2, 0, 1, 0, 0),
           ('20250601', 2025, 'Q3', 'UK', 'lapse', 0, 1, 1, 0, 0, 0, 1);

    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count,
         event_lapse_count)
    VALUES ('20241015', 2025, 'Q1', 'UK', 0, 0, 'election', 1, 2, 1, 1, 0, 1, 0, 0),
           ('20241015', 2025, 'Q1', 'UK', 0, 0, 'election', 2, 1, 1, 1, 0, 0, 0, 0),
           ('20250601', 2025, 'Q3', 'UK', 0, 0, 'lapse', 0, 0, 1, 1, 0, 0, 0, 1);

    SELECT * INTO #main_before FROM Layercake.silv_daily_count;
    SELECT * INTO #detail_before FROM Layercake.silv_daily_count_detail;

    EXEC Layercake.usp_run_payment_segments @as_of_date = '20250615';

    EXEC tSQLt.AssertEqualsTable '#main_before', 'Layercake.silv_daily_count';
    EXEC tSQLt.AssertEqualsTable '#detail_before', 'Layercake.silv_daily_count_detail';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-009 a changed retirement date moves the daily Practising Retired split but not silv_daily_count]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.ref_date_spine';
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_loaded', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_pending_rebuild', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_state_ranges', @Identity = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_profile';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_status';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';

    DELETE FROM Layercake.silv_membership_events;
    DELETE FROM Layercake.silv_payment_events;

    INSERT INTO Layercake.silv_ref_membership_status (id, status_name)
    VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('20240601', 2024, 'Q3'), ('20250114', 2025, 'Q2'), ('20250115', 2025, 'Q2'), ('20250201', 2025, 'Q2');

    INSERT INTO Layercake.silv_member_state_ranges
        (contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (N'T5', '20150101', NULL, 2015, 'election', 'UK', 2);

    -- Before: the apuk_retirementdate 2024-03-01, as Phase 1 had it.
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'T5', 0, 0, '20240301');

    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'T5', 2025, '20241010', '20241010', N'Fully Paid');

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id,
         assessment_route_id, rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year,
         campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (901, N'RN:T5:2025', 'Renewal', 'Standard', '20241010', NULL, N'T5', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1',
            0, 0, 0, 0, 0, 0, NULL, NULL, NULL);

    EXEC Layercake.usp_load_silv_daily_count;

    SELECT * INTO #main_before FROM Layercake.silv_daily_count;
    SELECT d.[date], d.grade, d.membership_status_id, d.active_count
    INTO #detail_before
    FROM Layercake.silv_daily_count_detail AS d;

    -- After: the derived retirement date 2025-01-15, applied with the one-off rebuild.
    UPDATE Layercake.silv_member_profile SET retirement_date = '20250115' WHERE contact_no = N'T5';
    EXEC Layercake.usp_load_silv_daily_count @RebuildFrom = '20240101';

    SELECT v.[date], v.campaign_year, v.campaign_quarter, v.region, v.grade, v.active_count, v.paid_count,
           v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpectedMain
    FROM (VALUES (CAST('20240601' AS date), 2024, CAST('Q3' AS char(2)), CAST('UK' AS varchar(12)), CAST('election' AS varchar(12)), 1, 0, 0, 0, 0, 0, 0),
                 ('20250114', 2025, 'Q2', 'UK', 'election', 1, 1, 1, 0, 0, 0, 0),
                 ('20250115', 2025, 'Q2', 'UK', 'election', 1, 1, 1, 0, 0, 0, 0),
                 ('20250201', 2025, 'Q2', 'UK', 'election', 1, 1, 1, 0, 0, 0, 0))
         AS v ([date], campaign_year, campaign_quarter, region, grade, active_count, paid_count, paid_count_event,
               event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#ExpectedMain', '#main_before';
    EXEC tSQLt.AssertEqualsTable '#main_before', 'Layercake.silv_daily_count';

    SELECT v.[date], v.grade, v.membership_status_id, v.active_count
    INTO #ExpectedDetailBefore
    FROM (VALUES (CAST('20240601' AS date), CAST('election' AS varchar(12)), 2, 1), ('20250114', 'election', 2, 1),
                 ('20250115', 'election', 2, 1), ('20250201', 'election', 2, 1))
         AS v ([date], grade, membership_status_id, active_count);
    EXEC tSQLt.AssertEqualsTable '#ExpectedDetailBefore', '#detail_before';

    SELECT d.[date], d.grade, d.membership_status_id, d.active_count
    INTO #ActualDetailAfter
    FROM Layercake.silv_daily_count_detail AS d;

    SELECT v.[date], v.grade, v.membership_status_id, v.active_count
    INTO #ExpectedDetailAfter
    FROM (VALUES (CAST('20240601' AS date), CAST('election' AS varchar(12)), 1, 1), ('20250114', 'election', 1, 1),
                 ('20250115', 'election', 2, 1), ('20250201', 'election', 2, 1))
         AS v ([date], grade, membership_status_id, active_count);
    EXEC tSQLt.AssertEqualsTable '#ExpectedDetailAfter', '#ActualDetailAfter';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-010 the run leaves fact_daily_member_count_detail unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.fact_daily_member_count_detail', @Identity = 1;

    INSERT INTO Layercake.fact_daily_member_count_detail
        (date_id, country_id, gender_id, membership_grade_id, membership_status_id, ActiveMembers, PaidMembers,
         PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
    VALUES (20241015, 0, 0, 2, 1, 2, 1, 1, 0, 1, 0, 0),
           (20241015, 0, 0, 2, 2, 1, 1, 1, 0, 0, 0, 0),
           (20250601, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1);

    SELECT * INTO #fact_before FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_run_payment_segments @as_of_date = '20250615';

    EXEC tSQLt.AssertEqualsTable '#fact_before', 'Layercake.fact_daily_member_count_detail';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-011 a changed retirement date leaves fact_daily_member_count_detail sums by date country and grade unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.ref_date_spine';
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_loaded', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_pending_rebuild', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_state_ranges', @Identity = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_profile';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_status';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.dim_date';
    EXEC tSQLt.FakeTable 'Layercake.dim_membership_grade';
    EXEC tSQLt.FakeTable 'Layercake.fact_daily_member_count_detail', @Identity = 1;

    DELETE FROM Layercake.silv_membership_events;
    DELETE FROM Layercake.silv_payment_events;

    INSERT INTO Layercake.silv_ref_membership_status (id, status_name)
    VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');

    INSERT INTO Layercake.dim_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('20240601', 2024, 'Q3'), ('20250114', 2025, 'Q2'), ('20250115', 2025, 'Q2'), ('20250201', 2025, 'Q2');

    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (20240601, '20240601', 2024, 'Q3'), (20250114, '20250114', 2025, 'Q2'),
           (20250115, '20250115', 2025, 'Q2'), (20250201, '20250201', 2025, 'Q2');

    INSERT INTO Layercake.silv_member_state_ranges
        (contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (N'T5', '20150101', NULL, 2015, 'election', 'UK', 2);

    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'T5', 0, 0, '20240301');

    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'T5', 2025, '20241010', '20241010', N'Fully Paid');

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id,
         assessment_route_id, rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year,
         campaign_quarter, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried,
         concession_type_id, concession_type_carried, subs_amount_gbp, invoiced_subtotal_gbp, amount_status)
    VALUES (901, N'RN:T5:2025', 'Renewal', 'Standard', '20241010', NULL, N'T5', 2, 0, 0, 0, 0, 0, 1, 2025, 'Q1',
            0, 0, 0, 0, 0, 0, NULL, NULL, NULL);

    EXEC Layercake.usp_load_silv_daily_count;
    EXEC Layercake.usp_load_fact_daily_member_count_detail;

    SELECT f.date_id, f.country_id, f.membership_grade_id,
           SUM(f.ActiveMembers) AS ActiveMembers, SUM(f.PaidMembers) AS PaidMembers,
           SUM(f.PaidMembersEvent) AS PaidMembersEvent, SUM(f.JoinEvents) AS JoinEvents,
           SUM(f.RenewalEvents) AS RenewalEvents, SUM(f.ReadmissionEvents) AS ReadmissionEvents,
           SUM(f.LapseEvents) AS LapseEvents
    INTO #sums_before
    FROM Layercake.fact_daily_member_count_detail AS f
    GROUP BY f.date_id, f.country_id, f.membership_grade_id;

    UPDATE Layercake.silv_member_profile SET retirement_date = '20250115' WHERE contact_no = N'T5';
    EXEC Layercake.usp_load_silv_daily_count @RebuildFrom = '20240101';
    EXEC Layercake.usp_load_fact_daily_member_count_detail;

    SELECT f.date_id, f.country_id, f.membership_grade_id,
           SUM(f.ActiveMembers) AS ActiveMembers, SUM(f.PaidMembers) AS PaidMembers,
           SUM(f.PaidMembersEvent) AS PaidMembersEvent, SUM(f.JoinEvents) AS JoinEvents,
           SUM(f.RenewalEvents) AS RenewalEvents, SUM(f.ReadmissionEvents) AS ReadmissionEvents,
           SUM(f.LapseEvents) AS LapseEvents
    INTO #sums_after
    FROM Layercake.fact_daily_member_count_detail AS f
    GROUP BY f.date_id, f.country_id, f.membership_grade_id;

    SELECT v.date_id, v.country_id, v.membership_grade_id, v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent,
           v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpectedSums
    FROM (VALUES (20240601, 0, 2, 1, 0, 0, 0, 0, 0, 0),
                 (20250114, 0, 2, 1, 1, 1, 0, 0, 0, 0),
                 (20250115, 0, 2, 1, 1, 1, 0, 0, 0, 0),
                 (20250201, 0, 2, 1, 1, 1, 0, 0, 0, 0))
         AS v (date_id, country_id, membership_grade_id, ActiveMembers, PaidMembers, PaidMembersEvent,
               JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    EXEC tSQLt.AssertEqualsTable '#ExpectedSums', '#sums_before';
    EXEC tSQLt.AssertEqualsTable '#sums_before', '#sums_after';

    SELECT f.date_id, f.membership_status_id, f.ActiveMembers
    INTO #ActualSplit
    FROM Layercake.fact_daily_member_count_detail AS f;

    SELECT v.date_id, v.membership_status_id, v.ActiveMembers
    INTO #ExpectedSplit
    FROM (VALUES (20240601, 1, 1), (20250114, 1, 1), (20250115, 2, 1), (20250201, 2, 1))
         AS v (date_id, membership_status_id, ActiveMembers);
    EXEC tSQLt.AssertEqualsTable '#ExpectedSplit', '#ActualSplit';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-012 the run leaves silv_annual_rate_base and fact_annual_rate_base unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_annual_rate_base';
    EXEC tSQLt.FakeTable 'Layercake.fact_annual_rate_base', @Identity = 1;

    INSERT INTO Layercake.silv_annual_rate_base
        (campaign_year, grade_id, membership_status_id, country_id, gender_id, members_start, members_end,
         members_joined, members_readmitted, members_lapsed, members_renewed)
    VALUES (2025, 2, 1, 0, 0, 3, 2, 0, 0, 1, 2),
           (2025, 2, 2, 0, 0, 1, 1, 0, 0, 0, 1);

    INSERT INTO Layercake.fact_annual_rate_base
        (campaign_year, grade_id, membership_status_id, country_id, gender_id, members_start, members_end,
         members_joined, members_readmitted, members_lapsed, members_renewed)
    VALUES (2025, 2, 1, 0, 0, 3, 2, 0, 0, 1, 2),
           (2025, 2, 2, 0, 0, 1, 1, 0, 0, 0, 1);

    SELECT * INTO #silv_before FROM Layercake.silv_annual_rate_base;
    SELECT * INTO #fact_before FROM Layercake.fact_annual_rate_base;

    EXEC Layercake.usp_run_payment_segments @as_of_date = '20250615';

    EXEC tSQLt.AssertEqualsTable '#silv_before', 'Layercake.silv_annual_rate_base';
    EXEC tSQLt.AssertEqualsTable '#fact_before', 'Layercake.fact_annual_rate_base';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-013 a changed retirement date moves the annual Practising Retired split but not its totals]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_member_base';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_grade';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_status';
    EXEC tSQLt.FakeTable 'Layercake.silv_annual_rate_base';
    EXEC tSQLt.FakeTable 'Layercake.fact_annual_rate_base', @Identity = 1;

    DELETE FROM Layercake.silv_membership_events;

    INSERT INTO Layercake.silv_ref_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');
    INSERT INTO Layercake.silv_ref_membership_status (id, status_name)
    VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');

    -- Before: the apuk_retirementdate 2024-03-01, as Phase 1 had it.
    INSERT INTO Layercake.silv_member_base
        (contact_id, contact_no, enrolment_date, election_date, is_rpq, election_enr_id, enrolment_from_exception,
         election_from_exception, recorded_enrolment_date, enrolment_from_subs_history, recorded_election_date,
         election_from_subs_history, contact_lapsed_date, lapsed_date, lapse_reason_id, lapse_reason_name,
         retirement_date, source_enr_id, rpq_variant_id, country_id, gender_id)
    VALUES ('00000000-0000-0000-0000-0000000000A5', N'T5', NULL, '20150101', 0, NULL, 0, 0, NULL, 0, NULL, 0, NULL, NULL, 0, NULL,
            '20240301', NULL, 0, 0, 0);

    EXEC Layercake.usp_load_silv_annual_rate_base;
    EXEC Layercake.usp_load_fact_annual_rate_base;

    SELECT r.campaign_year, r.grade_id, r.country_id, r.gender_id,
           SUM(r.members_start) AS members_start, SUM(r.members_end) AS members_end,
           SUM(r.members_joined) AS members_joined, SUM(r.members_readmitted) AS members_readmitted,
           SUM(r.members_lapsed) AS members_lapsed, SUM(r.members_renewed) AS members_renewed
    INTO #silv_sums_before
    FROM Layercake.silv_annual_rate_base AS r
    GROUP BY r.campaign_year, r.grade_id, r.country_id, r.gender_id;

    SELECT r.campaign_year, r.grade_id, r.membership_status_id, r.members_start, r.members_end
    INTO #silv_split_before
    FROM Layercake.silv_annual_rate_base AS r;

    -- After: the derived retirement date 2025-01-15.
    UPDATE Layercake.silv_member_base SET retirement_date = '20250115' WHERE contact_no = N'T5';
    EXEC Layercake.usp_load_silv_annual_rate_base;
    EXEC Layercake.usp_load_fact_annual_rate_base;

    SELECT r.campaign_year, r.grade_id, r.country_id, r.gender_id,
           SUM(r.members_start) AS members_start, SUM(r.members_end) AS members_end,
           SUM(r.members_joined) AS members_joined, SUM(r.members_readmitted) AS members_readmitted,
           SUM(r.members_lapsed) AS members_lapsed, SUM(r.members_renewed) AS members_renewed
    INTO #silv_sums_after
    FROM Layercake.silv_annual_rate_base AS r
    GROUP BY r.campaign_year, r.grade_id, r.country_id, r.gender_id;

    SELECT r.campaign_year, r.grade_id, r.country_id, r.gender_id,
           SUM(r.members_start) AS members_start, SUM(r.members_end) AS members_end,
           SUM(r.members_joined) AS members_joined, SUM(r.members_readmitted) AS members_readmitted,
           SUM(r.members_lapsed) AS members_lapsed, SUM(r.members_renewed) AS members_renewed
    INTO #fact_sums_after
    FROM Layercake.fact_annual_rate_base AS r
    GROUP BY r.campaign_year, r.grade_id, r.country_id, r.gender_id;

    SELECT v.campaign_year, v.grade_id, v.country_id, v.gender_id, v.members_start, v.members_end,
           v.members_joined, v.members_readmitted, v.members_lapsed, v.members_renewed
    INTO #ExpectedSums
    FROM (VALUES (2023, 2, 0, 0, 1, 1, 0, 0, 0, 0),
                 (2024, 2, 0, 0, 1, 1, 0, 0, 0, 0),
                 (2025, 2, 0, 0, 1, 1, 0, 0, 0, 0))
         AS v (campaign_year, grade_id, country_id, gender_id, members_start, members_end,
               members_joined, members_readmitted, members_lapsed, members_renewed);

    EXEC tSQLt.AssertEqualsTable '#ExpectedSums', '#silv_sums_before';
    EXEC tSQLt.AssertEqualsTable '#ExpectedSums', '#silv_sums_after';
    EXEC tSQLt.AssertEqualsTable '#ExpectedSums', '#fact_sums_after';

    SELECT v.campaign_year, v.grade_id, v.membership_status_id, v.members_start, v.members_end
    INTO #ExpectedSplitBefore
    FROM (VALUES (2023, 2, 1, 1, 1), (2024, 2, 1, 1, 0), (2024, 2, 2, 0, 1), (2025, 2, 2, 1, 1))
         AS v (campaign_year, grade_id, membership_status_id, members_start, members_end);
    EXEC tSQLt.AssertEqualsTable '#ExpectedSplitBefore', '#silv_split_before';

    SELECT r.campaign_year, r.grade_id, r.membership_status_id, r.members_start, r.members_end
    INTO #ActualSplitAfter
    FROM Layercake.fact_annual_rate_base AS r;

    SELECT v.campaign_year, v.grade_id, v.membership_status_id, v.members_start, v.members_end
    INTO #ExpectedSplitAfter
    FROM (VALUES (2023, 2, 1, 1, 1), (2024, 2, 1, 1, 1), (2025, 2, 1, 1, 0), (2025, 2, 2, 0, 1))
         AS v (campaign_year, grade_id, membership_status_id, members_start, members_end);
    EXEC tSQLt.AssertEqualsTable '#ExpectedSplitAfter', '#ActualSplitAfter';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-014 the daily and annual Phase 1 tables keep their column lists]
AS
BEGIN
    SELECT o.name AS table_name,
           CAST(ROW_NUMBER() OVER (PARTITION BY o.name ORDER BY c.column_id) AS int) AS ordinal,
           c.name AS column_name
    INTO #Actual
    FROM sys.columns AS c
    INNER JOIN sys.objects AS o
        ON o.object_id = c.object_id
    INNER JOIN sys.schemas AS s
        ON s.schema_id = o.schema_id
    WHERE s.name = N'Layercake'
      AND o.type = 'U'
      AND o.name IN (N'fact_daily_member_count_detail', N'fact_annual_rate_base',
                     N'silv_daily_count_detail', N'silv_annual_rate_base');

    SELECT v.table_name, v.ordinal, v.column_name
    INTO #Expected
    FROM (VALUES (CAST(N'silv_daily_count_detail' AS sysname), 1, CAST(N'date' AS sysname)),
                 (N'silv_daily_count_detail', 2, N'campaign_year'),
                 (N'silv_daily_count_detail', 3, N'campaign_quarter'),
                 (N'silv_daily_count_detail', 4, N'region'),
                 (N'silv_daily_count_detail', 5, N'country_id'),
                 (N'silv_daily_count_detail', 6, N'gender_id'),
                 (N'silv_daily_count_detail', 7, N'grade'),
                 (N'silv_daily_count_detail', 8, N'membership_status_id'),
                 (N'silv_daily_count_detail', 9, N'active_count'),
                 (N'silv_daily_count_detail', 10, N'paid_count'),
                 (N'silv_daily_count_detail', 11, N'paid_count_event'),
                 (N'silv_daily_count_detail', 12, N'event_join_count'),
                 (N'silv_daily_count_detail', 13, N'event_renewal_count'),
                 (N'silv_daily_count_detail', 14, N'event_readmission_count'),
                 (N'silv_daily_count_detail', 15, N'event_lapse_count'),
                 (N'fact_daily_member_count_detail', 1, N'id'),
                 (N'fact_daily_member_count_detail', 2, N'date_id'),
                 (N'fact_daily_member_count_detail', 3, N'country_id'),
                 (N'fact_daily_member_count_detail', 4, N'gender_id'),
                 (N'fact_daily_member_count_detail', 5, N'membership_grade_id'),
                 (N'fact_daily_member_count_detail', 6, N'membership_status_id'),
                 (N'fact_daily_member_count_detail', 7, N'ActiveMembers'),
                 (N'fact_daily_member_count_detail', 8, N'PaidMembers'),
                 (N'fact_daily_member_count_detail', 9, N'PaidMembersEvent'),
                 (N'fact_daily_member_count_detail', 10, N'JoinEvents'),
                 (N'fact_daily_member_count_detail', 11, N'RenewalEvents'),
                 (N'fact_daily_member_count_detail', 12, N'ReadmissionEvents'),
                 (N'fact_daily_member_count_detail', 13, N'LapseEvents'),
                 (N'silv_annual_rate_base', 1, N'campaign_year'),
                 (N'silv_annual_rate_base', 2, N'grade_id'),
                 (N'silv_annual_rate_base', 3, N'membership_status_id'),
                 (N'silv_annual_rate_base', 4, N'country_id'),
                 (N'silv_annual_rate_base', 5, N'gender_id'),
                 (N'silv_annual_rate_base', 6, N'members_start'),
                 (N'silv_annual_rate_base', 7, N'members_end'),
                 (N'silv_annual_rate_base', 8, N'members_joined'),
                 (N'silv_annual_rate_base', 9, N'members_readmitted'),
                 (N'silv_annual_rate_base', 10, N'members_lapsed'),
                 (N'silv_annual_rate_base', 11, N'members_renewed'),
                 (N'fact_annual_rate_base', 1, N'id'),
                 (N'fact_annual_rate_base', 2, N'campaign_year'),
                 (N'fact_annual_rate_base', 3, N'grade_id'),
                 (N'fact_annual_rate_base', 4, N'membership_status_id'),
                 (N'fact_annual_rate_base', 5, N'country_id'),
                 (N'fact_annual_rate_base', 6, N'gender_id'),
                 (N'fact_annual_rate_base', 7, N'members_start'),
                 (N'fact_annual_rate_base', 8, N'members_end'),
                 (N'fact_annual_rate_base', 9, N'members_joined'),
                 (N'fact_annual_rate_base', 10, N'members_readmitted'),
                 (N'fact_annual_rate_base', 11, N'members_lapsed'),
                 (N'fact_annual_rate_base', 12, N'members_renewed'))
         AS v (table_name, ordinal, column_name);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-015 the run leaves the Phase 1 tables the difference scripts compare unchanged]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_member_base';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_profile';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_state_ranges', @Identity = 1;

    INSERT INTO Layercake.silv_member_base
        (contact_id, contact_no, enrolment_date, election_date, is_rpq, election_enr_id, enrolment_from_exception,
         election_from_exception, recorded_enrolment_date, enrolment_from_subs_history, recorded_election_date,
         election_from_subs_history, contact_lapsed_date, lapsed_date, lapse_reason_id, lapse_reason_name,
         retirement_date, source_enr_id, rpq_variant_id, country_id, gender_id)
    VALUES ('00000000-0000-0000-0000-0000000000C1', N'C1', NULL, '20150101', 0, NULL, 0, 0, NULL, 0, NULL, 0, NULL, NULL, 0, NULL,
            NULL, NULL, 0, 0, 0);

    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'C1', 0, 0, NULL);

    INSERT INTO Layercake.silv_member_state_ranges
        (contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (N'C1', '20150101', NULL, 2015, 'election', 'UK', 2);

    SELECT * INTO #base_before FROM Layercake.silv_member_base;
    SELECT * INTO #profile_before FROM Layercake.silv_member_profile;
    SELECT * INTO #ranges_before FROM Layercake.silv_member_state_ranges;
    SELECT * INTO #payments_before FROM Layercake.silv_payment_events;
    SELECT * INTO #status_before FROM Layercake.brnz_subs_status;
    SELECT e.event_id, e.event_nk, e.event_type, e.event_subtype, e.event_date, e.source_enr_id, e.contact_no,
           e.grade_id, e.assessment_route_id, e.rpq_variant_id, e.hpb_id, e.country_id, e.gender_id,
           e.membership_status_id, e.campaign_year, e.campaign_quarter
    INTO #events_before
    FROM Layercake.silv_membership_events AS e;
    SELECT f.event_id, f.event_type, f.event_subtype, f.event_date, f.date_id, f.contact_no, f.grade_id,
           f.assessment_route_id, f.rpq_variant_id, f.hpb_id, f.country_id, f.gender_id, f.membership_status_id,
           f.campaign_year, f.campaign_quarter
    INTO #facts_before
    FROM Layercake.fact_membership_events AS f;

    EXEC Layercake.usp_run_payment_segments @as_of_date = '20250615';

    SELECT e.event_id, e.event_nk, e.event_type, e.event_subtype, e.event_date, e.source_enr_id, e.contact_no,
           e.grade_id, e.assessment_route_id, e.rpq_variant_id, e.hpb_id, e.country_id, e.gender_id,
           e.membership_status_id, e.campaign_year, e.campaign_quarter
    INTO #events_after
    FROM Layercake.silv_membership_events AS e;
    SELECT f.event_id, f.event_type, f.event_subtype, f.event_date, f.date_id, f.contact_no, f.grade_id,
           f.assessment_route_id, f.rpq_variant_id, f.hpb_id, f.country_id, f.gender_id, f.membership_status_id,
           f.campaign_year, f.campaign_quarter
    INTO #facts_after
    FROM Layercake.fact_membership_events AS f;

    EXEC tSQLt.AssertEqualsTable '#base_before', 'Layercake.silv_member_base';
    EXEC tSQLt.AssertEqualsTable '#profile_before', 'Layercake.silv_member_profile';
    EXEC tSQLt.AssertEqualsTable '#ranges_before', 'Layercake.silv_member_state_ranges';
    EXEC tSQLt.AssertEqualsTable '#payments_before', 'Layercake.silv_payment_events';
    EXEC tSQLt.AssertEqualsTable '#status_before', 'Layercake.brnz_subs_status';
    EXEC tSQLt.AssertEqualsTable '#events_before', '#events_after';
    EXEC tSQLt.AssertEqualsTable '#facts_before', '#facts_after';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-016 the run writes nothing to the external sources it reads]
AS
BEGIN
    SELECT * INTO #inv_before FROM Subs.tblSubsInvoices;
    SELECT * INTO #ct_before FROM synapse_fo.CUSTTRANS_RICS;
    SELECT * INTO #corp_before FROM Subs.vwCorpSubscriptions;
    SELECT * INTO #conc_before FROM CE.vwConcessionType;

    EXEC Layercake.usp_run_payment_segments @as_of_date = '20250615';

    EXEC tSQLt.AssertEqualsTable '#inv_before', 'Subs.tblSubsInvoices';
    EXEC tSQLt.AssertEqualsTable '#ct_before', 'synapse_fo.CUSTTRANS_RICS';
    EXEC tSQLt.AssertEqualsTable '#corp_before', 'Subs.vwCorpSubscriptions';
    EXEC tSQLt.AssertEqualsTable '#conc_before', 'CE.vwConcessionType';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-017 the deployed database holds the run procedure and no rolled back table]
AS
BEGIN
    DECLARE @object_type nvarchar(2) =
        (SELECT RTRIM(o.type) FROM sys.objects AS o WHERE o.object_id = OBJECT_ID(N'Layercake.usp_run_payment_segments'));
    EXEC tSQLt.AssertEqualsString N'P', @object_type;

    SELECT t.name
    INTO #RolledBack
    FROM sys.tables AS t
    INNER JOIN sys.schemas AS s
        ON s.schema_id = t.schema_id
    WHERE s.name = N'Layercake'
      AND t.name LIKE N'%[_]rolledback[_]MIG%';
    EXEC tSQLt.AssertEmptyTable '#RolledBack';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-018 every object the spec maps exists in the database with its kind]
AS
BEGIN
    SELECT o.name AS object_name, CAST(RTRIM(o.type) AS nvarchar(2)) COLLATE DATABASE_DEFAULT AS object_type
    INTO #Actual
    FROM sys.objects AS o
    INNER JOIN sys.schemas AS s
        ON s.schema_id = o.schema_id
    WHERE s.name = N'Layercake'
      AND o.name IN (N'brnz_subs_invoice', N'brnz_subs_invoice_line', N'brnz_subs_status', N'brnz_corporate_subscription',
                     N'brnz_concession', N'silv_ref_payment_method', N'silv_ref_payer_type', N'silv_ref_invoice_line_type',
                     N'silv_ref_currency', N'silv_ref_concession_type', N'silv_member_year_attributes', N'silv_event_amount',
                     N'silv_membership_events', N'silv_payment_events', N'silv_data_anomaly', N'silv_member_base',
                     N'dim_payment_method', N'dim_payer_type', N'dim_currency', N'dim_concession_type',
                     N'fact_membership_events', N'vw_silv_derived_retirement_date', N'vw_silv_eligible_invoice',
                     N'fn_map_payment_method');

    SELECT v.object_name, v.object_type
    INTO #Expected
    FROM (VALUES (CAST(N'brnz_subs_invoice' AS sysname), CAST(N'U' AS nvarchar(2))),
                 (N'brnz_subs_invoice_line', N'U'), (N'brnz_subs_status', N'U'), (N'brnz_corporate_subscription', N'U'),
                 (N'brnz_concession', N'U'), (N'silv_ref_payment_method', N'U'), (N'silv_ref_payer_type', N'U'),
                 (N'silv_ref_invoice_line_type', N'U'), (N'silv_ref_currency', N'U'), (N'silv_ref_concession_type', N'U'),
                 (N'silv_member_year_attributes', N'U'), (N'silv_event_amount', N'U'), (N'silv_membership_events', N'U'),
                 (N'silv_payment_events', N'U'), (N'silv_data_anomaly', N'U'), (N'silv_member_base', N'U'),
                 (N'dim_payment_method', N'U'), (N'dim_payer_type', N'U'), (N'dim_currency', N'U'),
                 (N'dim_concession_type', N'U'), (N'fact_membership_events', N'U'),
                 (N'vw_silv_derived_retirement_date', N'V'), (N'vw_silv_eligible_invoice', N'V'),
                 (N'fn_map_payment_method', N'FN'))
         AS v (object_name, object_type);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-019 payer type and invoiced amount reach every gold fact through the payer type dimension]
AS
BEGIN
    EXEC Layercake.usp_run_payment_segments @as_of_date = '20250615';

    SELECT f.event_id, d.payer_type_name, f.invoiced_subtotal_gbp, f.amount_status
    INTO #Actual
    FROM Layercake.fact_membership_events AS f
    LEFT JOIN Layercake.dim_payer_type AS d
        ON d.id = f.payer_type_id;

    SELECT v.event_id, v.payer_type_name, v.invoiced_subtotal_gbp, v.amount_status
    INTO #Expected
    FROM (VALUES (101, CAST('Individual' AS varchar(30)), CAST(450.0000 AS decimal(19,4)), CAST('Invoiced' AS varchar(30))),
                 (102, 'Individual', CAST(475.0000 AS decimal(19,4)), 'Invoiced'),
                 (201, 'Corporate', CAST(300.0000 AS decimal(19,4)), 'Invoiced'),
                 (301, 'Unknown', NULL, 'No invoice'),
                 (401, 'Unknown', NULL, NULL),
                 (501, 'Individual', CAST(520.0000 AS decimal(19,4)), 'Invoiced'))
         AS v (event_id, payer_type_name, invoiced_subtotal_gbp, amount_status);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-020 every anomaly type the run raises is one of the ten listed types]
AS
BEGIN
    EXEC Layercake.usp_run_payment_segments @as_of_date = '20250615';

    SELECT DISTINCT a.anomaly_type
    INTO #Unlisted
    FROM Layercake.silv_data_anomaly AS a
    WHERE a.anomaly_type <> 'NO_ELECTION_DATE'
      AND a.anomaly_type NOT IN ('CORPORATE_FLAG_NO_SCHEME', 'DOUBLE_PAYMENT', 'EVENT_NO_INVOICE', 'INVOICE_NO_EVENT',
                                 'INVOICE_MATCHES_MULTIPLE_EVENTS', 'EVENT_MATCHES_MULTIPLE_INVOICES', 'READMISSION_FREE',
                                 'READMISSION_NO_FEE', 'CONCESSION_NOT_IN_REFERENCE', 'FULL_CONCESSION_NO_CONCESSION');
    EXEC tSQLt.AssertEmptyTable '#Unlisted';

    SELECT DISTINCT a.anomaly_type
    INTO #Actual
    FROM Layercake.silv_data_anomaly AS a
    WHERE a.anomaly_type <> 'NO_ELECTION_DATE';

    SELECT v.anomaly_type
    INTO #Expected
    FROM (VALUES (CAST('CORPORATE_FLAG_NO_SCHEME' AS varchar(40))), ('EVENT_NO_INVOICE'), ('INVOICE_NO_EVENT'))
         AS v (anomaly_type);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD016.[test TC-016-021 amount statuses subs amount and reserved labels are as the pack describes them]
AS
BEGIN
    EXEC Layercake.usp_run_payment_segments @as_of_date = '20250615';

    SELECT e.event_id, e.event_type, e.amount_status
    INTO #BadStatus
    FROM Layercake.silv_membership_events AS e
    WHERE (e.event_type IN ('Join', 'Renewal', 'Readmission')
           AND (e.amount_status IS NULL
                OR e.amount_status NOT IN ('Before invoice data', 'No invoice', 'Counted on another event',
                                           'Full Concession', 'Fully credited', 'Invoiced')))
       OR (e.event_type NOT IN ('Join', 'Renewal', 'Readmission') AND e.amount_status IS NOT NULL);
    EXEC tSQLt.AssertEmptyTable '#BadStatus';

    SELECT f.event_id, f.subs_amount_gbp, f.invoiced_subtotal_gbp
    INTO #UnequalAmounts
    FROM Layercake.fact_membership_events AS f
    WHERE f.subs_amount_gbp <> f.invoiced_subtotal_gbp
       OR (f.subs_amount_gbp IS NULL AND f.invoiced_subtotal_gbp IS NOT NULL)
       OR (f.subs_amount_gbp IS NOT NULL AND f.invoiced_subtotal_gbp IS NULL);
    EXEC tSQLt.AssertEmptyTable '#UnequalAmounts';

    SELECT u.dimension, u.id, u.label
    INTO #ActualReserved
    FROM (SELECT CAST('dim_payment_method' AS varchar(30)) AS dimension, d.id, CAST(d.payment_method_name AS nvarchar(100)) AS label
          FROM Layercake.dim_payment_method AS d
          WHERE d.id IN (0, -1, -2)
          UNION ALL
          SELECT 'dim_payer_type', d.id, CAST(d.payer_type_name AS nvarchar(100))
          FROM Layercake.dim_payer_type AS d
          WHERE d.id IN (0, -1, -2)
          UNION ALL
          SELECT 'dim_concession_type', d.id, d.concession_type_name
          FROM Layercake.dim_concession_type AS d
          WHERE d.id IN (0, -1, -2)) AS u;

    SELECT v.dimension, v.id, v.label
    INTO #ExpectedReserved
    FROM (VALUES (CAST('dim_payment_method' AS varchar(30)), 0, CAST(N'Unknown' AS nvarchar(100))),
                 ('dim_payment_method', -1, N'Unrecognised'), ('dim_payment_method', -2, N'Not applicable'),
                 ('dim_payer_type', 0, N'Unknown'), ('dim_payer_type', -1, N'Unrecognised'),
                 ('dim_payer_type', -2, N'Not applicable'), ('dim_concession_type', 0, N'Unknown'),
                 ('dim_concession_type', -1, N'Unrecognised'), ('dim_concession_type', -2, N'Not applicable'))
         AS v (dimension, id, label);
    EXEC tSQLt.AssertEqualsTable '#ExpectedReserved', '#ActualReserved';
END;
GO
