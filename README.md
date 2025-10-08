**AWS-Snowflake Real-Time Weather ETL Pipeline**

This repository contains the full code and SQL setup for a serverless, automated data pipeline that collects real-time weather data and streams it into Snowflake using Snowpipe for immediate analytics.

The pipeline runs every two minutes, demonstrating continuous ingestion capabilities.

✨Architecture
The project follows a standard cloud ETL pattern:

Extract & Transform: AWS Lambda fetches data from the OpenWeatherMap API, flattens the JSON, and stages it.

Staging: Data is stored as JSON files in an S3 bucket.

Load: An S3 event notification triggers Snowpipe via an SQS queue, immediately loading the data into Snowflake's variant column.

🛠️ Tech Stack
Component	Technology	Role
Data Source	--> OpenWeatherMap API Real-time weather data.
Compute/Scheduler	--> AWS Lambda / EventBridge Serverless data collection and scheduling.
Staging/Queue -->	AWS S3 / SQS	Staging area and event messaging for Snowpipe.
Data Warehouse -->	Snowflake	Target data platform using Snowpipe.
Code -->	Python Lambda runtime language.

Export to Sheets
⚙️ Setup and Deployment
Step 1: AWS Setup (Lambda & S3)
S3 Bucket: Create an S3 bucket (e.g., weather-data-bucket-nitha). Within this bucket, all files will be written to the processed_weather_data/ prefix.

OpenWeatherMap API: Obtain a free API key and get the target city name (e.g., Dubai).

Lambda Deployment:

Create a new Python 3.x Lambda function.

Use the code from lambda_function.py.

Set the following Environment Variables:
| Key | Value |
| :--- | :--- |
| API_KEY | Your OpenWeatherMap Key |
| CITY | Target City (e.g., Dubai) |
| WEATHER_DATA_BUCKET | Your S3 Bucket Name (e.g., weather-data-bucket-nitha) |

Grant the Lambda's IAM Role permissions to:

Read/Write to the target S3 bucket.

Write logs to CloudWatch.

EventBridge Trigger: Configure an EventBridge (CloudWatch Events) rule to trigger the Lambda function every 2 minutes.

Step 2: Snowflake Setup (SQL Files)
Execute the SQL files in the following order in your Snowflake worksheet:

1. Setup Database, Warehouse, and File Format
The processed_weather_json_format includes STRIP_OUTER_ARRAY = TRUE to handle the JSON array structure created by the Lambda.

File: weatherdata_s3_snowflake_integration.sql

SQL

-- 1. Create Database and Warehouse
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH WITH WAREHOUSE_SIZE = 'XSMALL';
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_LEARNING_DB;
USE DATABASE SNOWFLAKE_LEARNING_DB;
USE SCHEMA PUBLIC;

-- 2. Create Target Table (Raw Data)
CREATE TABLE IF NOT EXISTS weather_data_raw (
    raw_json VARIANT,
    load_timestamp TIMESTAMP_TZ
);

-- 3. Create JSON File Format
CREATE OR REPLACE FILE FORMAT processed_weather_json_format
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE;
2. Create the External Stage
This step links Snowflake to your S3 bucket using a Storage Integration.

File: External_Stage.sql

SQL

-- 1. Create Storage Integration (run this first and copy the External ID & S3 ARN)
CREATE OR REPLACE STORAGE INTEGRATION s3_integration_weather
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_SNOWFLAKE_ROLE' -- Replace with your actual IAM Role ARN
    STORAGE_ALLOWED_LOCATIONS = ('s3://weather-data-bucket-nitha/processed_weather_data/');

-- NOTE: Execute DESCRIBE INTEGRATION to get the External ID and ARN for AWS IAM setup.
DESC INTEGRATION s3_integration_weather;

-- 2. Create the External Stage
CREATE OR REPLACE STAGE my_external_stage
    URL = 's3://weather-data-bucket-nitha/processed_weather_data/'
    STORAGE_INTEGRATION = s3_integration_weather
    FILE_FORMAT = processed_weather_json_format;
Remember to update your IAM role in AWS with the Snowflake STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID.

3. Create the Snowpipe
This creates the continuous ingestion pipe object.

File: snowpipe_s3_integration.sql

SQL

-- Create the pipe object
CREATE OR REPLACE PIPE weather_pipe
  AUTO_INGEST = TRUE
  AS
  COPY INTO weather_data_raw (raw_json, load_timestamp)
  FROM (SELECT $1, CURRENT_TIMESTAMP() FROM @my_external_stage)
  FILE_FORMAT = (FORMAT_NAME = processed_weather_json_format)
  -- The pattern is simplified because the stage URL includes the 'processed_weather_data/' prefix
  PATTERN = '.*\.json';

-- NOTE: Execute the following command and copy the SQS ARN for S3 Event Notification.
SELECT SYSTEM$PIPE_STATUS('weather_pipe');
Remember to create an S3 Event Notification in AWS pointing to the SQS ARN copied from SYSTEM$PIPE_STATUS.

Step 3: Final Verification
Run the final analytical query to view the continuously loaded data, filtered and transformed into a relational view.

File: weatherdata_final_output_check.sql

SQL

SELECT
    raw_json:city::VARCHAR AS City_Name,
    raw_json:timestamp::TIMESTAMP_TZ AS Reading_Time,
    raw_json:temperature::DECIMAL(5, 2) AS Temperature_C,
    raw_json:humidity::INTEGER AS Humidity_Percent,
    load_timestamp AS Snowflake_Load_Time
FROM
    SNOWFLAKE_LEARNING_DB.PUBLIC.weather_data_raw
WHERE 
    raw_json:city::VARCHAR = 'Dubai'
ORDER BY Reading_Time DESC
LIMIT 5;
