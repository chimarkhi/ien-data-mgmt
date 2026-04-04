-- Scientific name cleanup and synonym analysis.
-- Identifies annotations where the submitted usageKey differs from the
-- accepted speciesKey (i.e., synonyms or deprecated names that need resolving).
--
-- Run with: psql -d birdnet -h localhost -U birdnet -f sciname_analysis.sql

SELECT DISTINCT
    sci_name,
    taxa_info->>'usageKey'         AS submitted_usagekey,
    taxa_info->>'speciesKey'       AS submitted_specieskey,
    taxa_info->>'status'           AS gbif_status,
    taxa_info->>'rank'             AS gbif_rank,
    taxa_info->>'canonicalName'    AS submitted_sci_name,
    taxa_info->>'acceptedUsageKey' AS accepted_usagekey
FROM ien.anno
WHERE taxa_info->>'usageKey' <> taxa_info->>'speciesKey';
