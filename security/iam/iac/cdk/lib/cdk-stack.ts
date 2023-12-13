import * as cdk from "aws-cdk-lib";
import { Construct } from "constructs";
import * as iam from "aws-cdk-lib/aws-iam";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as logs from "aws-cdk-lib/aws-logs";

export class CdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const pBucket = new cdk.CfnParameter(this, "pBucket", {
      type: "String"
    })

    const cfnRole = new iam.Role(this, "cfnRole", {
      assumedBy: new iam.ServicePrincipal("cloudformation.amazonaws.com")
    });
    const cloudformationReadPolicy = new iam.Policy(this, "cloudformationReadPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "cloudformation:DescribeStacks",
            "cloudformation:ListChangeSets",
            "cloudformation:ListExports",
            "cloudformation:ListImports",
            "cloudformation:ListStacks"
          ],
          resources: ["*"]
        })
      ]
    });
    const cloudformationWritePolicy = new iam.Policy(this, "cloudformationWritePolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "cloudformation:CreateStack",
            "cloudformation:CreateChangeSet",
            "cloudformation:DeleteStack",
            "cloudformation:TagResource",
            "cloudformation:UpdateStack",
            "cloudformation:ValidateTemplate"
          ],
          resources: ["*"]
        })
      ]
    });
    const iamReadPolicy = new iam.Policy(this, "iamReadPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "iam:GetRole",
            "iam:GetRolePolicy",
            "iam:ListRoles"
          ],
          resources: ["*"]
        })
      ]
    });
    const iamWritePolicy = new iam.Policy(this, "iamWritePolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "iam:CreateRole",
            "iam:DeleteRole",
            "iam:DeleteRolePolicy",
            "iam:PassRole",
            "iam:PutRolePolicy",
            "iam:TagRole",
            "iam:UntagRole"
          ],
          resources: ["*"]
        })
      ]
    });
    const s3ReadPolicy = new iam.Policy(this, "s3ReadPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "s3:Get*"
          ],
          resources: [
            `arn:aws:s3:::${pBucket.valueAsString}/*`,
            `arn:aws:s3:::${pBucket.valueAsString}-versioned/*`
          ]
        })
      ]
    });
    const cloudwatchInsightsPolicy = new iam.Policy(this, "cloudwatchInsightsPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "logs:CreateLogGroup"
          ],
          resources: ["*"]
        })
      ]
    });
    const cloudwatchLogsPolicy = new iam.Policy(this, "cloudwatchLogsPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
          ],
          resources: ["arn:aws:logs:*:*:log-group:*:*"]
        })
      ]
    });
    const signerPolicy = new iam.Policy(this, "signerPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "signer:GetSigningProfile",
            "signer:PutSigningProfile"
          ],
          resources: ["*"]
        })
      ]
    });
    const lambdaReadPolicy = new iam.Policy(this, "lambdaReadPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "lambda:GetAccountSettings",
            "lambda:GetEventSourceMapping",
            "lambda:GetFunction",
            "lambda:GetFunctionConfiguration",
            "lambda:GetFunctionCodeSigningConfig",
            "lambda:GetFunctionConcurrency",
            "lambda:ListEventSourceMappings",
            "lambda:ListFunctions",
            "lambda:ListTags"
          ],
          resources: ["*"]
        })
      ]
    });
    const lambdaWritePolicy = new iam.Policy(this, "lambdaWritePolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "lambda:DeleteFunction",
            "lambda:TagResource"
          ],
          resources: ["*"]
        })
      ]
    });
    const lambdaSigningPolicy = new iam.Policy(this, "lambdaSigningPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "lambda:CreateCodeSigningConfig",
            "lambda:DeleteCodeSigningConfig",
            "lambda:GetCodeSigningConfig",
            "lambda:UpdateCodeSigningConfig"
          ],
          resources: ["*"]
        })
      ]
    });
    const lambdaDevelopFunctionPolicy = new iam.Policy(this, "lambdaDevelopFunctionPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "lambda:CreateFunction",
            "lambda:UpdateFunctionCode",
            "lambda:UpdateFunctionConfiguration"
          ],
          resources: ["*"],
          conditions: {
            "ForAllValues:StringLike": {
              "lambda:Layer": [
                `arn:aws:lambda:${cdk.Aws.REGION}:${cdk.Aws.ACCOUNT_ID}:layer:*:*`,
                `arn:aws:lambda:${cdk.Aws.REGION}:580247275435:layer:LambdaInsightsExtension:*`
              ]
            }
          }
        })
      ]
    });
    const lambdaDevelopLayerPolicy = new iam.Policy(this, "lambdaDevelopLayerPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "lambda:DeleteLayerVersion",
            "lambda:GetLayerVersion",
            "lambda:GetLayerVersionPolicy",
            "lambda:PublishLayerVersion",
            "lambda:AddLayerVersionPermission",
            "lambda:RemoveLayerVersionPermission"
          ],
          resources: ["*"]
        })
      ]
    });
    const lambdaDevelopMappingPolicy = new iam.Policy(this, "lambdaDevelopMappingPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "lambda:CreateEventSourceMapping",
            "lambda:DeleteEventSourceMapping",
            "lambda:UpdateEventSourceMapping"
          ],
          resources: ["*"],
          conditions: {
            "StringLike": {
              "lambda:FunctionArn": `arn:aws:lambda:${cdk.Aws.REGION}:${cdk.Aws.ACCOUNT_ID}:function:*`
            }
          }
        })
      ]
    });
    cfnRole.attachInlinePolicy(cloudformationReadPolicy);
    cfnRole.attachInlinePolicy(cloudformationWritePolicy);
    cfnRole.attachInlinePolicy(iamReadPolicy);
    cfnRole.attachInlinePolicy(iamWritePolicy);
    cfnRole.attachInlinePolicy(s3ReadPolicy);
    cfnRole.attachInlinePolicy(cloudwatchInsightsPolicy);
    cfnRole.attachInlinePolicy(cloudwatchLogsPolicy);
    cfnRole.attachInlinePolicy(signerPolicy);
    cfnRole.attachInlinePolicy(lambdaReadPolicy);
    cfnRole.attachInlinePolicy(lambdaWritePolicy);
    cfnRole.attachInlinePolicy(lambdaSigningPolicy);
    cfnRole.attachInlinePolicy(lambdaDevelopFunctionPolicy);
    cfnRole.attachInlinePolicy(lambdaDevelopLayerPolicy);
    cfnRole.attachInlinePolicy(lambdaDevelopMappingPolicy);

    new cdk.CfnOutput(this, "outCfnRole", { value: cfnRole.roleArn });
  };
}
