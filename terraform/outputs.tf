
# Output the relevant resource information
output "lambda.arn" {
  value = "${aws_lambda_function.lambda.arn}"
}

output "iam_role.arn" {
  value = "${aws_iam_role.lambda.arn}"
}

output "aws_api_gateway_rest_api-id" {
  value = "${aws_api_gateway_rest_api.api.id}"
}

output "api-domain" {
  value = "https://${aws_api_gateway_base_path_mapping.api.domain_name}/${aws_api_gateway_base_path_mapping.api.base_path}/{action}"
}
