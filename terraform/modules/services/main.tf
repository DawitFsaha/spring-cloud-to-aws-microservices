data "aws_region" "current" {}

data "aws_ssm_parameter" "product_service_base_url" {
  name = var.product_service_base_url_param
}

data "aws_ssm_parameter" "stock_service_base_url" {
  name = var.stock_service_base_url_param
}

data "aws_ssm_parameter" "order_created_topic" {
  name = var.order_created_topic_param
}

data "aws_ssm_parameter" "order_cancelled_topic" {
  name = var.order_cancelled_topic_param
}

data "aws_ssm_parameter" "stock_consumer_group" {
  name = var.stock_consumer_group_param
}

data "aws_ssm_parameter" "kafka_bootstrap" {
  name = var.kafka_bootstrap_param
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_service_discovery_service" "product" {
  name = "product-service"

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

resource "aws_service_discovery_service" "stock" {
  name = "stock-service"

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

resource "aws_service_discovery_service" "order" {
  name = "order-service"

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

resource "aws_service_discovery_service" "api_gateway" {
  count = var.deploy_api_gateway_service ? 1 : 0
  name  = "api-gateway"

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

resource "aws_ecs_task_definition" "product" {
  family                   = "${local.name_prefix}-product-service"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name         = "product-service"
      image        = var.product_service_image_uri
      essential    = true
      portMappings = [{ containerPort = 8901 }]
      environment = [
        { name = "SPRING_APPLICATION_NAME", value = "product-service" },
        { name = "SPRING_PROFILES_ACTIVE", value = "aws" },
        { name = "APP_ENV", value = var.environment },
        { name = "AWS_REGION", value = data.aws_region.current.name }
      ]
      secrets = [
        { name = "SPRING_DATASOURCE_URL", valueFrom = var.product_datasource_secret_arn },
        { name = "STOCK_SERVICE_BASE_URL", valueFrom = data.aws_ssm_parameter.stock_service_base_url.arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}/${var.environment}/product-service"
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "stock" {
  family                   = "${local.name_prefix}-stock-service"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name         = "stock-service"
      image        = var.stock_service_image_uri
      essential    = true
      portMappings = [{ containerPort = 8900 }]
      environment = [
        { name = "SPRING_APPLICATION_NAME", value = "stock-service" },
        { name = "SPRING_PROFILES_ACTIVE", value = "aws" },
        { name = "APP_ENV", value = var.environment },
        { name = "AWS_REGION", value = data.aws_region.current.name }
      ]
      secrets = [
        { name = "SPRING_DATASOURCE_URL", valueFrom = var.stock_datasource_secret_arn },
        { name = "ORDER_CREATED_TOPIC", valueFrom = data.aws_ssm_parameter.order_created_topic.arn },
        { name = "ORDER_CANCELLED_TOPIC", valueFrom = data.aws_ssm_parameter.order_cancelled_topic.arn },
        { name = "STOCK_CONSUMER_GROUP_ID", valueFrom = data.aws_ssm_parameter.stock_consumer_group.arn },
        { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", valueFrom = data.aws_ssm_parameter.kafka_bootstrap.arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}/${var.environment}/stock-service"
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "order" {
  family                   = "${local.name_prefix}-order-service"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name         = "order-service"
      image        = var.order_service_image_uri
      essential    = true
      portMappings = [{ containerPort = 8903 }]
      environment = [
        { name = "SPRING_APPLICATION_NAME", value = "order-service" },
        { name = "SPRING_PROFILES_ACTIVE", value = "aws" },
        { name = "APP_ENV", value = var.environment },
        { name = "AWS_REGION", value = data.aws_region.current.name }
      ]
      secrets = [
        { name = "SPRING_DATASOURCE_URL", valueFrom = var.order_datasource_secret_arn },
        { name = "PRODUCT_SERVICE_BASE_URL", valueFrom = data.aws_ssm_parameter.product_service_base_url.arn },
        { name = "STOCK_SERVICE_BASE_URL", valueFrom = data.aws_ssm_parameter.stock_service_base_url.arn },
        { name = "ORDER_CREATED_TOPIC", valueFrom = data.aws_ssm_parameter.order_created_topic.arn },
        { name = "ORDER_CANCELLED_TOPIC", valueFrom = data.aws_ssm_parameter.order_cancelled_topic.arn },
        { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", valueFrom = data.aws_ssm_parameter.kafka_bootstrap.arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}/${var.environment}/order-service"
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "api_gateway" {
  count                    = var.deploy_api_gateway_service ? 1 : 0
  family                   = "${local.name_prefix}-api-gateway"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name         = "api-gateway"
      image        = var.api_gateway_image_uri
      essential    = true
      portMappings = [{ containerPort = 8080 }]
      environment = [
        { name = "SPRING_APPLICATION_NAME", value = "api-gateway" },
        { name = "SPRING_PROFILES_ACTIVE", value = "aws" },
        { name = "APP_ENV", value = var.environment },
        { name = "AWS_REGION", value = data.aws_region.current.name }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}/${var.environment}/api-gateway"
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "product" {
  name            = "product-service"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.product.arn
  desired_count   = var.product_desired_count
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  network_configuration {
    assign_public_ip = false
    subnets          = [var.private_app_subnet_a, var.private_app_subnet_b]
    security_groups  = [var.ecs_service_security_group_id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.product.arn
  }

  load_balancer {
    target_group_arn = var.product_target_group_arn
    container_name   = "product-service"
    container_port   = 8901
  }
}

resource "aws_ecs_service" "stock" {
  name            = "stock-service"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.stock.arn
  desired_count   = var.stock_desired_count
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  network_configuration {
    assign_public_ip = false
    subnets          = [var.private_app_subnet_a, var.private_app_subnet_b]
    security_groups  = [var.ecs_service_security_group_id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.stock.arn
  }

  load_balancer {
    target_group_arn = var.stock_target_group_arn
    container_name   = "stock-service"
    container_port   = 8900
  }
}

resource "aws_ecs_service" "order" {
  name            = "order-service"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.order.arn
  desired_count   = var.order_desired_count
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  network_configuration {
    assign_public_ip = false
    subnets          = [var.private_app_subnet_a, var.private_app_subnet_b]
    security_groups  = [var.ecs_service_security_group_id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.order.arn
  }

  load_balancer {
    target_group_arn = var.order_target_group_arn
    container_name   = "order-service"
    container_port   = 8903
  }
}

resource "aws_ecs_service" "api_gateway" {
  count           = var.deploy_api_gateway_service ? 1 : 0
  name            = "api-gateway"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.api_gateway[0].arn
  desired_count   = var.api_gateway_desired_count
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  network_configuration {
    assign_public_ip = false
    subnets          = [var.private_app_subnet_a, var.private_app_subnet_b]
    security_groups  = [var.ecs_service_security_group_id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.api_gateway[0].arn
  }
}
