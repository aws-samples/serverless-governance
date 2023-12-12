# Overview
This repository implements example controls as Config rules with AWS Lambda functions.

## Pre-requisites
Copy `etc/environment.template` to `etc/environment.sh` and update accordingly.
* `PROFILE`: your AWS CLI profile with the appropriate credentials to deploy
* `REGION`: your AWS region
* `BUCKET`: your configuration bucket

For the Lambda stack, update the following accordingly.
* `P_FN_MEMORY`: amount of memory in MB for the Lambda function
* `P_FN_TIMEOUT`: timeout in seconds for the Lambda function

For the Config stack, update the following accordingly.
* `P_REQUIRED_SUBNET_IDS`: a comma-separated string of private subnet ids for VPC-enabled Lambda functions

For the optional Violations stack, update the following accordingly. This stack is optional as it deploys functions that intentionally violate example controls.
* `P_VPC_ID`: your VPC id
* `P_VIOLATION_SUBNET_IDS`: a comma-separated string of private subnet ids for VPC-enabled Lambda functions

## Deployment
Deploy the Lambda resources: `make lambda`

After completing the deployment, update the following outputs:
* `O_FN_DEPRECATED_RUNTIME`: output function name for deprecated runtimes
* `O_FN_REQUIRED_TAGS`: output function name for required tags
* `O_FN_REQUIRED_TAGS_EXPLORER`: output function name for required tags using explorer
* `O_FN`: can be set to any of the above ids for local testing

Deploy the Config resources: `make config`

Deploy the Lambda resources: `make violations`. This stack will fail to deploy because it has a function with a deprecated runtime. You will see the following error message: "The runtime parameter of nodejs12.x is no longer supported for creating or updating AWS Lambda functions."

## Testing
To test a function locally, update `P_TEST_FN` to the resource id of the function in the SAM template, e.g. `FnLambdaRequiredTagsExplorer`. Then run the following to test: `make lambda.local`. Note that for local testing, the event payload has a `resultToken` value which is invalid and will result in an error that the "result token provided is invalid". This is expected unless you update the event payload with a valid token.

## Control examples
Managed rules:
- [x] All Lambda functions must not be publicly accessible: `LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED`
- [x] All Lambda functions must be attached to a VPC: `LAMBDA_INSIDE_VPC`

Custom rules:
- [x] Lambda functions running Python must run Python 3+ version: `RuleLambdaDeprecatedRuntime` (can update to be more specific)
- [x] Lambda resources must be tagged with a valid appropriate tags (existing managed required-tags rule does not cover Lambda)
- [ ] Lambda layers must not be accessible outside of the Organization
- [ ] Lambda functions with an attached security group must use an approved version
- [ ] Lambda functions with an attached security group must have matching tags between the function and security group
- [ ] Lambda functions with an attached layer must use an approved version
- [ ] Lambda environment variables must be encrypted at rest with customer managed key
- [ ] Lambda environment variables must not store secrets
- [ ] Lambda@Edge resources are only able to access CloudFront and CloudWatch logs
- [ ] Lambda@Edge resources can only be invoked by CloudFront

## Resource Explorer
Resource Explorer is another option for querying resources with the query syntax is documented [here](https://docs.aws.amazon.com/resource-explorer/latest/userguide/using-search-query-syntax.html). According to [documentation](https://docs.aws.amazon.com/resource-explorer/latest/userguide/getting-started-setting-up.html?icmpid=docs_re_console_getting-started-setting-up):
> Tagged resources local to the index appear in search results within a few minutes. Untagged resources typically take less than two hours to appear, but can take longer when there is heavy demand. It can also can take up to an hour to complete the initial replication to a new aggregator index from all of the existing local indexes.

Depending on the requirements of how quickly resource changes need to be detected for an organization, the time for a resource to show up in the index might inhibit use of Resource Explorer for detecting violations. Be sure to test if resource detection through Resource Explorer is sufficient for your needs.
