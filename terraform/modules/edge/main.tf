locals {
  name_prefix = "${var.project_name}-${var.environment}"
  alb_name    = "${substr(local.name_prefix, 0, 27)}-alb"
}

resource "aws_lb" "internal" {
  name               = local.alb_name
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = [var.private_app_subnet_a, var.private_app_subnet_b]
}

resource "aws_lb_target_group" "order" {
  name        = "${substr(local.name_prefix, 0, 16)}-order-tg"
  port        = 8903
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path = "/actuator/health"
  }
}

resource "aws_lb_target_group" "product" {
  name        = "${substr(local.name_prefix, 0, 14)}-product-tg"
  port        = 8901
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path = "/actuator/health"
  }
}

resource "aws_lb_target_group" "stock" {
  name        = "${substr(local.name_prefix, 0, 16)}-stock-tg"
  port        = 8900
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path = "/actuator/health"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"message\":\"No matching route\"}"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "order" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order.arn
  }

  condition {
    path_pattern {
      values = ["/order", "/order/*"]
    }
  }
}

resource "aws_lb_listener_rule" "product" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.product.arn
  }

  condition {
    path_pattern {
      values = ["/product", "/product/*"]
    }
  }
}

resource "aws_lb_listener_rule" "stock" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.stock.arn
  }

  condition {
    path_pattern {
      values = ["/stock", "/stock/*"]
    }
  }
}

resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "${local.name_prefix}-http-vpc-link"
  security_group_ids = [var.vpc_link_security_group_id]
  subnet_ids         = [var.private_app_subnet_a, var.private_app_subnet_b]
}

resource "aws_apigatewayv2_api" "http" {
  name          = "${local.name_prefix}-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "alb" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.this.id
  integration_uri        = aws_lb_listener.http.arn
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "order" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY /order/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_route" "order_root" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY /order"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_route" "product" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY /product/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_route" "product_root" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY /product"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_route" "stock" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY /stock/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_route" "stock_root" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY /stock"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_wafv2_web_acl" "http_api" {
  count = var.enable_waf ? 1 : 0

  name  = "${local.name_prefix}-api-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common-rules"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "http_api" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_lb.internal.arn
  web_acl_arn  = aws_wafv2_web_acl.http_api[0].arn
}
