-- 01_setup.sql
-- One time account setup: role, warehouse, database and raw schema.
-- Run once in a Snowsight worksheet, starting as ACCOUNTADMIN.

USE ROLE ACCOUNTADMIN;

-- 1. A dedicated role for this project (least privilege)
CREATE ROLE IF NOT EXISTS TRANSFORMER
  COMMENT = 'Loads raw data and runs dbt for the Olist project';
GRANT ROLE TRANSFORMER TO ROLE SYSADMIN;
GRANT ROLE TRANSFORMER TO USER <"snowflake_user">;

-- 2. A small warehouse that switches itself off when idle
CREATE WAREHOUSE IF NOT EXISTS TRANSFORM_WH
  WAREHOUSE_SIZE      = 'XSMALL'
  AUTO_SUSPEND        = 60
  AUTO_RESUME         = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'X-Small warehouse for loading and dbt runs';
GRANT USAGE, OPERATE ON WAREHOUSE TRANSFORM_WH TO ROLE TRANSFORMER;

-- 3. Allow the project role to create its own database
GRANT CREATE DATABASE ON ACCOUNT TO ROLE TRANSFORMER;

-- 4. Switch to the project role and build the containers
USE ROLE TRANSFORMER;
USE WAREHOUSE TRANSFORM_WH;

CREATE DATABASE IF NOT EXISTS OLIST
  COMMENT = 'Olist e-commerce analytics project';

CREATE SCHEMA IF NOT EXISTS OLIST.RAW
  COMMENT = 'Raw files loaded as-is, no cleaning';


-- 5. Service user for dbt (key-pair auth only, no password)
-- Generate the key pair locally first; paste the public key below.
CREATE USER IF NOT EXISTS DBT_SVC
  TYPE              = SERVICE
  DEFAULT_ROLE      = TRANSFORMER
  DEFAULT_WAREHOUSE = TRANSFORM_WH
  RSA_PUBLIC_KEY    = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxIjAnA3vfX+xD5h0/6/O
7xbrDFoFCKHPWxhTmxgA8gVWRxRTv476QZKmSFwWrKag7MmOk/k8a/kkXDcEzebQ
pc2X241HDwtmg3HjtP60+LcQkSx5vkxoLBOFNflU+PcG45FHh4XkY+yqLtBjOxEv
ErtM2okjyXECaEJrwCVD7KOPtS3T6yilb9vAkcMw2vcTur3VRnwK2mz4sQaD974s
euhdXck83UX9X3oH96qDj7umST50ow7TWOHFU+v0DL6XDUtwJi30U34wX8hih39v
92RSqRmi5NsSoY8D2R+bwTYJs03LryIzcQZwiROFg8bJaoQ6O1KCW8JB+K9cu+Z5
kQIDAQAB';
GRANT ROLE TRANSFORMER TO USER DBT_SVC;