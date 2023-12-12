## Overview
This repository deploys an IAM role under which all other deployments are governed. This emulates the behavior of enterprises that perform deployments via pipelines, which assume an IAM role for performing actions within an AWS account.

## Pre-requisites
Copy `etc/environment.template` to `etc/environment.sh` and update accordingly.
* `PROFILE`: your AWS CLI profile with the appropriate credentials to deploy
* `REGION`: your AWS region
* `BUCKET`: your configuration bucket

For the Lambda stack, update the following accordingly.
* `P_FN_MEMORY`: amount of memory in MB for the Lambda function
* `P_FN_TIMEOUT`: timeout in seconds for the Lambda function

With the environment configuration set, deploy an example stack.

## Deployment
Deploy the IAM role using: `make iam`

After completing the deployment, update the following outputs:
* `O_CFN_ROLE_ARN`: output ARN for the IAM role for CloudFormation deployments

Note that this IAM role is used to perform a `sam deploy` while specifying a `-role-arn` with the specified permissions to deploy the resources. This IAM role can be vended by security teams for use with pipeline deployments.

## Testing
To test the IAM role and deployment permissions: `make lambda`  
To test the function locally: `make lambda.local`  
To test the deployed function: `make lambda.invoke.sync`
