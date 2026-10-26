# ADR-003: Delivery of the count-only profiling and findings queries

| | |
|---|---|
| Status | proposed |
| Date | 2026-10-23 |
| Requirement IDs | REQ-012, REQ-013, REQ-014 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
REQ-012, REQ-013 and REQ-014 need queries that return counts, sums and rates only (RULE-057, RULE-064, RULE-066). Mike runs them on real data, and the agents' tests run them on synthetic data. Several depend on the load date: the current Campaign Year (RULE-069) and the last full Campaign Year (RULE-070, RULE-062). The grain and corporate status profiles (RULE-095, RULE-096) read external objects and are wanted before the invoice build.

## Options
### Option A: Read-only procedures with an as-of date
One procedure per query in Layercake. Each returns one aggregate result set, with an optional as-of date parameter that defaults to today and sets the current and last full Campaign Year. They are deployed by migration, like every other object.

Trade-offs: tSQLt can test them with faked sources and a fixed as-of date, so date-relative results such as AC-014-03 and AC-014-04 are deterministic. Running them needs only EXECUTE. They are deployed and versioned with the solution. Cost: they must be deployed to production before Mike can run them there, and there are about a dozen extra objects.

### Option B: Views
One view per query in Layercake, reading the load date from the server clock.

Trade-offs: Easy to query and to grant SELECT on. But the current and last full Campaign Year come from today's date, so tests on synthetic data either depend on the run date or have to fake the calendar. Results cannot be re-run for an earlier date.

### Option C: Undeployed SQL scripts
Plain query scripts kept in the repository for Mike to run by hand, not deployed to any database.

Trade-offs: Nothing to deploy, and they can run before any build. But tSQLt cannot test them as objects, so the acceptance criteria could only be checked by running the scripts against synthetic data outside the test framework, and they could drift from the deployed objects.

## Recommendation
Option A: Read-only procedures with an as-of date. They are the only option that is testable in tSQLt, deterministic for date-relative figures, and versioned with the solution. Aggregate-only output is enforced by each procedure's fixed result shape.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
Adds usp_profile_* and usp_report_* procedures in Layercake (MOD-001, MOD-013, MOD-014, MOD-015). Grants: EXECUTE for the analyst who runs them, scripted for a human. The two source profiles are a separate early module (MOD-001), so they can be deployed and run before the invoice build.
