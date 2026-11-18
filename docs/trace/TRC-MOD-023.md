# Traceability: MOD-023

Checked by the Product Owner before the pre-merge review: requirement, acceptance criteria, test conditions, latest results.

**Result:** no gaps; 4 review flag(s).

| Requirement | Title | Acceptance criteria | Test conditions | Results | Status |
|---|---|---|---|---|---|
| REQ-021 | Payment and invoice segments in the normal daily load | AC-021-01, AC-021-02, AC-021-03, AC-021-04, AC-021-05, AC-021-06, AC-021-07 | TC-023-001, TC-023-002, TC-023-003, TC-023-004, TC-023-005, TC-023-006, TC-023-007, TC-023-008, TC-023-009, TC-023-010, TC-023-011, TC-023-012, TC-023-013 | pass | met |
| REQ-018 | Past daily counts kept in line with silver on every run | AC-018-10 | TC-023-013, TC-023-011 | pass | met |

## Review flags

- deviation: AC-001-04 / MP-001 MOD-023 scope: I could not run the Phase 1 reconciliation scripts reference/phase1/Scripts/Reconciliation/active-member-difference.sql and paid-member-difference.sql. They are SQLCMD files and my tools only run single T-SQL batches, so no PASS verdict is recorded here. As ASM-009 allows, this becomes a handover step for a human: run both scripts after one call of Layercake.usp_run_daily_load on the synthetic data and record both RS-1 verdicts. TC-023-011 covers the tables they compare on the pipeline side, and it passes.
- deviation: sqlfluff capitalisation and layout findings (CP01/CP02 and others) on usp_run_daily_load are left as they are. The procedure keeps its Phase 1 lower-case style, following the 'write new code in the style of the code around it' rule for changed existing objects.
- assumptions the Product Owner made for MOD-023: ASM-010 (docs/assumptions.md)
- handover documentation deferred to the handover (po.py handover)

Sources: docs/specs/SPEC-001.json, docs/design/MP-001.json, docs/test/TCS-MOD-023.json, docs/dev/CN-MOD-023.json, docs/test/TR-MOD-023-1.json
