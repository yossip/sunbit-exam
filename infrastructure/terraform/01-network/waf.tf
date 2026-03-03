# AWS WAFv2 Web ACL to attach to the Application Load Balancer
resource "aws_wafv2_web_acl" "pos_api_waf" {
  count       = var.enable_waf ? 1 : 0
  
  name        = "sunbit-pos-api-waf-${var.environment}"
  description = "WAF for Sunbit POS API ALB - ${var.environment}"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Add AWS Managed Core Rule Set to protect against common vulnerabilities (OWASP Top 10)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {} # Use the default action from the managed rule (Block usually)
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Add AWS Managed SQLi Rule Set to protect database parsing queries
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate Limiting Rule (e.g., prevent brute-forcing the credit application endpoint)
  rule {
    name     = "RateLimitCreditApplications"
    priority = 30

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 500 # Max requests per 5 minutes per IP
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "sunbitPOSApiWafMetric"
    sampled_requests_enabled   = true
  }

  tags = {
    Component = "Edge-Security"
  }
}

# Output the WAF ARN so it can be used in the Kubernetes Ingress manifest
output "waf_acl_arn" {
  value       = var.enable_waf ? aws_wafv2_web_acl.pos_api_waf[0].arn : ""
  description = "The ARN of the WAF Web ACL to annotate the AWS Load Balancer Controller Ingress"
}
