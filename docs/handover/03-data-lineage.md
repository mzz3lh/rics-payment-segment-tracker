# Data lineage: RICS Payment Segment Tracker

## Sources

The solution reads objects that other systems own and maintain. It never creates, changes or writes to them; any change one would need goes to its owner. So far it reads five of them:

| Source | What it holds | Read by |
|---|---|---|
| Subs.tblSubsInvoices | Subscription invoices, one row per invoice, from Campaign Year 2022 onward, with payment method, currency, amounts, credits, payment status and concession flags | Layercake.usp_load_brnz_subs_invoice (landed in brnz_subs_invoice); Layercake.usp_load_brnz_subs_invoice_line (to decide which transaction rows are in scope) |
| synapse_fo.CUSTTRANS_RICS | Customer transaction rows, including invoice rows with item codes (productcode) and posting types, credits and payments | Layercake.usp_load_brnz_subs_invoice_line (landed in brnz_subs_invoice_line); Layercake.usp_profile_custtrans_grain |
| Subs.vwCorpSubscriptions | Corporate scheme subscriptions: the contact, scheme and Campaign Year, with each subscription's 'Sub Status' and each subscription user's 'Sub User Status' | Layercake.usp_load_brnz_corporate_subscription (landed in brnz_corporate_subscription); Layercake.usp_profile_corp_subscription_status |
| CE.vwConcessionType | The concession reference (assumed, Q-008): one row per concession type, with its name, discount, product number, state and whether it is perpetual | Layercake.usp_load_brnz_concession (landed in brnz_concession) |
| Subs.vwSubsMemberStatuses | Member invoice statuses, one row per contact and Campaign Year. Phase 1 already lands its Member Invoice Position, Renewal Date and Renewal Date Adj; the solution now also lands 'Inv Total Amount' (the contact-year's invoiced total in GBP) and 'Retired Concession' | The Phase 1 load Layercake.usp_load_brnz_subs_status (landed in brnz_subs_status), changed by MOD-017 |

The two profiles read their sources directly and keep nothing. The bronze loads copy their sources into the bronze tables without changing any value.

The payment method list (MOD-003) and the payer type list (MOD-004) are not read from any source: each is a fixed list put in place by its migration, and each dimension is copied from its list. The line-type mapping and the currency list (MOD-005) are filled from the bronze invoice tables, and the concession type list (MOD-006) from the concession bronze table, not read from a source directly. The concession type list's four starting rows (the three reserved values and 'No concession') are put in place by its migration.

The member-year attributes (MOD-007) read no source directly. They are worked out from the bronze tables and lists above, and from three Phase 1 Layercake tables, which they read and never change:

| Phase 1 table | What the attributes take from it |
|---|---|
| Layercake.silv_membership_events | The contacts, and each contact's first-event year (the earliest Campaign Year of their events) |
| Layercake.silv_payment_events | The Phase 1 paid positions: a row for a contact and Campaign Year means the contact has a paid position that year |
| Layercake.ref_campaign_year_config | The Campaign Years, and the start and end dates that decide the current Campaign Year |

The segment anomalies (MOD-008) also read no source directly. They are worked out from each contact-year's segment invoice, as recorded on the member-year attributes, together with the bronze invoice, invoice line and corporate subscription tables and the concession type list, and are written to the Phase 1 anomaly table, Layercake.silv_data_anomaly.

The derived retirement date (MOD-018) reads no source directly either. It is worked out from the Phase 1 member status table, Layercake.brnz_subs_status, which the Phase 1 run fills from Subs.vwSubsMemberStatuses in its bronze step. It replaces the hand-entered retirement date, apuk_retirementdate, which Phase 1 took from the CRM membership record landed in Layercake.brnz_rics_record. That value is still landed in brnz_rics_record, but no longer feeds the member base.

The event amounts (MOD-010) read no source directly either. Each event's amount and amount status come from the member invoice statuses in Layercake.brnz_subs_status ('Inv Total Amount' and the Member Invoice Position), never from the invoices. The events come from the Phase 1 event table, Layercake.silv_membership_events, and a Join's amount Campaign Year from the Phase 1 paid positions in Layercake.silv_payment_events. The pairing of events with invoices, for the invoice checks only, uses the eligible invoices in Layercake.vw_silv_eligible_invoice.

<!-- evidence: PROJECT_STANDARDS.md#Objects owned by other systems (external); docs/sources/external_catalogue.json#Subs.tblSubsInvoices; docs/sources/external_catalogue.json#synapse_fo.CUSTTRANS_RICS; docs/sources/external_catalogue.json#Subs.vwCorpSubscriptions; docs/sources/external_catalogue.json#CE.vwConcessionType; docs/sources/external_catalogue.json#Subs.vwSubsMemberStatuses; docs/specs/SPEC-001.json#Invoice source coverage; docs/sources/external/synapse_fo/synapse_fo.CUSTTRANS_RICS.sql#PostingType_Description; docs/design/MP-001.json#count-only procedures over the external sources; docs/dev/CN-MOD-001.json#Neither writes anything; docs/specs/SPEC-001.json#REQ-002; docs/specs/SPEC-001.json#RULE-004; docs/specs/SPEC-001.json#RULE-103; docs/design/DES-001.json#Existing Phase 1 landing of Subs.vwSubsMemberStatuses, one row per ([Contact No.], [Campaign Year]); docs/design/DES-001.json#Its key, its existing columns (Contact No., Campaign Year, Member Invoice Position, Renewal Date, Renewal Date Adj and the audit columns); src/sql/Layercake/Procedures/Layercake.usp_load_brnz_subs_status.sql#Subs.vwSubsMemberStatuses -> Layercake.brnz_subs_status; docs/dev/CN-MOD-017.json#objects_changed; docs/dev/CN-MOD-002.json#Line scope (RULE-077) reads Subs.tblSubsInvoices directly; docs/design/DES-001.json#1:1 landing of Subs.vwCorpSubscriptions; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Sub Status; docs/design/DES-001.json#1:1 landing of CE.vwConcessionType (working default source, Q-008); docs/specs/SPEC-001.json#CE.vwConcessionType.apuk_discount; docs/specs/SPEC-001.json#CE.vwConcessionType.apuk_perpetualnonperpetual; docs/design/DES-001.json#Static list seeded by its migration; docs/design/DES-001.json#Reference lists: payment method and payer type are static lists seeded by their migrations; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type; docs/design/DES-001.json#seen in live brnz_subs_invoice_line rows; docs/design/DES-001.json#(brnz_subs_invoice.inv_currency); docs/design/DES-001.json#Inserts new concession types from live brnz_concession rows; docs/dev/CN-MOD-006.json#the migration seeds 0 Unknown, -1 Unrecognised, -2 Not applicable and 1 No concession; docs/answers.md#Contact list and first-event year (RULE-011, Q-030); docs/answers.md#Phase 1 paid position (RULE-021, RULE-017); docs/answers.md#Current Campaign Year; docs/test/TCS-MOD-007.json#TC-007-050; docs/design/DES-001.json#Derives the four segment anomaly types; docs/test/TCS-MOD-008.json#SetUp fakes every table read or written; docs/test/TCS-MOD-008.json#TC-008-004; docs/test/TCS-MOD-008.json#TC-008-007; docs/test/TCS-MOD-008.json#TC-008-009; docs/test/TCS-MOD-008.json#TC-008-018; docs/design/DES-001.json#rec_id of the year's segment invoice; docs/design/DES-001.json#A new view derives each contact's retirement date from brnz_subs_status; docs/design/DES-001.json#in place of the latest brnz_rics_record row's apuk_retirementdate; docs/design/adr/ADR-005-where-the-derived-retirement-date-replaces-apuk-retirementda.md#it stays in bronze brnz_rics_record and in the reconciliation diagnostic columns; docs/design/DES-001.json#Layercake.silv_event_amount; docs/specs/SPEC-001.json#It never comes from the invoices or invoice lines; docs/specs/SPEC-001.json#Layercake.brnz_subs_status.Member Invoice Position; docs/dev/CN-MOD-010.json#a Join's = MIN(campaign_year) of the contact in silv_payment_events, else its own; docs/dev/CN-MOD-010.json#eligible invoices from vw_silv_eligible_invoice of the amount year; docs/test/TCS-MOD-010.json#Standard set-up for every test -->

## Source-to-target mappings

Every bronze mapping is one-to-one (RULE-004): the target column holds the source value unchanged, with no defaults, trimming or change of case. All bronze tables also carry the four audit columns _loaded_at, _updated_at, _is_deleted and _deleted_at, which the load sets (see the Architecture and data model document). The profiles have no target table; their tables show which source columns they use and how they become the counts they return. The payment method mappings show how a source payment mode code becomes a payment method, and how each list reaches its gold dimension. The line-type and currency mappings show how codes on the bronze invoice data reach their lists, and the currency list its dimension. The concession mappings show how the concession reference reaches the bronze table, the concession type list and its dimension. The member status mapping shows the two columns MOD-017 adds to the Phase 1 member status table. The retirement mappings show how the derived retirement date is worked out from the member invoice statuses and how it reaches Practising / Retired. The member-year mappings show which invoices count and how each segment of a contact-year is worked out; the rules themselves are set out in full in the Architecture and data model document. The segment anomaly mapping shows what each anomaly type is worked out from and how its row is filled. The event amount mapping shows where each event's amount, amount status and invoice pairing come from.

<!-- evidence: docs/specs/SPEC-001.json#RULE-004; docs/specs/SPEC-001.json#_loaded_at, _updated_at, _is_deleted, _deleted_at (and the same on brnz_subs_invoice_line); docs/answers.md#DES-001 Q-037 bronze audit columns; docs/test/TCS-MOD-002.json#TC-002-003; docs/test/TCS-MOD-004.json#TC-004-012; docs/test/TCS-MOD-006.json#TC-006-002; docs/design/MP-001.json#Builds no tables and changes no existing object; docs/specs/SPEC-001.json#RULE-095; docs/specs/SPEC-001.json#RULE-096; docs/specs/SPEC-001.json#RULE-007; docs/specs/SPEC-001.json#RULE-010; docs/specs/SPEC-001.json#RULE-029; docs/specs/SPEC-001.json#RULE-031; docs/specs/SPEC-001.json#RULE-045; docs/specs/SPEC-001.json#RULE-046; docs/specs/SPEC-001.json#RULE-103; docs/specs/SPEC-001.json#RULE-099; docs/specs/SPEC-001.json#RULE-100; docs/specs/SPEC-001.json#RULE-014; docs/design/DES-001.json#Layercake.silv_member_year_attributes; docs/design/DES-001.json#Layercake.usp_load_silv_data_anomaly_segment; docs/design/DES-001.json#Layercake.silv_event_amount -->

### Subscription invoices (Subs.tblSubsInvoices to Layercake.brnz_subs_invoice)

All rows of the source are landed, one row each, identified by rec_id.

| Source column | Target column | Note |
|---|---|---|
| Rec_ID | rec_id | Source row key |
| Account_Num | account_num | The RICS contact number |
| Campaign_Year | campaign_year | |
| Invoice | invoice | |
| Voucher | voucher | Used to find the invoice's lines and settling rows |
| Trans_Date | trans_date | |
| Inv_Payment_Method | inv_payment_method | Payment mode on the invoice; a missing value stays missing. Later mapped to a payment method by fn_map_payment_method |
| Inv_Currency | inv_currency | Feeds the currency list (silv_ref_currency) |
| Exchange_Rate | exchange_rate | |
| Full_Invoice_Amount_CUR | full_invoice_amount_cur | Used to tell a credit note from a zero-value invoice numbered 'CRE' (RULE-014) |
| Invoice_Amount_CUR | invoice_amount_cur | |
| Invoice_Amount_GBP | invoice_amount_gbp | |
| Inv_Credit_Amount_CUR | inv_credit_amount_cur | |
| Inv_Credit_Amount_GBP | inv_credit_amount_gbp | |
| Fully_Credited | fully_credited | Includes the source's 'N/A' for invoices with no credit |
| Payment_Status | payment_status | |
| Has_Concession | has_concession | |
| 100%_Concession | full_concession_flag | |

<!-- evidence: docs/specs/SPEC-001.json#Subs.tblSubsInvoices.Rec_ID; docs/specs/SPEC-001.json#1:1. Equals the RICS contact number.; docs/specs/SPEC-001.json#1:1 (F&O PAYMMODE on the invoice); docs/answers.md#brnz_subs_invoice.inv_payment_method; docs/specs/SPEC-001.json#Used to tell a credit note from a zero-value invoice numbered 'CRE' (RULE-014); docs/specs/SPEC-001.json#Subs.tblSubsInvoices.100%_Concession; docs/design/DES-001.json#Source column 100%_Concession; docs/answers.md#the source writes 'N/A' for invoices with no credit; docs/test/TCS-MOD-002.json#TC-002-001; docs/test/TCS-MOD-002.json#TC-002-002; docs/specs/SPEC-001.json#Layercake.brnz_subs_invoice.inv_currency -->

### Invoice lines (synapse_fo.CUSTTRANS_RICS to Layercake.brnz_subs_invoice_line)

Only rows that belong to an invoice in Subs.tblSubsInvoices are landed (RULE-077, assumed pending Q-021): the account number must match the invoice's, and either the voucher or the last settlement voucher must be the invoice's voucher. Each row is landed once, identified by recid.

| Source column | Target column | Note |
|---|---|---|
| RECID | recid | Source row key |
| ACCOUNTNUM | accountnum | Must equal the invoice's Account_Num |
| INVOICE | invoice | |
| VOUCHER | voucher | Matches the invoice's voucher for the invoice's own lines |
| LASTSETTLEVOUCHER | lastsettlevoucher | Matches the invoice's voucher for credits and payments settling it |
| TRANSDATE | transdate | Kept to the millisecond |
| TRANSTYPE | transtype | |
| RICINVOICETYPE | ricinvoicetype | Lines of every invoice type are landed. With productcode, feeds the line-type mapping |
| productcode | productcode | Item code, used for the line-type mapping (silv_ref_invoice_line_type) and for the concession value |
| AMOUNTCUR | amountcur | Amount in the invoice currency |
| AMOUNTMST | amountmst | Amount in GBP, the accounting currency |
| SETTLEAMOUNTCUR | settleamountcur | Used to weigh payment methods in the payment-line fallback |
| CURRENCYCODE | currencycode | |
| PAYMMODE | paymmode | Payment mode on payment lines. Mapped to a payment method by fn_map_payment_method |
| PAYMREFERENCE | paymreference | |
| ORDERNUM | ordernum | |

<!-- evidence: docs/specs/SPEC-001.json#RULE-077; docs/answers.md#RULE-077 settling rows; docs/specs/SPEC-001.json#synapse_fo.CUSTTRANS_RICS.RECID; docs/specs/SPEC-001.json#1:1. The item code used for the line-type mapping and the concession value.; docs/specs/SPEC-001.json#1:1 (invoice currency); docs/specs/SPEC-001.json#1:1 (GBP accounting currency); docs/specs/SPEC-001.json#1:1 (payment mode on payment lines); docs/answers.md#brnz_subs_invoice_line.paymmode; docs/answers.md#ABS(settleamountcur) is summed per mapped method; docs/specs/SPEC-001.json#synapse_fo.CUSTTRANS_RICS.ORDERNUM; docs/dev/CN-MOD-002.json#transdate keeps milliseconds; docs/test/TCS-MOD-002.json#TC-002-011; docs/test/TCS-MOD-002.json#TC-002-014; docs/design/DES-001.json#Adds each (productcode, ricinvoicetype) seen in live brnz_subs_invoice_line rows -->

### Member invoice statuses (Subs.vwSubsMemberStatuses to Layercake.brnz_subs_status)

The Phase 1 load lands one row per contact and Campaign Year (RULE-103). Rows with no contact number or no Campaign Year are not landed, and where the source has two rows for the same contact and Campaign Year, the one with the latest Renewal Date Adj is kept, as in Phase 1. MOD-017 adds the last two columns below; the first five are the Phase 1 columns, unchanged.

| Source column | Target column | Note |
|---|---|---|
| Contact No. | Contact No. | Phase 1 column, part of the row's identity; unchanged |
| Campaign Year | Campaign Year | Phase 1 column, part of the row's identity; unchanged |
| Member Invoice Position | Member Invoice Position | Phase 1 column; unchanged. Also sets the amount status of events (MOD-010) |
| Renewal Date | Renewal Date | Phase 1 column; unchanged. Gives the derived retirement date (MOD-018) |
| Renewal Date Adj | Renewal Date Adj | Phase 1 column; unchanged. Not used for the derived retirement date |
| Inv Total Amount | inv_total_amount | New. The contact-year's invoiced total in GBP, copied unchanged with the source's full precision; a missing value stays missing. The source of each event's invoiced amount (MOD-010) |
| Retired Concession | retired_concession | New. 'No Invoice', 'No Conc.', 'Retired Conc.' or 'Non-Retired Conc.', copied byte for byte, letter case and trailing spaces included. Used for the derived retirement date (MOD-018) |

<!-- evidence: docs/specs/SPEC-001.json#RULE-103; docs/specs/SPEC-001.json#Subs.vwSubsMemberStatuses.Inv Total Amount; docs/specs/SPEC-001.json#1:1 (new column, GBP). Null where the source is null.; docs/specs/SPEC-001.json#Subs.vwSubsMemberStatuses.Retired Concession; docs/specs/SPEC-001.json#The source writes 'No Invoice', 'No Conc.', 'Retired Conc.' or 'Non-Retired Conc.'.; docs/design/DES-001.json#'Inv Total Amount', 1:1, GBP. Same type as the source, so no value is narrowed; docs/design/DES-001.json#'Retired Concession', 1:1; docs/design/DES-001.json#Its key, its existing columns (Contact No., Campaign Year, Member Invoice Position, Renewal Date, Renewal Date Adj and the audit columns), their names and its rows are unchanged; src/sql/Layercake/Procedures/Layercake.usp_load_brnz_subs_status.sql#Rows with a null contact are; src/sql/Layercake/Procedures/Layercake.usp_load_brnz_subs_status.sql#order by [Renewal Date Adj] desc; docs/dev/CN-MOD-017.json#test a duplicate source key keeps the row with the latest Renewal Date Adj and its new columns; docs/dev/CN-MOD-017.json#test a case-only or trailing-space change in Retired Concession is landed byte for byte; docs/answers.md#inv_total_amount (from 'Inv Total Amount') and retired_concession (from 'Retired Concession'); docs/test/TCS-MOD-017.json#TC-017-001; docs/test/TCS-MOD-017.json#TC-017-002; docs/test/TCS-MOD-017.json#TC-017-007; docs/specs/SPEC-001.json#Layercake.brnz_subs_status.Member Invoice Position; docs/dev/CN-MOD-010.json#it takes brnz_subs_status.inv_total_amount (live row); docs/design/MP-001.json#MOD-010; docs/design/MP-001.json#MOD-018; docs/test/TCS-MOD-018.json#The view uses Renewal Date, not Renewal Date Adj -->

### Derived retirement date (Layercake.brnz_subs_status to Layercake.vw_silv_derived_retirement_date to Layercake.silv_member_base)

The view gives one row per contact that has a derived retirement date (RULE-099), and the member base load writes that date to the member's retirement date (RULE-100, RULE-101). Only live rows of brnz_subs_status take part.

| Source | Target | Note |
|---|---|---|
| brnz_subs_status.Contact No. | vw_silv_derived_retirement_date.contact_no | One row per contact with at least one live 'Retired Conc.' row that has a Renewal Date |
| brnz_subs_status.retired_concession | (filter) | Only 'Retired Conc.' rows count; a value differing only in letter case or trailing spaces counts too. Rows marked as deleted are left out |
| brnz_subs_status.Campaign Year | vw_silv_derived_retirement_date.retirement_campaign_year | The lowest Campaign Year among those rows that has a Renewal Date |
| brnz_subs_status.Renewal Date | vw_silv_derived_retirement_date.derived_retirement_date | That row's Renewal Date: the first payment date, or a Full Concession invoice's settlement date kept inside the Campaign Year (Q-041). Renewal Date Adj is not used |
| vw_silv_derived_retirement_date.derived_retirement_date | silv_member_base.retirement_date | Matched on the contact number. Empty where the contact has no derived date: no fallback to apuk_retirementdate or to 'First Retired Year' (Q-040) |
| brnz_rics_record.apuk_retirementdate | (no longer used) | Filled silv_member_base.retirement_date in Phase 1 |

<!-- evidence: docs/specs/SPEC-001.json#RULE-099; docs/specs/SPEC-001.json#RULE-100; docs/specs/SPEC-001.json#RULE-101; docs/specs/SPEC-001.json#Layercake.brnz_subs_status.Renewal Date; docs/specs/SPEC-001.json#the [Renewal Date] of the row with the lowest [Campaign Year]. Null where the contact has no such row.; docs/specs/SPEC-001.json#Filter: [Retired Concession] = 'Retired Conc.' (RULE-099).; docs/design/DES-001.json#brnz_subs_status [Contact No.]; docs/design/DES-001.json#Campaign Year of the row that gives the date; docs/design/DES-001.json#That row's Renewal Date: the contact-year's first payment, or a Full Concession invoice's settlement date kept inside the Campaign Year (Q-041); docs/design/DES-001.json#Changed in one respect only: retirement_date is taken from vw_silv_derived_retirement_date for the contact_no; docs/design/DES-001.json#in place of the latest brnz_rics_record row's apuk_retirementdate, and is null where the contact has no derived date; docs/specs/SPEC-001.json#Q-040; docs/specs/SPEC-001.json#Q-041; docs/dev/CN-MOD-018.json#test a case or trailing space variant of Retired Conc counts as retired; docs/test/TCS-MOD-018.json#TC-018-001; docs/test/TCS-MOD-018.json#TC-018-003; docs/test/TCS-MOD-018.json#TC-018-006; docs/test/TCS-MOD-018.json#TC-018-007; docs/test/TCS-MOD-018.json#TC-018-008 -->

### Membership status (Layercake.silv_member_base.retirement_date to Practising / Retired)

The Phase 1 status rule reads the retirement date in the member base, which now holds the derived date: a member is Retired from that date, inclusive; the rest of the rule is unchanged (RULE-100). The Phase 1 loads that apply it are unchanged.

| Source | Target | Note |
|---|---|---|
| silv_member_base.retirement_date | silv_membership_events.membership_status_id, copied to fact_membership_events | Set on every event on each Phase 1 run. No event, event date or identifier changes |
| silv_member_base.retirement_date | silv_annual_rate_base membership status, copied to fact_annual_rate_base | Worked out again for every Campaign Year on each Phase 1 run |
| silv_member_base.retirement_date, through the copy in silv_member_profile.retirement_date | silv_daily_count_detail membership status, copied to fact_daily_member_count_detail | Days already loaded change only after the one-off rebuild (see the Runbook) |

<!-- evidence: docs/specs/SPEC-001.json#The Phase 1 status rule, reading the derived retirement date in place of Layercake.silv_member_base.retirement_date (RULE-100, RULE-101); docs/specs/SPEC-001.json#Layercake.silv_membership_events.membership_status_id, and the membership status of fact_membership_events, silv_annual_rate_base, fact_annual_rate_base, silv_daily_count_detail and fact_daily_member_count_detail; docs/specs/SPEC-001.json#The contact is Retired from that date, inclusive. The rest of the status logic is unchanged.; docs/answers.md#Q-048; docs/assumptions.md#silv_member_profile.retirement_date is a diff-synced copy of silv_member_base.retirement_date; src/sql/Layercake/Procedures/Layercake.usp_load_silv_annual_rate_base.sql#does pick up retrospective corrections immediately; docs/design/DES-001.json#Daily history after the retirement change (ASM-002); docs/test/TCS-MOD-018.json#TC-018-012; docs/test/TCS-MOD-018.json#TC-018-013; docs/test/TCS-MOD-018.json#TC-018-015; docs/test/TCS-MOD-018.json#TC-018-017; docs/test/TCS-MOD-018.json#TC-018-018; docs/test/TCS-MOD-018.json#TC-018-019; docs/test/TCS-MOD-018.json#TC-018-020 -->

### Corporate subscriptions (Subs.vwCorpSubscriptions to Layercake.brnz_corporate_subscription)

All rows of the source are landed, one row each, identified by contact number, scheme number and Campaign Year together (the source has no row key; see Q-033 in Known limitations).

| Source column | Target column | Note |
|---|---|---|
| Contact No | contact_no | Part of the row's identity; must be present |
| Scheme No | scheme_no | Part of the row's identity; must be present. Becomes corporate_account_ref for Corporate years |
| Scheme Name | scheme_name | A missing or blank name is kept as it is |
| Sub Campaign Year | sub_campaign_year | Part of the row's identity; must be present |
| Sub Status | sub_status | The subscription's status, kept exactly as the source has it. With Sub User Status, decides whether the subscription is live |
| Sub User Status | sub_user_status | The subscription user's status, kept exactly as the source has it |
| Round | (not landed) | Plays no part in the solution |

<!-- evidence: docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Contact No; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Scheme No; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Scheme Name; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Sub Campaign Year; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Sub Status; docs/specs/SPEC-001.json#Subs.vwCorpSubscriptions.Sub User Status; docs/specs/SPEC-001.json#The live-subscription test uses Layercake.brnz_corporate_subscription; docs/specs/SPEC-001.json#Layercake.silv_member_year_attributes.corporate_account_ref; docs/design/DES-001.json#The source has no row key; docs/design/DES-001.json#'Round' is not landed and plays no part; docs/answers.md#MOD-004 NULL matching key; docs/test/TCS-MOD-004.json#TC-004-008; docs/test/TCS-MOD-004.json#TC-004-009; docs/test/TCS-MOD-004.json#TC-004-011; docs/test/TCS-MOD-004.json#TC-004-012 -->

### Concession types (CE.vwConcessionType to Layercake.brnz_concession)

All rows of the source are landed, one row each, identified by the concession type id (apuk_concessiontypeid), which must be present and must not repeat (RULE-045, assumed pending Q-008).

| Source column | Target column | Note |
|---|---|---|
| apuk_concessiontypeid | apuk_concessiontypeid | The concession type's id; the row's identity; must be present |
| apuk_name | apuk_name | The type's name; a missing or untrimmed name is kept as it is |
| apuk_discount | apuk_discount | The discount; decides whether the type is a full concession, and which concession wins when an invoice carries several |
| Product_Number | product_number | Kept exactly as the source has it; later gives the type's item code |
| statecode | statecode | |
| apuk_perpetualnonperpetual | apuk_perpetualnonperpetual | Perpetual (200000000) or Non-Perpetual (200000001); later decides whether the type is perpetual |
| apuk_dualmembership | (not landed) | Plays no part in this release |

<!-- evidence: docs/specs/SPEC-001.json#CE.vwConcessionType.apuk_concessiontypeid; docs/specs/SPEC-001.json#CE.vwConcessionType.apuk_name; docs/specs/SPEC-001.json#CE.vwConcessionType.apuk_discount; docs/specs/SPEC-001.json#CE.vwConcessionType.Product_Number; docs/specs/SPEC-001.json#CE.vwConcessionType.statecode; docs/specs/SPEC-001.json#CE.vwConcessionType.apuk_perpetualnonperpetual; docs/specs/SPEC-001.json#RULE-045; docs/design/DES-001.json#apuk_discount through the business key; docs/design/DES-001.json#apuk_dualmembership is not landed (Q-025); docs/answers.md#apuk_dualmembership (v2 Q-025); docs/answers.md#MOD-006 NULL key, duplicate key and missing name; docs/test/TCS-MOD-006.json#TC-006-001; docs/test/TCS-MOD-006.json#TC-006-002; docs/test/TCS-MOD-006.json#TC-006-009 -->

### Concession type list (Layercake.brnz_concession to Layercake.silv_ref_concession_type)

usp_load_silv_ref_concession_type adds each live concession type not yet listed and updates a listed type whose name, item code or flags have changed; ids never change (RULE-046). Types marked as deleted in the bronze table are not added. The four starting rows are not taken from the bronze table.

| Source column (brnz_concession) | Target column (silv_ref_concession_type) | Note |
|---|---|---|
| (new type) | id | A new id for each new type, never changed; the starting rows have fixed ids |
| apuk_concessiontypeid | concession_type_bk | Identifies the type; empty for the four starting rows |
| apuk_name | concession_type_name | Updated when the source name changes. A missing, empty or blank name becomes 'Unnamed concession type' |
| product_number | item_code | Any 'rcs' prefix removed (RULE-048): 'rcsCONRETIRED' gives 'CONRETIRED' |
| apuk_discount | is_full_concession | 1 where the discount is exactly 100, otherwise 0 (RULE-047) |
| apuk_perpetualnonperpetual | is_perpetual | 1 where the value is 200000000 (Perpetual); 0 for any other value, including 200000001 and missing (RULE-094) |
| (the load's run) | load_id | The load log entry of the load that last wrote the row; empty for the starting rows |

<!-- evidence: docs/specs/SPEC-001.json#RULE-046; docs/specs/SPEC-001.json#Layercake.brnz_concession.apuk_concessiontypeid; docs/design/DES-001.json#null for reserved rows and No concession; docs/design/DES-001.json#Fixed for reserved rows and No concession; docs/specs/SPEC-001.json#Updated when the source name changes. Fixed names for the reserved rows and No concession.; docs/answers.md#concession_type_name N'Unnamed concession type'; docs/design/DES-001.json#product_number with any 'rcs' prefix removed (RULE-048); docs/specs/SPEC-001.json#A source Product_Number of 'rcsCONRETIRED' gives item_code 'CONRETIRED'.; docs/design/DES-001.json#1 where apuk_discount = 100, else 0; docs/design/DES-001.json#1 where apuk_perpetualnonperpetual = 200000000, else 0 (null included); docs/test/TCS-MOD-006.json#TC-006-010; docs/test/TCS-MOD-006.json#TC-006-011; docs/test/TCS-MOD-006.json#TC-006-016; docs/test/TCS-MOD-006.json#TC-006-017; docs/test/TCS-MOD-006.json#TC-006-018 -->

### Concession type dimension (Layercake.silv_ref_concession_type to Layercake.dim_concession_type)

Every row of the list is copied, the reserved rows and 'No concession' included, by usp_load_dim_concession_type.

| Source column (silv_ref_concession_type) | Target column (dim_concession_type) | Note |
|---|---|---|
| id | id | Same id, never changed |
| concession_type_name | concession_type_name | Corrected when the list's name changes |
| is_full_concession | is_full_concession | Corrected when the list's flag changes |
| is_perpetual | is_perpetual | Corrected when the list's flag changes |
| (the load's run) | load_id | The load log entry of the load that last wrote the row |

<!-- evidence: docs/design/DES-001.json#Gold copy of silv_ref_concession_type.; docs/design/DES-001.json#Mirrors silv_ref_concession_type into dim_concession_type. Logged.; docs/specs/SPEC-001.json#AC-010-05; docs/test/TCS-MOD-006.json#TC-006-023; docs/test/TCS-MOD-006.json#TC-006-025; docs/answers.md#DES-001 load_id -->

### Payment mode code to payment method (Layercake.fn_map_payment_method, using Layercake.silv_ref_payment_method)

The function takes one payment mode code, from brnz_subs_invoice.inv_payment_method or brnz_subs_invoice_line.paymmode, and returns a payment method id from silv_ref_payment_method (RULE-007, RULE-008). Letter case and spaces before or after the code are ignored.

| Source payment mode code | Payment method | Id |
|---|---|---|
| DD | Direct Debit | 1 to 5 (one id per method) |
| Card | Card | |
| Bank | Bank transfer | |
| Cheque | Cheque | |
| Corporate | Corporate | |
| Missing, empty or spaces only | Unknown | 0 |
| Any other code, including 'Mixed' | Unrecognised | -1 |

Not applicable (-2) is never the result of this mapping. There is no Mixed payment method, an assumption awaiting Q-015 (see Known limitations).

<!-- evidence: docs/specs/SPEC-001.json#Source payment mode codes map as follows; docs/specs/SPEC-001.json#Any other source code maps to Unrecognised (-1); docs/specs/SPEC-001.json#Layercake.silv_ref_payment_method.source_code; docs/answers.md#MOD-003 fn_map_payment_method; docs/test/TCS-MOD-003.json#TC-003-003; docs/test/TCS-MOD-003.json#TC-003-006; docs/test/TCS-MOD-003.json#TC-003-013; docs/dev/CN-MOD-003.json#It never matches a reserved row; docs/specs/SPEC-001.json#There is no Mixed value (assumes Q-015). -->

### Payment method dimension (Layercake.silv_ref_payment_method to Layercake.dim_payment_method)

Every row of the list is copied, reserved rows included, by usp_load_dim_payment_method (RULE-010).

| Source column (silv_ref_payment_method) | Target column (dim_payment_method) | Note |
|---|---|---|
| id | id | Same id, never changed |
| payment_method_name | payment_method_name | Corrected when the list's name changes, including a change only in letter case |
| (the load's run) | load_id | The load log entry of the load that last wrote the row |

<!-- evidence: docs/specs/SPEC-001.json#RULE-010; docs/specs/SPEC-001.json#Layercake.dim_payment_method.payment_method_name; docs/design/DES-001.json#payment_method_name; docs/design/DES-001.json#Mirrors silv_ref_payment_method into dim_payment_method; docs/test/TCS-MOD-003.json#TC-003-009; docs/test/TCS-MOD-003.json#TC-003-010; docs/answers.md#DES-001 load_id -->

### Payer type dimension (Layercake.silv_ref_payer_type to Layercake.dim_payer_type)

Every row of the list is copied, reserved rows included, by usp_load_dim_payer_type.

| Source column (silv_ref_payer_type) | Target column (dim_payer_type) | Note |
|---|---|---|
| id | id | Same id, never changed |
| payer_type_name | payer_type_name | Corrected when the list's name changes, including a change only in letter case |
| (the load's run) | load_id | The load log entry of the load that last wrote the row |

<!-- evidence: docs/design/DES-001.json#payer_type_name; docs/design/DES-001.json#Mirrors silv_ref_payer_type into dim_payer_type; docs/test/TCS-MOD-004.json#TC-004-004; docs/test/TCS-MOD-004.json#TC-004-005; docs/answers.md#DES-001 load_id -->

### Invoice item codes to line types (Layercake.brnz_subs_invoice_line to Layercake.silv_ref_invoice_line_type)

usp_load_silv_ref_invoice_line_type adds each item code and RIC invoice type pair found on the live invoice lines that is not yet listed (RULE-029). It never changes a row already listed.

| Source column (brnz_subs_invoice_line) | Target column (silv_ref_invoice_line_type) | Note |
|---|---|---|
| productcode | item_code | A missing, empty or blank item code adds no row |
| ricinvoicetype | ric_invoice_type | A missing invoice type is stored as empty |
| (new pair) | line_type | Always 'unmapped' when added; a person sets the line type by hand |
| (the load's run) | load_id | The load log entry of the load that added the row; empty for the starting rows |

The 12 starting rows (the item codes that Subs.usp_Refresh_SubsInvoices names, confirmed under Q-034) are not taken from the invoice lines; see the Architecture and data model document.

<!-- evidence: docs/design/DES-001.json#Adds each (productcode, ricinvoicetype) seen in live brnz_subs_invoice_line rows that is not yet mapped, with line type 'unmapped'. Existing rows are never chan; docs/design/DES-001.json#brnz_subs_invoice_line.productcode; docs/design/DES-001.json#brnz_subs_invoice_line.ricinvoicetype; docs/answers.md#MOD-005 NULL, blank and near-duplicate codes; docs/test/TCS-MOD-005.json#TC-005-005; docs/test/TCS-MOD-005.json#TC-005-006; docs/answers.md#Q-034 line-type mapping seed -->

### Invoice currency to currency list and dimension (Layercake.brnz_subs_invoice to Layercake.silv_ref_currency to Layercake.dim_currency)

usp_load_silv_ref_currency adds each currency found on the live invoices that is not yet listed, with a new id (RULE-031); usp_load_dim_currency then copies the list to the dimension.

| Source column | Target column | Note |
|---|---|---|
| brnz_subs_invoice.inv_currency | silv_ref_currency.currency_code | A missing, empty or blank currency adds no row; a code that differs from a listed one only in letter case or trailing spaces adds no row |
| (new code) | silv_ref_currency.id | A new id, never changed |
| silv_ref_currency.id | dim_currency.id | Same id |
| silv_ref_currency.currency_code | dim_currency.currency_code | Corrected when the list's code changes |
| (the load's run) | load_id on both tables | The load log entry of the load that last wrote the row |

<!-- evidence: docs/specs/SPEC-001.json#RULE-031; docs/design/DES-001.json#(brnz_subs_invoice.inv_currency); docs/design/DES-001.json#currency_code; docs/answers.md#usp_load_silv_ref_currency works the same way; docs/test/TCS-MOD-005.json#TC-005-020; docs/test/TCS-MOD-005.json#TC-005-021; docs/test/TCS-MOD-005.json#TC-005-023; docs/design/DES-001.json#Mirrors silv_ref_currency into dim_currency. Logged.; docs/answers.md#DES-001 load_id -->

### Eligible invoices (Layercake.brnz_subs_invoice and Layercake.brnz_subs_invoice_line to Layercake.vw_silv_eligible_invoice)

The view reads the live invoices and their own live lines, and lists the eligible invoices of each contact-year (RULE-014, RULE-079). It holds no data of its own.

| Source | View column | Note |
|---|---|---|
| brnz_subs_invoice.account_num | contact_no | The account number is the contact number. Invoices with no account number are left out |
| brnz_subs_invoice.campaign_year | campaign_year | Invoices with no Campaign Year are left out |
| brnz_subs_invoice.rec_id, invoice, voucher, trans_date, inv_payment_method, inv_currency | the same names | Copied as they are |
| brnz_subs_invoice.invoice and full_invoice_amount_cur | (filter) | Credit notes ('FTCN', or 'CRE' unless the full amount is exactly 0) are left out |
| brnz_subs_invoice.fully_credited | is_fully_credited | 1 only for 'Y'. Fully credited invoices are left out unless the contact-year has no other eligible invoice (assumed, Q-012) |
| brnz_subs_invoice_line.productcode and ricinvoicetype, through silv_ref_invoice_line_type | (filter) | The invoice's own lines (same account and voucher) are typed through the line-type mapping. Fee-only invoices are left out |
| brnz_subs_invoice.full_concession_flag | is_full_concession | Whether the invoice carries a full concession |
| brnz_subs_invoice.trans_date and rec_id | invoice_seq | Position in date order within the contact-year; a missing date comes first, equal dates by rec_id |
| (derived) | is_segment_invoice | 1 for the latest eligible invoice of the contact-year, ties to the higher rec_id (assumed, Q-012 and Q-036) |

<!-- evidence: docs/design/DES-001.json#Layercake.vw_silv_eligible_invoice; docs/specs/SPEC-001.json#RULE-014; docs/specs/SPEC-001.json#RULE-079; docs/answers.md#Eligible invoice (RULE-014, vw_silv_eligible_invoice); docs/answers.md#contact_no = account_num; docs/dev/CN-MOD-007.json#invoice_seq (ascending trans_date with NULL first, ties by rec_id); docs/dev/CN-MOD-007.json#is_full_concession; docs/test/TCS-MOD-007.json#TC-007-023; docs/test/TCS-MOD-007.json#TC-007-022 -->

### Member-year attributes (to Layercake.silv_member_year_attributes)

usp_load_silv_member_year_attributes works out one row per contact and Campaign Year, from the contact's first-event year to the current Campaign Year, and writes only the differences. The full rules are in the Architecture and data model document.

| Source | Target column | Note |
|---|---|---|
| silv_membership_events.contact_no | contact_no | Every contact with a membership event |
| ref_campaign_year_config.campaign_year | campaign_year | Every Campaign Year from the contact's earliest event year (in silv_membership_events) to the Campaign Year covering the as-of date |
| vw_silv_eligible_invoice.rec_id (the segment invoice) | segment_invoice_rec_id | Empty where the year has no eligible invoice |
| Segment invoice's inv_payment_method, else its payment lines' paymmode and settleamountcur in brnz_subs_invoice_line, through fn_map_payment_method | payment_method_id | RULE-012 to RULE-016. Before 2022: Not applicable (-2). Never empty |
| (derived) | payment_method_carried | 1 when carried forward from an earlier year with an eligible invoice |
| Segment invoice's payment method and payment lines, brnz_corporate_subscription (live rows with both statuses 'Active'), silv_payment_events | payer_type_id | RULE-021 to RULE-026, RULE-082, RULE-083: Corporate, Individual or Unknown. Before 2022: Not applicable (-2). Never empty |
| (derived) | payer_type_carried | 1 when carried forward |
| brnz_corporate_subscription.scheme_no | corporate_account_ref | Corporate years only; the lowest scheme number where there are several (assumed, Q-019 and Q-036) |
| Segment invoice's own lines with an item code starting 'CON' (brnz_subs_invoice_line.productcode), through silv_ref_concession_type.item_code, with brnz_concession.apuk_discount to choose between several | concession_type_id | RULE-049 to RULE-052. No concession line: No concession. A code not in the list: Unrecognised. Before 2022: Not applicable (-2). Never empty |
| silv_ref_concession_type.is_perpetual | concession_type_carried | 1 when carried forward, which happens only for a perpetual concession |
| (the load's run) | load_id | The load log entry of the load that last wrote the row |

<!-- evidence: docs/design/DES-001.json#Layercake.silv_member_year_attributes; docs/specs/SPEC-001.json#Layercake.silv_member_year_attributes.contact_no; docs/answers.md#Contact list and first-event year (RULE-011, Q-030); docs/answers.md#Current Campaign Year; docs/specs/SPEC-001.json#Layercake.silv_member_year_attributes.payment_method_id; docs/answers.md#Payment-line fallback (RULE-013); docs/specs/SPEC-001.json#Layercake.silv_member_year_attributes.payer_type_id; docs/design/DES-001.json#Attributes, payer type; docs/specs/SPEC-001.json#Layercake.silv_member_year_attributes.corporate_account_ref; docs/specs/SPEC-001.json#Layercake.silv_member_year_attributes.concession_type_id; docs/design/DES-001.json#Attributes, concession; docs/specs/SPEC-001.json#RULE-080; docs/specs/SPEC-001.json#RULE-051; docs/answers.md#DES-001 load_id -->

### Segment anomalies (to Layercake.silv_data_anomaly)

usp_load_silv_data_anomaly_segment works out the four segment anomaly types for contact-years from 2022 that have a live segment invoice, and writes only the differences. The full rules are in the Architecture and data model document.

| Anomaly type | Worked out from |
|---|---|
| CORPORATE_FLAG_NO_SCHEME | The segment invoice's payment method, and the live rows of brnz_corporate_subscription for the contact and Campaign Year, with sub_status and sub_user_status 'Active' (assumed, Q-002 and Q-027) |
| DOUBLE_PAYMENT | The segment invoice's live payment lines in brnz_subs_invoice_line, on its own account, and their payment modes (paymmode) |
| CONCESSION_NOT_IN_REFERENCE | The concession item codes (productcode) on the segment invoice's own lines in brnz_subs_invoice_line, compared with silv_ref_concession_type.item_code |
| FULL_CONCESSION_NO_CONCESSION | The contact-year's Full Concession position, and whether the concession on the segment invoice is a full-rate type (silv_ref_concession_type.is_full_concession) |

Each anomaly row is filled as follows:

| Source | Target column (silv_data_anomaly) | Note |
|---|---|---|
| silv_member_year_attributes.segment_invoice_rec_id, matched to a live row of brnz_subs_invoice | (filter) | Only contact-years from 2022 with a live segment invoice are looked at |
| (the rule that raised the case) | anomaly_type | One of the four types above |
| The contact-year's contact | contact_no | |
| Anomaly type, contact number and Campaign Year, and for CONCESSION_NOT_IN_REFERENCE the unknown item code | anomaly_nk | Joined by colons; identifies the case |
| The Campaign Year, and the segment invoice's invoice number and rec_id (brnz_subs_invoice) | detail | Rewritten when its text changes, for example when the segment invoice changes |
| (the load's run) | first_detected_at, last_seen_at | When the case was first recorded; not changed later |

<!-- evidence: docs/design/DES-001.json#Layercake.usp_load_silv_data_anomaly_segment; docs/dev/CN-MOD-008.json#For contact-years from 2022 with a live segment invoice; docs/specs/SPEC-001.json#RULE-025; docs/specs/SPEC-001.json#RULE-026; docs/specs/SPEC-001.json#RULE-052; docs/specs/SPEC-001.json#RULE-053; docs/specs/SPEC-001.json#Layercake.silv_data_anomaly (CONCESSION_NOT_IN_REFERENCE and FULL_CONCESSION_NO_CONCESSION rows); docs/test/TCS-MOD-008.json#TC-008-004; docs/test/TCS-MOD-008.json#TC-008-008; docs/test/TCS-MOD-008.json#TC-008-009; docs/test/TCS-MOD-008.json#TC-008-011; docs/test/TCS-MOD-008.json#TC-008-018; docs/test/TCS-MOD-008.json#TC-008-022; docs/test/TCS-MOD-008.json#TC-008-023; docs/test/TCS-MOD-008.json#TC-008-007; docs/dev/CN-MOD-008.json#test a soft-deleted segment invoice raises nothing and removes its old case; docs/dev/CN-MOD-008.json#test double payment counts an unrecognised mode as another method but not own lines or other accounts; docs/dev/CN-MOD-008.json#anomaly_nk is '<type>:<contact_no>:<campaign_year>[:<item_code>]'; docs/dev/CN-MOD-008.json#detail names the Campaign Year and the segment invoice (number and rec_id); docs/dev/CN-MOD-008.json#updates detail on a case that is still raised when the text has changed; docs/dev/CN-MOD-008.json#leaves first_detected_at and last_seen_at as they were; docs/design/DES-001.json#rec_id of the year's segment invoice -->

### Event amounts (to Layercake.silv_event_amount)

usp_load_silv_event_amount works out one row for every Join, Renewal and Readmission in the Phase 1 event table, and writes only the differences. No column is ever filled from an invoice or invoice line amount. The full rules are in the Architecture and data model document.

| Source | Target column | Note |
|---|---|---|
| silv_membership_events.event_nk, event_id, contact_no, event_type, event_date | the same names | Join, Renewal and Readmission events only; Change and Lapse get no row |
| silv_membership_events.campaign_year; for a Join, the contact's earliest silv_payment_events.campaign_year | amount_campaign_year | RULE-032. A Join whose contact has no paid position uses its own year (assumed, Q-029) |
| brnz_subs_status.inv_total_amount, from the live row with the same contact number and Campaign Year as the event's contact and amount Campaign Year | invoiced_subtotal_gbp | Copied as the source gives it, onto the one event per contact and amount Campaign Year chosen by RULE-098 (Readmission, Renewal, Join, earliest date, lowest event_id). Empty on the other events, before 2022, where there is no live row, and where the value is empty |
| (same value) | subs_amount_gbp | Always equal to invoiced_subtotal_gbp, and empty with it (RULE-035, Q-044) |
| brnz_subs_status.Member Invoice Position, with whether a live row and an amount exist and which event carries the amount | amount_status | RULE-088: Before invoice data, No invoice, Counted on another event, Full Concession, Fully credited or Invoiced |
| vw_silv_eligible_invoice.rec_id, for the same contact and amount Campaign Year from 2022 | invoice_rec_id | The invoice paired with the event by date (RULE-084 to RULE-086); empty where none. Used only for the invoice checks |
| (derived from the pairing) | match_outcome | Matched, No eligible invoice, Invoice shortfall or Before invoice data |
| (the load's run) | load_id | The load log entry of the load that last wrote the row |

<!-- evidence: docs/design/DES-001.json#Layercake.silv_event_amount; docs/design/DES-001.json#Layercake.usp_load_silv_event_amount; docs/dev/CN-MOD-010.json#No invoice or line amount is read; docs/specs/SPEC-001.json#RULE-032; docs/specs/SPEC-001.json#Q-029; docs/dev/CN-MOD-010.json#a Join's = MIN(campaign_year) of the contact in silv_payment_events, else its own; docs/specs/SPEC-001.json#Layercake.brnz_subs_status.Inv Total Amount; docs/specs/SPEC-001.json#Live row (_is_deleted = 0) with [Contact No.] = contact_no and [Campaign Year] = the event's amount Campaign Year (RULE-032); docs/specs/SPEC-001.json#RULE-098; docs/specs/SPEC-001.json#RULE-033; docs/specs/SPEC-001.json#RULE-041; docs/specs/SPEC-001.json#Same value as invoiced_subtotal_gbp (RULE-035).; docs/specs/SPEC-001.json#Q-044; docs/specs/SPEC-001.json#Layercake.brnz_subs_status.Member Invoice Position; docs/specs/SPEC-001.json#RULE-088; docs/design/DES-001.json#Matched eligible invoice for the REQ-009 checks; docs/specs/SPEC-001.json#RULE-084; docs/specs/SPEC-001.json#RULE-086; docs/dev/CN-MOD-010.json#match_outcome: 'Before invoice data' (<2022), 'No eligible invoice', 'Invoice shortfall', 'Matched'; docs/answers.md#DES-001 load_id; docs/test/TCS-MOD-010.json#TC-010-001; docs/test/TCS-MOD-010.json#TC-010-003; docs/test/TCS-MOD-010.json#TC-010-024; docs/test/TCS-MOD-010.json#TC-010-036 -->

### New event-table columns (Layercake.silv_membership_events and Layercake.fact_membership_events)

MOD-007 adds the seventeen new columns to both event tables but fills none of them; every event holds the defaults (0 for the segment keys and flags, empty amounts). In the design, a later load (MOD-012) copies the keys and carried flags from the contact's member-year attributes row, and subs_amount_gbp, invoiced_subtotal_gbp and amount_status from the event amounts table, Layercake.silv_event_amount (MOD-010), onto silv_membership_events, and copies them on to fact_membership_events by event_id. Those mappings will be added here when they are delivered.

<!-- evidence: docs/design/MP-001.json#without writing values or changing any Phase 1 column, row, event_nk or event_id; docs/design/DES-001.json#Their values are written by usp_load_silv_membership_events_segments; docs/design/DES-001.json#Writes the new columns on silv_membership_events (ADR-001); docs/design/DES-001.json#Join, Renewal and Readmission take subs_amount_gbp, invoiced_subtotal_gbp and amount_status from silv_event_amount by event_nk; docs/design/DES-001.json#Gold copies silver by event_id; docs/test/TCS-MOD-007.json#TC-007-053; docs/test/TCS-MOD-007.json#TC-007-054 -->

### Grain profile (Layercake.usp_profile_custtrans_grain)

The profile counts invoices in synapse_fo.CUSTTRANS_RICS (RULE-095). It has no target table.

| Source column | How it is used |
|---|---|
| TRANSTYPE | Rows of type 8 or 24 are left out; rows with no type are left out |
| INVOICE | Rows whose invoice number contains 'CRE' or 'FTCN' are left out; rows with no invoice number are left out. With ACCOUNTNUM, identifies an invoice |
| ACCOUNTNUM | With INVOICE, identifies an invoice, so one invoice number on two accounts counts as two invoices |
| productcode | Counted as distinct_productcodes per invoice; a row with no item code adds nothing |
| PostingType_Description | 'Sales tax' marks a tax row, counted as has_sales_tax_row |
| (number of rows) | Counted as rows_per_invoice per invoice |

<!-- evidence: docs/specs/SPEC-001.json#RULE-095; docs/dev/CN-MOD-001.json#rows_per_invoice; docs/dev/CN-MOD-001.json#PostingType_Description = 'Sales tax'; docs/dev/CN-MOD-001.json#The design does not settle these cases; docs/test/TCS-MOD-001.json#TC-001-002; docs/test/TCS-MOD-001.json#TC-001-003 -->

### Corporate status profile (Layercake.usp_profile_corp_subscription_status)

The profile counts rows of Subs.vwCorpSubscriptions (RULE-096). It has no target table.

| Source column | How it is used |
|---|---|
| Sub Status | Rows counted by each value found |
| Sub User Status | Rows counted by each value found |

It counts source rows, not contacts.

<!-- evidence: docs/specs/SPEC-001.json#RULE-096; docs/specs/SPEC-001.json#The corporate status profile returns row counts of Subs.vwCorpSubscriptions by 'Sub Status' and 'Sub User Status' value.; docs/test/TCS-MOD-001.json#TC-001-004; docs/test/TCS-MOD-001.json#TC-001-005 -->
