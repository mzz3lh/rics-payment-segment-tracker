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
