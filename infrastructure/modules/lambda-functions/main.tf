# Creating "ts_lambda_role" role
resource "aws_iam_role" "ts_lambda_role" {
  name = "lambda-functions-role"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Sid    = ""
          Principal = {
            Service : [
              "lambda.amazonaws.com",
            ]
          }
        },
      ]
  })

  lifecycle {
    ignore_changes = all
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "lambda_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.ts_lambda_role.name
}

# Creating zip file
data "archive_file" "application-code" {
  type        = "zip"
  # source_dir  = "${path.module}/../../../src/lambda-functions/deployment"
  source_dir  = "${path.module}/../../../src/lambda-functions"
  output_path = "lambda.zip"
}

# Creating Lambda function
resource "aws_lambda_function" "ts_lambda" {
  filename          = data.archive_file.application-code.output_path
  source_code_hash  = data.archive_file.application-code.output_base64sha256
  function_name     = "ts_lambda"
  role              = aws_iam_role.ts_lambda_role.arn
  handler           = "handler.handler"
  runtime           = "nodejs20.x"
  memory_size       = 1024
  timeout           = 300

  lifecycle {
    create_before_destroy = true
  }
}