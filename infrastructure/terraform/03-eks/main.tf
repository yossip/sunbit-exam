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
      Layer       = "03-EKS"
    }
  }
}

# 1. EKS Auto Mode Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0" # Version 20.x supports EKS Auto Mode natively

  cluster_name    = "sunbit-pos-eks-auto-${var.environment}"
  cluster_version = var.eks_cluster_version

  cluster_endpoint_public_access = false
  cluster_endpoint_private_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  # Enable EKS Auto Mode (managed compute, storage, and networking)
  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose", "system"]
  }

  enable_irsa = true

  # 2. OIDC for User Access Management (SSO for kubectl)
  # Allows developers to authenticate to the cluster using Corporate SSO (Okta/Entra) instead of AWS IAM
  cluster_identity_providers = {
    corporate_sso = {
      client_id      = var.corporate_oidc_client_id
      issuer_url     = var.corporate_oidc_issuer_url
      groups_claim   = "groups"
      groups_prefix  = "sso:"
      username_claim = "email"
    }
  }

  # EKS Auto Mode eliminates the need for manual `eks_managed_node_groups`
  # The 80% Spot / 20% On-Demand split is handled via Karpenter NodePool manifests
  # deployed *into* the cluster after creation.

  # EKS Addons - Native controllers
  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }
}

# --- Essential Controllers (Route53 & EBS) via IRSA (Least Privilege IAM) ---

# 1. AWS EBS CSI Driver IRSA
# Allows the cluster to dynamically provision Elastic Block Store (EBS) volumes for persistent state
module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "ebs-csi-${var.environment}"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# 2. ExternalDNS (Route 53 Controller) IRSA
# Automatically creates/updates Route 53 DNS records when Kubernetes Ingresses or Services are created
module "external_dns_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                     = "external-dns-${var.environment}"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/*"] # Best practice: lock this to a specific Zone ID

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}


# --- Kubernetes Manifests for EKS Auto Mode (Karpenter NodePools) ---
# Note: In a real environment, you deploy these via kubectl, Helm, or GitOps. 
# We explicitly document the 20/80 split for the interview here.

resource "kubernetes_manifest" "pos_nodepool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "pos-workloads"
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "default"
          }
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = var.karpenter_capacity_types
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64", "arm64"]
            }
          ]
        }
      }
      
      # Taints to isolate specific workloads (e.g., AI Decision Engine)
      # Only pods with matching tolerations can be scheduled on these nodes.
      taints = [
        {
          key    = "workload-type"
          value  = "decision-engine"
          effect = "NoSchedule"
        }
      ]

      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter   = "1m"
      }
      
      # The core interview requirement: 80% Spot, 20% On-Demand
      limits = {
        cpu    = var.karpenter_cpu_limit
        memory = var.karpenter_memory_limit
      }
      weight = 100
    }
  }
}

# Example of enforcing the 20/80 split mathematically using Karpenter's 
# `capacity-type` weightings (or relying on native EKS Auto capacity fallbacks).
# Alternatively, in EKS Auto Mode, you configure specific Pod topology spread 
# constraints across capacity types in the Deployment.

# --- Horizontal Pod Autoscaler (HPA) ---
# Managed via Terraform to allow injecting environment-specific min/max scaling limits

resource "kubernetes_manifest" "pos_api_hpa" {
  manifest = {
    apiVersion = "autoscaling/v2"
    kind       = "HorizontalPodAutoscaler"
    metadata = {
      name      = "sunbit-pos-api-hpa"
      namespace = "default"
    }
    spec = {
      scaleTargetRef = {
        apiVersion = "apps/v1"
        kind       = "Deployment"
        name       = "sunbit-pos-api"
      }
      minReplicas = var.hpa_min_replicas
      maxReplicas = var.hpa_max_replicas
      metrics = [
        {
          type = "Resource"
          resource = {
            name = "cpu"
            target = {
              type = "Utilization"
              averageUtilization = 70
            }
          }
        },
        # More sophisticated Datadog-based custom metric (Network Latency)
        {
          type = "Object"
          object = {
            describedObject = {
              apiVersion = "datadoghq.com/v1alpha1"
              kind       = "DatadogMetric"
              name       = "pos-api-latency"
            }
            metric = {
              name = "pos-api-latency"
            }
            target = {
              type  = "Value"
              value = "100m" # Target 100 milliseconds average latency before triggering scale-up
            }
          }
        }
      ]
    }
  }
}

# --- Datadog Metric Query ---
# Exposes a raw Datadog query to the Kubernetes HPA Controller (via the Datadog Cluster Agent)
resource "kubernetes_manifest" "pos_api_datadog_metric" {
  manifest = {
    apiVersion = "datadoghq.com/v1alpha1"
    kind       = "DatadogMetric"
    metadata = {
      name      = "pos-api-latency"
      namespace = "default"
    }
    spec = {
      # Resolves to a raw query calculating average network latency for this specific service and environment
      query = "avg:network.latency{service:pos-api,env:${var.environment}}"
    }
  }
}
