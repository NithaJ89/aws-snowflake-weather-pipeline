CREATE
OR REPLACE STORAGE INTEGRATION s3_integration TYPE = EXTERNAL_STAGE STORAGE_PROVIDER = 'S3' ENABLED = TRUE STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::560615485825:role/SnowflakeS3AccessRole' STORAGE_ALLOWED_LOCATIONS = (
    's3://weather-data-bucket-nitha/processed_weather_data/'
);
DESCRIBE INTEGRATION s3_integration;