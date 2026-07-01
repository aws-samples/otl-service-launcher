# -----------------------------------------------------------------------------
# EKS on Outposts self-managed node group
# -----------------------------------------------------------------------------
resource "aws_autoscaling_group" "eks_outposts_node_group" {
  name               = "${var.cluster_name}-${var.node_group_name}-nodes"
  availability_zones = [data.aws_subnet.outpost_subnet.availability_zone]
  desired_capacity   = var.desired_capacity
  min_size           = var.min_size
  max_size           = var.max_size

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.tags, {
      "Name"                                      = "${var.cluster_name}-${var.node_group_name}-node"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
  ]
}

resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${var.cluster_name}-${var.node_group_name}-node"
  description = "Amazon EKS on Outposts self-managed node launch template"

  image_id      = data.aws_ami.eks_node.id
  instance_type = var.instance_type
  user_data     = base64encode(local.user_data)

  iam_instance_profile {
    arn = aws_iam_instance_profile.eks_outposts_node_group.arn
  }

  block_device_mappings {
    device_name = var.volume_device_name

    ebs {
      volume_type           = var.volume_type
      volume_size           = var.volume_size
      delete_on_termination = true
    }
  }

  network_interfaces {
    delete_on_termination = true
    subnet_id             = var.outpost_subnet_id
    security_groups       = [var.security_group]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = var.tags
}

data "aws_subnet" "outpost_subnet" {
  id = var.outpost_subnet_id
}

data "aws_ami" "eks_node" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-al2023-x86_64-standard-${var.kubernetes_version}*"]
  }

  filter {
    name   = "virtualization-type"
    values = [var.virtualization_type]
  }

  filter {
    name   = "architecture"
    values = [var.architecture]
  }

  filter {
    name   = "root-device-type"
    values = [var.root_device_type]
  }
}

locals {
  use_cluster_id = var.cluster_id != ""
  user_data = templatefile("${path.module}/user_data_al2023.sh", {
    cluster_id       = local.use_cluster_id ? var.cluster_id : var.cluster_name
    cluster_endpoint = var.cluster_endpoint
    cluster_ca       = var.cluster_ca
    service_cidr     = var.service_cidr
  })
}


# -----------------------------------------------------------------------------
# IAM roles and policies
# -----------------------------------------------------------------------------

# IAM instance profile and role for the self-managed node group
resource "aws_iam_instance_profile" "eks_outposts_node_group" {
  name = "${var.cluster_name}-eks-node-group-instance-profile"
  role = aws_iam_role.eks_outposts_node_group.name
}

resource "aws_iam_role" "eks_outposts_node_group" {
  name               = "${var.cluster_name}-${var.node_group_name}-eks-node-group-role"
  assume_role_policy = file("${path.module}/iam_ec2_assume_role_policy.json")
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_outposts_node_group.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_outposts_node_group.name
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_outposts_node_group.name
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_outposts_node_group.name
}

# -----------------------------------------------------------------------------
# Kubernetes cluster configuration
# -----------------------------------------------------------------------------

# Apply the AWS IAM Authenticator configuration map to enable nodes to join the 
# cluster from within the private VPC.
# https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
# aws-auth ConfigMap is patched via the node's userdata script.
# The node applies the configmap on first boot since it has network access
# to the local cluster API server (Terraform/laptop cannot reach it).
