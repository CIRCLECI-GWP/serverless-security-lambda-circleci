variable "terraform_aws_access_key" {
  type        = string
  description = "AWS terraform access key"
  sensitive   = true
}

variable "terraform_aws_secret_key" {
  type        = string
  description = "AWS terraform secret key"
  sensitive   = true
}
