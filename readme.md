This **Node.js code** implements secure **CRUD operations** for managing real estate listings in **AWS DynamoDB**, following some best security practices. This code:

✅ Uses **AWS SDK v3** for DynamoDB.  
✅ Implements **IAM least privilege** (assumes AWS credentials are handled securely).  
✅ Uses **AWS Secrets Manager** to retrieve database settings securely.  
✅ Performs **input validation and sanitization**.  
✅ Includes **structured error handling**.  

---

### ** Install Dependencies**  
Run the following command to install required packages:  
```sh
npm install @aws-sdk/client-dynamodb @aws-sdk/lib-dynamodb @aws-sdk/client-secrets-manager dotenv express helmet serverless-http
```

### ** Security Features Implemented**
🔹 **IAM Least Privilege** – Lambda function should have minimal permissions (DynamoDB read/write only).  
🔹 **Secrets Manager** – Retrieves database table name securely (instead of hardcoding).  
🔹 **Input Validation** – Checks request body to prevent malicious inputs.  
🔹 **Condition Expressions** – Prevents overwrites and ensures items exist before updates/deletes.  
🔹 **Helmet Middleware** – Adds security headers to prevent common web attacks.  
🔹 **Error Handling** – Provides structured responses to avoid leaking sensitive data.  

# Testing scripts and CI/CD setup

✅ **Secure Node.js CRUD API for AWS DynamoDB**  
✅ **Testing with Jest & Supertest**  
✅ **CI/CD Pipeline with CircleCI**  

---

# **1️⃣ Install Testing Dependencies**  
Run the following command:  

```sh
npm install --save-dev jest supertest dotenv
```

---

# **2️⃣ Create Jest Test Cases**  
Create a new file: **`__tests__/property.test.js`**  

```javascript
import request from "supertest";
import dotenv from "dotenv";
import app from "../server.js"; // Import the Express app

dotenv.config();

describe("Property API Endpoints", () => {
    let propertyID = `test-${Date.now()}`; // Unique ID for testing

    // ✅ Create a Property
    it("should create a new property", async () => {
        const res = await request(app).post("/property").send({
            PropertyID: propertyID,
            Title: "Test Property",
            Description: "A test real estate listing",
            Type: "Rent",
            Price: 1000,
            Location: "Test City",
        });

        expect(res.statusCode).toEqual(201);
        expect(res.body.message).toBe("Property created successfully");
    });

    // ✅ Get a Property
    it("should retrieve the created property", async () => {
        const res = await request(app).get(`/property/${propertyID}`);
        expect(res.statusCode).toEqual(200);
        expect(res.body.Title).toBe("Test Property");
    });

    // ✅ Update a Property
    it("should update the property", async () => {
        const res = await request(app).put(`/property/${propertyID}`).send({
            Title: "Updated Property",
        });

        expect(res.statusCode).toEqual(200);
        expect(res.body.message).toBe("Property updated successfully");
    });

    // ✅ Delete a Property
    it("should delete the property", async () => {
        const res = await request(app).delete(`/property/${propertyID}`);
        expect(res.statusCode).toEqual(200);
        expect(res.body.message).toBe("Property deleted successfully");
    });

    // ✅ Get Deleted Property (Should Fail)
    it("should return 404 for deleted property", async () => {
        const res = await request(app).get(`/property/${propertyID}`);
        expect(res.statusCode).toEqual(404);
    });
});
```

---

# **3️⃣ Setup Jest in `package.json`**  
Modify `package.json` to include Jest:  

```json
"scripts": {
  "start": "node server.js",
  "test": "jest"
}
```

---

# **4️⃣ Create CircleCI CI/CD Pipeline**  
Create **`.circleci/config.yml`**:  

```yaml
version: 2.1

executors:
  node-executor:
    docker:
      - image: circleci/node:18

jobs:
  test:
    executor: node-executor
    steps:
      - checkout
      - run:
          name: Install Dependencies
          command: npm install
      - run:
          name: Run Tests
          command: npm test

  deploy:
    executor: node-executor
    steps:
      - checkout
      - run:
          name: Install Dependencies
          command: npm install
      - run:
          name: Deploy to AWS Lambda
          command: |
            aws lambda update-function-code \
              --function-name $AWS_LAMBDA_FUNCTION_NAME \
              --zip-file fileb://lambda.zip

workflows:
  version: 2
  test-and-deploy:
    jobs:
      - test
      - deploy:
          requires:
            - test
          filters:
            branches:
              only: main
```

---

# **5️⃣ How CI/CD Works**
1. **Tests Run on Every Commit** – CircleCI installs dependencies and runs Jest tests.  
2. **Deployment Only on Main Branch** – If tests pass, it updates the AWS Lambda function.  
3. **Secure Environment Variables** – CircleCI uses AWS credentials securely.  

---

# **6️⃣ Running Tests Locally**  
Run:  
```sh
npm test
```

---

### **🚀 Conclusion**  
✅ Secure **CRUD API** with AWS DynamoDB  
✅ **Automated Testing** using Jest & Supertest  
✅ **CI/CD Pipeline** with CircleCI  

Would you like me to add **Terraform for Infrastructure as Code (IaC)?** 🚀



# Provisioning the AWS Infrastructure

Steps to **provision the AWS infrastructure** for the **serverless real estate API** using **Terraform**.  

This setup includes:  
✅ **DynamoDB Table**  
✅ **IAM Role & Policy for AWS Lambda**  
✅ **AWS Lambda Deployment**  
✅ **AWS API Gateway for HTTP Requests**  

---

## **1️⃣ Install Terraform & AWS CLI**  
Ensure you have **Terraform** and **AWS CLI** installed.  
- [Install Terraform](https://developer.hashicorp.com/terraform/downloads)  
- [Install AWS CLI](https://aws.amazon.com/cli/)  

Run this command to verify Terraform:  
```sh
terraform --version
```

---

## **2️⃣ Create the Terraform Configuration**  
Create a new folder **`terraform/`**, then inside it, create the file **`main.tf`**.

```hcl
provider "aws" {
  region = "us-east-1"
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

# ✅ AWS Lambda Function
resource "aws_lambda_function" "real_estate_lambda" {
  function_name = "RealEstateAPI"
  runtime       = "nodejs18.x"
  handler       = "index.handler"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 10

  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")

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

# ✅ Output API Gateway URL
output "api_url" {
  value = aws_api_gateway_deployment.real_estate_deployment.invoke_url
}
```

---

## **3️⃣ Package the Lambda Function**  
Before deploying, you need to zip your **server.js** and **node_modules**:  

```sh
zip -r lambda.zip index.js node_modules
```

or

```sh
Compress-Archive -Path index.js, node_modules -DestinationPath lambda.zip -Force
```
---









---

## **✅ Solution 1: Configure AWS CLI Credentials**  
Run the following command to set up your AWS credentials:  

```powershell
aws configure
```

You'll be prompted to enter:  
- **AWS Access Key ID**
- **AWS Secret Access Key**  
- **Default region** (e.g., `us-east-1`)  
- **Output format** (leave empty for default)

Verify the credentials file exists:  

```powershell
Get-Content $HOME\.aws\credentials
```

---

## **✅ Solution 2: Set Environment Variables (Temporary Fix)**  
If you don't want to use `aws configure`, you can set the credentials in PowerShell:  

```powershell
$env:AWS_ACCESS_KEY_ID="your-access-key"
$env:AWS_SECRET_ACCESS_KEY="your-secret-key"
$env:AWS_REGION="us-east-1"
```

Now try running:  
```powershell
terraform plan
```

---

## **✅ Solution 3: Check Terraform AWS Provider in `main.tf`**  
Make sure your **`main.tf`** file has the correct provider definition:  

```hcl
provider "aws" {
  region = "us-east-1"
}
```

If you’re using AWS profiles, explicitly set it:

```hcl
provider "aws" {
  region                  = "us-east-1"
  shared_credentials_files = ["$HOME/.aws/credentials"]
  profile                 = "default"
}
```

---

## **✅ Solution 4: Verify IAM Permissions**  
Your AWS user **must have permissions** to manage AWS services. Attach the following policies to your IAM user:  
- `AdministratorAccess` (for full access)  
- OR  
- `AmazonDynamoDBFullAccess`
- `AWSLambdaFullAccess`
- `AmazonAPIGatewayAdministrator`

---

### **🎯 Final Step: Retry Terraform**
After applying these fixes, run:

```powershell
terraform init
terraform plan
```

To deploy:
```powershell
terraform apply
```

ERROR:

Enter a value: yes

aws_api_gateway_rest_api.real_estate_api: Creating...
aws_iam_role.lambda_role: Creating...
aws_dynamodb_table.real_estate: Creating...
aws_api_gateway_rest_api.real_estate_api: Creation complete after 2s [id=blvg46stm7]
aws_api_gateway_resource.real_estate_resource: Creating...
aws_api_gateway_deployment.real_estate_deployment: Creating...
aws_iam_role.lambda_role: Creation complete after 2s [id=RealEstateLambdaRole]
aws_api_gateway_resource.real_estate_resource: Creation complete after 0s [id=ey8fzk]
aws_api_gateway_method.real_estate_method: Creating...
aws_api_gateway_method.real_estate_method: Creation complete after 0s [id=agm-blvg46stm7-ey8fzk-ANY]
aws_dynamodb_table.real_estate: Still creating... [10s elapsed]
aws_dynamodb_table.real_estate: Creation complete after 15s [id=RealEstateListings]
aws_iam_policy.dynamodb_policy: Creating...
aws_lambda_function.real_estate_lambda: Creating...
aws_iam_policy.dynamodb_policy: Creation complete after 0s [id=arn:aws:iam::109718661763:policy/LambdaDynamoDBPolicy]
aws_iam_role_policy_attachment.lambda_dynamodb_attach: Creating...
aws_iam_role_policy_attachment.lambda_dynamodb_attach: Creation complete after 1s [id=RealEstateLambdaRole-20250313023541375400000001]
aws_lambda_function.real_estate_lambda: Creation complete after 9s [id=RealEstateAPI]
aws_lambda_permission.api_gateway_permission: Creating...
aws_api_gateway_integration.real_estate_integration: Creating...
aws_lambda_permission.api_gateway_permission: Creation complete after 0s [id=AllowExecutionFromAPIGateway]
aws_api_gateway_integration.real_estate_integration: Creation complete after 0s [id=agi-blvg46stm7-ey8fzk-ANY]
╷
│ Error: creating API Gateway Deployment: operation error API Gateway: CreateDeployment, https response error StatusCode: 400, RequestID: c1e8691e-39c2-486b-ac35-25d1b80661d4, BadRequestException: The REST API doesn't contain any methods
│
│   with aws_api_gateway_deployment.real_estate_deployment,
│   on main.tf line 116, in resource "aws_api_gateway_deployment" "real_estate_deployment":
│  116: resource "aws_api_gateway_deployment" "real_estate_deployment" {







Before running terraform apply, make sure your dependencies are installed:

```sh
npm install --production
```
This ensures that node_modules is included in the zip.


## **4️⃣ Deploy with Terraform**  
Run the following commands inside the `terraform/` directory:  

```sh
terraform init       # Initialize Terraform
terraform plan       # Preview the changes
terraform apply -auto-approve  # Deploy everything
```

---

## **5️⃣ Verify Deployment**  
Once deployment completes, **Terraform will print the API Gateway URL**.  
Test it with:  

```sh
curl -X GET "https://YOUR-API-GATEWAY-URL/property"
```

## Test

### Get Function URL

Lambda > Functions > [YOUR-LAMBDA]

* Click the Configuration tab
* Function URL > create
* Auth type: AWS_IAM
* Copy the Function URL
* Add /property/123 to the route, ex:
  https://bsavwnamwm4wu7yscertmrccwi0woshb.lambda-url.us-east-1.on.aws/property/123

### Get credentials

aws sts get-session-token

### Create DynamoDB Secret

```console
aws secretsmanager create-secret --name "DBSecret" --secret-string '{"tableName":"RealEstateListings"}'
```

Now go to **AWS Secrets Manager > Secrets > DBSecret**

Then edit the secret value to :

```console
{"tableName":"RealEstateListings"}
```

### Set environment variables

$env:DB_SECRET_NAME="DBSecret"

### Configure Postman for AWS Signature v4
* Open Postman.
* Select GET or POST (based on your Lambda function).
* Paste the Function URL.
* Go to the Authorization tab.
* Select AWS Signature from the Type dropdown.
* Enter your AWS credentials:
* Access Key: YOUR_ACCESS_KEY
* Secret Key: YOUR_SECRET_KEY
* Session Token (if applicable)
* AWS Region: Example: us-east-1
* Service Name: Use lambda
* Click Send.

---

### **🚀 Final Setup Recap**
✅ **DynamoDB Table** for real estate listings  
✅ **IAM Role & Policies** for secure AWS Lambda access  
✅ **AWS Lambda Deployment** (API logic)  
✅ **API Gateway** to expose REST endpoints  
✅ **CI/CD Pipeline** to deploy via **CircleCI**  
✅ **Terraform for Infrastructure as Code (IaC)**  

---

Would you like any **enhancements**, such as:  
1️⃣ **Custom domain name for API Gateway**?  
2️⃣ **Monitoring with AWS CloudWatch**? 🚀