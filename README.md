# Olist E-commerce Analytics: Snowflake + dbt

A mini ELT pipeline on the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce): raw CSVs are loaded into Snowflake, modelled in dbt through **raw → staging → marts**, and turned into a commercial recommendation.

**Headline:** late deliveries drop review scores from 4.29★ to 1.70★ and only 3.1% of customers ever buy again. I recommend a controlled late-delivery recovery campaign (see [`analysis_answers.md`](analysis_answers.md)).

```
CSV files ──PUT/upload──► OLIST.RAW (8 tables, as-is + load metadata)
                              │  dbt staging (views): rename, type, clean, dedupe, 27 tests
                              ▼
                          OLIST.STAGING (8 models, 3NF)
                              │  dbt marts (tables): star schema, 16 tests
                              ▼
                          OLIST.MARTS: dim_customers · dim_products · fct_order_items
                              │
                              ▼
                  sql/analytics_queries.sql → analysis_answers.md
```

## Platform
**Snowflake** (the brief's default). I had used Databricks before, but not Snowflake or dbt; part of the goal was to pick up the stack Elio uses.

## Setup
| Item | Value |
|---|---|
| Account | Snowflake Enterprise trial, AWS Europe (London) |
| Warehouse | `TRANSFORM_WH`, X-Small, auto-suspend 60s, auto-resume |
| Database / schemas | `OLIST` → `RAW`, `STAGING`, `MARTS` |
| Role | `TRANSFORMER` (project role, least privilege) |
| dbt user | `DBT_SVC`: service user, key-pair auth only, no password |
| Versions | dbt-core 1.12.7, dbt-snowflake 1.12.5, dbt_utils 1.4.1, Python 3.14 |

## How to reproduce

### 1. Python environment
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Snowflake objects and raw load
Run these in a Snowsight worksheet, in order:
1. `ingest/01_setup.sql`: role, warehouse, database, RAW schema and the `DBT_SVC` service user (replace the two placeholders first).
2. `ingest/02_file_format_and_stage.sql`: CSV file format and internal stage.
3. **Manual step:** download the dataset from Kaggle and upload these 8 CSVs to `OLIST.RAW.OLIST_STAGE` (Snowsight → Database Explorer → stage → **+ Files**), or use the Snowflake CLI: `PUT file://data/*.csv @OLIST.RAW.OLIST_STAGE`. The geolocation file isn't needed.
4. `ingest/03_raw_tables_and_load.sql`: creates the raw tables and loads them with `COPY INTO`.
5. `ingest/04_validate_load.sql`: row counts, load errors, encoding and duplicate checks.

### 3. Key-pair authentication for dbt
```bash
mkdir -p ~/.snowflake
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out ~/.snowflake/rsa_key.p8 -nocrypt
openssl rsa -in ~/.snowflake/rsa_key.p8 -pubout -out ~/.snowflake/rsa_key.pub
```
Paste the public key (without the BEGIN/END lines) into the `DBT_SVC` statement in `01_setup.sql`. The private key stays outside the repo.

### 4. Configure dbt
```bash
cp dbt_project/profiles.yml.example dbt_project/profiles.yml
export SNOWFLAKE_ACCOUNT=<org>-<account>        # e.g. from your Snowsight URL
export SNOWFLAKE_USER=DBT_SVC
export SNOWFLAKE_PRIVATE_KEY_PATH=~/.snowflake/rsa_key.p8
```
`profiles.yml` only reads environment variables, so no secrets are stored in it (and it's gitignored anyway). I keep the three `export` lines in a gitignored `.env` and run `source .env`.

### 5. Build and test
```bash
cd dbt_project
dbt deps        # installs dbt_utils (pinned in package-lock.yml)
dbt debug       # checks the connection
dbt build       # runs 11 models + 43 tests in dependency order
```

### 6. Analytics queries
Open `sql/analytics_queries.sql` in a Snowsight worksheet (role `TRANSFORMER`, warehouse `TRANSFORM_WH`) and run each query. The results feed `analysis_answers.md`.

## Repository layout
```
ingest/                  Snowflake setup, stage, COPY INTO, validation (+ manual steps above)
dbt_project/
  models/staging/        8 staging views, sources and tests
  models/marts/          dim_customers, dim_products, fct_order_items + tests and docs
  macros/                generate_schema_name (clean STAGING / MARTS schema names)
  profiles.yml.example   connection template using env vars
sql/analytics_queries.sql  5 analytics queries on the marts
docs/data_model.md       3NF ERD, star schema, keys, types, materialisation
docs/learning_log.md     notes taken as I learned the stack
analysis_answers.md      Part B: insights, campaign, caveats, client memo, LLM idea
```

## Key decisions
- **Raw as-is (VARCHAR) + load metadata** (`_source`, `_loaded_at`), so nothing is rejected at load time and every row is traceable. `ON_ERROR = 'CONTINUE'`, with errors checked in `LOAD_HISTORY`. COPY INTO skips already-loaded files, so re-runs are safe.
- **Staging = views, marts = tables.** Normalised (3NF) in staging for consistency, a star schema in marts for simple analysis. Details in [`docs/data_model.md`](docs/data_model.md).
- **Keys proven by tests**, since Snowflake doesn't enforce PK/FK: `unique`, `not_null` and `relationships` on every key, 43 tests in total.
- **Customer grain = `customer_unique_id`.** Olist issues a new `customer_id` per order.
- **Reviews = one per order** (latest kept). The source has 814 duplicate `review_id`s.

## Assumptions and shortcuts (time-boxed to the brief)
- The geolocation file wasn't loaded; customer and seller state are enough for the analysis.
- The raw upload is a manual Snowsight step rather than a scripted `PUT`.
- Single `dev` target; no separate prod environment or CI yet.
- Marts are full rebuilds (tables), which is fine at ~100k rows.

## What I'd do next
1. **CI:** a GitHub Actions workflow running `dbt build` on every PR against a CI schema, with credentials in GitHub secrets.
2. **Environments:** separate dev/prod databases, with zero-copy clones of prod for each PR.
3. **Incremental:** make `fct_order_items` incremental (merge on `order_item_sk`) as volume grows.
4. **History:** a dbt snapshot on customers (SCD Type 2) to track address changes.
5. **Freshness and alerting:** `dbt source freshness` on `_loaded_at` plus row-count anomaly checks.

## What was new to me and how I got up to speed
**Snowflake and dbt were both new to me.** I'd built production pipelines before (SQL/Python, Databricks, Azure Data Factory at Bajaj Finserv), so the concepts were familiar but the tools weren't. I learned by building in small steps, reading the official docs, and using an AI assistant as a tutor to explain each concept before applying it. Every line here was run, tested and is explained by me. Notes from the process are in [`docs/learning_log.md`](docs/learning_log.md). Highlights:
- **Snowflake:** storage vs compute separation, roles and least privilege, stages and `COPY INTO` with metadata columns, and that unquoted identifiers are uppercased (which broke my first GRANT).
- **Auth:** key-pair login failed for my lowercase human user, which led to the better pattern of a dedicated uppercase **service user** for dbt.
- **dbt:** sources vs `ref()`, materialisations, tests as a substitute for unenforced constraints, `dbt_utils` surrogate keys, and overriding `generate_schema_name`.