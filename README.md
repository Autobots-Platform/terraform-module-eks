# Autobots EKS Terraform Module

A production-ready, enterprise-grade Terraform module for provisioning and managing Amazon EKS (Elastic Kubernetes Service) clusters on AWS. Designed with security, observability, and GitOps principles at its core.

**Part of the Autobots Platform** — A modular cloud platform architecture for Kubernetes-based workloads on AWS.

## ?? Features

- ? **Production-Ready EKS Cluster** — Managed Kubernetes with automatic patch management
- ?? **Security by Design** — IAM roles, IRSA (IAM Roles for Service Accounts), security groups, RBAC
- ?? **Observability Built-in** — CloudWatch Container Insights, CloudWatch Logs, Prometheus support
- ?? **GitOps Ready** — Pre-configured for ArgoCD, Flux, or other GitOps controllers
- ??? **Auto-Scaling** — Cluster Autoscaler IRSA, HPA support with Metrics Server
- ?? **Storage Support** — EBS CSI Driver for persistent volumes, EFS CSI Driver option
- ?? **Network Security** — Private control plane, VPC isolation, security group management
- ??? **Tagging Strategy** — Comprehensive tagging for cost allocation and resource management
- ?? **Add-on Management** — AWS-managed add-ons (CoreDNS, VPC-CNI, Kube-Proxy, EBS CSI, etc.)

## ?? Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| AWS Provider | >= 6.0.0 |
| AWS CLI | Latest (for kubeconfig setup) |
| kubectl | >= 1.27 (for cluster access) |

## ?? Dependencies

This module depends on:
- **terraform-aws-modules/eks/aws** (implicitly used for best practices, but module is self-contained)
- **hashicorp/aws** provider >= 6.0.0
- **hashicorp/tls** provider (for IRSA certificate validation)

## ?? Quick Start

### Basic Usage

```hcl
module "eks" {
  source = "github.com/Autobots-Platform/terraform-module-eks"

  # Cluster configuration
  cluster_name    = "my-cluster"
  environment     = "dev"
  kubernetes_version = "1.31"
  aws_region      = "us-east-1"

  # Network configuration
  vpc_id              = aws_vpc.main.id
  private_subnet_ids  = [aws_subnet.private1.id, aws_subnet.private2.id, aws_subnet.private3.id]

  # Node group configuration
  node_group_config = {
    instance_types = ["t3.medium"]
    desired_size   = 2
    min_size       = 2
    max_size       = 4
    disk_size      = 100
    capacity_type  = "ON_DEMAND"
  }

  # Features
  enable_cluster_autoscaler = true
  enable_metrics_server     = true
  enable_ebs_csi_driver     = true
  enable_container_insights = true

  # Tagging
  common_tags = {
    Project   = "Autobots"
    Owner     = "Platform-Engineering"
    CostCenter = "Platform"
  }
}

# Update kubeconfig to access cluster
# Run: aws eks update-kubeconfig --name my-cluster --region us-east-1
```

### Production Configuration (Multi-AZ, Spot Instances, Security Hardened)

```hcl
module "eks_prod" {
  source = "github.com/Autobots-Platform/terraform-module-eks"

  cluster_name    = "production-cluster"
  environment     = "prod"
  kubernetes_version = "1.31"
  aws_region      = "us-east-1"

  vpc_id             = aws_vpc.production.id
  private_subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id,
    aws_subnet.private_az3.id
  ]

  # High availability: multiple AZs, larger node groups
  node_group_config = {
    instance_types = ["t3.large", "t3a.large"]  # Multiple instance types for flexibility
    desired_size   = 3
    min_size       = 3
    max_size       = 10
    disk_size      = 150
    capacity_type  = "ON_DEMAND"
  }

  # Security hardening
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false  # Private cluster
  enable_irsa                     = true
  iam_role_permissions_boundary   = aws_iam_policy.boundary.arn

  # Observability
  enable_container_insights           = true
  cloudwatch_log_group_retention_in_days = 60
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Platform integrations
  enable_cluster_autoscaler = true
  enable_metrics_server     = true
  enable_ebs_csi_driver     = true
  enable_efs_csi_driver     = true

  common_tags = {
    Project     = "Autobots"
    Owner       = "Platform-Engineering"
    Environment = "production"
    CostCenter  = "Platform"
    Compliance  = "SOC2"
  }
}
```

## ?? Input Variables

### Core Cluster Variables

| Variable | Type | Default | Required | Description |
|----------|------|---------|:--------:|-------------|
| `cluster_name` | string | - | ? | Name of the EKS cluster (alphanumeric, max 100 chars) |
| `environment` | string | - | ? | Environment tier (dev, staging, prod) |
| `aws_region` | string | - | ? | AWS region for deployment |
| `kubernetes_version` | string | "1.31" | ? | Kubernetes version (e.g., 1.30, 1.31) |

### Network Configuration

| Variable | Type | Default | Required | Description |
|----------|------|---------|:--------:|-------------|
| `vpc_id` | string | - | ? | VPC ID where cluster is deployed |
| `private_subnet_ids` | list(string) | - | ? | Min 2 private subnets for HA |
| `control_plane_subnet_ids` | list(string) | null | ? | Explicit control plane subnets (defaults to private_subnet_ids) |
| `cluster_endpoint_private_access` | bool | true | ? | Enable private API endpoint |
| `cluster_endpoint_public_access` | bool | false | ? | Enable public API endpoint |

### Node Group Configuration

| Variable | Type | Default | Required | Description |
|----------|------|---------|:--------:|-------------|
| `node_group_config` | object | See defaults | ? | Node group sizing and instance types |
| `enable_spot_instances` | bool | false | ? | Use Spot instances for cost optimization |
| `max_pods_per_node` | number | 110 | ? | Maximum pods per node (affects ENI allocation) |

### Feature Flags

| Variable | Type | Default | Required | Description |
|----------|------|---------|:--------:|-------------|
| `enable_cluster_autoscaler` | bool | true | ? | Deploy Cluster Autoscaler via IRSA |
| `enable_metrics_server` | bool | true | ? | Deploy Metrics Server for HPA |
| `enable_ebs_csi_driver` | bool | true | ? | Deploy EBS CSI Driver for persistent volumes |
| `enable_efs_csi_driver` | bool | false | ? | Deploy EFS CSI Driver for shared storage |
| `enable_container_insights` | bool | true | ? | Enable CloudWatch Container Insights |
| `prometheus_scrape_config` | bool | false | ? | Enable ServiceMonitor for Prometheus |

### Security & Access

| Variable | Type | Default | Required | Description |
|----------|------|---------|:--------:|-------------|
| `enable_irsa` | bool | true | ? | Enable IAM Roles for Service Accounts |
| `cluster_access_entries` | map(any) | {} | ? | Map of IAM principals to cluster access |
| `iam_role_permissions_boundary` | string | null | ? | ARN of permissions boundary policy |

See [variables.tf](./variables.tf) for complete list.

## ?? Outputs

Key outputs for downstream consumption:

```hcl
# Cluster identification
cluster_id                              # Cluster ID
cluster_name                            # Cluster name
cluster_endpoint                        # API server endpoint
cluster_arn                             # Cluster ARN
cluster_version                         # Kubernetes version

# IRSA & Authentication
cluster_oidc_issuer_url                 # OIDC issuer for IRSA
cluster_oidc_issuer_arn                 # OIDC provider ARN
cluster_certificate_authority_data      # CA certificate (base64)

# IAM Roles
cluster_iam_role_arn                    # Cluster control plane role ARN
node_iam_role_arn                       # Node role ARN

# Security Groups
cluster_security_group_id               # Control plane SG ID
node_security_group_id                  # Node SG ID

# Node Group
node_group_id                           # Node group ID
node_group_arn                          # Node group ARN
node_group_status                       # Node group status

# Add-ons
cluster_addons                          # Map of installed add-ons

# Networking
vpc_id                                  # VPC where cluster deployed
private_subnet_ids                      # Private subnet IDs
control_plane_subnet_ids                # Control plane subnet IDs

# CloudWatch
cluster_log_group_name                  # CloudWatch log group
cluster_log_group_arn                   # Log group ARN

# GitOps Integration
autobots_gitops_ready                   # Boolean: cluster ready for GitOps
kubeconfig_context                      # kubectl context ARN
```

## ?? Security Features

### IAM Roles for Service Accounts (IRSA)
Workloads can assume IAM roles for fine-grained permissions without managing keys:

```hcl
# Cluster Autoscaler, Metrics Server, EBS CSI Driver, Container Insights
# all use IRSA for secure credential-less authentication
```

### Network Security
- Private control plane by default (`cluster_endpoint_private_access = true`)
- Optional public access with CIDR restrictions
- Node security groups restrict ingress/egress
- VPC isolation via subnets

### RBAC & Access Control
- Cluster access entries for granular IAM principal mapping
- Support for access policies (Admin, PowerUser, Viewer, etc.)

### Audit Logging
- CloudWatch audit logs for cluster API calls
- Authenticator logs for authentication events
- Controller Manager & Scheduler logs

## ?? Observability

### CloudWatch Container Insights
Automatic metrics collection and visualization:
- Pod CPU, memory, network metrics
- Container restart counts
- Node resource utilization

### CloudWatch Logs
Structured cluster logs available in CloudWatch Logs Console:
- **Cluster logs** — `/aws/eks/{cluster_name}`
- **Container Insights** — `/aws/containerinsights/{cluster_name}/performance`
- **Retention policy** — Configurable (default: 30 days)

### Prometheus Integration
ServiceMonitor support for Prometheus Operator:
```yaml
# Deploy Prometheus Operator and it will auto-discover ServiceMonitors
# Configure scrape intervals and retention policies in your Prometheus stack
```

## ?? GitOps Integration

### ArgoCD / Flux Readiness
The module outputs `autobots_gitops_ready` flag to indicate cluster is fully provisioned:

```hcl
output "autobots_gitops_ready" {
  value = aws_eks_cluster.main.status == "ACTIVE" && 
          aws_eks_node_group.default.status == "ACTIVE"
}
```

### Next Steps After Cluster Creation
1. Update kubeconfig: `aws eks update-kubeconfig --name <cluster_name>`
2. Deploy GitOps controller (ArgoCD, Flux)
3. Install Prometheus/Grafana for monitoring
4. Configure network policies and RBAC

## ??? Development & Testing

### Pre-commit Hooks
Ensure code quality before commits:

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

### Terraform Validation
```bash
terraform init
terraform validate
terraform fmt -recursive .
terraform plan
terraform apply
```

## ?? Examples

See the `example/` directory for complete, runnable configurations:
- Basic cluster deployment
- Production-hardened setup
- Multi-environment setup

## ?? Contributing

Contributions are welcome! Please follow:
1. Conventional Commits (feat:, fix:, docs:, etc.)
2. Terraform style guide (terraform fmt)
3. Code review process via pull requests

## ?? License

MIT License — See LICENSE file

## ????? Maintainers

**Autobots Platform Engineering Team**

- GitHub Organization: https://github.com/Autobots-Platform
- Documentation: [Autobots Platform Docs](https://github.com/Autobots-Platform)

---

**? If you find this module useful, star the repository!**
