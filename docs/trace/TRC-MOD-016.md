# Traceability: MOD-016

Checked by the Product Owner before the pre-merge review: requirement, acceptance criteria, test conditions, latest results.

**Result:** no gaps; 4 review flag(s).

| Requirement | Title | Acceptance criteria | Test conditions | Results | Status |
|---|---|---|---|---|---|
| REQ-001 | Phase 1 counts and measures unchanged | AC-001-01, AC-001-02, AC-001-04, AC-001-05 | TC-016-008, TC-016-009, TC-016-010, TC-016-011, TC-016-015, TC-016-012, TC-016-013, TC-016-014, TC-016-001, TC-016-002, TC-016-004, TC-016-005 | pass | met |
| REQ-015 | Platform Schema document content | AC-015-01, AC-015-02, AC-015-03, AC-015-04 | TC-016-018, TC-016-019, TC-016-020, TC-016-021 | pass | met |
| REQ-016 | Migrations, rollback and rerunnable loads | AC-016-01, AC-016-02, AC-016-03 | TC-016-017, TC-016-001, TC-016-002, TC-016-003, TC-016-004, TC-016-005, TC-016-006, TC-016-007, TC-016-016 | pass | met |

## Review flags

- deviation: AC-001-04: the Phase 1 difference scripts (reference/phase1/Scripts/Reconciliation/active-member-difference.sql and paid-member-difference.sql) are SQLCMD files. They are not among the files the Developer can read, and no tool here runs SQLCMD, so their RS-1 verdicts are not recorded in this note. As ASM-009 allows, running both against a database loaded with the synthetic data, after the Phase 1 run and usp_run_payment_segments, and confirming both read PASS, is a listed handover step for a human. TC-016-015 and TC-016-008 to TC-016-011 cover the tables the scripts compare.
- assumptions the Product Owner made for MOD-016: ASM-008, ASM-009 (docs/assumptions.md)
- open questions in the spec touch this module's requirements: Q-005, Q-007, Q-011
- handover documentation deferred to the handover (po.py handover)

Sources: docs/specs/SPEC-001.json, docs/design/MP-001.json, docs/test/TCS-MOD-016.json, docs/dev/CN-MOD-016.json, docs/test/TR-MOD-016-1.json
