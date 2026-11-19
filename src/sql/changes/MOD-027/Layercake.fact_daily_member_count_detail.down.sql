-- Narrow id back to int, keeping the values. An id beyond the int range
-- cannot be kept, so the rollback stops before changing anything.
IF EXISTS (SELECT 1 FROM Layercake.fact_daily_member_count_detail WHERE id > 2147483647 OR id < -2147483648)
    THROW 50027, 'Layercake.fact_daily_member_count_detail.id holds a value beyond the int range, so it cannot be narrowed back to int: MIG-0029 was not rolled back.', 1;
-- Every id fits int, but the identity may already have issued a value
-- beyond it (rows since deleted). SQL Server refuses to narrow the column
-- then (error 8115), so the identity restarts after the highest id kept.
IF IDENT_CURRENT(N'Layercake.fact_daily_member_count_detail') > 2147483647
BEGIN
    DECLARE @max_id bigint = (SELECT ISNULL(MAX(id), 0) FROM Layercake.fact_daily_member_count_detail);
    DBCC CHECKIDENT ('Layercake.fact_daily_member_count_detail', RESEED, @max_id) WITH NO_INFOMSGS;
END;
ALTER TABLE Layercake.fact_daily_member_count_detail DROP CONSTRAINT pk_fact_daily_member_count_detail;
ALTER TABLE Layercake.fact_daily_member_count_detail ALTER COLUMN id int NOT NULL;
ALTER TABLE Layercake.fact_daily_member_count_detail ADD CONSTRAINT pk_fact_daily_member_count_detail PRIMARY KEY NONCLUSTERED (id);
