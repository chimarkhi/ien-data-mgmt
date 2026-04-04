-- One-time migration: ingest QC review CSVs into ien.typea_qc and ien.typeb_qc
-- Run with: psql -v ON_ERROR_STOP=1 -d birdnet -h localhost -U birdnet -f load_qc_data.sql
--
-- Source files (update paths as needed):
--   Type A QC: /mnt/c/Workshop/bioac/IEN data/typea_qc_31jan_doublereview.csv
--   Type B QC: /mnt/c/Workshop/bioac/IEN data/typeb_qc_31jan_doublereview.csv
--
-- The source CSVs have raw text validation columns ('OK'/'Not OK') and
-- extra review columns. The temp tables handle the text→boolean coercion
-- before inserting into the final ien.*_qc tables.

-- ── Type A QC ────────────────────────────────────────────────────────────────

CREATE TEMP TABLE temp_typea_qc (
    media_file_name            varchar(500),
    begin_time_s               numeric(16,10),
    end_time_s                 numeric(16,10),
    low_freq_hz                numeric(10,3),
    high_freq_hz               numeric(10,3),
    sci_name                   varchar,
    validation                 text,
    validation_comments        text,
    rejection_classification   text,
    specific_rejetion_category text,
    new_review_pc              text,
    new_review_reason          text
);

\copy temp_typea_qc FROM '/mnt/c/Workshop/bioac/IEN data/typea_qc_31jan_doublereview.csv' CSV DELIMITER ',' HEADER;

UPDATE temp_typea_qc SET validation    = 'true'  WHERE validation    = 'OK';
UPDATE temp_typea_qc SET validation    = 'false' WHERE validation    = 'Not OK';
UPDATE temp_typea_qc SET new_review_pc = 'false' WHERE new_review_pc = 'Not OK';
UPDATE temp_typea_qc SET new_review_pc = 'true'  WHERE new_review_pc = 'OK';

-- Final validation = original OR secondary review (NULL secondary defaults to true)
INSERT INTO ien.typea_qc
SELECT
    media_file_name,
    begin_time_s,
    end_time_s,
    low_freq_hz,
    high_freq_hz,
    sci_name,
    validation::boolean OR COALESCE(new_review_pc, 'true')::boolean AS validation,
    row_to_json(t)::jsonb
        - 'media_file_name'
        - 'begin_time_s'
        - 'end_time_s'
        - 'low_freq_hz'
        - 'high_freq_hz'
        - 'sci_name'
        AS validation_comments
FROM temp_typea_qc t;

DROP TABLE temp_typea_qc;

-- ── Type B QC ────────────────────────────────────────────────────────────────

CREATE TEMP TABLE temp_typeb_qc (
    media_file_name            varchar(500),
    sci_name                   varchar,
    validation                 text,
    validation_comments        text,
    rejection_classification   text,
    specific_rejetion_category text,
    new_review_pc              text,
    new_review_reason          text
);

\copy temp_typeb_qc FROM '/mnt/c/Workshop/bioac/IEN data/typeb_qc_31jan_doublereview.csv' CSV DELIMITER ',' HEADER;

UPDATE temp_typeb_qc SET validation    = 'false' WHERE validation    = 'Not OK';
UPDATE temp_typeb_qc SET validation    = 'true'  WHERE validation    = 'OK';
UPDATE temp_typeb_qc SET new_review_pc = 'false' WHERE new_review_pc = 'Not OK';
UPDATE temp_typeb_qc SET new_review_pc = 'true'  WHERE new_review_pc = 'OK';

INSERT INTO ien.typeb_qc
SELECT
    media_file_name,
    sci_name,
    validation::boolean OR COALESCE(new_review_pc, 'true')::boolean AS validation,
    row_to_json(t)::jsonb
        - 'media_file_name'
        - 'sci_name'
        AS validation_comments
FROM temp_typeb_qc t;

DROP TABLE temp_typeb_qc;
