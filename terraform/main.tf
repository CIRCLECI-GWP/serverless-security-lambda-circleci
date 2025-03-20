provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
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

# ✅ IAM Role for AWS Lambda
resource "aws_iam_role" "lambda_role" {
  name = "RealEstateLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
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

# ✅ Attach Policy to Role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  policy_arn = aws_iam_policy.dynamodb_policy.arn
  role       = aws_iam_role.lambda_role.name
}

data "archive_file" "lambda_zip" {
    type          = "zip"
    source_dir   = "../src/"
    output_path   = "lambda.zip"   
}

# ✅ AWS Lambda Function
resource "aws_lambda_function" "real_estate_lambda" {
  function_name = "RealEstateAPI"
  runtime       = "nodejs18.x"
  handler       = "index.handler"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 10
  filename         = "lambda.zip"
  # source_code_hash = filebase64sha256("../lambda.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.real_estate.name
    }
  }
}

# ✅ API Gateway
resource "aws_api_gateway_rest_api" "real_estate_api" {
  name        = "RealEstateAPI"
  description = "API Gateway for Real Estate Lambda"
}

resource "aws_api_gateway_resource" "real_estate_resource" {
  rest_api_id = aws_api_gateway_rest_api.real_estate_api.id
  parent_id   = aws_api_gateway_rest_api.real_estate_api.root_resource_id
  path_part   = "property"
}

resource "aws_api_gateway_method" "real_estate_method" {
  rest_api_id   = aws_api_gateway_rest_api.real_estate_api.id
  resource_id   = aws_api_gateway_resource.real_estate_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "real_estate_integration" {
  rest_api_id             = aws_api_gateway_rest_api.real_estate_api.id
  resource_id             = aws_api_gateway_resource.real_estate_resource.id
  http_method             = aws_api_gateway_method.real_estate_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.real_estate_lambda.invoke_arn
}

# ✅ Deploy API Gateway
resource "aws_api_gateway_deployment" "real_estate_deployment" {
  depends_on = [
    aws_api_gateway_integration.real_estate_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.real_estate_api.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.real_estate_api))
  }
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.real_estate_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_secretsmanager_secret" "db_secret" {
  name = "DBSecret2"
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    tableName = "RealEstateListings"
  })
}

# ✅ Output API Gateway URL
output "api_url" {
  value = aws_api_gateway_deployment.real_estate_deployment.invoke_url
}
