# ============================================================================
# Cluster Information Outputs
# ============================================================================

output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_status" {
  description = "Status of the EKS cluster (CREATING, ACTIVE, DELETING, FAILED, PENDING, UPDATING)"
  value       = aws_eks_cluster.main.status
}

# ============================================================================
# Cluster Security & Authentication
# ============================================================================

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data for the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = try(aws_eks_cluster.main.identity[0].oidc[0].issuer, null)
}

output "cluster_oidc_issuer_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = try(aws_iam_openid_connect_provider.cluster[0].arn, null)
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider (alias for cluster_oidc_issuer_arn)"
  value       = try(aws_iam_openid_connect_provider.cluster[0].arn, null)
}

# ============================================================================
# IAM Roles
# ============================================================================

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "node_iam_role_arn" {
  description = "IAM role ARN of the EKS worker nodes"
  value       = aws_iam_role.node.arn
}

output "node_iam_role_name" {
  description = "IAM role name of the EKS worker nodes"
  value       = aws_iam_role.node.name
}

output "node_instance_profile_arn" {
  description = "ARN of the node instance profile"
  value       = aws_iam_instance_profile.node.arn
}

# ============================================================================
# Security Groups
# ============================================================================

output "cluster_security_group_id" {
  description = "Security group ID of the cluster control plane"
  value       = var.create_cluster_security_group ? aws_security_group.cluster[0].id : null
}

output "node_security_group_id" {
  description = "Security group ID of the EKS nodes"
  value       = aws_security_group.node.id
}

# ============================================================================
# Node Group Information
# ============================================================================

output "node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.default.id
}

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.default.arn
}

output "node_group_status" {
  description = "Status of the EKS Node Group. One of: CREATING, ACTIVE, UPDATING, DELETING, CREATE_FAILED, DELETE_FAILED, DEGRADED, UNKNOWN"
  value       = aws_eks_node_group.default.status
}

output "node_group_resources" {
  description = "Resources associated with the EKS Node Group (Auto Scaling Groups, etc)"
  value       = aws_eks_node_group.default.resources
}

# ============================================================================
# Add-ons Information
# ============================================================================

output "cluster_addons" {
  description = "Map of EKS add-on names to addon details"
  value = {
    for addon_name, addon_resource in aws_eks_addon.default :
    addon_name => {
      id               = addon_resource.id
      arn              = addon_resource.arn
      version          = addon_resource.addon_version
      created_at       = addon_resource.created_at
      modified_at      = addon_resource.modified_at
    }
  }
}

# ============================================================================
# VPC & Networking
# ============================================================================

output "vpc_id" {
  description = "VPC ID where the cluster is deployed"
  value       = var.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by the cluster"
  value       = var.private_subnet_ids
}

output "control_plane_subnet_ids" {
  description = "Subnet IDs used for EKS control plane"
  value       = local.control_plane_subnet_ids
}

# ============================================================================
# CloudWatch Logging
# ============================================================================

output "cluster_log_group_name" {
  description = "Name of the CloudWatch log group for cluster logs"
  value       = aws_cloudwatch_log_group.cluster.name
}

output "cluster_log_group_arn" {
  description = "ARN of the CloudWatch log group for cluster logs"
  value       = aws_cloudwatch_log_group.cluster.arn
}

# ============================================================================
# Autobots Platform Helper Outputs
# ============================================================================

output "kubeconfig_context" {
  description = "kubectl context name for accessing the cluster (use: aws eks update-kubeconfig --name <cluster_name>)"
  value       = "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${aws_eks_cluster.main.name}"
}

output "autobots_gitops_ready" {
  description = "Flag indicating cluster is ready for GitOps deployment (ArgoCD, Flux, etc)"
  value       = aws_eks_cluster.main.status == "ACTIVE" && aws_eks_node_group.default.status == "ACTIVE"
}
