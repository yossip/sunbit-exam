# Sunbit POS Backend Project (AWS & EKS)

This repository contains a basic but highly available Point of Sale (POS) backend processing architecture, designed to demonstrate enterprise-grade cloud patterns on AWS. It is built to support instant online credit applications with high availability, security, and scalability in mind.

## 🚀 Project Overview

The project simulates a microservice (`pos-api`) that receives a credit application, saves the application state, queries an AI/ML model for a risk assessment, and records the final ledger decision.

### Key Components

1.  **Infrastructure as Code (`/infrastructure`)**: Terraform configurations divided into isolated logical layers (`01-network`, `02-data`, `03-eks`, `04-identity`) to separate stateful database resources from mutable compute resources. Hardcoded values have been abstracted into `variables.tf`, allowing the exact same codebase to provision isolated Dev, Staging, and Production accounts using Terraform Workspaces mapped to `env-<workspace>.tfvars` files in `infrastructure/terraform/environments/`.
2.  **Application (`/application`)**: A Python FastAPI microservice to process POS requests. Includes a production-ready, non-root, multi-stage `Dockerfile`.
3.  **Kubernetes Manifests (`/k8s`)**: Standard manifests and an **Argo Rollouts** definition (`argo-rollout.yaml`) to demonstrate Progressive Delivery (Canary rollouts).
4.  **CI/CD Pipeline (`/.github/workflows`)**: A GitHub Actions workflow demonstrating building, testing, secure OIDC AWS authentication, Trivy vulnerability scanning, and Amazon ECR pushing.

#### Terraform Workspace Deployment Strategy Example
```bash
# Provisioning the Production Environment using Workspaces
cd infrastructure/terraform/01-network
terraform workspace select prod || terraform workspace new prod
terraform init
terraform apply -var-file="../environments/env-prod.tfvars"
```

---

## 🏗 System Architecture & Well-Architected Framework

This project adheres to the AWS Well-Architected Framework pillars:

### 1. Reliability (HA & DR)
*   **High Availability (HA)**: 
    *   The VPC spans **3 Availability Zones (AZs)**.
    *   The EKS cluster worker nodes and the `Deployment` pods are spread across these AZs using Kubernetes `topologySpreadConstraints`.
    *   **Aurora PostgreSQL** is configured for Multi-AZ deployments, ensuring automatic failover if the primary database instance goes down.
*   **Disaster Recovery (DR) & Multi-Region Setup**:
    *   **Architecture**: Warm Standby (Active-Passive) across two separate AWS Regions (e.g., `us-east-1` Primary, `us-west-2` Standby).
    *   **Target RPO** (Recovery Point Objective): < 1 second. Handled by **Aurora Global Database** (asynchronous cross-region replication) and **DynamoDB Global Tables**.
    *   **Target RTO** (Recovery Time Objective): < 15 minutes. Handled by **Route 53 Failover Routing** redirecting traffic to the secondary region.
    *   **Standby Compute**: A scaled-down EKS cluster runs in the secondary region. During failover, **Karpenter** instantly provisions nodes to handle the sudden burst of cross-country traffic.

### 2. Security
*   **Zero-Trust Networking (PrivateLink)**: 
    *   EKS Nodes and applications live in **Private Subnets**.
    *   **AWS PrivateLink (VPC Endpoints)** are configured in Terraform to ensure traffic between EKS pods and AWS services (like DynamoDB and SageMaker) travel entirely over the private AWS backbone, severely drastically reducing the attack surface.
    *   Databases live in **Isolated Subnets** with no internet gateways attached.
*   **Least Privilege IAM**: 
    *   The application does not use long-lived AWS Access Keys. Instead, it relies on **IAM Roles for Service Accounts (IRSA)** to grant EKS pods specific permissions (e.g., only access to the specific DynamoDB table).
    *   The CI/CD pipeline uses AWS native OIDC federation to push to ECR without storing static secrets in GitHub.
*   **Container Security**:
    *   The Dockerfile uses `python:slim`, installs dependencies in a virtual environment, and runs the application as a **non-root user**.
    *   Kubernetes pods force `readOnlyRootFilesystem: true` and drop ALL Linux capabilities to prevent privilege escalation.
    *   Trivy scans the image for `CRITICAL` or `HIGH` vulnerabilities before pushing to the staging/production registry.

### 3. Observability & APM (Datadog)
*   **Datadog Agent**: Configured to run as a DaemonSet to collect cluster-level and node-level metrics.
*   **Unified Service Tagging**: Deeply integrated into the Kubernetes manifests (via `tags.datadoghq.com` labels) to ensure all traces, logs, and metrics are flawlessly correlated to the `pos-api` service.
*   **Application Performance Monitoring (APM)**: The FastAPI application is instrumented with `ddtrace`, automatically sending detailed distributed traces for every POS transaction to uncover latency bottlenecks.

---

## 💻 Running the Project Locally (Mock Mode)

To run the Python microservice locally:

```bash
cd application/
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Run the API
uvicorn app.main:app --reload
```

Test the endpoint:
```bash
curl -X 'POST' \
  'http://localhost:8000/api/v1/credit-applications' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "merchant_id": "merch_12345",
  "user_id": "user_9876",
  "purchase_amount": 1500.00,
  "item_category": "dental"
}'
```

---

## 🚀 CI/CD Flow overview

1.  **Developer** pushes code to the `main` branch.
2.  **GitHub Actions** CI triggers:
    *   Runs Unit Tests and Linting.
    *   Builds the Docker image.
    *   Runs **Aquasec Trivy** to scan the image for vulnerabilities.
    *   Uses **AWS OIDC** to obtain temporary, short-lived credentials to push the image to **Amazon ECR**.
3.  **Continuous Deployment & Progressive Delivery (GitOps)**:
    *   **ArgoCD** continuously monitors the Git repository. When a new image SHA is updated, ArgoCD initiates the sync.
    *   **Argo Rollouts** manages the zero-downtime deployment using a **Canary Strategy**. Initially, it routes 20% of the live traffic to the new version and pauses for manual/automated metric checks before soaking at 50% and eventually promoting to 100%. This is critical for high-stakes financial processing backends.
