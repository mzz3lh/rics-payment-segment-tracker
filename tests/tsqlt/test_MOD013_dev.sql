EXEC tSQLt.NewTestClass 'test_MOD013_dev';
GO

CREATE PROCEDURE test_MOD013_dev.[SetUp]
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
        (1,  N'No concession', NULL,           0, 0),
        (13, N'Retired',       N'CONRETIRED',  1, 1),
        (30, N'Retired lower', N'conretired',  1, 1);

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES
        (2024, '2023-10-01', '2024-09-30', '2024-03-31'),
        (2025, '2024-10-01', '2025-09-30', '2025-03-31');
END;
GO

CREATE PROCEDURE test_MOD013_dev.[test a paid position with no attributes row has no retired concession]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'P1', 2025), (N'P2', 2025);

    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], retired_concession, _is_deleted)
    VALUES (N'P1', 2025, '2024-11-01', 'Retired Conc.', 0);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2025, 2, 0, 0, 1, 1, 50.0)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013_dev.[test a paid year with no campaign year config row is counted but its derived date does not count]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'Q1', 2027), (N'Q2', 2027);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'Q1', 2027, 13), (N'Q2', 2027, 1);

    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], retired_concession, _is_deleted)
    VALUES (N'Q1', 2024, '2023-11-01', 'Retired Conc.', 0),
           (N'Q2', 2024, '2023-11-01', 'Retired Conc.', 0);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2027, 2, 0, 1, 0, 1, 50.0)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013_dev.[test a retired item code differing only in case counts as retired]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'R1', 2025);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'R1', 2025, 30);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2025, 1, 0, 1, 0, 0, 0.0)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013_dev.[test an attributes row with no paid position is not counted and no paid positions gives no rows]
AS
BEGIN
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'S1', 2025, 13);

    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], retired_concession, _is_deleted)
    VALUES (N'S1', 2025, '2024-11-01', 'Retired Conc.', 0);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO

CREATE PROCEDURE test_MOD013_dev.[test agreement rate rounds to one decimal one in six is 16.7 and five in six is 83.3]
AS
BEGIN
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year)
    VALUES (N'U1', 2024), (N'U2', 2024), (N'U3', 2024), (N'U4', 2024), (N'U5', 2024), (N'U6', 2024),
           (N'V1', 2025), (N'V2', 2025), (N'V3', 2025), (N'V4', 2025), (N'V5', 2025), (N'V6', 2025);

    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, concession_type_id)
    VALUES (N'U1', 2024, 1), (N'U2', 2024, 13), (N'U3', 2024, 13), (N'U4', 2024, 13), (N'U5', 2024, 13), (N'U6', 2024, 13),
           (N'V1', 2025, 1), (N'V2', 2025, 1), (N'V3', 2025, 1), (N'V4', 2025, 1), (N'V5', 2025, 1), (N'V6', 2025, 13);

    CREATE TABLE #Actual (
        campaign_year int, paid_positions int, retired_concession_and_date int, retired_concession_only int,
        derived_date_only int, neither int, agreement_rate_pct decimal(5,1));

    INSERT INTO #Actual (campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct)
    EXEC Layercake.usp_report_retirement_comparison;

    SELECT v.campaign_year, v.paid_positions, v.retired_concession_and_date, v.retired_concession_only,
           v.derived_date_only, v.neither, CAST(v.agreement_rate_pct AS decimal(5,1)) AS agreement_rate_pct
    INTO #Expected
    FROM (VALUES (2024, 6, 0, 5, 0, 1, 16.7),
                 (2025, 6, 0, 1, 0, 5, 83.3)) AS v(campaign_year, paid_positions, retired_concession_and_date, retired_concession_only, derived_date_only, neither, agreement_rate_pct);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
