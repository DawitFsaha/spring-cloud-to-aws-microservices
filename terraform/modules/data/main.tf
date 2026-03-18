locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_secretsmanager_secret" "aurora_master" {
  name = "/${var.project_name}/${var.environment}/aurora/master"
}

resource "random_password" "aurora_password" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret_version" "aurora_master" {
  secret_id = aws_secretsmanager_secret.aurora_master.id
  secret_string = jsonencode({
    username = var.db_master_username
    password = random_password.aurora_password.result
  })
}

resource "aws_db_subnet_group" "aurora" {
  name       = "${local.name_prefix}-aurora-subnets"
  subnet_ids = [var.private_data_subnet_a, var.private_data_subnet_b]
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier     = "${local.name_prefix}-aurora-pg"
  engine                 = "aurora-postgresql"
  database_name          = "app_db"
  master_username        = var.db_master_username
  master_password        = random_password.aurora_password.result
  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [var.db_security_group_id]
  storage_encrypted      = true
  skip_final_snapshot    = true
}

resource "aws_rds_cluster_instance" "aurora_a" {
  identifier          = "${local.name_prefix}-aurora-pg-a"
  cluster_identifier  = aws_rds_cluster.aurora.id
  instance_class      = var.db_instance_class
  engine              = aws_rds_cluster.aurora.engine
  publicly_accessible = false
}

resource "aws_secretsmanager_secret" "product_datasource_url" {
  name = "/${var.project_name}/${var.environment}/product-service/datasource-url"
}

resource "aws_secretsmanager_secret_version" "product_datasource_url" {
  secret_id     = aws_secretsmanager_secret.product_datasource_url.id
  secret_string = "jdbc:postgresql://${aws_rds_cluster.aurora.endpoint}:5432/app_db?user=${var.db_master_username}&password=${random_password.aurora_password.result}"
}

resource "aws_secretsmanager_secret" "stock_datasource_url" {
  name = "/${var.project_name}/${var.environment}/stock-service/datasource-url"
}

resource "aws_secretsmanager_secret_version" "stock_datasource_url" {
  secret_id     = aws_secretsmanager_secret.stock_datasource_url.id
  secret_string = "jdbc:postgresql://${aws_rds_cluster.aurora.endpoint}:5432/app_db?user=${var.db_master_username}&password=${random_password.aurora_password.result}"
}

resource "aws_secretsmanager_secret" "order_datasource_url" {
  name = "/${var.project_name}/${var.environment}/order-service/datasource-url"
}

resource "aws_secretsmanager_secret_version" "order_datasource_url" {
  secret_id     = aws_secretsmanager_secret.order_datasource_url.id
  secret_string = "jdbc:postgresql://${aws_rds_cluster.aurora.endpoint}:5432/app_db?user=${var.db_master_username}&password=${random_password.aurora_password.result}"
}
