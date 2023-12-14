import * as cdk from "aws-cdk-lib";
import { Construct } from "constructs";
import * as iam from "aws-cdk-lib/aws-iam";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as logs from "aws-cdk-lib/aws-logs";

export class CdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const pFnMemory = new cdk.CfnParameter(this, "pFnMemory", {
      type: "Number"
    });
    const pFnTimeout = new cdk.CfnParameter(this, "pFnTimeout", {
      type: "Number"
    });

    const role = new iam.Role(this, "fnRole", {
      assumedBy: new iam.ServicePrincipal("lambda.amazonaws.com")
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
    const xrayPolicy = new iam.Policy(this, "xrayPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "xray:PutTraceSegments",
            "xray:PutTelemetryRecords",
            "xray:GetSamplingRules",
            "xray:GetSamplingTargets",
            "xray:GetSamplingStatisticSummaries"
          ],
          resources: ["*"]
        })
      ]
    });
    role.attachInlinePolicy(cloudwatchInsightsPolicy);
    role.attachInlinePolicy(cloudwatchLogsPolicy);
    role.attachInlinePolicy(xrayPolicy);

    const insightsLayer = lambda.LayerVersion.fromLayerVersionArn(this, "insightsLayer",
      "arn:aws:lambda:us-east-1:580247275435:layer:LambdaInsightsExtension:38"
    );
    const fn1Vulnerable = new lambda.Function(this, "fn1Vulnerable", {
      runtime: lambda.Runtime.PYTHON_3_11,
      memorySize: pFnMemory.valueAsNumber,
      timeout: cdk.Duration.seconds(pFnTimeout.valueAsNumber),
      code: lambda.Code.fromAsset("../../src/python-1-vulnerable"),
      handler: "fn.handler",
      role: role,
      layers: [
        insightsLayer
      ],
      logRetention: logs.RetentionDays.ONE_WEEK
    });
    cdk.Tags.of(fn1Vulnerable).add("application:group", "governance");
    cdk.Tags.of(fn1Vulnerable).add("application:subgroup", "inspector");
    cdk.Tags.of(fn1Vulnerable).add("application:owner", "aws");
    const fn1Patched = new lambda.Function(this, "fn1Patched", {
      runtime: lambda.Runtime.PYTHON_3_11,
      memorySize: pFnMemory.valueAsNumber,
      timeout: cdk.Duration.seconds(pFnTimeout.valueAsNumber),
      code: lambda.Code.fromAsset("../../src/python-1-patched"),
      handler: "fn.handler",
      role: role,
      layers: [
        insightsLayer
      ],
      logRetention: logs.RetentionDays.ONE_WEEK
    });
    cdk.Tags.of(fn1Patched).add("application:group", "governance");
    cdk.Tags.of(fn1Patched).add("application:subgroup", "inspector");
    cdk.Tags.of(fn1Patched).add("application:owner", "aws");
    const fn2Vulnerable = new lambda.Function(this, "fn2Vulnerable", {
      runtime: lambda.Runtime.PYTHON_3_11,
      memorySize: pFnMemory.valueAsNumber,
      timeout: cdk.Duration.seconds(pFnTimeout.valueAsNumber),
      code: lambda.Code.fromAsset("../../src/python-2-vulnerable"),
      handler: "fn.handler",
      role: role,
      layers: [
        insightsLayer
      ],
      logRetention: logs.RetentionDays.ONE_WEEK
    });
    cdk.Tags.of(fn2Vulnerable).add("application:group", "governance");
    cdk.Tags.of(fn2Vulnerable).add("application:subgroup", "inspector");
    cdk.Tags.of(fn2Vulnerable).add("application:owner", "aws");
    const fn2Patched = new lambda.Function(this, "fn2Patched", {
      runtime: lambda.Runtime.PYTHON_3_11,
      memorySize: pFnMemory.valueAsNumber,
      timeout: cdk.Duration.seconds(pFnTimeout.valueAsNumber),
      code: lambda.Code.fromAsset("../../src/python-2-patched"),
      handler: "fn.handler",
      role: role,
      layers: [
        insightsLayer
      ],
      logRetention: logs.RetentionDays.ONE_WEEK
    });
    cdk.Tags.of(fn2Patched).add("application:group", "governance");
    cdk.Tags.of(fn2Patched).add("application:subgroup", "inspector");
    cdk.Tags.of(fn2Patched).add("application:owner", "aws");

    new cdk.CfnOutput(this, "outFn1Vulnerable", { value: fn1Vulnerable.functionName });
    new cdk.CfnOutput(this, "outFn1Patched", { value: fn1Patched.functionName });
    new cdk.CfnOutput(this, "outFn2Vulnerable", { value: fn2Vulnerable.functionName });
    new cdk.CfnOutput(this, "outFn2Patched", { value: fn2Patched.functionName });
  };
}
