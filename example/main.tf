# ============================================================================
# Example: Autobots EKS Module Usage
# ============================================================================
# This example demonstrates a production-ready EKS cluster configuration
# using the autobots-eks Terraform module.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }

  # Uncomment for remote state (adjust bucket and key as needed)
  # backend "s3" {
  #   bucket         = "my-terraform-state"
  #   key            = "autobots-eks/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "Autobots"
      CreatedBy = "Terraform"
      Module    = "autobots-eks"
    }
  }
}

# ============================================================================
# VPC and Network Setup (Pre-existing, referenced here)
# ============================================================================

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["autobots-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Type"
    values = ["Private"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# ============================================================================
# EKS Cluster Module Instantiation
# ============================================================================

module "eks" {
  source = "../"  # Point to the module root directory

  # Cluster Configuration
  cluster_name       = var.cluster_name
  environment        = var.environment
  kubernetes_version = var.kubernetes_version
  aws_region         = var.aws_region

  # Network Configuration
  vpc_id             = data.aws_vpc.main.id
  private_subnet_ids = data.aws_subnets.private.ids

  # Node Group Configuration
  node_group_config = {
    instance_types = var.node_instance_types
    desired_size   = var.node_desired_size
    min_size       = var.node_min_size
    max_size       = var.node_max_size
    disk_size      = 100
    capacity_type  = var.use_spot_instances ? "SPOT" : "ON_DEMAND"
  }

  # Feature Flags
  enable_cluster_autoscaler = true
  enable_metrics_server     = true
  enable_ebs_csi_driver     = true
  enable_efs_csi_driver     = false
  enable_container_insights = true
  enable_irsa               = true

  # Security Configuration
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false  # Private cluster for production

  # Observability
  cloudwatch_log_group_retention_in_days = 30
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Tagging
  common_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      Module      = "autobots-eks"
    }
  )

  # Optional: Cluster access entries for RBAC
  cluster_access_entries = {
    platform_admin = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AdminRole"
      type          = "STANDARD"
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    }
  }
}

# ============================================================================
# Outputs for Downstream Consumption
# ============================================================================

output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_arn" {
  description = "ARN of the OIDC issuer for IRSA"
  value       = module.eks.cluster_oidc_issuer_arn
}

output "node_security_group_id" {
  description = "Security group ID of the EKS nodes"
  value       = module.eks.node_security_group_id
}

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler"
  value       = module.eks.cluster_autoscaler_role_arn
}

output "kubeconfig_update_command" {
  description = "Command to update kubeconfig for cluster access"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "autobots_gitops_ready" {
  description = "Cluster is ready for GitOps deployment"
  value       = module.eks.autobots_gitops_ready
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_caller_identity" "current" {
  description = "Current AWS account info for RBAC configuration"
}
