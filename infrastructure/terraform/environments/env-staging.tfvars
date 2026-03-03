environment           = "staging"
aws_account_id        = "444455556666" # Example Staging Account
aws_region            = "us-east-1"
vpc_cidr              = "10.50.0.0/16"
private_subnets       = ["10.50.1.0/24", "10.50.2.0/24", "10.50.3.0/24"]
public_subnets        = ["10.50.101.0/24", "10.50.102.0/24", "10.50.103.0/24"]
database_subnets      = ["10.50.201.0/24", "10.50.202.0/24", "10.50.203.0/24"]

enable_waf             = true  # Validating WAF rules before prod
aurora_instance_count  = 2     # Matching Production Architecture but scaled down
aurora_instance_class  = "db.r6g.large"
eks_cluster_version    = "1.31"
karpenter_cpu_limit    = "100"
karpenter_memory_limit = "500Gi"

api_url               = "staging-api.sunbit.com"
cognito_domain_prefix = "sunbit-pos-auth-staging"
