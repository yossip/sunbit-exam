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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet CIDR ranges"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDR ranges"
  type        = list(string)
}

variable "database_subnets" {
  description = "List of database subnet CIDR ranges"
  type        = list(string)
}

variable "enable_waf" {
  description = "Enable WAF creation (usually disabled in lower dev accounts to save costs)"
  type        = bool
  default     = true
}
