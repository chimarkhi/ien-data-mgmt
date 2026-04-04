-- Author contribution analysis for Type A and Type B datasets.
-- Run with: psql -d birdnet -h localhost -U birdnet -f author_analysis.sql

-- ── Type A author analysis ────────────────────────────────────────────────────
-- Per-author: file count, total annotated duration, unique species and classes,
-- and total valid media length (annotations with a resolved taxonomic rank).

SELECT
    t."Author",
    t."Email ID",
    t2.file_count,
    t2.anno_duration,
    t2.unique_species,
    t2.unique_class,
    t3.valid_media_length_minutes
FROM
    (SELECT DISTINCT ON ("Author") "Author", "Email ID" FROM ien.authors) t

LEFT JOIN (
    SELECT
        ta.author,
        COUNT(DISTINCT ta.media_file_name)          AS file_count,
        ROUND(SUM(end_time_s - begin_time_s) / 60, 1) AS anno_duration,
        COUNT(DISTINCT taxa_info->>'speciesKey')     AS unique_species,
        COUNT(DISTINCT taxa_info->>'class')          AS unique_class
    FROM (
        SELECT TRIM(UNNEST(string_to_array(authors, ','))) AS author, *
        FROM ien.typea_meta
    ) ta
    LEFT JOIN ien.anno an
        ON ta.id = an.media_id
        AND an.taxa_info->>'usageKey' IS NOT NULL
    GROUP BY 1
) t2 ON t."Author" = t2.author

LEFT JOIN (
    SELECT
        author,
        ROUND(SUM(valid_media_len) / 60, 1) AS valid_media_length_minutes
    FROM (
        SELECT
            TRIM(UNNEST(string_to_array(authors, ','))) AS author,
            ta.media_file_name,
            MAX(media_length_sec) AS valid_media_len
        FROM ien.typea_meta ta
        LEFT JOIN ien.anno an
            ON ta.id = an.media_id
            AND an.taxa_info->>'rank' NOT IN ('UNRANKED', 'KINGDOM', 'FORM')
            AND an.taxa_info->>'rank' IS NOT NULL
        GROUP BY 1, 2
    ) t_int
    GROUP BY 1
) t3 ON t."Author" = t3.author

WHERE t2.file_count IS NOT NULL
ORDER BY valid_media_length_minutes;


-- ── Type B author analysis ────────────────────────────────────────────────────
-- Per-author: file count, unique species and classes, total media duration.
-- Only counts files with a resolved GBIF usageKey.

SELECT
    t."Author",
    t."Email ID",
    t2.file_count,
    t2.unique_species,
    t2.unique_class,
    t2.media_length_minutes
FROM
    (SELECT DISTINCT ON ("Author") "Author", "Email ID" FROM ien.authors) t

LEFT JOIN (
    SELECT
        author,
        COUNT(DISTINCT media_file_name)              AS file_count,
        COUNT(DISTINCT taxa_info->>'speciesKey')     AS unique_species,
        COUNT(DISTINCT taxa_info->>'class')          AS unique_class,
        ROUND(SUM(media_length_sec) / 60, 1)        AS media_length_minutes
    FROM (
        SELECT TRIM(UNNEST(string_to_array(authors, ','))) AS author, *
        FROM ien.typeb_meta
    ) tb
    WHERE tb.taxa_info->>'usageKey' IS NOT NULL
    GROUP BY 1
) t2 ON t."Author" = t2.author

WHERE t2.file_count IS NOT NULL
ORDER BY media_length_minutes;
