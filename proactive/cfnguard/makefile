include etc/environment.sh

test:
	cfn-guard test --rules-file etc/lambda_inside_vpc.guard --test-data etc/tests/test_lambda_inside_vpc.yaml
	cfn-guard test --rules-file etc/lambda_public_access_prohibited.guard --test-data etc/tests/test_lambda_public_access_prohibited.yaml

validate.already_deprecated:
	cfn-guard validate --rules etc/sam_lambda_already_deprecated_runtime.guard --data iac/lambda.yaml
validate.concurrent_executions:
	cfn-guard validate --rules etc/sam_lambda_concurrent_execution_limit_configured.guard --data iac/lambda.yaml
validate.in_vpc:
	cfn-guard validate --rules etc/sam_lambda_in_vpc.guard --data iac/lambda.yaml
validate.soon_to_be_deprecated:
	cfn-guard validate --rules etc/sam_lambda_soon_to_be_deprecated_runtime.guard --data iac/lambda.yaml
