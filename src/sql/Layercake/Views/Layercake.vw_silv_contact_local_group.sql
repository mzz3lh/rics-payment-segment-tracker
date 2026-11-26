/*====================================================================
    Layercake.vw_silv_contact_local_group
    The one place that decides each member's local group, country and
    regions (ADR-016 Option A, AMD-009). One row per live brnz_contact row.
    contact_country_id is the own country exactly as Phase 1 derives
    silv_member_base.country_id: silv_ref_country matched on rics_countryid,
    0 where rics_countryid is null or not found (Q-069 c).
    A member whose rics_localgroupid names a reportable silv_ref_local_group
    row takes that group's id, country and both regions; every other member
    takes local_group_id 0 and the own country with its own regions in every
    field. Fields are never mixed, and -2 is never given.
====================================================================*/
CREATE OR ALTER VIEW Layercake.vw_silv_contact_local_group
AS
SELECT c.ContactId AS contact_id,
       c.Rics_contactno AS contact_no,
       oc.contact_country_id,
       ISNULL(lg.id, 0) AS local_group_id,
       CASE WHEN lg.id IS NULL THEN oc.contact_country_id ELSE lg.country_id END AS country_id,
       CASE WHEN lg.id IS NULL THEN own.region_name ELSE lg.region_name END AS region_name,
       CASE WHEN lg.id IS NULL THEN own.market_reporting_region ELSE lg.market_reporting_region END AS market_reporting_region,
       own.region_name AS contact_region_name,
       own.market_reporting_region AS contact_market_reporting_region
FROM Layercake.brnz_contact AS c
LEFT JOIN Layercake.silv_ref_country AS ctry
    ON ctry.country_id = c.rics_countryid
CROSS APPLY (SELECT ISNULL(ctry.id, 0) AS contact_country_id) AS oc
LEFT JOIN Layercake.silv_ref_country AS own
    ON own.id = oc.contact_country_id
LEFT JOIN Layercake.silv_ref_local_group AS lg
    ON  lg.local_group_bk = c.rics_localgroupid
    AND lg.is_reportable = 1
WHERE c._is_deleted = 0;
