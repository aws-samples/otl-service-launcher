# -----------------------------------------------------------------------------
# Region EKS cluster
# -----------------------------------------------------------------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.username}-eks-cluster"
  role_arn = aws_iam_role.iam_eks_service_role.arn

  version = var.kubernetes_version

  enabled_cluster_log_types = ["api", "audit"]

  vpc_config {
    subnet_ids = var.region_public_subnet_ids
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr
  }

  tags = var.tags

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy,
    aws_iam_role_policy_attachment.amazon_eks_vpc_resource_controller,
  ]
}


# -----------------------------------------------------------------------------
# Outpost EKS node group
# -----------------------------------------------------------------------------
resource "aws_eks_node_group" "outpost_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.username}-eks-outpost-node-group"
  node_role_arn   = aws_iam_role.iam_eks_node_group_role.arn

  subnet_ids     = var.outpost_private_subnet_ids
  instance_types = var.instance_types

  scaling_config {
    desired_size = var.node_count
    max_size     = var.node_count
    min_size     = var.node_count
  }

  tags = var.tags

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
  ]
}


# -----------------------------------------------------------------------------
# CloudWatch control plane logging
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${aws_eks_cluster.eks_cluster.name}/cluster"
  retention_in_days = 7

  tags = var.tags
}


# -----------------------------------------------------------------------------
# IAM roles and policies
# -----------------------------------------------------------------------------

# IAM role for the EKS Service
resource "aws_iam_role" "iam_eks_service_role" {
  name               = "${var.username}-eks-service-role"
  assume_role_policy = file("${path.module}/iam_eks_assume_role_policy.json")

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.iam_eks_service_role.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.iam_eks_service_role.name
}


# IAM role for the EKS Node Group
resource "aws_iam_role" "iam_eks_node_group_role" {
  name               = "${var.username}-eks-node-group-role"
  assume_role_policy = file("${path.module}/iam_ec2_assume_role_policy.json")
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.iam_eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.iam_eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.iam_eks_node_group_role.name
}
