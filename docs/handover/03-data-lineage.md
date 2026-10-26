# Data lineage: RICS Payment Segment Tracker

## Sources

The solution reads objects that other systems own and maintain. It never creates, changes or writes to them; any change one would need goes to its owner. MOD-001 reads two of them:

| Source | What it holds | Read by |
|---|---|---|
| synapse_fo.CUSTTRANS_RICS | Customer transaction rows, including invoice rows with item codes (productcode) and posting types | Layercake.usp_profile_custtrans_grain |
| Subs.vwCorpSubscriptions | Corporate subscriptions, with each subscription's 'Sub Status' and each subscription user's 'Sub User Status' | Layercake.usp_profile_corp_subscription_status |

Both profiles read the sources directly and keep nothing: no data is landed or copied.

<!-- evidence: PROJECT_STANDARDS.md#Objects owned by other systems (external); docs/sources/external_catalogue.json#synapse_fo.CUSTTRANS_RICS; docs/sources/external_catalogue.json#Subs.vwCorpSubscriptions; docs/sources/external/synapse_fo/synapse_fo.CUSTTRANS_RICS.sql#PostingType_Description; docs/design/MP-001.json#count-only procedures over the external sources; docs/dev/CN-MOD-001.json#Neither writes anything -->

## Source-to-target mappings

The profiles have no target table. The tables below show which source columns each profile uses and how they become the counts it returns.

<!-- evidence: docs/design/MP-001.json#Builds no tables and changes no existing object; docs/specs/SPEC-001.json#RULE-095; docs/specs/SPEC-001.json#RULE-096 -->

### Grain profile (Layercake.usp_profile_custtrans_grain)

| Source column (synapse_fo.CUSTTRANS_RICS) | Use in the profile |
|---|---|
| TRANSTYPE | Rows with type 8 or 24, or with no type, are left out |
| INVOICE | Rows whose invoice number contains 'CRE' or 'FTCN', or that have no invoice number, are left out. With ACCOUNTNUM, it identifies an invoice |
| ACCOUNTNUM | With INVOICE, it identifies an invoice |
| productcode | Counted as distinct_productcodes per invoice; a missing item code is not counted |
| PostingType_Description | An invoice with a row of 'Sales tax' counts as has_sales_tax_row '1' |
| (number of rows) | Counted as rows_per_invoice per invoice |

Output: for each measure and value, the number of invoices (invoice_count).

<!-- evidence: docs/specs/SPEC-001.json#RULE-095; docs/design/DES-001.json#Layercake.usp_profile_custtrans_grain; docs/dev/CN-MOD-001.json#PostingType_Description = 'Sales tax'; docs/dev/CN-MOD-001.json#invoice_count; docs/test/TCS-MOD-001.json#TC-001-001 -->

### Corporate status profile (Layercake.usp_profile_corp_subscription_status)

| Source column (Subs.vwCorpSubscriptions) | Use in the profile |
|---|---|
| Sub Status | Rows counted per value, reported with status_column 'Sub Status' |
| Sub User Status | Rows counted per value, reported with status_column 'Sub User Status' |

Output: for each status column and value (status_value), the number of source rows (row_count). A missing status is reported as its own value.

<!-- evidence: docs/specs/SPEC-001.json#RULE-096; docs/design/DES-001.json#Layercake.usp_profile_corp_subscription_status; docs/dev/CN-MOD-001.json#row_count; docs/test/TCS-MOD-001.json#TC-001-004 -->
