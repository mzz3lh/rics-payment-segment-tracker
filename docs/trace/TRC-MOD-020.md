# Traceability: MOD-020

Checked by the Product Owner before the pre-merge review: requirement, acceptance criteria, test conditions, latest results.

**Result:** no gaps; 3 review flag(s).

| Requirement | Title | Acceptance criteria | Test conditions | Results | Status |
|---|---|---|---|---|---|
| REQ-004 | Member-year attributes with payment method | AC-004-13, AC-004-14 | TC-020-001, TC-020-002, TC-020-003, TC-020-004, TC-020-005, TC-020-006, TC-020-007, TC-020-008 | pass | met |
| REQ-006 | Payer type (Individual or Corporate) | AC-006-16 | TC-020-009, TC-020-010, TC-020-011 | pass | met |
| REQ-007 | Invoice line-type mapping and currency reference | AC-007-04 | TC-020-012, TC-020-013, TC-020-014 | pass | met |
| REQ-009 | Anomalies linking invoices and events | AC-009-11, AC-009-12 | TC-020-015, TC-020-016, TC-020-017, TC-020-018, TC-020-019 | pass | met |
| REQ-011 | Concession type on member-years and every event | AC-011-12, AC-011-13 | TC-020-020, TC-020-021, TC-020-022, TC-020-023 | pass | met |

## Review flags

- deviation: Choice the design leaves open: if the qualifying lines of one payment transaction (recid) disagree on mode, date or settled amount (they repeat in the source, so they should not), the line with the lowest line_id gives the values for the whole transaction, with postingtype and accountdisplayvalue breaking any tie. Lines with a blank mode are dropped before that line is picked, so a blank line never makes a transaction disappear. Covered by test_MOD020_dev.
- open questions in the spec touch this module's requirements: Q-001, Q-002, Q-006, Q-011, Q-012, Q-017, Q-019, Q-024, Q-027, Q-028
- handover documentation deferred to the handover (po.py handover)

Sources: docs/specs/SPEC-001.json, docs/design/MP-001.json, docs/test/TCS-MOD-020.json, docs/dev/CN-MOD-020.json, docs/test/TR-MOD-020-1.json
