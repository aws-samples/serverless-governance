import * as cdk from "aws-cdk-lib";
import { Construct } from "constructs";
import * as config from "aws-cdk-lib/aws-config";
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
    const configPolicy = new iam.Policy(this, "configPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "config:PutEvaluations"
          ],
          resources: ["*"]
        })
      ]
    });
    const configLambdaPolicy = new iam.Policy(this, "configLambdaPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "lambda:ListFunctions",
            "lambda:ListTags"
          ],
          resources: ["*"]
        })
      ]
    });
    const resourceExplorerPolicy = new iam.Policy(this, "resourceExplorerPolicy", {
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            "resource-explorer-2:Search"
          ],
          resources: [`arn:aws:resource-explorer-2:${cdk.Aws.REGION}:${cdk.Aws.ACCOUNT_ID}:view/*/*`]
        })
      ]
    });
    role.attachInlinePolicy(cloudwatchInsightsPolicy);
    role.attachInlinePolicy(cloudwatchLogsPolicy);
    role.attachInlinePolicy(xrayPolicy);
    role.attachInlinePolicy(configPolicy);
    role.attachInlinePolicy(configLambdaPolicy);
    role.attachInlinePolicy(resourceExplorerPolicy);

    const insightsLayer = lambda.LayerVersion.fromLayerVersionArn(this, "insightsLayer",
      "arn:aws:lambda:us-east-1:580247275435:layer:LambdaInsightsExtension:38"
    );
    const fnDeprecatedRuntime = new lambda.Function(this, "fnDeprecatedRuntime", {
      runtime: lambda.Runtime.PYTHON_3_11,
      memorySize: pFnMemory.valueAsNumber,
      timeout: cdk.Duration.seconds(pFnTimeout.valueAsNumber),
      code: lambda.Code.fromAsset("../../src/deprecated_runtime"),
      handler: "fn.handler",
      role: role,
      layers: [
        insightsLayer
      ],
      logRetention: logs.RetentionDays.ONE_WEEK
    });
    fnDeprecatedRuntime.addPermission("configPermission", {
      principal: new iam.ServicePrincipal("config.amazonaws.com"),
      action: "lambda:InvokeFunction",
      sourceArn: `arn:aws:config:${cdk.Aws.REGION}:${cdk.Aws.ACCOUNT_ID}:config-rule/*`
    });
    cdk.Tags.of(fnDeprecatedRuntime).add("application:group", "governance");
    cdk.Tags.of(fnDeprecatedRuntime).add("application:subgroup", "config");
    cdk.Tags.of(fnDeprecatedRuntime).add("application:owner", "aws");

    const fnRequiredTags = new lambda.Function(this, "fnRequiredTags", {
      runtime: lambda.Runtime.PYTHON_3_11,
      memorySize: pFnMemory.valueAsNumber,
      timeout: cdk.Duration.seconds(pFnTimeout.valueAsNumber),
      code: lambda.Code.fromAsset("../../src/required_tags"),
      handler: "fn.handler",
      role: role,
      layers: [
        insightsLayer
      ],
      logRetention: logs.RetentionDays.ONE_WEEK
    });
    fnRequiredTags.addPermission("configPermission", {
      principal: new iam.ServicePrincipal("config.amazonaws.com"),
      action: "lambda:InvokeFunction",
      sourceArn: `arn:aws:config:${cdk.Aws.REGION}:${cdk.Aws.ACCOUNT_ID}:config-rule/*`
    });
    cdk.Tags.of(fnRequiredTags).add("application:group", "governance");
    cdk.Tags.of(fnRequiredTags).add("application:subgroup", "config");
    cdk.Tags.of(fnRequiredTags).add("application:owner", "aws");

    const fnRequiredTagsExplorer = new lambda.Function(this, "fnRequiredTagsExplorer", {
      runtime: lambda.Runtime.PYTHON_3_11,
      memorySize: pFnMemory.valueAsNumber,
      timeout: cdk.Duration.seconds(pFnTimeout.valueAsNumber),
      code: lambda.Code.fromAsset("../../src/required_tags_explorer"),
      handler: "fn.handler",
      role: role,
      layers: [
        insightsLayer
      ],
      logRetention: logs.RetentionDays.ONE_WEEK
    });
    fnRequiredTagsExplorer.addPermission("configPermission", {
      principal: new iam.ServicePrincipal("config.amazonaws.com"),
      action: "lambda:InvokeFunction",
      sourceArn: `arn:aws:config:${cdk.Aws.REGION}:${cdk.Aws.ACCOUNT_ID}:config-rule/*`
    });
    cdk.Tags.of(fnRequiredTagsExplorer).add("application:group", "governance");
    cdk.Tags.of(fnRequiredTagsExplorer).add("application:subgroup", "config");
    cdk.Tags.of(fnRequiredTagsExplorer).add("application:owner", "aws");

    const ruleLambdaPublicAccessProhibited = new config.ManagedRule(this, "ruleLambdaPublicAccessProhibited", {
      identifier: config.ManagedRuleIdentifiers.LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED,
      ruleScope: config.RuleScope.fromResource(config.ResourceType.LAMBDA_FUNCTION)
    });
    const ruleLambdaInsideVpc = new config.ManagedRule(this, "ruleLambdaInsideVpc", {
      identifier: config.ManagedRuleIdentifiers.LAMBDA_INSIDE_VPC,
      ruleScope: config.RuleScope.fromResource(config.ResourceType.LAMBDA_FUNCTION)
    });
    const ruleLambdaDeprecatedRuntime = new config.CustomRule(this, "ruleLambdaDeprecatedRuntime", {
      configurationChanges: false,
      periodic: true,
      lambdaFunction: fnDeprecatedRuntime,
      ruleScope: config.RuleScope.fromResource(config.ResourceType.LAMBDA_FUNCTION)
    });
    const ruleLambdaRequiredTags = new config.CustomRule(this, "ruleLambdaRequiredTagsScheduled", {
      configurationChanges: true,
      periodic: true,
      lambdaFunction: fnRequiredTagsExplorer,
      ruleScope: config.RuleScope.fromResource(config.ResourceType.LAMBDA_FUNCTION),
      maximumExecutionFrequency: config.MaximumExecutionFrequency.ONE_HOUR
    });

    new cdk.CfnOutput(this, "outFnDeprecatedRuntime", { value: fnDeprecatedRuntime.functionName });
    new cdk.CfnOutput(this, "outFnRequiredTags", { value: fnRequiredTags.functionName });
    new cdk.CfnOutput(this, "outFnRequiredTagsExplorer", { value: fnRequiredTagsExplorer.functionName });
    new cdk.CfnOutput(this, "outRuleLambdaPublicAccessProhibitedArn", { value: ruleLambdaPublicAccessProhibited.configRuleArn });
    new cdk.CfnOutput(this, "outRuleLambdaDeprecatedRuntimeArn", { value: ruleLambdaInsideVpc.configRuleArn });
    new cdk.CfnOutput(this, "outRuleLambdaInsideVpc", { value: ruleLambdaDeprecatedRuntime.configRuleArn });
    new cdk.CfnOutput(this, "outRuleLambdaRequiredTags", { value: ruleLambdaRequiredTags.configRuleArn });
  };
}
