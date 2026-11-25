# Traceability: MOD-029

Checked by the Product Owner before the pre-merge review: requirement, acceptance criteria, test conditions, latest results.

**Result:** no gaps; 5 review flag(s).

| Requirement | Title | Acceptance criteria | Test conditions | Results | Status |
|---|---|---|---|---|---|
| REQ-026 | Payment method, payer type and concession in the daily member counts | AC-026-09, AC-026-10, AC-026-11, AC-026-13, AC-026-14, AC-026-16, AC-026-20, AC-026-21 | TC-029-001, TC-029-002, TC-029-003, TC-029-013, TC-029-014, TC-029-015, TC-029-016, TC-029-017, TC-029-018, TC-029-004, TC-029-005, TC-029-006, TC-029-007, TC-029-008, TC-029-009, TC-029-010, TC-029-011, TC-029-012, TC-029-019, TC-029-020 | pass | met |
| REQ-021 | Payment and invoice segments in the normal daily load | - | TC-029-001, TC-029-008, TC-029-009, TC-029-010, TC-029-014 | pass | met |

## Review flags

- deviation: Check D2 of reference/phase1/Scripts/Reconciliation/pipeline-reconciliation-report.sql was not changed, and that script, active-member-difference.sql and paid-member-difference.sql were not run. The Developer's tools cannot edit files under reference/ or run SQLCMD scripts. I asked the owner (deferred). Assumption, following ASM-009: these become listed handover steps for a human. (1) Add payment_method_id, payer_type_id and concession_type_id to D2's expected star, taken from silv_daily_count_detail, and to its join and grouping with fact_daily_member_count_detail. (2) After one usp_run_daily_load on the synthetic data, run the three scripts and record the RS-1 and D2 verdicts. Until (1) is done, D2 will report differences against the 8-column fact.
- deviation: usp_run_daily_load passes only its @FullRebuild to usp_load_silv_daily_count. DES-001 says 'the run's @FullRebuild and @RebuildFrom', but usp_run_daily_load has no @RebuildFrom parameter, and the design keeps its parameters unchanged. So @RebuildFrom keeps its default (NULL), and @DailyCountBatchDays and @DetailBatchDays keep their defaults (31), the same values the silver and gold steps passed before.
- deviation: DEF-008: tests/tsqlt/test_MOD023_dev.sql amended by a human (Mike) at febea017cd537e917a555128b32566a9a6bdddbd: SetUp also spies usp_load_silv_daily_count and usp_load_fact_daily_member_count_detail, the test expects 6 calls and is renamed for the new run order; no procedure change. Check D2 of reference/phase1/Scripts/Reconciliation/pipeline-reconciliation-report.sql was amended by a human (Mike) at 6474dd6 (AC-026-20).
- assumptions the Product Owner made for MOD-029: ASM-016 (docs/assumptions.md)
- handover documentation deferred to the handover (po.py handover)

Sources: docs/specs/SPEC-001.json, docs/design/MP-001.json, docs/test/TCS-MOD-029.json, docs/dev/CN-MOD-029.json, docs/test/TR-MOD-029-3.json
