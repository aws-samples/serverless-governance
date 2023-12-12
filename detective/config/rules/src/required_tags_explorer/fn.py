import boto3
import botocore.exceptions
import json
import os
from lib.encoders import DateTimeEncoder
from lib.enums import ComplianceStates

# initialization
session = boto3.session.Session()
config_client = session.client('config')
explorer_client = session.client('resource-explorer-2')

# get environment
REQUIRED_TAGS = os.environ.get("REQUIRED_TAGS", "application:group,application:subgroup,application:owner").split(",")

def has_required_tags(fn_arn=None):
    if fn_arn is None:
        query = "service:lambda resourcetype:lambda:function"
        for tag in REQUIRED_TAGS:
            query += f" -tag.key:{tag}"
    else:
        query = f"service:lambda resourcetype:lambda:function id:{fn_arn}"
    print(query)
    response = explorer_client.search(
        QueryString=query
    )
    print(json.dumps(response, cls=DateTimeEncoder))
    output = []
    for fn in response["Resources"]:
        missing_tags = []
        for required_tag in REQUIRED_TAGS:
            if len(fn["Properties"]) == 1 and "Data" in fn["Properties"][0]:
                applied_tags = [tag["Key"] for tag in fn["Properties"][0]["Data"]]
            else:
                applied_tags = []
            if required_tag not in applied_tags:
                missing_tags.append(required_tag)
        if len(missing_tags) > 0:
            violation = {
                "FunctionArn": fn["Arn"],
                "MissingTags": missing_tags
            }
            output.append(violation)
    return output

def get_violations(invoking_event):
    violations = []
    message_type = invoking_event["messageType"]
    if message_type == "ScheduledNotification":
        violations = has_required_tags()
    elif message_type == "ConfigurationItemChangeNotification":
        change_item_arn = invoking_event["configurationItem"]["ARN"]
        violations = has_required_tags(change_item_arn)
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
        if len(violation["MissingTags"]) > 0:
            evaluation["ComplianceType"] = ComplianceStates.NON_COMPLIANT.value
            evaluation["Annotation"] = json.dumps(violation["MissingTags"])
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
        response = config_client.put_evaluations(Evaluations=evaluations, ResultToken=result_token)
    except botocore.exceptions.ClientError as e:
        response = e.response
    print(json.dumps(response))

    return violations
