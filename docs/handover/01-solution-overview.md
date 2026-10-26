# Solution overview: RICS Payment Segment Tracker

## Purpose

The RICS Payment Segment Tracker adds financial segments and invoiced amounts to the existing Phase 1 membership solution (the Layercake schema). When complete, every membership event (Join, Change, Lapse, Readmission, Renewal) and every paid member can be filtered by payment method, payer type (Individual or Corporate) and concession type. Each Join, Renewal and Readmission will carry the amount invoiced for it, with one headline value in GBP. Phase 1 counts and measures do not change.

<!-- evidence: docs/specs/SPEC-001.json#Adds financial segments and invoiced amounts; docs/specs/SPEC-001.json#REQ-001 -->

## Scope

The release covers the payment method, payer type and concession segments, invoiced amounts on events, and count-only queries for profiling and coverage. The employer segment is delivered as findings only in this release. Steps that need real data (profiling, reconciliation to Finance figures, team reviews and traces of real contacts) are done by a person, using the count-only queries the solution provides. Updating the Platform Schema document is also outside the solution: this pack supplies its content and a person updates it.

The solution is delivered in modules (MOD-nnn), each built and tested in turn. This pack currently covers MOD-001, Source profiling queries: two read-only procedures that profile the source data before the invoice build. Later modules are added to the pack as they pass testing.

<!-- evidence: docs/specs/SPEC-001.json#The employer segment is delivered as findings only; docs/specs/SPEC-001.json#Real-data steps, which are done by a human; docs/specs/SPEC-001.json#Editing the Platform Schema document itself; docs/design/MP-001.json#MOD-001; docs/design/MP-001.json#Source profiling queries -->

## Requirements delivered

Requirements are numbered REQ-nnn and each has acceptance criteria (AC-nnn-nn) that the tests check. Business rules are numbered RULE-nnn and open questions to the client Q-nnn.

| Requirement | What it delivers | Status |
|---|---|---|
| REQ-014 Count-only profiling and coverage queries | Queries that return counts only, run on real data by Mike, with the results brought back as answers to open questions. Delivered so far: the CUSTTRANS_RICS grain profile (AC-014-07) and the corporate subscription status profile (AC-014-08). | Partly delivered. The two source profiles passed testing. The coverage queries (AC-014-01 to AC-014-06) come in a later module (MOD-015). |

For what each profile does, see the Architecture and data model document. For the test results, see the Test summary.

<!-- evidence: docs/specs/SPEC-001.json#REQ-014; docs/specs/SPEC-001.json#Count-only profiling and coverage queries; docs/specs/SPEC-001.json#AC-014-07; docs/specs/SPEC-001.json#AC-014-08; docs/design/MP-001.json#MOD-015; docs/design/MP-001.json#AC-014-01; docs/test/TR-MOD-001-1.json#REQ-014 -->
