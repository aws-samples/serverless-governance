include etc/environment.sh

lambda: lambda.build lambda.package lambda.deploy
layer.prepare:
	pip install -r src/python-2-patched/layer/requirements.txt --target=src/python-2-patched/tmp/python --upgrade
	pip install -r src/python-2-vulnerable/layer/requirements.txt --target=src/python-2-vulnerable/tmp/python --upgrade
lambda.build:
	sam build -t ${LAMBDA_TEMPLATE} --parameter-overrides ${LAMBDA_PARAMS} --build-dir build --use-container
lambda.package:
	sam package -t build/template.yaml --region ${REGION} --output-template-file ${LAMBDA_OUTPUT} --s3-bucket ${BUCKET} --s3-prefix ${LAMBDA_STACK}
lambda.deploy:
	sam deploy -t ${LAMBDA_OUTPUT} --region ${REGION} --stack-name ${LAMBDA_STACK} --parameter-overrides ${LAMBDA_PARAMS} --capabilities CAPABILITY_NAMED_IAM

lambda.local:
	sam local invoke -t build/template.yaml --parameter-overrides ${LAMBDA_PARAMS} --env-vars etc/envvars.json -e etc/event.json ${TEST_FN} | jq
lambda.invoke.sync:
	aws --profile ${PROFILE} lambda invoke --function-name ${O_FN} --invocation-type RequestResponse --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "." > tmp/response.json
	cat tmp/response.json | jq -r ".LogResult" | base64 --decode
	cat tmp/fn.json | jq
lambda.invoke.async:
	aws --profile ${PROFILE} lambda invoke --function-name ${O_FN} --invocation-type Event --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "."

cdk.synth:
	cd iac/cdk && cdk synth ${CDK_PARAMS}
cdk.deploy:
	cd iac/cdk && cdk deploy --context stackName=${CDK_STACK} ${CDK_PARAMS}
cdk.destroy:
	cd iac/cdk && cdk destroy --context stackName=${CDK_STACK} ${CDK_PARAMS}

terraform.init:
	cd iac/terraform && terraform init
terraform.plan:
	cd iac/terraform && terraform plan -var-file=variable.tfvars
terraform.apply:
	cd iac/terraform && terraform apply -var-file=variable.tfvars
terraform.destroy:
	cd iac/terraform && terraform destroy -var-file=variable.tfvars
