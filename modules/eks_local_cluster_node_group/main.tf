# -----------------------------------------------------------------------------
# EKS on Outposts self-managed node group
# -----------------------------------------------------------------------------
resource "aws_autoscaling_group" "eks_outposts_node_group" {
  name               = "${var.cluster_name}-${var.node_group_name}-nodes"
  availability_zones = [data.aws_subnet.outpost_subnet.availability_zone]
  desired_capacity   = var.desired_capacity
  min_size           = var.min_size
  max_size           = var.max_size

  #provider = kubernetes.cluster2  

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"

  }



  tags = concat(
    [for tag, value in var.tags : {
      key                 = tag
      value               = value
      propagate_at_launch = true
    }],
    [
      {
        key                 = "Name"
        value               = "${var.cluster_name}-${var.node_group_name}-node"
        propagate_at_launch = true
      },
#      {
#        key                 = "kubernetes.io/cluster/${var.cluster_name}"
#        value               = "owned"
#        propagate_at_launch = true
#      },
    ]
  )

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
  ]
}

resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${var.cluster_name}-${var.node_group_name}-node"
  description = "Amazon EKS on Outposts self-managed node launch template"

  #provider = kubernetes.cluster2  
  image_id      = data.aws_ami.eks_node.id
  instance_type = var.instance_type
  user_data     = base64encode(data.template_file.user_data.rendered)

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
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
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
    values = ["amazon-eks-node-${var.kubernetes_version}*"]
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

data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")
  vars = {
    cluster_name = var.cluster_name
  }
}


# -----------------------------------------------------------------------------
# IAM roles and policies
# -----------------------------------------------------------------------------

# IAM instance profile and role for the self-managed node group
resource "aws_iam_instance_profile" "eks_outposts_node_group" {
  name = "${var.cluster_name}-eks-node-group-instance-profile"
  role = aws_iam_role.eks_outposts_node_group.name
  #provider = kubernetes.cluster2  
}

resource "aws_iam_role" "eks_outposts_node_group" {
  name               = "${var.cluster_name}-${var.node_group_name}-eks-node-group-role"
  assume_role_policy = file("${path.module}/iam_ec2_assume_role_policy.json")
  #provider = kubernetes.cluster2  
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_outposts_node_group.name
  #provider = kubernetes.cluster2  
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_outposts_node_group.name
  #provider = kubernetes.cluster2  
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_outposts_node_group.name
  #provider = kubernetes.cluster2  
}


# -----------------------------------------------------------------------------
# Kubernetes cluster configuration
# -----------------------------------------------------------------------------

# Apply the AWS IAM Authenticator configuration map to enable nodes to join the 
# cluster from within the private VPC.
# https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
resource "kubernetes_config_map" "aws_auth" {
  provider = kubernetes.local_cluster 
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = templatefile(
      "${path.module}/aws-auth-config-map-data-map-roles.yaml",
      {
        eks_outposts_node_group_iam_role = aws_iam_role.eks_outposts_node_group.arn
      }
    )
  }
}
