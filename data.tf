# ============================================================================
# AWS Account and Region Data
# ============================================================================

data "aws_caller_identity" "current" {
  description = "Get current AWS account ID and ARN for IAM role trust relationships"
}

data "aws_region" "current" {
  description = "Get current AWS region details"
}

# ============================================================================
# VPC and Network Data
# ============================================================================

data "aws_vpc" "cluster_vpc" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "subnet-id"
    values = var.private_subnet_ids
  }
}

# ============================================================================
# EKS Add-on Versions (fetches latest compatible versions)
# ============================================================================

data "aws_eks_addon_version" "coredns" {
  addon_name             = "coredns"
  kubernetes_version     = var.kubernetes_version
  most_recent            = true
}

data "aws_eks_addon_version" "kube_proxy" {
  addon_name             = "kube-proxy"
  kubernetes_version     = var.kubernetes_version
  most_recent            = true
}

data "aws_eks_addon_version" "vpc_cni" {
  addon_name             = "vpc-cni"
  kubernetes_version     = var.kubernetes_version
  most_recent            = true
}

data "aws_eks_addon_version" "ebs_csi" {
  count                  = var.enable_ebs_csi_driver ? 1 : 0
  addon_name             = "aws-ebs-csi-driver"
  kubernetes_version     = var.kubernetes_version
  most_recent            = true
}

data "aws_eks_addon_version" "efs_csi" {
  count                  = var.enable_efs_csi_driver ? 1 : 0
  addon_name             = "aws-efs-csi-driver"
  kubernetes_version     = var.kubernetes_version
  most_recent            = true
}

data "aws_eks_addon_version" "guardduty" {
  count                  = true
  addon_name             = "aws-guardduty-agent"
  kubernetes_version     = var.kubernetes_version
  most_recent            = true
}

# ============================================================================
# AMI Data for EKS-optimized nodes (for reference, nodes use managed AMI by default)
# ============================================================================

data "aws_ami" "eks_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.kubernetes_version}-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
