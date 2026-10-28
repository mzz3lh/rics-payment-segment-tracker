# Project Standards: RICS Payment Segment Tracker (RPST)

| | |
|---|---|
| Inherits | Agent team base standards v1.10 (`standards/BASE_STANDARDS.md` in the framework) |
| Owner | Product Owner agent; changes approved by a named human |
| Created | 2026-10-19 |

Every agent on this project reads the base standards **and** this document. The base standards apply in full except where section 2 records an approved project-specific decision. An agent that cannot comply with either raises it to the Product Owner rather than deviating.

## 1. Project facts

| | |
|---|---|
| Project code (artefact IDs, object names) | `RPST` |
| Dev database | `RPST_Dev` |
| Test database | `RPST_Test` |
| Agent logins | `rpst_agent_<role>` |
| Client / business owner | _to be completed at project set-up_ |
| Source systems | _to be completed by the Analyst_ |
| Repository | _to be completed_ |

## 2. Project-specific decisions and overrides

Only for things the base standards leave open or that the client requires differently (for example client naming rules, extra schemas, a different handover format). Each needs a named human's approval.

| ID | Base section | Decision | Reason | Approved by | Date |
|---|---|---|---|---|---|
| | | _none yet_ | | | |

## 3. Change log

| Date | Change | Approved by |
|---|---|---|
| 2026-10-19 | Project created from base standards v1.10 | pending |

## Existing solution (baseline)

This project extends an existing solution. Its deployable scripts were imported as the baseline migration
`MIG-0002_bootstrap_phase1-layercake` (object files under `src/sql/<schema>/`, other scripts under `src/sql/baseline/`).
Overrides of the base standards, so that new code matches the solution and nothing that reads it breaks:

- Schemas (2.1): `Layercake` only. Production admits objects in the existing `Layercake` schema only and the
  deploy login cannot create schemas, so no deployable script creates one (`create_schemas: false`): `MIG-0000`
  only checks that `Layercake` exists. In dev and test, `src/sql/setup/00_create_databases.sql` creates it.
  Mike, 2026-10-28.
- Deploy journal (3.1): in `Layercake`, named like the solution: `Layercake.migration_history`,
  `Layercake.vw_migration_state`, `Layercake.vw_database_version`, `Layercake.fn_migration_is_applied`,
  `Layercake.usp_record_migration` (and the dbt journal objects, unused while dbt is off). Phase 1's own
  `Layercake.schema_migration` is left to `Deploy-Database.ps1`. Mike, 2026-10-28 (card: New Layercake journal).
- Load audit (3): `MIG-0001` creates nothing in this project (no `audit` schema); it only records itself, so
  migration numbers match the framework's.
- Table names (2.1): `^[a-z][a-z0-9_]*$`.
- Column names (2.1): `^_?[a-z][a-z0-9_]*$`; the leading underscore is only for the standard bronze audit columns (`_loaded_at`, `_updated_at`, `_is_deleted`, `_deleted_at`), as in the Phase 1 bronze tables.
- Load logging (3): load procedures call `Layercake.usp_etl_log_start`, `Layercake.usp_etl_log_end` instead of the `audit` procedures.
- Changing an existing object: the Developer changes it in place (a table through its change scripts); the
  module's down script restores the previous definition (base standards 3.1).
- The baseline is not rolled back: a database goes back to before its baseline by restoring a backup.

## Objects owned by other systems (external)

The project reads objects it does not own: other systems load or maintain them. They are listed in
`docs/sources/external_catalogue.json` with their columns, and their definitions (identifying literals masked) are under
`docs/sources/external/`. Agents use them as sources and to understand the existing data, and never create, alter, drop
or write to them (base standards 3.3). A change one would need goes to its owner through a human. In CI and on
the local dev and test databases they exist only as the stand-ins in `src/sql/ci/external_standins.sql`.
