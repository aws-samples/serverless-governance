# Overview
This repository implements example controls as CloudFormation Guard rules. It demonstrates how to unit test rules and how to validate templates with rules.

## Pre-requisites
Install the [CloudFormation Guard CLI tool](https://docs.aws.amazon.com/cfn-guard/latest/ug/setting-up.html).

## Testing
To test rule files against provided test templates: `make test`

To validate example rule (already deprecated): `make validate.already_deprecated`  
To validate example rule (concurrent executions): `make validate.concurrent_executions`  
To validate example rule (inside vpc): `make validate.in_vpc`  
To validate example rule (soon to be deprecated): `make validate.soon_to_be_deprecated`

## Alternates
To use CloudFormation Guard with CDK, validations can be done using the `CfnGuardValidator` plugin, as documented in [Github](https://github.com/cdklabs/cdk-validator-cfnguard).  
To use CloudFormation Guard with Terraform, validations can be done against the Terraform plan in JSON format, as mentioned in [Github](https://github.com/aws-cloudformation/cloudformation-guard).
