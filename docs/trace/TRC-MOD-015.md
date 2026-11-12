# Traceability: MOD-015

Checked by the Product Owner before the pre-merge review: requirement, acceptance criteria, test conditions, latest results.

**Result:** no gaps; 5 review flag(s).

| Requirement | Title | Acceptance criteria | Test conditions | Results | Status |
|---|---|---|---|---|---|
| REQ-014 | Count-only profiling and coverage queries | AC-014-01, AC-014-02, AC-014-03, AC-014-04, AC-014-05, AC-014-06 | TC-015-001, TC-015-002, TC-015-003, TC-015-004, TC-015-017, TC-015-005, TC-015-006, TC-015-007, TC-015-008, TC-015-009, TC-015-010, TC-015-011, TC-015-012, TC-015-015, TC-015-013, TC-015-014, TC-015-016 | pass | met |

## Review flags

- deviation: Grant script src/sql/grants/MOD-015.sql uses the placeholder role [<analyst_role>] (as MOD-014 does), because the analyst role's name is not known. A human replaces it and runs the script.
- deviation: DES-001 does not define the four reports' interface. They are built to the interface in ASM-007 (Product Owner answer, unreviewed): one @as_of_date parameter, one aggregate result set each, and the columns, bases and measures stated there.
- assumptions the Product Owner made for MOD-015: ASM-007 (docs/assumptions.md)
- open questions in the spec touch this module's requirements: Q-027
- handover documentation deferred to the handover (po.py handover)

Sources: docs/specs/SPEC-001.json, docs/design/MP-001.json, docs/test/TCS-MOD-015.json, docs/dev/CN-MOD-015.json, docs/test/TR-MOD-015-1.json
