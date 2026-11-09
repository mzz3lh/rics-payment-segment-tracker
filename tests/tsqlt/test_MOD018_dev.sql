EXEC tSQLt.NewTestClass 'test_MOD018_dev';
GO

CREATE PROCEDURE test_MOD018_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.brnz_subs_status';
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
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
END;
GO

/* ---------------- view ---------------- */

CREATE PROCEDURE test_MOD018_dev.[test view columns have the designed types and nullability]
AS
BEGIN
    SELECT TOP (0)
        CAST(N'' AS nvarchar(200)) AS contact_no,
        CAST(0 AS int) AS retirement_campaign_year,
        CAST('2000-01-01' AS date) AS derived_retirement_date
    INTO #Expected;

    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT contact_no, retirement_campaign_year, derived_retirement_date FROM #Expected',
        'SELECT contact_no, retirement_campaign_year, derived_retirement_date FROM Layercake.vw_silv_derived_retirement_date';
END;
GO

CREATE PROCEDURE test_MOD018_dev.[test a case or trailing space variant of Retired Conc counts as retired]
AS
BEGIN
    -- chosen behaviour: retired_concession is compared as the database collation compares it
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], _is_deleted, retired_concession)
    VALUES (N'D1', 2024, '2023-11-02', 0, 'RETIRED CONC. '),
           (N'D2', 2024, '2023-11-03', 0, 'Retired'),
           (N'D3', 2024, '2023-11-04', 0, 'Non-Retired Conc.');

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Actual
    FROM Layercake.vw_silv_derived_retirement_date;

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Expected
    FROM (VALUES (N'D1', 2024, CAST('2023-11-02' AS date))) AS v (contact_no, retirement_campaign_year, derived_retirement_date);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018_dev.[test a contact whose only Retired Conc rows are deleted or undated has no row]
AS
BEGIN
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], _is_deleted, retired_concession)
    VALUES (N'D4', 2023, '2022-11-01', 1, 'Retired Conc.'),
           (N'D4', 2024, NULL, 0, 'Retired Conc.'),
           (N'D4', 2025, '2024-10-05', 0, 'No Conc.');

    SELECT contact_no, retirement_campaign_year, derived_retirement_date
    INTO #Actual
    FROM Layercake.vw_silv_derived_retirement_date;

    EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO

/* ---------------- Layercake.usp_load_silv_member_base ---------------- */

CREATE PROCEDURE test_MOD018_dev.[test the derived date is taken even when the latest rics record has no apuk date]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-0000000000d5', N'D5', 0);
    -- two rics records: the latest (2024) has no apuk date, the older one has
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-0000000000d5', '00000000-0000-0000-0000-0000000000d5', N'D5', '2018-01-01', '2020-01-01', 0),
           ('20000000-0000-0000-0000-0000000000d5', '00000000-0000-0000-0000-0000000000d5', N'D5', NULL, '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (5, N'D5', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'D5', '00000000-0000-0000-0000-0000000000d5', '2015-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], _is_deleted, retired_concession)
    VALUES (N'D5', 2025, '2024-11-11', 0, 'Retired Conc.');

    EXEC Layercake.usp_load_silv_member_base;

    SELECT contact_no, retirement_date
    INTO #Actual
    FROM Layercake.silv_member_base;

    SELECT contact_no, retirement_date
    INTO #Expected
    FROM (VALUES (N'D5', CAST('2024-11-11' AS date))) AS v (contact_no, retirement_date);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD018_dev.[test the log counts the rows inserted and the previous rows as deleted]
AS
BEGIN
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-0000000000d6', N'D6', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-0000000000d6', '00000000-0000-0000-0000-0000000000d6', N'D6', '2021-06-01', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (6, N'D6', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'D6', '00000000-0000-0000-0000-0000000000d6', '2015-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], _is_deleted, retired_concession)
    VALUES (N'D6', 2024, '2023-12-01', 0, 'Retired Conc.');

    -- the previous run's content: two rows, replaced wholesale by the full re-derive
    INSERT INTO Layercake.silv_member_base (contact_id, contact_no, retirement_date)
    VALUES ('00000000-0000-0000-0000-0000000000d6', N'D6', '2021-06-01'),
           ('00000000-0000-0000-0000-0000000000d7', N'D7', NULL);

    EXEC Layercake.usp_load_silv_member_base;

    SELECT layer, step_name, status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT layer, step_name, status, rows_inserted, rows_updated, rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('silver', 'silv_member_base', 'Success', 1, 0, 2)) AS v (layer, step_name, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';

    SELECT contact_no, retirement_date
    INTO #Actual
    FROM Layercake.silv_member_base;

    SELECT contact_no, retirement_date
    INTO #Expected
    FROM (VALUES (N'D6', CAST('2023-12-01' AS date))) AS v (contact_no, retirement_date);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD018_dev.[test a rejected null retirement date fails the load logs Failed and keeps the previous rows]
AS
BEGIN
    -- D8 has an apuk date but no derived date, so the load writes NULL; a test-only CHECK rejects it
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, _is_deleted)
    VALUES ('00000000-0000-0000-0000-0000000000d8', N'D8', 0);
    INSERT INTO Layercake.brnz_rics_record (Id, apuk_contactid, apuk_ricsmembershipnumber, apuk_retirementdate, ModifiedOn, _is_deleted)
    VALUES ('10000000-0000-0000-0000-0000000000d8', '00000000-0000-0000-0000-0000000000d8', N'D8', '2019-05-01', '2024-01-01', 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (8, N'D8', 0);
    INSERT INTO Layercake.ref_enrolment_exception (contact_no, contact_id, derived_election_date)
    VALUES (N'D8', '00000000-0000-0000-0000-0000000000d8', '2010-01-01');
    INSERT INTO Layercake.brnz_subs_status ([Contact No.], [Campaign Year], [Renewal Date], _is_deleted, retired_concession)
    VALUES (N'D8', 2024, '2023-10-20', 0, 'Non-Retired Conc.');

    INSERT INTO Layercake.silv_member_base (contact_id, contact_no, retirement_date)
    VALUES ('00000000-0000-0000-0000-0000000000d8', N'D8', '2019-05-01');

    ALTER TABLE Layercake.silv_member_base ADD CONSTRAINT ck_test_mod018_dev_no_null_retirement
        CHECK (retirement_date IS NOT NULL);

    BEGIN TRY
        EXEC Layercake.usp_load_silv_member_base;
        EXEC tSQLt.Fail 'usp_load_silv_member_base should have raised an error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    SELECT contact_no, retirement_date
    INTO #Actual
    FROM Layercake.silv_member_base;

    SELECT contact_no, retirement_date
    INTO #Expected
    FROM (VALUES (N'D8', CAST('2019-05-01' AS date))) AS v (contact_no, retirement_date);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT step_name, status, CASE WHEN error_message LIKE '%547%' THEN 1 ELSE 0 END AS has_error_547
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT step_name, status, has_error_547
    INTO #ExpectedLog
    FROM (VALUES ('silv_member_base', 'Failed', 1)) AS v (step_name, status, has_error_547);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
