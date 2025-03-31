terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tf-state-bucket-20250330-2000"
    key            = "terraform/state.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
  }
}

# Creating AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = var.terraform_aws_access_key
  secret_key = var.terraform_aws_secret_key
}

#Call module lambda Terraform
module "lambda" {
  source                   = "../../modules/lambda"
  terraform_aws_access_key = var.terraform_aws_access_key
  terraform_aws_secret_key = var.terraform_aws_secret_key
}