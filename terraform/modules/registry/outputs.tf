output "namespace_id" { value = aws_service_discovery_private_dns_namespace.this.id }
output "namespace_name" { value = aws_service_discovery_private_dns_namespace.this.name }
output "product_service_base_url_parameter_name" { value = aws_ssm_parameter.product_service_base_url.name }
output "stock_service_base_url_parameter_name" { value = aws_ssm_parameter.stock_service_base_url.name }
output "order_created_topic_parameter_name" { value = aws_ssm_parameter.order_created_topic.name }
output "order_cancelled_topic_parameter_name" { value = aws_ssm_parameter.order_cancelled_topic.name }
output "stock_consumer_group_parameter_name" { value = aws_ssm_parameter.stock_consumer_group.name }
output "kafka_bootstrap_parameter_name" { value = local.kafka_bootstrap_name }
