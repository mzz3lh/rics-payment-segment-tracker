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
