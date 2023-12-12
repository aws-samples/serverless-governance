include etc/environment.sh

lambda: lambda.package lambda.deploy
lambda.package:
	sam package --profile ${PROFILE} -t ${LAMBDA_TEMPLATE} --output-template-file ${LAMBDA_OUTPUT} --s3-bucket ${BUCKET} --s3-prefix ${LAMBDA_STACK}
lambda.deploy:
	sam deploy --profile ${PROFILE} -t ${LAMBDA_OUTPUT} --stack-name ${LAMBDA_STACK} --parameter-overrides ${LAMBDA_PARAMS} --capabilities CAPABILITY_NAMED_IAM

lambda.local:
	sam local invoke -t ${LAMBDA_TEMPLATE} --parameter-overrides ${LAMBDA_PARAMS} --env-vars etc/envvars.json -e etc/payload.json ${P_TEST_FN} | jq
lambda.invoke.sync:
	aws lambda invoke --profile ${PROFILE} --function-name ${O_FN} --invocation-type RequestResponse --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "." > tmp/response.json
	cat tmp/response.json | jq -r ".LogResult" | base64 --decode
	cat tmp/fn.json | jq
lambda.invoke.async:
	aws lambda invoke --profile ${PROFILE} --function-name ${O_FN} --invocation-type Event --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "."

config: config.package config.deploy
config.package:
	sam package --profile ${PROFILE} -t ${CONFIG_TEMPLATE} --output-template-file ${CONFIG_OUTPUT} --s3-bucket ${BUCKET} --s3-prefix ${CONFIG_STACK}
config.deploy:
	sam deploy --profile ${PROFILE} -t ${CONFIG_OUTPUT} --stack-name ${CONFIG_STACK} --parameter-overrides ${CONFIG_PARAMS} --capabilities CAPABILITY_NAMED_IAM

violations: violations.package violations.deploy
violations.package:
	sam package --profile ${PROFILE} -t ${VIOLATIONS_TEMPLATE} --output-template-file ${VIOLATIONS_OUTPUT} --s3-bucket ${BUCKET} --s3-prefix ${VIOLATIONS_STACK}
violations.deploy:
	sam deploy --profile ${PROFILE} -t ${VIOLATIONS_OUTPUT} --stack-name ${VIOLATIONS_STACK} --parameter-overrides ${VIOLATIONS_PARAMS} --capabilities CAPABILITY_NAMED_IAM

cdk.synth:
	cd iac/cdk && cdk synth
cdk.deploy:
	cd iac/cdk && cdk deploy --context stackName=${CDK_STACK}
