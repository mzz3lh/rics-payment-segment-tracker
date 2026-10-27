# Answers to agents' questions

<!-- Human-written. When an agent defers a question (po.py run lists them under "Questions the agents deferred"),
write the answer here, one entry per question, then rerun that step: po.py redo discards the agent's unapproved
draft so the next po.py run redoes it, and every agent reads this file at the start of its run. An answer replaces
the agent's working assumption. Example:

## MOD-002 test design
- Which status values do the ETL log procedures write? 'Success' and 'Failed'.
-->

## SPEC-001 review 1 (Damian Watson, 2026-10-20)
- Damian reviewed SPEC-001 v1. His review is docs/reviews/SPEC-001-review-1.md, and the v1 draft it cites (RULE, REQ, AC and Q numbers) is docs/reviews/SPEC-001-v1.json. Rewrite the spec so it makes all twelve changes in the review's section 6. Where a change depends on Finance (fee treatment Q-003, corporate discount Q-005 and the others in section 5), keep or raise it as an open question with a stated working assumption rather than deciding it.
- CUSTTRANS_RICS grain (review 1.1): profiling real data is a human step. Raise it as an open question, give the count-only profiling query the human should run (rows per invoice, distinct productcode per invoice, whether tax is its own row), and say which rules depend on the answer and what changes if it is transaction grain.
- Employer segment (REQ-013): deliver it as findings only, as the review's section 5 recommends.
- Section 4 assumptions: keep them as open questions for Damian and Mike. REQ-001 acceptance stays synthetic-only, with no pass threshold for real data in this release.
- Keep the v1 numbering where a requirement, rule or question carries over, so the review's references still line up; give new items new numbers.

## SPEC-001 v2 deferred questions (Mike, 2026-10-23)
- Corporate payer-type test (review change 9): a contact is in a live corporate subscription for a Campaign Year when they exist in Subs.vwCorpSubscriptions and both 'Sub Status' and 'Sub User Status' are active. Do not use 'Round': a round is a tranche of processing corporate records and later rounds may change it. Record this in the spec as an assumption.
- Two events sharing one invoice (review 1.2): invoices are raised only when a member joins, renews or readmits, so assume exactly one invoice per Join, Renewal or Readmission event. State the assumption, and match each event to its own invoice (say how the match picks that event's invoice when a contact has more than one event in a Campaign Year; raise it as a question if the sources don't make it clear). Data that breaks the assumption (two events matching one invoice, or one event matching several) is an anomaly with its own reason code. Keep Damian's priority (Readmission, Renewal, Join, then earliest event date) only as the fallback that stops an invoice being counted twice in that case.
- Consequence for v2's single selected invoice per contact-year (RULE-014, RULE-032, Q-012): a contact with two events in one Campaign Year (for example a Renewal and a Readmission) has two live invoices, and both are legitimate. Each event takes its own invoice's amounts, so the second invoice is not an INVOICE_NO_EVENT anomaly. State which invoice sets the contact-year's payment method, payer type and concession when the year has more than one, and raise it as a question if the sources don't settle it. Rework the ACs that assume one shared invoice (v2's AC-008-12 to AC-008-15, AC-009-06).
- apuk_dualmembership (v2 Q-025): Damian's review says it is unused; it plays no part in this release.

## DES-001 Q-037 bronze audit columns (approved by Mike by merging PR #6, 2026-10-26)
- The column-name convention now allows an optional leading underscore (`^_?[a-z][a-z0-9_]*$`), but only for the four standard bronze audit columns `_loaded_at`, `_updated_at`, `_is_deleted` and `_deleted_at`, as in the Phase 1 bronze tables. New bronze tables carry them with the existing bronze types and defaults: `_loaded_at` and `_updated_at` datetime2(3) not null default SYSDATETIME(), `_is_deleted` bit not null default 0, `_deleted_at` datetime2(3) null.
- DES-001 lists them as columns on brnz_subs_invoice, brnz_subs_invoice_line, brnz_corporate_subscription and brnz_concession (MOD-002, MOD-004, MOD-006). This amends the approved design; merging the change is the approval.

## RULE-077 settling rows (Mike, 2026-10-26)
- A CUSTTRANS_RICS row that settles an invoice is in scope only when its LASTSETTLEVOUCHER matches the invoice's voucher AND its ACCOUNTNUM equals the invoice's Account_Num. A payment or credit posted on another customer account is not landed, even when it settles the invoice. Do not match on DATAAREAID: Subs.tblSubsInvoices has no legal entity, so RULE-077 stays ACCOUNTNUM + VOUCHER and ACCOUNTNUM + LASTSETTLEVOUCHER, as the spec, design and approved tests have it. (Corrected 2026-10-26: an earlier version of this answer added a DATAAREAID match that Mike had not asked for.)

## DES-001 bronze column types (2026-10-26)
- New bronze tables land source columns 1:1, so no column may be narrower than its source. DES-001 now uses the source width where it was narrower: brnz_subs_invoice.fully_credited nvarchar(3) (the source writes 'N/A' for invoices with no credit), payment_status nvarchar(100); brnz_subs_invoice_line.transdate datetime2(3) (source datetime keeps milliseconds), ordernum nvarchar(50); brnz_corporate_subscription.scheme_name nvarchar(4000), sub_status and sub_user_status nvarchar(350); brnz_concession.product_number nvarchar(4000), apuk_discount decimal(38,2). This amends the approved design; merging the change is the approval.

## MOD-002 ordernum and amount types (2026-10-26)
- brnz_subs_invoice_line.ordernum is nvarchar(50), as the amended DES-001 says; the design wins over the approved test. TC-002-018 must force the line load's error path some other way than an over-long ORDERNUM, and it is being amended for that.
- The money columns stay numeric(32,6) even though Subs.tblSubsInvoices has numeric(38,6): numeric(32,6) is the solution's money type (Phase 1 bronze uses it), and 26 integer digits cannot be exceeded by a real invoice amount. This is the one deliberate exception to "no column narrower than its source".

## MOD-003 fn_map_payment_method (Mike, 2026-10-26)
- Layercake.fn_map_payment_method is a scalar function: one nvarchar(20) code in (brnz_subs_invoice.inv_payment_method, brnz_subs_invoice_line.paymmode), the silv_ref_payment_method int id out.
- Compare the code with surrounding spaces trimmed and ignoring case: 'dd', ' DD' and 'Card ' map to their method. A code that is empty or only spaces maps to 0 Unknown, like NULL and ''. Only a code that is still different after that maps to -1 Unrecognised. TC-003-013 tests this.

## DES-001 load_id (Mike, 2026-10-26)
- Every load_id column is bigint and holds Layercake.etl_run_log.log_id (bigint identity, one row per step) of the load that last wrote the row; not run_id. DES-001 now says bigint for all nine (dim_payment_method, dim_payer_type, silv_ref_invoice_line_type, silv_ref_currency, dim_currency, silv_ref_concession_type, dim_concession_type, silv_member_year_attributes, silv_event_amount). This amends the approved design; merging the change is the approval.

## MOD-003 dim_payment_method population (Mike, 2026-10-26)
- dim_payment_method is not seeded by its migration. It is populated dynamically by Layercake.usp_load_dim_payment_method from silv_ref_payment_method, so after MIG-0005 it is empty until that load runs. Until MOD-016 adds usp_run_payment_segments (which runs it with the other loads), it is run by hand. The same applies to the other gold dimensions over seeded reference lists (dim_payer_type, dim_currency, dim_concession_type).

## MOD-004 NULL matching key (Mike, 2026-10-26)
- brnz_corporate_subscription keeps contact_no, scheme_no and sub_campaign_year NOT NULL. A Subs.vwCorpSubscriptions row where any of 'Contact No', 'Scheme No' or 'Sub Campaign Year' is NULL fails usp_load_brnz_corporate_subscription (error 515): the load logs Failed, re-raises and leaves the target unchanged. No row is skipped.

## MOD-005 NULL, blank and near-duplicate codes (Mike, 2026-10-27)
- usp_load_silv_ref_invoice_line_type takes codes from live brnz_subs_invoice_line rows. A row whose productcode is NULL, empty or only spaces has no item code and adds no mapping row.
- A row with a productcode but a NULL ricinvoicetype is not skipped. Its code is added with ric_invoice_type N'' (empty string) and line type 'unmapped', so the invoice is flagged 'Unmapped lines' (RULE-088) rather than its amount being lost unseen, and the pair can be mapped by hand like any other. Any later load that joins lines to the mapping treats a NULL ricinvoicetype as N''.
- Codes are matched as the database collation compares them (case-insensitive, trailing spaces ignored). A productcode or ricinvoicetype that differs from a listed pair only in case or trailing spaces is that pair: no new row, and it takes that pair's line type. A code with different leading spaces or characters is a new code and is added as 'unmapped'.
- usp_load_silv_ref_currency works the same way: an inv_currency that is NULL, empty or only spaces adds no row, and a code that differs from a listed one only in case or trailing spaces adds no row.

## Q-034 line-type mapping seed (Mike, 2026-10-27)
- The MOD-005 migration seeds Layercake.silv_ref_invoice_line_type with exactly the 12 codes that Subs.usp_Refresh_SubsInvoices names, all on ric_invoice_type N'SUB' with load_id NULL: RAFEE_ACAND, RAFEE_APCC, RAFEE_ASSOC, RAFEE_FRICS, RAFEE_MRICS, RAFEE_PMU2 as 'readmission fee', and CONPWRQ1, CONPWRQ2, CONPWRQ3, CONRETIRED, CONRETIREDFL, CONRETIREDSPECIAL as 'concession'. No other curated list exists.
- Every other code is added as 'unmapped' by the first load. After the first load on real data, Damian maps the unmapped codes by hand, following how Subs.usp_Refresh_SubsInvoices classifies them: a SUB line whose code is in the concession product list is a concession, other SUB lines are subscription, and RICINVOICETYPE 'APP' is an enrolment or application fee. This is a human step, and the handover lists it.

## MOD-006 NULL key, duplicate key and missing name (Mike, 2026-10-27)
- brnz_concession keeps apuk_concessiontypeid NOT NULL as its key, as MOD-004 does. A CE.vwConcessionType row with a NULL apuk_concessiontypeid, or two rows with the same apuk_concessiontypeid, fails usp_load_brnz_concession: the load logs Failed, re-raises and leaves the target unchanged. No row is skipped.
- A live brnz_concession type whose apuk_name is NULL, empty or only spaces is not skipped and does not fail usp_load_silv_ref_concession_type. It is added (or kept) with concession_type_name N'Unnamed concession type', so its id, item code and flags still reach the invoices that use it. When the source later gives it a name, the next load updates the name in place (RULE-046).

## MOD-007 attributes load (approved by Mike by merging this PR, 2026-10-27)
- Contact list and first-event year (RULE-011, Q-030): the contacts are every contact_no in Layercake.silv_membership_events, and a contact's first-event year is MIN(campaign_year) over all their events there. silv_member_base is not used: it holds no event year and is deliberately not unique on contact_no. Each contact gets one row per Campaign Year in Layercake.ref_campaign_year_config, from the first-event year to the current Campaign Year inclusive. A contact whose first event is after the current Campaign Year gets no rows. contact_no is nvarchar(200), the Phase 1 type (DES-001 said nvarchar(20); this PR corrects it on silv_member_year_attributes and silv_event_amount).
- Current Campaign Year: the ref_campaign_year_config row whose campaign_year_start <= @as_of_date <= campaign_year_end. The load is `Layercake.usp_load_silv_member_year_attributes @run_id uniqueidentifier = NULL, @as_of_date date = NULL`, where NULL means CAST(SYSDATETIME() AS date), so the scheduled run needs no argument and tests pass a fixed date. If no config row covers @as_of_date, the load fails: it logs Failed, re-raises and changes nothing.
- Phase 1 paid position (RULE-021, RULE-017): a contact has a paid position in a Campaign Year when Layercake.silv_payment_events has a row for that (contact_no, campaign_year). That table holds only the paid invoice positions (Full Concession, Fully Paid, Partially Paid, Pre-Subs Payment), so no further filter on invoice_position is applied. brnz_subs_status is not read directly.
- Eligible invoice (RULE-014, vw_silv_eligible_invoice): only live invoices count (brnz_subs_invoice._is_deleted = 0) with a non-NULL account_num and campaign_year; contact_no = account_num.
  - (a) Credit note: invoice LIKE '%FTCN%', or invoice LIKE '%CRE%' unless full_invoice_amount_cur = 0. This matches the owner's test, which lets a CRE invoice through only when its amount is 0, so a CRE invoice with a NULL amount is a credit note. A NULL invoice number is not a credit note.
  - (b) Fully credited: fully_credited = 'Y'. Subs.usp_Refresh_SubsInvoices sets 'Y', 'N' or 'N/A'; anything other than 'Y', including NULL, is not fully credited.
  - (c) Fee-only: the invoice's own lines are the live brnz_subs_invoice_line rows with accountnum = account_num and voucher = voucher. Each is typed through silv_ref_invoice_line_type on productcode = item_code and ISNULL(ricinvoicetype, N'') = ric_invoice_type; a line with no mapping row counts as unmapped. The invoice is fee-only, and not eligible, when it has at least one 'enrolment or application fee' line and every other own line is 'tax'. An invoice with no own lines is not fee-only, so it stays eligible.
  - Fallback: where a contact-year has no invoice passing (a), (b) and (c), its fully credited invoices that pass (a) and (c) are eligible instead.
  - Segment invoice: the latest eligible invoice by trans_date, ties to the higher rec_id (Q-036); a NULL trans_date sorts before every date.
- Payment-line fallback (RULE-013): it applies only when the segment invoice's inv_payment_method is NULL or blank after trimming. A non-blank code the mapping doesn't know gives -1 Unrecognised, with no fallback.
  - Payment lines: the live brnz_subs_invoice_line rows with lastsettlevoucher = the invoice's voucher and accountnum = its account_num (RULE-077 answer), with a paymmode that is not NULL or blank. The invoice's own lines (voucher = the invoice's voucher) are not payment lines.
  - Choosing the method: each paymmode is mapped through fn_map_payment_method, and ABS(settleamountcur) is summed per mapped method, with a NULL amount counting as 0. The method with the largest sum wins. On a tie, the method whose earliest payment (MIN(transdate)) is earliest wins, and the lowest recid breaks any remaining tie. An unrecognised mode takes part like any other, so if it wins the year gets -1. With no qualifying payment line, the year gets 0 Unknown with flag 0 (RULE-015).
- Load pattern (DES-001): not a full rebuild. The load recomputes every contact-year, inserts new rows, updates rows whose values differ (refreshing updated_at and load_id, keeping created_at), deletes rows no longer derived and leaves unchanged rows untouched. A rerun on unchanged data therefore logs 0, 0, 0.
- Logging: the same as the MOD-004 to MOD-006 loads. Layercake.usp_etl_log_start @run_id, 'silver', 'silv_member_year_attributes' runs before the transaction, and usp_etl_log_end logs 'Success' with the inserted, updated and deleted counts. On error, CATCH rolls back, logs 'Failed' with the error message and re-raises (THROW).

## MOD-007 carry-forward and campaign-year config (Mike, 2026-10-27)
- Carry-forward of Unknown (RULE-016, RULE-022): a Campaign Year from 2022 with no eligible invoice takes the value of the latest earlier year that has one, even when that value is 0 Unknown. It then gets 0 with carried flag 1, as built. Only a year with no earlier invoice year to carry from gets 0 with flag 0.
- An eligible invoice (2022 onward) in a year before the contact's first-event year can be carried into the first-event year, as built.
- Double payment (RULE-026): a contact-year whose segment invoice is settled both by Corporate and by another method, with no live corporate subscription, is Individual even when the contact has no Phase 1 paid position that year. RULE-026 is the specific rule for this case and takes precedence over RULE-021's paid-position test, as built.
- Layercake.ref_campaign_year_config needs no manual upkeep. Every Phase 1 silver run (usp_load_silver) first extends ref_date_spine to two years past today and then inserts any missing Campaign Year (1 Oct to 30 Sep) through usp_load_ref_campaign_year_config. The segment loads run after Phase 1, so the current Campaign Year always has a row. The attributes load can fail on a missing year only if Phase 1 silver has not run on a new database.
