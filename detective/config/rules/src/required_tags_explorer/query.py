import boto3
import json
from datetime import datetime

class DateTimeEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, datetime):
            return o.isoformat()
        return json.JSONEncoder.default(self, o)

def main():
    session = boto3.session.Session()
    client = session.client('resource-explorer-2')
    # query = "service:lambda tag:application:group=governance tag:application:subgroup=config"
    query = "service:lambda resourcetype:lambda:function  -tag.key:application:group  -tag.key:application:owner"
    response = client.search(
        QueryString=query
    )
    print(json.dumps(response, cls=DateTimeEncoder))

if __name__ == "__main__":
    main()