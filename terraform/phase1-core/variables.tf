variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-2"
}

variable "project_name" {
  type        = string
  description = "Project slug used in naming"
  default     = "cs590-microservices"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "demo"
}

variable "namespace_name" {
  type        = string
  description = "Cloud Map private DNS namespace"
  default     = "demo.local"
}

variable "db_master_username" {
  type        = string
  description = "Aurora master username"
  default     = "appadmin"
}

variable "db_instance_class" {
  type        = string
  description = "Aurora instance class"
  default     = "db.t4g.medium"
}

variable "order_service_image_uri" {
  type        = string
  description = "ECR image URI for order-service"
  default     = ""
}

variable "api_gateway_image_uri" {
  type        = string
  description = "ECR image URI for api-gateway"
  default     = ""
}

variable "deploy_services" {
  type        = bool
  description = "Deploy ECS application services in this phase"
  default     = false
}

variable "deploy_api_gateway_service" {
  type        = bool
  description = "Deploy Spring api-gateway ECS service"
  default     = false
}

variable "product_service_image_uri" {
  type        = string
  description = "ECR image URI for product-service"
  default     = ""
}

variable "stock_service_image_uri" {
  type        = string
  description = "ECR image URI for stock-service"
  default     = ""
}

variable "product_desired_count" {
  type    = number
  default = 1
}

variable "stock_desired_count" {
  type    = number
  default = 2
}

variable "order_desired_count" {
  type    = number
  default = 1
}

variable "api_gateway_desired_count" {
  type    = number
  default = 1
}

variable "create_kafka_bootstrap_parameter" {
  type        = bool
  description = "Create placeholder SSM parameter for manual Kafka cluster bootstrap brokers"
  default     = true
}

variable "kafka_bootstrap_brokers_value" {
  type        = string
  description = "Value for Kafka bootstrap brokers parameter. Update after manual cluster setup"
  default     = "REPLACE_ME_KAFKA_BOOTSTRAP_BROKERS"
}

variable "enable_waf" {
  type        = bool
  description = "Attach AWS managed WAF rules to HTTP API"
  default     = true
}
