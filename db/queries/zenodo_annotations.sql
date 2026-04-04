-- Zenodo submission annotation queries.
-- Produces per-annotation rows for the published annotation CSVs.
--
-- Run with: psql -d birdnet -h localhost -U birdnet -f zenodo_annotations.sql
-- Or \copy (<query>) TO 'output.csv' CSV HEADER;

-- ── Type A annotations ────────────────────────────────────────────────────────
-- Annotations with a resolved GBIF usageKey (identified species).

SELECT
    m.info->>'dataset_file_name'                                                AS media_file_name,
    a.begin_time_s                                                              AS begin_time,
    a.end_time_s                                                                AS end_time,
    a.high_freq_hz                                                              AS high_freq,
    a.low_freq_hz                                                               AS low_freq,
    a.sci_name                                                                  AS scientific_name,
    CASE WHEN q.validation IS TRUE  THEN '1'
         WHEN q.validation IS FALSE THEN '0'
         ELSE 'NA' END                                                          AS validation,
    validation_comments->>'rejection_classification'                            AS validation_fail_reason,
    CASE WHEN q.validation IS NULL THEN NULL
         ELSE jsonb_build_object(
             'reviewer_comments',   validation_comments->>'validation_comments',
             'comment_explanation', validation_comments->>'specific_rejetion_category'
         )
    END                                                                         AS validation_comments,
    a.notes,
    a.taxa_info
FROM ien.anno a
LEFT JOIN ien.typea_meta m ON m.id = a.media_id
LEFT JOIN ien.typea_qc q
    ON (q.media_file_name, q.begin_time_s, q.end_time_s, q.high_freq_hz, q.low_freq_hz, q.sci_name)
     = (a.media_file_name,  a.begin_time_s,  a.end_time_s,  a.high_freq_hz,  a.low_freq_hz,  a.sci_name)
WHERE a.taxa_info->>'usageKey' IS NOT NULL;


-- ── Background annotations ────────────────────────────────────────────────────
-- Annotations without a resolved GBIF usageKey (ambient / unidentified sounds).

SELECT
    m.info->>'dataset_file_name'                                                AS media_file_name,
    a.begin_time_s                                                              AS begin_time,
    a.end_time_s                                                                AS end_time,
    a.high_freq_hz                                                              AS high_freq,
    a.low_freq_hz                                                               AS low_freq,
    a.sci_name                                                                  AS scientific_name,
    CASE WHEN q.validation IS TRUE  THEN '1'
         WHEN q.validation IS FALSE THEN '0'
         ELSE 'NA' END                                                          AS validation,
    validation_comments->>'rejection_classification'                            AS validation_fail_reason,
    CASE WHEN q.validation IS NULL THEN NULL
         ELSE jsonb_build_object(
             'reviewer_comments',   validation_comments->>'validation_comments',
             'comment_explanation', validation_comments->>'specific_rejetion_category'
         )
    END                                                                         AS validation_comments,
    a.notes,
    a.taxa_info
FROM ien.anno a
LEFT JOIN ien.typea_meta m ON m.id = a.media_id
LEFT JOIN ien.typea_qc q
    ON (q.media_file_name, q.begin_time_s, q.end_time_s, q.high_freq_hz, q.low_freq_hz, q.sci_name)
     = (a.media_file_name,  a.begin_time_s,  a.end_time_s,  a.high_freq_hz,  a.low_freq_hz,  a.sci_name)
WHERE a.taxa_info->>'usageKey' IS NULL;
