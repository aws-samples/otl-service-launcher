# -----------------------------------------------------------------------------
# Region EKS cluster
# -----------------------------------------------------------------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.iam_eks_service_role.arn

  version = var.kubernetes_version

  enabled_cluster_log_types = ["api", "audit"]

  vpc_config {
    endpoint_public_access  = false
    endpoint_private_access = true
    subnet_ids              = var.cluster_subnet_ids
  }

#  kubernetes_network_config {
#    service_ipv4_cidr = var.service_ipv4_cidr
#  }

  outpost_config {
    control_plane_instance_type = var.instance_type
    outpost_arns                = var.outpost_arn
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
# IAM roles and policies
# -----------------------------------------------------------------------------

# IAM role for the EKS Service
resource "aws_iam_role" "iam_eks_service_role" {
  name               = "${var.cluster_name}-eks-service-role"
  assume_role_policy = file("${path.module}/iam_eks_assume_role_policy.json")

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "amazon_eks_local_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLocalOutpostClusterPolicy"
  role       = aws_iam_role.iam_eks_service_role.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.iam_eks_service_role.name
}
