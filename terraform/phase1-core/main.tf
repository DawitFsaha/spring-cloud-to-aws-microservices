module "networking" {
  source = "../modules/networking"

  project_name = var.project_name
  environment  = var.environment
}

module "registry" {
  source = "../modules/registry"

  project_name                     = var.project_name
  environment                      = var.environment
  namespace_name                   = var.namespace_name
  vpc_id                           = module.networking.vpc_id
  create_kafka_bootstrap_parameter = var.create_kafka_bootstrap_parameter
  kafka_bootstrap_brokers_value    = var.kafka_bootstrap_brokers_value
}

module "compute" {
  source = "../modules/compute"

  project_name = var.project_name
  environment  = var.environment
}

module "data" {
  source = "../modules/data"

  project_name          = var.project_name
  environment           = var.environment
  db_master_username    = var.db_master_username
  db_instance_class     = var.db_instance_class
  private_data_subnet_a = module.networking.private_data_subnet_a_id
  private_data_subnet_b = module.networking.private_data_subnet_b_id
  db_security_group_id  = module.networking.db_security_group_id
}

module "edge" {
  source = "../modules/edge"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.networking.vpc_id
  private_app_subnet_a       = module.networking.private_app_subnet_a_id
  private_app_subnet_b       = module.networking.private_app_subnet_b_id
  alb_security_group_id      = module.networking.alb_security_group_id
  vpc_link_security_group_id = module.networking.vpc_link_security_group_id
  enable_waf                 = var.enable_waf
}

module "services" {
  source = "../modules/services"
  count  = var.deploy_services ? 1 : 0

  project_name                   = var.project_name
  environment                    = var.environment
  ecs_cluster_arn                = module.compute.ecs_cluster_arn
  task_execution_role_arn        = module.compute.task_execution_role_arn
  task_role_arn                  = module.compute.task_role_arn
  namespace_id                   = module.registry.namespace_id
  private_app_subnet_a           = module.networking.private_app_subnet_a_id
  private_app_subnet_b           = module.networking.private_app_subnet_b_id
  ecs_service_security_group_id  = module.networking.ecs_service_security_group_id
  product_datasource_secret_arn  = module.data.product_datasource_url_secret_arn
  stock_datasource_secret_arn    = module.data.stock_datasource_url_secret_arn
  order_datasource_secret_arn    = module.data.order_datasource_url_secret_arn
  product_service_base_url_param = module.registry.product_service_base_url_parameter_name
  stock_service_base_url_param   = module.registry.stock_service_base_url_parameter_name
  order_created_topic_param      = module.registry.order_created_topic_parameter_name
  order_cancelled_topic_param    = module.registry.order_cancelled_topic_parameter_name
  stock_consumer_group_param     = module.registry.stock_consumer_group_parameter_name
  kafka_bootstrap_param          = module.registry.kafka_bootstrap_parameter_name
  product_target_group_arn       = module.edge.product_target_group_arn
  stock_target_group_arn         = module.edge.stock_target_group_arn
  order_target_group_arn         = module.edge.order_target_group_arn
  product_service_image_uri      = var.product_service_image_uri
  stock_service_image_uri        = var.stock_service_image_uri
  order_service_image_uri        = var.order_service_image_uri
  api_gateway_image_uri          = var.api_gateway_image_uri
  deploy_api_gateway_service     = var.deploy_api_gateway_service
  product_desired_count          = var.product_desired_count
  stock_desired_count            = var.stock_desired_count
  order_desired_count            = var.order_desired_count
  api_gateway_desired_count      = var.api_gateway_desired_count
}
