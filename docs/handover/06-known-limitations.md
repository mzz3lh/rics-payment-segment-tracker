# Known limitations: RICS Payment Segment Tracker

## Assumptions awaiting confirmation

These are working assumptions recorded in the specification, each awaiting the client's answer to an open question. The MOD-001 profiles exist to help answer them.

| Question | Working assumption | What rests on it | How to settle it |
|---|---|---|---|
| Q-021: the grain of synapse_fo.CUSTTRANS_RICS | One row per invoice line with an item code (productcode), with tax as its own line, as Subs.usp_Refresh_SubsInvoices treats it. This is not yet proven. | Already built: which transaction rows the line load treats as belonging to an invoice (RULE-077), and the assumed grain of brnz_subs_invoice_line (MOD-002). Still to come: the split of invoiced amounts into subscription, fee and tax; the build of REQ-007 (line-type mapping), REQ-008 (invoiced amounts) and REQ-011 (concessions) waits for the grain profile. | Run Layercake.usp_profile_custtrans_grain on real data: rows per invoice, different item codes per invoice, and whether tax is its own row. |
| Q-027: the value of 'Sub Status' and 'Sub User Status' for an active subscription and subscription user | 'Active' | Whether a contact is in a live corporate subscription for a Campaign Year, which is assumed to mean both statuses are active (with 'Round' not used). This feeds the payer type. | Run Layercake.usp_profile_corp_subscription_status on real data and confirm which value means active. |

<!-- evidence: docs/specs/SPEC-001.json#Q-021; docs/specs/SPEC-001.json#tax appears as its own line, as Subs.usp_Refresh_SubsInvoices treats it; docs/specs/SPEC-001.json#before any build of REQ-007, REQ-008 or REQ-011; docs/specs/SPEC-001.json#RULE-077; docs/design/DES-001.json#The grain is assumed to be one row per invoice line (Q-021); docs/specs/SPEC-001.json#Q-027; docs/specs/SPEC-001.json#Working default: 'Active'; docs/specs/SPEC-001.json#both 'Sub Status' and 'Sub User Status' are active; docs/answers.md#Do not use 'Round'; docs/design/DES-001.json#Q-027 for payer type -->

## Known limitations

- **Invoice data starts at Campaign Year 2022.** The invoice source, Subs.tblSubsInvoices, keeps only Campaign Year 2022 onward, so the bronze invoice tables hold nothing earlier.
- **Very large invoice amounts would stop the invoice load.** The money columns of brnz_subs_invoice hold up to 26 digits before the decimal point, which is the solution's standard money type, while the source allows up to 32. This is the one deliberate exception to copying source column sizes exactly, confirmed on 2026-10-26, since no real invoice amount comes near that size. If such a value ever appeared, the load would fail and change nothing (see the Runbook) rather than store a cut-down amount.
- **Payments and credits posted on another customer account are not landed.** A transaction row is landed against an invoice only when it is on the invoice's own account. A payment or credit that settles the invoice but was posted on a different account is left out, as confirmed on 2026-10-26.
- **The layout of the profiles' results is not yet confirmed.** The design does not define it, and the question about it is still unanswered. The profiles were built and tested to the layout described in the Architecture and data model document. If a different layout is wanted, the procedures and their tests will need to change.
- **Some edge cases in the grain profile were decided during the build, not by the design.** Rows with no transaction type or no invoice number are not treated as invoice rows and are left out. A row with no item code adds nothing to the count of different item codes. A tax row is recognised only by the posting type 'Sales tax'. Please confirm these suit the purpose of the profile.
- **The permission script needs the analyst's role name.** The grant script uses the placeholder [<analyst_role>], because the role name is not known. It cannot be run until a person replaces the placeholder.
- **The decision records for ADR-001 and ADR-003 are still marked as pending**, although the design that follows their recommendations has been approved.

<!-- evidence: docs/specs/SPEC-001.json#Invoice source coverage; docs/sources/external/Subs/Subs.usp_Refresh_SubsInvoices.sql#Campaign_Year >= 2022; docs/dev/CN-MOD-002.json#deviations; docs/dev/CN-MOD-002.json#A source value beyond 26 integer digits fails the load with error 8115 (TC-002-010) instead of being truncated; docs/answers.md#MOD-002 ordernum and amount types; docs/answers.md#This is the one deliberate exception; docs/answers.md#A payment or credit posted on another customer account is not landed, even when it settles the invoice; docs/test/TCS-MOD-002.json#TC-002-013; docs/dev/CN-MOD-001.json#Result shape of both procedures is not defined in DES-001; docs/dev/CN-MOD-001.json#The design does not settle these cases; docs/dev/CN-MOD-001.json#PostingType_Description = 'Sales tax'; docs/dev/CN-MOD-001.json#[<analyst_role>]; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#Pending: filled in by a human at the architecture validation gate; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#Pending: filled in by a human at the architecture validation gate -->

## Recommended next steps

1. Confirm the analyst's role name, replace the placeholder in src/sql/grants/MOD-001.sql and run it.
2. Deploy migrations MIG-0003 and MIG-0004 to production (see the Runbook, Deployment and rollback).
3. Run both profiles on real data and use the results to answer Q-021 and Q-027 before the invoice build. The Q-021 answer also confirms, or changes, which transaction rows the line load lands.
4. Confirm the layout of the profiles' results and the grain profile's edge-case handling (see Known limitations above).
5. Record the decisions on ADR-001 and ADR-003.
6. Confirm the schedule for the loads once the run procedure is delivered (see the Runbook, Scheduling).

<!-- evidence: docs/dev/CN-MOD-001.json#A human must replace it before running the script; docs/dev/CN-MOD-001.json#MIG-0003; docs/dev/CN-MOD-002.json#MIG-0004; docs/design/adr/ADR-003-delivery-of-the-count-only-profiling-and-findings-queries.md#they must be deployed to production before Mike can run them there; docs/design/MP-001.json#so Mike can run them before the invoice build; docs/specs/SPEC-001.json#RULE-077; docs/dev/CN-MOD-001.json#the Tester's question about it is still unanswered; docs/design/adr/ADR-001-how-segment-keys-and-amounts-reach-the-event-tables.md#which a human schedules after the Phase 1 run -->
