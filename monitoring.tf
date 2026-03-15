# ============================================================================
# CloudWatch Container Insights Monitoring
# ============================================================================

resource "aws_iam_role" "container_insights" {
  count = var.enable_container_insights ? 1 : 0
  name  = "${local.name_prefix}-container-insights"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster[0].arn
        }
        Condition = {
          StringEquals = {
            "${local.oidc_provider_name}:sub" = "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"
            "${local.oidc_provider_name}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.common_resource_tags

  depends_on = [aws_iam_openid_connect_provider.cluster]
}

resource "aws_iam_role_policy_attachment" "container_insights" {
  count      = var.enable_container_insights ? 1 : 0
  role       = aws_iam_role.container_insights[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ============================================================================
# Prometheus & ServiceMonitor Support
# ============================================================================

# This outputs configuration for Prometheus Operator to scrape metrics
locals {
  prometheus_config = var.prometheus_scrape_config ? {
    enabled = true
    serviceMonitor = {
      namespace = "monitoring"
      enabled   = true
      interval  = "30s"
    }
    alertManager = {
      enabled = true
    }
  } : {
    enabled = false
  }
}

# ============================================================================
# CloudWatch Insights Queries (Pre-built for common troubleshooting)
# ============================================================================

# Outputs common CloudWatch Insights queries for quick access
locals {
  cloudwatch_insights_queries = {
    pod_errors = "fields @timestamp, @message | filter @message like /ERROR/ | stats count() by bin(5m)"
    
    container_restarts = "fields @timestamp, container_name, exit_code | filter exit_code > 0 | stats count() as restart_count by container_name"
    
    high_memory_usage = "fields container_name, @message | filter @message like /MemoryHigh/ | stats avg(memory) by container_name"
    
    api_latency = "fields @timestamp, request_duration | stats avg(request_duration), max(request_duration) by bin(1m)"
    
    network_errors = "fields @timestamp, @message | filter @message like /NetworkError/ | stats count() by bin(1m)"
  }
}

# ============================================================================
# Observability Helper Outputs
# ============================================================================

output "container_insights_enabled" {
  description = "Whether Container Insights is enabled for the cluster"
  value       = var.enable_container_insights
}

output "container_insights_role_arn" {
  description = "IAM role ARN for Container Insights CloudWatch agent"
  value       = try(aws_iam_role.container_insights[0].arn, null)
}

output "cloudwatch_insights_queries" {
  description = "Pre-built CloudWatch Insights queries for troubleshooting"
  value       = local.cloudwatch_insights_queries
}

output "prometheus_scrape_enabled" {
  description = "Whether Prometheus scraping is enabled"
  value       = var.prometheus_scrape_config
}

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler (IRSA)"
  value       = try(aws_iam_role.cluster_autoscaler[0].arn, null)
}

output "cluster_autoscaler_helm_config" {
  description = "Helm values for deploying Cluster Autoscaler via GitOps"
  value       = local.cluster_autoscaler_helm_values
}

output "ebs_csi_driver_role_arn" {
  description = "IAM role ARN for EBS CSI Driver (IRSA)"
  value       = try(aws_iam_role.ebs_csi_driver[0].arn, null)
}
