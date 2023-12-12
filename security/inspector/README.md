## Overview
This repository demonstrates the capabilities of Inspector standard and code scanning.

## Pre-requisites
Enable Amazon Inspector in your account per the [documentation](https://docs.aws.amazon.com/inspector/latest/user/getting_started_tutorial.html) for a standalone account.

Copy `etc/environment.template` to `etc/environment.sh` and update accordingly.
* `PROFILE`: your AWS CLI profile with the appropriate credentials to deploy
* `REGION`: your AWS region
* `BUCKET`: your versioned configuration bucket

## Deployment
Prepare the layer dependencies: `make layer.prepare`  
Deploy the example functions: `make lambda`  
Note that this will build 8 functions locally and can take a few minutes to prepare.

## Testing
Test the function locally: `make lambda.local`  
To change the function that you test, update `TEST_FN` to the resource id in the SAM template.

Test the deployed function: `make lambda.invoke.sync`
To change the function that you test, update `O_FN` to the deployed function id in your AWS account.
