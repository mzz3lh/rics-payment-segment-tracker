# Test summary: RICS Payment Segment Tracker

## Test approach

Each module is tested against test conditions (TC-nnn-nnn) designed from the approved specification and design, each tied to an acceptance criterion. The tests are automated tSQLt tests. They run on synthetic data only, in a test database rebuilt clean for each test run, with the external sources replaced by fakes holding the test data. The tSQLt framework and its test schemas exist only in the development and test databases and are never deployed further. Real-data checks are done separately by a person, using the count-only queries.

The MOD-001 test conditions were approved on 2026-10-25. They cover normal cases, rows that must be left out, and duplicates (one invoice number on two accounts; several rows for one contact).

The MOD-002 test conditions were approved on 2026-10-26. They cover first loads, missing and blank values, reruns on unchanged data, changed, removed and reappearing source rows, which transaction rows are in scope, the row-count check, and loads that fail part-way.

The MOD-003 test conditions were approved on 2026-10-26. They check the payment method list as deployed (its eight rows, exact labels and source codes, and no Mixed value); the mapping of known, missing, unknown and differently written codes; and the dimension load's first run, rerun, additions, name changes (including changes only in letter case), a failed run, and a match with the deployed list.

<!-- evidence: docs/test/TCS-MOD-001.json#TCS-MOD-001; docs/test/TCS-MOD-001.json#test_design_review; docs/test/TCS-MOD-002.json#TCS-MOD-002; docs/test/TCS-MOD-002.json#test_design_review; docs/test/TCS-MOD-002.json#idempotency; docs/test/TCS-MOD-002.json#reconciliation; docs/test/TCS-MOD-003.json#TCS-MOD-003; docs/test/TCS-MOD-003.json#2026-10-26T14:57:38Z; docs/test/TCS-MOD-003.json#boundary; docs/test/TCS-MOD-003.json#idempotency; docs/setup/ENVIRONMENTS.md#Rebuilt clean from `main` + the module commit for each test run; docs/setup/ENVIRONMENTS.md#tSQLt and the `test_*` schemas exist in dev and test only; docs/specs/SPEC-001.json#Real-data steps, which are done by a human -->

## Results by module

| Module | Test run | Conditions | Passed | Failed | Skipped | Verdict |
|---|---|---|---|---|---|---|
| MOD-001 Source profiling queries | 2026-10-25, test environment | 5 | 5 | 0 | 0 | Pass |
| MOD-002 Subscription invoice bronze | 2026-10-26, test environment | 19 | 19 | 0 | 0 | Pass |
| MOD-003 Payment method reference and dimension | 2026-10-26, test environment | 13 | 13 | 0 | 0 | Pass |

MOD-001 passed on its first test run, with no defects found. REQ-014 is met for the two acceptance criteria this module covers (AC-014-07 and AC-014-08). Four further unit tests, covering rows with missing values and an empty source, also passed.

MOD-002 passed on its first test run, with no defects found. REQ-002 is met. Ten further unit tests also passed, covering among other things the 'N/A' value in the fully-credited column, changes only in letter case or trailing spaces, transaction dates to the millisecond, a 50-character order number, and a load that fails on a duplicate row key in the source.

MOD-003 passed on its first test run, with no defects found. REQ-003 is met for the five acceptance criteria this module covers (AC-003-01 to AC-003-05). Six further unit tests also passed, covering that the mapping reads the codes from the list and never returns a reserved row, that only spaces are trimmed from a code, a name change only in trailing spaces, a dimension row whose id has left the list, a failed run undoing a name update it had already made, how load_id and the created and updated times are set, and a load log entry number too large for a standard whole number.

<!-- evidence: docs/test/TR-MOD-001-1.json#TR-MOD-001-1; docs/test/TR-MOD-001-1.json#"verdict": "pass"; docs/test/TR-MOD-001-1.json#REQ-014; docs/dev/CN-MOD-001.json#test_MOD001_dev; docs/test/TR-MOD-002-1.json#TR-MOD-002-1; docs/test/TR-MOD-002-1.json#"verdict": "pass"; docs/test/TR-MOD-002-1.json#"status": "met"; docs/dev/CN-MOD-002.json#test_MOD002_dev; docs/dev/CN-MOD-002.json#10 unit test(s); docs/test/TR-MOD-003-1.json#TR-MOD-003-1; docs/test/TR-MOD-003-1.json#2026-10-26T15:52:17Z; docs/test/TR-MOD-003-1.json#"verdict": "pass"; docs/test/TR-MOD-003-1.json#"status": "met"; docs/design/MP-001.json#AC-003-05; docs/dev/CN-MOD-003.json#test_MOD003_dev; docs/dev/CN-MOD-003.json#6 unit test(s); docs/dev/CN-MOD-003.json#stores a log_id beyond the int range in load_id -->

## Traceability

| Requirement | Acceptance criterion | Test condition | What it checks | Result |
|---|---|---|---|---|
| REQ-002 | AC-002-01 | TC-002-001 | The first invoice load lands 5 source invoices one-to-one, all live, with every column equal to the source | Passed |
| REQ-002 | AC-002-03 | TC-002-002 | A missing invoice payment method lands as missing, with no default | Passed |
| REQ-002 | AC-002-03 | TC-002-003 | Blank and untrimmed lower-case payment methods land exactly as in the source | Passed |
| REQ-002 | AC-002-04 | TC-002-004 | The first invoice load logs 'Success' with 5 rows inserted | Passed |
| REQ-002 | AC-002-04 | TC-002-005 | A second invoice load on unchanged data changes nothing and logs 0 inserted and 0 updated | Passed |
| REQ-002 | AC-002-05 | TC-002-006 | Every landed invoice row has _loaded_at and _updated_at set | Passed |
| REQ-002 | AC-002-04 | TC-002-007 | A changed invoice is updated in place, only it gets a new _updated_at, and the update is counted | Passed |
| REQ-002 | AC-002-01 | TC-002-008 | An invoice no longer in the source is marked as deleted, not removed | Passed |
| REQ-002 | AC-002-01 | TC-002-009 | A deleted invoice that the source sends again is made live again, not added twice | Passed |
| REQ-002 | AC-002-04 | TC-002-010 | An invoice load that fails on an amount too large for the table reports the error, logs 'Failed' and leaves the table unchanged | Passed |
| REQ-002 | AC-002-04 | TC-002-019 | After inserts and a deletion, live invoice rows equal the source row count, and the counts are logged | Passed |
| REQ-002 | AC-002-02 | TC-002-011 | The first line load lands 12 in-scope transaction rows one-to-one, all live, with every column equal to the source | Passed |
| REQ-002 | AC-002-06 | TC-002-012 | Only an invoice's own lines and the rows settling it are landed; rows of a voucher not in Subs.tblSubsInvoices are not | Passed |
| REQ-002 | AC-002-06 | TC-002-013 | A row with the invoice's voucher but on another account is not landed | Passed |
| REQ-002 | AC-002-06 | TC-002-014 | A row matching on both voucher and last settlement voucher is landed once | Passed |
| REQ-002 | AC-002-06 | TC-002-015 | A line whose invoice leaves Subs.tblSubsInvoices is marked as deleted | Passed |
| REQ-002 | AC-002-02 | TC-002-016 | The line load logs like the invoice load, and a second run on unchanged data changes nothing | Passed |
| REQ-002 | AC-002-05 | TC-002-017 | Every landed line row has _loaded_at and _updated_at set | Passed |
| REQ-002 | AC-002-02 | TC-002-018 | A line load that fails part-way through its writes reports the error, logs 'Failed' and leaves the table unchanged | Passed |
| REQ-003 | AC-003-01 | TC-003-001 | The deployed payment method list holds exactly the three reserved rows at their fixed ids and the five methods on ids 1 to 5, with exact labels | Passed |
| REQ-003 | AC-003-01 | TC-003-002 | The deployed payment method list has no Mixed value (assumed, Q-015) | Passed |
| REQ-003 | AC-003-02 | TC-003-003 | The codes DD, Card, Bank, Cheque and Corporate map to their methods, and a missing or empty code to Unknown | Passed |
| REQ-003 | AC-003-02 | TC-003-004 | Each of the five methods carries the source code it maps from | Passed |
| REQ-003 | AC-003-03 | TC-003-005 | The code 'XYZ' maps to Unrecognised, not Unknown | Passed |
| REQ-003 | AC-003-03 | TC-003-006 | Method names used as codes, partial or extended codes, 'Mixed' and a reserved label map to Unrecognised | Passed |
| REQ-003 | AC-003-02 | TC-003-013 | Codes that differ only in letter case or surrounding spaces map to their method, and a code of spaces only maps to Unknown | Passed |
| REQ-003 | AC-003-05 | TC-003-007 | The first dimension load copies all eight ids and names, reserved rows included, and logs 'Success' with 8 rows inserted | Passed |
| REQ-003 | AC-003-04 | TC-003-008 | A second dimension load keeps every name on the same id and changes nothing | Passed |
| REQ-003 | AC-003-05 | TC-003-009 | The dimension load adds missing ids, corrects a changed name on its existing id and leaves unchanged rows untouched | Passed |
| REQ-003 | AC-003-05 | TC-003-010 | A dimension name that differs from the list only in letter case is corrected | Passed |
| REQ-003 | AC-003-05 | TC-003-011 | A dimension load that fails on a rejected row reports the error, logs 'Failed' and leaves the dimension unchanged | Passed |
| REQ-003 | AC-003-05 | TC-003-012 | Loaded from the deployed list, the dimension has the same rows, ids and names as the list | Passed |
| REQ-014 | AC-014-07 | TC-001-001 | The grain profile counts invoices by number of rows, number of different item codes and whether they have a 'Sales tax' row | Passed |
| REQ-014 | AC-014-07 | TC-001-002 | The grain profile leaves out transaction types 8 and 24 and invoice numbers containing 'CRE' or 'FTCN' | Passed |
| REQ-014 | AC-014-07 | TC-001-003 | One invoice number on two accounts counts as two invoices | Passed |
| REQ-014 | AC-014-08 | TC-001-004 | The corporate status profile counts rows by 'Sub Status' and by 'Sub User Status' | Passed |
| REQ-014 | AC-014-08 | TC-001-005 | The status profile counts source rows, not contacts, and lists every status value it finds | Passed |

<!-- evidence: docs/test/TCS-MOD-002.json#TC-002-001; docs/test/TCS-MOD-002.json#TC-002-002; docs/test/TCS-MOD-002.json#TC-002-003; docs/test/TCS-MOD-002.json#TC-002-004; docs/test/TCS-MOD-002.json#TC-002-005; docs/test/TCS-MOD-002.json#TC-002-006; docs/test/TCS-MOD-002.json#TC-002-007; docs/test/TCS-MOD-002.json#TC-002-008; docs/test/TCS-MOD-002.json#TC-002-009; docs/test/TCS-MOD-002.json#TC-002-010; docs/test/TCS-MOD-002.json#TC-002-019; docs/test/TCS-MOD-002.json#TC-002-011; docs/test/TCS-MOD-002.json#TC-002-012; docs/test/TCS-MOD-002.json#TC-002-013; docs/test/TCS-MOD-002.json#TC-002-014; docs/test/TCS-MOD-002.json#TC-002-015; docs/test/TCS-MOD-002.json#TC-002-016; docs/test/TCS-MOD-002.json#TC-002-017; docs/test/TCS-MOD-002.json#TC-002-018; docs/test/TR-MOD-002-1.json#TC-002-018; docs/test/TCS-MOD-003.json#TC-003-001; docs/test/TCS-MOD-003.json#TC-003-002; docs/test/TCS-MOD-003.json#TC-003-003; docs/test/TCS-MOD-003.json#TC-003-004; docs/test/TCS-MOD-003.json#TC-003-005; docs/test/TCS-MOD-003.json#TC-003-006; docs/test/TCS-MOD-003.json#TC-003-013; docs/test/TCS-MOD-003.json#TC-003-007; docs/test/TCS-MOD-003.json#TC-003-008; docs/test/TCS-MOD-003.json#TC-003-009; docs/test/TCS-MOD-003.json#TC-003-010; docs/test/TCS-MOD-003.json#TC-003-011; docs/test/TCS-MOD-003.json#TC-003-012; docs/test/TR-MOD-003-1.json#TC-003-001; docs/test/TR-MOD-003-1.json#TC-003-013; docs/test/TCS-MOD-001.json#TC-001-001; docs/test/TCS-MOD-001.json#TC-001-002; docs/test/TCS-MOD-001.json#TC-001-003; docs/test/TCS-MOD-001.json#TC-001-004; docs/test/TCS-MOD-001.json#TC-001-005; docs/test/TR-MOD-001-1.json#TC-001-005 -->
