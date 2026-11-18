# Traceability: MOD-021

Checked by the Product Owner before the pre-merge review: requirement, acceptance criteria, test conditions, latest results.

**Result:** no gaps; 4 review flag(s).

| Requirement | Title | Acceptance criteria | Test conditions | Results | Status |
|---|---|---|---|---|---|
| REQ-019 | Adjustment history of daily counts | - | TC-021-015, TC-021-016, TC-021-017 | pass | met |
| REQ-020 | Daily counts as known at any time, and adjustments review | AC-020-01, AC-020-02, AC-020-03, AC-020-04, AC-020-05, AC-020-06, AC-020-07 | TC-021-001, TC-021-002, TC-021-003, TC-021-010, TC-021-004, TC-021-005, TC-021-011, TC-021-006, TC-021-007, TC-021-008, TC-021-009, TC-021-012, TC-021-013, TC-021-014, TC-021-015, TC-021-016, TC-021-017 | pass | met |

## Review flags

- deviation: Grant script src/sql/grants/MOD-021.sql uses the placeholder role [<reporting_role>]: DES-001 names 'the existing reporting role that reads fact_membership_events' but not its name. A human replaces it and runs the script.
- deviation: Q-052 (open, blocks MOD-021 and MOD-022), part (b) only: confirmed from the Phase 1 code (Layercake.usp_load_silv_daily_count, the insert into silv_daily_count) that silv_daily_count is silv_daily_count_detail summed by [date], campaign_year, campaign_quarter, region and grade. So fn_silv_daily_count_as_known_at sums the detail function and does not read silv_daily_count. Parts (a) and (c) are left for MOD-022, as the plan says.
- open questions in the spec touch this module's requirements: Q-049, Q-050, Q-051
- handover documentation deferred to the handover (po.py handover)

Sources: docs/specs/SPEC-001.json, docs/design/MP-001.json, docs/test/TCS-MOD-021.json, docs/dev/CN-MOD-021.json, docs/test/TR-MOD-021-1.json
