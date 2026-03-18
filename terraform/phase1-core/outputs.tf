output "http_api_invoke_url" {
  value       = module.edge.http_api_invoke_url
  description = "Base invoke URL for API Gateway HTTP API"
}

output "internal_alb_dns_name" {
  value       = module.edge.internal_alb_dns_name
  description = "Internal ALB DNS name"
}

output "namespace_name" {
  value       = module.registry.namespace_name
  description = "Cloud Map namespace"
}

output "kafka_bootstrap_parameter_name" {
  value       = module.registry.kafka_bootstrap_parameter_name
  description = "SSM parameter name where manual Kafka bootstrap brokers should be stored"
}

output "ecs_cluster_name" {
  value       = module.compute.ecs_cluster_name
  description = "ECS cluster name"
}

output "aurora_endpoint" {
  value       = module.data.aurora_endpoint
  description = "Aurora cluster writer endpoint"
}
