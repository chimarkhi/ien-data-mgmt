-- Zenodo submission metadata queries.
-- Each query produces one row per media file with the standardised columns
-- used in the published dataset CSVs.
--
-- Run with: psql -d birdnet -h localhost -U birdnet -f zenodo_metadata.sql
-- Or \copy (<query>) TO 'output.csv' CSV HEADER;

-- ── Type A metadata ───────────────────────────────────────────────────────────
-- One row per media file (distinct on); only files with an identified species.

SELECT DISTINCT ON (m.media_file_name)
    m.info->>'dataset_file_name'                                                AS media_file_name,
    'audio_type_A_' || state || '.zip'                                          AS archive_name,
    recording_date,
    CASE WHEN hide_exact_location IS TRUE THEN 'NA' ELSE longitude::text END    AS longitude,
    CASE WHEN hide_exact_location IS TRUE THEN 'NA' ELSE latitude::text END     AS latitude,
    REPLACE(authors, ',', ';')                                                  AS author_names,
    REPLACE(m.info->>'email_ids', ',', ';')                                     AS author_emails,
    m.notes,
    taxa_info,
    jsonb_build_object(
        'media_length_seconds', media_length_sec::numeric(8,1),
        'bit_depth',            bit_depth::int,
        'sampling_rate_KHz',    (sampling_rate / 1000)::int,
        'byte_size_Mb',         (byte_size / (1024 * 1024))::numeric(8,1)
    )                                                                           AS media_info
FROM ien.typea_meta m
LEFT JOIN ien.anno a ON m.id = a.media_id
WHERE taxa_info->>'usageKey' IS NOT NULL;


-- ── Type B metadata ───────────────────────────────────────────────────────────
-- One row per media file; includes QC validation result.

SELECT DISTINCT ON (m.media_file_name)
    m.info->>'dataset_file_name'                                                AS media_file_name,
    'audio_type_B_' || state || '.zip'                                          AS archive_name,
    m.sci_name                                                                  AS scientific_name,
    recording_date,
    CASE WHEN hide_exact_location IS TRUE THEN 'NA' ELSE longitude::text END    AS longitude,
    CASE WHEN hide_exact_location IS TRUE THEN 'NA' ELSE latitude::text END     AS latitude,
    REPLACE(authors, ',', ';')                                                  AS author_names,
    REPLACE(m.info->>'email_ids', ',', ';')                                     AS author_emails,
    m.notes,
    CASE WHEN q.validation IS TRUE  THEN '1'
         WHEN q.validation IS FALSE THEN '0'
         ELSE 'NA' END                                                          AS validation,
    validation_comments->>'rejection_classification'                            AS validation_fail_reason,
    jsonb_build_object(
        'reviewer_comments',   validation_comments->>'validation_comments',
        'comment_explanation', validation_comments->>'specific_rejetion_category'
    )                                                                           AS validation_comments,
    taxa_info,
    jsonb_build_object(
        'media_length_seconds', media_length_sec::numeric(8,1),
        'bit_depth',            bit_depth::int,
        'sampling_rate_KHz',    (sampling_rate / 1000)::int,
        'byte_size_Mb',         (byte_size / (1024 * 1024))::numeric(8,1)
    )                                                                           AS media_info
FROM ien.typeb_meta m
LEFT JOIN ien.typeb_qc q ON q.media_file_name = m.media_file_name;


-- ── Background metadata ───────────────────────────────────────────────────────
-- Type A files where no species annotation has a resolved usageKey
-- (i.e., ambient / background recordings).

SELECT DISTINCT ON (m.media_file_name)
    m.info->>'dataset_file_name'                                                AS media_file_name,
    'audio_background_' || state || '.zip'                                      AS archive_name,
    recording_date,
    CASE WHEN hide_exact_location IS TRUE THEN 'NA' ELSE longitude::text END    AS longitude,
    CASE WHEN hide_exact_location IS TRUE THEN 'NA' ELSE latitude::text end     AS latitude,
    REPLACE(authors, ',', ';')                                                  AS author_names,
    REPLACE(m.info->>'email_ids', ',', ';')                                     AS author_emails,
    m.notes,
    NULL::jsonb                                                                 AS taxa_info,
    jsonb_build_object(
        'media_length_seconds', media_length_sec::numeric(8,1),
        'bit_depth',            bit_depth::int,
        'sampling_rate_KHz',    (sampling_rate / 1000)::int,
        'byte_size_Mb',         (byte_size / (1024 * 1024))::numeric(8,1)
    )                                                                           AS media_info
FROM ien.typea_meta m
LEFT JOIN ien.anno a ON m.id = a.media_id
WHERE taxa_info->>'usageKey' IS NULL;
