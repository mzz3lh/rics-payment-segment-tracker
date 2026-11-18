# ADR-009: Final tie-break for a repeated corporate subscription key

| | |
|---|---|
| Status | proposed |
| Date | 2026-11-18 |
| Requirement IDs | REQ-022 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
Subs.vwCorpSubscriptions is at subscription-user grain and has no row key, so (Contact No, Scheme No, Sub Campaign Year) repeats (Q-033 answered No; AMD-004, 2026-11-18). RULE-128 makes Layercake.usp_load_brnz_corporate_subscription land one row per key, keeping in order: the copy whose Sub Status and Sub User Status are both 'Active' (Q-027); then the latest Sub User Created Date, NULL losing (Q-053); then the highest Round number, as Q-054 defines it. Copies can still tie after these three steps: 14 production keys repeat identical rows, and copies with equal dates whose Rounds are both NULL or have no trailing number (for example 'Round X' and NULL) tie while landing different sub_user_status values. RULE-128 says the remaining tie must be broken so that the same source data always lands the same row, whatever order the view returns rows in, and leaves the exact rule to the design. The source has no subscription-user id to fall back on. The landed values decide what the readers see (RULE-131), and the row-count check (RULE-130) and the zero-change rerun (AC-022-06) need the same copy to be chosen on every run.

## Options
### Option A: Landed values in exact order
After the three RULE-128 steps, keep the copy whose landed values come first when compared exactly, character by character with case and trailing spaces counting: sub_user_status first, then sub_status, then scheme_name, with a missing value before any value. Copies still tied then land identical values in every landed column, so it does not matter which one is kept.

Trade-offs: Simple to state, build and test, and depends only on the values the table holds, so a rerun on the same data always lands the same values and updates nothing. Exact comparison means copies that the database collation treats as equal, such as 'Active' and 'ACTIVE', still give a fixed result. The order has no business meaning: among copies the business rules cannot tell apart it favours whichever text sorts first. Columns that are not landed (Sub User State, Contact ID, dates) play no part, which is fine because they cannot change the landed row.

### Option B: Prefer a live subscription-user record, then landed values
Before the landed-value order of the first option, prefer the copy whose 'Sub User State' is the active state (the CRM subscription-user record has not been deactivated), on the reading that a live record is more current than a deactivated one.

Trade-offs: Gives the last step some business meaning, and stays deterministic because the landed-value order still follows. But it adds a business rule Mike did not ask for: he set the order as status, created date, Round, then any deterministic break. It also makes a fourth source column part of the choice and assumes the value of the active state, a second assumption like Q-027 that profiling has not confirmed. It needs more test cases and changes nothing for the readers, which only look for an Active/Active copy, which step 1 already prefers.

### Option C: Fingerprint of the whole source row
Compute a fingerprint over every source column of each copy and keep the copy with the lowest fingerprint.

Trade-offs: Deterministic over all source columns, including those not landed, and needs no column list. But the result is opaque: nobody can tell from the data why a copy won, testers have to compute fingerprints to predict a result, and a change to an unlanded column (for example Sub User Created Date on a losing copy) can switch the landed copy and update the bronze row with no business change behind it.

## Recommendation
Option A: Landed values in exact order. It meets RULE-128's only requirement for the last step, that the same source data always lands the same row, with the smallest rule that is easy to explain and test. It decides only between copies the business rules cannot tell apart, and adds no business rule beyond Mike's order. Because it looks only at landed values, any copies left tied land the same row, so reruns update nothing (AC-022-06).

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
DES-001: the Layercake.usp_load_brnz_corporate_subscription description and the corporate subscription repeated keys pattern state the fourth step as exact order of sub_user_status, then sub_status, then scheme_name, with a missing value first. MP-001: MOD-024 builds and tests it, including the identical-copy key (AC-022-06) and a key tied on the first three steps that lands different sub_user_status values. If the second option is chosen, the load also prefers the active Sub User State before the landed values, and MOD-024 tests that step and records the assumed state value in one place in the load. If the third option is chosen, the fourth step is the lowest whole-row fingerprint, and the tests predict results from fingerprints. Table structure and readers do not change under any option.
