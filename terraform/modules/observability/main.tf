locals {
  name_prefix    = "${var.project_name}-${var.environment}"
  metrics_prefix = "${var.project_name}/${var.environment}"
  has_alarm_mail = trimspace(var.alarm_email) != ""
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/ecs/${var.project_name}/${var.environment}/api-gateway"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "product" {
  name              = "/ecs/${var.project_name}/${var.environment}/product-service"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "stock" {
  name              = "/ecs/${var.project_name}/${var.environment}/stock-service"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "order" {
  name              = "/ecs/${var.project_name}/${var.environment}/order-service"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_metric_filter" "order_error" {
  name           = "${local.name_prefix}-order-error-filter"
  log_group_name = aws_cloudwatch_log_group.order.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "order-service-error-count"
    namespace = local.metrics_prefix
    value     = "1"
  }
}

resource "aws_sns_topic" "alarm" {
  count = local.has_alarm_mail ? 1 : 0
  name  = "${local.name_prefix}-alarms"
}

resource "aws_sns_topic_subscription" "alarm_email" {
  count     = local.has_alarm_mail ? 1 : 0
  topic_arn = aws_sns_topic.alarm[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "order_error" {
  alarm_name          = "${local.name_prefix}-order-service-errors"
  alarm_description   = "Alarm when order-service emits ERROR logs"
  namespace           = local.metrics_prefix
  metric_name         = "order-service-error-count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.has_alarm_mail ? [aws_sns_topic.alarm[0].arn] : []
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-microservices"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [[local.metrics_prefix, "order-service-error-count"]]
          period  = 60
          stat    = "Sum"
          region  = data.aws_region.current.name
          title   = "Order Service ERROR count"
        }
      }
    ]
  })
}

data "aws_region" "current" {}

resource "aws_xray_sampling_rule" "default" {
  rule_name      = "${local.name_prefix}-default-sampling"
  priority       = 1000
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.2
  host           = "*"
  http_method    = "*"
  url_path       = "*"
  resource_arn   = "*"
  service_name   = "*"
  service_type   = "*"
}
