# Traceability: MOD-028

Checked by the Product Owner before the pre-merge review: requirement, acceptance criteria, test conditions, latest results.

**Result:** no gaps; 4 review flag(s).

| Requirement | Title | Acceptance criteria | Test conditions | Results | Status |
|---|---|---|---|---|---|
| REQ-026 | Payment method, payer type and concession in the daily member counts | AC-026-01, AC-026-02, AC-026-03, AC-026-04, AC-026-05, AC-026-06, AC-026-07, AC-026-08, AC-026-12, AC-026-15, AC-026-17, AC-026-18, AC-026-19, AC-026-22 | TC-028-001, TC-028-002, TC-028-003, TC-028-004, TC-028-023, TC-028-024, TC-028-005, TC-028-006, TC-028-007, TC-028-008, TC-028-009, TC-028-010, TC-028-011, TC-028-012, TC-028-013, TC-028-014, TC-028-015, TC-028-016, TC-028-017, TC-028-018, TC-028-019, TC-028-020, TC-028-021, TC-028-022, TC-028-025, TC-028-026 | pass | met |
| REQ-019 | Adjustment history of daily counts | - | TC-028-002, TC-028-014, TC-028-015, TC-028-019, TC-028-020, TC-028-021, TC-028-023, TC-028-026 | pass | met |
| REQ-020 | Daily counts as known at any time, and adjustments review | - | TC-028-002, TC-028-004, TC-028-022, TC-028-024 | pass | met |
| REQ-024 | Daily count recomputes only the contacts that changed | - | TC-028-002, TC-028-013, TC-028-014, TC-028-015, TC-028-019, TC-028-021, TC-028-026 | pass | met |
| REQ-025 | Gold daily fact synced cell by cell | - | TC-028-003, TC-028-016, TC-028-017, TC-028-018 | pass | met |

## Review flags

- deviation: DEF-007 is only partly fixed. The three failing tests are in tests/tsqlt/test_MOD027_dev.sql, an earlier module's Developer test file. No Developer tool can write that file: write_unit_tests only replaces this module's file, test_MOD028_dev.sql. I asked the owner how the fix should reach the branch. The answer was deferred. Working assumption: copies of the three tests, amended as the defect asks (payment_method_id, payer_type_id, concession_type_id = 0 on every silv_daily_count_detail and fact_daily_member_count_detail row and column list, nothing else changed), are added to test_MOD028_dev so the behaviour is proven at the new grain on this branch. Someone else (a human, or the framework) still has to make the same edit in test_MOD027_dev.sql, or delete those three tests from it. Until then the test_MOD027_dev regression run still fails with 515 on #det_stage. No procedure code was changed.
- deviation: DEF-007: tests/tsqlt/test_MOD027_dev.sql amended by a human (Mike) at a5bf3a37e8d3178a401fd0e4034b288c37b1150b: segment ids = 0 in three tests' inserts; no procedure change.
- assumptions the Product Owner made for MOD-028: ASM-015 (docs/assumptions.md)
- handover documentation deferred to the handover (po.py handover)

Sources: docs/specs/SPEC-001.json, docs/design/MP-001.json, docs/test/TCS-MOD-028.json, docs/dev/CN-MOD-028.json, docs/test/TR-MOD-028-3.json
