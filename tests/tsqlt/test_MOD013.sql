EXEC tSQLt.NewTestClass 'test_MOD013';
GO

CREATE PROCEDURE test_MOD013.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type';
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_base';

    INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_name, item_code, is_full_concession, is_perpetual)
    VALUES
        (0,  N'Unknown',                  NULL,                   0, 0),
        (-1, N'Unrecognised',             NULL,                   0, 0),
        (-2, N'Not applicable',           NULL,                   0, 0),
        (1,  N'No concession',            NULL,                   0, 0),
        (10, N'Retired PWRQ 1',           N'CONPWRQ1',            0, 1),
        (11, N'Retired PWRQ 2',           N'CONPWRQ2',            0, 1),
        (12, N'Retired PWRQ 3',           N'CONPWRQ3',            0, 1),
        (13, N'Retired',                  N'CONRETIRED',          1, 1),
        (14, N'Retired full',             N'CONRETIREDFL',        1, 1),
        (15, N'Retired special',          N'CONRETIREDSPECIAL',   1, 1),
        (20, N'Exceptional Hardship',     N'CONHARDSHIP',         0, 0),
        (21, N'Retired lookalike',        N'CONRETIREDX',         0, 0),
        (22, N'PWRQ 4 lookalike',         N'CONPWRQ4',            0, 0);

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES
        (2022, '2021-10-01', '2022-09-30', '2022-03-31'),
        (2023, '2022-10-01', '2023-09-30', '2023-03-31'),
        (2024, '2023-10-01', '2024-09-30', '2024-03-31'),
        (2025, '2024-10-01', '2025-09-30', '2025-03-31'),
        (2026, '2025-10-01', '2026-09-30', '2026-03-31');
END;
GO

CREATE PROCEDURE test_MOD013.[test TC-013-001 ten 2025 paid positions split 4 1 2 3 with agreement 70.0]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'A1', 2025), (N'A2', 2025), (N'A3', 2025), (N'A4', 2025), (N'A5', 2025),
           (N'A6', 2025), (N'A7', 2025), (N'A8', 2025), (N'A9', 2025), (N'A10', 2025);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'A1', 2025, 13), (N'A2', 2025, 10), (N'A3', 2025, 15), (N'A4', 2025, 14), (N'A5', 2025, 13),
           (N'A6', 2025, 1), (N'A7', 2025, 0), (N'A8', 2025, 1), (N'A9', 2025, 20), (N'A10', 2025, 0);

    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], retired_concession, _is_deleted)
    VALUES (N'A1', 2024, '2023-11-20', 'Retired Conc.', 0),
           (N'A2', 2025, '2024-10-05', 'Retired Conc.', 0),
           (N'A3', 2025, '2025-03-01', 'Retired Conc.', 0),
           (N'A4', 2025, '2024-12-01', 'Retired Conc.', 0),
           (N'A6', 2025, '2024-11-15', 'Retired Conc.', 0),
           (N'A7', 2023, '2022-10-20', 'Retired Conc.', 0);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2025, 10, 4, 1, 2, 3, 70.0)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013.[test TC-013-002 derived date on the Campaign Year end counts and the day after does not]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'B1', 2025), (N'B2', 2025), (N'B3', 2025), (N'B4', 2025);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'B1', 2025, 13), (N'B2', 2025, 10), (N'B3', 2025, 1), (N'B4', 2025, 1);

    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], retired_concession, _is_deleted)
    VALUES (N'B1', 2025, '2025-09-30', 'Retired Conc.', 0),
           (N'B2', 2026, '2025-10-01', 'Retired Conc.', 0),
           (N'B3', 2025, '2025-09-30', 'Retired Conc.', 0),
           (N'B4', 2026, '2025-10-01', 'Retired Conc.', 0);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2025, 4, 1, 1, 1, 1, 50.0)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013.[test TC-013-003 one row per Campaign Year with paid positions each compared with its own year end]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'C1', 2023), (N'C1', 2024), (N'C1', 2025), (N'C2', 2024), (N'C2', 2025);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'C1', 2023, 1), (N'C1', 2024, 13), (N'C1', 2025, 13), (N'C2', 2024, 10), (N'C2', 2025, 1);

    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], retired_concession, _is_deleted)
    VALUES (N'C1', 2023, '2022-10-15', 'No Conc.', 0),
           (N'C1', 2024, '2023-11-20', 'Retired Conc.', 0);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2023, 1, 0, 0, 0, 1, 100.0),
                 (2024, 2, 1, 1, 0, 0, 50.0),
                 (2025, 2, 1, 0, 0, 1, 100.0)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013.[test TC-013-004 agreement rate of two in three rounds to 66.7]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'E1', 2025), (N'E2', 2025), (N'E3', 2025);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'E1', 2025, 13), (N'E2', 2025, 1), (N'E3', 2025, 1);

    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], retired_concession, _is_deleted)
    VALUES (N'E1', 2025, '2024-11-01', 'Retired Conc.', 0),
           (N'E2', 2025, '2024-11-02', 'Retired Conc.', 0);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2025, 3, 1, 0, 1, 1, 66.7)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013.[test TC-013-005 each of the six retired item codes counts as a retired concession]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'F1', 2025), (N'F2', 2025), (N'F3', 2025), (N'F4', 2025), (N'F5', 2025), (N'F6', 2025);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'F1', 2025, 10), (N'F2', 2025, 11), (N'F3', 2025, 12), (N'F4', 2025, 13), (N'F5', 2025, 14), (N'F6', 2025, 15);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2025, 6, 0, 6, 0, 0, 0.0)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013.[test TC-013-006 other concession codes and reserved types are not a retired concession]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'G1', 2025), (N'G2', 2025), (N'G3', 2025), (N'G4', 2025), (N'G5', 2025), (N'G6', 2025), (N'G7', 2025);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'G1', 2025, 20), (N'G2', 2025, 21), (N'G3', 2025, 22), (N'G4', 2025, 0), (N'G5', 2025, -1), (N'G6', 2025, -2), (N'G7', 2025, 1);

    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], retired_concession, _is_deleted)
    VALUES (N'G1', 2025, '2024-11-10', 'Retired Conc.', 0),
           (N'G2', 2025, '2024-11-10', 'Retired Conc.', 0),
           (N'G3', 2025, '2024-11-10', 'Retired Conc.', 0),
           (N'G4', 2025, '2024-11-10', 'Retired Conc.', 0),
           (N'G5', 2025, '2024-11-10', 'Retired Conc.', 0),
           (N'G6', 2025, '2024-11-10', 'Retired Conc.', 0),
           (N'G7', 2025, '2024-11-10', 'Retired Conc.', 0);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2025, 7, 0, 0, 7, 0, 0.0)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013.[test TC-013-007 deleted undated and non-retired status rows give no derived date]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'H1', 2025), (N'H2', 2025), (N'H3', 2025), (N'H4', 2025);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'H1', 2025, 1), (N'H2', 2025, 1), (N'H3', 2025, 1), (N'H4', 2025, 1);

    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], retired_concession, _is_deleted)
    VALUES (N'H1', 2024, '2023-11-01', 'Retired Conc.', 1),
           (N'H2', 2024, NULL,         'Retired Conc.', 0),
           (N'H3', 2024, '2023-11-01', 'Non-Retired Conc.', 0),
           (N'H4', 2024, '2023-11-01', 'No Conc.', 0);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2025, 4, 0, 0, 0, 4, 100.0)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013.[test TC-013-008 a contact with several Retired Conc years counts once per paid position]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'D1', 2025);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'D1', 2025, 13);

    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], retired_concession, _is_deleted)
    VALUES (N'D1', 2024, '2023-11-20', 'Retired Conc.', 0),
           (N'D1', 2025, '2024-10-05', 'Retired Conc.', 0),
           (N'D1', 2026, '2025-10-03', 'Retired Conc.', 0);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2025, 1, 1, 0, 0, 0, 100.0)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013.[test TC-013-009 output is the seven aggregate columns with one row per Campaign Year and no contact column]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'J1', 2024), (N'J1', 2025), (N'J2', 2024), (N'J3', 2025);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'J1', 2024, 13), (N'J1', 2025, 13), (N'J2', 2024, 1), (N'J3', 2025, 1);

    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], retired_concession, _is_deleted)
    VALUES (N'J1', 2024, '2023-11-20', 'Retired Conc.', 0),
           (N'J3', 2025, '2024-12-01', 'Retired Conc.', 0);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison @as_of_date = '2023-01-01';

    DECLARE @row_count int = (SELECT COUNT(*) FROM #Actual);
    EXEC tSQLt.AssertEquals 2, @row_count, 'Expected one aggregate row per Campaign Year, not one per contact';

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2024, 2, 1, 0, 0, 1, 100.0),
                 (2025, 2, 1, 0, 1, 0, 50.0)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013.[test TC-013-010 apuk retirement date in silv_member_base with no derived date or retired concession is neither]
AS
BEGIN
    INSERT INTO Layercake.silv_member_base (contact_no, retirement_date)
    VALUES (N'K1', '2020-01-01');

    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'K1', 2025);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'K1', 2025, 1);

    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], retired_concession, _is_deleted)
    VALUES (N'K1', 2025, '2024-10-20', 'No Conc.', 0);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2025, 1, 0, 0, 0, 1, 100.0)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013.[test TC-013-011 running the report changes no status or source row]
AS
BEGIN
    INSERT INTO Layercake.silv_member_base (contact_no, retirement_date)
    VALUES (N'L1', '2020-01-01'), (N'L2', '2023-11-20');

    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'L1', 2025), (N'L2', 2025);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'L1', 2025, 13), (N'L2', 2025, 1);

    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], retired_concession, _is_deleted)
    VALUES (N'L2', 2024, '2023-11-20', 'Retired Conc.', 0);

    SELECT * INTO #BeforeBase FROM Layercake.silv_member_base;
    SELECT * INTO #BeforeAttr FROM Layercake.silv_member_year_attributes;
    SELECT * INTO #BeforePay FROM Layercake.silv_payment_events;

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT * INTO #AfterBase FROM Layercake.silv_member_base;
    SELECT * INTO #AfterAttr FROM Layercake.silv_member_year_attributes;
    SELECT * INTO #AfterPay FROM Layercake.silv_payment_events;

    EXEC tSQLt.AssertEqualsTable '#BeforeBase', '#AfterBase';
    EXEC tSQLt.AssertEqualsTable '#BeforeAttr', '#AfterAttr';
    EXEC tSQLt.AssertEqualsTable '#BeforePay', '#AfterPay';

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2025, 2, 0, 1, 1, 0, 0.0)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
