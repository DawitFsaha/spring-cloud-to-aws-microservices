output "ecs_cluster_arn" { value = aws_ecs_cluster.this.arn }
output "ecs_cluster_name" { value = aws_ecs_cluster.this.name }
output "task_execution_role_arn" { value = aws_iam_role.task_execution.arn }
output "task_role_arn" { value = aws_iam_role.task_role.arn }
output "api_gateway_ecr_repository_uri" { value = aws_ecr_repository.api_gateway.repository_url }
output "product_service_ecr_repository_uri" { value = aws_ecr_repository.product_service.repository_url }
output "stock_service_ecr_repository_uri" { value = aws_ecr_repository.stock_service.repository_url }
output "order_service_ecr_repository_uri" { value = aws_ecr_repository.order_service.repository_url }
