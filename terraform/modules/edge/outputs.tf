output "http_api_id" { value = aws_apigatewayv2_api.http.id }
output "http_api_invoke_url" { value = aws_apigatewayv2_stage.default.invoke_url }
output "internal_alb_dns_name" { value = aws_lb.internal.dns_name }
output "order_target_group_arn" { value = aws_lb_target_group.order.arn }
output "product_target_group_arn" { value = aws_lb_target_group.product.arn }
output "stock_target_group_arn" { value = aws_lb_target_group.stock.arn }
