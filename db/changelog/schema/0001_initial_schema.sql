--liquibase formatted sql
-- Run against: psql -v ON_ERROR_STOP=1 -d birdnet -h localhost -U birdnet
-- Or via Liquibase: liquibase --url=jdbc:postgresql://localhost:5432/birdnet --username=birdnet update

--changeset sameer:1 labels:initial comment:Enable uuid-ossp extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
--rollback DROP EXTENSION IF EXISTS "uuid-ossp";

--changeset sameer:2 labels:initial comment:Create ien schema
CREATE SCHEMA IF NOT EXISTS ien;
--rollback DROP SCHEMA IF EXISTS ien CASCADE;

--changeset sameer:3 labels:initial comment:Create authors table
CREATE TABLE ien.authors (
    "Author"       character varying,
    "Email ID"     character varying,
    "Affiliations" text,
    id             bigserial PRIMARY KEY
);
--rollback DROP TABLE IF EXISTS ien.authors;

--changeset sameer:4 labels:initial comment:Create typeb_meta table for Type B recording metadata
CREATE TABLE ien.typeb_meta (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    media_file_name     varchar(500),
    latitude            numeric(11,6),
    longitude           numeric(11,6),
    recording_date      date,           -- date format is messy in source submissions
    authors             text,
    sci_name            varchar,
    organism_seen       boolean,
    hide_exact_location boolean,
    recording_type      varchar,
    notes               text,
    media_length_sec    numeric(14,3),
    bit_depth           numeric(10,3),
    sampling_rate       numeric(10,3),
    byte_size           numeric(14,3),
    binary_hash         VARCHAR,
    original_zip        text,
    new_media_path      text,
    new_xls_path        text,
    state               VARCHAR,
    taxa_info           jsonb,
    eco_name            VARCHAR,
    info                jsonb,
    CONSTRAINT media_sciname UNIQUE (media_file_name, sci_name)
);
--rollback DROP TABLE IF EXISTS ien.typeb_meta;

--changeset sameer:5 labels:initial comment:Create typea_meta table for Type A recording metadata
CREATE TABLE ien.typea_meta (
    id                       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    media_file_name          varchar(500),
    latitude                 numeric(11,6),
    longitude                numeric(11,6),
    recording_date           date,       -- date format is messy in source submissions
    authors                  text,
    annotation_file_attached boolean,
    hide_exact_location      boolean,
    recording_type           varchar,
    notes                    text,
    annotation_found         boolean,
    media_length_sec         numeric(14,3),
    bit_depth                numeric(10,3),
    sampling_rate            numeric(10,3),
    byte_size                numeric(14,3),
    binary_hash              VARCHAR,
    original_zip             text,
    new_media_path           text,
    new_xls_path             text,
    state                    VARCHAR,
    eco_name                 VARCHAR,
    info                     jsonb,
    CONSTRAINT media_name UNIQUE (media_file_name)
);
--rollback DROP TABLE IF EXISTS ien.typea_meta;

--changeset sameer:6 labels:initial comment:Create anno table for Type A annotations
CREATE TABLE ien.anno (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    media_id        uuid NOT NULL REFERENCES ien.typea_meta(id),
    media_file_name varchar(500) NOT NULL,  -- redundant with media_id; kept for query convenience
    begin_time_s    numeric(16,10),
    end_time_s      numeric(16,10),
    low_freq_hz     numeric(10,3),
    high_freq_hz    numeric(10,3),
    organism_seen   boolean,
    sci_name        varchar,
    taxa_info       jsonb,
    notes           text,
    info            jsonb
);
--rollback DROP TABLE IF EXISTS ien.anno;

--changeset sameer:7 labels:initial comment:Create typea_qc table for Type A quality control results
CREATE TABLE ien.typea_qc (
    media_file_name      varchar(500),
    begin_time_s         numeric(16,10),
    end_time_s           numeric(16,10),
    low_freq_hz          numeric(10,3),
    high_freq_hz         numeric(10,3),
    sci_name             varchar,
    validation           boolean,
    validation_comments  jsonb
);
--rollback DROP TABLE IF EXISTS ien.typea_qc;

--changeset sameer:8 labels:initial comment:Create typeb_qc table for Type B quality control results
CREATE TABLE ien.typeb_qc (
    media_file_name      varchar(500),
    sci_name             varchar,
    validation           boolean,
    validation_comments  jsonb
);
--rollback DROP TABLE IF EXISTS ien.typeb_qc;
