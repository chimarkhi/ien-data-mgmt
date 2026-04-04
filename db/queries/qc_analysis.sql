-- QC validation analysis for Type A and Type B datasets.
-- Sections use the final `validation` boolean on the qc tables (post double-review merge).
--
-- Run with: psql -d birdnet -h localhost -U birdnet -f qc_analysis.sql

-- ── Type A: pass/fail counts by state and taxa class ─────────────────────────

SELECT
    state,
    taxa_info->>'class'                                                         AS "Taxa Class",
    COUNT(DISTINCT mfn)                                                         AS "#Media Files",
    SUM(CASE WHEN validation IS NOT NULL THEN 1 ELSE 0 END)                     AS "#Labels",
    SUM(CASE WHEN validation IS FALSE THEN 1 ELSE 0 END)                        AS "#Fail Labels",
    COUNT(DISTINCT CASE WHEN validation IS FALSE THEN mfn ELSE NULL END)        AS "#Fail Media Files"
FROM (
    SELECT *, m.media_file_name AS mfn
    FROM ien.typea_meta m
    LEFT JOIN ien.anno a     ON m.id = a.media_id
    LEFT JOIN ien.typea_qc q ON q.media_file_name = a.media_file_name
                             AND q.begin_time_s = a.begin_time_s
    WHERE authors NOT ILIKE '%mayuri%'
      AND q.media_file_name IS NOT NULL
) t
WHERE validation IS NOT NULL
  AND taxa_info->>'class' IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2;


-- ── Type A: fail reason breakdown ────────────────────────────────────────────

SELECT
    validation_comments->>'rejection_classification'                            AS "Reason for Validation Fail",
    COUNT(DISTINCT CASE WHEN validation IS FALSE THEN mfn ELSE NULL END)        AS "#Media Files",
    SUM(CASE WHEN validation IS FALSE THEN 1 ELSE 0 END)                        AS "#Labels"
FROM (
    SELECT *, m.media_file_name AS mfn
    FROM ien.typea_meta m
    LEFT JOIN ien.anno a     ON m.id = a.media_id
    LEFT JOIN ien.typea_qc q ON q.media_file_name = a.media_file_name
                             AND q.begin_time_s = a.begin_time_s
    WHERE authors NOT ILIKE '%mayuri%'
      AND q.media_file_name IS NOT NULL
      AND q.media_file_name NOT ILIKE 'WGH%'
) t
WHERE validation IS NOT NULL
  AND validation_comments->>'rejection_classification' IS NOT NULL
GROUP BY 1
ORDER BY 1;


-- ── Type B: pass/fail counts by state and taxa class ─────────────────────────

SELECT
    state,
    taxa_info->>'class'                                                         AS "Taxa Class",
    COUNT(DISTINCT mfn)                                                         AS "#Media Files",
    COUNT(DISTINCT CASE WHEN validation IS FALSE THEN mfn ELSE NULL END)        AS "#Fail Media Files"
FROM (
    SELECT *, m.media_file_name AS mfn
    FROM ien.typeb_meta m
    LEFT JOIN ien.typeb_qc q ON q.media_file_name = m.media_file_name
) t
WHERE validation IS NOT NULL
  AND taxa_info->>'class' IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2;


-- ── Type B: fail reason breakdown ────────────────────────────────────────────

SELECT
    validation_comments->>'rejection_classification'                            AS "Reason for Validation Fail",
    COUNT(DISTINCT CASE WHEN validation IS FALSE THEN mfn ELSE NULL END)        AS "#Media Files"
FROM (
    SELECT *, m.media_file_name AS mfn
    FROM ien.typeb_meta m
    LEFT JOIN ien.typeb_qc q ON q.media_file_name = m.media_file_name
    WHERE q.media_file_name IS NOT NULL
) t
WHERE validation IS NOT NULL
  AND validation_comments->>'rejection_classification' IS NOT NULL
GROUP BY 1
ORDER BY 1;
