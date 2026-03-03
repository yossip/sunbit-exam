provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Sunbit-POS"
      CostCenter  = "101-DevOps"
      Owner       = "Yossi-Makover"
      ManagedBy   = "Terraform"
      Compliance  = "PCI-DSS-Scope"
      Layer       = "01-Network"
    }
  }
}

# 1. VPC & Networking for High Availability (3 AZs)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "sunbit-pos-vpc-${var.environment}" # Core Foundation
  cidr = var.vpc_cidr

  azs              = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  # 2. Strict Security: VPC Endpoints (AWS PrivateLink)
  # This ensures EKS Pods communicate with AWS Services over the private AWS backbone, 
  # bypassing the public internet—a key PCI/HIPAA compliance metric highlighted in BNPL architectures.
  enable_vpn_gateway = false
}

# Define VPC Endpoints to isolate Database and Registry Traffic
module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  endpoints = {
    dynamodb = {
      service      = "dynamodb"
      service_type = "Gateway"
      route_table_ids = flatten([module.vpc.private_route_table_ids])
      tags         = { Name = "dynamodb-vpc-endpoint" }
    },
    sagemaker = {
      service             = "sagemaker.runtime"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    }
  }
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}
