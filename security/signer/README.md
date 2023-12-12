## Overview
This repository implements code signing for deploying zip artifacts and layers for Lambda functions.

## Pre-requisites
Copy `etc/environment.template` to `etc/environment.sh` and update accordingly.
* `PROFILE`: your AWS CLI profile with the appropriate credentials to deploy
* `REGION`: your AWS region
* `BUCKET`: your versioned configuration bucket

Note that code signing requires a versioned bucket.

## Deployment
Deploy the Signer resources: `make signer`

After completing the deployment, update the following outputs:
* `O_SIGNER_ARN`: output ARN for the Signer signing profile
* `O_SIGNER_ID`: output id for the Signer signing profile
* `O_SIGNING_CONFIG_ARN`: output ARN for the Lambda signing configuration

Next we'll prepare the layer directory in preparation for testing both a signed and unsigned deployment of the layer.

Install the dependencies locally (aws-xray-sdk): `make layer.prepare`

Perform an unsigned deployment: `make layer.unsigned`

After completing the deployment, update the following outputs:
* `O_LAYER_ARN`: output ARN for the layer version
* `O_LAYER_VERSION_NUMBER` output layer version number

Make an update to the layer, which we'll do by updating the description: `P_DESCRIPTION=xray-2.12.1-signed`

Perform a signed deployment: `make layer.signed`
* This should be the same layer ARN but an incremented layer version.
* You will likely see version 1 with `xray-2.12.1-unsigned` and version 2 with `xray-2.12.1-signed`.

Deploy a function with the signed layer and a signed zip deployment: `make lambda.signed`

After completing the deployment, update the following outputs:
* `O_FN`: output function id
* `O_SIGNER_JOB_ID`: code signing job id

View the details of the signing job: `make signer.job`

##  Testing
Test the deployed function: `make lambda.invoke.sync`

Test a deployment with an unsigned zip deployment (which should fail): `make lambda.unsigned`

You should see an error message as follows:
```
Resource handler returned message: "Lambda cannot deploy the function. The function or layer might be signed using a signature that the client is not configured to accept. Check the provided signature for arn:aws:lambda:{REGION}:{ACCOUNTID}:function:{FUNCTIONID}. (Service: Lambda, Status Code: 400, Request ID: b9f228eb-35a5-4601-b4ad-4564d8c4aae1)" (RequestToken: c950e133-5d4a-c673-bab8-c3cd2b081406, HandlerErrorCode: InvalidRequest)
```

You can also attempt to attached the unsigned layer while performing a signed deployment. Update `O_LAYER_ARN` to point to the unsigned layer version and perform a signed deployment: `make lambda.signed`. You should see a similar failure message as above.
