# ADR-002: Persisting per-event invoice matches and amounts

| | |
|---|---|
| Status | proposed |
| Date | 2026-10-23 |
| Requirement IDs | REQ-008, REQ-009 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
Each Join, Renewal and Readmission event is paired with its own eligible invoice (RULE-032, RULE-084 to RULE-086, RULE-089). Its amounts and amount_status come from that invoice (RULE-033 to RULE-041, RULE-087, RULE-088). The same pairing decides four anomaly types: EVENT_NO_INVOICE, INVOICE_NO_EVENT, INVOICE_MATCHES_MULTIPLE_EVENTS and EVENT_MATCHES_MULTIPLE_INVOICES (RULE-042, RULE-043, RULE-090, RULE-091). Readmission fee anomalies depend on the amounts (RULE-044). The pairing result therefore feeds both the event columns and the anomaly load.

## Options
### Option A: Persisted silver match table
A new table, Layercake.silv_event_amount, holds one row per Join, Renewal and Readmission event: the amount Campaign Year, the matched invoice (if any), the match outcome, every amount column and amount_status. Its own procedure loads it. The event enrichment copies from it, and the invoice anomaly load reads it.

Trade-offs: The pairing runs once and has one tested home. The anomaly load and the event columns cannot disagree, and the pairing can be tested and traced without the event tables. Cost: one more table (about one row per Join, Renewal and Readmission event) and one more load step to keep idempotent.

### Option B: Compute inside each consumer
The event enrichment procedure pairs events with invoices and writes the amounts directly. The invoice anomaly load repeats the same pairing to find unmatched events and surplus invoices.

Trade-offs: No extra table. But the pairing logic exists twice and can drift, so an event could show 'No invoice' with no matching anomaly. Tests must cover the pairing twice, and the event enrichment module becomes too big for one build-and-test cycle.

## Recommendation
Option A: Persisted silver match table. One implementation of the pairing guarantees that amounts and anomalies agree (AC-009-06 to AC-009-08 depend on it), and it keeps the event and anomaly modules small.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
Adds Layercake.silv_event_amount and Layercake.usp_load_silv_event_amount as their own module (MOD-010), before the invoice anomalies (MOD-011) and the event enrichment (MOD-012), which both depend on it. The table is internal to silver; gold reads amounts only from silv_membership_events.
