locals {
  name_prefix                   = "${var.project_name}-${var.environment}"
  product_service_base_url_name = "/${var.project_name}/${var.environment}/config/product-service/base-url"
  stock_service_base_url_name   = "/${var.project_name}/${var.environment}/config/stock-service/base-url"
  order_created_topic_name      = "/${var.project_name}/${var.environment}/config/kafka/order-created-topic"
  order_cancelled_topic_name    = "/${var.project_name}/${var.environment}/config/kafka/order-cancelled-topic"
  stock_consumer_group_name     = "/${var.project_name}/${var.environment}/config/kafka/stock-consumer-group"
  kafka_bootstrap_name          = "/${var.project_name}/${var.environment}/config/kafka/bootstrap-brokers"
}

resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = var.namespace_name
  description = "Cloud Map namespace for ${local.name_prefix}"
  vpc         = var.vpc_id
}

resource "aws_ssm_parameter" "product_service_base_url" {
  name  = local.product_service_base_url_name
  type  = "String"
  value = "http://product-service.${var.namespace_name}:8901"
}

resource "aws_ssm_parameter" "stock_service_base_url" {
  name  = local.stock_service_base_url_name
  type  = "String"
  value = "http://stock-service.${var.namespace_name}:8900"
}

resource "aws_ssm_parameter" "order_created_topic" {
  name  = local.order_created_topic_name
  type  = "String"
  value = "order-created"
}

resource "aws_ssm_parameter" "order_cancelled_topic" {
  name  = local.order_cancelled_topic_name
  type  = "String"
  value = "order-cancelled"
}

resource "aws_ssm_parameter" "stock_consumer_group" {
  name  = local.stock_consumer_group_name
  type  = "String"
  value = "stock-service-group"
}

resource "aws_ssm_parameter" "kafka_bootstrap_brokers" {
  count = var.create_kafka_bootstrap_parameter ? 1 : 0

  name  = local.kafka_bootstrap_name
  type  = "String"
  value = var.kafka_bootstrap_brokers_value

  lifecycle {
    ignore_changes = [value]
  }
}
