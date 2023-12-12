import boto3
import json

# initialization
session = boto3.session.Session()
client = session.client('dynamodb')

def handler(event, context):
    output = event
    output["message"] = "hello world"
    print(json.dumps(output))
    return output
