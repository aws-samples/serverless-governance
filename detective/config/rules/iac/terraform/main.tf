provider "aws" {
    profile = var.profile
    region = var.region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "lambda_role" {
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Service = "lambda.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_policy" "lambda_policy_cloudwatch" {
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "logs:CreateLogGroup"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow",
                Action = [
                    "logs:CreateLogStream",
                    "logs:PutLogEvents",
                    "logs:DescribeLogStreams"
                ]
                Resource = "arn:aws:logs:*:*:log-group:*:*"
            }
        ]
    })
}
resource "aws_iam_policy" "lambda_policy_xray" {
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "xray:PutTraceSegments",
                    "xray:PutTelemetryRecords",
                    "xray:GetSamplingRules",
                    "xray:GetSamplingTargets",
                    "xray:GetSamplingStatisticSummaries"
                ]
                Resource = "*"
            }
        ]
    })
}
resource "aws_iam_policy" "lambda_policy_config" {
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "config:PutEvaluations"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow",
                Action = [
                    "lambda:ListFunctions",
                    "lambda:ListTags"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow",
                Action = [
                    "resource-explorer-2:Search"
                ]
                Resource = "arn:aws:resource-explorer-2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:view/*/*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "lambda_attach_cloudwatch" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.lambda_policy_cloudwatch.arn
}
resource "aws_iam_role_policy_attachment" "lambda_attach_xray" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.lambda_policy_xray.arn
}
resource "aws_iam_role_policy_attachment" "lambda_attach_config" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.lambda_policy_config.arn
}

data "archive_file" "zip_deprecated_runtime" {
    type = "zip"
    source_dir = "../../src/deprecated_runtime"
    output_path = "../../tmp/deprecated_runtime.zip"
}
resource "aws_s3_object" "s3_deprecated_runtime" {
    bucket = var.bucket
    key = "config/deprecated_runtime.zip"
    source = data.archive_file.zip_deprecated_runtime.output_path
    etag = filemd5(data.archive_file.zip_deprecated_runtime.output_path)
}
resource "aws_lambda_function" "fn_deprecated_runtime" {
    function_name = "tf-fn-deprecated-runtime"
    s3_bucket = var.bucket
    s3_key = aws_s3_object.s3_deprecated_runtime.key
    runtime = "python3.11"
    handler = "fn.handler"
    memory_size = var.fn_memory
    timeout = var.fn_timeout
    source_code_hash = data.archive_file.zip_deprecated_runtime.output_base64sha256
    role = aws_iam_role.lambda_role.arn
    layers = [
        "arn:aws:lambda:us-east-1:580247275435:layer:LambdaInsightsExtension:38"
    ]
    tags = {
        "application:group" = "governance"
        "application:subgroup" = "config"
        "application:owner" = "aws"
    }
}
resource "aws_lambda_permission" "fn_deprecated_runtime_allow_config" {
    function_name = aws_lambda_function.fn_deprecated_runtime.function_name
    principal = "config.amazonaws.com"
    action = "lambda:InvokeFunction"
    source_arn = "arn:aws:config:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:config-rule/*"
}
resource "aws_cloudwatch_log_group" "fn_deprecated_runtime_log_group" {
    name = "/aws/lambda/${aws_lambda_function.fn_deprecated_runtime.function_name}"
    retention_in_days = 7
}

data "archive_file" "zip_required_tags" {
    type = "zip"
    source_dir = "../../src/required_tags"
    output_path = "../../tmp/required_tags.zip"
}
resource "aws_s3_object" "s3_required_tags" {
    bucket = var.bucket
    key = "config/required_tags.zip"
    source = data.archive_file.zip_required_tags.output_path
    etag = filemd5(data.archive_file.zip_required_tags.output_path)
}
resource "aws_lambda_function" "fn_required_tags" {
    function_name = "tf-fn-required-tags"
    s3_bucket = var.bucket
    s3_key = aws_s3_object.s3_required_tags.key
    runtime = "python3.11"
    handler = "fn.handler"
    memory_size = var.fn_memory
    timeout = var.fn_timeout
    source_code_hash = data.archive_file.zip_required_tags.output_base64sha256
    role = aws_iam_role.lambda_role.arn
    layers = [
        "arn:aws:lambda:us-east-1:580247275435:layer:LambdaInsightsExtension:38"
    ]
    tags = {
        "application:group" = "governance"
        "application:subgroup" = "config"
        "application:owner" = "aws"
    }
}
resource "aws_lambda_permission" "fn_required_tags_allow_config" {
    function_name = aws_lambda_function.fn_required_tags.function_name
    principal = "config.amazonaws.com"
    action = "lambda:InvokeFunction"
    source_arn = "arn:aws:config:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:config-rule/*"
}
resource "aws_cloudwatch_log_group" "fn_required_tags_log_group" {
    name = "/aws/lambda/${aws_lambda_function.fn_required_tags.function_name}"
    retention_in_days = 7
}

data "archive_file" "zip_required_tags_explorer" {
    type = "zip"
    source_dir = "../../src/required_tags_explorer"
    output_path = "../../tmp/required_tags_explorer.zip"
}
resource "aws_s3_object" "s3_required_tags_explorer" {
    bucket = var.bucket
    key = "config/required_tags_explorer.zip"
    source = data.archive_file.zip_required_tags_explorer.output_path
    etag = filemd5(data.archive_file.zip_required_tags_explorer.output_path)
}
resource "aws_lambda_function" "fn_required_tags_explorer" {
    function_name = "tf-fn-required-tags-explorer"
    s3_bucket = var.bucket
    s3_key = aws_s3_object.s3_required_tags_explorer.key
    runtime = "python3.11"
    handler = "fn.handler"
    memory_size = var.fn_memory
    timeout = var.fn_timeout
    source_code_hash = data.archive_file.zip_required_tags_explorer.output_base64sha256
    role = aws_iam_role.lambda_role.arn
    layers = [
        "arn:aws:lambda:us-east-1:580247275435:layer:LambdaInsightsExtension:38"
    ]
    tags = {
        "application:group" = "governance"
        "application:subgroup" = "config"
        "application:owner" = "aws"
    }
}
resource "aws_lambda_permission" "fn_required_tags_explorer_allow_config" {
    function_name = aws_lambda_function.fn_required_tags_explorer.function_name
    principal = "config.amazonaws.com"
    action = "lambda:InvokeFunction"
    source_arn = "arn:aws:config:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:config-rule/*"
}
resource "aws_cloudwatch_log_group" "fn_required_tags_explorer_log_group" {
    name = "/aws/lambda/${aws_lambda_function.fn_required_tags_explorer.function_name}"
    retention_in_days = 7
}

resource "aws_config_config_rule" "lambda_public_access_prohibited" {
    name = "tf-lambda-public-access-prohibited"
    scope {
        compliance_resource_types = [
            "AWS::Lambda::Function"
        ]
    }
    source {
        owner = "AWS"
        source_identifier = "LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED"
    }
}
resource "aws_config_config_rule" "lambda_inside_vpc" {
    name = "tf-lambda-inside-vpc"
    scope {
        compliance_resource_types = [
            "AWS::Lambda::Function"
        ]
    }
    source {
        owner = "AWS"
        source_identifier = "LAMBDA_INSIDE_VPC"
    }
}
resource "aws_config_config_rule" "lambda_deprecated_runtimes" {
    name = "tf-lambda-deprecated-runtimes"
    scope {
        compliance_resource_types = [
            "AWS::Lambda::Function"
        ]
    }
    source {
        owner = "CUSTOM_LAMBDA"
        source_identifier = aws_lambda_function.fn_deprecated_runtime.arn
        source_detail {
          message_type = "ScheduledNotification"
          maximum_execution_frequency = "One_Hour"
        }
    }
}
resource "aws_config_config_rule" "lambda_required_tags" {
    name = "tf-lambda-required-tags"
    scope {
        compliance_resource_types = [
            "AWS::Lambda::Function"
        ]
    }
    source {
        owner = "CUSTOM_LAMBDA"
        source_identifier = aws_lambda_function.fn_required_tags_explorer.arn
        source_detail {
          message_type = "ScheduledNotification"
          maximum_execution_frequency = "One_Hour"
        }
    }
}
resource "aws_config_config_rule" "lambda_required_tags_on_change" {
    name = "tf-lambda-required-tags-on-change"
    scope {
        compliance_resource_types = [
            "AWS::Lambda::Function"
        ]
    }
    source {
        owner = "CUSTOM_LAMBDA"
        source_identifier = aws_lambda_function.fn_required_tags_explorer.arn
        source_detail {
          message_type = "ConfigurationItemChangeNotification"
        }
    }
}

output "fn_deprecated_runtime" { value = aws_lambda_function.fn_deprecated_runtime.arn }
output "fn_required_tags" { value = aws_lambda_function.fn_required_tags.arn }
output "fn_required_tags_explorer" { value = aws_lambda_function.fn_required_tags_explorer.arn }
output "config_rule_lambda_public_access_prohibited" { value = aws_config_config_rule.lambda_public_access_prohibited.arn }
output "config_rule_lambda_inside_vpc" { value = aws_config_config_rule.lambda_inside_vpc.arn }
output "config_rule_lambda_deprecated_runtimes" { value = aws_config_config_rule.lambda_deprecated_runtimes.arn }
output "config_rule_lambda_required_tags" { value = aws_config_config_rule.lambda_required_tags.arn }
output "config_rule_lambda_required_tags_on_change" { value = aws_config_config_rule.lambda_required_tags_on_change.arn }
