environment           = "prod"
aws_account_id        = "777788889999" # Example Prod Account
aws_region            = "us-east-1"
vpc_cidr              = "10.100.0.0/16"
private_subnets       = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
public_subnets        = ["10.100.101.0/24", "10.100.102.0/24", "10.100.103.0/24"]
database_subnets      = ["10.100.201.0/24", "10.100.202.0/24", "10.100.203.0/24"]

enable_waf             = true  # Required for Production PCI-DSS compliance
aurora_instance_count  = 3     # Multi-AZ Highly Available
aurora_instance_class  = "db.r6g.2xlarge" # Memory Optimized for high IOPS
eks_cluster_version    = "1.31"
karpenter_cpu_limit    = "1000"
karpenter_memory_limit = "1000Gi"

hpa_min_replicas       = 3
hpa_max_replicas       = 20

api_url               = "api.sunbit.com"
cognito_domain_prefix = "sunbit-pos-auth-prod"
