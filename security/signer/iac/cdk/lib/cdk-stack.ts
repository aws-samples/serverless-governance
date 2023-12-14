import * as cdk from "aws-cdk-lib";
import { Construct } from "constructs";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as signer from "aws-cdk-lib/aws-signer";

export class CdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const signingProfile = new signer.SigningProfile(this, "signingProfile", {
      platform: signer.Platform.AWS_LAMBDA_SHA384_ECDSA
    });
    const signingConfig = new lambda.CodeSigningConfig(this, "signingConfig", {
      signingProfiles: [signingProfile]
    });

    new cdk.CfnOutput(this, "outSignerId", { value: signingProfile.signingProfileName });
    new cdk.CfnOutput(this, "outSignerArn", { value: signingProfile.signingProfileArn });
    new cdk.CfnOutput(this, "outSigningConfigArn", { value: signingConfig.codeSigningConfigArn });
  };
}
