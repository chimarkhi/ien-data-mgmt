# ien-data-mgmt

Notebooks, database schema, and SQL utilities for managing the IEN (Indian Eagle Network) crowd-sourced bioacoustics dataset — from raw volunteer submissions through quality control to published Zenodo archives.

## Repository contents

```
IEN_data_mgmt.ipynb       # Main processing notebook (Google Colab)
ien_schema.sql            # Original schema reference file
db/
  changelog/              # Liquibase schema (run once to initialise DB)
    db.changelog-master.xml
    schema/0001_initial_schema.sql
  migrations/             # One-time data load scripts
    load_qc_data.sql
    load_loceco_data.sql
  queries/                # Reusable reporting / Zenodo export queries
    author_analysis.sql
    sciname_analysis.sql
    qc_analysis.sql
    zenodo_metadata.sql
    zenodo_annotations.sql
```

## Notebook overview

`IEN_data_mgmt.ipynb` is designed to run in **Google Colab** with Google Drive mounted. It covers the full pipeline:

1. Ingest contributor `.zip` submissions from Google Drive
2. Validate and standardise metadata, author, and annotation sheets
3. Enrich species names via the [GBIF backbone taxonomy](https://www.gbif.org/dataset/d7dddbf4-2cf0-4f39-9b2a-bb099caae36c)
4. Store processed records in PostgreSQL (`ien` schema)
5. Sample QC sets per state and taxonomic class
6. Export per-state audio archives and metadata/annotation CSVs for Zenodo
7. Upload archives to Zenodo via REST API

## Setup

### Credentials

The notebook reads two secrets at startup. **Never hardcode these.**

| Secret key | Value |
|---|---|
| `IEN_DB_URL` | `postgresql://user:password@host:5432/birdnet` |
| `IEN_ZENODO_TOKEN` | Personal access token from [zenodo.org/account/settings/applications](https://zenodo.org/account/settings/applications) |

**In Google Colab:** add both via the Secrets panel (key icon in the left sidebar).

**For local development:** copy `.env.example` to `.env` and fill in values. The notebook loads them via `os.environ` when running outside Colab.

### Configuration (cell 3)

Before running, set `data_type` at the top of cell 3:

```python
data_type = 'type_A'   # or 'type_B'
```

All per-type settings (Drive folder, timestamp cutoff, required columns, output paths) are defined in `TYPE_CONFIG` in the same cell and automatically applied to `cfg`.

Other flags in `cfg`:

| Flag | Default | Effect |
|---|---|---|
| `wait_for_inputs` | `False` | Pause for user confirmation when a fuzzy filename match is found |
| `run_qc_sampling` | `False` | Set `True` to execute the "Create QC sets" section |

## Database

Schema: `ien` on a PostgreSQL server. Apply with Liquibase:

```bash
liquibase --url=jdbc:postgresql://localhost:5432/birdnet \
          --username=birdnet --password=<password> \
          --changeLogFile=db/changelog/db.changelog-master.xml \
          update
```

Tables: `authors`, `typea_meta`, `typeb_meta`, `anno`, `typea_qc`, `typeb_qc`.

One-time data migrations (QC review CSVs, ecoregion lookups) are in `db/migrations/`.

## Submission format

Each contributor submits a `.zip` containing:
- One `.xls`/`.xlsx` workbook with sheets: `Meta`, `Authors`, `Annotations`
- Audio files in any of: `.wav`, `.flac`, `.mp3`, `.m4a`, `.aiff`, `.aac`, `.ogg`, `.wma`

Column names are fuzzy-matched to standard names (cutoff 0.7) to tolerate minor variation between contributors.
