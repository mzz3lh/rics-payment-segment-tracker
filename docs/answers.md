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
