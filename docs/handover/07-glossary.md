# Glossary: RICS Payment Segment Tracker

## Terms

| Term | Meaning |
|---|---|
| Audit columns | The four columns every bronze table carries: _loaded_at (first landed), _updated_at (last changed by a load), _is_deleted (1 when no longer in the source) and _deleted_at (when it was marked as deleted). |
| Bronze | The layer of tables that copy source data one-to-one, with no change to any value, plus the audit columns. Their names start brnz_. |
| Campaign Year | The RICS subscription year, as held in Layercake.ref_campaign_year_config and on the invoice source. |
| Count-only query | A read-only query that returns counts, sums or rates only, never individual records, so it can be run on real data safely. |
| Grain | What one row of a table represents, for example one invoice line or one whole transaction. |
| Grain profile | Layercake.usp_profile_custtrans_grain: counts invoices in synapse_fo.CUSTTRANS_RICS by rows, different item codes and tax rows, to show the source's grain (Q-021). |
| Corporate status profile | Layercake.usp_profile_corp_subscription_status: counts rows of Subs.vwCorpSubscriptions by each 'Sub Status' and 'Sub User Status' value (Q-027). |
| Last settlement voucher | On a credit or payment row in synapse_fo.CUSTTRANS_RICS, the voucher of the invoice it settles (RULE-077). |
| Live corporate subscription | A row in Subs.vwCorpSubscriptions for the contact and Campaign Year where both 'Sub Status' and 'Sub User Status' are active. Which value means active is an assumption ('Active') awaiting Q-027. |
| Live row | A bronze row whose source row still exists (_is_deleted 0). |
| Load log | Layercake.etl_run_log: one row per load run, with its outcome ('Success' or 'Failed') and the rows inserted, updated and deleted. |
| Item code (productcode) | The code on an invoice row that says what the row is for, for example a subscription or a fee. |
| Layercake | The database schema that holds the Phase 1 membership solution and every object this solution adds. |
| Marked as deleted (soft delete) | A bronze row whose source row has gone is kept, with _is_deleted set to 1 and _deleted_at recorded, rather than removed. |
| Migration | A numbered, recorded change to the database (MIG-nnnn), with an up script that applies it and a down script that reverses it. |
| Phase 1 | The existing Layercake membership solution that this solution extends without changing its results. |
| REQ, RULE, AC, Q | Specification identifiers: a requirement, a business rule, an acceptance criterion and an open question to the client. |
| MOD, TC, ADR | A module of the build, a test condition, and an architecture decision record. |
| Synthetic data | Made-up test data, used for all automated testing; no real data is used in testing. |
| Voucher | The reference that links an invoice in Subs.tblSubsInvoices to its rows in synapse_fo.CUSTTRANS_RICS: an invoice's own lines carry its voucher (RULE-077). |

<!-- evidence: docs/design/DES-001.json#Standard bronze audit column: when the row was first landed; docs/design/DES-001.json#Standard bronze audit column: 1 when the row is no longer in the source (soft delete); docs/design/DES-001.json#brnz_* tables: 1:1 landings of external sources; docs/specs/SPEC-001.json#RULE-004; docs/specs/SPEC-001.json#RULE-077; docs/specs/SPEC-001.json#RULE-005; docs/dev/CN-MOD-002.json#with status 'Success' or 'Failed'; docs/test/TCS-MOD-002.json#TC-002-004; docs/test/TCS-MOD-002.json#TC-002-008; docs/specs/SPEC-001.json#Campaign Year; docs/specs/SPEC-001.json#Live corporate subscription; docs/specs/SPEC-001.json#Working default: 'Active'; docs/specs/SPEC-001.json#Q-021; docs/design/DES-001.json#reporting queries; docs/design/DES-001.json#Layercake.usp_profile_custtrans_grain; docs/design/DES-001.json#Layercake.usp_profile_corp_subscription_status; docs/design/DES-001.json#Item code for the line-type mapping; docs/design/DES-001.json#Extends the Phase 1 Layercake membership solution; docs/dev/CN-MOD-001.json#MIG-0003; docs/setup/ENVIRONMENTS.md#Synthetic only; docs/design/MP-001.json#MOD-001 -->
