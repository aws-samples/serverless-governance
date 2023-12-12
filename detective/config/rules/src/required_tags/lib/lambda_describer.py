import boto3
import json
import sys
import botocore.exceptions
from lib.enums import LayerOptions

class LambdaDescriber:
    def __init__(self, session=None):
        if session is None:
            self.session = boto3.session.Session()
        else:
            self.session = session
        self.client = self.session.client("lambda")

    # helper functions
    def _list_layer_versions(self, layer):
        response = self.client.list_layer_versions(
            LayerName=layer
        )
        return response["LayerVersions"]

    def _list_functions_paginated(self, next_marker=None):
        if next_marker is None:
            response = self.client.list_functions()
        else:
            response = self.client.list_functions(
                Marker=next_marker
            )
        return response

    # function-level information
    def get_function(self, fname):
        response = self.client.get_function(
            FunctionName=fname
        )
        return response

    def list_layers(self, desired=None):
        response = self.client.list_layers()
        output = []
        for layer in response["Layers"]:
            if desired == LayerOptions.BASE:
                layer_arn = layer["LayerArn"]
            elif desired == LayerOptions.LATEST:
                layer_arn = layer["LatestMatchingVersion"]["LayerVersionArn"]
            elif desired == LayerOptions.ALL_VERSIONS:
                layer_arn = layer["LayerArn"]
                versions = self._list_layer_versions(layer_arn)
                for version in versions:
                    output.append(version["LayerVersionArn"])
            else:
                sys.exit(1)
            output.append(layer_arn)
        return output

    def list_functions(self, next_marker=None, online=False):
        fns = []
        if online:
            response = self._list_functions_paginated()
            fns.extend(response["Functions"])
            while "NextMarker" in response:
                response = self._list_functions_paginated(next_marker=response["NextMarker"])
                fns.extend(response["Functions"])
        else:
            with open("tmp/list_functions.json") as f:
                fns = json.load(f)
        return fns

    def list_functions_by_layer(self, online=False):
        layers = self.list_layers(LayerOptions.ALL_VERSIONS)
        fns = self.list_functions(online=online)

        output = {}
        for in_scope in layers:
            output[in_scope] = []
            for fn in fns:
                if "Layers" in fn:
                    for layer in fn["Layers"]:
                        if in_scope == layer["Arn"]:
                            output[in_scope].append(fn["FunctionName"])
        return output

    def list_functions_by_eni(self, online=False):
        fns = self.list_functions(online=online)

        output = []
        attribs = [
            "FunctionName", "Runtime",
            "State", "StateReason", "StateReasonCode",
            "LastModified",
            "LastUpdateStatus", "LastUpdateStatusReason", "LastUpdateStatusReasonCode",
            "VpcConfig"
        ]
        for fn in fns:
            payload = {}
            for attrib in attribs:
                if attrib in fn:
                    payload[attrib] = fn[attrib]
            if "VpcConfig" in fn and "VpcId" in fn["VpcConfig"] and fn["VpcConfig"]["VpcId"] != "":
                # details seem to be missing from list_functions()
                details = self.get_function(fn["FunctionName"])
                extras = ["State", "LastUpdateStatus"]
                for extra in extras:
                    payload[extra] = details["Configuration"][extra]
                output.append(payload)
        return output

    def list_functions_in_runtime_list(self, runtimes, online=False):
        fns = self.list_functions(online=online)

        output = []
        for fn in fns:
            runtime = fn["Runtime"]
            if runtime in runtimes:
                output.append(fn)
        return output

    def list_tags(self, resource):
        try:
            response = self.client.list_tags(Resource=resource)["Tags"]
        except botocore.exceptions.ClientError as e:
            # TODO: if rate limited, will return no tags (creates false positive)
            print(json.dumps(e.response))
            response = []
        return response

    def list_functions_without_tags(self, required_tags, fn_arn=None, online=False):
        if fn_arn is None:
            fns = self.list_functions(online=online)
        else:
            fns = [{"FunctionArn": fn_arn}]
        print(json.dumps(required_tags))

        output = []
        for fn in fns:
            applied_tags = self.list_tags(fn["FunctionArn"])
            missing_tags = []
            for required_tag in required_tags:
                if required_tag not in applied_tags:
                    missing_tags.append(required_tag)
            violation = {
                "FunctionArn": fn["FunctionArn"],
                "MissingTags": missing_tags
            }
            output.append(violation)
        return output

    # account-level information
    def get_concurrency_limits(self):
        response = self.client.get_account_settings()
        output = {
            "limits": {
                "concurrent_executions": response["AccountLimit"]["ConcurrentExecutions"],
                "unreserved_concurrent_executions": response["AccountLimit"]["UnreservedConcurrentExecutions"]
            }
        }
        return output

    def get_code_storage(self):
        response = self.client.get_account_settings()
        total_code_gb = response["AccountLimit"]["TotalCodeSize"]/1024/1024/1024
        total_code_used = response["AccountUsage"]["TotalCodeSize"]/1024/1024/1024
        per_fn_code_size_unzipped_mb = response["AccountLimit"]["CodeSizeUnzipped"]/1024/1024
        per_fn_code_size_zipped_mb = response["AccountLimit"]["CodeSizeZipped"]/1024/1024
        fn_count = response["AccountUsage"]["FunctionCount"]
        output = {
            "limits": {
                "total_code_gb": total_code_gb,
                "per_fn_code_size_unzipped_mb": per_fn_code_size_unzipped_mb,
                "per_fn_code_size_zipped_mb": per_fn_code_size_zipped_mb
            },
            "usage": {
                "total_code_used_gb": total_code_used,
                "total_code_remaining_gb": total_code_gb - total_code_used,
                "fn_count": fn_count
            }
        }
        return output
