resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.function_name}_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy_document" "lambda_policy_document" {
  statement {
    actions = [
      "dynamodb:UpdateItem",
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
    ]
    resources = [
      var.dynamodb_table_arn
    ] 
  }
}

resource "aws_iam_policy" "dynamodb_lambda_policy" {
  name        = "dynamodb-lambda-policy"
  description = "This policy will be used by the lambda to write get data from DynamoDB"
  policy      = data.aws_iam_policy_document.lambda_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_attachment" {
    role       = aws_iam_role.lambda_exec_role.name
    policy_arn = aws_iam_policy.dynamodb_lambda_policy.arn
 }
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "visitor_counter" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  handler          = "app.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }
}

data "aws_acm_certificate" "cert" {
  domain = "joshvvcv.com"
  statuses = ["ISSUED"]
  most_recent = true
}  

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.function_name}-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["https://joshvvcv.com"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.visitor_counter.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_domain_name" "custom_d" {
  domain_name = "api.joshvvcv.com"
  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }  
}

resource "aws_apigatewayv2_api_mapping" "custom_m" {
  domain_name = aws_apigatewayv2_domain_name.custom_d.id
  api_id     = aws_apigatewayv2_api.http_api.id
  stage        = aws_apigatewayv2_stage.visit_stage.id
  depends_on = [ aws_apigatewayv2_stage.visit_stage, ]
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /visit"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "options" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "OPTIONS /visit"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "get" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /visit"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_deployment" "count_api_deployment" {
  api_id = aws_apigatewayv2_api.http_api.id
  depends_on = [ aws_apigatewayv2_integration.lambda_integration,]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  deployment_id = aws_apigatewayv2_deployment.count_api_deployment.id
  auto_deploy = false
}

resource "aws_cloudwatch_log_group" "http_api_logs" {
  name              = "/aws/apigateway/http-api"
  retention_in_days = 14
}

resource "aws_apigatewayv2_stage" "visit_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  deployment_id = aws_apigatewayv2_deployment.count_api_deployment.id
  name        = "prod"
  auto_deploy = false

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.http_api_logs.arn
    format          = jsonencode({
      requestId       = "$context.requestId",
      sourceIp        = "$context.identity.sourceIp",
      httpMethod      = "$context.httpMethod",
      routeKey        = "$context.routeKey",
      status          = "$context.status",
      protocol        = "$context.protocol"
    })
  }

  default_route_settings {
    logging_level          = "INFO"
    data_trace_enabled     = true
    detailed_metrics_enabled = true
    throttling_rate_limit  = 1000
    throttling_burst_limit = 500
  }
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*/visit"
}

