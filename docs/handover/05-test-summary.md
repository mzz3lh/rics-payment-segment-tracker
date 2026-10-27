# Test summary: RICS Payment Segment Tracker

## Test approach

Each module is tested against test conditions (TC-nnn-nnn) designed from the approved specification and design, each tied to an acceptance criterion. The tests are automated tSQLt tests. They run on synthetic data only, in a test database rebuilt clean for each test run, with the external sources replaced by fakes holding the test data. The tSQLt framework and its test schemas exist only in the development and test databases and are never deployed further. Real-data checks are done separately by a person, using the count-only queries.

The MOD-001 test conditions were approved on 2026-10-25. They cover normal cases, rows that must be left out, and duplicates (one invoice number on two accounts; several rows for one contact).

The MOD-002 test conditions were approved on 2026-10-26. They cover first loads, missing and blank values, reruns on unchanged data, changed, removed and reappearing source rows, which transaction rows are in scope, the row-count check, and loads that fail part-way.

The MOD-003 test conditions were approved on 2026-10-26. They check the payment method list as deployed (its eight rows, exact labels and source codes, and no Mixed value); the mapping of known, missing, unknown and differently written codes; and the dimension load's first run, rerun, additions, name changes (including changes only in letter case), a failed run, and a match with the deployed list.

The MOD-004 test conditions were approved on 2026-10-26. They check the payer type list as deployed (its five rows and exact labels); the payer type dimension load's first run, rerun, additions, name changes (including changes only in letter case), a failed run, and a match with the deployed list; and the corporate subscription load's first run, that 'Round' is neither landed nor treated as a change, missing, blank and differently written values, reruns on unchanged data, changed, removed and reappearing rows, how rows are matched, the row-count check, a failed load, and source rows with a missing contact number, scheme number or Campaign Year.

The MOD-005 test conditions were approved on 2026-10-27. They check the line-type mapping load's handling of new, repeated and already listed item codes; missing, blank and differently written codes and invoice types; lines marked as deleted; that hand mappings and other existing rows are never changed, end to end; reruns on unchanged data; the currency list and dimension loads' first run, rerun, additions and new ids, missing, blank and differently written currencies, and invoices marked as deleted; and a failed run of each of the three loads.

The MOD-006 test conditions were approved on 2026-10-27. They check the concession bronze load's first run, missing and untrimmed values, reruns on unchanged data, renamed, removed and reappearing types, the row-count check, and source rows with a missing or repeated concession type id; that the unused dual-membership column is not landed; the concession type list as deployed (the three reserved values and 'No concession'); the list load's additions, renames, new ids, item codes, full-concession and perpetual flags, types marked as deleted, types with no name, reruns and a failed run; the dimension load's first run, rerun, additions, corrections and a failed run; two end-to-end runs through all three loads; and that the reserved values carry the same ids and labels in the payment method, payer type and concession type lists.

<!-- evidence: docs/test/TCS-MOD-001.json#TCS-MOD-001; docs/test/TCS-MOD-001.json#test_design_review; docs/test/TCS-MOD-002.json#TCS-MOD-002; docs/test/TCS-MOD-002.json#test_design_review; docs/test/TCS-MOD-002.json#idempotency; docs/test/TCS-MOD-002.json#reconciliation; docs/test/TCS-MOD-003.json#TCS-MOD-003; docs/test/TCS-MOD-003.json#2026-10-26T14:57:38Z; docs/test/TCS-MOD-003.json#boundary; docs/test/TCS-MOD-003.json#idempotency; docs/test/TCS-MOD-004.json#TCS-MOD-004; docs/test/TCS-MOD-004.json#2026-10-26T17:10:05Z; docs/test/TCS-MOD-004.json#test_design_review; docs/test/TCS-MOD-004.json#TC-004-001; docs/test/TCS-MOD-004.json#TC-004-009; docs/test/TCS-MOD-004.json#TC-004-010; docs/test/TCS-MOD-004.json#TC-004-021; docs/test/TCS-MOD-005.json#TCS-MOD-005; docs/test/TCS-MOD-005.json#2026-10-27T09:57:57Z; docs/test/TCS-MOD-005.json#test_design_review; docs/test/TCS-MOD-005.json#duplicates; docs/test/TCS-MOD-005.json#nulls; docs/test/TCS-MOD-005.json#boundary; docs/test/TCS-MOD-005.json#idempotency; docs/test/TCS-MOD-005.json#negative; docs/test/TCS-MOD-006.json#TCS-MOD-006; docs/test/TCS-MOD-006.json#2026-10-27T12:03:09Z; docs/test/TCS-MOD-006.json#test_design_review; docs/test/TCS-MOD-006.json#TC-006-009; docs/test/TCS-MOD-006.json#TC-006-027; docs/test/TCS-MOD-006.json#TC-006-028; docs/test/TCS-MOD-006.json#TC-006-029; docs/setup/ENVIRONMENTS.md#Rebuilt clean from `main` + the module commit for each test run; docs/setup/ENVIRONMENTS.md#tSQLt and the `test_*` schemas exist in dev and test only; docs/specs/SPEC-001.json#Real-data steps, which are done by a human -->

## Results by module

| Module | Test run | Conditions | Passed | Failed | Skipped | Verdict |
|---|---|---|---|---|---|---|
| MOD-001 Source profiling queries | 2026-10-25, test environment | 5 | 5 | 0 | 0 | Pass |
| MOD-002 Subscription invoice bronze | 2026-10-26, test environment | 19 | 19 | 0 | 0 | Pass |
| MOD-003 Payment method reference and dimension | 2026-10-26, test environment | 13 | 13 | 0 | 0 | Pass |
| MOD-004 Corporate subscription bronze and payer type reference | 2026-10-26, test environment | 23 | 23 | 0 | 0 | Pass |
| MOD-005 Invoice line-type mapping and currency | 2026-10-27, test environment | 26 | 26 | 0 | 0 | Pass |
| MOD-006 Concession reference and dimension | 2026-10-27, test environment | 29 | 29 | 0 | 0 | Pass |

MOD-001 passed on its first test run, with no defects found. REQ-014 is met for the two acceptance criteria this module covers (AC-014-07 and AC-014-08). Four further unit tests, covering rows with missing values and an empty source, also passed.

MOD-002 passed on its first test run, with no defects found. REQ-002 is met. Ten further unit tests also passed, covering among other things the 'N/A' value in the fully-credited column, changes only in letter case or trailing spaces, transaction dates to the millisecond, a 50-character order number, and a load that fails on a duplicate row key in the source.

MOD-003 passed on its first test run, with no defects found. REQ-003 is met for the five acceptance criteria this module covers (AC-003-01 to AC-003-05). Six further unit tests also passed, covering that the mapping reads the codes from the list and never returns a reserved row, that only spaces are trimmed from a code, a name change only in trailing spaces, a dimension row whose id has left the list, a failed run undoing a name update it had already made, how load_id and the created and updated times are set, and a load log entry number too large for a standard whole number.

MOD-004 passed on its first test run, with no defects found. REQ-006 is met for the acceptance criterion this module covers (AC-006-01). Seven further unit tests also passed, covering a change only in letter case in the scheme number (updated in place), a change only in trailing spaces in the scheme name, a deleted row restored and counted as one update, an already deleted row that is still missing being left alone, a corporate subscription load that fails on two source rows with the same key and changes nothing, a payer type dimension row whose id has left the list, and how the dimension load sets load_id.

MOD-005 passed on its first test run, with no defects found. REQ-007 is met. Five further unit tests also passed, covering which spelling is kept when one new item code or currency arrives in several spellings in one run, that new rows carry the load log entry and equal created and updated times, a currency dimension code corrected when the list's code changes only in letter case, and a failed currency dimension run undoing a correction it had already made.

MOD-006 passed on its first test run, with no defects found. REQ-010 is met, and with AC-003-06 now passed, REQ-003 is met in full. Seven further unit tests also passed, covering a concession bronze load that fails on a missing or a repeated concession type id and changes nothing, a change only in trailing spaces and a restored row each counted as one update in the bronze table, an 'rcs' prefix removed in any letter case and only at the start, an over-long item code failing the concession type list load and changing nothing, deleted types and the starting rows being kept while a rename only in letter case is recorded with the load log entry, and a dimension row whose id has left the list being kept while a change only in a flag counts as one update.

<!-- evidence: docs/test/TR-MOD-001-1.json#TR-MOD-001-1; docs/test/TR-MOD-001-1.json#"verdict": "pass"; docs/test/TR-MOD-001-1.json#REQ-014; docs/dev/CN-MOD-001.json#test_MOD001_dev; docs/test/TR-MOD-002-1.json#TR-MOD-002-1; docs/test/TR-MOD-002-1.json#"verdict": "pass"; docs/test/TR-MOD-002-1.json#"status": "met"; docs/dev/CN-MOD-002.json#test_MOD002_dev; docs/dev/CN-MOD-002.json#10 unit test(s); docs/test/TR-MOD-003-1.json#TR-MOD-003-1; docs/test/TR-MOD-003-1.json#2026-10-26T15:52:17Z; docs/test/TR-MOD-003-1.json#"verdict": "pass"; docs/test/TR-MOD-003-1.json#"status": "met"; docs/design/MP-001.json#AC-003-05; docs/dev/CN-MOD-003.json#test_MOD003_dev; docs/dev/CN-MOD-003.json#6 unit test(s); docs/dev/CN-MOD-003.json#stores a log_id beyond the int range in load_id; docs/test/TR-MOD-004-1.json#TR-MOD-004-1; docs/test/TR-MOD-004-1.json#2026-10-26T17:14:00Z; docs/test/TR-MOD-004-1.json#"verdict": "pass"; docs/test/TR-MOD-004-1.json#"status": "met"; docs/design/MP-001.json#AC-006-01; docs/dev/CN-MOD-004.json#test_MOD004_dev; docs/dev/CN-MOD-004.json#7 unit test(s); docs/dev/CN-MOD-004.json#test case only change in scheme no updates the row in place; docs/dev/CN-MOD-004.json#test trailing space change in scheme name is landed; docs/dev/CN-MOD-004.json#test restored soft deleted row clears deleted at and is logged as one update; docs/dev/CN-MOD-004.json#test already soft deleted row still absent is not touched or counted; docs/dev/CN-MOD-004.json#test duplicate source key fails the corporate subscription load with 2627 and changes nothing; docs/dev/CN-MOD-004.json#test dimension load keeps an id no longer in silver; docs/dev/CN-MOD-004.json#test dimension load stamps load_id with the log id and lands a trailing space change; docs/test/TR-MOD-005-1.json#TR-MOD-005-1; docs/test/TR-MOD-005-1.json#2026-10-27T10:03:34Z; docs/test/TR-MOD-005-1.json#"verdict": "pass"; docs/test/TR-MOD-005-1.json#"status": "met"; docs/dev/CN-MOD-005.json#test_MOD005_dev; docs/dev/CN-MOD-005.json#5 unit test(s); docs/dev/CN-MOD-005.json#test currency spellings of one new code keep the upper case spelling and the load log id; docs/dev/CN-MOD-005.json#test line type spellings of one new pair keep the upper case and shortest spelling; docs/dev/CN-MOD-005.json#test new line type rows carry the load log id and equal created and updated times; docs/dev/CN-MOD-005.json#test dim_currency takes a case only change of a silver code as one update; docs/dev/CN-MOD-005.json#test failed dim_currency insert also rolls back the update made before it; docs/test/TR-MOD-006-1.json#TR-MOD-006-1; docs/test/TR-MOD-006-1.json#2026-10-27T13:43:58Z; docs/test/TR-MOD-006-1.json#"verdict": "pass"; docs/test/TR-MOD-006-1.json#"status": "met"; docs/dev/CN-MOD-006.json#test_MOD006_dev; docs/dev/CN-MOD-006.json#7 unit test(s); docs/dev/CN-MOD-006.json#test duplicate source key fails the concession bronze load with 2627 and changes nothing; docs/dev/CN-MOD-006.json#test null source key fails the concession bronze load with 515 and changes nothing; docs/dev/CN-MOD-006.json#test trailing space change and restore are each one update in bronze; docs/dev/CN-MOD-006.json#test rcs prefix is removed in any case and only at the start; docs/dev/CN-MOD-006.json#test over long item code fails the concession type load and changes nothing; docs/dev/CN-MOD-006.json#test soft deleted type and seeded rows are kept and a case only rename is stamped with the log id; docs/dev/CN-MOD-006.json#test dimension keeps an id no longer in silver and counts a flag only change as one update -->

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
| REQ-003 | AC-003-06 | TC-006-029 | The reserved ids 0, -1 and -2 carry the same three labels in the deployed payment method, payer type and concession type lists | Passed |
| REQ-006 | AC-006-01 | TC-004-001 | The deployed payer type list holds exactly the three reserved rows at their fixed ids, and Individual and Corporate on ids 1 and 2, with exact labels | Passed |
| REQ-006 | AC-006-01 | TC-004-002 | The first payer type dimension load copies all five ids and names, reserved rows included, and logs 'Success' with 5 rows inserted | Passed |
| REQ-006 | AC-006-01 | TC-004-003 | A second payer type dimension load keeps every id and changes nothing | Passed |
| REQ-006 | AC-006-01 | TC-004-004 | The payer type dimension load adds a missing id, corrects a changed name on its existing id and leaves unchanged rows untouched | Passed |
| REQ-006 | AC-006-01 | TC-004-005 | A payer type dimension name that differs from the list only in letter case is corrected | Passed |
| REQ-006 | AC-006-01 | TC-004-006 | A payer type dimension load that fails on a rejected row reports the error, logs 'Failed' and leaves the dimension unchanged | Passed |
| REQ-006 | AC-006-01 | TC-004-007 | Loaded from the deployed list, the payer type dimension has the same five ids and names as the list | Passed |
| REQ-006 | AC-006-01 | TC-004-008 | The first corporate subscription load lands 4 source rows one-to-one, all live, and logs 'Success' with 4 rows inserted | Passed |
| REQ-006 | AC-006-01 | TC-004-009 | The corporate subscription table has no Round column | Passed |
| REQ-006 | AC-006-01 | TC-004-010 | A source row that differs from the landed row only in Round is not treated as a change | Passed |
| REQ-006 | AC-006-01 | TC-004-011 | A missing scheme name, Sub Status or Sub User Status lands as missing, with no default | Passed |
| REQ-006 | AC-006-01 | TC-004-012 | A blank scheme name and untrimmed or differently cased statuses land exactly as in the source | Passed |
| REQ-006 | AC-006-01 | TC-004-013 | A second corporate subscription load on unchanged data changes nothing | Passed |
| REQ-006 | AC-006-01 | TC-004-014 | A changed corporate subscription row is updated, and only it gets a new _updated_at | Passed |
| REQ-006 | AC-006-01 | TC-004-015 | A status change only in letter case is landed as a change | Passed |
| REQ-006 | AC-006-01 | TC-004-016 | A corporate subscription row gone from the source is marked as deleted, not removed | Passed |
| REQ-006 | AC-006-01 | TC-004-017 | A deleted corporate subscription row that reappears unchanged is made live again | Passed |
| REQ-006 | AC-006-01 | TC-004-018 | Rows are matched on contact, scheme and Campaign Year: a name change updates the row, and a new year or scheme adds a row | Passed |
| REQ-006 | AC-006-01 | TC-004-019 | After inserts and a deletion, live corporate subscription rows equal the source row count | Passed |
| REQ-006 | AC-006-01 | TC-004-020 | A corporate subscription load that fails on a rejected row reports the error, logs 'Failed' and leaves the table unchanged | Passed |
| REQ-006 | AC-006-01 | TC-004-021 | A source row with a missing contact number fails the load, which changes nothing | Passed |
| REQ-006 | AC-006-01 | TC-004-022 | A source row with a missing scheme number fails the load, which changes nothing | Passed |
| REQ-006 | AC-006-01 | TC-004-023 | A source row with a missing Campaign Year fails the load, which changes nothing | Passed |
| REQ-007 | AC-007-01 | TC-005-001 | A line with the new item code NEWFEE adds one 'unmapped' row, and a pair already listed is not added again | Passed |
| REQ-007 | AC-007-01 | TC-005-002 | A second line-type load on unchanged data leaves exactly one NEWFEE row and changes nothing | Passed |
| REQ-007 | AC-007-01 | TC-005-003 | A code repeated on many lines adds one row per item code and RIC invoice type pair | Passed |
| REQ-007 | AC-007-01 | TC-005-004 | Two new codes in one load that differ only in letter case add a single 'unmapped' row | Passed |
| REQ-007 | AC-007-01 | TC-005-005 | Lines with a missing, empty or blank item code add no mapping row | Passed |
| REQ-007 | AC-007-01 | TC-005-006 | A missing RIC invoice type is added as an empty type, and matches a listed pair with an empty type | Passed |
| REQ-007 | AC-007-01 | TC-005-007 | A code seen only on a line marked as deleted adds no mapping row | Passed |
| REQ-007 | AC-007-01 | TC-005-008 | Codes that differ from a listed pair only in letter case or trailing spaces add no row | Passed |
| REQ-007 | AC-007-01 | TC-005-009 | A code with a leading space or other characters is a new 'unmapped' code | Passed |
| REQ-007 | AC-007-02 | TC-005-010 | A code mapped by hand to 'readmission fee' keeps its line type after the next load | Passed |
| REQ-007 | AC-007-02 | TC-005-011 | A line that differs from a hand-mapped pair only in letter case or trailing spaces leaves that pair unchanged | Passed |
| REQ-007 | AC-007-02 | TC-005-012 | Existing rows, including those with no live line, are kept unchanged while a new code is added | Passed |
| REQ-007 | AC-007-02 | TC-005-013 | NEWFEE, added as 'unmapped' and then mapped by hand, stays 'readmission fee' after the next load | Passed |
| REQ-007 | AC-007-01 | TC-005-014 | A failed line-type load reports the error, logs 'Failed' and leaves the mapping unchanged | Passed |
| REQ-007 | AC-007-03 | TC-005-015 | Invoices in GBP, EUR and HKD give exactly those three currency codes | Passed |
| REQ-007 | AC-007-03 | TC-005-016 | A second currency load keeps every id and changes nothing | Passed |
| REQ-007 | AC-007-03 | TC-005-017 | Loaded after the currency list, the currency dimension has the same id and code pairs | Passed |
| REQ-007 | AC-007-03 | TC-005-018 | A second currency dimension load keeps every pair and changes nothing | Passed |
| REQ-007 | AC-007-03 | TC-005-019 | The currency dimension load adds missing ids and leaves an existing row untouched | Passed |
| REQ-007 | AC-007-03 | TC-005-020 | Invoices with a missing, empty or blank currency add no currency row | Passed |
| REQ-007 | AC-007-03 | TC-005-021 | A currency that differs from a listed code only in letter case adds no row | Passed |
| REQ-007 | AC-007-03 | TC-005-022 | A currency seen only on an invoice marked as deleted adds no row | Passed |
| REQ-007 | AC-007-03 | TC-005-023 | A new currency gets a new id, and listed currencies keep theirs | Passed |
| REQ-007 | AC-007-03 | TC-005-024 | A new currency arriving in several letter cases in one load adds a single row | Passed |
| REQ-007 | AC-007-03 | TC-005-025 | A failed currency load reports the error, logs 'Failed' and leaves the currency list unchanged | Passed |
| REQ-007 | AC-007-03 | TC-005-026 | A failed currency dimension load reports the error, logs 'Failed' and leaves the dimension unchanged | Passed |
| REQ-010 | AC-010-01 | TC-006-001 | The first concession bronze load lands three source types one-to-one, all live, and logs 'Success' with 3 rows inserted | Passed |
| REQ-010 | AC-010-01 | TC-006-002 | Missing values land as missing, and an untrimmed, mixed-case name and product number land exactly as in the source | Passed |
| REQ-010 | AC-010-01 | TC-006-003 | A second concession bronze load on unchanged data changes nothing | Passed |
| REQ-010 | AC-010-02 | TC-006-004 | A type renamed in the source is updated in the bronze table, and only it gets a new _updated_at | Passed |
| REQ-010 | AC-010-01 | TC-006-005 | A type gone from the source is marked as deleted, not removed, and live rows equal the source row count | Passed |
| REQ-010 | AC-010-01 | TC-006-006 | A deleted type that reappears unchanged is made live again, not added twice | Passed |
| REQ-010 | AC-010-01 | TC-006-007 | A source row with a missing concession type id fails the bronze load, which changes nothing | Passed |
| REQ-010 | AC-010-01 | TC-006-008 | Two source rows with the same concession type id fail the bronze load, which changes nothing | Passed |
| REQ-010 | AC-010-01 | TC-006-009 | The concession bronze table has no dual-membership column | Passed |
| REQ-010 | AC-010-01 | TC-006-010 | The deployed concession type list holds the three reserved rows at their fixed ids and one 'No concession' row, none with a source id and both flags 0 | Passed |
| REQ-010 | AC-010-01 | TC-006-011 | Three source types give seven rows, with item codes, and Retired and Life Member marked as full concessions | Passed |
| REQ-010 | AC-010-02 | TC-006-012 | A renamed type is updated in place on its existing id, and other rows are untouched | Passed |
| REQ-010 | AC-010-03 | TC-006-013 | A fourth source type adds one row with a new id, and the seven existing ids are unchanged | Passed |
| REQ-010 | AC-010-03 | TC-006-014 | A second concession type list load on unchanged data changes nothing | Passed |
| REQ-010 | AC-010-04 | TC-006-015 | The item code is the product number with the 'rcs' prefix removed; a code without the prefix is kept as it is | Passed |
| REQ-010 | AC-010-01 | TC-006-016 | A type is marked as a full concession only when its discount is exactly 100 | Passed |
| REQ-010 | AC-010-06 | TC-006-017 | A type is perpetual for the source value 200000000, and not for 200000001 or a missing value | Passed |
| REQ-010 | AC-010-03 | TC-006-018 | A type marked as deleted in the bronze table is not added to the list | Passed |
| REQ-010 | AC-010-01 | TC-006-019 | A type with a missing, empty or blank name is added as 'Unnamed concession type' | Passed |
| REQ-010 | AC-010-02 | TC-006-020 | An unnamed type that later gets a name is renamed in place on its id | Passed |
| REQ-010 | AC-010-02 | TC-006-021 | A changed discount, product number and perpetual value update the item code and flags in place | Passed |
| REQ-010 | AC-010-02 | TC-006-022 | A failed concession type list load reports the error, logs 'Failed' and leaves the list unchanged | Passed |
| REQ-010 | AC-010-05 | TC-006-023 | The first dimension load copies every id, name and both flags, reserved rows included, and logs 'Success' | Passed |
| REQ-010 | AC-010-05 | TC-006-024 | A second dimension load on unchanged data changes nothing | Passed |
| REQ-010 | AC-010-05 | TC-006-025 | The dimension load adds a missing id, corrects a changed name and flag, and leaves unchanged rows untouched | Passed |
| REQ-010 | AC-010-05 | TC-006-026 | A failed dimension load reports the error, logs 'Failed' and leaves the dimension unchanged | Passed |
| REQ-010 | AC-010-02 | TC-006-027 | Renaming a type in the source and reloading the bronze table and the list updates its name and keeps every id | Passed |
| REQ-010 | AC-010-05 | TC-006-028 | Loaded through the bronze table and the list, the dimension has the same row count and id and name pairs as the list | Passed |
| REQ-014 | AC-014-07 | TC-001-001 | The grain profile counts invoices by number of rows, number of different item codes and whether they have a 'Sales tax' row | Passed |
| REQ-014 | AC-014-07 | TC-001-002 | The grain profile leaves out transaction types 8 and 24 and invoice numbers containing 'CRE' or 'FTCN' | Passed |
| REQ-014 | AC-014-07 | TC-001-003 | One invoice number on two accounts counts as two invoices | Passed |
| REQ-014 | AC-014-08 | TC-001-004 | The corporate status profile counts rows by 'Sub Status' and by 'Sub User Status' | Passed |
| REQ-014 | AC-014-08 | TC-001-005 | The status profile counts source rows, not contacts, and lists every status value it finds | Passed |

<!-- evidence: docs/test/TCS-MOD-001.json#TC-001-001; docs/test/TCS-MOD-002.json#TC-002-001; docs/test/TCS-MOD-003.json#TC-003-001; docs/test/TCS-MOD-004.json#TC-004-001; docs/test/TCS-MOD-005.json#TC-005-001; docs/test/TCS-MOD-006.json#TC-006-001; docs/test/TCS-MOD-006.json#AC-010-01; docs/test/TCS-MOD-006.json#AC-010-02; docs/test/TCS-MOD-006.json#AC-010-03; docs/test/TCS-MOD-006.json#AC-010-04; docs/test/TCS-MOD-006.json#AC-010-05; docs/test/TCS-MOD-006.json#AC-010-06; docs/test/TCS-MOD-006.json#AC-003-06; docs/test/TCS-MOD-006.json#TC-006-029; docs/test/TR-MOD-001-1.json#TR-MOD-001-1; docs/test/TR-MOD-002-1.json#TR-MOD-002-1; docs/test/TR-MOD-003-1.json#TR-MOD-003-1; docs/test/TR-MOD-004-1.json#TR-MOD-004-1; docs/test/TR-MOD-005-1.json#TR-MOD-005-1; docs/test/TR-MOD-006-1.json#TR-MOD-006-1 -->
