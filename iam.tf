# ============================================================================
# EKS Cluster IAM Role
# ============================================================================

resource "aws_iam_role" "cluster" {
  name               = local.cluster_iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_resource_tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# ============================================================================
# EKS Node IAM Role
# ============================================================================

resource "aws_iam_role" "node" {
  name               = local.node_iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  permissions_boundary = var.iam_role_permissions_boundary

  tags = local.common_resource_tags
}

resource "aws_iam_role_policy_attachment" "node_eks_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ssm_session" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cloudwatch_agent" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node.name
}

# ============================================================================
# OIDC Provider for IRSA (IAM Roles for Service Accounts)
# ============================================================================

resource "aws_iam_openid_connect_provider" "cluster" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = local.common_resource_tags
}

data "tls_certificate" "cluster" {
  count = var.enable_irsa ? 1 : 0
  url   = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# ============================================================================
# Cluster Access Entries (for fine-grained RBAC)
# ============================================================================

resource "aws_eks_access_entry" "cluster_admin" {
  for_each = var.cluster_access_entries

  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = each.value.principal_arn
  type              = lookup(each.value, "type", "STANDARD")
  kubernetes_groups = lookup(each.value, "kubernetes_groups", [])
}

resource "aws_eks_access_policy_association" "cluster_admin" {
  for_each = var.cluster_access_entries

  access_scope {
    type       = "cluster"
  }
  cluster_name      = aws_eks_cluster.main.name
  policy_arn        = lookup(each.value, "policy_arn", "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy")
  principal_arn     = each.value.principal_arn
}

# ============================================================================
# Node Instance Profile for EC2
# ============================================================================

resource "aws_iam_instance_profile" "node" {
  name = "${local.name_prefix}-node-instance-profile"
  role = aws_iam_role.node.name
}
