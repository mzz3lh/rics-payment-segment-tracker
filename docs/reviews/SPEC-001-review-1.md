<!-- Damian Watson (Layercake), review of SPEC-001 v1, received from Mike 2026-10-21. Verbatim. The RULE, REQ, AC and Q numbers refer to the v1 draft, kept as docs/reviews/SPEC-001-v1.json. -->

# SPEC-001 Review: Financial Segments and Revenue Data

**Spec:** SPEC-001 v1 (for_review, 19 Oct 2026), source BR-001
**Reviewed by:** Damian Watson, Layercake
**Date:** 20 October 2026

## Purpose of this review

This review checks SPEC-001 against the two requirements the dashboard places on this data:

1. **Every event is segmentable by the financial segment data** (payment method, payer type, concession type and, at lower priority, employer). This covers Join, Change, Lapse, Readmission and Renewal.
2. **Every Join, Renewal and Readmission event holds a clear monetary value.**

Power BI build work is not in scope, so this review does not cover the semantic model, DAX or the daily count and annual rate tables. The working default for Q-007 (keys on the event fact only) fits these requirements.

The spec is thorough. Phase 1 results are protected (REQ-001), each rule names the open question it depends on, and the acceptance criteria are concrete. The points below are what would stop it fully meeting the two requirements, plus assumptions to confirm before build.

---

## 1. Gaps against "a clear monetary value"

### 1.1 The invoice-line split may not be possible from the chosen source (REQ-002, REQ-007, REQ-008)

The subs, fee and tax split assumes `synapse_fo.CUSTTRANS_RICS` holds one row per invoice line with an item code (`productcode`). The Platform Schema describes `synapse_fo.custtrans` as transaction grain: positive rows for invoices, negative for payments, grouped by payment reference. If CUSTTRANS_RICS has the same grain, each invoice has one total, there is no separate tax line, and RULE-033 and RULE-034 cannot be applied.

**Action:** Run a count-only profile before any build: rows per invoice, distinct `productcode` per invoice, and whether tax appears as its own row. If it is transaction grain, line-level data needs a different source (for example invoice line or tax transaction tables).

### 1.2 One invoice can be counted on more than one event (RULE-032)

Each event finds its invoice by contact and Campaign Year. Nothing stops two events using the same invoice. Examples:

- Two Readmission events for the same contact in one Campaign Year.
- A Renewal and an in-year readmission in the same year (the business definitions treat in-year readmission as a Renewal).
- A Join whose first paid position is the following year, sharing that year's invoice with another event.

Each case doubles the revenue.

**Action:** Add a rule that each invoice is matched to at most one event, with a stated priority (for example Readmission, then Renewal, then Join, then earliest event date), and an acceptance criterion that the sum of event amounts never exceeds the sum of matched invoice amounts.

### 1.3 The headline value is not defined

Events carry `subs_amount`, `fee_amount`, `invoiced_subtotal` and `credited_amount`, each in invoice currency and GBP. That is eight candidate figures. "Clear" needs one agreed headline value.

- Invoice-currency columns cannot be summed across currencies, so they should not be the headline.
- `invoiced_subtotal` is gross, before credits (RULE-036). There is no net value (invoiced minus credited), which is closer to how Finance reports.
- The sign of `credited_amount` is not fixed (AC-008-04 says "absolute value").

**Action:** Name one headline measure (proposed: `invoiced_subtotal_gbp`), add `net_amount_gbp = invoiced_subtotal_gbp - credited_amount_gbp`, and fix credits as a positive number.

### 1.4 Join amounts and Join segments come from different years (RULE-017, RULE-032, Q-013)

A Join takes its amount from the first paid position's year but its segment keys from the Join event's own year. AC-005-04 shows the effect: a Join can carry Card while its revenue came from a Direct Debit invoice. Revenue by payment method for Joins will be misattributed, which breaks both requirements at once.

**Action:** Take the Join's segment keys from the same Campaign Year as its amount. Answer Q-013 that way.

### 1.5 Invoice selection can pick the wrong document (RULE-014)

"The latest invoice by trans_date that is not fully credited" has two problems:

- A credit note raised later could itself be selected if it appears as a subscription invoice row.
- It does not say what happens when every invoice in the year is fully credited.

Picking a single invoice also drops any other genuine, uncredited invoices in the year (for example a mid-year grade change or a Round 2 individual invoice after a corporate credit).

**Action:** Exclude credit notes from selection explicitly, define the all-credited case, and confirm with Finance (Q-012) whether more than one live invoice per year can be legitimate.

### 1.6 Null amounts need a reason on the event (RULE-041)

A Join, Renewal or Readmission with no invoice has null amounts. The reason sits only in `silv_data_anomaly`. On the event itself a null looks the same whether the invoice is missing, the year predates the invoice source (pre-2022, Q-011), or the item code is unmapped (RULE-030).

**Action:** Add an `amount_status` (or similar) column on the event: Invoiced, Full Concession, No invoice, Before invoice data, Unmapped lines. This makes every event's value explainable without a join to the anomaly table.

### 1.7 Unmapped item codes silently reduce amounts (RULE-030, Q-016)

Until a new item code is mapped, its value is left out of `subs_amount` and `fee_amount`. The event shows a lower figure with nothing to say so.

**Action:** Either hold unmapped amounts in an `other_amount` column, or flag the event as in 1.6.

### 1.8 Fee treatment needs Finance sign-off (RULE-034, Q-003)

Enrolment and application fees are excluded from Joins, and Renewals never carry a fee. If Finance counts enrolment fees as membership income, Join values will look low against their figures.

### 1.9 Corporate values will differ from Finance (RULE-038, Q-005)

Firm-level discounts (£2,500 or £5,000 for the largest firms) are not spread to individuals, so corporate revenue on events will be higher than Finance's. This is fine as a stated limitation, but the size of the difference should be known before Finance sees the numbers.

---

## 2. Gaps against "every event is segmentable"

### 2.1 Carried-forward flags do not reach the event fact (REQ-004, REQ-005)

The `*_carried` flags exist only on `silv_member_year_attributes`. Events receive the keys but not whether the value was real or copied from an earlier year. Lapse events and current-year events (CY2027 is now under way) will be mostly carried.

**Action:** Copy the carried flags (or a single `segments_carried` flag) onto `silv_membership_events` and `fact_membership_events`.

### 2.2 Payment method and payer type can contradict each other (RULE-021, REQ-004)

Enrolment-fee-only invoices are excluded from the payer type test but not from payment method. A member can be payment method Corporate and payer type Individual (test cases P3 and P5). Both segments will appear side by side on the same events.

**Action:** Apply the same invoice exclusions to both, or document how the pair should be read.

### 2.3 The double-payment rule does not say which payer type wins (RULE-026)

It requires exactly one payer type but does not say which.

**Action:** State the rule (for example Corporate where a scheme subscription exists, otherwise Individual).

### 2.4 Corporate subscription status is landed but not used (REQ-006)

`Sub Status` and `Round` are landed from `Subs.vwCorpSubscriptions` but play no part in the Corporate test. Round 2 leavers whose corporate subscription was credited could still be classed as Corporate.

### 2.5 Time-limited concessions are carried forward (RULE-051)

`apuk_perpetualnonperpetual` is landed but unused. Non-perpetual concessions (for example hardship) will carry into later years where the member no longer holds them. `apuk_dualmembership` is also landed and unused.

**Action:** Carry forward perpetual concessions only, or none.

### 2.6 Unrecognised payment codes are hidden as "Not recorded" (RULE-008, Q-014)

Missing values and unrecognised codes look the same. An "Other" value keeps them separate and visible.

### 2.7 Employer carry-forward uses the wrong trigger (RULE-063)

The rule carries forward when there is no invoice, but employer comes from the corporate scheme, not the invoice.

### 2.8 Events before 2022 will all be "Not recorded" (Q-011)

This is expected given the invoice source, but should be stated as a limitation so pre-2022 segment views are not read as data quality failures.

### 2.9 Id 0 covers cases that mean different things (RULE-008, RULE-015, RULE-018, RULE-060, Q-011)

Using id 0 as a fixed key for missing values is right: no event has a null key and none drop out of a filter. But one bucket ("Not recorded" or "Not determined") currently holds three different situations:

- **Unknown:** the source has no value (for example a blank payment mode, or no paid position for payer type).
- **Unrecognised:** the source has a value the mapping does not know (payment code 'XYZ', a concession item code not in the reference). This needs action and should stay visible (see 2.6).
- **Not applicable:** no value is expected. Individually funded members currently get employer "Not recorded" (RULE-060), which reads as a data gap when it is really "Individual, no employer". Pre-2022 years (2.8) also belong here.

Concession already separates "Not recorded" from "No concession". The same approach should apply to every segment:

| Segment | Labels to hold |
|---|---|
| Payment method | Unknown, Unrecognised, plus the five methods |
| Payer type | Unknown, Individual, Corporate |
| Concession | Unknown, Unrecognised, No concession, plus the types |
| Employer | Unknown, Not applicable (individual), Other, plus the top employers |

**Action:** Keep id 0 as Unknown, add fixed reserved ids for Unrecognised and Not applicable (for example -1 and -2) in every segment reference table, use the same labels across all segments, and update RULE-008, RULE-015, RULE-018, RULE-052, RULE-060 and the acceptance criteria that expect id 0. This is cheap at build and hard to separate once data is loaded.

---

## 3. Anomaly volumes

- **READMISSION_NO_FEE (RULE-044):** Free readmissions in Q2 are policy, so this will fire on many legitimate cases. It needs a reason code that separates free readmissions from missing fees.
- **EVENT_NO_INVOICE (RULE-042):** Every Join, Renewal and Readmission before 2022 will raise one. Limit anomalies to years the invoice source covers.

---

## 4. Other assumptions to confirm

| Ref | Assumption | Confirm with |
|---|---|---|
| Q-001 | Invoice payment mode is the system of record for payment method | RICS Data |
| Q-002 | Corporate = Corporate payment method plus a scheme subscription | Finance |
| Q-004 | GBP taken from the source accounting-currency amounts | Finance |
| Q-006 | Segments carry forward to years with no invoice | Finance, Membership Growth |
| Q-012 | Latest uncredited invoice sets the year's values | Finance |
| REQ-006 | Removing `silv_payment_events.payment_source` breaks nothing downstream | Mike |
| REQ-001 | Acceptance is on synthetic data only; no pass threshold set for real data (for example minimum payment method coverage) | Damian, Mike |

---

## 5. Scope and delivery

- **Employer segment (REQ-013):** This phase only explores employer as a segment. Full employer segmentation is planned for early 2027, and corporate views are being picked up separately by Alex. Recommend REQ-013 is delivered as findings only (Q-020) unless budget allows.
- **Design notes:** Five design notes need Damian's sign-off before each story builds.
- **Open questions:** Most of the 20 open questions sit with Finance. One working session with Haider covering Q-002 to Q-006 and Q-012 would unblock most of the build.

---

## 6. Summary of changes requested

1. Profile CUSTTRANS_RICS grain before build (1.1).
2. Match each invoice to at most one event (1.2).
3. Name one headline GBP value and add a net value (1.3).
4. Take Join segments from the same year as Join amounts (1.4).
5. Exclude credit notes and define the all-credited case in invoice selection (1.5).
6. Add an amount status column on events (1.6, 1.7).
7. Carry the carried-forward flags onto the event fact (2.1).
8. Align payment method and payer type exclusions, and state the double-payment winner (2.2, 2.3).
9. Use corporate subscription status in the Corporate test (2.4).
10. Stop carrying forward non-perpetual concessions (2.5).
11. Limit and reason-code anomalies (section 3).
12. Split id 0 into Unknown, Unrecognised and Not applicable, with consistent labels across all segments (2.9).
