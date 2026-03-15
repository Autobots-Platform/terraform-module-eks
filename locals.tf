locals {
  # Naming conventions for Autobots platform
  name_prefix = "${var.cluster_name}-${var.environment}"
  
  # Derive control plane subnets if not explicitly provided
  control_plane_subnet_ids = var.control_plane_subnet_ids != null ? var.control_plane_subnet_ids : var.private_subnet_ids

  # IAM role naming
  cluster_iam_role_name = "${local.name_prefix}-cluster-role"
  node_iam_role_name    = "${local.name_prefix}-node-role"

  # Security group naming
  cluster_sg_name = "${local.name_prefix}-cluster-sg"
  node_sg_name    = "${local.name_prefix}-node-sg"

  # Log group naming
  cluster_log_group_name = "/aws/eks/${var.cluster_name}"

  # OIDC provider naming for IRSA
  oidc_provider_name = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")

  # Common tags for all resources
  common_resource_tags = merge(
    var.common_tags,
    var.cluster_tags,
    {
      ClusterName = var.cluster_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  # Node group configuration defaults
  node_group = {
    instance_types = var.node_group_config.instance_types
    desired_size   = var.node_group_config.desired_size
    min_size       = var.node_group_config.min_size
    max_size       = var.node_group_config.max_size
    disk_size      = var.node_group_config.disk_size
    capacity_type  = var.enable_spot_instances ? "SPOT" : var.node_group_config.capacity_type
  }

  # Add-on configuration map
  addons_to_install = {
    coredns = {
      name    = "coredns"
      version = data.aws_eks_addon_version.coredns.version
    }
    kube-proxy = {
      name    = "kube-proxy"
      version = data.aws_eks_addon_version.kube_proxy.version
    }
    vpc-cni = {
      name    = "vpc-cni"
      version = data.aws_eks_addon_version.vpc_cni.version
    }
    ebs-csi-driver = var.enable_ebs_csi_driver ? {
      name    = "aws-ebs-csi-driver"
      version = data.aws_eks_addon_version.ebs_csi[0].version
    } : null
    efs-csi-driver = var.enable_efs_csi_driver ? {
      name    = "aws-efs-csi-driver"
      version = data.aws_eks_addon_version.efs_csi[0].version
    } : null
    aws-guardduty-agent = {
      name    = "aws-guardduty-agent"
      version = data.aws_eks_addon_version.guardduty[0].version
    }
  }
}
