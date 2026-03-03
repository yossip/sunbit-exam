environment           = "dev"
aws_account_id        = "111122223333" # Example Dev Account
aws_region            = "us-east-1"
vpc_cidr              = "10.10.0.0/16"
private_subnets       = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
public_subnets        = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]
database_subnets      = ["10.10.201.0/24", "10.10.202.0/24", "10.10.203.0/24"]

enable_waf             = false # Save costs in Dev
aurora_instance_count  = 1     # Single instance for Dev
aurora_instance_class  = "db.t4g.medium" # Cheaper Graviton burstable
eks_cluster_version    = "1.31"
karpenter_cpu_limit      = "20"
karpenter_memory_limit   = "64Gi"
karpenter_capacity_types = ["spot"] # 100% Spot for maximum cost savings in Dev

hpa_min_replicas       = 1
hpa_max_replicas       = 3

api_url               = "dev-api.sunbit-interview.com"
cognito_domain_prefix = "sunbit-pos-auth-dev-yossi"

# Note: vpc_id and subnet parameters for EKS/Data layers would be passed dynamically 
# in a real pipeline via Terragrunt `dependency` blocks or Terraform Cloud.
