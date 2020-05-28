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
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
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
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  connection_type = "VPC_LINK"
  connection_id = aws_api_gateway_vpc_link.link.id
}


resource "aws_api_gateway_deployment" "prod" {
  stage_name  = "prod"
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(join(",", list(
      jsonencode(aws_api_gateway_integration.integration),
    )))
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

resource "aws_api_gateway_base_path_mapping" "base_path_mapping" {
  api_id      = aws_api_gateway_rest_api.api.id
  domain_name = aws_api_gateway_domain_name.domain.domain_name
  stage_name  = "prod"
}