# Traceability: MOD-024

Checked by the Product Owner before the pre-merge review: requirement, acceptance criteria, test conditions, latest results.

**Result:** no gaps; 3 review flag(s).

| Requirement | Title | Acceptance criteria | Test conditions | Results | Status |
|---|---|---|---|---|---|
| REQ-022 | One corporate subscription row per contact, scheme and Campaign Year | AC-022-01, AC-022-02, AC-022-03, AC-022-04, AC-022-05, AC-022-06, AC-022-07, AC-022-08, AC-022-09, AC-022-10, AC-022-11, AC-022-12, AC-022-13 | TC-024-001, TC-024-002, TC-024-016, TC-024-003, TC-024-004, TC-024-005, TC-024-012, TC-024-006, TC-024-011, TC-024-007, TC-024-008, TC-024-009, TC-024-013, TC-024-014, TC-024-015, TC-024-010, TC-024-017, TC-024-018, TC-024-019, TC-024-020, TC-024-021, TC-024-022, TC-024-023, TC-024-024 | pass | met |

## Review flags

- deviation: ADR-009's final tie-break (sub_user_status, then sub_status, then scheme_name, in exact order, missing first) gets two more steps: contact_no, then scheme_no, in exact order. The key matches case-insensitively, so copies such as 'c2201' and 'C2201' are one key but would land different bytes in the key columns. Without these steps the landed copy would depend on the order the view returns rows, which breaks RULE-128's determinism. These steps only decide copies the ADR's steps leave tied. 'Exact order' is binary comparison (Latin1_General_BIN2), then DATALENGTH, so a value comes before the same value with a trailing space.
- deviation: Step 1 (Active/Active, Q-027) compares the active value under the database collation, not exactly, because that is how the five readers compare it (cs.sub_status = N'Active'). A copy the readers count as active, such as 'ACTIVE'/'active', is therefore always preferred.
- handover documentation deferred to the handover (po.py handover)

Sources: docs/specs/SPEC-001.json, docs/design/MP-001.json, docs/test/TCS-MOD-024.json, docs/dev/CN-MOD-024.json, docs/test/TR-MOD-024-1.json
