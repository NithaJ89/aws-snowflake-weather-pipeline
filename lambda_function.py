import json
import os
import boto3
import requests
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')

DYNAMO_TABLE = os.environ['WEATHER_DATA_TABLE']
S3_BUCKET = os.environ['WEATHER_DATA_BUCKET']
CITY = os.environ['CITY']
API_KEY = os.environ['API_KEY']

# --- Define the specific S3 prefix for Snowpipe ---
S3_SNOWPIPE_PREFIX = 'processed_weather_data/' 

def lambda_handler(event, context):
    url = f"http://api.openweathermap.org/data/2.5/weather?q={CITY}&appid={API_KEY}&units=metric"
    response = requests.get(url)
    weather = response.json()

    if response.status_code != 200:
        print(f"Error: {weather}")
        return {"status": "error", "message": weather}

    # 1. Prepare the processed/flattened data (same structure as for DynamoDB)
    processed_data = {
        "city": CITY,
        "timestamp": datetime.utcnow().isoformat() + 'Z', # Use 'Z' for UTC
        "temperature": weather['main']['temp'],
        "humidity": weather['main']['humidity'],
        "description": weather['weather'][0]['description']
    }

    # NOTE: DYNAMODB REQUIRES Decimal type, S3/JSON DOES NOT.
    # We remove the Decimal casting before serialization for S3 writing.
    
    # 2. Store in DynamoDB (Requires Decimal conversion)
    # The original DynamoDB logic is fine:
    dynamo_item = {k: Decimal(str(v)) if isinstance(v, (float, int)) else v for k, v in processed_data.items()}
    table = dynamodb.Table(DYNAMO_TABLE)
    table.put_item(Item=dynamo_item)

    # 3. Store Processed Data in S3 for Snowpipe (CRITICAL CHANGE)
    # The file should contain an array of objects to match STRIP_OUTER_ARRAY=TRUE
    # We will write the processed_data (not the raw 'weather' response) to the Snowpipe path
    
    # Define S3 Key using the required prefix
    file_key = f"{S3_SNOWPIPE_PREFIX}{CITY}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.json"
    
    # Create a list (array) containing the single processed data record
    # This matches the JSON structure you confirmed earlier: [ {record} ]
    s3_body = json.dumps([processed_data], indent=4) 

    s3.put_object(
        Bucket=S3_BUCKET,
        Key=file_key,
        Body=s3_body
    )

    print(f"Stored Processed data for {CITY} in DynamoDB and S3 at {file_key}")
    return {"status": "success", "data": processed_data}