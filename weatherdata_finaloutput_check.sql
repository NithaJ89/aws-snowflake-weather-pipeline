SELECT
    FILE_NAME,
    STATUS,
    ROW_COUNT,
    LAST_LOAD_TIME
FROM
    TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'SNOWFLAKE_LEARNING_DB.PUBLIC.WEATHER_DATA_RAW',
        START_TIME => DATEADD(MINUTE, -10, CURRENT_TIMESTAMP()) -- Check activity for the last 10 minutes
    ))
ORDER BY LAST_LOAD_TIME DESC;

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

