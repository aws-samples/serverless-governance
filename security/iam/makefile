include etc/environment.sh

iam: iam.package iam.deploy
iam.package:
	sam package --profile ${PROFILE} -t ${IAM_TEMPLATE} --output-template-file ${IAM_OUTPUT} --s3-bucket ${BUCKET} --s3-prefix ${IAM_STACK}
iam.deploy:
	sam deploy --profile ${PROFILE} -t ${IAM_OUTPUT} --stack-name ${IAM_STACK} --parameter-overrides ${IAM_PARAMS} --capabilities CAPABILITY_NAMED_IAM

lambda: lambda.package lambda.deploy
lambda.package:
	sam package --profile ${PROFILE} -t ${LAMBDA_TEMPLATE} --output-template-file ${LAMBDA_OUTPUT} --s3-bucket ${BUCKET} --s3-prefix ${LAMBDA_STACK}
lambda.deploy:
	sam deploy --profile ${PROFILE} -t ${LAMBDA_OUTPUT} --stack-name ${LAMBDA_STACK} --parameter-overrides ${LAMBDA_PARAMS} --role-arn ${O_CFN_ROLE_ARN} --capabilities CAPABILITY_NAMED_IAM

lambda.local:
	sam local invoke -t ${LAMBDA_TEMPLATE} --parameter-overrides ${LAMBDA_PARAMS} --env-vars etc/envvars.json -e etc/event.json Fn | jq
lambda.invoke.sync:
	aws lambda invoke --profile ${PROFILE} --function-name ${O_FN} --invocation-type RequestResponse --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "." > tmp/response.json
	cat tmp/response.json | jq -r ".LogResult" | base64 --decode
	cat tmp/fn.json | jq
lambda.invoke.async:
	aws lambda invoke --profile ${PROFILE} --function-name ${O_FN} --invocation-type Event --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "."

cdk.synth:
	cd iac/cdk && cdk synth --parameters ${CDK_PARAMS}
cdk.deploy:
	cd iac/cdk && cdk deploy --context stackName=${CDK_STACK} --parameters ${CDK_PARAMS}
cdk.destroy:
	cd iac/cdk && cdk destroy --context stackName=${CDK_STACK} --parameters ${CDK_PARAMS}
