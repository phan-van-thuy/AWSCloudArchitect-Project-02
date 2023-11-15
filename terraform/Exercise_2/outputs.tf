# TODO: Define the output variable for the lambda function.
output "role-lambda" {
    description = "rolo for lambda"
    value = aws_iam_role.role-lambda
}
output "policy" {
    description = "output policy lambda"
    value = aws_iam_policy.policy-lambda
}

output "lambda" {
    description = "output lambda"
    value = aws_lambda_function.lambda-tf
}
