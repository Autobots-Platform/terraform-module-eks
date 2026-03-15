# ============================================================================
# EKS Cluster Security Group
# ============================================================================

resource "aws_security_group" "cluster" {
  count       = var.create_cluster_security_group ? 1 : 0
  name        = local.cluster_sg_name
  description = "Security group for ${var.cluster_name} EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_resource_tags,
    { Name = local.cluster_sg_name }
  )
}

resource "aws_security_group_rule" "cluster_ingress_workstation_https" {
  count             = var.create_cluster_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = data.aws_subnets.private.cidr_blocks
  security_group_id = aws_security_group.cluster[0].id
  description       = "Allow HTTPS from private subnets"
}

# ============================================================================
# EKS Cluster
# ============================================================================

resource "aws_eks_cluster" "main" {
  name            = var.cluster_name
  version         = var.kubernetes_version
  role_arn        = aws_iam_role.cluster.arn
  enabled_cluster_log_types = var.cluster_enabled_log_types

  vpc_config {
    subnet_ids              = concat(local.control_plane_subnet_ids, var.private_subnet_ids)
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access ? var.cluster_endpoint_public_access_cidrs : []
    security_group_ids      = var.create_cluster_security_group ? [aws_security_group.cluster[0].id] : var.additional_security_group_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_resource_controller,
  ]

  tags = local.common_resource_tags
}

# ============================================================================
# CloudWatch Log Group for EKS Cluster Logs
# ============================================================================

resource "aws_cloudwatch_log_group" "cluster" {
  name              = local.cluster_log_group_name
  retention_in_days = var.cloudwatch_log_group_retention_in_days

  tags = merge(
    local.common_resource_tags,
    { Name = local.cluster_log_group_name }
  )
}

# ============================================================================
# Node Security Group
# ============================================================================

resource "aws_security_group" "node" {
  name        = local.node_sg_name
  description = "Security group for ${var.cluster_name} EKS nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_resource_tags,
    { Name = local.node_sg_name }
  )
}

resource "aws_security_group_rule" "node_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.node.id
  description       = "Allow all TCP from nodes"
}

resource "aws_security_group_rule" "node_ingress_cluster" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = var.create_cluster_security_group ? aws_security_group.cluster[0].id : null
  security_group_id        = aws_security_group.node.id
  description              = "Allow from cluster security group"
}

resource "aws_security_group_rule" "node_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node.id
  description       = "Allow all outbound traffic"
}

# ============================================================================
# EKS Managed Node Group
# ============================================================================

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name_prefix}-default-ng"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = local.node_group.instance_types
  capacity_type  = local.node_group.capacity_type
  disk_size      = local.node_group.disk_size

  scaling_config {
    desired_size = local.node_group.desired_size
    min_size     = local.node_group.min_size
    max_size     = local.node_group.max_size
  }

  vpc_config {
    security_groups = [aws_security_group.node.id]
  }

  tags = merge(
    local.common_resource_tags,
    {
      NodeGroup = "default"
      CapacityType = local.node_group.capacity_type
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.node_eks_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_container_registry,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# EKS Cluster Add-ons
# ============================================================================

resource "aws_eks_addon" "default" {
  for_each = { for k, v in local.addons_to_install : k => v if v != null }

  cluster_name             = aws_eks_cluster.main.name
  addon_name               = each.value.name
  addon_version            = each.value.version
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                 = false

  tags = merge(
    local.common_resource_tags,
    { Addon = each.value.name }
  )

  depends_on = [aws_eks_node_group.default]
}

# ============================================================================
# Container Insights Monitoring (Optional)
# ============================================================================

resource "aws_cloudwatch_log_group" "container_insights" {
  count             = var.enable_container_insights ? 1 : 0
  name              = "/aws/containerinsights/${var.cluster_name}/performance"
  retention_in_days = var.cloudwatch_log_group_retention_in_days

  tags = merge(
    local.common_resource_tags,
    { Name = "/aws/containerinsights/${var.cluster_name}/performance" }
  )
}
