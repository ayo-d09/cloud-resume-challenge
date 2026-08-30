import os
import boto3
import json
from decimal import Decimal

dynamodb = boto3.resource("dynamodb")
ddbTable = os.environ.get("TABLE_NAME")
table = dynamodb.Table(ddbTable)

ALLOWED_ORIGINS = {"https://ayomideobadina.com", "https://www.ayomideobadina.com"}

def lambda_handler(event, context):
    origin = event.get("headers", {}).get("origin", "")
    allow_origin = origin if origin in ALLOWED_ORIGINS else ""

    headers = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": allow_origin,
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
    }

    try:
        response = table.update_item(
            Key={"id": "visitor_count"},
            UpdateExpression="ADD #count :inc",
            ExpressionAttributeNames={"#count": "count"},
            ExpressionAttributeValues={":inc": Decimal(1)},
            ReturnValues="UPDATED_NEW",
        )

        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({"count": int(response["Attributes"]["count"])}),
        }
    except Exception as e:
        print(f"Visitor-count update failed: {e}")
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"message": "Unable to update visitor count."}),
        }
