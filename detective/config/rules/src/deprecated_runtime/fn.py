import boto3
import botocore.exceptions
import json
from lib.encoders import DateTimeEncoder
from lib.enums import ComplianceStates
from lib.lambda_describer import LambdaDescriber

# initialization
session = boto3.session.Session()
client = session.client('config')

# upcoming phase 1 runtime deprecation timeframes (as of 12/8/2023):
# https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html
# 11/27/2023: nodejs14.x
# 11/27/2023: python3.7
# 12/07/2023: ruby2.7
# 12/31/2023: java8
# 12/31/2023: go1.x
# 12/31/2023: provided
# 05/14/2024: dotnet7
# 06/12/2024: nodejs16.x
DEPRECATED_RUNTIME_IDENTIFIERS = [
  "dotnetcore1.0",
  "dotnetcore2.0",
  "dotnetcore2.1",
  "dotnetcore3.1",
  "dotnet5.0",
  "nodejs",
  "nodejs4.3",
  "nodejs4.3-edge",
  "nodejs6.10",
  "nodejs8.10",
  "nodejs10.x",
  "nodejs12.x",
  "python2.7",
  "python3.6",
  "ruby2.5"
]

def has_deprecated_runtime():
    ld = LambdaDescriber(session)
    fns = ld.list_functions(online=True)
    output = []
    for fn in fns:
        invalid = {
            "FunctionArn": fn["FunctionArn"],
            "InvalidRuntimes": [fn["Runtime"]] if fn["Runtime"] in DEPRECATED_RUNTIME_IDENTIFIERS else []
        }
        output.append(invalid)

    print(json.dumps(output))
    return output

def get_violations(invoking_event):
    violations = []
    message_type = invoking_event["messageType"]
    if message_type == "ScheduledNotification":
        violations = has_deprecated_runtime()
    elif message_type == "ConfigurationItemChangeNotification":
        violations = []
    return violations

def get_evaluations(violations, timestamp):
    evaluations = []
    for violation in violations:
        evaluation = {
            "OrderingTimestamp": timestamp,
            "ComplianceResourceType": "AWS::Lambda::Function",
            "ComplianceResourceId": violation["FunctionArn"].split(":")[-1],
            "ComplianceType": ComplianceStates.NOT_APPLICABLE.value
        }
        if len(violation["InvalidRuntimes"]) > 0:
            evaluation["ComplianceType"] = ComplianceStates.NON_COMPLIANT.value
            evaluation["Annotation"] = violation["InvalidRuntimes"][0]
        elif len(violation["MissingTags"]) == 0:
            evaluation["ComplianceType"] = ComplianceStates.COMPLIANT.value
        evaluations.append(evaluation)
    return evaluations

def handler(event, context):
    print(json.dumps(event))
    invoking_event = json.loads(event["invokingEvent"])
    print(json.dumps(invoking_event, cls=DateTimeEncoder))
    timestamp = str(invoking_event["notificationCreationTime"])
    result_token = event["resultToken"]

    violations = get_violations(invoking_event)
    evaluations = get_evaluations(violations, timestamp)
    print(json.dumps(evaluations, cls=DateTimeEncoder))

    try:
        response = client.put_evaluations(Evaluations=evaluations, ResultToken=result_token)
    except botocore.exceptions.ClientError as e:
        response = e.response
    print(json.dumps(response))

    return violations