# Learning log

Notes written as I went, on what was new to me and how I worked it out.

## Snowflake (first time using it)
- Storage and compute are separate: the warehouse is the compute and is billed per second while running. Used X-Small with auto-suspend 60s to keep cost low.
- Roles: created a project role (TRANSFORMER) instead of working as ACCOUNTADMIN (least privilege).
- Unquoted identifiers are uppercased. My username is lowercase, so the GRANT failed until I wrapped it in double quotes.
- `IF NOT EXISTS` makes setup scripts safe to re run (idempotent). My first run failed halfway and re-running was safe.

## dbt
- dbt connects with a key-pair service user (DBT_SVC). My human user is lowercase, and key-pair login sends the name in capitals, so a dedicated uppercase service user fixed "JWT token is invalid". Also better practice: tools shouldn't log in as people.
- Staging models are views (always fresh, no storage). Marts are tables (fast for analysts).
- Snowflake doesn't enforce PK/FK constraints, so dbt tests (unique, not_null, relationships) prove them on every build. First build: 8 models, 27 tests passing.
- dbt's default schema naming gives DEV_STAGING; a generate_schema_name macro gives clean STAGING / MARTS.
- VS Code: unsaved files caused empty commits and "file is empty" errors. Turned on Auto Save.

Uploaded via the Snowsight UI (manual step). The scripted equivalent is PUT file://... @stage via the Snowflake CLI.