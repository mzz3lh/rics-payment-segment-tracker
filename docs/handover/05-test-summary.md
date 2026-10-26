# Test summary: RICS Payment Segment Tracker

## Test approach

Each module is tested against test conditions (TC-nnn-nnn) designed from the approved specification and design, each tied to an acceptance criterion. The tests are automated tSQLt tests. They run on synthetic data only, in a test database rebuilt clean for each test run, with the external sources replaced by fakes holding the test data. The tSQLt framework and its test schemas exist only in the development and test databases and are never deployed further. Real-data checks are done separately by a person, using the count-only queries.

The MOD-001 test conditions were approved on 2026-10-25. They cover normal cases, rows that must be left out, and duplicates (one invoice number on two accounts; several rows for one contact).

<!-- evidence: docs/test/TCS-MOD-001.json#TCS-MOD-001; docs/test/TCS-MOD-001.json#test_design_review; docs/setup/ENVIRONMENTS.md#Rebuilt clean from `main` + the module commit for each test run; docs/setup/ENVIRONMENTS.md#tSQLt and the `test_*` schemas exist in dev and test only; docs/specs/SPEC-001.json#Real-data steps, which are done by a human -->

## Results by module

| Module | Test run | Conditions | Passed | Failed | Skipped | Verdict |
|---|---|---|---|---|---|---|
| MOD-001 Source profiling queries | 2026-10-25, test environment | 5 | 5 | 0 | 0 | Pass |

MOD-001 passed on its first test run, with no defects found. REQ-014 is met for the two acceptance criteria this module covers (AC-014-07 and AC-014-08). Four further unit tests, covering rows with missing values and an empty source, also passed.

<!-- evidence: docs/test/TR-MOD-001-1.json#TR-MOD-001-1; docs/test/TR-MOD-001-1.json#"verdict": "pass"; docs/test/TR-MOD-001-1.json#REQ-014; docs/dev/CN-MOD-001.json#test_MOD001_dev -->

## Traceability

| Requirement | Acceptance criterion | Test condition | What it checks | Result |
|---|---|---|---|---|
| REQ-014 | AC-014-07 | TC-001-001 | The grain profile counts invoices by number of rows, number of different item codes and whether they have a 'Sales tax' row | Passed |
| REQ-014 | AC-014-07 | TC-001-002 | The grain profile leaves out transaction types 8 and 24 and invoice numbers containing 'CRE' or 'FTCN' | Passed |
| REQ-014 | AC-014-07 | TC-001-003 | One invoice number on two accounts counts as two invoices | Passed |
| REQ-014 | AC-014-08 | TC-001-004 | The corporate status profile counts rows by 'Sub Status' and by 'Sub User Status' | Passed |
| REQ-014 | AC-014-08 | TC-001-005 | The status profile counts source rows, not contacts, and lists every status value it finds | Passed |

<!-- evidence: docs/test/TCS-MOD-001.json#TC-001-001; docs/test/TCS-MOD-001.json#TC-001-002; docs/test/TCS-MOD-001.json#TC-001-003; docs/test/TCS-MOD-001.json#TC-001-004; docs/test/TCS-MOD-001.json#TC-001-005; docs/test/TR-MOD-001-1.json#TC-001-005 -->
