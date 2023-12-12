import json

def handler(event, context):
    output = {
        "message": "hello world"
    }
    print(json.dumps(output))
    return output