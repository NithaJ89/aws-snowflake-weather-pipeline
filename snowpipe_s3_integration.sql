
CREATE OR REPLACE FILE FORMAT processed_weather_json_format
  TYPE = 'JSON'
  STRIP_OUTER_ARRAY = TRUE 
  COMMENT = 'File format for processed weather data in JSON format.';


CREATE OR REPLACE TABLE weather_data_raw (
    raw_json VARIANT,
    load_timestamp TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

DROP PIPE WEATHER_PIPE;

CREATE OR REPLACE PIPE weather_pipe
  AUTO_INGEST = TRUE
  AS
  COPY INTO weather_data_raw (raw_json, load_timestamp)
  FROM (SELECT $1, CURRENT_TIMESTAMP() FROM @my_external_stage)
  FILE_FORMAT = (FORMAT_NAME = processed_weather_json_format)
  PATTERN = '.*\.json';

SELECT SYSTEM$PIPE_STATUS('weather_pipe');

SELECT * FROM SNOWFLAKE_LEARNING_DB.PUBLIC.weather_data_raw;