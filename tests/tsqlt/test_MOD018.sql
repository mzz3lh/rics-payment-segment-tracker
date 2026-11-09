EXEC tSQLt.NewTestClass 'test_MOD018';
GO

CREATE PROCEDURE test_MOD018.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status';
    EXEC tSQLt.FakeTable 'Subs.vwSubsMemberStatuses';
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact';
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact_test_record';
    EXEC tSQLt.FakeTable 'Layercake.brnz_rics_record';
    EXEC tSQLt.FakeTable 'Layercake.brnz_cust_trans';
    EXEC tSQLt.FakeTable 'Layercake.brnz_enrolment';
    EXEC tSQLt.FakeTable 'Layercake.brnz_route';
    EXEC tSQLt.FakeTable 'Layercake.ref_enrolment_exception';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_base';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_rpq_variant';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_lapse_reason';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_gender';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_grade';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_status';
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_date';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_profile';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_state_ranges';
    EXEC tSQLt.FakeTable 'Layercake.ref_date_spine';
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count';
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_loaded', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_pending_rebuild', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_annual_rate_base';
    EXEC tSQLt.FakeTable 'Layercake.fact_annual_rate_base', @Identity = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;

    INSERT INTO Layercake.silv_ref_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');
    INSERT INTO Layercake.silv_ref_membership_status (id, status_name)
    VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');
END;
GO

/* ---------------- view: Layercake.vw_silv_derived_retirement_date ---------------- */

CREATE PROCEDURE test_MOD018.[test TC-018-001 T1 derived date is the Renewal Date of the earliest Retired Conc year]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T1', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T1', 2024, 'Fully Paid', '2023-11-20', '2023-12-31', 0, 'Retired Conc.'),
           (N'T1', 2025, 'Fully Paid', '2024-10-05', '2024-10-05', 0, 'Retired Conc.');

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Actual
    FROM Layercake.vw_silv_derived_retirement_date;

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Expected
    FROM (VALUES (N'T1', 2024, CAST('2023-11-20' AS date))) AS v(contact_no, retirement_campaign_year, derived_retirement_date);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-002 T2 a Retired Conc year with a null Renewal Date is skipped]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T2', 2024, 'Full Concession', NULL, NULL, 0, 'Retired Conc.'),
           (N'T2', 2025, 'Fully Paid', '2024-12-01', '2024-12-01', 0, 'Retired Conc.');

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Actual
    FROM Layercake.vw_silv_derived_retirement_date;

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Expected
    FROM (VALUES (N'T2', 2025, CAST('2024-12-01' AS date))) AS v(contact_no, retirement_campaign_year, derived_retirement_date);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-003 T3 a soft deleted Retired Conc row is ignored]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T3', 2023, 'Fully Paid', '2022-11-01', '2022-11-01', 1, 'Retired Conc.'),
           (N'T3', 2024, 'Fully Paid', '2023-10-12', '2023-10-12', 0, 'Retired Conc.');

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Actual
    FROM Layercake.vw_silv_derived_retirement_date;

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Expected
    FROM (VALUES (N'T3', 2024, CAST('2023-10-12' AS date))) AS v(contact_no, retirement_campaign_year, derived_retirement_date);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-004 T4 with no Retired Conc row has no derived date]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T4', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T4', 2024, 'Fully Paid', '2023-10-20', '2023-10-20', 0, 'Non-Retired Conc.'),
           (N'T4', 2025, 'No Payment', NULL, NULL, 0, 'No Invoice'),
           (N'T4', 2026, 'Fully Paid', '2025-10-10', '2025-10-10', 0, NULL);
    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Retired Concession], [First Retired Year], [Renewal Date])
    VALUES (N'T4', 2024, 'Non-Retired Conc.', 2018, '2023-10-20');

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Actual
    FROM Layercake.vw_silv_derived_retirement_date;

    EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-005 mixed contacts give exactly one row per contact with a derived date]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T1', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T1', 2024, 'Fully Paid', '2023-11-20', '2023-12-31', 0, 'Retired Conc.'),
           (N'T1', 2025, 'Fully Paid', '2024-10-05', '2024-10-05', 0, 'Retired Conc.'),
           (N'T2', 2024, 'Full Concession', NULL, NULL, 0, 'Retired Conc.'),
           (N'T2', 2025, 'Fully Paid', '2024-12-01', '2024-12-01', 0, 'Retired Conc.'),
           (N'T3', 2023, 'Fully Paid', '2022-11-01', '2022-11-01', 1, 'Retired Conc.'),
           (N'T3', 2024, 'Fully Paid', '2023-10-12', '2023-10-12', 0, 'Retired Conc.'),
           (N'T4', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T4', 2024, 'Fully Paid', '2023-10-20', '2023-10-20', 0, 'Non-Retired Conc.');

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Actual
    FROM Layercake.vw_silv_derived_retirement_date;

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Expected
    FROM (VALUES (N'T1', 2024, CAST('2023-11-20' AS date)),
                 (N'T2', 2025, CAST('2024-12-01' AS date)),
                 (N'T3', 2024, CAST('2023-10-12' AS date))) AS v(contact_no, retirement_campaign_year, derived_retirement_date);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-006 the earliest Campaign Year wins even when a later year has an earlier Renewal Date]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T10', 2024, 'Fully Paid', '2023-11-20', '2023-11-20', 0, 'Retired Conc.'),
           (N'T10', 2025, 'Fully Paid', '2023-10-05', '2024-10-01', 0, 'Retired Conc.');

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Actual
    FROM Layercake.vw_silv_derived_retirement_date;

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Expected
    FROM (VALUES (N'T10', 2024, CAST('2023-11-20' AS date))) AS v(contact_no, retirement_campaign_year, derived_retirement_date);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

/* ---------------- Layercake.usp_load_silv_member_base ---------------- */

CREATE PROCEDURE test_MOD018.[test TC-018-007 member base takes the derived date in place of apuk_retirementdate]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000001', N'T1', 0),
           ('00000000-0000-0000-0000-000000000002', N'T2', 0),
           ('00000000-0000-0000-0000-000000000003', N'T3', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', N'T1', '2021-06-01', '2024-01-01', 0),
           ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', N'T2', '2020-01-01', '2024-01-01', 0),
           ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', N'T3', '2019-01-01', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (1, N'T1', 0), (2, N'T2', 0), (3, N'T3', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T1', '00000000-0000-0000-0000-000000000001', '2015-01-01'),
           (N'T2', '00000000-0000-0000-0000-000000000002', '2015-01-01'),
           (N'T3', '00000000-0000-0000-0000-000000000003', '2015-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T1', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T1', 2024, 'Fully Paid', '2023-11-20', '2023-12-31', 0, 'Retired Conc.'),
           (N'T1', 2025, 'Fully Paid', '2024-10-05', '2024-10-05', 0, 'Retired Conc.'),
           (N'T2', 2024, 'Full Concession', NULL, NULL, 0, 'Retired Conc.'),
           (N'T2', 2025, 'Fully Paid', '2024-12-01', '2024-12-01', 0, 'Retired Conc.'),
           (N'T3', 2023, 'Fully Paid', '2022-11-01', '2022-11-01', 1, 'Retired Conc.'),
           (N'T3', 2024, 'Fully Paid', '2023-10-12', '2023-10-12', 0, 'Retired Conc.');

    EXEC Layercake.usp_load_silv_member_base;

    SELECT contact_no, retirement_date
    INTO #Actual
    FROM Layercake.silv_member_base;

    SELECT contact_no, retirement_date
    INTO #Expected
    FROM (VALUES (N'T1', CAST('2023-11-20' AS date)),
                 (N'T2', CAST('2024-12-01' AS date)),
                 (N'T3', CAST('2023-10-12' AS date))) AS v(contact_no, retirement_date);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-008 T4 gets a null retirement date with no fallback to apuk or First Retired Year]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000004', N'T4', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000004', N'T4', '2019-05-01', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (4, N'T4', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T4', '00000000-0000-0000-0000-000000000004', '2010-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T4', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T4', 2024, 'Fully Paid', '2023-10-20', '2023-10-20', 0, 'Non-Retired Conc.');
    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Retired Concession], [First Retired Year], [Renewal Date])
    VALUES (N'T4', 2023, 'No Conc.', 2018, '2022-10-15'),
           (N'T4', 2024, 'Non-Retired Conc.', 2018, '2023-10-20');

    EXEC Layercake.usp_load_silv_member_base;

    SELECT contact_no, retirement_date
    INTO #Actual
    FROM Layercake.silv_member_base;

    SELECT contact_no, retirement_date
    INTO #Expected
    FROM (VALUES (N'T4', CAST(NULL AS date))) AS v(contact_no, retirement_date);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-009 the member base row set other columns and logging are unchanged]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000001', N'T1', 0),
           ('00000000-0000-0000-0000-000000000006', N'T6', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', N'T1', '2021-06-01', '2024-01-01', 0),
           ('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000006', N'T6', '2022-02-02', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (1, N'T1', 0), (6, N'T6', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T1', '00000000-0000-0000-0000-000000000001', '2015-01-01'),
           (N'T6', '00000000-0000-0000-0000-000000000006', '2015-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T1', 2024, 'Fully Paid', '2023-11-20', '2023-11-20', 0, 'Retired Conc.'),
           (N'T7', 2024, 'Fully Paid', '2023-11-01', '2023-11-01', 0, 'Retired Conc.');

    EXEC Layercake.usp_load_silv_member_base;

    SELECT contact_id, contact_no, enrolment_date, election_date, is_rpq, election_from_exception, lapsed_date, retirement_date
    INTO #Actual
    FROM Layercake.silv_member_base;

    SELECT contact_id, contact_no, enrolment_date, election_date, is_rpq, election_from_exception, lapsed_date, retirement_date
    INTO #Expected
    FROM (VALUES (CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), N'T1', CAST(NULL AS date), CAST('2015-01-01' AS date), 0, 1, CAST(NULL AS date), CAST('2023-11-20' AS date)),
                 (CAST('00000000-0000-0000-0000-000000000006' AS uniqueidentifier), N'T6', CAST(NULL AS date), CAST('2015-01-01' AS date), 0, 1, CAST(NULL AS date), CAST(NULL AS date)))
         AS v(contact_id, contact_no, enrolment_date, election_date, is_rpq, election_from_exception, lapsed_date, retirement_date);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT layer, step_name, status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT layer, step_name, status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('silver', 'silv_member_base', 'Success', 2, 0, 0)) AS v(layer, step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-010 a rerun on unchanged sources leaves silv_member_base identical]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000001', N'T1', 0),
           ('00000000-0000-0000-0000-000000000006', N'T6', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', N'T1', '2021-06-01', '2024-01-01', 0),
           ('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000006', N'T6', '2022-02-02', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (1, N'T1', 0), (6, N'T6', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T1', '00000000-0000-0000-0000-000000000001', '2015-01-01'),
           (N'T6', '00000000-0000-0000-0000-000000000006', '2015-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T1', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T1', 2024, 'Fully Paid', '2023-11-20', '2023-11-20', 0, 'Retired Conc.');

    EXEC Layercake.usp_load_silv_member_base;
    SELECT * INTO #First FROM Layercake.silv_member_base;

    EXEC Layercake.usp_load_silv_member_base;
    SELECT * INTO #Second FROM Layercake.silv_member_base;

    EXEC tSQLt.AssertEqualsTable '#First', '#Second';

    DECLARE @succeeded int = (SELECT COUNT(*) FROM Layercake.etl_run_log WHERE step_name = 'silv_member_base' AND status = 'Success');
    EXEC tSQLt.AssertEquals 2, @succeeded;

    DECLARE @t1 date = (SELECT retirement_date FROM #Second WHERE contact_no = N'T1');
    DECLARE @t1_expected date = '2023-11-20';
    EXEC tSQLt.AssertEquals @t1_expected, @t1;
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD018.[test TC-018-011 a load the target rejects re-raises logs Failed and leaves silv_member_base unchanged]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000001', N'T1', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', N'T1', '2021-06-01', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (1, N'T1', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T1', '00000000-0000-0000-0000-000000000001', '2015-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T1', 2024, 'Fully Paid', '2023-11-20', '2023-11-20', 0, 'Retired Conc.');

    -- the previous run's content, as Phase 1 left it
    INSERT INTO Layercake.silv_member_base
        (contact_id, contact_no, enrolment_date, election_date, is_rpq, enrolment_from_exception, election_from_exception,
         enrolment_from_subs_history, election_from_subs_history, lapse_reason_id, retirement_date, rpq_variant_id, country_id, gender_id)
    VALUES ('00000000-0000-0000-0000-000000000001', N'T1', NULL, '2015-01-01', 0, 0, 1, 0, 0, 0, '2021-06-01', 0, 0, 0);

    -- test-only constraint: the target rejects the derived date, so the load fails while writing it
    ALTER TABLE Layercake.silv_member_base ADD CONSTRAINT ck_test_mod018_reject_derived
        CHECK (retirement_date IS NULL OR retirement_date <> '2023-11-20');

    SELECT * INTO #Before FROM Layercake.silv_member_base;

    BEGIN TRY
        EXEC Layercake.usp_load_silv_member_base;
        EXEC tSQLt.Fail 'usp_load_silv_member_base should have raised an error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    SELECT * INTO #After FROM Layercake.silv_member_base;
    EXEC tSQLt.AssertEqualsTable '#Before', '#After';

    SELECT step_name, status, CASE WHEN error_message IS NULL THEN 0 ELSE 1 END AS has_error_message
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT step_name, status, has_error_message
    INTO #ExpectedLog
    FROM (VALUES ('silv_member_base', 'Failed', 1)) AS v(step_name, status, has_error_message);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

/* ---------------- events: silv_membership_events and fact_membership_events ---------------- */

CREATE PROCEDURE test_MOD018.[test TC-018-012 T1 Renewals in silv_membership_events are Practising before and Retired from the derived date]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000001', N'T1', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', N'T1', '2021-06-01', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (1, N'T1', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T1', '00000000-0000-0000-0000-000000000001', '2015-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T1', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T1', 2024, 'Fully Paid', '2023-11-20', '2023-11-20', 0, 'Retired Conc.'),
           (N'T1', 2025, 'Fully Paid', '2024-10-05', '2024-10-05', 0, 'Retired Conc.');
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj)
    VALUES (N'T1', 2023, NULL, '2022-10-15'),
           (N'T1', 2024, NULL, '2023-10-20'),
           (N'T1', 2025, NULL, '2024-10-10');

    EXEC Layercake.usp_load_silv_member_base;
    EXEC Layercake.usp_load_silv_membership_events;

    SELECT event_type, event_date, membership_status_id
    INTO #Actual
    FROM Layercake.silv_membership_events
    WHERE contact_no = N'T1' AND event_type = 'Renewal';

    SELECT event_type, event_date, membership_status_id
    INTO #Expected
    FROM (VALUES ('Renewal', CAST('2022-10-15' AS date), 1),
                 ('Renewal', CAST('2023-10-20' AS date), 1),
                 ('Renewal', CAST('2024-10-10' AS date), 2)) AS v(event_type, event_date, membership_status_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-013 T1 Renewals in fact_membership_events are Practising before and Retired from the derived date]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000001', N'T1', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', N'T1', '2021-06-01', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (1, N'T1', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T1', '00000000-0000-0000-0000-000000000001', '2015-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T1', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T1', 2024, 'Fully Paid', '2023-11-20', '2023-11-20', 0, 'Retired Conc.'),
           (N'T1', 2025, 'Fully Paid', '2024-10-05', '2024-10-05', 0, 'Retired Conc.');
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj)
    VALUES (N'T1', 2023, NULL, '2022-10-15'),
           (N'T1', 2024, NULL, '2023-10-20'),
           (N'T1', 2025, NULL, '2024-10-10');

    EXEC Layercake.usp_load_silv_member_base;
    EXEC Layercake.usp_load_silv_membership_events;
    EXEC Layercake.usp_load_fact_membership_events;

    SELECT event_type, event_date, membership_status_id
    INTO #Actual
    FROM Layercake.fact_membership_events
    WHERE contact_no = N'T1' AND event_type = 'Renewal';

    SELECT event_type, event_date, membership_status_id
    INTO #Expected
    FROM (VALUES ('Renewal', CAST('2022-10-15' AS date), 1),
                 ('Renewal', CAST('2023-10-20' AS date), 1),
                 ('Renewal', CAST('2024-10-10' AS date), 2)) AS v(event_type, event_date, membership_status_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-014 every T4 event is Practising in silv and fact despite apuk 2019-05-01]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000004', N'T4', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000004', N'T4', '2019-05-01', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (4, N'T4', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T4', '00000000-0000-0000-0000-000000000004', '2010-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T4', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T4', 2024, 'Fully Paid', '2023-10-20', '2023-10-20', 0, 'Non-Retired Conc.');
    INSERT INTO Subs.vwSubsMemberStatuses ([Contact No.], [Campaign Year], [Retired Concession], [First Retired Year], [Renewal Date])
    VALUES (N'T4', 2023, 'No Conc.', 2018, '2022-10-15'),
           (N'T4', 2024, 'Non-Retired Conc.', 2018, '2023-10-20');
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj)
    VALUES (N'T4', 2023, NULL, '2022-10-15'),
           (N'T4', 2024, NULL, '2023-10-20');

    EXEC Layercake.usp_load_silv_member_base;
    EXEC Layercake.usp_load_silv_membership_events;
    EXEC Layercake.usp_load_fact_membership_events;

    SELECT event_type, event_date, membership_status_id
    INTO #ActualRenewals
    FROM Layercake.silv_membership_events
    WHERE contact_no = N'T4' AND event_type = 'Renewal';

    SELECT event_type, event_date, membership_status_id
    INTO #ExpectedRenewals
    FROM (VALUES ('Renewal', CAST('2022-10-15' AS date), 1),
                 ('Renewal', CAST('2023-10-20' AS date), 1)) AS v(event_type, event_date, membership_status_id);

    EXEC tSQLt.AssertEqualsTable '#ExpectedRenewals', '#ActualRenewals';

    SELECT event_id, event_type, event_date, membership_status_id
    INTO #NotPractisingSilver
    FROM Layercake.silv_membership_events
    WHERE contact_no = N'T4' AND membership_status_id <> 1;
    EXEC tSQLt.AssertEmptyTable '#NotPractisingSilver';

    SELECT event_id, event_type, event_date, membership_status_id
    INTO #NotPractisingGold
    FROM Layercake.fact_membership_events
    WHERE contact_no = N'T4' AND membership_status_id <> 1;
    EXEC tSQLt.AssertEmptyTable '#NotPractisingGold';

    DECLARE @gold int = (SELECT COUNT(*) FROM Layercake.fact_membership_events WHERE contact_no = N'T4' AND event_type = 'Renewal');
    EXEC tSQLt.AssertEquals 2, @gold;
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-015 silv_membership_events before and after differ only in membership_status_id of contacts whose date changed]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000001', N'T1', 0),
           ('00000000-0000-0000-0000-000000000004', N'T4', 0),
           ('00000000-0000-0000-0000-000000000008', N'T8', 0),
           ('00000000-0000-0000-0000-000000000009', N'T9', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', N'T1', '2021-06-01', '2024-01-01', 0),
           ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000004', N'T4', '2019-05-01', '2024-01-01', 0),
           ('10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000008', N'T8', '2023-11-20', '2024-01-01', 0),
           ('10000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000009', N'T9', NULL, '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (1, N'T1', 0), (4, N'T4', 0), (8, N'T8', 0), (9, N'T9', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T1', '00000000-0000-0000-0000-000000000001', '2015-01-01'),
           (N'T4', '00000000-0000-0000-0000-000000000004', '2010-01-01'),
           (N'T8', '00000000-0000-0000-0000-000000000008', '2012-01-01'),
           (N'T9', '00000000-0000-0000-0000-000000000009', '2012-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T1', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T1', 2024, 'Fully Paid', '2023-11-20', '2023-11-20', 0, 'Retired Conc.'),
           (N'T1', 2025, 'Fully Paid', '2024-10-05', '2024-10-05', 0, 'Retired Conc.'),
           (N'T4', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T4', 2024, 'Fully Paid', '2023-10-20', '2023-10-20', 0, 'Non-Retired Conc.'),
           (N'T8', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T8', 2024, 'Fully Paid', '2023-11-20', '2023-11-20', 0, 'Retired Conc.'),
           (N'T9', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T9', 2024, 'Fully Paid', '2023-10-20', '2023-10-20', 0, 'No Conc.');
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj)
    VALUES (N'T1', 2023, NULL, '2022-10-15'), (N'T1', 2024, NULL, '2023-10-20'), (N'T1', 2025, NULL, '2024-10-10'),
           (N'T4', 2023, NULL, '2022-10-15'), (N'T4', 2024, NULL, '2023-10-20'),
           (N'T8', 2023, NULL, '2022-10-15'), (N'T8', 2024, NULL, '2023-10-20'), (N'T8', 2025, NULL, '2024-10-10'),
           (N'T9', 2023, NULL, '2022-10-15'), (N'T9', 2024, NULL, '2023-10-20');

    -- before the change: silv_member_base as Phase 1 leaves it (retirement_date = apuk_retirementdate)
    EXEC Layercake.usp_load_silv_member_base;
    UPDATE b
    SET retirement_date = CAST(r.apuk_retirementdate AS date)
    FROM Layercake.silv_member_base b
    JOIN Layercake.brnz_rics_record r ON r.apuk_ricsmembershipnumber = b.contact_no;
    EXEC Layercake.usp_load_silv_membership_events;

    SELECT event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id, assessment_route_id,
           rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter
    INTO #Before
    FROM Layercake.silv_membership_events;

    -- after the change
    EXEC Layercake.usp_load_silv_member_base;
    EXEC Layercake.usp_load_silv_membership_events;

    SELECT event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id, assessment_route_id,
           rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter
    INTO #After
    FROM Layercake.silv_membership_events;

    -- 1. nothing but membership_status_id differs, and the same events exist with the same ids
    SELECT event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id, assessment_route_id,
           rpq_variant_id, hpb_id, country_id, gender_id, campaign_year, campaign_quarter
    INTO #BeforeOther FROM #Before;
    SELECT event_id, event_nk, event_type, event_subtype, event_date, source_enr_id, contact_no, grade_id, assessment_route_id,
           rpq_variant_id, hpb_id, country_id, gender_id, campaign_year, campaign_quarter
    INTO #AfterOther FROM #After;
    EXEC tSQLt.AssertEqualsTable '#BeforeOther', '#AfterOther';

    -- 2. exactly these events changed status
    SELECT b.contact_no, b.event_type, b.event_date, b.membership_status_id AS status_before, a.membership_status_id AS status_after
    INTO #Changed
    FROM #Before b
    JOIN #After a ON a.event_id = b.event_id
    WHERE a.membership_status_id <> b.membership_status_id;

    SELECT contact_no, event_type, event_date, status_before, status_after
    INTO #ExpectedChanged
    FROM (VALUES (N'T1', 'Renewal', CAST('2022-10-15' AS date), 2, 1),
                 (N'T1', 'Renewal', CAST('2023-10-20' AS date), 2, 1),
                 (N'T4', 'Renewal', CAST('2022-10-15' AS date), 2, 1),
                 (N'T4', 'Renewal', CAST('2023-10-20' AS date), 2, 1)) AS v(contact_no, event_type, event_date, status_before, status_after);
    EXEC tSQLt.AssertEqualsTable '#ExpectedChanged', '#Changed';

    -- 3. no changed event belongs to a contact whose derived date equals apuk_retirementdate
    SELECT c.contact_no
    INTO #ChangedSameDate
    FROM #Changed c
    JOIN Layercake.brnz_rics_record r ON r.apuk_ricsmembershipnumber = c.contact_no
    LEFT JOIN Layercake.vw_silv_derived_retirement_date d ON d.contact_no = c.contact_no
    WHERE (d.derived_retirement_date IS NULL AND r.apuk_retirementdate IS NULL)
       OR d.derived_retirement_date = CAST(r.apuk_retirementdate AS date);
    EXEC tSQLt.AssertEmptyTable '#ChangedSameDate';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-016 fact_membership_events before and after differ only in membership_status_id of contacts whose date changed]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000001', N'T1', 0),
           ('00000000-0000-0000-0000-000000000004', N'T4', 0),
           ('00000000-0000-0000-0000-000000000008', N'T8', 0),
           ('00000000-0000-0000-0000-000000000009', N'T9', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', N'T1', '2021-06-01', '2024-01-01', 0),
           ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000004', N'T4', '2019-05-01', '2024-01-01', 0),
           ('10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000008', N'T8', '2023-11-20', '2024-01-01', 0),
           ('10000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000009', N'T9', NULL, '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (1, N'T1', 0), (4, N'T4', 0), (8, N'T8', 0), (9, N'T9', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T1', '00000000-0000-0000-0000-000000000001', '2015-01-01'),
           (N'T4', '00000000-0000-0000-0000-000000000004', '2010-01-01'),
           (N'T8', '00000000-0000-0000-0000-000000000008', '2012-01-01'),
           (N'T9', '00000000-0000-0000-0000-000000000009', '2012-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T1', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T1', 2024, 'Fully Paid', '2023-11-20', '2023-11-20', 0, 'Retired Conc.'),
           (N'T1', 2025, 'Fully Paid', '2024-10-05', '2024-10-05', 0, 'Retired Conc.'),
           (N'T4', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T4', 2024, 'Fully Paid', '2023-10-20', '2023-10-20', 0, 'Non-Retired Conc.'),
           (N'T8', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T8', 2024, 'Fully Paid', '2023-11-20', '2023-11-20', 0, 'Retired Conc.'),
           (N'T9', 2023, 'Fully Paid', '2022-10-15', '2022-10-15', 0, 'No Conc.'),
           (N'T9', 2024, 'Fully Paid', '2023-10-20', '2023-10-20', 0, 'No Conc.');
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj)
    VALUES (N'T1', 2023, NULL, '2022-10-15'), (N'T1', 2024, NULL, '2023-10-20'), (N'T1', 2025, NULL, '2024-10-10'),
           (N'T4', 2023, NULL, '2022-10-15'), (N'T4', 2024, NULL, '2023-10-20'),
           (N'T8', 2023, NULL, '2022-10-15'), (N'T8', 2024, NULL, '2023-10-20'), (N'T8', 2025, NULL, '2024-10-10'),
           (N'T9', 2023, NULL, '2022-10-15'), (N'T9', 2024, NULL, '2023-10-20');

    -- before the change: silv_member_base as Phase 1 leaves it (retirement_date = apuk_retirementdate)
    EXEC Layercake.usp_load_silv_member_base;
    UPDATE b
    SET retirement_date = CAST(r.apuk_retirementdate AS date)
    FROM Layercake.silv_member_base b
    JOIN Layercake.brnz_rics_record r ON r.apuk_ricsmembershipnumber = b.contact_no;
    EXEC Layercake.usp_load_silv_membership_events;
    EXEC Layercake.usp_load_fact_membership_events;

    SELECT event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id,
           rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter
    INTO #Before
    FROM Layercake.fact_membership_events;

    -- after the change
    EXEC Layercake.usp_load_silv_member_base;
    EXEC Layercake.usp_load_silv_membership_events;
    EXEC Layercake.usp_load_fact_membership_events;

    SELECT event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id,
           rpq_variant_id, hpb_id, country_id, gender_id, membership_status_id, campaign_year, campaign_quarter
    INTO #After
    FROM Layercake.fact_membership_events;

    SELECT event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id,
           rpq_variant_id, hpb_id, country_id, gender_id, campaign_year, campaign_quarter
    INTO #BeforeOther FROM #Before;
    SELECT event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id,
           rpq_variant_id, hpb_id, country_id, gender_id, campaign_year, campaign_quarter
    INTO #AfterOther FROM #After;
    EXEC tSQLt.AssertEqualsTable '#BeforeOther', '#AfterOther';

    SELECT b.contact_no, b.event_type, b.event_date, b.membership_status_id AS status_before, a.membership_status_id AS status_after
    INTO #Changed
    FROM #Before b
    JOIN #After a ON a.event_id = b.event_id
    WHERE a.membership_status_id <> b.membership_status_id;

    SELECT contact_no, event_type, event_date, status_before, status_after
    INTO #ExpectedChanged
    FROM (VALUES (N'T1', 'Renewal', CAST('2022-10-15' AS date), 2, 1),
                 (N'T1', 'Renewal', CAST('2023-10-20' AS date), 2, 1),
                 (N'T4', 'Renewal', CAST('2022-10-15' AS date), 2, 1),
                 (N'T4', 'Renewal', CAST('2023-10-20' AS date), 2, 1)) AS v(contact_no, event_type, event_date, status_before, status_after);
    EXEC tSQLt.AssertEqualsTable '#ExpectedChanged', '#Changed';
END;
GO

/* ---------------- daily count and annual rate base ---------------- */

CREATE PROCEDURE test_MOD018.[test TC-018-017 T5 daily detail is Practising up to the day before the derived date and Retired from it]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000005', N'T5', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000005', N'T5', '2024-03-01', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (5, N'T5', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T5', '00000000-0000-0000-0000-000000000005', '2015-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T5', 2024, 'Fully Paid', '2023-10-20', '2023-10-20', 0, 'No Conc.'),
           (N'T5', 2025, 'Full Concession', '2025-01-15', '2025-01-15', 0, 'Retired Conc.');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'T5', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2024-06-01', 2024, 'Q3'), ('2025-01-14', 2025, 'Q2'), ('2025-01-15', 2025, 'Q2'), ('2025-02-01', 2025, 'Q2');

    EXEC Layercake.usp_load_silv_member_base;
    EXEC Layercake.usp_load_silv_member_profile;
    EXEC Layercake.usp_load_silv_daily_count;

    SELECT [date], grade, membership_status_id, active_count
    INTO #Actual
    FROM Layercake.silv_daily_count_detail;

    SELECT [date], grade, membership_status_id, active_count
    INTO #Expected
    FROM (VALUES (CAST('2024-06-01' AS date), 'election', 1, 1),
                 (CAST('2025-01-14' AS date), 'election', 1, 1),
                 (CAST('2025-01-15' AS date), 'election', 2, 1),
                 (CAST('2025-02-01' AS date), 'election', 2, 1)) AS v([date], grade, membership_status_id, active_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-018 T5 counts only under Practising in silv_annual_rate_base for CY2024]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000005', N'T5', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000005', N'T5', '2024-03-01', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (5, N'T5', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T5', '00000000-0000-0000-0000-000000000005', '2015-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T5', 2024, 'Fully Paid', '2023-10-20', '2023-10-20', 0, 'No Conc.'),
           (N'T5', 2025, 'Full Concession', '2025-01-15', '2025-01-15', 0, 'Retired Conc.');
    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2024, '2023-10-01', '2024-09-30', '2024-06-01'),
           (2025, '2024-10-01', '2025-09-30', '2025-06-01');

    EXEC Layercake.usp_load_silv_member_base;
    EXEC Layercake.usp_load_silv_annual_rate_base;

    SELECT campaign_year, grade_id, membership_status_id, country_id, gender_id, members_start, members_end,
           members_joined, members_readmitted, members_lapsed, members_renewed
    INTO #Actual
    FROM Layercake.silv_annual_rate_base;

    SELECT campaign_year, grade_id, membership_status_id, country_id, gender_id, members_start, members_end,
           members_joined, members_readmitted, members_lapsed, members_renewed
    INTO #Expected
    FROM (VALUES (2024, 2, 1, 0, 0, 1, 1, 0, 0, 0, 0),
                 (2025, 2, 1, 0, 0, 1, 0, 0, 0, 0, 0),
                 (2025, 2, 2, 0, 0, 0, 1, 0, 0, 0, 0))
         AS v(campaign_year, grade_id, membership_status_id, country_id, gender_id, members_start, members_end,
              members_joined, members_readmitted, members_lapsed, members_renewed);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-019 T5 counts only under Practising in fact_annual_rate_base for CY2024]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000005', N'T5', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000005', N'T5', '2024-03-01', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (5, N'T5', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T5', '00000000-0000-0000-0000-000000000005', '2015-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T5', 2024, 'Fully Paid', '2023-10-20', '2023-10-20', 0, 'No Conc.'),
           (N'T5', 2025, 'Full Concession', '2025-01-15', '2025-01-15', 0, 'Retired Conc.');
    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2024, '2023-10-01', '2024-09-30', '2024-06-01'),
           (2025, '2024-10-01', '2025-09-30', '2025-06-01');

    EXEC Layercake.usp_load_silv_member_base;
    EXEC Layercake.usp_load_silv_annual_rate_base;
    EXEC Layercake.usp_load_fact_annual_rate_base;

    SELECT campaign_year, grade_id, membership_status_id, country_id, gender_id, members_start, members_end,
           members_joined, members_readmitted, members_lapsed, members_renewed
    INTO #Actual
    FROM Layercake.fact_annual_rate_base;

    SELECT campaign_year, grade_id, membership_status_id, country_id, gender_id, members_start, members_end,
           members_joined, members_readmitted, members_lapsed, members_renewed
    INTO #Expected
    FROM (VALUES (2024, 2, 1, 0, 0, 1, 1, 0, 0, 0, 0),
                 (2025, 2, 1, 0, 0, 1, 0, 0, 0, 0, 0),
                 (2025, 2, 2, 0, 0, 0, 1, 0, 0, 0, 0))
         AS v(campaign_year, grade_id, membership_status_id, country_id, gender_id, members_start, members_end,
              members_joined, members_readmitted, members_lapsed, members_renewed);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018.[test TC-018-020 loaded daily history keeps the old split until a rebuild from the pending date applies the derived date]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-000000000005', N'T5', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000005', N'T5', '2024-03-01', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (5, N'T5', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'T5', '00000000-0000-0000-0000-000000000005', '2015-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Member Invoice Position], [Renewal Date], [Renewal Date Adj], _is_deleted, retired_concession)
    VALUES (N'T5', 2024, 'Fully Paid', '2023-10-20', '2023-10-20', 0, 'No Conc.'),
           (N'T5', 2025, 'Full Concession', '2025-01-15', '2025-01-15', 0, 'Retired Conc.');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'T5', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2024-06-01', 2024, 'Q3'), ('2025-02-01', 2025, 'Q2');

    -- as Phase 1 left it: profile on apuk 2024-03-01, both days loaded and counted Retired
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'T5', 0, 0, '2024-03-01');
    INSERT INTO Layercake.etl_daily_count_loaded ([date], run_id, batch_from, batch_to)
    VALUES ('2024-06-01', NULL, '2024-06-01', '2024-06-01'), ('2025-02-01', NULL, '2025-02-01', '2025-02-01');
    INSERT INTO Layercake.silv_daily_count_detail
        ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
         active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
    VALUES ('2024-06-01', 2024, 'Q3', 'UK', 0, 0, 'election', 2, 1, 0, 0, 0, 0, 0, 0),
           ('2025-02-01', 2025, 'Q2', 'UK', 0, 0, 'election', 2, 1, 0, 0, 0, 0, 0, 0);

    EXEC Layercake.usp_load_silv_member_base;
    EXEC Layercake.usp_load_silv_member_profile;
    EXEC Layercake.usp_load_silv_daily_count;

    -- the daily run does not rebuild loaded dates
    DECLARE @before_rebuild int = (SELECT membership_status_id FROM Layercake.silv_daily_count_detail WHERE [date] = '2024-06-01');
    EXEC tSQLt.AssertEquals 2, @before_rebuild;

    -- the profile change registered a pending rebuild from the earlier of the two dates
    DECLARE @from date = (SELECT affected_from FROM Layercake.etl_daily_count_pending_rebuild WHERE [source] = 'member_profile' AND applied_at IS NULL);
    DECLARE @from_expected date = '2024-03-01';
    EXEC tSQLt.AssertEquals @from_expected, @from;

    -- the one-off handover rebuild
    EXEC Layercake.usp_load_silv_daily_count @RebuildFrom = @from;

    SELECT [date], grade, membership_status_id, active_count
    INTO #Actual
    FROM Layercake.silv_daily_count_detail;

    SELECT [date], grade, membership_status_id, active_count
    INTO #Expected
    FROM (VALUES (CAST('2024-06-01' AS date), 'election', 1, 1),
                 (CAST('2025-02-01' AS date), 'election', 2, 1)) AS v([date], grade, membership_status_id, active_count);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    DECLARE @open int = (SELECT COUNT(*) FROM Layercake.etl_daily_count_pending_rebuild WHERE [source] = 'member_profile' AND applied_at IS NULL);
    EXEC tSQLt.AssertEquals 0, @open;
END;
GO
