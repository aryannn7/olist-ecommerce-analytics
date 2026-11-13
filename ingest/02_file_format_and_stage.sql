-- 02_file_format_and_stage.sql
-- How to read the Olist CSVs, and the internal stage they are uploaded to.

USE ROLE TRANSFORMER;
USE WAREHOUSE TRANSFORM_WH;
USE SCHEMA OLIST.RAW;

CREATE OR REPLACE FILE FORMAT OLIST.RAW.CSV_FORMAT
  TYPE                           = CSV
  FIELD_DELIMITER                = ','
  SKIP_HEADER                    = 1
  FIELD_OPTIONALLY_ENCLOSED_BY   = '"'
  NULL_IF                        = ('', 'NULL', 'null')
  EMPTY_FIELD_AS_NULL            = TRUE
  TRIM_SPACE                     = TRUE
  ENCODING                       = 'UTF8'
  ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE;

CREATE OR REPLACE STAGE OLIST.RAW.OLIST_STAGE
  FILE_FORMAT = OLIST.RAW.CSV_FORMAT
  COMMENT     = 'Internal stage for raw Olist CSV files';