import json
import requests

def handler(event, context):
    response = {
        "level": "info",
        "message": "function is patched"
    }
    print(json.dumps(response))
    return response
