include etc/environment.sh

signer: signer.package signer.deploy
signer.package:
	sam package --profile ${PROFILE} -t ${SIGNER_TEMPLATE} --output-template-file ${SIGNER_OUTPUT} --s3-bucket ${S3BUCKET} --s3-prefix ${SIGNER_STACK}
signer.deploy:
	sam deploy --profile ${PROFILE} -t ${SIGNER_OUTPUT} --stack-name ${SIGNER_STACK} --parameter-overrides ${SIGNER_PARAMS} --capabilities CAPABILITY_NAMED_IAM
signer.list:
	aws signer --profile ${PROFILE} list-signing-platforms | jq -r '.platforms[].platformId'
signer.show:
	aws signer --profile ${PROFILE} get-signing-profile --profile-name ${O_SIGNER_ID} | jq
signer.job:
	aws signer --profile ${PROFILE} describe-signing-job --job-id ${O_SIGNER_JOB_ID} | jq

layer.unsigned: layer.prepare layer.package layer.deploy
layer.signed: layer.prepare layer.package.signed layer.deploy
layer.prepare:
	mkdir -p tmp/layer/python && pip install -r src/layer/requirements.txt -t tmp/layer/python --upgrade
layer.package:
	sam package -t ${LAYER_TEMPLATE} --output-template-file ${LAYER_OUTPUT} --s3-bucket ${BUCKET} --s3-prefix ${LAYER_STACK}
layer.package.signed:
	sam package -t ${LAYER_TEMPLATE} --output-template-file ${LAYER_OUTPUT} --s3-bucket ${BUCKET_VERSIONED} --s3-prefix ${LAYER_STACK} --signing-profiles ${P_SIGNING_PROFILES_LAYER}
layer.deploy:
	sam deploy -t ${LAYER_OUTPUT} --stack-name ${LAYER_STACK} --parameter-overrides ${LAYER_PARAMS} --capabilities CAPABILITY_NAMED_IAM
layer.show:
	aws lambda --profile ${PROFILE} get-layer-version --layer-name ${P_NAME} --version-number ${O_LAYER_VERSION_NUMBER} | jq

lambda.unsigned: lambda.package lambda.deploy
lambda.signed: lambda.package.signed lambda.deploy
lambda.package:
	sam package --profile ${PROFILE} -t ${LAMBDA_TEMPLATE} --output-template-file ${LAMBDA_OUTPUT} --s3-bucket ${BUCKET} --s3-prefix ${LAMBDA_STACK}
lambda.package.signed:
	sam package --profile ${PROFILE} -t ${LAMBDA_TEMPLATE} --output-template-file ${LAMBDA_OUTPUT} --s3-bucket ${BUCKET_VERSIONED} --s3-prefix ${LAMBDA_STACK} --signing-profiles ${P_SIGNING_PROFILES_FN}
lambda.deploy:
	sam deploy --profile ${PROFILE} -t ${LAMBDA_OUTPUT} --stack-name ${LAMBDA_STACK} --parameter-overrides ${LAMBDA_PARAMS} --capabilities CAPABILITY_NAMED_IAM
lambda.show:
	aws lambda --profile ${PROFILE} get-function-configuration --function-name ${O_FN} | jq

lambda.local:
	sam local invoke -t ${LAMBDA_TEMPLATE} --parameter-overrides ${LAMBDA_PARAMS} --env-vars etc/envvars.json -e etc/event.json Fn | jq
lambda.invoke.sync:
	aws lambda invoke --profile ${PROFILE} --function-name ${O_FN} --invocation-type RequestResponse --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "." > tmp/response.json
	cat tmp/response.json | jq -r ".LogResult" | base64 --decode
	cat tmp/fn.json | jq
lambda.invoke.async:
	aws lambda invoke --profile ${PROFILE} --function-name ${O_FN} --invocation-type Event --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "."

cdk.synth:
	cd iac/cdk && cdk synth
cdk.deploy:
	cd iac/cdk && cdk deploy --context stackName=${CDK_STACK}
cdk.destroy:
	cd iac/cdk && cdk destroy --context stackName=${CDK_STACK}
