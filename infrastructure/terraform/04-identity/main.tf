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
      Layer       = "04-Identity"
    }
  }
}

# 1. Amazon Cognito User Pool
# Secures merchant and user identities for the BNPL application
resource "aws_cognito_user_pool" "pos_users" {
  name = "sunbit-pos-users-${var.environment}"

  # Enforce strict password policies (PCI/Compliance standard)
  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  # Multi-Factor Authentication (MFA) is strictly required for financial apps
  mfa_configuration = "ON"

  software_token_mfa_configuration {
    enabled = true
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }
}

# 2. Amazon Cognito User Pool Client
# Represents the specific application (e.g., the POS Gateway or Mobile App)
resource "aws_cognito_user_pool_client" "pos_app_client" {
  name         = "pos-frontend-client"
  user_pool_id = aws_cognito_user_pool.pos_users.id

  generate_secret = true

  # OAuth 2.0 flows required by the Application Load Balancer
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  
  supported_identity_providers = ["COGNITO"]
  
  callback_urls = ["https://${var.api_url}/oauth2/idpresponse"]
  logout_urls   = ["https://${var.api_url}/"]
}

# 3. Amazon Cognito Domain
# Required for the ALB to redirect unauthenticated users to a hosted login UI
resource "aws_cognito_user_pool_domain" "pos_domain" {
  # Prefix must be globally unique across AWS region
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.pos_users.id
}

# Outputs for Kubernetes Ingress
output "cognito_user_pool_arn" {
  value = aws_cognito_user_pool.pos_users.arn
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.pos_app_client.id
}

output "cognito_user_pool_domain" {
  value = aws_cognito_user_pool_domain.pos_domain.domain
}
