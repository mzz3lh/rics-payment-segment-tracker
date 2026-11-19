# Traceability: MOD-026

Checked by the Product Owner before the pre-merge review: requirement, acceptance criteria, test conditions, latest results.

**Result:** no gaps; 3 review flag(s).

| Requirement | Title | Acceptance criteria | Test conditions | Results | Status |
|---|---|---|---|---|---|
| REQ-024 | Daily count recomputes only the contacts that changed | AC-024-01, AC-024-02, AC-024-03, AC-024-04, AC-024-05, AC-024-06, AC-024-07, AC-024-08, AC-024-09, AC-024-10, AC-024-11, AC-024-12, AC-024-13, AC-024-14 | TC-026-001, TC-026-027, TC-026-002, TC-026-003, TC-026-004, TC-026-006, TC-026-007, TC-026-009, TC-026-010, TC-026-011, TC-026-005, TC-026-008, TC-026-012, TC-026-013, TC-026-014, TC-026-015, TC-026-016, TC-026-017, TC-026-018, TC-026-019, TC-026-020, TC-026-021, TC-026-022, TC-026-023, TC-026-024, TC-026-025, TC-026-026 | pass | met |
| REQ-018 | Past daily counts kept in line with silver on every run | - | TC-026-002, TC-026-003, TC-026-004, TC-026-005, TC-026-006, TC-026-007, TC-026-008, TC-026-009, TC-026-010, TC-026-011, TC-026-012, TC-026-016, TC-026-017, TC-026-018, TC-026-019, TC-026-021, TC-026-022, TC-026-024 | pass | met |
| REQ-019 | Adjustment history of daily counts | - | TC-026-002, TC-026-003, TC-026-004, TC-026-005, TC-026-006, TC-026-007, TC-026-008, TC-026-009, TC-026-010, TC-026-011, TC-026-012, TC-026-020, TC-026-021, TC-026-022, TC-026-024, TC-026-025, TC-026-027 | pass | met |

## Review flags

- deviation: Withdrawing a snapshot only covers contacts that already have one. A contact that is new in a run has no snapshot rows to remove. So in the first batch transaction, each new contact (no basis row yet) gets a header-only row in etl_daily_count_applied_contact, with its current profile. This puts the snapshot out of step (the 'reverse' case of the design's rule). Without it, a run that only adds contacts, commits a batch and then fails would leave the snapshot in step, and the next normal run would count those contacts a second time on the committed dates. With it, RULE-149 holds: the next run takes the full-recompute path. The final transaction replaces these header-only rows. The design describes this step only as withdrawing rows. test_MOD026_dev covers the case.
- deviation: When the full-recompute path brings the snapshot into line, it rewrites only the contacts the run applied (changed, new or removed) and the contacts that were out of step. It does not rewrite every contact. For every other contact the basis and the snapshot already describe the same inputs, because both are only ever written together in the final transaction. So after a @FullRebuild with no input change, every snapshot row keeps the run_id that first wrote it (test_MOD026_dev covers this).
- handover documentation deferred to the handover (po.py handover)

Sources: docs/specs/SPEC-001.json, docs/design/MP-001.json, docs/test/TCS-MOD-026.json, docs/dev/CN-MOD-026.json, docs/test/TR-MOD-026-1.json
