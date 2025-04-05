# Creating AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = var.terraform_aws_access_key
  secret_key = var.terraform_aws_secret_key
}

# ✅ DynamoDB Table
resource "aws_dynamodb_table" "real_estate" {
  name           = "RealEstateListings"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PropertyID"

  attribute {
    name = "PropertyID"
    type = "S"
  }

  tags = {
    Name        = "RealEstateListings"
    Environment = "Production"
  }
}

# ✅ IAM Policy for DynamoDB Access
resource "aws_iam_policy" "dynamodb_policy" {
  name        = "LambdaDynamoDBPolicy"
  description = "Policy for Lambda to interact with DynamoDB"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.real_estate.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

}

resource "aws_apigatewayv2_integration" "real_estate_lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.real_estate_lambda.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "real_estate_lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "ANY /property/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.real_estate_lambda.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.real_estate_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  policy_arn = aws_iam_policy.dynamodb_policy.arn
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_iam_role_policy_attachment" "lambda_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}



# Creating zip file
data "archive_file" "application-code" {
  type        = "zip"
  source_dir  = "${path.module}/../../../src/lambda"
  output_path = "lambda.zip"
}

# Creating Lambda function
resource "aws_lambda_function" "real_estate_lambda" {
  filename          = data.archive_file.application-code.output_path
  source_code_hash  = data.archive_file.application-code.output_base64sha256
  function_name     = "real_state_api"
  handler           = "index.handler"
  runtime           = "nodejs20.x"
  memory_size       = 1024
  timeout           = 300

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.real_estate.name
    }
  }
}





resource "aws_secretsmanager_secret" "db_secret" {
  name = "DBSecret6"
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    tableName = "RealEstateListings"
  })
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_real_estate_lambda"

  assume_role_policy = jsonencode(
	{
	  "Version": "2012-10-17",
	  "Statement": [
		{
		  "Action": "sts:AssumeRole",
		  "Effect": "Allow",
		  "Sid": ""
		  "Principal": {
			  "Service": "lambda.amazonaws.com"
		  },
		}
	  ]
	})
}

data "aws_caller_identity" "current" {}

locals {
  lambda_assumed_role_arn = "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/${aws_iam_role.lambda_exec.name}/${aws_lambda_function.real_estate_lambda.function_name}"
}

data "aws_iam_policy_document" "db_secret" {
  statement {
    sid    = "EnableAnotherAWSAccountToReadTheSecret"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [local.lambda_assumed_role_arn]
    }

    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret_policy" "db_secret" {
  secret_arn = aws_secretsmanager_secret.db_secret.arn
  policy     = data.aws_iam_policy_document.db_secret.json
}