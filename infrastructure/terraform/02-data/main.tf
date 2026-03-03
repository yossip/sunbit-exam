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
      Layer       = "02-Data"
    }
  }
}

# The VPC ID and Subnets are passed as variables in a real pipeline 
# (e.g., fetched from Terragrunt or Terraform Cloud Workspaces)

# 1. Database Stub (Aurora PostgreSQL for HA)
module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 8.0"

  name           = "sunbit-pos-db-${var.environment}"
  engine         = "aurora-postgresql"
  engine_version = "15.3"
  
  vpc_id               = var.vpc_id
  subnets              = var.database_subnets
  create_db_subnet_group = true

  # Dynamic instance sizing based on environment (e.g. 1 x t4g.medium in Dev, 2 x r6g.large in Prod)
  instances = {
    for i in range(1, var.aurora_instance_count + 1) : i => {
      instance_class = var.aurora_instance_class
    }
  }

  # DRP Note: For Multi-Region Active-Passive Setup
  # global_cluster_identifier = aws_rds_global_cluster.pos_ledger.id

  storage_encrypted   = true
  apply_immediately   = true
  skip_final_snapshot = true
  
  tags = {
    Component = "Database-POS-Ledger"
  }
}

# 2. DynamoDB Table for fast state/lookups
resource "aws_dynamodb_table" "pos_sessions" {
  name           = "sunbit-pos-sessions-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "SessionId"

  attribute {
    name = "SessionId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  # DRP Note: Enable Replica blocks for Multi-Region Active-Active Global Tables
  # replica {
  #   region_name = "us-west-2"
  # }

  tags = {
    Component = "Database-POS-Sessions"
  }
}
