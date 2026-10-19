# BR-001 Payment Segments Tracker

**Requested by:** Mike Lewis, 2026-10-19. Damian reviews each design note.
**Source:** the Payment Segments Tracker user stories, copied from the requirements page with their wording kept.

Five additions to the RICS membership platform (the Phase 1 Layercake solution):
1. **Payment Method:** Direct Debit, Card, Bank transfer, Cheque, Corporate.
2. **Payer Type:** Individual or Corporate.
3. **The invoiced subtotal** on Join, Readmission and Renewal events, split into subscription and fee.
4. **Concessions.**
5. **An Employer segment** for RICS' largest employers. This is lower priority.

Segments 1, 2 and 4 match the dashboard design's filters.

## How to use this request

- The stories below include data design, implementation and testing steps written before discovery. Treat them as guidance. The agents should follow their own analysis and design where it differs, and raise the difference as a question.
- **Order and dependencies:**
  - Stories 1 and 2 share one discovery, because "Corporate" is a value of the payment method field.
  - Story 3 can start in parallel.
  - Story 4 shares Story 3's invoice source, since concessions come from the invoice data.
  - Story 5 follows Story 2, whose corporate account link is the likeliest route to an employer. It may end as findings only (its D6).
- **Real data stays with a human.** The agents work on synthetic data only. Profiling real data (coverage, agreement rates, value lists), reconciling to Finance figures and spreadsheets, Finance and Corporate team reviews, and traces of real contacts are human steps. Agents may prepare profiling queries that return counts only; Mike runs them and brings back the results as answers. Inside the agents' own tests, the same checks run on synthetic data.
- **Migrations:** this project uses the framework's migrations (`src/sql/deploy/`, journal `etl.MigrationHistory`) for every change, with a tested rollback. Where a story says "migration recorded in schema_migration", read it as this.
- **The Platform Schema document** lives outside this repo. The Technical Writer's handover pack gives the bronze, silver and gold content for it, and a human updates the document.
- **Regression:** existing Phase 1 counts and measures must not change. That covers active, both paid measures and event counts by date, region and grade, and the Phase 1 difference lists (`reference/phase1/Scripts/Reconciliation/active-member-difference.sql` and `paid-member-difference.sql`) must still read PASS.

## Story 1

As a Finance or Membership Growth user, I want to filter every membership event (Join, Change, Lapse, Readmission and Renewal) and paid members by how the member pays (Direct Debit, Card, Bank transfer, Cheque, Corporate), so that I can see how collection behaviour differs and why Direct Debit members show as Partially Paid for most of the year.

### Data design
- D1 Find where payment method lives. Values confirmed in May: Bank, Card, Cheque, DD, Corporate and null. Candidates: the CE invoice or quote record, Subs.vwSubsMemberStatuses, or the F&O payment journal / custtrans payment mode. Prefer a source already in the RICS data warehouse.
- D2 Confirm grain and join. One value per subscription invoice, per payment line, or per contact? Confirm how it joins to contact number and Campaign Year: directly, or through paymreference and the due-date rule.
- D3 Derive the method for every event. Every event, Change and Lapse included, takes its payment method from the contact's invoice data for the event's Campaign Year. Within a year, proposed: the method on the subscription invoice. Where only payment lines carry it, the method covering the largest settled amount; ties go to the earliest payment. Add a Mixed value only if profiling shows it is common. Where the event's Campaign Year has no invoice (common for a Lapse), proposed: carry forward the latest earlier year's method, flagged as carried forward, else Not recorded.
- D4 Profile coverage from 2021. Share of paid positions with a payment method, by Campaign Year. Nulls map to id 0 (Not recorded).
- D5 Design note agreed. Source, grain, rule, coverage and the daily-detail decision written into the Platform Schema document and agreed with Damian. Build starts after this.

### Implementation (bronze to gold, with migrations)
- I1 Bronze landing and migration. New brnz_subs_invoice (or extra columns on the source that holds the field) with the standard 1:1 pattern, audit columns and row-count check. Migration recorded in schema_migration.
- I2 Reference list and member-year attributes. silv_ref_payment_method, identity-keyed with id 0 = Not recorded. Create silv_member_year_attributes: one row per contact per Campaign Year, from the contact's first event to the current year, built before silv_membership_events. It holds payment_method_id from the contact's invoice data for that year; a year with no invoice carries forward the latest earlier value with payment_method_carried = 1, else 0. Stories 2, 4 and 5 add their columns here.
- I3 Carry the key onto every event. Every row of silv_membership_events (Join, Change, Lapse, Readmission, Renewal) takes payment_method_id from silv_member_year_attributes on contact + the event's Campaign Year. No change to event_nk or event_id.
- I4 Gold dimension and fact column. dim_payment_method and the key on fact_membership_events. Extend the silver-to-gold row-count check.
- I5 Daily detail and annual rate base (if agreed). Adding the key changes the grain and row volume of fact_daily_member_count_detail and fact_annual_rate_base. Recommended: event fact first, daily detail only if Finance needs paid members by method day by day. If built, log a rebuild and run @RebuildFrom deliberately.
- I6 Update the Platform Schema document. Bronze, silver and gold sections.

### Testing (regression, reconciliation and traces)
- T1 Regression. Active, both paid measures and all event counts unchanged by date, region and grade. Both difference scripts read PASS.
- T2 Coverage and key resolution. Share of paid positions with a method per Campaign Year, nulls explained. Every payment_method_id resolves to dim_payment_method. Coverage reported by event type, so Change and Lapse events are checked separately.
- T3 Direct Debit check. Direct Debit members account for most Partially Paid positions in the current Campaign Year.
- T4 Trace 10 contacts. At least one per method and one mixed payer, from source to gold.
- T5 Finance review. Totals by method for the last full Campaign Year reviewed with Finance.

## Story 2

As a Finance or Commercial user, I want every membership event and paid member marked as Individual or Corporate, so that I can track corporate-funded membership (about 16% of members and 20% of subscription income) separately from members who pay for themselves.

### Data design
- D1 Choose the corporate signal. Profile three candidates for one Campaign Year and say which is most reliable: the Corporate payment method (Story 1); the corporate scheme code the Digital team sets on the individual in CE; the sub ID / unique reference on the corporate quote.
- D2 Explain the count gap. Alex's count of about 21,944 corporate-paid members does not match Finance's invoiced figures. Test the three explanations raised in May: the flag is also applied to enrolment fees; historic flags were not removed; some members paid individually despite the flag, or the reverse. Cross-check against Finance's corporate tracking spreadsheet.
- D3 Agree the rule. Proposed: Corporate where the subscription invoice for that Campaign Year was raised under a corporate scheme and settled by corporate allocation; Individual where the paid position exists and that test fails; Not determined (id 0) where the source cannot tell. Enrolment-fee-only lines excluded from the test.
- D4 Decide on the employer reference. If the sub ID reliably links to the firm, land it as `corporate_account_ref` on the payment event. No employer dimension: full employer segmentation is a separate piece of work planned for early 2027.
- D5 Edge cases. A member paid by card and by their employer (Finance flags these as double payments). A corporate leaver before 31 January is credited in Round 2, becomes Fully Credited and drops out of paid, so needs no payer type.
- D6 Design note agreed. Chosen signal, rule, known gaps and anomaly types written into the Platform Schema document and agreed with Damian.

### Implementation (bronze to gold, with migrations)
- I1 Bronze landing for extra CE fields. Scheme code or sub ID, if held outside the Story 1 source. Standard pattern and migration.
- I2 Reference list and derivation. `silv_ref_payer_type`: Not determined (0), Individual, Corporate. Add `payer_type_id` to `silv_member_year_attributes`, same carry-forward rule, replacing the text `payment_source` on `silv_payment_events`; add `corporate_account_ref` if D4 holds.
- I3 New anomaly types. For example `CORPORATE_FLAG_NO_SCHEME` and `DOUBLE_PAYMENT` in `silv_data_anomaly`.
- I4 Events and gold. `payer_type_id` on every event, from the attributes row for its contact and Campaign Year; `dim_payer_type` and the key on `fact_membership_events`. Same daily-detail decision as Story 1.
- I5 Update the Platform Schema document. Including closing to-do 7.2 #9.

### Testing (regression, reconciliation and traces)
- T1 Regression. All existing counts unchanged; difference scripts read PASS.
- T2 Reconcile to Finance. Corporate count for the last full Campaign Year reconciled to Finance's corporate tracking spreadsheet, every difference listed by reason. Corporate share close to the expected 16%, any gap explained.
- T3 One payer type per year. No contact holds both payer types in one Campaign Year without an anomaly row.
- T4 Trace 10 contacts. Corporate, individual, a Round 2 leaver credited before 31 January, a leaver after 31 January, and a double payment.

## Story 3

As a Finance user, I want each Join, Readmission and Renewal event to carry the amount invoiced for it, split into the membership subscription and any associated fee (such as the readmission fee), so that I can report subscription revenue by segment from the same events that drive the membership counts.

### Data design
- D1 Find the invoice line detail. The F&O invoice line source behind custtrans, or the CE invoice detail, and the field that identifies the item: subscription, readmission fee, enrolment or application fee, other.
- D2 Tie invoices to events. Proposed: Renewal and Readmission take the subscription invoice for their Campaign Year (contact + Campaign Year through paymreference and the due-date rule in silv_payment_events). A Join takes the invoice for the Campaign Year of the first paid position.
- D3 Agree which fees count. Readmission fee on Readmission events is confirmed. Agree with Finance whether an enrolment or application fee belongs on the Join, and whether other fee types exist.
- D4 Currency and subtotal definition. Invoice currency, GBP, or both, and where the exchange rate comes from. Proposed subtotal: before tax and before credits, with credits carried separately so a Round 2 corporate credit does not rewrite the original invoice.
- D5 Corporate invoices. Firm-level discounts (£2,500 or £5,000 for the largest firms) sit on the firm's invoice. Confirm the individual's allocated line is the amount to carry, and record the discount as a known gap.
- D6 Design note agreed. Source, line-type mapping, matching rule, currency treatment and field list agreed with Damian.

### Implementation (bronze to gold, with migrations)
- I1 Bronze landing of invoice lines. Plus currency or exchange rate source if needed. Standard pattern and migration.
- I2 Line-type mapping in silver. Held in a reference table so new item codes show up rather than being dropped.
- I3 Attach amounts to events. subs_amount, fee_amount, invoiced_subtotal, credited_amount, currency_id (and GBP columns if agreed) on Join, Renewal and Readmission; null on Change and Lapse. Event count unchanged.
- I4 Gold measures and dim_currency. Additive measures on fact_membership_events; new dim_currency.
- I5 Anomaly types. Events with no matching invoice, and invoices with no event.
- I6 Update the Platform Schema document. Including closing to-do 7.2 #6.

### Testing (regression, reconciliation and traces)
- T1 Regression. Event counts and all existing measures unchanged.
- T2 Coverage. Share of Join, Renewal and Readmission events with an invoiced subtotal, by Campaign Year.
- T3 Reconcile to Finance. Total subscription invoiced for the last full Campaign Year against Finance's figure and the Subs Performance Dashboard, by currency.
- T4 Readmission fee check. Every Readmission event has a readmission fee, or an anomaly row explains why not. This also answers RICS item 7.1 #11.
- T5 Concessions and traces. Full Concession positions carry a zero subtotal, not null. Trace 10 events: individual, corporate and Direct Debit renewals, standard and in-year readmissions, Candidate and RPQ joins.

## Story 4

As a Finance or Membership Growth user, I want every membership event and paid member segmented by concession type, so that I can see how many members pay a reduced or nil rate, which concessions they hold, and whether concession members renew and lapse differently.

### Data design
- D1 Find the concession reference. A reference table in source is expected to hold the concession list. Identify it and confirm its key matches the concession value on the invoice. It replaces the dashboard design's placeholder list and becomes dim_concession_type.
- D2 Confirm the concession field on the invoice. Where the invoice (header or line, from Story 3's source) carries the concession, and how it joins to contact number and Campaign Year. Share discovery with Story 3.
- D3 One concession per Campaign Year? Check whether a member can hold more than one concession in a year, or have one applied mid-year. Proposed rule: the concession on the subscription invoice for that Campaign Year.
- D4 Separate full and reduced. Use the reference's flag if it has one; otherwise derive nil versus reduced rate from the invoiced subtotal (Story 3). Members with none get No concession; id 0 stays Not recorded.
- D5 Compare with retirement date. The definitions work assumed Retired members are counted from the retired concession. Compare it with apuk_retirementdate, which drives Practising / Retired today, and report the agreement rate. No change to the status logic in this story.
- D6 Design note agreed. Concession reference table, invoice field, Campaign Year rule and the retirement comparison agreed with Damian.

### Implementation (bronze to gold, with migrations)
- I1 Bronze landing. New brnz_concession: 1:1 landing of the source reference, standard pattern and migration. Concession field confirmed in Story 3's invoice landing.
- I2 Reference list and derivation. silv_ref_concession_type built from brnz_concession, insert-and-update like silv_ref_country, so new concessions flow through and ids stay stable. Id 0 = Not recorded, plus No concession. Add concession_type_id to silv_member_year_attributes, same carry-forward rule.
- I3 Events and gold. concession_type_id on every event, from the attributes row for its contact and Campaign Year; dim_concession_type and the key on fact_membership_events. Same daily-detail decision as Stories 1 and 2.
- I4 Anomaly types. A Full Concession position with no concession on the invoice, or a concession value missing from the reference.
- I5 Update the Platform Schema document. Bronze, silver and gold sections.

### Testing (regression, reconciliation and traces)
- T1 Regression. All existing counts unchanged; difference scripts read PASS.
- T2 Full Concession coverage. Every Full Concession position has a full-rate concession type, or an anomaly row says why not.
- T3 Review counts with RICS. Counts by concession type for the last full Campaign Year, reviewed with Finance and Membership Growth.
- T4 Retirement comparison written up. Retired concession against apuk_retirementdate, with the agreement rate and examples of each disagreement.
- T5 Cross-check with Story 3. Concession members' invoiced subtotal is below the standard rate, and zero for full concessions.
- T6 Trace 10 contacts. Across concession types, including one granted mid-year.

## Story 5 (lower priority)

As a Commercial or Membership Growth user, I want current metrics segmented by RICS' largest employers, so that I can see how membership, renewal and lapse differ across the firms that employ the most members, and judge whether the employer data is reliable enough to build on.

### Data design
- D1 Find the employer source. Candidates: the corporate firm linked through the sub ID on the corporate quote (Story 2), and the employer or parent account on the CE contact. Profile both for coverage, how current they are, and how often they agree.
- D2 Decide who is in the view. Corporate-funded members have a firm by definition. Decide whether individually funded members with an employer on their contact record are included.
- D3 Choose the employers. Proposed: the top 25 by paid members in the last full Campaign Year, everything else as Other, id 0 for Not recorded. Agree the number with RICS.
- D4 Point in time or current. Prefer the employer at the Campaign Year's invoice (corporate link). If only the contact's current employer exists, label it current-state, as country and gender are today.
- D5 Group firm names. The same firm may sit under several accounts or spellings. A simple curated grouping for the top employers only.
- D6 Feasibility note and build decision. Findings and the employer data quality note agreed with Damian, with a decision: build the segment, or report the findings only.

### Implementation (bronze to gold, with migrations)
- I1 Bronze landing. New brnz_account (CE accounts) and, if needed, the contact's employer field on brnz_contact. Standard pattern and migration.
- I2 Curated employer grouping. ref_employer_group: accounts grouped into the top employers, plus Other and Not recorded.
- I3 Derive the key, events and gold. employer_id on silv_member_year_attributes, same carry-forward rule, and so on every event; dim_employer and the key on fact_membership_events. Daily detail and annual rate base only if the data proves reliable.
- I4 Update the Platform Schema document. Bronze, silver and gold sections, plus the data quality note.

### Testing (regression, reconciliation and traces)
- T1 Regression. All existing counts unchanged; difference scripts read PASS.
- T2 Coverage. Share of paid members with an employer, by Campaign Year and payer type.
- T3 Corporate team sense check. Top employers' member counts checked against the Corporate team's own lists.
- T4 Corporate members have an employer. Every corporate-funded member in the top employers has an employer; any gap listed in silv_data_anomaly.
- T5 Trace 10 contacts. Across three of the top employers, including one who moved employer between Campaign Years.

## Proposed schema changes (guidance)

Proposals until each design note is agreed; source tables marked TBC are found in discovery.

| Story | Layer | Table | Change |
|---|---|---|---|
| 1 | Bronze | brnz_subs_invoice (new) | Payment method with contact number, Campaign Year and invoice reference. Or extra columns on whichever source holds the field (TBC). |
| 2 | Bronze | CE scheme code / sub ID source (new) | Only if not already in the Story 1 source (TBC). |
| 3 | Bronze | Invoice line source (new) | F&O invoice lines or CE invoice detail, with item code and currency (TBC). |
| 4 | Bronze | brnz_concession (new) | 1:1 landing of the source concession reference. The concession value itself comes with Story 3's invoice source. |
| 5 | Bronze | brnz_account (new) | CE accounts, plus the contact's employer field on brnz_contact if needed (TBC). |
| 1 | Silver | silv_ref_payment_method (new) | Identity-keyed; id 0 = Not recorded. |
| 2 | Silver | silv_ref_payer_type (new) | Not determined (0), Individual, Corporate. |
| 3 | Silver | silv_ref_currency, line-type mapping (new) | Currency list and the item-code to subscription / fee mapping. |
| 4 | Silver | silv_ref_concession_type (new) | Built from brnz_concession, insert-and-update; Not recorded (0), No concession, full or reduced flag if the source has one. |
| 5 | Silver | ref_employer_group (new) | Curated grouping of accounts into the top employers; Other and Not recorded. |
| 1, 2, 4, 5 | Silver | silv_member_year_attributes (new) | One row per contact per Campaign Year: payment_method_id, payer_type_id, concession_type_id, employer_id, corporate_account_ref if agreed, each with a carried-forward flag. Created by Story 1, built before the events. |
| 2 | Silver | silv_payment_events | Text payment_source retired; payer type now lives on silv_member_year_attributes. |
| 1-5 | Silver | silv_membership_events | Every event takes payment_method_id, payer_type_id, concession_type_id and employer_id from silv_member_year_attributes on contact + Campaign Year. Add subs_amount, fee_amount, invoiced_subtotal, credited_amount, currency_id on Join, Renewal and Readmission. |
| 2, 3, 4 | Silver | silv_data_anomaly | New types: corporate flag disagreements, double payments, events without invoices, invoices without events, Full Concession with no concession record. |
| 1 | Gold | dim_payment_method (new) | From silv_ref_payment_method. |
| 2 | Gold | dim_payer_type (new) | From silv_ref_payer_type. |
| 3 | Gold | dim_currency (new) | From silv_ref_currency. |
| 4 | Gold | dim_concession_type (new) | From silv_ref_concession_type. |
| 5 | Gold | dim_employer (new) | From ref_employer_group. |
| 1-5 | Gold | fact_membership_events | New keys and additive amount measures, copied from silver. |
| 1, 2, 4, 5 | Gold | fact_daily_member_count_detail, fact_annual_rate_base | Only if agreed (question F). Changes the grain; needs a deliberate rebuild. |

## Open questions

From the requirements page, for RICS to answer once discovery has evidence. Two of them (named B and F on the page) change how much gets built.

1. Which field is the system of record for payment method, and since which Campaign Year is it reliable? RICS Data · Story 1
2. Is the corporate scheme code, the Corporate payment method or the sub ID the right test for a corporate-funded member? Finance · Story 2
3. Should an enrolment or application fee count as an associated fee on a Join? Finance · Story 3
4. Report amounts in invoice currency, GBP, or both? Which exchange rate? Finance · Story 3
5. Should corporate firm discounts be spread across individuals, or reported at firm level only? Finance · Story 3
6. Where an event's Campaign Year has no invoice (a Lapse, say), should its payment method carry forward from the latest earlier year? Finance, Membership Growth · Story 1
7. Is paid members by payment method, payer type or concession needed day by day, or are the event and annual views enough? Finance, Membership Growth · Stories 1, 2 and 4
8. Which source table is the concession reference, and is it complete and current? Finance, Membership · Story 4
9. Should the retired concession or the retirement date drive Practising / Retired status? Finance, Membership Growth · Story 4
10. How many employers should the view cover, and should it include individually funded members whose contact record names an employer? Commercial, Corporate team · Story 5
