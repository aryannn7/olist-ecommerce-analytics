-- 01_setup.sql
-- One time account setup: role, warehouse, database and raw schema.
-- Run once in a Snowsight worksheet, starting as ACCOUNTADMIN.

USE ROLE ACCOUNTADMIN;

-- 1. A dedicated role for this project (least privilege)
CREATE ROLE IF NOT EXISTS TRANSFORMER
  COMMENT = 'Loads raw data and runs dbt for the Olist project';
GRANT ROLE TRANSFORMER TO ROLE SYSADMIN;
GRANT ROLE TRANSFORMER TO USER "aryandhawan210";

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