provider "aws" {
    profile = var.profile
    region = var.region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_signer_signing_profile" "signer" {
    platform_id = "AWSLambda-SHA384-ECDSA"
    signature_validity_period {
      value = var.valid_days
      type = "DAYS"
    }
}
resource "aws_lambda_code_signing_config" "signing_config" {
    allowed_publishers {
      signing_profile_version_arns = [
        aws_signer_signing_profile.signer.arn
      ]
    }
}

output "signer_id" { value = aws_signer_signing_profile.signer.name }
output "signer_arn" { value = aws_signer_signing_profile.signer.arn }
output "signing_config_arn" { value = aws_lambda_code_signing_config.signing_config.arn }
