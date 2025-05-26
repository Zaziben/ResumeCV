output "api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "function" {
  value = aws_lambda_function.visitor_counter.function_name
}

output "api_custom_domain_name" {
  value = aws_apigatewayv2_domain_name.custom_d.domain_name_configuration[0].target_domain_name
}

output "api_hosted_zone_id" {
  value = aws_apigatewayv2_domain_name.custom_d.domain_name_configuration[0].hosted_zone_id
}


