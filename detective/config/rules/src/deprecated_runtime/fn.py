import boto3
import json
from lib.lambda_describer import LambdaDescriber
from lib.enums import ComplianceStates

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
    validations = []
    for fn in fns:
        validation = {
            "FunctionArn": fn["FunctionArn"],
            "InvalidRuntimes": [fn["Runtime"]] if fn["Runtime"] in DEPRECATED_RUNTIME_IDENTIFIERS else []
        }
        validations.append(validation)

    print(json.dumps(validations))
    return validations

def handler(event, context):
    print(json.dumps(event))
    invoking_event = json.loads(event["invokingEvent"])
    message_type = invoking_event["messageType"]
    timestamp = str(invoking_event["notificationCreationTime"])
    result_token = event["resultToken"]

    if message_type == "ScheduledNotification":
        validations = has_deprecated_runtime()
    elif message_type == "ConfigurationItemChangeNotification":
        validations = []
    else:
        validations = []

    evaluations = []
    for validation in validations:
        evaluation = {
            "ComplianceResourceType": "AWS::Lambda::Function",
            "ComplianceResourceId": validation["FunctionArn"].split(":")[-1],
            "OrderingTimestamp": timestamp,
        }
        if len(validation["InvalidRuntimes"]) > 0:
            evaluation["ComplianceType"] = ComplianceStates.NON_COMPLIANT.value
            evaluation["Annotation"] = validation["InvalidRuntimes"][0]
        elif len(validation["InvalidRuntimes"]) == 0:
            evaluation["ComplianceType"] = ComplianceStates.COMPLIANT.value
        else:
            evaluation["InvalidRuntimes"] = ComplianceStates.NOT_APPLICABLE.value
        evaluations.append(evaluation)

    response = client.put_evaluations(Evaluations=evaluations, ResultToken=result_token)
    print(json.dumps(response))
    return response