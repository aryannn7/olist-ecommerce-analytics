# Learning log

Notes written as I went, on what was new to me and how I worked it out.

## Snowflake (first time using it)
- Storage and compute are separate: the warehouse is the compute and is billed per second while running. Used X-Small with auto-suspend 60s to keep cost low.
- Roles: created a project role (TRANSFORMER) instead of working as ACCOUNTADMIN (least privilege).
- Unquoted identifiers are uppercased. My username is lowercase, so the GRANT failed until I wrapped it in double quotes.
- `IF NOT EXISTS` makes setup scripts safe to re run (idempotent). My first run failed halfway and re-running was safe.

## dbt
- (to fill in as I go)