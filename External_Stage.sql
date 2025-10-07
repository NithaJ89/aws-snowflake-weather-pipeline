CREATE OR REPLACE STAGE my_external_stage
  URL = 's3://weather-data-bucket-nitha/processed_weather_data/'
  STORAGE_INTEGRATION = S3_INTEGRATION
  FILE_FORMAT = processed_weather_json_format;