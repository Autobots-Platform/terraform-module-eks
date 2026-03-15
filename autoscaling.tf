# ============================================================================
# Cluster Autoscaler IAM Role (IRSA)
# ============================================================================

resource "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  name  = "${local.name_prefix}-cluster-autoscaler"

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
            "${local.oidc_provider_name}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
            "${local.oidc_provider_name}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.common_resource_tags

  depends_on = [aws_iam_openid_connect_provider.cluster]
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  count  = var.enable_cluster_autoscaler ? 1 : 0
  name   = "${local.name_prefix}-cluster-autoscaler-policy"
  role   = aws_iam_role.cluster_autoscaler[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
          }
        }
      }
    ]
  })
}

# ============================================================================
# Cluster Autoscaler Deployment Configuration (Output for GitOps)
# ============================================================================

locals {
  cluster_autoscaler_helm_values = var.enable_cluster_autoscaler ? {
    autoDiscovery = {
      clusterName = var.cluster_name
      enabled     = true
    }
    awsRegion = data.aws_region.current.name
    rbac = {
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler[0].arn
        }
        create = true
        name   = "cluster-autoscaler"
      }
    }
  } : {}
}

# ============================================================================
# Metrics Server IAM Role (IRSA) for HPA
# ============================================================================

resource "aws_iam_role" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0
  name  = "${local.name_prefix}-metrics-server"

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
            "${local.oidc_provider_name}:sub" = "system:serviceaccount:kube-system:metrics-server"
            "${local.oidc_provider_name}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.common_resource_tags

  depends_on = [aws_iam_openid_connect_provider.cluster]
}

# Metrics server typically only needs read permissions for metrics
resource "aws_iam_role_policy" "metrics_server" {
  count  = var.enable_metrics_server ? 1 : 0
  name   = "${local.name_prefix}-metrics-server-policy"
  role   = aws_iam_role.metrics_server[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# EBS CSI Driver IAM Role (IRSA)
# ============================================================================

resource "aws_iam_role" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0
  name  = "${local.name_prefix}-ebs-csi-driver"

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
            "${local.oidc_provider_name}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${local.oidc_provider_name}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.common_resource_tags

  depends_on = [aws_iam_openid_connect_provider.cluster]
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  count      = var.enable_ebs_csi_driver ? 1 : 0
  role       = aws_iam_role.ebs_csi_driver[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
