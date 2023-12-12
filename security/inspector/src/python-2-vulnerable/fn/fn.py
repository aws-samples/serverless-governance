import json
import requests

def handler(event, context):
    response = {
        "level": "warn",
        "message": "function is vulnerable"
    }
    print(json.dumps(response))
    return response
