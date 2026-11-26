# Traceability: MOD-030

Checked by the Product Owner before the pre-merge review: requirement, acceptance criteria, test conditions, latest results.

**Result:** no gaps; 4 review flag(s).

| Requirement | Title | Acceptance criteria | Test conditions | Results | Status |
|---|---|---|---|---|---|
| REQ-027 | Member country and region by local group | AC-027-12 | TC-030-001, TC-030-002, TC-030-003, TC-030-004, TC-030-005, TC-030-006, TC-030-007, TC-030-008, TC-030-009, TC-030-010, TC-030-011, TC-030-012, TC-030-013, TC-030-014, TC-030-015, TC-030-016, TC-030-017, TC-030-018, TC-030-019, TC-030-020, TC-030-021, TC-030-022, TC-030-023, TC-030-024, TC-030-025, TC-030-026, TC-030-027, TC-030-028 | pass | met |

## Review flags

- deviation: Question deferred (asked 2026-11-26): MP-001/DES-001 say MOD-030's down script removes the dim_country rows the changed usp_load_dim_country adds (ids from 1000001). Those rows are written by the load, not the migration, and the migration builder can only put a DELETE in a down script through a seed (needs an up INSERT) or a table change (would need a dummy up statement). Assumption built on: the rollback leaves those rows in dim_country. They are harmless: the restored Phase 1 dim_country load only touches silv_ref_country ids, and no fact references a combination id while only MIG-0032 is applied (the gold loads that point country_id at them come in MOD-031/MOD-032). To remove them after a rollback: DELETE FROM Layercake.dim_country WHERE id >= 1000001.
- deviation: dim_local_group is not seeded by the migration. Its two reserved rows (-2 Not applicable, 0 Unknown) are copied from the seeded silv_ref_local_group by usp_load_dim_local_group on the first gold run, as the other gold dimensions over seeded lists are (answers.md, MOD-003 dim_payment_method population). After MIG-0032 alone, dim_local_group is empty until usp_load_gold or usp_load_dim_local_group runs.
- deviation: Grant script src/sql/grants/MOD-030.sql uses the placeholder role [<reporting_role>], as MOD-021 did: DES-001 names 'the existing reporting role that reads fact_membership_events' but not its name. A human replaces it and runs the script.
- handover documentation deferred to the handover (po.py handover)

Sources: docs/specs/SPEC-001.json, docs/design/MP-001.json, docs/test/TCS-MOD-030.json, docs/dev/CN-MOD-030.json, docs/test/TR-MOD-030-1.json
