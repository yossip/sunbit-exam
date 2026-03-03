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

variable "aurora_instance_class" {
  description = "Instance class for Aurora PostgreSQL"
  type        = string
  default     = "db.r6g.large"
}

variable "aurora_instance_count" {
  description = "Number of Aurora instances (1 for Dev, 2+ for Prod/Staging HA)"
  type        = number
  default     = 2
}

variable "vpc_id" {
  description = "VPC ID from the 01-network layer"
  type        = string
}

variable "database_subnets" {
  description = "Database subnet IDs from the 01-network layer"
  type        = list(string)
}
