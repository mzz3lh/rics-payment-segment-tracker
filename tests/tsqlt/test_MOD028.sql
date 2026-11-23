EXEC tSQLt.NewTestClass 'test_MOD028';
GO

CREATE PROCEDURE test_MOD028.[SetUp]
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
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_applied_attribute', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.etl_daily_count_cell_contacts', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_adjustment', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count_detail', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_daily_count', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.ref_date_spine';
    EXEC tSQLt.FakeTable 'Layercake.ref_campaign_year_config';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_status';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_membership_grade';
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payment_method', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_ref_concession_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_membership_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_state_ranges';
    EXEC tSQLt.FakeTable 'Layercake.silv_member_profile';
    EXEC tSQLt.FakeTable 'Layercake.silv_payment_events', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.silv_member_year_attributes', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.fact_daily_member_count_detail', @Identity = 1, @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_date';
    EXEC tSQLt.FakeTable 'Layercake.dim_membership_grade';
    EXEC tSQLt.FakeTable 'Layercake.dim_payment_method', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_payer_type', @Defaults = 1;
    EXEC tSQLt.FakeTable 'Layercake.dim_concession_type', @Defaults = 1;

    INSERT INTO Layercake.ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end, bulk_lapse_date)
    VALUES (2021, '2020-10-01', '2021-09-30', '2021-06-01'),
           (2022, '2021-10-01', '2022-09-30', '2022-06-01'),
           (2023, '2022-10-01', '2023-09-30', '2023-06-01'),
           (2024, '2023-10-01', '2024-09-30', '2024-06-01'),
           (2025, '2024-10-01', '2025-09-30', '2025-06-01'),
           (2026, '2025-10-01', '2026-09-30', '2026-05-01'),
           (2027, '2026-10-01', '2027-09-30', '2027-05-01');

    INSERT INTO Layercake.silv_ref_membership_status (id, status_name) VALUES (0, 'N/A'), (1, 'Practising'), (2, 'Retired');
    INSERT INTO Layercake.silv_ref_membership_grade (id, grade_name) VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');
    INSERT INTO Layercake.dim_membership_grade (id, grade_name) VALUES (0, 'N/A'), (1, 'Candidate'), (2, 'Qualified');

    INSERT INTO Layercake.silv_ref_payment_method (id, payment_method_name, source_code, created_at, updated_at)
    VALUES (0, 'Unknown', NULL, SYSDATETIME(), SYSDATETIME()),
           (-1, 'Unrecognised', NULL, SYSDATETIME(), SYSDATETIME()),
           (-2, 'Not applicable', NULL, SYSDATETIME(), SYSDATETIME()),
           (1, 'Direct Debit', 'DD', SYSDATETIME(), SYSDATETIME()),
           (2, 'Card', 'Card', SYSDATETIME(), SYSDATETIME()),
           (3, 'Bank transfer', 'Bank', SYSDATETIME(), SYSDATETIME()),
           (4, 'Cheque', 'Cheque', SYSDATETIME(), SYSDATETIME()),
           (5, 'Corporate', 'Corporate', SYSDATETIME(), SYSDATETIME());
    INSERT INTO Layercake.dim_payment_method (id, payment_method_name, load_id, created_at, updated_at)
    VALUES (0, 'Unknown', NULL, SYSDATETIME(), SYSDATETIME()),
           (-1, 'Unrecognised', NULL, SYSDATETIME(), SYSDATETIME()),
           (-2, 'Not applicable', NULL, SYSDATETIME(), SYSDATETIME()),
           (1, 'Direct Debit', NULL, SYSDATETIME(), SYSDATETIME()),
           (2, 'Card', NULL, SYSDATETIME(), SYSDATETIME()),
           (3, 'Bank transfer', NULL, SYSDATETIME(), SYSDATETIME()),
           (4, 'Cheque', NULL, SYSDATETIME(), SYSDATETIME()),
           (5, 'Corporate', NULL, SYSDATETIME(), SYSDATETIME());

    INSERT INTO Layercake.silv_ref_payer_type (id, payer_type_name, created_at, updated_at)
    VALUES (0, 'Unknown', SYSDATETIME(), SYSDATETIME()),
           (-1, 'Unrecognised', SYSDATETIME(), SYSDATETIME()),
           (-2, 'Not applicable', SYSDATETIME(), SYSDATETIME()),
           (1, 'Individual', SYSDATETIME(), SYSDATETIME()),
           (2, 'Corporate', SYSDATETIME(), SYSDATETIME());
    INSERT INTO Layercake.dim_payer_type (id, payer_type_name, load_id, created_at, updated_at)
    VALUES (0, 'Unknown', NULL, SYSDATETIME(), SYSDATETIME()),
           (-1, 'Unrecognised', NULL, SYSDATETIME(), SYSDATETIME()),
           (-2, 'Not applicable', NULL, SYSDATETIME(), SYSDATETIME()),
           (1, 'Individual', NULL, SYSDATETIME(), SYSDATETIME()),
           (2, 'Corporate', NULL, SYSDATETIME(), SYSDATETIME());

    INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, NULL, N'Unknown', NULL, 0, 0, NULL, SYSDATETIME(), SYSDATETIME()),
           (-1, NULL, N'Unrecognised', NULL, 0, 0, NULL, SYSDATETIME(), SYSDATETIME()),
           (-2, NULL, N'Not applicable', NULL, 0, 0, NULL, SYSDATETIME(), SYSDATETIME()),
           (1, NULL, N'No concession', NULL, 0, 0, NULL, SYSDATETIME(), SYSDATETIME()),
           (6, '6A1D2C3B-0000-4000-8000-000000000006', N'Exceptional Hardship', N'CONEXCEPTIONHP', 0, 0, NULL, SYSDATETIME(), SYSDATETIME());
    INSERT INTO Layercake.dim_concession_type (id, concession_type_name, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (0, N'Unknown', 0, 0, NULL, SYSDATETIME(), SYSDATETIME()),
           (-1, N'Unrecognised', 0, 0, NULL, SYSDATETIME(), SYSDATETIME()),
           (-2, N'Not applicable', 0, 0, NULL, SYSDATETIME(), SYSDATETIME()),
           (1, N'No concession', 0, 0, NULL, SYSDATETIME(), SYSDATETIME()),
           (6, N'Exceptional Hardship', 0, 0, NULL, SYSDATETIME(), SYSDATETIME());
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-001 detail and fact keep their columns and gain three not null int segment ids]
AS
BEGIN
    DECLARE @det int, @fact int;
    SELECT @det = r.ObjectId FROM tSQLt.Private_RenamedObjectLog AS r
    WHERE REPLACE(REPLACE(r.OriginalName, N'[', N''), N']', N'') IN (N'silv_daily_count_detail', N'Layercake.silv_daily_count_detail')
      AND OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake';
    IF @det IS NULL SET @det = OBJECT_ID(N'Layercake.silv_daily_count_detail');
    SELECT @fact = r.ObjectId FROM tSQLt.Private_RenamedObjectLog AS r
    WHERE REPLACE(REPLACE(r.OriginalName, N'[', N''), N']', N'') IN (N'fact_daily_member_count_detail', N'Layercake.fact_daily_member_count_detail')
      AND OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake';
    IF @fact IS NULL SET @fact = OBJECT_ID(N'Layercake.fact_daily_member_count_detail');

    SELECT c.name COLLATE DATABASE_DEFAULT AS column_name,
           TYPE_NAME(c.user_type_id) COLLATE DATABASE_DEFAULT AS type_name,
           CAST(c.is_nullable AS int) AS is_nullable
    INTO #ActualDetail
    FROM sys.columns AS c
    WHERE c.object_id = @det;

    SELECT v.column_name, v.type_name, v.is_nullable
    INTO #ExpectedDetail
    FROM (VALUES (N'date', N'date', 0), (N'campaign_year', N'int', 0), (N'campaign_quarter', N'char', 0),
                 (N'region', N'varchar', 0), (N'country_id', N'int', 0), (N'gender_id', N'int', 0),
                 (N'grade', N'varchar', 0), (N'membership_status_id', N'int', 0),
                 (N'payment_method_id', N'int', 0), (N'payer_type_id', N'int', 0), (N'concession_type_id', N'int', 0),
                 (N'active_count', N'int', 0), (N'paid_count', N'int', 0), (N'paid_count_event', N'int', 0),
                 (N'event_join_count', N'int', 0), (N'event_renewal_count', N'int', 0),
                 (N'event_readmission_count', N'int', 0), (N'event_lapse_count', N'int', 0)) AS v(column_name, type_name, is_nullable);

    EXEC tSQLt.AssertEqualsTable '#ExpectedDetail', '#ActualDetail', 'silv_daily_count_detail columns';

    SELECT c.name COLLATE DATABASE_DEFAULT AS column_name,
           TYPE_NAME(c.user_type_id) COLLATE DATABASE_DEFAULT AS type_name,
           CAST(c.is_nullable AS int) AS is_nullable
    INTO #ActualFact
    FROM sys.columns AS c
    WHERE c.object_id = @fact;

    SELECT v.column_name, v.type_name, v.is_nullable
    INTO #ExpectedFact
    FROM (VALUES (N'id', N'bigint', 0), (N'date_id', N'int', 0), (N'country_id', N'int', 0), (N'gender_id', N'int', 0),
                 (N'membership_grade_id', N'int', 0), (N'membership_status_id', N'int', 0),
                 (N'payment_method_id', N'int', 0), (N'payer_type_id', N'int', 0), (N'concession_type_id', N'int', 0),
                 (N'ActiveMembers', N'int', 0), (N'PaidMembers', N'int', 0), (N'PaidMembersEvent', N'int', 0),
                 (N'JoinEvents', N'int', 0), (N'RenewalEvents', N'int', 0), (N'ReadmissionEvents', N'int', 0),
                 (N'LapseEvents', N'int', 0)) AS v(column_name, type_name, is_nullable);

    EXEC tSQLt.AssertEqualsTable '#ExpectedFact', '#ActualFact', 'fact_daily_member_count_detail columns';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-002 adjustment history cell counts review view and detail function gain the three segment ids]
AS
BEGIN
    DECLARE @adj int, @cc int;
    SELECT @adj = r.ObjectId FROM tSQLt.Private_RenamedObjectLog AS r
    WHERE REPLACE(REPLACE(r.OriginalName, N'[', N''), N']', N'') IN (N'silv_daily_count_adjustment', N'Layercake.silv_daily_count_adjustment')
      AND OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake';
    IF @adj IS NULL SET @adj = OBJECT_ID(N'Layercake.silv_daily_count_adjustment');
    SELECT @cc = r.ObjectId FROM tSQLt.Private_RenamedObjectLog AS r
    WHERE REPLACE(REPLACE(r.OriginalName, N'[', N''), N']', N'') IN (N'etl_daily_count_cell_contacts', N'Layercake.etl_daily_count_cell_contacts')
      AND OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake';
    IF @cc IS NULL SET @cc = OBJECT_ID(N'Layercake.etl_daily_count_cell_contacts');

    SELECT o.object_name,
           (SELECT COUNT(*) FROM sys.columns AS c WHERE c.object_id = o.obj_id) AS column_count,
           (SELECT COUNT(*) FROM sys.columns AS c
            WHERE c.object_id = o.obj_id
              AND c.name IN (N'payment_method_id', N'payer_type_id', N'concession_type_id')
              AND TYPE_NAME(c.user_type_id) = N'int') AS segment_int_columns,
           CASE WHEN o.is_table = 1 THEN
               (SELECT COUNT(*) FROM sys.columns AS c
                WHERE c.object_id = o.obj_id
                  AND c.name IN (N'payment_method_id', N'payer_type_id', N'concession_type_id')
                  AND c.is_nullable = 0)
           END AS segment_not_null_columns
    INTO #Actual
    FROM (VALUES (N'silv_daily_count_adjustment', @adj, 1),
                 (N'etl_daily_count_cell_contacts', @cc, 1),
                 (N'vw_silv_daily_count_adjustment_review', OBJECT_ID(N'Layercake.vw_silv_daily_count_adjustment_review'), 0),
                 (N'fn_silv_daily_count_detail_as_known_at', OBJECT_ID(N'Layercake.fn_silv_daily_count_detail_as_known_at'), 0)) AS o(object_name, obj_id, is_table);

    SELECT v.object_name, v.column_count, v.segment_int_columns, v.segment_not_null_columns
    INTO #Expected
    FROM (VALUES (N'silv_daily_count_adjustment', 20, 3, 3),
                 (N'etl_daily_count_cell_contacts', 15, 3, 3),
                 (N'vw_silv_daily_count_adjustment_review', 14, 3, NULL),
                 (N'fn_silv_daily_count_detail_as_known_at', 16, 3, NULL)) AS v(object_name, column_count, segment_int_columns, segment_not_null_columns);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-003 fact unique clustered index covers the eight grain columns with no foreign key on the new ids and id bigint]
AS
BEGIN
    DECLARE @fact int, @fk int, @idtype sysname;
    SELECT @fact = r.ObjectId FROM tSQLt.Private_RenamedObjectLog AS r
    WHERE REPLACE(REPLACE(r.OriginalName, N'[', N''), N']', N'') IN (N'fact_daily_member_count_detail', N'Layercake.fact_daily_member_count_detail')
      AND OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake';
    IF @fact IS NULL SET @fact = OBJECT_ID(N'Layercake.fact_daily_member_count_detail');

    SELECT c.name COLLATE DATABASE_DEFAULT AS column_name
    INTO #Actual
    FROM sys.indexes AS i
    INNER JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
    INNER JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = @fact
      AND i.type = 1
      AND i.is_unique = 1;

    SELECT v.column_name
    INTO #Expected
    FROM (VALUES (N'date_id'), (N'country_id'), (N'gender_id'), (N'membership_grade_id'), (N'membership_status_id'),
                 (N'payment_method_id'), (N'payer_type_id'), (N'concession_type_id')) AS v(column_name);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'unique clustered index key columns';

    SELECT @fk = COUNT(*)
    FROM sys.foreign_key_columns AS fkc
    INNER JOIN sys.columns AS c ON c.object_id = fkc.parent_object_id AND c.column_id = fkc.parent_column_id
    WHERE fkc.parent_object_id = @fact
      AND c.name IN (N'payment_method_id', N'payer_type_id', N'concession_type_id');
    EXEC tSQLt.AssertEquals 0, @fk, 'foreign keys on the three segment columns';

    SELECT @idtype = TYPE_NAME(c.user_type_id) FROM sys.columns AS c WHERE c.object_id = @fact AND c.name = N'id';
    EXEC tSQLt.AssertEqualsString N'bigint', @idtype, 'id type';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-004 silv_daily_count columns and fn_silv_daily_count_as_known_at result columns are unchanged]
AS
BEGIN
    DECLARE @day int;
    SELECT @day = r.ObjectId FROM tSQLt.Private_RenamedObjectLog AS r
    WHERE REPLACE(REPLACE(r.OriginalName, N'[', N''), N']', N'') IN (N'silv_daily_count', N'Layercake.silv_daily_count')
      AND OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake';
    IF @day IS NULL SET @day = OBJECT_ID(N'Layercake.silv_daily_count');

    SELECT c.name COLLATE DATABASE_DEFAULT AS column_name
    INTO #ActualDay
    FROM sys.columns AS c
    WHERE c.object_id = @day;

    SELECT v.column_name
    INTO #ExpectedDay
    FROM (VALUES (N'date'), (N'campaign_year'), (N'campaign_quarter'), (N'region'), (N'grade'),
                 (N'active_count'), (N'paid_count'), (N'paid_count_event'), (N'event_join_count'),
                 (N'event_renewal_count'), (N'event_readmission_count'), (N'event_lapse_count')) AS v(column_name);

    EXEC tSQLt.AssertEqualsTable '#ExpectedDay', '#ActualDay', 'silv_daily_count columns';

    SELECT c.name COLLATE DATABASE_DEFAULT AS column_name
    INTO #ActualFn
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(N'Layercake.fn_silv_daily_count_as_known_at');

    SELECT v.column_name
    INTO #ExpectedFn
    FROM (VALUES (N'date'), (N'region'), (N'grade'),
                 (N'active_count'), (N'paid_count'), (N'paid_count_event'), (N'event_join_count'),
                 (N'event_renewal_count'), (N'event_readmission_count'), (N'event_lapse_count')) AS v(column_name);

    EXEC tSQLt.AssertEqualsTable '#ExpectedFn', '#ActualFn', 'fn_silv_daily_count_as_known_at columns';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-005 Y1 moves from the Direct Debit cell to the Card cell on 1 October in silver and gold]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2024-09-01', 2024, 'Q4'), ('2024-09-30', 2024, 'Q4'), ('2024-10-01', 2025, 'Q1'), ('2025-03-31', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2024-09-01', 2024, 'Q4'), (2, '2024-09-30', 2024, 'Q4'), (3, '2024-10-01', 2025, 'Q1'), (4, '2025-03-31', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y1', '2023-10-01', NULL, 2024, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date) VALUES (N'Y1', 1, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y1', 2024, 1, 0, 1, 0, 1, 0, 1), (N'Y1', 2025, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    SELECT CAST(v.[date] AS date) AS [date], v.campaign_year, CAST(v.campaign_quarter AS char(2)) AS campaign_quarter,
           CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('2024-09-01', 2024, 'Q4', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2024-09-30', 2024, 'Q4', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2024-10-01', 2025, 'Q1', 'UK', 1, 1, 'election', 1, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-03-31', 2025, 'Q2', 'UK', 1, 1, 'election', 1, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
              payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
                  payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'silv_daily_count_detail';

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpectedFact
    FROM (VALUES (1, 1, 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 (2, 1, 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 (3, 1, 1, 2, 1, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 (4, 1, 1, 2, 1, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    SELECT TOP (0) * INTO #ActualFact FROM #ExpectedFact;
    INSERT INTO #ActualFact
    EXEC (N'SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
           FROM Layercake.fact_daily_member_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#ExpectedFact', '#ActualFact', 'fact_daily_member_count_detail';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-006 Y2 with no attributes row for the day Campaign Year is counted under 0 Unknown]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES ('2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter) VALUES (1, '2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y2', '2024-10-01', NULL, 2025, 'election', 'UK', 1),
           (2, N'Y2B', '2024-10-01', NULL, 2025, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'Y2', 2, 1, NULL), (N'Y2B', 22, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y2B', 2024, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('2025-01-10', 'UK', 2, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 22, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'silv_daily_count_detail';

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpectedFact
    FROM (VALUES (1, 2, 1, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 (1, 22, 1, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    SELECT TOP (0) * INTO #ActualFact FROM #ExpectedFact;
    INSERT INTO #ActualFact
    EXEC (N'SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
           FROM Layercake.fact_daily_member_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#ExpectedFact', '#ActualFact', 'fact_daily_member_count_detail';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-007 Y3 on 2021-05-01 is counted under -2 Not applicable from its 2021 attributes]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES ('2021-05-01', 2021, 'Q3');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter) VALUES (1, '2021-05-01', 2021, 'Q3');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y3', '2020-01-01', NULL, 2020, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date) VALUES (N'Y3', 3, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y3', 2021, -2, 0, -2, 0, -2, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('2021-05-01', 'UK', 3, 1, 'election', 1, -2, -2, -2, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'silv_daily_count_detail';

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id, v.concession_type_id, v.ActiveMembers
    INTO #ExpectedFact
    FROM (VALUES (1, 3, 1, 2, 1, -2, -2, -2, 1))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id, ActiveMembers);

    SELECT TOP (0) * INTO #ActualFact FROM #ExpectedFact;
    INSERT INTO #ActualFact
    EXEC (N'SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id, ActiveMembers
           FROM Layercake.fact_daily_member_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#ExpectedFact', '#ActualFact', 'fact_daily_member_count_detail';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-008 the cell changes on 2021-10-01 from the 2021 row or 0 to the 2022 attributes]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2021-09-30', 2021, 'Q4'), ('2021-10-01', 2022, 'Q1');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2021-09-30', 2021, 'Q4'), (2, '2021-10-01', 2022, 'Q1');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y12', '2020-01-01', NULL, 2020, 'election', 'UK', 1),
           (2, N'Y13', '2020-01-01', NULL, 2020, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'Y12', 12, 1, NULL), (N'Y13', 13, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y12', 2022, 2, 0, 1, 0, 1, 0, 1),
           (N'Y13', 2021, -2, 0, -2, 0, -2, 0, 1),
           (N'Y13', 2022, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('2021-09-30', 'UK', 12, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2021-10-01', 'UK', 12, 1, 'election', 1, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2021-09-30', 'UK', 13, 1, 'election', 1, -2, -2, -2, 1, 0, 0, 0, 0, 0, 0),
                 ('2021-10-01', 'UK', 13, 1, 'election', 1, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-009 Y4 carried and Y5 not carried share one cell and no carried flag column exists]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @det int, @fact int, @carried int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES ('2025-11-01', 2026, 'Q1');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter) VALUES (1, '2025-11-01', 2026, 'Q1');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y4', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (2, N'Y5', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'Y4', 1, 1, NULL), (N'Y5', 1, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y4', 2026, 2, 1, 1, 1, 1, 0, 1),
           (N'Y5', 2026, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('2025-11-01', 'UK', 1, 1, 'election', 1, 2, 1, 1, 2, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'silv_daily_count_detail';

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id, v.concession_type_id, v.ActiveMembers
    INTO #ExpectedFact
    FROM (VALUES (1, 1, 1, 2, 1, 2, 1, 1, 2))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id, ActiveMembers);

    SELECT TOP (0) * INTO #ActualFact FROM #ExpectedFact;
    INSERT INTO #ActualFact
    EXEC (N'SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id, ActiveMembers
           FROM Layercake.fact_daily_member_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#ExpectedFact', '#ActualFact', 'fact_daily_member_count_detail';

    SELECT @det = r.ObjectId FROM tSQLt.Private_RenamedObjectLog AS r
    WHERE REPLACE(REPLACE(r.OriginalName, N'[', N''), N']', N'') IN (N'silv_daily_count_detail', N'Layercake.silv_daily_count_detail')
      AND OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake';
    SELECT @fact = r.ObjectId FROM tSQLt.Private_RenamedObjectLog AS r
    WHERE REPLACE(REPLACE(r.OriginalName, N'[', N''), N']', N'') IN (N'fact_daily_member_count_detail', N'Layercake.fact_daily_member_count_detail')
      AND OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake';

    SELECT @carried = COUNT(*)
    FROM sys.columns AS c
    WHERE c.object_id IN (@det, @fact)
      AND c.name IN (N'payment_method_carried', N'payer_type_carried', N'concession_type_carried');
    EXEC tSQLt.AssertEquals 0, @carried, 'carried flag columns on detail or fact';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-010 enrolment Y6 and the Lapse of Y7 are counted in the cells of their 2025 attributes]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2025-01-10', 2025, 'Q2'), ('2025-06-01', 2025, 'Q3');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2025-01-10', 2025, 'Q2'), (2, '2025-06-01', 2025, 'Q3');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y6', '2024-11-01', NULL, 2025, 'enrolment', 'UK', 1),
           (2, N'Y7', '2015-01-01', '2025-06-01', 2015, 'election', 'UK', 1),
           (3, N'Y7', '2025-06-01', NULL, 2025, 'lapse', 'UK', 2);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'Y6', 6, 1, NULL), (N'Y7', 7, 1, NULL);
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (701, N'LA:Y7:2025', 'Lapse', 'Standard', '2025-06-01', N'Y7', 0, 0, 0, 0, 7, 1, 0, 2025, 'Q3', 0, 0, 0, 0, 0, 0);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y6', 2025, 5, 0, 2, 0, 1, 0, 1),
           (N'Y7', 2025, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('2025-01-10', 'UK', 6, 1, 'enrolment', 0, 5, 2, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-06-01', 'UK', 6, 1, 'enrolment', 0, 5, 2, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 7, 1, 'election', 1, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-06-01', 'UK', 7, 1, 'lapse', 0, 2, 1, 1, 0, 0, 0, 0, 0, 0, 1))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'silv_daily_count_detail';

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpectedFact
    FROM (VALUES (1, 6, 1, 1, 0, 5, 2, 1, 1, 0, 0, 0, 0, 0, 0),
                 (2, 6, 1, 1, 0, 5, 2, 1, 1, 0, 0, 0, 0, 0, 0),
                 (1, 7, 1, 2, 1, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 (2, 7, 1, 0, 0, 2, 1, 1, 0, 0, 0, 0, 0, 0, 1))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    SELECT TOP (0) * INTO #ActualFact FROM #ExpectedFact;
    INSERT INTO #ActualFact
    EXEC (N'SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
           FROM Layercake.fact_daily_member_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#ExpectedFact', '#ActualFact', 'fact_daily_member_count_detail';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-011 Y8 Join on 2024-06-01 is counted under its 2024 Card attributes while the event carries Direct Debit]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID();

    EXEC tSQLt.FakeTable 'Layercake.silv_event_amount';
    EXEC tSQLt.FakeTable 'Layercake.fact_membership_events';

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES ('2024-06-01', 2024, 'Q3');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter) VALUES (1, '2024-06-01', 2024, 'Q3');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y8', '2024-06-01', NULL, 2024, 'enrolment', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date) VALUES (N'Y8', 8, 1, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'Y8', 2025, '2024-10-15', '2024-10-15', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (801, N'JR:Y8', 'Join', 'Direct Entry', '2024-06-01', N'Y8', 1, 0, 0, 0, 8, 1, 1, 2024, 'Q3', 0, 0, 0, 0, 0, 0);
    INSERT INTO Layercake.fact_membership_events
        (event_id, event_type, event_subtype, event_date, date_id, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (801, 'Join', 'Direct Entry', '2024-06-01', 1, N'Y8', 1, 0, 0, 0, 8, 1, 1, 2024, 'Q3', 0, 0, 0, 0, 0, 0);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y8', 2024, 2, 0, 1, 0, 1, 0, 1),
           (N'Y8', 2025, 1, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_membership_events_segments @run_id = @r1;
    EXEC Layercake.usp_load_fact_membership_events_segments @run_id = @r1;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('2024-06-01', 'UK', 8, 1, 'enrolment', 0, 2, 1, 1, 1, 0, 1, 1, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'silv_daily_count_detail';

    SELECT event_id, payment_method_id, payer_type_id, concession_type_id
    INTO #ActualEvent
    FROM Layercake.fact_membership_events;

    SELECT v.event_id, v.payment_method_id, v.payer_type_id, v.concession_type_id
    INTO #ExpectedEvent
    FROM (VALUES (801, 1, 1, 1)) AS v(event_id, payment_method_id, payer_type_id, concession_type_id);

    EXEC tSQLt.AssertEqualsTable '#ExpectedEvent', '#ActualEvent', 'fact_membership_events';

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.ActiveMembers, v.PaidMembersEvent, v.JoinEvents
    INTO #ExpectedFact
    FROM (VALUES (1, 8, 1, 1, 0, 2, 1, 1, 1, 1, 1))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              ActiveMembers, PaidMembersEvent, JoinEvents);

    SELECT TOP (0) * INTO #ActualFact FROM #ExpectedFact;
    INSERT INTO #ActualFact
    EXEC (N'SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  ActiveMembers, PaidMembersEvent, JoinEvents
           FROM Layercake.fact_daily_member_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#ExpectedFact', '#ActualFact', 'fact_daily_member_count_detail';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-012 totals at the old grain and silv_daily_count are unchanged by the segment split]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @cells int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES ('2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter) VALUES (1, '2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'R1', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (2, N'R2', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (3, N'R3', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (4, N'R4', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'R1', 1, 1, NULL), (N'R2', 1, 1, NULL), (N'R3', 1, 1, NULL), (N'R4', 1, 1, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'R2', 2025, '2024-10-20', '2024-10-20', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (201, N'RN:R2:2025', 'Renewal', 'Standard', '2024-10-20', N'R2', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'R1', 2025, 1, 0, 1, 0, 1, 0, 1),
           (N'R2', 2025, 2, 0, 1, 0, 1, 0, 1),
           (N'R3', 2025, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpectedSplit
    FROM (VALUES ('2025-01-10', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 2, 1, 1, 2, 1, 1, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #ActualSplit FROM #ExpectedSplit;
    INSERT INTO #ActualSplit
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#ExpectedSplit', '#ActualSplit', 'detail at the segment grain';

    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           SUM(active_count) AS active_count, SUM(paid_count) AS paid_count, SUM(paid_count_event) AS paid_count_event,
           SUM(event_join_count) AS event_join_count, SUM(event_renewal_count) AS event_renewal_count,
           SUM(event_readmission_count) AS event_readmission_count, SUM(event_lapse_count) AS event_lapse_count
    INTO #ActualOld
    FROM Layercake.silv_daily_count_detail
    GROUP BY [date], region, country_id, gender_id, grade, membership_status_id;

    SELECT CAST(v.[date] AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpectedOld
    FROM (VALUES ('2025-01-10', 'UK', 1, 1, 'election', 1, 4, 1, 1, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#ExpectedOld', '#ActualOld', 'detail summed to the old grain';

    SELECT [date], campaign_year, campaign_quarter, region, grade,
           active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #ActualDay
    FROM Layercake.silv_daily_count;

    SELECT CAST(v.[date] AS date) AS [date], v.campaign_year, CAST(v.campaign_quarter AS char(2)) AS campaign_quarter, v.region, v.grade,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpectedDay
    FROM (VALUES ('2025-01-10', 2025, 'Q2', 'UK', 'election', 4, 1, 1, 0, 0, 0, 0))
         AS v([date], campaign_year, campaign_quarter, region, grade,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    EXEC tSQLt.AssertEqualsTable '#ExpectedDay', '#ActualDay', 'silv_daily_count';

    SELECT @cells = SUM(contact_count) FROM Layercake.etl_daily_count_cell_contacts;
    EXEC tSQLt.AssertEquals 4, @cells, 'contacts counted in cells on 2025-01-10';

    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           SUM(ActiveMembers) AS ActiveMembers, SUM(PaidMembers) AS PaidMembers, SUM(PaidMembersEvent) AS PaidMembersEvent,
           SUM(JoinEvents) AS JoinEvents, SUM(RenewalEvents) AS RenewalEvents, SUM(ReadmissionEvents) AS ReadmissionEvents, SUM(LapseEvents) AS LapseEvents
    INTO #ActualFactOld
    FROM Layercake.fact_daily_member_count_detail
    GROUP BY date_id, country_id, gender_id, membership_grade_id, membership_status_id;

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpectedFactOld
    FROM (VALUES (1, 1, 1, 2, 1, 4, 1, 1, 0, 0, 0, 0))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    EXEC tSQLt.AssertEqualsTable '#ExpectedFactOld', '#ActualFactOld', 'fact summed to the old grain';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-013 a new concession type alone recomputes 0 contacts on the normal path and changes nothing]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @cr int, @fp int, @adj int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2024-09-30', 2024, 'Q4'), ('2024-10-01', 2025, 'Q1');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2024-09-30', 2024, 'Q4'), (2, '2024-10-01', 2025, 'Q1');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y1', '2023-10-01', NULL, 2024, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date) VALUES (N'Y1', 1, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y1', 2024, 1, 0, 1, 0, 1, 0, 1), (N'Y1', 2025, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    SELECT * INTO #DetailBefore FROM Layercake.silv_daily_count_detail;
    SELECT * INTO #DailyBefore FROM Layercake.silv_daily_count;
    SELECT * INTO #FactBefore FROM Layercake.fact_daily_member_count_detail;

    INSERT INTO Layercake.silv_ref_concession_type (id, concession_type_bk, concession_type_name, item_code, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (7, '7A1D2C3B-0000-4000-8000-000000000007', N'Bereavement', N'CONBEREAVE', 0, 0, NULL, SYSDATETIME(), SYSDATETIME());
    INSERT INTO Layercake.dim_concession_type (id, concession_type_name, is_full_concession, is_perpetual, load_id, created_at, updated_at)
    VALUES (7, N'Bereavement', 0, 0, NULL, SYSDATETIME(), SYSDATETIME());

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;

    SELECT @cr = p.rows_affected FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.step_name = 'silv_daily_count' AND p.substep = N'contacts_recomputed';
    SELECT @fp = p.rows_affected FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.step_name = 'silv_daily_count' AND p.substep = N'full_recompute_path';
    SELECT @adj = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r2;

    EXEC tSQLt.AssertEquals 0, @cr, 'contacts_recomputed';
    EXEC tSQLt.AssertEquals 0, @fp, 'full_recompute_path';
    EXEC tSQLt.AssertEquals 0, @adj, 'adjustment rows of run 2';
    EXEC tSQLt.AssertEqualsTable '#DetailBefore', 'Layercake.silv_daily_count_detail', 'silv_daily_count_detail';
    EXEC tSQLt.AssertEqualsTable '#DailyBefore', 'Layercake.silv_daily_count', 'silv_daily_count';
    EXEC tSQLt.AssertEqualsTable '#FactBefore', 'Layercake.fact_daily_member_count_detail', 'fact_daily_member_count_detail';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-014 Y1 2025 payment method change alone moves its days from 1 October and matches a full recompute]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @cr int, @fp int, @adj3 int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2024-09-30', 2024, 'Q4'), ('2024-10-01', 2025, 'Q1'), ('2025-03-31', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2024-09-30', 2024, 'Q4'), (2, '2024-10-01', 2025, 'Q1'), (3, '2025-03-31', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y1', '2023-10-01', NULL, 2024, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date) VALUES (N'Y1', 1, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y1', 2024, 1, 0, 1, 0, 1, 0, 1), (N'Y1', 2025, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    SELECT * INTO #DailyAfterRun1 FROM Layercake.silv_daily_count;

    UPDATE Layercake.silv_member_year_attributes SET payment_method_id = 1 WHERE contact_no = N'Y1' AND campaign_year = 2025;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT @cr = p.rows_affected FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.step_name = 'silv_daily_count' AND p.substep = N'contacts_recomputed';
    SELECT @fp = p.rows_affected FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.step_name = 'silv_daily_count' AND p.substep = N'full_recompute_path';
    EXEC tSQLt.AssertEquals 1, @cr, 'contacts_recomputed';
    EXEC tSQLt.AssertEquals 0, @fp, 'full_recompute_path';

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('2024-09-30', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2024-10-01', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-03-31', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'detail after run 2';

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count_change, v.paid_count_change, v.paid_count_event_change, v.event_join_count_change,
           v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpectedAdj
    FROM (VALUES ('2024-10-01', 'UK', 1, 1, 'election', 1, 2, 1, 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2024-10-01', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-03-31', 'UK', 1, 1, 'election', 1, 2, 1, 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-03-31', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
              event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);

    SELECT TOP (0) * INTO #ActualAdj FROM #ExpectedAdj;
    INSERT INTO #ActualAdj
    EXEC sp_executesql
        N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
                 event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
          FROM Layercake.silv_daily_count_adjustment
          WHERE run_id = @run;',
        N'@run uniqueidentifier', @run = @r2;

    EXEC tSQLt.AssertEqualsTable '#ExpectedAdj', '#ActualAdj', 'adjustment rows of run 2';
    EXEC tSQLt.AssertEqualsTable '#DailyAfterRun1', 'Layercake.silv_daily_count', 'silv_daily_count unchanged by run 2';

    SELECT * INTO #DetailAfterRun2 FROM Layercake.silv_daily_count_detail;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    SELECT @adj3 = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;

    EXEC tSQLt.AssertEquals 0, @adj3, 'adjustment rows of the full recompute';
    EXEC tSQLt.AssertEqualsTable '#DetailAfterRun2', 'Layercake.silv_daily_count_detail', 'detail after the full recompute';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-015 concession and payer type changes and a removed attributes row each make a changed contact]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(), @cr int, @fp int, @adj3 int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2023-09-30', 2023, 'Q4'), ('2023-10-01', 2024, 'Q1'), ('2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2023-09-30', 2023, 'Q4'), (2, '2023-10-01', 2024, 'Q1'), (3, '2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y9', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (2, N'Y10', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (3, N'Y11', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'Y9', 9, 1, NULL), (N'Y10', 10, 1, NULL), (N'Y11', 11, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y9', 2025, 2, 0, 1, 0, 1, 0, 1),
           (N'Y10', 2023, 2, 0, 1, 0, 1, 0, 1),
           (N'Y10', 2024, 2, 0, 1, 0, 1, 0, 1),
           (N'Y10', 2025, 2, 0, 1, 0, 1, 0, 1),
           (N'Y11', 2024, 5, 0, 1, 0, 1, 0, 1),
           (N'Y11', 2025, 5, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    UPDATE Layercake.silv_member_year_attributes SET concession_type_id = 6 WHERE contact_no = N'Y10' AND campaign_year = 2023;
    UPDATE Layercake.silv_member_year_attributes SET payer_type_id = 2 WHERE contact_no = N'Y11' AND campaign_year = 2025;
    DELETE FROM Layercake.silv_member_year_attributes WHERE contact_no = N'Y9';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT @cr = p.rows_affected FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.step_name = 'silv_daily_count' AND p.substep = N'contacts_recomputed';
    SELECT @fp = p.rows_affected FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.step_name = 'silv_daily_count' AND p.substep = N'full_recompute_path';
    EXEC tSQLt.AssertEquals 3, @cr, 'contacts_recomputed';
    EXEC tSQLt.AssertEquals 0, @fp, 'full_recompute_path';

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('2023-09-30', 'UK', 9, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2023-10-01', 'UK', 9, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 9, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2023-09-30', 'UK', 10, 1, 'election', 1, 2, 1, 6, 1, 0, 0, 0, 0, 0, 0),
                 ('2023-10-01', 'UK', 10, 1, 'election', 1, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 10, 1, 'election', 1, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2023-09-30', 'UK', 11, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2023-10-01', 'UK', 11, 1, 'election', 1, 5, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 11, 1, 'election', 1, 5, 2, 1, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'detail after run 2';

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count_change, v.paid_count_change, v.paid_count_event_change, v.event_join_count_change,
           v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpectedAdj
    FROM (VALUES ('2023-09-30', 'UK', 10, 1, 'election', 1, 2, 1, 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2023-09-30', 'UK', 10, 1, 'election', 1, 2, 1, 6, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 11, 1, 'election', 1, 5, 1, 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 11, 1, 'election', 1, 5, 2, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 9, 1, 'election', 1, 2, 1, 1, -1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 9, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
              event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);

    SELECT TOP (0) * INTO #ActualAdj FROM #ExpectedAdj;
    INSERT INTO #ActualAdj
    EXEC sp_executesql
        N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
                 event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
          FROM Layercake.silv_daily_count_adjustment
          WHERE run_id = @run;',
        N'@run uniqueidentifier', @run = @r2;

    EXEC tSQLt.AssertEqualsTable '#ExpectedAdj', '#ActualAdj', 'adjustment rows of run 2';

    SELECT * INTO #DetailAfterRun2 FROM Layercake.silv_daily_count_detail;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    SELECT @adj3 = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;

    EXEC tSQLt.AssertEquals 0, @adj3, 'adjustment rows of the full recompute';
    EXEC tSQLt.AssertEqualsTable '#DetailAfterRun2', 'Layercake.silv_daily_count_detail', 'detail after the full recompute';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-016 gold carries resolvable dim keys for real 0 and -2 ids and matches silver cell for cell]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @nulls int, @orphans int, @status varchar(10);

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2021-05-01', 2021, 'Q3'), ('2024-09-30', 2024, 'Q4'), ('2024-10-01', 2025, 'Q1');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2021-05-01', 2021, 'Q3'), (2, '2024-09-30', 2024, 'Q4'), (3, '2024-10-01', 2025, 'Q1');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y1', '2023-10-01', NULL, 2024, 'election', 'UK', 1),
           (2, N'Y2', '2024-10-01', NULL, 2025, 'election', 'UK', 1),
           (3, N'Y3', '2020-01-01', NULL, 2020, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'Y1', 1, 1, NULL), (N'Y2', 2, 1, NULL), (N'Y3', 3, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y1', 2024, 1, 0, 1, 0, 1, 0, 1),
           (N'Y1', 2025, 2, 0, 1, 0, 1, 0, 1),
           (N'Y3', 2021, -2, 0, -2, 0, -2, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    SELECT @status = l.status FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @r1 AND l.layer = 'gold' AND l.step_name = 'fact_daily_member_count_detail';
    EXEC tSQLt.AssertEqualsString 'Success', @status, 'gold load status (row-count check passed)';

    EXEC sp_executesql
        N'SELECT @n = COUNT(*) FROM Layercake.fact_daily_member_count_detail AS f
          WHERE f.payment_method_id IS NULL OR f.payer_type_id IS NULL OR f.concession_type_id IS NULL;',
        N'@n int OUTPUT', @n = @nulls OUTPUT;
    EXEC tSQLt.AssertEquals 0, @nulls, 'null segment ids';

    EXEC sp_executesql
        N'SELECT @n = COUNT(*) FROM Layercake.fact_daily_member_count_detail AS f
          WHERE NOT EXISTS (SELECT 1 FROM Layercake.dim_payment_method AS d WHERE d.id = f.payment_method_id)
             OR NOT EXISTS (SELECT 1 FROM Layercake.dim_payer_type AS d WHERE d.id = f.payer_type_id)
             OR NOT EXISTS (SELECT 1 FROM Layercake.dim_concession_type AS d WHERE d.id = f.concession_type_id);',
        N'@n int OUTPUT', @n = @orphans OUTPUT;
    EXEC tSQLt.AssertEquals 0, @orphans, 'orphan segment keys';

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpectedFact
    FROM (VALUES (1, 3, 1, 2, 1, -2, -2, -2, 1, 0, 0, 0, 0, 0, 0),
                 (2, 1, 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 (2, 3, 1, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 (3, 1, 1, 2, 1, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 (3, 2, 1, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 (3, 3, 1, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    SELECT TOP (0) * INTO #ActualFact FROM #ExpectedFact;
    INSERT INTO #ActualFact
    EXEC (N'SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
           FROM Layercake.fact_daily_member_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#ExpectedFact', '#ActualFact', 'fact_daily_member_count_detail';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-017 gold syncs cell by cell on the eight-column key keeping ids and deleting a hand row]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(),
            @ins int, @upd int, @del int, @status varchar(10);

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2024-09-30', 2024, 'Q4'), ('2024-10-01', 2025, 'Q1'), ('2025-03-31', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2024-09-30', 2024, 'Q4'), (2, '2024-10-01', 2025, 'Q1'), (3, '2025-03-31', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y1', '2023-10-01', NULL, 2024, 'election', 'UK', 1),
           (2, N'Z1', '2023-10-01', NULL, 2024, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'Y1', 1, 1, NULL), (N'Z1', 1, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y1', 2024, 1, 0, 1, 0, 1, 0, 1),
           (N'Y1', 2025, 2, 0, 1, 0, 1, 0, 1),
           (N'Z1', 2025, 1, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    SELECT * INTO #FactBefore FROM Layercake.fact_daily_member_count_detail;

    UPDATE Layercake.silv_member_year_attributes SET payment_method_id = 1 WHERE contact_no = N'Y1' AND campaign_year = 2025;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    EXEC (N'INSERT INTO Layercake.fact_daily_member_count_detail
              (date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
               ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
            VALUES (1, 1, 1, 2, 1, 3, 1, 1, 1, 0, 0, 0, 0, 0, 0);');

    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;

    SELECT @ins = l.rows_inserted, @upd = l.rows_updated, @del = l.rows_deleted, @status = l.status
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @r2 AND l.layer = 'gold' AND l.step_name = 'fact_daily_member_count_detail';

    EXEC tSQLt.AssertEqualsString 'Success', @status, 'gold load status';
    EXEC tSQLt.AssertEquals 0, @ins, 'rows_inserted';
    EXEC tSQLt.AssertEquals 2, @upd, 'rows_updated';
    EXEC tSQLt.AssertEquals 3, @del, 'rows_deleted';

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents, v.kept_id
    INTO #Expected
    FROM (VALUES (1, 1, 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1),
                 (1, 1, 1, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1),
                 (2, 1, 1, 2, 1, 1, 1, 1, 2, 0, 0, 0, 0, 0, 0, 1),
                 (3, 1, 1, 2, 1, 1, 1, 1, 2, 0, 0, 0, 0, 0, 0, 1))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents, kept_id);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT f.date_id, f.country_id, f.gender_id, f.membership_grade_id, f.membership_status_id, f.payment_method_id, f.payer_type_id, f.concession_type_id,
                  f.ActiveMembers, f.PaidMembers, f.PaidMembersEvent, f.JoinEvents, f.RenewalEvents, f.ReadmissionEvents, f.LapseEvents,
                  CASE WHEN b.id = f.id THEN 1 ELSE 0 END
           FROM Layercake.fact_daily_member_count_detail AS f
           LEFT JOIN #FactBefore AS b
               ON  b.date_id = f.date_id AND b.country_id = f.country_id AND b.gender_id = f.gender_id
               AND b.membership_grade_id = f.membership_grade_id AND b.membership_status_id = f.membership_status_id
               AND b.payment_method_id = f.payment_method_id AND b.payer_type_id = f.payer_type_id AND b.concession_type_id = f.concession_type_id;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'fact after the second gold load';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-018 a rerun on unchanged silver logs 0 0 0 and leaves every fact row and id unchanged]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @ins int, @upd int, @del int, @cr int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2024-09-30', 2024, 'Q4'), ('2024-10-01', 2025, 'Q1');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2024-09-30', 2024, 'Q4'), (2, '2024-10-01', 2025, 'Q1');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y1', '2023-10-01', NULL, 2024, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date) VALUES (N'Y1', 1, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y1', 2024, 1, 0, 1, 0, 1, 0, 1), (N'Y1', 2025, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;
    SELECT * INTO #FactBefore FROM Layercake.fact_daily_member_count_detail;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;

    SELECT @cr = p.rows_affected FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.step_name = 'silv_daily_count' AND p.substep = N'contacts_recomputed';
    SELECT @ins = l.rows_inserted, @upd = l.rows_updated, @del = l.rows_deleted
    FROM Layercake.etl_run_log AS l
    WHERE l.run_id = @r2 AND l.layer = 'gold' AND l.step_name = 'fact_daily_member_count_detail';

    EXEC tSQLt.AssertEquals 0, @cr, 'contacts_recomputed';
    EXEC tSQLt.AssertEquals 0, @ins, 'rows_inserted';
    EXEC tSQLt.AssertEquals 0, @upd, 'rows_updated';
    EXEC tSQLt.AssertEquals 0, @del, 'rows_deleted';
    EXEC tSQLt.AssertEqualsTable '#FactBefore', 'Layercake.fact_daily_member_count_detail', 'fact including id';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-019 the first run after deployment restates the -2 cells at the segment grain writing no adjustment]
AS
BEGIN
    DECLARE @r0 uniqueidentifier = NEWID(), @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(),
            @fp int, @marker int, @adj3 int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2025-01-09', 2025, 'Q2'), ('2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2025-01-09', 2025, 'Q2'), (2, '2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'R1', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (2, N'R2', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (3, N'R3', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'R1', 1, 1, NULL), (N'R2', 1, 1, NULL), (N'R3', 1, 1, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'R2', 2025, '2024-10-20', '2024-10-20', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (201, N'RN:R2:2025', 'Renewal', 'Standard', '2024-10-20', N'R2', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'R1', 2025, 1, 0, 1, 0, 1, 0, 1),
           (N'R2', 2025, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r1;

    -- The state the migration leaves: stored figures at the old grain with -2, snapshot emptied, marker written.
    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           SUM(active_count) AS active_count, SUM(paid_count) AS paid_count, SUM(paid_count_event) AS paid_count_event,
           SUM(event_join_count) AS event_join_count, SUM(event_renewal_count) AS event_renewal_count,
           SUM(event_readmission_count) AS event_readmission_count, SUM(event_lapse_count) AS event_lapse_count
    INTO #OldDetail
    FROM Layercake.silv_daily_count_detail
    GROUP BY [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id;

    SELECT [date], region, country_id, gender_id, grade, membership_status_id, SUM(contact_count) AS contact_count
    INTO #OldCells
    FROM Layercake.etl_daily_count_cell_contacts
    GROUP BY [date], region, country_id, gender_id, grade, membership_status_id;

    SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id,
           SUM(ActiveMembers) AS ActiveMembers, SUM(PaidMembers) AS PaidMembers, SUM(PaidMembersEvent) AS PaidMembersEvent,
           SUM(JoinEvents) AS JoinEvents, SUM(RenewalEvents) AS RenewalEvents, SUM(ReadmissionEvents) AS ReadmissionEvents, SUM(LapseEvents) AS LapseEvents
    INTO #OldFact
    FROM Layercake.fact_daily_member_count_detail
    GROUP BY date_id, country_id, gender_id, membership_grade_id, membership_status_id;

    DELETE FROM Layercake.silv_daily_count_detail;
    DELETE FROM Layercake.etl_daily_count_cell_contacts;
    DELETE FROM Layercake.fact_daily_member_count_detail;

    EXEC sp_executesql
        N'INSERT INTO Layercake.silv_daily_count_detail
              ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
               payment_method_id, payer_type_id, concession_type_id,
               active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
          SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id, -2, -2, -2,
                 active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
          FROM #OldDetail;
          INSERT INTO Layercake.etl_daily_count_cell_contacts
              ([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id, contact_count, run_id, updated_at)
          SELECT [date], region, country_id, gender_id, grade, membership_status_id, -2, -2, -2, contact_count, @run, SYSDATETIME()
          FROM #OldCells;
          INSERT INTO Layercake.fact_daily_member_count_detail
              (date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
               ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents)
          SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, -2, -2, -2,
                 ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
          FROM #OldFact;
          INSERT INTO Layercake.silv_daily_count_adjustment
              (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
               payment_method_id, payer_type_id, concession_type_id,
               active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
               event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
          VALUES (@pre, 7, ''2025-01-10T07:00:00'', ''2025-01-10'', ''UK'', 1, 1, ''election'', 1, -2, -2, -2, 1, 0, 0, 0, 0, 0, 0);',
        N'@run uniqueidentifier, @pre uniqueidentifier', @run = @r1, @pre = @r0;

    DELETE FROM Layercake.etl_daily_count_applied_contact;
    DELETE FROM Layercake.etl_daily_count_applied_state_range;
    DELETE FROM Layercake.etl_daily_count_applied_payment;
    DELETE FROM Layercake.etl_daily_count_applied_event;
    DELETE FROM Layercake.etl_daily_count_applied_attribute;
    INSERT INTO Layercake.etl_daily_count_input_basis (input_name, input_key, input_fingerprint, earliest_affected_date, run_id, updated_at)
    VALUES ('detail_grain_restatement', N'', 0x00, '2020-10-01', @r1, SYSDATETIME());

    SELECT * INTO #DailyBefore FROM Layercake.silv_daily_count;

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;
    EXEC Layercake.usp_load_fact_daily_member_count_detail @run_id = @r2;

    SELECT @fp = p.rows_affected FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.step_name = 'silv_daily_count' AND p.substep = N'full_recompute_path';
    EXEC tSQLt.AssertEquals 1, @fp, 'full_recompute_path';

    SELECT @marker = COUNT(*) FROM Layercake.etl_daily_count_input_basis WHERE input_name = 'detail_grain_restatement';
    EXEC tSQLt.AssertEquals 0, @marker, 'restatement marker rows';

    SELECT @r0 AS run_id, CAST(7 AS bigint) AS load_id, CAST('2025-01-10T07:00:00' AS datetime2(3)) AS written_at, CAST('2025-01-10' AS date) AS [date],
           CAST('UK' AS varchar(12)) AS region, 1 AS country_id, 1 AS gender_id, CAST('election' AS varchar(12)) AS grade, 1 AS membership_status_id,
           -2 AS payment_method_id, -2 AS payer_type_id, -2 AS concession_type_id,
           1 AS active_count_change, 0 AS paid_count_change, 0 AS paid_count_event_change, 0 AS event_join_count_change,
           0 AS event_renewal_count_change, 0 AS event_readmission_count_change, 0 AS event_lapse_count_change
    INTO #ExpectedAdj;

    SELECT TOP (0) * INTO #ActualAdj FROM #ExpectedAdj;
    INSERT INTO #ActualAdj
    EXEC (N'SELECT run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
                  payment_method_id, payer_type_id, concession_type_id,
                  active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
                  event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
           FROM Layercake.silv_daily_count_adjustment;');

    EXEC tSQLt.AssertEqualsTable '#ExpectedAdj', '#ActualAdj', 'adjustment history: only the pre-deployment row, unchanged';

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('2025-01-09', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 1, 1, 'election', 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 1, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'detail restated at the segment grain';
    EXEC tSQLt.AssertEqualsTable '#DailyBefore', 'Layercake.silv_daily_count', 'silv_daily_count unchanged';

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id, v.contact_count
    INTO #ExpectedCells
    FROM (VALUES ('2025-01-09', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1),
                 ('2025-01-09', 'UK', 1, 1, 'election', 1, 2, 1, 1, 1),
                 ('2025-01-09', 'UK', 1, 1, 'election', 1, 0, 0, 0, 1),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 2, 1, 1, 1),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 0, 0, 0, 1))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id, contact_count);

    SELECT TOP (0) * INTO #ActualCells FROM #ExpectedCells;
    INSERT INTO #ActualCells
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id, contact_count
           FROM Layercake.etl_daily_count_cell_contacts;');

    EXEC tSQLt.AssertEqualsTable '#ExpectedCells', '#ActualCells', 'cell counts restated';

    SELECT v.date_id, v.country_id, v.gender_id, v.membership_grade_id, v.membership_status_id, v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.ActiveMembers, v.PaidMembers, v.PaidMembersEvent, v.JoinEvents, v.RenewalEvents, v.ReadmissionEvents, v.LapseEvents
    INTO #ExpectedFact
    FROM (VALUES (1, 1, 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 (1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0),
                 (1, 1, 1, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 (2, 1, 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 (2, 1, 1, 2, 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0),
                 (2, 1, 1, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0))
         AS v(date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents);

    SELECT TOP (0) * INTO #ActualFact FROM #ExpectedFact;
    INSERT INTO #ActualFact
    EXEC (N'SELECT date_id, country_id, gender_id, membership_grade_id, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  ActiveMembers, PaidMembers, PaidMembersEvent, JoinEvents, RenewalEvents, ReadmissionEvents, LapseEvents
           FROM Layercake.fact_daily_member_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#ExpectedFact', '#ActualFact', 'fact restated at the eight-column grain';

    SELECT * INTO #DetailAfterRun2 FROM Layercake.silv_daily_count_detail;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3, @FullRebuild = 1;
    SELECT @adj3 = COUNT(*) FROM Layercake.silv_daily_count_adjustment WHERE run_id = @r3;

    EXEC tSQLt.AssertEquals 0, @adj3, 'adjustment rows of the full recompute';
    EXEC tSQLt.AssertEqualsTable '#DetailAfterRun2', 'Layercake.silv_daily_count_detail', 'detail equals the full recompute';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-020 a real change found by the restating run is recorded at the old grain with -2]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @marker int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2025-01-09', 2025, 'Q2'), ('2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2025-01-09', 2025, 'Q2'), (2, '2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'R1', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (2, N'R2', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (3, N'R3', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'R1', 1, 1, NULL), (N'R2', 1, 1, NULL), (N'R3', 1, 1, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'R2', 2025, '2024-10-20', '2024-10-20', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (201, N'RN:R2:2025', 'Renewal', 'Standard', '2024-10-20', N'R2', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'R1', 2025, 1, 0, 1, 0, 1, 0, 1),
           (N'R2', 2025, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    -- The state the migration leaves.
    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           SUM(active_count) AS active_count, SUM(paid_count) AS paid_count, SUM(paid_count_event) AS paid_count_event,
           SUM(event_join_count) AS event_join_count, SUM(event_renewal_count) AS event_renewal_count,
           SUM(event_readmission_count) AS event_readmission_count, SUM(event_lapse_count) AS event_lapse_count
    INTO #OldDetail
    FROM Layercake.silv_daily_count_detail
    GROUP BY [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id;

    SELECT [date], region, country_id, gender_id, grade, membership_status_id, SUM(contact_count) AS contact_count
    INTO #OldCells
    FROM Layercake.etl_daily_count_cell_contacts
    GROUP BY [date], region, country_id, gender_id, grade, membership_status_id;

    DELETE FROM Layercake.silv_daily_count_detail;
    DELETE FROM Layercake.etl_daily_count_cell_contacts;

    EXEC sp_executesql
        N'INSERT INTO Layercake.silv_daily_count_detail
              ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
               payment_method_id, payer_type_id, concession_type_id,
               active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
          SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id, -2, -2, -2,
                 active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
          FROM #OldDetail;
          INSERT INTO Layercake.etl_daily_count_cell_contacts
              ([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id, contact_count, run_id, updated_at)
          SELECT [date], region, country_id, gender_id, grade, membership_status_id, -2, -2, -2, contact_count, @run, SYSDATETIME()
          FROM #OldCells;',
        N'@run uniqueidentifier', @run = @r1;

    DELETE FROM Layercake.etl_daily_count_applied_contact;
    DELETE FROM Layercake.etl_daily_count_applied_state_range;
    DELETE FROM Layercake.etl_daily_count_applied_payment;
    DELETE FROM Layercake.etl_daily_count_applied_event;
    DELETE FROM Layercake.etl_daily_count_applied_attribute;
    INSERT INTO Layercake.etl_daily_count_input_basis (input_name, input_key, input_fingerprint, earliest_affected_date, run_id, updated_at)
    VALUES ('detail_grain_restatement', N'', 0x00, '2020-10-01', @r1, SYSDATETIME());

    -- The day's real source change: a Renewal for R3 on 2025-01-10.
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (301, N'RN:R3:2025', 'Renewal', 'Standard', '2025-01-10', N'R3', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count_change, v.paid_count_change, v.paid_count_event_change, v.event_join_count_change,
           v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpectedAdj
    FROM (VALUES ('2025-01-10', 'UK', 1, 1, 'election', 1, -2, -2, -2, 0, 0, 1, 0, 1, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
              event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);

    SELECT TOP (0) * INTO #ActualAdj FROM #ExpectedAdj;
    INSERT INTO #ActualAdj
    EXEC sp_executesql
        N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
                 event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
          FROM Layercake.silv_daily_count_adjustment
          WHERE run_id = @run;',
        N'@run uniqueidentifier', @run = @r2;

    EXEC tSQLt.AssertEqualsTable '#ExpectedAdj', '#ActualAdj', 'adjustment rows of the restating run';

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('2025-01-09', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 1, 1, 'election', 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 1, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'detail after the restating run';

    SELECT @marker = COUNT(*) FROM Layercake.etl_daily_count_input_basis WHERE input_name = 'detail_grain_restatement';
    EXEC tSQLt.AssertEquals 0, @marker, 'restatement marker rows';
END;
GO

--[@tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE test_MOD028.[test TC-028-021 a restating run that fails part way keeps the marker and the next run finishes with no cleanup]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @r3 uniqueidentifier = NEWID(),
            @marker int, @status2 varchar(10), @status3 varchar(10);

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2025-01-09', 2025, 'Q2'), ('2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2025-01-09', 2025, 'Q2'), (2, '2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'R1', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (2, N'R2', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (3, N'R3', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'R1', 1, 1, NULL), (N'R2', 1, 1, NULL), (N'R3', 1, 1, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'R2', 2025, '2024-10-20', '2024-10-20', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (201, N'RN:R2:2025', 'Renewal', 'Standard', '2024-10-20', N'R2', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'R1', 2025, 1, 0, 1, 0, 1, 0, 1),
           (N'R2', 2025, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    -- The state the migration leaves.
    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           SUM(active_count) AS active_count, SUM(paid_count) AS paid_count, SUM(paid_count_event) AS paid_count_event,
           SUM(event_join_count) AS event_join_count, SUM(event_renewal_count) AS event_renewal_count,
           SUM(event_readmission_count) AS event_readmission_count, SUM(event_lapse_count) AS event_lapse_count
    INTO #OldDetail
    FROM Layercake.silv_daily_count_detail
    GROUP BY [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id;

    SELECT [date], region, country_id, gender_id, grade, membership_status_id, SUM(contact_count) AS contact_count
    INTO #OldCells
    FROM Layercake.etl_daily_count_cell_contacts
    GROUP BY [date], region, country_id, gender_id, grade, membership_status_id;

    DELETE FROM Layercake.silv_daily_count_detail;
    DELETE FROM Layercake.etl_daily_count_cell_contacts;

    EXEC sp_executesql
        N'INSERT INTO Layercake.silv_daily_count_detail
              ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
               payment_method_id, payer_type_id, concession_type_id,
               active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
          SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id, -2, -2, -2,
                 active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
          FROM #OldDetail;
          INSERT INTO Layercake.etl_daily_count_cell_contacts
              ([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id, contact_count, run_id, updated_at)
          SELECT [date], region, country_id, gender_id, grade, membership_status_id, -2, -2, -2, contact_count, @run, SYSDATETIME()
          FROM #OldCells;',
        N'@run uniqueidentifier', @run = @r1;

    DELETE FROM Layercake.etl_daily_count_applied_contact;
    DELETE FROM Layercake.etl_daily_count_applied_state_range;
    DELETE FROM Layercake.etl_daily_count_applied_payment;
    DELETE FROM Layercake.etl_daily_count_applied_event;
    DELETE FROM Layercake.etl_daily_count_applied_attribute;
    INSERT INTO Layercake.etl_daily_count_input_basis (input_name, input_key, input_fingerprint, earliest_affected_date, run_id, updated_at)
    VALUES ('detail_grain_restatement', N'', 0x00, '2020-10-01', @r1, SYSDATETIME());

    -- New contact D6 from 2025-01-10 whose region is missing: the 2025-01-10 batch cannot be written.
    ALTER TABLE Layercake.silv_daily_count_detail ALTER COLUMN region varchar(12) NOT NULL;
    ALTER TABLE Layercake.etl_daily_count_cell_contacts ALTER COLUMN region varchar(12) NOT NULL;
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (10, N'D6', '2025-01-10', NULL, 2025, 'election', NULL, 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date) VALUES (N'D6', 7, 1, NULL);

    BEGIN TRY
        EXEC Layercake.usp_load_silv_daily_count @run_id = @r2, @DailyCountBatchDays = 1;
        EXEC tSQLt.Fail 'The restating run should fail on the missing region of D6.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515 THROW;
    END CATCH;

    SELECT @status2 = l.status FROM Layercake.etl_run_log AS l WHERE l.run_id = @r2 AND l.step_name = 'silv_daily_count';
    SELECT @marker = COUNT(*) FROM Layercake.etl_daily_count_input_basis WHERE input_name = 'detail_grain_restatement';
    EXEC tSQLt.AssertEqualsString 'Failed', @status2, 'status of the failed restating run';
    EXEC tSQLt.AssertEquals 1, @marker, 'marker kept after the failure';

    UPDATE Layercake.silv_member_state_ranges SET region = 'UK' WHERE contact_no = N'D6';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r3;

    SELECT @status3 = l.status FROM Layercake.etl_run_log AS l WHERE l.run_id = @r3 AND l.step_name = 'silv_daily_count';
    SELECT @marker = COUNT(*) FROM Layercake.etl_daily_count_input_basis WHERE input_name = 'detail_grain_restatement';
    EXEC tSQLt.AssertEqualsString 'Success', @status3, 'status of the next run';
    EXEC tSQLt.AssertEquals 0, @marker, 'marker removed by the completed run';

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count_change, v.paid_count_change, v.paid_count_event_change, v.event_join_count_change,
           v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpectedAdj
    FROM (VALUES ('2025-01-10', 'UK', 7, 1, 'election', 1, -2, -2, -2, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
              event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);

    SELECT TOP (0) * INTO #ActualAdj FROM #ExpectedAdj;
    INSERT INTO #ActualAdj
    EXEC sp_executesql
        N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 SUM(active_count_change), SUM(paid_count_change), SUM(paid_count_event_change), SUM(event_join_count_change),
                 SUM(event_renewal_count_change), SUM(event_readmission_count_change), SUM(event_lapse_count_change)
          FROM Layercake.silv_daily_count_adjustment
          WHERE run_id IN (@run2, @run3)
          GROUP BY [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id;',
        N'@run2 uniqueidentifier, @run3 uniqueidentifier', @run2 = @r2, @run3 = @r3;

    EXEC tSQLt.AssertEqualsTable '#ExpectedAdj', '#ActualAdj', 'adjustments of the failed and the completing run, summed per cell';

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('2025-01-09', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 1, 1, 'election', 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 1, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 7, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'detail after the completing run';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-022 figures as known at a time before deployment are unchanged by the restating run]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(),
            @t datetime2(3) = '2025-01-10T08:30:00';

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2025-01-09', 2025, 'Q2'), ('2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2025-01-09', 2025, 'Q2'), (2, '2025-01-10', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'R1', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (2, N'R2', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (3, N'R3', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'R1', 1, 1, NULL), (N'R2', 1, 1, NULL), (N'R3', 1, 1, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'R2', 2025, '2024-10-20', '2024-10-20', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (201, N'RN:R2:2025', 'Renewal', 'Standard', '2024-10-20', N'R2', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'R1', 2025, 1, 0, 1, 0, 1, 0, 1),
           (N'R2', 2025, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    -- The state the migration leaves, with two adjustment rows written before deployment.
    SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
           SUM(active_count) AS active_count, SUM(paid_count) AS paid_count, SUM(paid_count_event) AS paid_count_event,
           SUM(event_join_count) AS event_join_count, SUM(event_renewal_count) AS event_renewal_count,
           SUM(event_readmission_count) AS event_readmission_count, SUM(event_lapse_count) AS event_lapse_count
    INTO #OldDetail
    FROM Layercake.silv_daily_count_detail
    GROUP BY [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id;

    SELECT [date], region, country_id, gender_id, grade, membership_status_id, SUM(contact_count) AS contact_count
    INTO #OldCells
    FROM Layercake.etl_daily_count_cell_contacts
    GROUP BY [date], region, country_id, gender_id, grade, membership_status_id;

    DELETE FROM Layercake.silv_daily_count_detail;
    DELETE FROM Layercake.etl_daily_count_cell_contacts;

    EXEC sp_executesql
        N'INSERT INTO Layercake.silv_daily_count_detail
              ([date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id,
               payment_method_id, payer_type_id, concession_type_id,
               active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count)
          SELECT [date], campaign_year, campaign_quarter, region, country_id, gender_id, grade, membership_status_id, -2, -2, -2,
                 active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
          FROM #OldDetail;
          INSERT INTO Layercake.etl_daily_count_cell_contacts
              ([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id, contact_count, run_id, updated_at)
          SELECT [date], region, country_id, gender_id, grade, membership_status_id, -2, -2, -2, contact_count, @run, SYSDATETIME()
          FROM #OldCells;
          INSERT INTO Layercake.silv_daily_count_adjustment
              (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
               payment_method_id, payer_type_id, concession_type_id,
               active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
               event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
          VALUES (NEWID(), 7, ''2025-01-10T08:00:00'', ''2025-01-10'', ''UK'', 1, 1, ''election'', 1, -2, -2, -2, 1, 0, 0, 0, 0, 0, 0),
                 (NEWID(), 8, ''2025-01-10T09:00:00'', ''2025-01-09'', ''UK'', 1, 1, ''election'', 1, -2, -2, -2, 0, 1, 0, 0, 0, 0, 0);',
        N'@run uniqueidentifier', @run = @r1;

    DELETE FROM Layercake.etl_daily_count_applied_contact;
    DELETE FROM Layercake.etl_daily_count_applied_state_range;
    DELETE FROM Layercake.etl_daily_count_applied_payment;
    DELETE FROM Layercake.etl_daily_count_applied_event;
    DELETE FROM Layercake.etl_daily_count_applied_attribute;
    INSERT INTO Layercake.etl_daily_count_input_basis (input_name, input_key, input_fingerprint, earliest_affected_date, run_id, updated_at)
    VALUES ('detail_grain_restatement', N'', 0x00, '2020-10-01', @r1, SYSDATETIME());

    SELECT CAST(v.[date] AS date) AS [date], v.region, v.grade,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpectedDay
    FROM (VALUES ('2025-01-09', 'UK', 'election', 3, 0, 1, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 'election', 3, 1, 1, 0, 0, 0, 0))
         AS v([date], region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT CAST(v.[date] AS date) AS [date], v.region, v.country_id, v.gender_id, v.grade, v.membership_status_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpectedDetail
    FROM (VALUES ('2025-01-09', 'UK', 1, 1, 'election', 1, 3, 0, 1, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 3, 1, 1, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT [date], region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #DayBeforeRun
    FROM Layercake.fn_silv_daily_count_as_known_at('2020-10-01', '2025-01-10', @t);
    EXEC tSQLt.AssertEqualsTable '#ExpectedDay', '#DayBeforeRun', 'daily grain at T before the restating run';

    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           SUM(active_count) AS active_count, SUM(paid_count) AS paid_count, SUM(paid_count_event) AS paid_count_event,
           SUM(event_join_count) AS event_join_count, SUM(event_renewal_count) AS event_renewal_count,
           SUM(event_readmission_count) AS event_readmission_count, SUM(event_lapse_count) AS event_lapse_count
    INTO #DetailBeforeRun
    FROM Layercake.fn_silv_daily_count_detail_as_known_at('2020-10-01', '2025-01-10', @t)
    GROUP BY [date], region, country_id, gender_id, grade, membership_status_id;
    EXEC tSQLt.AssertEqualsTable '#ExpectedDetail', '#DetailBeforeRun', 'old detail grain at T before the restating run';

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT [date], region, grade, active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
    INTO #DayAfterRun
    FROM Layercake.fn_silv_daily_count_as_known_at('2020-10-01', '2025-01-10', @t);
    EXEC tSQLt.AssertEqualsTable '#ExpectedDay', '#DayAfterRun', 'daily grain at T after the restating run';

    SELECT [date], region, country_id, gender_id, grade, membership_status_id,
           SUM(active_count) AS active_count, SUM(paid_count) AS paid_count, SUM(paid_count_event) AS paid_count_event,
           SUM(event_join_count) AS event_join_count, SUM(event_renewal_count) AS event_renewal_count,
           SUM(event_readmission_count) AS event_readmission_count, SUM(event_lapse_count) AS event_lapse_count
    INTO #DetailAfterRun
    FROM Layercake.fn_silv_daily_count_detail_as_known_at('2020-10-01', '2025-01-10', @t)
    GROUP BY [date], region, country_id, gender_id, grade, membership_status_id;
    EXEC tSQLt.AssertEqualsTable '#ExpectedDetail', '#DetailAfterRun', 'old detail grain at T after the restating run';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-023 the review view carries each adjustment cell segment ids with -2 on rows written before deployment]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID();

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES ('2024-10-01', 2025, 'Q1');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter) VALUES (1, '2024-10-01', 2025, 'Q1');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y1', '2023-10-01', NULL, 2024, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date) VALUES (N'Y1', 1, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y1', 2025, 2, 0, 1, 0, 1, 0, 1);

    EXEC (N'INSERT INTO Layercake.silv_daily_count_adjustment
              (run_id, load_id, written_at, [date], region, country_id, gender_id, grade, membership_status_id,
               payment_method_id, payer_type_id, concession_type_id,
               active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
               event_renewal_count_change, event_readmission_count_change, event_lapse_count_change)
            VALUES (NEWID(), 7, ''2024-10-01T07:00:00'', ''2024-10-01'', ''UK'', 1, 1, ''election'', 1, -2, -2, -2, 0, 1, 0, 0, 0, 0, 0);');

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    UPDATE Layercake.silv_member_year_attributes SET payment_method_id = 1 WHERE contact_no = N'Y1' AND campaign_year = 2025;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id, CAST(v.measure_name AS varchar(30)) AS measure_name, v.change_value
    INTO #Expected
    FROM (VALUES ('2024-10-01', 'UK', 1, 1, 'election', 1, -2, -2, -2, 'paid_count', 1),
                 ('2024-10-01', 'UK', 1, 1, 'election', 1, 2, 1, 1, 'active_count', -1),
                 ('2024-10-01', 'UK', 1, 1, 'election', 1, 1, 1, 1, 'active_count', 1))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id, measure_name, change_value);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  measure_name, change_value
           FROM Layercake.vw_silv_daily_count_adjustment_review;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-024 the detail as-known-at function returns the segment cell of each time]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @t1 datetime2(3), @t2 datetime2(3);

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter) VALUES ('2024-10-01', 2025, 'Q1');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter) VALUES (1, '2024-10-01', 2025, 'Q1');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'Y1', '2023-10-01', NULL, 2024, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date) VALUES (N'Y1', 1, 1, NULL);
    INSERT INTO Layercake.silv_member_year_attributes (contact_no, campaign_year, payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried, load_id)
    VALUES (N'Y1', 2025, 2, 0, 1, 0, 1, 0, 1);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;
    WAITFOR DELAY '00:00:00.050';
    SET @t1 = SYSDATETIME();
    WAITFOR DELAY '00:00:00.050';
    UPDATE Layercake.silv_member_year_attributes SET payment_method_id = 1 WHERE contact_no = N'Y1' AND campaign_year = 2025;
    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;
    WAITFOR DELAY '00:00:00.050';
    SET @t2 = SYSDATETIME();

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpectedT1
    FROM (VALUES ('2024-10-01', 'UK', 1, 1, 'election', 1, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #ActualT1 FROM #ExpectedT1;
    INSERT INTO #ActualT1
    EXEC sp_executesql
        N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
          FROM Layercake.fn_silv_daily_count_detail_as_known_at(''2020-10-01'', ''2025-12-31'', @t)
          WHERE active_count <> 0 OR paid_count <> 0 OR paid_count_event <> 0 OR event_join_count <> 0
             OR event_renewal_count <> 0 OR event_readmission_count <> 0 OR event_lapse_count <> 0;',
        N'@t datetime2(3)', @t = @t1;

    EXEC tSQLt.AssertEqualsTable '#ExpectedT1', '#ActualT1', 'as known at T1';

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #ExpectedT2
    FROM (VALUES ('2024-10-01', 'UK', 1, 1, 'election', 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #ActualT2 FROM #ExpectedT2;
    INSERT INTO #ActualT2
    EXEC sp_executesql
        N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
          FROM Layercake.fn_silv_daily_count_detail_as_known_at(''2020-10-01'', ''2025-12-31'', @t);',
        N'@t datetime2(3)', @t = @t2;

    EXEC tSQLt.AssertEqualsTable '#ExpectedT2', '#ActualT2', 'as known at T2';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-025 every module object is in the Layercake schema and the applied attribute snapshot has its columns]
AS
BEGIN
    DECLARE @att int;

    SELECT v.object_name,
           CASE WHEN OBJECT_ID(N'Layercake.' + v.object_name) IS NOT NULL THEN 1 ELSE 0 END AS in_layercake,
           (SELECT COUNT(*) FROM sys.objects AS o
            WHERE o.name = v.object_name COLLATE DATABASE_DEFAULT
              AND o.schema_id <> SCHEMA_ID(N'Layercake')) AS outside_layercake
    INTO #Actual
    FROM (VALUES (N'silv_daily_count_detail'), (N'etl_daily_count_cell_contacts'), (N'silv_daily_count_adjustment'),
                 (N'fact_daily_member_count_detail'), (N'etl_daily_count_applied_attribute'),
                 (N'fn_silv_daily_count_detail_as_known_at'), (N'vw_silv_daily_count_adjustment_review'),
                 (N'usp_load_silv_daily_count'), (N'usp_load_fact_daily_member_count_detail')) AS v(object_name);

    SELECT v.object_name, v.in_layercake, v.outside_layercake
    INTO #Expected
    FROM (VALUES (N'silv_daily_count_detail', 1, 0), (N'etl_daily_count_cell_contacts', 1, 0), (N'silv_daily_count_adjustment', 1, 0),
                 (N'fact_daily_member_count_detail', 1, 0), (N'etl_daily_count_applied_attribute', 1, 0),
                 (N'fn_silv_daily_count_detail_as_known_at', 1, 0), (N'vw_silv_daily_count_adjustment_review', 1, 0),
                 (N'usp_load_silv_daily_count', 1, 0), (N'usp_load_fact_daily_member_count_detail', 1, 0)) AS v(object_name, in_layercake, outside_layercake);

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'module objects';

    SELECT @att = r.ObjectId FROM tSQLt.Private_RenamedObjectLog AS r
    WHERE REPLACE(REPLACE(r.OriginalName, N'[', N''), N']', N'') IN (N'etl_daily_count_applied_attribute', N'Layercake.etl_daily_count_applied_attribute')
      AND OBJECT_SCHEMA_NAME(r.ObjectId) = N'Layercake';
    IF @att IS NULL SET @att = OBJECT_ID(N'Layercake.etl_daily_count_applied_attribute');

    SELECT c.name COLLATE DATABASE_DEFAULT AS column_name,
           TYPE_NAME(c.user_type_id) COLLATE DATABASE_DEFAULT AS type_name,
           CAST(c.max_length AS int) AS max_length,
           CAST(c.is_nullable AS int) AS is_nullable
    INTO #ActualColumns
    FROM sys.columns AS c
    WHERE c.object_id = @att;

    SELECT v.column_name, v.type_name, v.max_length, v.is_nullable
    INTO #ExpectedColumns
    FROM (VALUES (N'contact_no', N'nvarchar', 400, 0), (N'campaign_year', N'int', 4, 0),
                 (N'payment_method_id', N'int', 4, 0), (N'payer_type_id', N'int', 4, 0), (N'concession_type_id', N'int', 4, 0))
         AS v(column_name, type_name, max_length, is_nullable);

    EXEC tSQLt.AssertEqualsTable '#ExpectedColumns', '#ActualColumns', 'etl_daily_count_applied_attribute columns';
END;
GO

CREATE PROCEDURE test_MOD028.[test TC-028-026 a MOD-026 Renewal case with no attributes keeps its figures under 0 0 0]
AS
BEGIN
    DECLARE @r1 uniqueidentifier = NEWID(), @r2 uniqueidentifier = NEWID(), @cr int;

    INSERT INTO Layercake.ref_date_spine ([date], campaign_year, campaign_quarter)
    VALUES ('2025-01-09', 2025, 'Q2'), ('2025-01-10', 2025, 'Q2'), ('2025-01-11', 2025, 'Q2');
    INSERT INTO Layercake.dim_date (id, [date], campaign_year, campaign_quarter)
    VALUES (1, '2025-01-09', 2025, 'Q2'), (2, '2025-01-10', 2025, 'Q2'), (3, '2025-01-11', 2025, 'Q2');
    INSERT INTO Layercake.silv_member_state_ranges (id, contact_no, valid_from, valid_to, campaign_year_from, grade, region, state_seq)
    VALUES (1, N'D1', '2015-01-01', NULL, 2015, 'election', 'UK', 1),
           (2, N'D2', '2015-01-01', NULL, 2015, 'election', 'UK', 1);
    INSERT INTO Layercake.silv_member_profile (contact_no, country_id, gender_id, retirement_date)
    VALUES (N'D1', 1, 1, NULL), (N'D2', 2, 2, NULL);
    INSERT INTO Layercake.silv_payment_events (contact_no, campaign_year, payment_date, renewal_date_adj, invoice_position)
    VALUES (N'D2', 2025, '2024-10-20', '2024-10-20', N'Fully Paid');
    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (1, N'RN:D2:2025', 'Renewal', 'Standard', '2024-10-20', N'D2', 2, 0, 0, 0, 2, 2, 1, 2025, 'Q1', 0, 0, 0, 0, 0, 0);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r1;

    INSERT INTO Layercake.silv_membership_events
        (event_id, event_nk, event_type, event_subtype, event_date, contact_no, grade_id, assessment_route_id, rpq_variant_id, hpb_id,
         country_id, gender_id, membership_status_id, campaign_year, campaign_quarter,
         payment_method_id, payment_method_carried, payer_type_id, payer_type_carried, concession_type_id, concession_type_carried)
    VALUES (2, N'RN:D1:2025', 'Renewal', 'Standard', '2025-01-10', N'D1', 2, 0, 0, 0, 1, 1, 1, 2025, 'Q2', 0, 0, 0, 0, 0, 0);

    EXEC Layercake.usp_load_silv_daily_count @run_id = @r2;

    SELECT @cr = p.rows_affected FROM Layercake.etl_progress_log AS p
    INNER JOIN Layercake.etl_run_log AS l ON l.log_id = p.log_id
    WHERE l.run_id = @r2 AND l.step_name = 'silv_daily_count' AND p.substep = N'contacts_recomputed';
    EXEC tSQLt.AssertEquals 1, @cr, 'contacts_recomputed';

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count, v.paid_count, v.paid_count_event, v.event_join_count, v.event_renewal_count, v.event_readmission_count, v.event_lapse_count
    INTO #Expected
    FROM (VALUES ('2025-01-09', 'UK', 1, 1, 'election', 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 1, 1, 'election', 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0),
                 ('2025-01-11', 'UK', 1, 1, 'election', 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0),
                 ('2025-01-09', 'UK', 2, 2, 'election', 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-10', 'UK', 2, 2, 'election', 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0),
                 ('2025-01-11', 'UK', 2, 2, 'election', 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count);

    SELECT TOP (0) * INTO #Actual FROM #Expected;
    INSERT INTO #Actual
    EXEC (N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                  active_count, paid_count, paid_count_event, event_join_count, event_renewal_count, event_readmission_count, event_lapse_count
           FROM Layercake.silv_daily_count_detail;');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual', 'detail';

    SELECT CAST(v.[date] AS date) AS [date], CAST(v.region AS varchar(12)) AS region, v.country_id, v.gender_id, CAST(v.grade AS varchar(12)) AS grade, v.membership_status_id,
           v.payment_method_id, v.payer_type_id, v.concession_type_id,
           v.active_count_change, v.paid_count_change, v.paid_count_event_change, v.event_join_count_change,
           v.event_renewal_count_change, v.event_readmission_count_change, v.event_lapse_count_change
    INTO #ExpectedAdj
    FROM (VALUES ('2025-01-10', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0),
                 ('2025-01-11', 'UK', 1, 1, 'election', 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0))
         AS v([date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
              active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
              event_renewal_count_change, event_readmission_count_change, event_lapse_count_change);

    SELECT TOP (0) * INTO #ActualAdj FROM #ExpectedAdj;
    INSERT INTO #ActualAdj
    EXEC sp_executesql
        N'SELECT [date], region, country_id, gender_id, grade, membership_status_id, payment_method_id, payer_type_id, concession_type_id,
                 active_count_change, paid_count_change, paid_count_event_change, event_join_count_change,
                 event_renewal_count_change, event_readmission_count_change, event_lapse_count_change
          FROM Layercake.silv_daily_count_adjustment
          WHERE run_id = @run;',
        N'@run uniqueidentifier', @run = @r2;

    EXEC tSQLt.AssertEqualsTable '#ExpectedAdj', '#ActualAdj', 'adjustment rows of run 2';
END;
GO
