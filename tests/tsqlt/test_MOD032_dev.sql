EXEC tSQLt.NewTestClass 'test_MOD032_dev';
GO

CREATE PROCEDURE test_MOD032_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_cust_trans', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_rics_record', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.brnz_contact_test_record', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_lapse_reason';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_gender';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_grade';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_status';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_country';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_local_group', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_base', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_annual_rate_base', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_annual_rate_base', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_date';

    INSERT INTO Layercake.silv_ref_membership_grade (id, grade_name)
    VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');
    INSERT INTO Layercake.silv_ref_membership_status (id, status_name)
    VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');
    INSERT INTO Layercake.silv_ref_gender (id, gender_code, gender_name)
    VALUES (1, 1, 'Male');
    INSERT INTO Layercake.silv_ref_country (id, country_id, country_name, region_name, market_reporting_region)
    VALUES (1, 'C0000000-0000-0000-0000-000000000001', N'United Kingdom', N'UK&I', 'UK&I'),
           (2, 'C0000000-0000-0000-0000-000000000002', N'United Arab Emirates', N'MEA', 'MEA'),
           (3, 'C0000000-0000-0000-0000-000000000003', N'India', N'APAC', 'APAC');
    INSERT INTO Layercake.silv_ref_local_group
        (id, local_group_bk, local_group_name, local_group_code, country_id, region_name, market_reporting_region,
         statecode, is_reportable, dim_country_id, load_id, created_at, updated_at)
    VALUES (0, NULL, N'Unknown', NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-01-01', '2026-01-01'),
           (1, 'A0000000-0000-0000-0000-000000000001', N'Gulf', N'GULF', 2, N'MEA', 'MEA', 0, 1, 2, NULL, '2026-01-01', '2026-01-01'),
           (6, 'A0000000-0000-0000-0000-000000000006', N'Closed Gulf', N'CGULF', 2, N'MEA', 'MEA', 1, 0, NULL, NULL, '2026-01-01', '2026-01-01');
END;
GO

/* ---------------- Layercake.usp_load_silv_membership_events ---------------- */

CREATE PROCEDURE test_MOD032_dev.[test a Join Subscription event takes its country local group and own country from vw_silv_contact_local_group]
AS
BEGIN
    -- S1 (own country UK) is in Gulf, a usable group; S2 (own country India) is in Closed Gulf,
    -- which is not usable, so the whole-member fallback applies (RULE-171 to RULE-173).
    -- Neither has a member base row, so both take the Join/Subscription branch.
    INSERT INTO Layercake.brnz_contact (ContactId, Rics_contactno, GenderCode, rics_countryid, rics_localgroupid, CreatedOn, StateCode, _is_deleted)
    VALUES ('B0000000-0000-0000-0000-000000000001', N'S1', 1, 'C0000000-0000-0000-0000-000000000001', 'A0000000-0000-0000-0000-000000000001', '2020-01-01', 0, 0),
           ('B0000000-0000-0000-0000-000000000002', N'S2', 1, 'C0000000-0000-0000-0000-000000000003', 'A0000000-0000-0000-0000-000000000006', '2020-01-01', 0, 0);
    INSERT INTO Layercake.brnz_cust_trans (recid, accountnum, _is_deleted)
    VALUES (1, N'S1', 0), (2, N'S2', 0);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'S1', 2025, '2024-10-15', '2024-10-15', N'Fully Paid'),
           (N'S1', 2026, '2025-10-15', '2025-10-15', N'Fully Paid'),
           (N'S2', 2025, '2024-11-05', '2024-11-05', N'Fully Paid');

    EXEC Layercake.usp_load_silv_membership_events;

    -- the S1 Renewal has no member base row behind it, so it keeps Phase 1's 0 country and
    -- takes local group 0 and own country 0 with it (left join to the base, unchanged)
    SELECT event_nk, event_type, event_subtype, country_id, local_group_id, contact_country_id
    INTO #Actual
    FROM Layercake.silv_membership_events;

    SELECT event_nk, event_type, event_subtype, country_id, local_group_id, contact_country_id
    INTO #Expected
    FROM (VALUES (N'JS:S1', 'Join', 'Subscription', 2, 1, 1),
                 (N'RN:S1:2026', 'Renewal', 'Standard', 0, 0, 0),
                 (N'JS:S2', 'Join', 'Subscription', 3, 0, 3))
         AS v (event_nk, event_type, event_subtype, country_id, local_group_id, contact_country_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD032_dev.[test a member base row without the new columns counts under local group 0 and its own country_id]
AS
BEGIN
    -- the change script gives rows stored before deployment local group 0 and the own country
    -- equal to country_id; the load reads a base row missing them the same way
    INSERT INTO Layercake.silv_member_base
        (contact_id, contact_no, enrolment_date, election_date, is_rpq, retirement_date, lapsed_date, rpq_variant_id, country_id, gender_id)
    VALUES ('B0000000-0000-0000-0000-000000000003', N'M1', NULL, '2015-01-01', 0, NULL, NULL, 0, 3, 1);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'M1', 2025, '2024-10-20', '2024-10-20', N'Fully Paid');

    EXEC Layercake.usp_load_silv_membership_events;

    SELECT event_nk, country_id, local_group_id, contact_country_id
    INTO #Actual
    FROM Layercake.silv_membership_events;

    SELECT event_nk, country_id, local_group_id, contact_country_id
    INTO #Expected
    FROM (VALUES (N'JR:M1', 3, 0, 3), (N'RN:M1:2025', 3, 0, 3))
         AS v (event_nk, country_id, local_group_id, contact_country_id);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD032_dev.[test the events log counts an update for each event whose local group alone changed]
AS
BEGIN
    INSERT INTO Layercake.silv_member_base
        (contact_id, contact_no, enrolment_date, election_date, is_rpq, retirement_date, lapsed_date, rpq_variant_id,
         country_id, gender_id, local_group_id, contact_country_id)
    VALUES ('B0000000-0000-0000-0000-000000000004', N'G1', NULL, '2015-01-01', 0, NULL, NULL, 0, 2, 1, 1, 1);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'G1', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');

    EXEC Layercake.usp_load_silv_membership_events @run_id = 'E0000000-0000-0000-0000-000000000001';
    UPDATE Layercake.silv_member_base SET local_group_id = 0 WHERE contact_no = N'G1';
    EXEC Layercake.usp_load_silv_membership_events @run_id = 'E0000000-0000-0000-0000-000000000002';
    EXEC Layercake.usp_load_silv_membership_events @run_id = 'E0000000-0000-0000-0000-000000000003';

    SELECT run_id, status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;

    SELECT CAST(v.run_id AS uniqueidentifier) AS run_id, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('E0000000-0000-0000-0000-000000000001', 'Success', 2, 0, 0),
                 ('E0000000-0000-0000-0000-000000000002', 'Success', 0, 2, 0),
                 ('E0000000-0000-0000-0000-000000000003', 'Success', 0, 0, 0))
         AS v (run_id, status, rows_inserted, rows_updated, rows_deleted);

    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD032_dev.[test a duplicate member fails the events load logs Failed and leaves the events unchanged]
AS
BEGIN
    -- two member base rows for one contact derive two JR:D1 events: the stage key rejects them
    INSERT INTO Layercake.silv_member_base
        (contact_id, contact_no, enrolment_date, election_date, is_rpq, retirement_date, lapsed_date, rpq_variant_id,
         country_id, gender_id, local_group_id, contact_country_id)
    VALUES ('B0000000-0000-0000-0000-000000000005', N'D1', NULL, '2015-01-01', 0, NULL, NULL, 0, 1, 1, 0, 1),
           ('B0000000-0000-0000-0000-000000000006', N'D1', NULL, '2015-01-01', 0, NULL, NULL, 0, 1, 1, 0, 1);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'D1', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events
        (event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, local_group_id, contact_country_id)
    VALUES (N'JR:OLD', 'Join', 'Direct Entry', '2010-01-01', N'OLD', 2, 0, 0, 0, 1, 1, 1, 2010, 'Q2', 0, 1);

    BEGIN TRY
        EXEC Layercake.usp_load_silv_membership_events;
        EXEC tSQLt.Fail 'usp_load_silv_membership_events should have raised an error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 2627 THROW;
    END CATCH;

    SELECT event_nk INTO #Actual FROM Layercake.silv_membership_events;
    SELECT v.event_nk INTO #Expected FROM (VALUES (N'JR:OLD')) AS v (event_nk);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT step_name, status, CASE WHEN error_message LIKE '%2627%' THEN 1 ELSE 0 END AS has_error_2627
    INTO #ActualLog
    FROM Layercake.etl_run_log;
    SELECT v.step_name, v.status, v.has_error_2627
    INTO #ExpectedLog
    FROM (VALUES ('silv_membership_events', 'Failed', 1)) AS v (step_name, status, has_error_2627);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

/* ---------------- Layercake.usp_load_fact_membership_events ---------------- */

CREATE PROCEDURE test_MOD032_dev.[test a changed group dim_country row alone updates the gold event in place and logs one update]
AS
BEGIN
    INSERT INTO Layercake.silv_membership_events
        (event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, local_group_id, contact_country_id)
    VALUES (N'JR:G1', 'Join', 'Direct Entry', '2015-01-01', N'G1', 2, 0, 0, 0, 2, 1, 1, 2015, 'Q2', 1, 1),
           (N'JR:N1', 'Join', 'Direct Entry', '2015-01-01', N'N1', 2, 0, 0, 0, 3, 1, 1, 2015, 'Q2', 0, 3);

    EXEC Layercake.usp_load_fact_membership_events @run_id = 'E0000000-0000-0000-0000-000000000001';
    UPDATE Layercake.silv_ref_local_group SET dim_country_id = 1000002 WHERE id = 1;
    EXEC Layercake.usp_load_fact_membership_events @run_id = 'E0000000-0000-0000-0000-000000000002';

    SELECT event_id, country_id, local_group_id, contact_country_id
    INTO #Actual
    FROM Layercake.fact_membership_events;
    SELECT v.event_id, v.country_id, v.local_group_id, v.contact_country_id
    INTO #Expected
    FROM (VALUES (1, 1000002, 1, 1), (2, 3, 0, 3)) AS v (event_id, country_id, local_group_id, contact_country_id);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT run_id, status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;
    SELECT CAST(v.run_id AS uniqueidentifier) AS run_id, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('E0000000-0000-0000-0000-000000000001', 'Success', 2, 0, 0),
                 ('E0000000-0000-0000-0000-000000000002', 'Success', 0, 1, 0))
         AS v (run_id, status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD032_dev.[test a duplicate silver event_id fails the gold events load logs Failed and leaves gold unchanged]
AS
BEGIN
    EXEC tSQLt.ApplyConstraint 'Layercake.fact_membership_events', 'pk_fact_membership_events';
    INSERT INTO Layercake.fact_membership_events
        (event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, local_group_id, contact_country_id)
    VALUES (9, 'Join', 'Direct Entry', '2010-01-01', 0, N'OLD', 2, 0, 0, 0, 1, 1, 1, 2010, 'Q2', 0, 1);

    SET IDENTITY_INSERT Layercake.silv_membership_events ON;
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter, local_group_id, contact_country_id)
    VALUES (5, N'JR:X1', 'Join', 'Direct Entry', '2015-01-01', N'X1', 2, 0, 0, 0, 1, 1, 1, 2015, 'Q2', 0, 1),
           (5, N'JR:X2', 'Join', 'Direct Entry', '2015-01-01', N'X2', 2, 0, 0, 0, 1, 1, 1, 2015, 'Q2', 0, 1);
    SET IDENTITY_INSERT Layercake.silv_membership_events OFF;

    BEGIN TRY
        EXEC Layercake.usp_load_fact_membership_events;
        EXEC tSQLt.Fail 'usp_load_fact_membership_events should have raised an error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 2627 THROW;
    END CATCH;

    SELECT event_id, contact_no INTO #Actual FROM Layercake.fact_membership_events;
    SELECT v.event_id, v.contact_no INTO #Expected FROM (VALUES (9, N'OLD')) AS v (event_id, contact_no);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT step_name, status, CASE WHEN error_message LIKE '%2627%' THEN 1 ELSE 0 END AS has_error_2627
    INTO #ActualLog
    FROM Layercake.etl_run_log;
    SELECT v.step_name, v.status, v.has_error_2627
    INTO #ExpectedLog
    FROM (VALUES ('fact_membership_events', 'Failed', 1)) AS v (step_name, status, has_error_2627);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

/* ---------------- Layercake.usp_load_silv_annual_rate_base ---------------- */

CREATE PROCEDURE test_MOD032_dev.[test the annual load moves a member to its new local group with one insert and one delete]
AS
BEGIN
    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2025, '2024-10-01', '2025-09-30', '2025-12-31');
    INSERT INTO Layercake.silv_member_base
        (contact_id, contact_no, enrolment_date, election_date, is_rpq, retirement_date, lapsed_date, rpq_variant_id,
         country_id, gender_id, local_group_id, contact_country_id)
    VALUES ('B0000000-0000-0000-0000-000000000007', N'G1', NULL, '2015-01-01', 0, NULL, NULL, 0, 2, 1, 1, 1);

    EXEC Layercake.usp_load_silv_annual_rate_base @run_id = 'E0000000-0000-0000-0000-000000000001';
    UPDATE Layercake.silv_member_base SET country_id = 1, local_group_id = 0 WHERE contact_no = N'G1';
    EXEC Layercake.usp_load_silv_annual_rate_base @run_id = 'E0000000-0000-0000-0000-000000000002';

    SELECT campaign_year, country_id, local_group_id, contact_country_id, members_start, members_end
    INTO #Actual
    FROM Layercake.silv_annual_rate_base;
    SELECT v.campaign_year, v.country_id, v.local_group_id, v.contact_country_id, v.members_start, v.members_end
    INTO #Expected
    FROM (VALUES (2025, 1, 0, 1, 1, 1)) AS v (campaign_year, country_id, local_group_id, contact_country_id, members_start, members_end);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT run_id, status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;
    SELECT CAST(v.run_id AS uniqueidentifier) AS run_id, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('E0000000-0000-0000-0000-000000000001', 'Success', 1, 0, 0),
                 ('E0000000-0000-0000-0000-000000000002', 'Success', 1, 0, 1))
         AS v (run_id, status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD032_dev.[test a campaign year whose boundary cannot be a date fails the annual load logs Failed and leaves it unchanged]
AS
BEGIN
    -- 30 Sep of year 10000 is not a valid date; the member makes the boundary headcount run
    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (10001, '9999-10-01', '9999-12-31', '9999-12-31');
    INSERT INTO Layercake.silv_member_base
        (contact_id, contact_no, enrolment_date, election_date, is_rpq, retirement_date, lapsed_date, rpq_variant_id,
         country_id, gender_id, local_group_id, contact_country_id)
    VALUES ('B0000000-0000-0000-0000-000000000008', N'O1', NULL, '2015-01-01', 0, NULL, NULL, 0, 1, 1, 0, 1);
    INSERT INTO Layercake.silv_annual_rate_base
        (campaign_year, grade_id, membership_status_id, country_id, gender_id, local_group_id, contact_country_id,
         members_start, members_end, members_joined, members_readmitted, members_lapsed, members_renewed)
    VALUES (2024, 2, 1, 1, 1, 0, 1, 5, 5, 0, 0, 0, 5);

    BEGIN TRY
        EXEC Layercake.usp_load_silv_annual_rate_base;
        EXEC tSQLt.Fail 'usp_load_silv_annual_rate_base should have raised an error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 289 THROW;
    END CATCH;

    SELECT campaign_year, local_group_id, contact_country_id, members_start
    INTO #Actual
    FROM Layercake.silv_annual_rate_base;
    SELECT v.campaign_year, v.local_group_id, v.contact_country_id, v.members_start
    INTO #Expected
    FROM (VALUES (2024, 0, 1, 5)) AS v (campaign_year, local_group_id, contact_country_id, members_start);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT step_name, status, CASE WHEN error_message LIKE '%289%' THEN 1 ELSE 0 END AS has_error_289
    INTO #ActualLog
    FROM Layercake.etl_run_log;
    SELECT v.step_name, v.status, v.has_error_289
    INTO #ExpectedLog
    FROM (VALUES ('silv_annual_rate_base', 'Failed', 1)) AS v (step_name, status, has_error_289);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

/* ---------------- Layercake.usp_load_fact_annual_rate_base ---------------- */

CREATE PROCEDURE test_MOD032_dev.[test a changed group dim_country row moves the gold annual row with one insert and one delete]
AS
BEGIN
    INSERT INTO Layercake.silv_annual_rate_base
        (campaign_year, grade_id, membership_status_id, country_id, gender_id, local_group_id, contact_country_id,
         members_start, members_end, members_joined, members_readmitted, members_lapsed, members_renewed)
    VALUES (2025, 2, 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 1),
           (2025, 2, 1, 3, 1, 0, 3, 1, 1, 0, 0, 0, 1);

    EXEC Layercake.usp_load_fact_annual_rate_base @run_id = 'E0000000-0000-0000-0000-000000000001';
    UPDATE Layercake.silv_ref_local_group SET dim_country_id = 1000002 WHERE id = 1;
    EXEC Layercake.usp_load_fact_annual_rate_base @run_id = 'E0000000-0000-0000-0000-000000000002';

    SELECT id, country_id, local_group_id, contact_country_id, members_start
    INTO #Actual
    FROM Layercake.fact_annual_rate_base;
    SELECT v.id, v.country_id, v.local_group_id, v.contact_country_id, v.members_start
    INTO #Expected
    FROM (VALUES (2, 3, 0, 3, 1), (3, 1000002, 1, 1, 1)) AS v (id, country_id, local_group_id, contact_country_id, members_start);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT run_id, status, rows_inserted, rows_updated, rows_deleted
    INTO #ActualLog
    FROM Layercake.etl_run_log;
    SELECT CAST(v.run_id AS uniqueidentifier) AS run_id, v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #ExpectedLog
    FROM (VALUES ('E0000000-0000-0000-0000-000000000001', 'Success', 2, 0, 0),
                 ('E0000000-0000-0000-0000-000000000002', 'Success', 1, 0, 1))
         AS v (run_id, status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD032_dev.[test two silver rows mapping to one gold key fail the gold annual load log Failed and leave it unchanged]
AS
BEGIN
    -- both rows are in Gulf (reportable, dim_country_id 2) but carry different silver countries,
    -- so both map to the same gold key: the stage's unique index rejects them
    INSERT INTO Layercake.silv_annual_rate_base
        (campaign_year, grade_id, membership_status_id, country_id, gender_id, local_group_id, contact_country_id,
         members_start, members_end, members_joined, members_readmitted, members_lapsed, members_renewed)
    VALUES (2025, 2, 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 1),
           (2025, 2, 1, 3, 1, 1, 1, 1, 1, 0, 0, 0, 1);
    INSERT INTO Layercake.fact_annual_rate_base
        (campaign_year, grade_id, membership_status_id, country_id, gender_id, local_group_id, contact_country_id,
         members_start, members_end, members_joined, members_readmitted, members_lapsed, members_renewed)
    VALUES (2024, 2, 1, 1, 1, 0, 1, 5, 5, 0, 0, 0, 5);

    BEGIN TRY
        EXEC Layercake.usp_load_fact_annual_rate_base;
        EXEC tSQLt.Fail 'usp_load_fact_annual_rate_base should have raised an error';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 1505 THROW;
    END CATCH;

    SELECT campaign_year, country_id, members_start INTO #Actual FROM Layercake.fact_annual_rate_base;
    SELECT v.campaign_year, v.country_id, v.members_start INTO #Expected FROM (VALUES (2024, 1, 5)) AS v (campaign_year, country_id, members_start);
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

    SELECT step_name, status, CASE WHEN error_message LIKE '%1505%' THEN 1 ELSE 0 END AS has_error_1505
    INTO #ActualLog
    FROM Layercake.etl_run_log;
    SELECT v.step_name, v.status, v.has_error_1505
    INTO #ExpectedLog
    FROM (VALUES ('fact_annual_rate_base', 'Failed', 1)) AS v (step_name, status, has_error_1505);
    EXEC tSQLt.AssertEqualsTable '#ExpectedLog', '#ActualLog';
END;
GO
