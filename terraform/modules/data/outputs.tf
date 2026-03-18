output "aurora_endpoint" { value = aws_rds_cluster.aurora.endpoint }
output "product_datasource_url_secret_arn" { value = aws_secretsmanager_secret.product_datasource_url.arn }
output "stock_datasource_url_secret_arn" { value = aws_secretsmanager_secret.stock_datasource_url.arn }
output "order_datasource_url_secret_arn" { value = aws_secretsmanager_secret.order_datasource_url.arn }
