# Sunbit POS Backend - Monthly AWS Cost Estimation

As a DevOps Manager, understanding and forecasting FinOps metrics is just as critical as system architecture. Below is an estimated monthly cost breakdown for the strictly defined infrastructure across the three isolated AWS accounts (Dev, Staging, Production). 

*Note: Prices are estimated based on `us-east-1` (N. Virginia) on-demand and spot pricing, excluding data egress bandwidth and Datadog licensing which varies heavily by traffic volume.*

---

## 1. Development Environment (Cost Optimized)
**Goal:** Provide an isolated sandbox for developers with the absolute minimum spend required to run the Kubernetes microservices.
**Key Savings:** 100% Spot Instances for compute, Single-AZ Database, WAF Disabled.

| AWS Service | Configuration | Estimated Monthly Cost |
| :--- | :--- | :--- |
| **Amazon EKS** | 1 Control Plane ($0.10/hr) | ~$73 |
| **EKS Compute (Karpenter)** | ~2x `t3.medium` instances (100% Spot Pricing) | ~$15 |
| **NAT Gateway** | 1x NAT Gateway + Data Processing (Low Volume) | ~$35 |
| **ALB & Route 53** | 1x Application Load Balancer + Hosted Zone | ~$17 |
| **Aurora PostgreSQL** | 1x `db.t4g.medium` (Single-AZ, Graviton) | ~$52 |
| **DynamoDB & ElastiCache** | Provisioned Low Capacity / `cache.t4g.micro` | ~$20 |
| **Cognito & VPC Endpoints** | Minimal MAUs, ~3 Interface Endpoints | ~$25 |
| **Total Dev Cost** | **Strictly Cost-Optimized** | **~$237 / month** |

---

## 2. Staging Environment (Integration & Testing)
**Goal:** Provide a scaled-down clone of production to run integration tests, chaos engineering, and Argo Rollout validations.
**Key Savings:** Uses Production Instance Classes but strictly relies on 100% Spot Instances for compute. WAF is enabled for rule testing.

| AWS Service | Configuration | Estimated Monthly Cost |
| :--- | :--- | :--- |
| **Amazon EKS** | 1 Control Plane ($0.10/hr) | ~$73 |
| **EKS Compute (Karpenter)** | ~3x `m5.large` instances (100% Spot Pricing) | ~$85 |
| **NAT Gateway** | 3x NAT Gateways (Multi-AZ for testing failovers) | ~$105 |
| **ALB, WAF & Route 53** | 1x ALB + AWS WAFv2 Web ACL + Rule Groups | ~$45 |
| **Aurora PostgreSQL** | 2x `db.r6g.large` (Multi-AZ for replication testing) | ~$380 |
| **DynamoDB & ElastiCache** | Scaled Capacity / `cache.t4g.medium` | ~$40 |
| **Cognito & VPC Endpoints** | Moderate MAUs, Interface Endpoints | ~$30 |
| **Total Staging Cost** | **Production Parity (Spot Compute)** | **~$758 / month** |

---

## 3. Production Environment (Mission Critical HA)
**Goal:** Zero-downtime, financially compliant architecture capable of taking immense burst traffic during peak retail hours.
**Key Costs:** 80/20 Spot/On-Demand mix to guarantee scheduling, Multi-AZ massive databases, WAF/Shield Advanced.

| AWS Service | Configuration | Estimated Monthly Cost |
| :--- | :--- | :--- |
| **Amazon EKS** | 1 Control Plane ($0.10/hr) | ~$73 |
| **EKS Compute (Karpenter)** | ~10-20x `m5.xlarge` (80% Spot, 20% On-Demand Mix) | ~$650 |
| **Amazon MSK / Kafka** | `kafka.m5.large` (3 Brokers for Event Streaming) | ~$460 |
| **NAT Gateway** | 3x NAT Gateways + High Volume Data Processing | ~$150+ |
| **ALB, WAF & Route 53** | 1x ALB + Advanced WAF Rules + Multi-Region DNS | ~$100 |
| **Aurora PostgreSQL** | 3x `db.r6g.2xlarge` (1 Primary, 2 Replicas - Multi-AZ) | ~$2,250 |
| **DynamoDB & ElastiCache** | High Capacity / 3x `cache.r6g.large` (Redis Cluster) | ~$350 |
| **Cognito & VPC Endpoints** | High MAUs, Interface Endpoints for SageMaker/S3 | ~$150 |
| **Total Prod Cost** | **Highly Available & Compliant** | **~$4,183+ / month** |

---

## DevOps FinOps Interview Talking Points
If asked about cost optimization during the interview, highlight the following design choices present in your Terraform:

1.  **Karpenter Spot Provisioning**: By feeding Karpenter an 80/20 mix in Production (via Topology Spread Constraints) and 100% Spot in Dev/Staging, we are saving **up to 70%** on our EC2 compute bill compared to static managed node groups.
2.  **Graviton Processors**: We utilize `t4g` and `r6g` instance classes for Aurora and ElastiCache. AWS Graviton (ARM64) processors provide up to 20% cost savings and 30% better performance over standard x86 Intel chips.
3.  **VPC Gateway Endpoints for S3**: By routing S3 KYC Document uploads through a *Gateway* Endpoint rather than a NAT Gateway, we bypass NAT Gateway data processing charges entirely (saving $0.045 per GB transferred).
