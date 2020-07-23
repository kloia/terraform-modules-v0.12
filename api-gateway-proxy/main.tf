resource "aws_api_gateway_rest_api" "api" {
 name = "api-gateway-${var.environment}"
 description = "Proxy to handle requests to our API"
}

resource "aws_api_gateway_vpc_link" "link" {
  name        = "link-${var.region}"
  description = "link"
  target_arns = [var.alb_arn]
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
  request_parameters = {
    "method.request.path.proxy" = true
    "method.request.header.user" = false
  }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.domain_name}/{proxy}"
 
  request_parameters =  {
    "integration.request.path.proxy"           = "method.request.path.proxy",
    "integration.request.header.user"          = "context.authorizer.user"
    "integration.request.header.from-external" = "'true'"
  }

  connection_type = "VPC_LINK"
  connection_id = aws_api_gateway_vpc_link.link.id
}

## authorizer
resource "aws_api_gateway_authorizer" "authorizer" {
  name                   = "authorizer-${var.environment}"
  rest_api_id            = aws_api_gateway_rest_api.api.id
  authorizer_uri         = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.invocation_role.arn
}

resource "aws_iam_role" "invocation_role" {
  name = "api_gateway_auth_invocation"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "invocation_policy" {
  name = "lambda-invoke-policy-${var.environment}"
  role = aws_iam_role.invocation_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.authorizer.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda" {
  name = "authorizer-lambda-role-${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${aws_lambda_function.authorizer.function_name}"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "vpc_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "sg_for_lambda" {
  name        = "lambda_security_group"
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "Lambda VPC Security Group"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_lambda_function" "authorizer" {
  function_name = "api_gateway_authorizer_${var.environment}"
  role          = aws_iam_role.lambda.arn
  handler       = var.authorizer_lambda_handler
  
  runtime       = var.authorizer_lamba_runtime

  s3_bucket     = var.lambda_source_code_bucket
  s3_key        = var.lambda_source_code_key

  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  vpc_config    {
    subnet_ids = var.subnet_ids
    security_group_ids = [aws_security_group.sg_for_lambda.id]
  }

  environment {
    variables = var.lambda_environment_variables
  }
}

## deployment

resource "aws_api_gateway_deployment" "prod" {
  stage_name  = "prod"
  rest_api_id = aws_api_gateway_rest_api.api.id
  description = "Deployed at ${timestamp()}"
  stage_description = "Deployed at ${timestamp()}"

  triggers = {
    redeployment = sha1(join(",", list(
      jsonencode(aws_api_gateway_integration.integration),
    )))
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_api_gateway_domain_name" "domain" {
  domain_name              = var.domain_name
  regional_certificate_arn = var.regional_certificate_arn

  endpoint_configuration {
    types = var.endpoint_configuration_types
  }
}

resource "aws_route53_record" "record" {
  name            = aws_api_gateway_domain_name.domain.domain_name
  type            = "A"
  zone_id         = var.route53_zone_id
  allow_overwrite = true

  alias {
    evaluate_target_health = false
    name                   = aws_api_gateway_domain_name.domain.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.domain.regional_zone_id
  }
}

resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.prod.id
}

resource "aws_api_gateway_base_path_mapping" "base_path_mapping" {
  api_id      = aws_api_gateway_rest_api.api.id
  domain_name = aws_api_gateway_domain_name.domain.domain_name
  stage_name  = aws_api_gateway_stage.prod.stage_name
}