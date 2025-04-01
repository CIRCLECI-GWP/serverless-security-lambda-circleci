# Set AWS Region
$region = "us-east-1"

# Delete Lambda function
$lambdaFunctionName = "real_state_api"
aws lambda delete-function --function-name $lambdaFunctionName --region $region

# Detach IAM Policies from Role
$roleName = "serverless_real_estate_lambda"
$attachedPolicies = aws iam list-attached-role-policies --role-name $roleName --query "AttachedPolicies[*].PolicyArn" --output json | ConvertFrom-Json
foreach ($policy in $attachedPolicies) {
    aws iam detach-role-policy --role-name $roleName --policy-arn $policy
}

# Delete IAM Role
aws iam delete-role --role-name $roleName

# Delete API Gateway v2
$apiId = $(aws apigatewayv2 get-apis --query "Items[?Name=='serverless_lambda_gw'].ApiId" --output text)
if ($apiId) {
    aws apigatewayv2 delete-api --api-id $apiId
}

# Delete DynamoDB Table
$dynamoDbTableName = "RealEstateListings"
aws dynamodb delete-table --table-name $dynamoDbTableName --region $region

# Delete IAM Policy
$policyName = "LambdaDynamoDBPolicy"
$policyArn = aws iam list-policies --query "Policies[?PolicyName=='$policyName'].Arn" --output text
if ($policyArn) {
    aws iam delete-policy --policy-arn $policyArn
}

# Delete Secrets Manager Secret
$secretName = "DBSecret6"
$secretId = aws secretsmanager list-secrets --query "SecretList[?Name=='$secretName'].ARN" --output text
if ($secretId) {
    aws secretsmanager delete-secret --secret-id $secretId --force-delete-without-recovery
}
