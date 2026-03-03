variable "aws_region" {
  description = "AWS Region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_account_id" {
  description = "The AWS Account ID where the infrastructure is deployed"
  type        = string
}

variable "api_url" {
  description = "The public facing URL of the API for Cognito Callbacks"
  type        = string
}

variable "cognito_domain_prefix" {
  description = "Globally unique prefix for the Cognito Hosted UI domain"
  type        = string
}
