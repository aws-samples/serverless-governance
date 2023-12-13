provider "aws" {
    profile = var.profile
    region = var.region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "cfn_role" {
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Service = "cloudformation.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_policy" "policy_cloudformation" {
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "cloudformation:DescribeStacks",
                    "cloudformation:ListChangeSets",
                    "cloudformation:ListExports",
                    "cloudformation:ListImports",
                    "cloudformation:ListStacks"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow",
                Action = [
                    "cloudformation:CreateStack",
                    "cloudformation:CreateChangeSet",
                    "cloudformation:DeleteStack",
                    "cloudformation:TagResource",
                    "cloudformation:UpdateStack",
                    "cloudformation:ValidateTemplate"
                ]
                Resource = "*"
            }
        ]
    })
}
resource "aws_iam_policy" "policy_iam" {
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "iam:GetRole",
                    "iam:GetRolePolicy",
                    "iam:ListRoles"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow",
                Action = [
                    "iam:CreateRole",
                    "iam:DeleteRole",
                    "iam:DeleteRolePolicy",
                    "iam:PassRole",
                    "iam:PutRolePolicy",
                    "iam:TagRole",
                    "iam:UntagRole"
                ]
                Resource = "*"
            }
        ]
    })
}
resource "aws_iam_policy" "policy_s3" {
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "s3:Get*"
                ]
                Resource = [
                    "arn:aws:s3:::${var.bucket}/*",
                    "arn:aws:s3:::${var.bucket}-versioned/*"
                ]
            }
        ]
    })
}
resource "aws_iam_policy" "policy_cloudwatch" {
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
resource "aws_iam_policy" "policy_signer" {
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "signer:GetSigningProfile",
                    "signer:PutSigningProfile"
                ]
                Resource = "*"
            }
        ]
    })
}
resource "aws_iam_policy" "policy_lambda" {
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "lambda:GetAccountSettings",
                    "lambda:GetEventSourceMapping",
                    "lambda:GetFunction",
                    "lambda:GetFunctionConfiguration",
                    "lambda:GetFunctionCodeSigningConfig",
                    "lambda:GetFunctionConcurrency",
                    "lambda:ListEventSourceMappings",
                    "lambda:ListFunctions",
                    "lambda:ListTags"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow",
                Action = [
                    "lambda:DeleteFunction",
                    "lambda:TagResource"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow",
                Action = [
                    "lambda:CreateCodeSigningConfig",
                    "lambda:DeleteCodeSigningConfig",
                    "lambda:GetCodeSigningConfig",
                    "lambda:UpdateCodeSigningConfig"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow",
                Action = [
                    "lambda:CreateFunction",
                    "lambda:UpdateFunctionCode",
                    "lambda:UpdateFunctionConfiguration"
                ]
                Resource = "*",
                Condition = {
                    "ForAllValues:StringLike" = {
                        "lambda:Layer" = [
                            "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:layer:*:*",
                            "arn:aws:lambda:${data.aws_region.current.name}:580247275435:layer:LambdaInsightsExtension:*"
                        ]
                    }
                }
            },
            {
                Effect = "Allow",
                Action = [
                    "lambda:DeleteLayerVersion",
                    "lambda:GetLayerVersion",
                    "lambda:GetLayerVersionPolicy",
                    "lambda:PublishLayerVersion",
                    "lambda:AddLayerVersionPermission",
                    "lambda:RemoveLayerVersionPermission"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow",
                Action = [
                    "lambda:CreateEventSourceMapping",
                    "lambda:DeleteEventSourceMapping",
                    "lambda:UpdateEventSourceMapping"
                ]
                Resource = "*",
                Condition = {
                    "StringLike" = {
                        "lambda:FunctionArn" = [
                            "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"
                        ]
                    }
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "attach_cloudformation" {
    role = aws_iam_role.cfn_role.name
    policy_arn = aws_iam_policy.policy_cloudformation.arn
}
resource "aws_iam_role_policy_attachment" "attach_iam" {
    role = aws_iam_role.cfn_role.name
    policy_arn = aws_iam_policy.policy_iam.arn
}
resource "aws_iam_role_policy_attachment" "attach_s3" {
    role = aws_iam_role.cfn_role.name
    policy_arn = aws_iam_policy.policy_s3.arn
}
resource "aws_iam_role_policy_attachment" "attach_cloudwatch" {
    role = aws_iam_role.cfn_role.name
    policy_arn = aws_iam_policy.policy_cloudwatch.arn
}
resource "aws_iam_role_policy_attachment" "attach_signer" {
    role = aws_iam_role.cfn_role.name
    policy_arn = aws_iam_policy.policy_signer.arn
}
resource "aws_iam_role_policy_attachment" "attach_lambda" {
    role = aws_iam_role.cfn_role.name
    policy_arn = aws_iam_policy.policy_lambda.arn
}

output "cfn_role" { value = aws_iam_role.cfn_role.arn }
