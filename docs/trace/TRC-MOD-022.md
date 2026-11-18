# Traceability: MOD-022

Checked by the Product Owner before the pre-merge review: requirement, acceptance criteria, test conditions, latest results.

**Result:** no gaps; 10 review flag(s).

| Requirement | Title | Acceptance criteria | Test conditions | Results | Status |
|---|---|---|---|---|---|
| REQ-018 | Past daily counts kept in line with silver on every run | AC-018-01, AC-018-02, AC-018-03, AC-018-04, AC-018-05, AC-018-06, AC-018-07, AC-018-08, AC-018-09 | TC-022-001, TC-022-026, TC-022-002, TC-022-003, TC-022-004, TC-022-005, TC-022-006, TC-022-007, TC-022-008, TC-022-009, TC-022-010, TC-022-011, TC-022-016 | pass | met |
| REQ-019 | Adjustment history of daily counts | AC-019-01, AC-019-02, AC-019-03, AC-019-04, AC-019-05, AC-019-06, AC-019-07, AC-019-08, AC-019-09, AC-019-10 | TC-022-012, TC-022-013, TC-022-014, TC-022-015, TC-022-016, TC-022-017, TC-022-018, TC-022-019, TC-022-020, TC-022-021, TC-022-022, TC-022-023, TC-022-024 | pass | met |
| REQ-020 | Daily counts as known at any time, and adjustments review | AC-020-08, AC-020-09 | TC-022-024, TC-022-025 | pass | met |

## Review flags

- deviation: Earlier suite superseded by REQ-018: test_MOD018.[test TC-018-020 ...] asserts the Phase 1 forward-only behaviour (a plain daily run leaves a loaded date on the old Retired split until a one-off @RebuildFrom). MOD-022 makes every run correct changed past dates, so that assertion now fails by design ('Expected <2> but was <1>'; checked in dev). Asked the owner whether the Tester amends or retires it (deferred). Assumption: REQ-018 and the approved TCS-MOD-022 win, and the code was not bent to keep the ASM-002 behaviour. test_MOD016 TC-016-009 and TC-016-011 still pass.
- deviation: Q-052 confirmed from the Phase 1 code. (a) usp_load_silver passes @run_id, @FullRebuild, @RebuildFrom and @DailyCountBatchDays straight to usp_load_silv_daily_count, and all rebuild handling sits in the daily count, so usp_load_silver is unchanged. (b) Confirmed in CN-MOD-021. (c) The derivation reads: silv_member_state_ranges (contact_no, valid_from, valid_to, grade, region); silv_member_profile (contact_no, country_id, gender_id, retirement_date); silv_payment_events (contact_no, campaign_year, renewal_date_adj); silv_membership_events (contact_no, campaign_year, event_type, event_date, and event_id only as a tie-break that cannot change a figure, so it is left out of the fingerprint); ref_date_spine ([date], campaign_year, campaign_quarter); ref_campaign_year_config (campaign_year, campaign_year_start, campaign_year_end); silv_ref_membership_status (id, status_name). It does not read silv_ref_membership_grade, so that table is not a reference input, although DES-001 names the grade list as an example.
- deviation: Today is now marked in etl_daily_count_loaded by its first load (RULE-114), where Phase 1 never marked it. @FullRebuild and @RebuildFrom no longer clear loaded markers; they only move the start date earlier, so their changes are recorded as adjustments (RULE-115). The comment in the unchanged etl_daily_count_loaded table file still describes the Phase 1 behaviour, and the file was left as it is on the base commit, as the plan requires.
- deviation: A contact with no dated input row (only a silv_member_profile row, so no ranges) gets earliest_affected_date 9999-12-31, meaning it affects no date. With no state range it contributes to no cell, so a change to it alone does not move the start back. The design does not cover this case.
- deviation: The earliest affected date also takes in silv_payment_events.payment_date. The derivation does not read it, but DES-001 lists 'payment and renewal dates', and it can only move the start earlier.
- deviation: Rows on dates after today that belong to a date already marked loaded are removed by the Phase 1 housekeeping (possible only if the clock moved back). They are now recorded as negative adjustments in the same transaction, so RULE-116 (stored before + adjustments = after) holds on that path too.
- deviation: rows_inserted, rows_updated and rows_deleted in the step's etl_run_log row now count the differences actually written to both daily tables, where Phase 1 logged every re-inserted row and always 0 updated. The step name and statuses are unchanged.
- assumptions the Product Owner made for MOD-022: ASM-010 (docs/assumptions.md)
- open questions in the spec touch this module's requirements: Q-049, Q-050, Q-051
- handover documentation deferred to the handover (po.py handover)

Sources: docs/specs/SPEC-001.json, docs/design/MP-001.json, docs/test/TCS-MOD-022.json, docs/dev/CN-MOD-022.json, docs/test/TR-MOD-022-2.json
