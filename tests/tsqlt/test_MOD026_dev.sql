EXEC tSQLt.NewTestClass 'test_MOD026_dev';
GO

CREATE PROCEDURE test_MOD026_dev.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'Layercake.etl_run_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_progress_log', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_loaded', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_pending_rebuild', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_input_basis', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_contact', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_state_range', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_payment', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_event', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_cell_contacts', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail';
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count';
    EXEC tSQLt.FakeTable 'Layercake.ref_date_spine';
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_status';
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_state_ranges';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_profile';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events';

    INSERT INTO Layercake.silv_ref_membership_status (id, status_name)
    VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2021, '2020-10-01', '2021-09-30', '2021-06-01'),
           (2022, '2021-10-01', '2022-09-30', '2022-06-01'),
           (2023, '2022-10-01', '2023-09-30', '2023-06-01'),
           (2024, '2023-10-01', '2024-09-30', '2024-06-01'),
           (2025, '2024-10-01', '2025-09-30', '2025-06-01');

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2025-01-09', 2025, 'Q2'), ('2025-01-10', 2025, 'Q2'), ('2025-01-11', 2025, 'Q2');

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'D1', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (2, N'D2', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D1', 1, 1, NULL), (N'D2', 2, 2, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'D2', 2025, '2024-10-20', '2024-10-20', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events (event_id, event_nk, event_type, event_subtype, event_date, contact_no, campaign_year, campaign_quarter)
    VALUES (1, N'RN:D2:2025', 'Renewal', 'Standard', '2024-10-20', N'D2', 2025, 'Q1');
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD026_dev.[test a failed run that only adds contacts sends the next run down the full path and counts each once]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID();
    DECLARE @failed bit = 0, @status varchar(10);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    -- two new contacts only: N9's NULL region fails the 2025-01-10 batch after the 2025-01-09 batch has committed N8
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (8, N'N8', '2025-01-09', NULL, 2025, 'election', 'UK', 1),
           (9, N'N9', '2025-01-10', NULL, 2025, 'election', NULL, 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'N8', 81, 1, NULL), (N'N9', 82, 1, NULL);

    BEGIN TRY
        EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @DailyCountBatchDays = 1;
    END TRY
    BEGIN CATCH
        SET @failed = 1;
        IF ERROR_NUMBER() <> 515 THROW;
    END CATCH;
    IF @failed = 0
        EXEC tSQLt.Fail 'run 2 did not fail on N9''s NULL region';

    SELECT @status = status FROM Layercake.etl_run_log WHERE run_id = @r2 AND layer = 'silver' AND step_name = 'silv_daily_count';
    EXEC tSQLt.AssertEqualsString 'Failed', @status, 'run 2 step status';

    -- the appeared contacts hold a snapshot header and no basis row: out of step
    SELECT v.contact_no INTO #out_expected FROM (VALUES (N'N8'), (N'N9')) AS v(contact_no);
    SELECT h.contact_no
    INTO #out_actual
    FROM Layercake.etl_daily_count_applied_contact AS h
    WHERE NOT EXISTS (SELECT 1 FROM Layercake.etl_daily_count_input_basis AS b
                      WHERE b.input_name = 'contact' AND b.input_key = h.contact_no);
    EXEC tSQLt.AssertEqualsTable '#out_expected', '#out_actual', 'contacts out of step after the failed run';

    UPDATE Layercake.silv_member_state_ranges SET region = 'UK' WHERE id = 9;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3;

    SELECT p.substep, p.rows_affected
    INTO #path_actual
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r3 AND p.substep = N'full_recompute_path';
    SELECT v.substep, v.rows_affected INTO #path_expected FROM (VALUES (N'full_recompute_path', 1)) AS v(substep, rows_affected);
    EXEC tSQLt.AssertEqualsTable '#path_expected', '#path_actual', 'run 3 path';

    SELECT CAST(v.d AS date) AS [date], v.country_id, v.a AS active_count
    INTO #expected
    FROM (VALUES ('2025-01-09', 81, 1), ('2025-01-10', 81, 1), ('2025-01-11', 81, 1),
                 ('2025-01-10', 82, 1), ('2025-01-11', 82, 1)) AS v(d, country_id, a);
    SELECT [date], country_id, active_count
    INTO #actual FROM Layercake.silv_daily_count_detail WHERE country_id IN (81, 82);
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'N8 and N9 each counted once';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD026_dev.[test the guard names the first overlapping contact by contact_no with the number affected and logs no path]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @failed bit = 0, @err_msg nvarchar(4000), @n int;

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (21, N'A2', '2023-01-01', '2024-06-01', 2023, 'election', 'UK', 1),
           (22, N'A2', '2024-05-31', NULL, 2024, 'election', 'UK', 2),
           (23, N'A1', '2023-01-01', NULL, 2023, 'enrolment', 'UK', 1),
           (24, N'A1', '2023-01-01', NULL, 2023, 'enrolment', 'UK', 1);

    BEGIN TRY
        EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    END TRY
    BEGIN CATCH
        SET @failed = 1;
        SET @err_msg = ERROR_MESSAGE();
        IF ERROR_NUMBER() <> 50026 THROW;
    END CATCH;
    IF @failed = 0
        EXEC tSQLt.Fail 'the load did not fail on overlapping ranges';

    EXEC tSQLt.AssertLike '%contact A1 %(2 contact(s) affected)%', @err_msg, 'guard message';

    SELECT @n = COUNT(*)
    FROM Layercake.etl_progress_log AS p
    JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r1 AND p.substep IN (N'contacts_recomputed', N'full_recompute_path');
    EXEC tSQLt.AssertEquals 0, @n, 'a run stopped by the guard logged its path';

    SELECT [date] INTO #detail FROM Layercake.silv_daily_count_detail;
    EXEC tSQLt.AssertEmptyTable '#detail', 'the guard let the load write detail rows';
END;
GO

CREATE PROCEDURE test_MOD026_dev.[test a normal run that empties a cell logs 3 inserted 0 updated 3 deleted]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (31, N'M1', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'M1', 3, 2, NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    UPDATE Layercake.silv_member_profile SET country_id = 4 WHERE contact_no = N'M1';
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT status, rows_inserted, rows_updated, rows_deleted
    INTO #log_actual
    FROM Layercake.etl_run_log
    WHERE run_id = @r2 AND layer = 'silver' AND step_name = 'silv_daily_count';
    SELECT v.status, v.rows_inserted, v.rows_updated, v.rows_deleted
    INTO #log_expected
    FROM (VALUES (CAST('Success' AS varchar(10)), 3, 0, 3)) AS v(status, rows_inserted, rows_updated, rows_deleted);
    EXEC tSQLt.AssertEqualsTable '#log_expected', '#log_actual', 'run 2 row counts';

    SELECT [date] INTO #country3 FROM Layercake.etl_daily_count_cell_contacts WHERE country_id = 3;
    EXEC tSQLt.AssertEmptyTable '#country3', 'the emptied cell kept its contact count';
END;
GO

CREATE PROCEDURE test_MOD026_dev.[test a FullRebuild with no input change leaves every snapshot row as the first run wrote it]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @FullRebuild = 1;

    SELECT v.contact_no, v.run_id
    INTO #expected
    FROM (VALUES (N'D1', @r1), (N'D2', @r1)) AS v(contact_no, run_id);
    SELECT contact_no, run_id INTO #actual FROM Layercake.etl_daily_count_applied_contact;
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'snapshot headers after the FullRebuild';

    SELECT v.contact_no, CAST(v.valid_from AS date) AS valid_from
    INTO #ranges_expected
    FROM (VALUES (N'D1', '2015-01-01'), (N'D2', '2015-01-01')) AS v(contact_no, valid_from);
    SELECT contact_no, valid_from INTO #ranges_actual FROM Layercake.etl_daily_count_applied_state_range;
    EXEC tSQLt.AssertEqualsTable '#ranges_expected', '#ranges_actual', 'snapshot ranges after the FullRebuild';
END;
GO

CREATE PROCEDURE test_MOD026_dev.[test a new lapsed contact with no measures gets its cell and a contact count of 1 and no adjustment]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @n int;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (41, N'Z1', '2020-01-01', NULL, 2020, 'lapse', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'Z1', 91, 1, NULL);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT CAST(v.d AS date) AS [date], v.grade, v.membership_status_id, v.a AS active_count, v.p AS paid_count,
           v.pe AS paid_count_event, v.l AS event_lapse_count, v.c AS contact_count
    INTO #expected
    FROM (VALUES ('2025-01-09', 'lapse', 0, 0, 0, 0, 0, 1), ('2025-01-10', 'lapse', 0, 0, 0, 0, 0, 1),
                 ('2025-01-11', 'lapse', 0, 0, 0, 0, 0, 1)) AS v(d, grade, membership_status_id, a, p, pe, l, c);
    SELECT d.[date], d.grade, d.membership_status_id, d.active_count, d.paid_count, d.paid_count_event,
           d.event_lapse_count, cc.contact_count
    INTO #actual
    FROM Layercake.silv_daily_count_detail AS d
    JOIN Layercake.etl_daily_count_cell_contacts AS cc
      ON cc.[date] = d.[date] AND cc.region = d.region AND cc.country_id = d.country_id AND cc.gender_id = d.gender_id
     AND cc.grade = d.grade AND cc.membership_status_id = d.membership_status_id
    WHERE d.country_id = 91;
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual', 'Z1 cells and contact counts';

    SELECT @n = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEquals 0, @n, 'a cell with no measures wrote adjustment rows';
END;
GO

CREATE PROCEDURE test_MOD026_dev.[test a contact applied with no profile moves from country 0 when its profile arrives]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (51, N'P1', '2015-01-01', NULL, 2015, 'election', 'UK', 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT v.contact_no, v.profile_found, v.country_id
    INTO #header_expected
    FROM (VALUES (N'P1', CAST(0 AS bit), CAST(NULL AS int))) AS v(contact_no, profile_found, country_id);
    SELECT contact_no, profile_found, country_id
    INTO #header_actual FROM Layercake.etl_daily_count_applied_contact WHERE contact_no = N'P1';
    EXEC tSQLt.AssertEqualsTable '#header_expected', '#header_actual', 'P1 header after run 1';

    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'P1', 95, 1, NULL);
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT CAST(v.d AS date) AS [date], v.country_id, v.gender_id, v.a AS active_count_change
    INTO #adj_expected
    FROM (VALUES ('2025-01-09', 0, 0, -1), ('2025-01-09', 95, 1, 1),
                 ('2025-01-10', 0, 0, -1), ('2025-01-10', 95, 1, 1),
                 ('2025-01-11', 0, 0, -1), ('2025-01-11', 95, 1, 1)) AS v(d, country_id, gender_id, a);
    SELECT [date], country_id, gender_id, active_count_change
    INTO #adj_actual FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;
    EXEC tSQLt.AssertEqualsTable '#adj_expected', '#adj_actual', 'run 2 adjustment rows';

    SELECT [date] INTO #country0 FROM Layercake.silv_daily_count_detail WHERE country_id = 0;
    EXEC tSQLt.AssertEmptyTable '#country0', 'P1 still sits in country 0';
END;
GO
