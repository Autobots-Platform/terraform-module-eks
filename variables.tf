# ============================================================================
# Core Cluster Variables
# ============================================================================

variable "aws_region" {
  description = "AWS region where the EKS cluster will be deployed"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  validation {
    condition     = length(var.cluster_name) <= 100 && can(regex("^[a-zA-Z0-9-]+$", var.cluster_name))
    error_message = "Cluster name must be alphanumeric with hyphens, max 100 chars."
  }
}

variable "environment" {
  description = "Environment tier (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version to deploy (e.g., 1.30, 1.31)"
  type        = string
  default     = "1.31"
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS cluster nodes and ENIs"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
}

variable "control_plane_subnet_ids" {
  description = "Optional: Subnet IDs for control plane (defaults to private_subnet_ids)"
  type        = list(string)
  default     = null
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access public endpoint (required if public access enabled)"
  type        = list(string)
  default     = []
}

# ============================================================================
# Node Group Configuration
# ============================================================================

variable "node_group_config" {
  description = "Configuration for the default EKS managed node group"
  type = object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
    capacity_type  = string # ON_DEMAND or SPOT
  })
  default = {
    instance_types = ["t3.medium"]
    desired_size   = 2
    min_size       = 2
    max_size       = 4
    disk_size      = 100
    capacity_type  = "ON_DEMAND"
  }
}

variable "enable_spot_instances" {
  description = "Enable Spot instances for cost optimization"
  type        = bool
  default     = false
}

variable "max_pods_per_node" {
  description = "Maximum number of pods per node (constrains CNI)"
  type        = number
  default     = 110
}

# ============================================================================
# Add-on and Observability Configuration
# ============================================================================

variable "enable_cluster_autoscaler" {
  description = "Deploy cluster autoscaler via IRSA"
  type        = bool
  default     = true
}

variable "enable_metrics_server" {
  description = "Deploy metrics-server for HPA and monitoring"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver" {
  description = "Deploy AWS EBS CSI driver for persistent volumes"
  type        = bool
  default     = true
}

variable "enable_efs_csi_driver" {
  description = "Deploy AWS EFS CSI driver for shared storage"
  type        = bool
  default     = false
}

variable "cluster_enabled_log_types" {
  description = "List of EKS control plane log types to enable for CloudWatch"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 30
}

# ============================================================================
# Security and Access Control
# ============================================================================

variable "create_cluster_security_group" {
  description = "Whether to create a dedicated security group for the cluster"
  type        = bool
  default     = true
}

variable "additional_security_group_ids" {
  description = "Additional security groups to attach to cluster control plane and nodes"
  type        = list(string)
  default     = []
}

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = true
}

variable "cluster_access_entries" {
  description = "Map of IAM principals to cluster access entries (for granular RBAC)"
  type        = map(any)
  default     = {}
}

variable "iam_role_permissions_boundary" {
  description = "ARN of IAM permissions boundary policy for node IAM role"
  type        = string
  default     = null
}

# ============================================================================
# Monitoring and GitOps Integration
# ============================================================================

variable "prometheus_scrape_config" {
  description = "Enable ServiceMonitor creation for Prometheus scraping (requires Prometheus Operator)"
  type        = bool
  default     = false
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for cluster monitoring"
  type        = bool
  default     = true
}

variable "gitops_repository" {
  description = "URL of GitOps repository (e.g., ArgoCD source)"
  type        = string
  default     = ""
}

# ============================================================================
# Tagging and Metadata
# ============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    "Project" = "Autobots"
    "Owner"   = "Platform-Engineering"
  }
}

variable "cluster_tags" {
  description = "Additional tags specific to the EKS cluster"
  type        = map(string)
  default     = {}
}
