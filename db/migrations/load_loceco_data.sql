-- One-time migration: load ecoregion name lookups into typea_meta and typeb_meta
-- Run with: psql -v ON_ERROR_STOP=1 -d birdnet -h localhost -U birdnet -f load_loceco_data.sql
--
-- Source files (update paths as needed):
--   Type A: /mnt/c/Workshop/bioac/IEN data/TypeA_data/typea_lat_long_econames_21dec.csv
--   Type B: /mnt/c/Workshop/bioac/IEN data/TypeB_data/typeb_lat_long_econame.csv

-- ── Type A loceco ─────────────────────────────────────────────────────────────

CREATE TEMP TABLE temp_typea_loceco (
    media_file_name varchar(500),
    latitude        numeric(11,6),
    longitude       numeric(11,6),
    eco_name        VARCHAR
);

\copy temp_typea_loceco FROM '/mnt/c/Workshop/bioac/IEN data/TypeA_data/typea_lat_long_econames_21dec.csv' CSV DELIMITER ',' HEADER;

UPDATE ien.typea_meta m
SET eco_name = t.eco_name
FROM temp_typea_loceco t
WHERE m.media_file_name = t.media_file_name;

DROP TABLE temp_typea_loceco;

-- ── Type B loceco ─────────────────────────────────────────────────────────────

CREATE TEMP TABLE temp_typeb_loceco (
    media_file_name varchar(500),
    latitude        numeric(11,6),
    longitude       numeric(11,6),
    eco_name        VARCHAR
);

\copy temp_typeb_loceco FROM '/mnt/c/Workshop/bioac/IEN data/TypeB_data/typeb_lat_long_econame.csv' CSV DELIMITER ',' HEADER;

UPDATE ien.typeb_meta m
SET eco_name = t.eco_name
FROM temp_typeb_loceco t
WHERE m.media_file_name = t.media_file_name;

DROP TABLE temp_typeb_loceco;
