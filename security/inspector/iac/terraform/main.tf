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

resource "aws_iam_role_policy_attachment" "lambda_attach_cloudwatch" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.lambda_policy_cloudwatch.arn
}
resource "aws_iam_role_policy_attachment" "lambda_attach_xray" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.lambda_policy_cloudwatch.arn
}

data "archive_file" "zip_fn1_vulnerable" {
    type = "zip"
    source_dir = "../../src/python-1-vulnerable"
    output_path = "../tmp/fn1_vulnerable.zip"
}
resource "aws_s3_object" "s3_fn1_vulnerable" {
    bucket = var.bucket
    key = "inspector/fn1_vulnerable.zip"
    source = data.archive_file.zip_fn1_vulnerable.output_path
    etag = filemd5(data.archive_file.zip_fn1_vulnerable.output_path)
}
resource "aws_lambda_function" "fn1_vulnerable" {
    function_name = "tf-fn1-vulnerable"
    s3_bucket = var.bucket
    s3_key = aws_s3_object.s3_fn1_vulnerable.key
    runtime = "python3.11"
    handler = "fn.handler"
    memory_size = var.fn_memory
    timeout = var.fn_timeout
    source_code_hash = data.archive_file.zip_fn1_vulnerable.output_base64sha256
    role = aws_iam_role.lambda_role.arn
    layers = [
        "arn:aws:lambda:us-east-1:580247275435:layer:LambdaInsightsExtension:38"
    ]
    tags = {
        "application:group" = "governance"
        "application:subgroup" = "inspector"
        "application:owner" = "aws"
    }
}
resource "aws_cloudwatch_log_group" "fn1_vulnerable_log_group" {
    name = "/aws/lambda/${aws_lambda_function.fn1_vulnerable.function_name}"
    retention_in_days = 7
}

data "archive_file" "zip_fn1_patched" {
    type = "zip"
    source_dir = "../../src/python-1-patched"
    output_path = "../tmp/fn1_patched.zip"
}
resource "aws_s3_object" "s3_fn1_patched" {
    bucket = var.bucket
    key = "inspector/fn1_patched.zip"
    source = data.archive_file.zip_fn1_patched.output_path
    etag = filemd5(data.archive_file.zip_fn1_patched.output_path)
}
resource "aws_lambda_function" "fn1_patched" {
    function_name = "tf-fn1-patched"
    s3_bucket = var.bucket
    s3_key = aws_s3_object.s3_fn1_patched.key
    runtime = "python3.11"
    handler = "fn.handler"
    memory_size = var.fn_memory
    timeout = var.fn_timeout
    source_code_hash = data.archive_file.zip_fn1_patched.output_base64sha256
    role = aws_iam_role.lambda_role.arn
    layers = [
        "arn:aws:lambda:us-east-1:580247275435:layer:LambdaInsightsExtension:38"
    ]
    tags = {
        "application:group" = "governance"
        "application:subgroup" = "inspector"
        "application:owner" = "aws"
    }
}
resource "aws_cloudwatch_log_group" "fn1_patched_log_group" {
    name = "/aws/lambda/${aws_lambda_function.fn1_patched.function_name}"
    retention_in_days = 7
}

data "archive_file" "zip_fn2_vulnerable" {
    type = "zip"
    source_dir = "../../src/python-2-vulnerable"
    output_path = "../tmp/fn2_vulnerable.zip"
}
resource "aws_s3_object" "s3_fn2_vulnerable" {
    bucket = var.bucket
    key = "inspector/fn2_vulnerable.zip"
    source = data.archive_file.zip_fn2_vulnerable.output_path
    etag = filemd5(data.archive_file.zip_fn2_vulnerable.output_path)
}
resource "aws_lambda_function" "fn2_vulnerable" {
    function_name = "tf-fn2-vulnerable"
    s3_bucket = var.bucket
    s3_key = aws_s3_object.s3_fn2_vulnerable.key
    runtime = "python3.11"
    handler = "fn.handler"
    memory_size = var.fn_memory
    timeout = var.fn_timeout
    source_code_hash = data.archive_file.zip_fn2_vulnerable.output_base64sha256
    role = aws_iam_role.lambda_role.arn
    layers = [
        "arn:aws:lambda:us-east-1:580247275435:layer:LambdaInsightsExtension:38"
    ]
    tags = {
        "application:group" = "governance"
        "application:subgroup" = "inspector"
        "application:owner" = "aws"
    }
}
resource "aws_cloudwatch_log_group" "fn2_vulnerable_log_group" {
    name = "/aws/lambda/${aws_lambda_function.fn2_vulnerable.function_name}"
    retention_in_days = 7
}

data "archive_file" "zip_fn2_patched" {
    type = "zip"
    source_dir = "../../src/python-2-patched"
    output_path = "../tmp/fn2_patched.zip"
}
resource "aws_s3_object" "s3_fn2_patched" {
    bucket = var.bucket
    key = "inspector/fn2_patched.zip"
    source = data.archive_file.zip_fn2_patched.output_path
    etag = filemd5(data.archive_file.zip_fn2_patched.output_path)
}
resource "aws_lambda_function" "fn2_patched" {
    function_name = "tf-fn2-patched"
    s3_bucket = var.bucket
    s3_key = aws_s3_object.s3_fn2_patched.key
    runtime = "python3.11"
    handler = "fn.handler"
    memory_size = var.fn_memory
    timeout = var.fn_timeout
    source_code_hash = data.archive_file.zip_fn2_patched.output_base64sha256
    role = aws_iam_role.lambda_role.arn
    layers = [
        "arn:aws:lambda:us-east-1:580247275435:layer:LambdaInsightsExtension:38"
    ]
    tags = {
        "application:group" = "governance"
        "application:subgroup" = "inspector"
        "application:owner" = "aws"
    }
}
resource "aws_cloudwatch_log_group" "fn2_patched_log_group" {
    name = "/aws/lambda/${aws_lambda_function.fn2_patched.function_name}"
    retention_in_days = 7
}

output "fn1_vulnerable" { value = aws_lambda_function.fn1_vulnerable.arn }
output "fn1_patched" { value = aws_lambda_function.fn1_patched.arn }
output "fn2_vulnerable" { value = aws_lambda_function.fn2_vulnerable.arn }
output "fn2_patched" { value = aws_lambda_function.fn2_patched.arn }
