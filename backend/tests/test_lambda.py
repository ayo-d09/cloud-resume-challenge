from moto import mock_aws
import boto3
import os
import json
import pytest

@pytest.fixture
def dynamodb_table():
    with mock_aws():
        dynamodb = boto3.resource("dynamodb", region_name="us-east-1")

        dynamodb.create_table(
            TableName="test_table",
            KeySchema=[
                {
                    "AttributeName": "id",
                    "KeyType": "HASH"
                }
            ],
            AttributeDefinitions=[
                {
                    "AttributeName": "id",
                    "AttributeType": "S"
                }
            ],
            ProvisionedThroughput={
                "ReadCapacityUnits": 1,
                "WriteCapacityUnits": 1
            }
        )
        yield dynamodb.Table("test_table")

def test_first_invocation(dynamodb_table):
    os.environ["TABLE_NAME"] = "test_table"
    os.environ["AWS_DEFAULT_REGION"] = "us-east-1"

    from backend.lambda_function import lambda_handler

    response = lambda_handler({}, {})
    body = json.loads(response["body"])

    assert response["statusCode"] == 200
    assert body["count"] == 1

def test_counter_increment(dynamodb_table):
    os.environ["TABLE_NAME"] = "test_table"
    os.environ["AWS_DEFAULT_REGION"] = "us-east-1"

    from backend.lambda_function import lambda_handler

    lambda_handler({}, {})
    response = lambda_handler({}, {})
    body = json.loads(response["body"])

    assert response["statusCode"] == 200
    assert body["count"] == 2

def test_return_500_when_update_fails(dynamodb_table, monkeypatch):
    os.environ["TABLE_NAME"] = "test_table"
    os.environ["AWS_DEFAULT_REGION"] = "us-east-1"

    from backend import lambda_function

    class FailingTable:
        def update_item(self, *args, **kwargs):
            raise Exception("DynamoDB unavailable")

    monkeypatch.setattr(lambda_function, "table", FailingTable())

    response = lambda_function.lambda_handler({}, {})
    assert response["statusCode"] == 500
    body = json.loads(response["body"])
    assert body["message"] == "Unable to update visitor count."

def test_cors_allows_known_origin(dynamodb_table):
    from backend.lambda_function import lambda_handler

    event = {"headers": {"origin": "https://ayomideobadina.com"}}
    response = lambda_handler(event, {})

    assert response["headers"]["Access-Control-Allow-Origin"] == "https://ayomideobadina.com"


def test_cors_blocks_unknown_origin(dynamodb_table):
    from backend.lambda_function import lambda_handler

    event = {"headers": {"origin": "https://random-site.com"}}
    response = lambda_handler(event, {})

    assert response["headers"]["Access-Control-Allow-Origin"] == ""