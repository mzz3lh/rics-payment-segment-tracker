# ADR-004: Free-readmission window

| | |
|---|---|
| Status | proposed |
| Date | 2026-10-23 |
| Requirement IDs | REQ-009 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
A Readmission with no readmission fee gets READMISSION_FREE when it falls under the free-readmission policy, otherwise READMISSION_NO_FEE (RULE-044). RULE-092 and the spec's assumptions define the window as 1 April to 30 June of the calendar year, and AC-009-03 and AC-009-05 test 2025-05-14 (free) and 2025-08-12 (not free). The spec records Q-023 as answered 'Campaign Year Quarter', which points to the second quarter of the Campaign Year instead. The two readings agree only if the Campaign Year starts on 1 January. The question has been put to the business (Q-032).

## Options
### Option A: Second quarter of the Campaign Year
Free when the Readmission's event date falls in months four to six of its Campaign Year, counted from campaign_year_start in Layercake.ref_campaign_year_config.

Trade-offs: Follows the recorded answer to Q-023, and follows the Campaign Year if its start date ever moves. If the Campaign Year does not start on 1 January, AC-009-03 and AC-009-05 as written would need new dates.

### Option B: Calendar 1 April to 30 June
Free when the event date falls between 1 April and 30 June of the event's calendar year, as RULE-092 states.

Trade-offs: Matches the rule text and the acceptance criteria exactly, and needs no calendar lookup. But it contradicts the recorded answer if the Campaign Year does not start on 1 January.

## Recommendation
Option A: Second quarter of the Campaign Year. The recorded answer replaces the working assumption. The recommendation is provisional until Q-032 confirms whether Campaign Year Q2 is the intended window and whether it coincides with April to June. The window is a single rule in the invoice anomaly load, so switching takes one change.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
The invoice anomaly load (MOD-011) reads campaign_year_start from Layercake.ref_campaign_year_config to place each Readmission in its Campaign Year quarter. If the calendar option is chosen, that lookup is dropped. If the business confirms Campaign Year Q2 and the year does not start on 1 January, AC-009-03 and AC-009-05 need new dates in a spec update.
