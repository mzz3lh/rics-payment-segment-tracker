-- RULE-152 / Q-056: widen id from int to bigint, keeping the identity, its
-- values and the nonclustered primary key. The key has to be dropped to
-- change the column's type, and is recreated with its existing name.
ALTER TABLE Layercake.fact_daily_member_count_detail DROP CONSTRAINT pk_fact_daily_member_count_detail;
ALTER TABLE Layercake.fact_daily_member_count_detail ALTER COLUMN id bigint NOT NULL;
ALTER TABLE Layercake.fact_daily_member_count_detail ADD CONSTRAINT pk_fact_daily_member_count_detail PRIMARY KEY NONCLUSTERED (id);
