# ADR-006: How the invoice line key is enforced

| | |
|---|---|
| Status | proposed |
| Date | 2026-11-12 |
| Requirement IDs | REQ-002 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
Profiling of real data (Q-021, AMD-002, 2026-11-11) shows synapse_fo.CUSTTRANS_RICS is at ledger-distribution grain: one customer transaction (RECID) is split into one row per POSTINGTYPE and ACCOUNTDISPLAYVALUE. RULE-104 makes Layercake.brnz_subs_invoice_line one row per source row in scope, identified by (recid, postingtype, accountdisplayvalue), and leaves the way the key is enforced to the design. Built by MOD-002, the table today has its primary key on recid alone, so the load fails with a duplicate key on real data. Three facts limit the choice. (1) accountdisplayvalue is nvarchar(500) in the source, up to 1,000 bytes, so (recid, postingtype, accountdisplayvalue) can reach 1,012 bytes: over SQL Server's 900-byte limit for a clustered index key, but within the 1,700-byte limit for a nonclustered index. (2) postingtype and accountdisplayvalue can both be null and must land as null (RULE-004, AC-002-11), so they cannot be primary key columns. (3) Bronze is 1:1 with the source, and the column must keep its full source width (no column narrower than its source).

## Options
### Option A: Option A: Surrogate line key plus a unique index on the source identity
Add line_id, a bigint identity, as the clustered primary key. A unique nonclustered index on (recid, postingtype, accountdisplayvalue) enforces the source identity at full width. Two nulls count as equal in that index, so a transaction can have at most one row with null postingtype and null accountdisplayvalue, which matches the source's uniqueness. The load matches source rows to bronze on the three columns, with null matching null, compared under the database collation the index uses.

Trade-offs: The table has a real, narrow, never-null primary key, and the business identity is still enforced by the database, so a duplicate cannot be landed. The one column that does not come from the source is line_id, a technical key like the audit columns. Nothing reads it, so readers keep working on recid, voucher and lastsettlevoucher. The unique index is wide (up to about 1 KB per entry) and costs some insert time and storage on a table of about a million rows. That is acceptable for a daily full comparison.

### Option B: Option B: Clustered primary key on recid, postingtype and a hash of the account string
Add a persisted column holding a fixed-length hash of accountdisplayvalue, with stand-in values for null postingtype and accountdisplayvalue so the columns can be key columns. Put the clustered primary key on (recid, postingtype key, hash), and keep the full accountdisplayvalue as an ordinary column.

Trade-offs: A transaction's lines are stored together in recid order, which suits readers that work per transaction, and the key is narrow. But the hash is built from the exact characters, while the database collation compares without regard to case. Two values that differ only in case would be one row to the source and the load but two to the key, so the key would not match the identity the source guarantees. It also needs null stand-ins and a hash column that is not in the source, and it carries a small collision risk. More to build and explain, for a benefit the expected volumes do not need.

### Option C: Option C: Unique index on the source identity, with no primary key
Drop the recid primary key and add no surrogate. A non-unique clustered index on recid keeps a transaction's lines together, and a unique nonclustered index on (recid, postingtype, accountdisplayvalue) enforces the identity.

Trade-offs: The table stays strictly 1:1, with no extra column, and the identity is enforced just as in Option A. But the table has no primary key, unlike every other table in the solution. Tools and people that expect a key on each table (the migration checks, the Platform Schema document, later merges) would treat it as an exception, and a heap-like non-unique clustered key adds a hidden uniquifier on every row.

## Recommendation
Option A: Option A: Surrogate line key plus a unique index on the source identity. Option A enforces exactly the identity the source guarantees: all three columns at full width, nulls allowed, compared the way the database and the load compare them. It also keeps a conventional, narrow primary key. Option B's hash compares differently from the collation, and Option C leaves the table without a primary key. Neither gains enough at about a million rows to justify that.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
MOD-019 changes Layercake.brnz_subs_invoice_line through a change script. It adds the five source columns postingtype, accountdisplayvalue, mainaccount, costcenter and ricscampaignyear, all nullable and at source width, and the line_id identity. It replaces the recid primary key with a primary key on line_id and a unique index on (recid, postingtype, accountdisplayvalue). It changes usp_load_brnz_subs_invoice_line to match on those three columns. Rows landed before the change hold null in the new columns, so the first load after deployment soft-deletes them and lands the source rows at the new grain. Because the old key cannot hold split rows, the down script renames the table to brnz_subs_invoice_line_rolledback_MIGnnnn when it holds rows, recreates it at its MOD-002 shape and restores the MOD-002 load. The MOD-002 load then lands it again (and, on real data, fails on split transactions as it does today). Readers do not read line_id. If Option C were chosen, line_id would go and the clustered index would move to recid. If Option B were chosen, the hash column and null stand-ins would be added and the load would match on the hash.
