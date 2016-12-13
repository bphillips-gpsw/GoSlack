resource "aws_api_gateway_rest_api" "api" {
  name = "${var.application-name}"
  description = "API for ${var.application-name} lambda function"
  
  depends_on = ["aws_lambda_function.lambda"]
}

resource "aws_lambda_permission" "allow_api_gateway" {
    function_name = "${aws_lambda_function.lambda.arn}"
    statement_id = "AllowExecutionFromApiGateway"
    action = "lambda:InvokeFunction"
    principal = "apigateway.amazonaws.com"
    # This is *${aws_api_gateway_resource.action.path} because the path starts with a /
    source_arn = "arn:aws:execute-api:${var.aws-region}:${module.aws.account-id}:${aws_api_gateway_rest_api.api.id}/*/*${aws_api_gateway_resource.action.path}"
}

resource "aws_api_gateway_resource" "action" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part = "{action}"
}

resource "aws_api_gateway_method" "action-get-request" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.action.id}"
  http_method = "GET"
  authorization = "NONE"
  api_key_required = "true"
}

resource "aws_api_gateway_method" "action-post-request" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.action.id}"
  http_method = "POST"
  authorization = "NONE"
  api_key_required = "false"
}

variable "request-template" {
  default = <<EOF
#set($allParams = $input.params())
{
"body-json" : $input.json('$'),
"action": "$allParams.get('path').get('action')",
"params" : {
#foreach($type in $allParams.keySet())
    #set($params = $allParams.get($type))
"$type" : {
    #foreach($paramName in $params.keySet())
    "$paramName" : "$util.escapeJavaScript($params.get($paramName))"
        #if($foreach.hasNext),#end
    #end
}
    #if($foreach.hasNext),#end
#end
},
"stage-variables" : {
#foreach($key in $stageVariables.keySet())
"$key" : "$util.escapeJavaScript($stageVariables.get($key))"
    #if($foreach.hasNext),#end
#end
},
"context" : {
    "account-id" : "$context.identity.accountId",
    "api-id" : "$context.apiId",
    "api-key" : "$context.identity.apiKey",
    "authorizer-principal-id" : "$context.authorizer.principalId",
    "caller" : "$context.identity.caller",
    "cognito-authentication-provider" : "$context.identity.cognitoAuthenticationProvider",
    "cognito-authentication-type" : "$context.identity.cognitoAuthenticationType",
    "cognito-identity-id" : "$context.identity.cognitoIdentityId",
    "cognito-identity-pool-id" : "$context.identity.cognitoIdentityPoolId",
    "http-method" : "$context.httpMethod",
    "stage" : "$context.stage",
    "source-ip" : "$context.identity.sourceIp",
    "user" : "$context.identity.user",
    "user-agent" : "$context.identity.userAgent",
    "user-arn" : "$context.identity.userArn",
    "request-id" : "$context.requestId",
    "resource-id" : "$context.resourceId",
    "resource-path" : "$context.resourcePath"
    }
}
EOF
}

resource "aws_api_gateway_integration" "action-get-integration" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.action.id}"
  http_method = "${aws_api_gateway_method.action-get-request.http_method}"
  type = "AWS"
  uri = "arn:aws:apigateway:${var.aws-region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.aws-region}:${module.aws.account-id}:function:${aws_lambda_function.lambda.function_name}/invocations"
  integration_http_method = "POST"
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  request_templates = {
    "application/json" = "${var.request-template}" 
  }
}

resource "aws_api_gateway_integration" "action-post-integration" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.action.id}"
  http_method = "${aws_api_gateway_method.action-post-request.http_method}"
  type = "AWS"
  uri = "arn:aws:apigateway:${var.aws-region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.aws-region}:${module.aws.account-id}:function:${aws_lambda_function.lambda.function_name}/invocations"
  integration_http_method = "POST"
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  request_templates = {
    "application/json" = "${var.request-template}" 
  }
}

variable "response-codes" {
  default = [
    {
      code = 200
      response_template = "Empty"
      pattern = ""
      integration_template = ""
    },
    {
      code = 400
      response_template = "Error"
      pattern = ".*httpStatus\\\": 400.*"
      integration_template = <<EOF
#set ($errorMessageObj = $util.parseJson($input.path('$.errorMessage')))
{
  "httpStatus" : "$errorMessageObj.httpStatus",
  "message" : "$errorMessageObj.errorMessage"
}
EOF
    },
    {
      code = 404
      response_template = "Error"
      pattern = ".*httpStatus\\\": 404.*"
      integration_template = <<EOF
#set ($errorMessageObj = $util.parseJson($input.path('$.errorMessage')))
{
  "httpStatus" : "$errorMessageObj.httpStatus",
  "message" : "$errorMessageObj.errorMessage"
}
EOF
    },
    {
      code = 405
      response_template = "Error"
      pattern = ".*httpStatus\\\": 405.*"
      integration_template = <<EOF
#set ($errorMessageObj = $util.parseJson($input.path('$.errorMessage')))
{
  "httpStatus" : "$errorMessageObj.httpStatus",
  "message" : "$errorMessageObj.errorMessage"
}
EOF
    },
    {
      code = 500
      response_template = "Error"
      pattern = ".*httpStatus\\\": 500.*"
      integration_template = <<EOF
#set ($errorMessageObj = $util.parseJson($input.path('$.errorMessage')))
{
  "httpStatus" : "$errorMessageObj.httpStatus",
  "message" : "$errorMessageObj.errorMessage"
}
EOF
    }
  ]
}

resource "aws_api_gateway_method_response" "get-method-response" {
  count = 5
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.action.id}"
  http_method = "${aws_api_gateway_method.action-get-request.http_method}"
  status_code = "${lookup(var.response-codes[count.index], "code")}"
  response_models = {
    "application/json" = "${lookup(var.response-codes[count.index], "response_template")}"
  }

}

resource "aws_api_gateway_integration_response" "action-get-integration-response" {
  count = 5
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.action.id}"
  http_method = "${aws_api_gateway_method.action-get-request.http_method}"
  status_code = "${lookup(var.response-codes[count.index], "code")}"
  selection_pattern = "${lookup(var.response-codes[count.index], "pattern")}"
  response_templates = {
    "application/json" = "${lookup(var.response-codes[count.index], "integration_template")}"
  }

  depends_on = ["aws_api_gateway_method_response.get-method-response"]
}

resource "aws_api_gateway_method_response" "post-method-response" {
  count = 5
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.action.id}"
  http_method = "${aws_api_gateway_method.action-post-request.http_method}"
  status_code = "${lookup(var.response-codes[count.index], "code")}"
  response_models = {
    "application/json" = "${lookup(var.response-codes[count.index], "response_template")}"
  }

}

resource "aws_api_gateway_integration_response" "action-post-integration-response" {
  count = 5
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.action.id}"
  http_method = "${aws_api_gateway_method.action-post-request.http_method}"
  status_code = "${lookup(var.response-codes[count.index], "code")}"
  selection_pattern = "${lookup(var.response-codes[count.index], "pattern")}"
  response_templates = {
    "application/json" = "${lookup(var.response-codes[count.index], "integration_template")}"
  }

  depends_on = ["aws_api_gateway_method_response.post-method-response"]
}

variable "deployment-environments" {
  default = ["qa", "staging", "prod"]
}

resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "goslacka"
  domain_name = "api.gopro-platform.com"
  base_path   = "goslacka"
}
