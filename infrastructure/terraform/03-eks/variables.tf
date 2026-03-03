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

variable "vpc_id" {
  description = "VPC ID from the 01-network layer"
  type        = string
}

variable "private_subnets" {
  description = "Private Subnet IDs from the 01-network layer"
  type        = list(string)
}

variable "eks_cluster_version" {
  description = "Kubernetes Version for the EKS Cluster"
  type        = string
  default     = "1.31"
}

variable "karpenter_cpu_limit" {
  description = "Maximum CPU cores Karpenter is allowed to provision"
  type        = string
  default     = "100"
}

variable "karpenter_memory_limit" {
  description = "Maximum Memory Karpenter is allowed to provision"
  type        = string
  default     = "1000Gi"
}

variable "hpa_min_replicas" {
  description = "Minimum number of API Pod replicas"
  type        = number
  default     = 3
}

variable "hpa_max_replicas" {
  description = "Maximum number of API Pod replicas"
  type        = number
  default     = 10
}

variable "karpenter_capacity_types" {
  description = "Allowed EC2 capacity types for the environment (e.g., [\"spot\"] for Dev, [\"spot\", \"on-demand\"] for Prod)"
  type        = list(string)
  default     = ["spot", "on-demand"]
}
