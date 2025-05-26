import boto3
import json

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("joshvvcv-vstore")

def lambda_handler(event, context):
    res = table.update_item(
        Key={"joshvvcv.com": "homepage"},
        UpdateExpression="ADD visit_count :incr",
        ExpressionAttributeValues={":incr": 1},
        ReturnValues="UPDATED_NEW"
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"visits": int(res['Attributes']['visit_count'])}),
        "headers": {
            'Content-Type': 'application/json',
            "Access-Control-Allow-Origin": "https://joshvvcv.com"
        }
    }

