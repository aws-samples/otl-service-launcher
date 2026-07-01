# -----------------------------------------------------------------------------
# EKS cluster
# -----------------------------------------------------------------------------
module "eks_cluster" {
  source = "./modules/eks_cluster"
  count  = (var.eks && var.eks_cluster) ? 1 : 0

  tags = local.tags

  cluster_name = local.eks_cluster_name

  kubernetes_version = "1.33"
  service_ipv4_cidr  = "192.168.0.0/16"

  cluster_subnet_ids = [
    aws_subnet.region_az_1_private.id,
    aws_subnet.region_az_2_private.id,
  ]

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

# -----------------------------------------------------------------------------
# EKS cluster on Outpost
# -----------------------------------------------------------------------------
module "eks_on_outposts" {
  source = "./modules/eks_cluster_on_outposts"
  count  = (var.eks_cluster_on_outposts) ? 1 : 0

  tags = local.tags

  cluster_name = local.eks_local_cluster_name

  kubernetes_version = "1.32"
  service_ipv4_cidr  = "192.168.0.0/16"

  outpost_arn   = data.aws_outposts_outposts.all.arns
  instance_type = coalesce(local.allowed_outpost_instance_types...)

  cluster_subnet_ids = [
    aws_subnet.outpost_private.id,
    aws_subnet.outpost_public.id
  ]

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

module "eks_outposts_node_group" {
  source = "./modules/eks_outposts_node_group"
  count  = (var.eks && var.eks_outpost_node_group) ? 1 : 0

  tags = local.tags

  cluster_name       = local.eks_cluster_name
  cluster_endpoint   = concat(module.eks_cluster[*].cluster_endpoint, [""])[0]
  cluster_ca         = concat(module.eks_cluster[*].cluster_ca_cert, [""])[0]
  service_cidr       = "192.168.0.0/16"
  kubernetes_version = "1.33"
  outpost_subnet_id  = aws_subnet.outpost_private.id
  instance_type      = coalesce(local.allowed_outpost_instance_types...)
  security_group     = concat(module.eks_cluster[*].cluster_security_group_id, [""])[0]

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

module "eks_local_outposts_node_group" {
  source = "./modules/eks_outposts_node_group"
  count  = (var.eks_cluster_on_outposts && var.eks_outpost_node_group) ? 1 : 0

  tags = local.tags

  cluster_name       = local.eks_local_cluster_name
  cluster_id         = concat(module.eks_on_outposts[*].cluster_id, [""])[0]
  cluster_endpoint   = concat(module.eks_on_outposts[*].cluster_endpoint, [""])[0]
  cluster_ca         = concat(module.eks_on_outposts[*].cluster_ca_cert, [""])[0]
  service_cidr       = "192.168.0.0/16"
  kubernetes_version = "1.32"
  outpost_subnet_id  = aws_subnet.outpost_private.id
  instance_type      = coalesce(local.allowed_outpost_instance_types...)
  security_group     = concat(module.eks_on_outposts[*].cluster_security_group_id, [""])[0]
  admin_role_arn     = concat(aws_iam_role.bastion[*].arn, [""])[0]

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

# -----------------------------------------------------------------------------
# Bastion instance (for EKS Local Cluster management)
# Deployed in-region in the same VPC so it can reach the local cluster API
# -----------------------------------------------------------------------------
resource "aws_instance" "bastion" {
  count         = var.eks_cluster_on_outposts ? 1 : 0
  ami           = data.aws_ami.bastion_ami[0].id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.region_az_1_public.id

  iam_instance_profile = aws_iam_instance_profile.bastion[0].name
  vpc_security_group_ids = compact([
    aws_security_group.alpha.id,
    try(module.eks_on_outposts[0].cluster_security_group_id, ""),
  ])

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  user_data = base64encode(join("\n", [
    "#!/bin/bash",
    "dnf install -y jq git",
    "curl -LO \"https://dl.k8s.io/release/v1.32.0/bin/linux/amd64/kubectl\"",
    "chmod +x kubectl && mv kubectl /usr/local/bin/",
    "curl -sL \"https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz\" | tar xz -C /usr/local/bin/",
    "curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash",
    "",
    "# Pre-generate aws-auth ConfigMap for EKS Local Cluster",
    "cat > /home/ec2-user/aws-auth.yaml << 'AUTHEOF'",
    "apiVersion: v1",
    "kind: ConfigMap",
    "metadata:",
    "  name: aws-auth",
    "  namespace: kube-system",
    "data:",
    "  mapRoles: |",
    "    - rolearn: ${module.eks_local_outposts_node_group[0].node_role_arn}",
    "      username: system:node:{{EC2PrivateDNSName}}",
    "      groups:",
    "        - system:bootstrappers",
    "        - system:nodes",
    "    - rolearn: ${aws_iam_role.bastion[0].arn}",
    "      username: admin",
    "      groups:",
    "        - system:masters",
    "AUTHEOF",
    "",
    "# Pre-generate kubeconfig setup script",
    "cat > /home/ec2-user/setup-kubeconfig.sh << 'SETUPEOF'",
    "#!/bin/bash",
    "CLUSTER_NAME=\"${local.eks_local_cluster_name}\"",
    "CLUSTER_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.id' --output text --region ${var.region})",
    "aws eks update-kubeconfig --name $CLUSTER_NAME --region ${var.region}",
    "sed -i \"s/--cluster-name/--cluster-id/\" ~/.kube/config",
    "sed -i \"s/$CLUSTER_NAME/$CLUSTER_ID/\" ~/.kube/config",
    "echo \"Kubeconfig configured for local cluster (using cluster-id: $CLUSTER_ID)\"",
    "echo \"\"",
    "echo \"To authorize the node and bastion roles, run:\"",
    "echo \"  kubectl apply -f ~/aws-auth.yaml\"",
    "SETUPEOF",
    "",
    "chmod +x /home/ec2-user/setup-kubeconfig.sh",
    "chown -R ec2-user:ec2-user /home/ec2-user/aws-auth.yaml /home/ec2-user/setup-kubeconfig.sh",
    "",
  ]))

  tags = merge(local.tags, {
    Name = "${var.username}-eks-bastion"
  })

  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

data "aws_ami" "bastion_ami" {
  count       = var.eks_cluster_on_outposts ? 1 : 0
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_iam_role" "bastion" {
  count              = var.eks_cluster_on_outposts ? 1 : 0
  name               = "${var.username}-eks-bastion-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  count      = var.eks_cluster_on_outposts ? 1 : 0
  role       = aws_iam_role.bastion[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion_eks" {
  count      = var.eks_cluster_on_outposts ? 1 : 0
  role       = aws_iam_role.bastion[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy" "bastion_eks_admin" {
  count = var.eks_cluster_on_outposts ? 1 : 0
  name  = "eks-admin"
  role  = aws_iam_role.bastion[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:*", "ec2:Describe*", "iam:GetRole", "iam:ListRoles"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "bastion" {
  count = var.eks_cluster_on_outposts ? 1 : 0
  name  = "${var.username}-eks-bastion-profile"
  role  = aws_iam_role.bastion[0].name
}

# Patch aws-auth ConfigMap via SSM on the bastion (only machine with network
# access to the local cluster API). Terraform cannot reach the private endpoint.
resource "null_resource" "patch_aws_auth" {
  count = var.eks_cluster_on_outposts ? 1 : 0

  triggers = {
    cluster_id     = module.eks_on_outposts[0].cluster_id
    node_role_arn  = module.eks_local_outposts_node_group[0].node_role_arn
    bastion_role   = aws_iam_role.bastion[0].arn
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for bastion SSM agent to register
      for i in $(seq 1 30); do
        aws ssm describe-instance-information --filters Key=InstanceIds,Values=${aws_instance.bastion[0].id} --region ${var.region} --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null | grep -q Online && break
        sleep 10
      done
      # Send the kubectl patch command
      aws ssm send-command \
        --instance-ids ${aws_instance.bastion[0].id} \
        --document-name AWS-RunShellScript \
        --parameters 'commands=["aws eks update-kubeconfig --name ${local.eks_local_cluster_name} --region ${var.region} && sed -i \"s/--cluster-name/--cluster-id/\" ~/.kube/config && sed -i \"s/${local.eks_local_cluster_name}/${module.eks_on_outposts[0].cluster_id}/\" ~/.kube/config && kubectl apply -f - <<EOF\napiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: aws-auth\n  namespace: kube-system\ndata:\n  mapRoles: |\n    - rolearn: ${module.eks_local_outposts_node_group[0].node_role_arn}\n      username: system:node:{{EC2PrivateDNSName}}\n      groups:\n        - system:bootstrappers\n        - system:nodes\n    - rolearn: ${aws_iam_role.bastion[0].arn}\n      username: admin\n      groups:\n        - system:masters\nEOF"]' \
        --region ${var.region} \
        --output text
    EOT
  }

  depends_on = [
    module.eks_on_outposts,
    module.eks_local_outposts_node_group,
    aws_instance.bastion,
  ]
}

# -----------------------------------------------------------------------------
# ElastiCache clusters
# -----------------------------------------------------------------------------
module "elasticache_memcached_instance" {
  source = "./modules/elasticache"
  count  = var.memcached ? 1 : 0

  username = var.username
  tags     = local.tags

  subnet_ids = [aws_subnet.outpost_private.id]

  engine               = "memcached"
  engine_version       = "1.6.22"
  parameter_group_name = "default.memcached1.6"
  node_type            = "cache.m5.xlarge"
  num_cache_nodes      = 1

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

module "elasticache_redis_instance" {
  source = "./modules/elasticache"
  count  = var.redis ? 1 : 0

  username = var.username
  tags     = local.tags

  subnet_ids = [aws_subnet.outpost_private.id]

  engine               = "redis"
  engine_version       = "7.1"
  parameter_group_name = "default.redis7"
  node_type            = "cache.m5.xlarge"
  num_cache_nodes      = 1

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}


# -----------------------------------------------------------------------------
# EMR cluster
# -----------------------------------------------------------------------------
module "emr_cluster" {
  source = "./modules/emr"
  count  = var.emr ? 1 : 0

  username = var.username
  tags     = local.tags

  main_vpc_id = aws_vpc.main_vpc.id

  subnet_id = aws_subnet.outpost_private.id

  # EMR 7.x AMIs default to gp3 root volumes which aren't available on Outposts.
  # Setting ebs_root_volume_size forces gp2 behavior on Outposts.
  release_label = "emr-7.13.0"

  # these will be cross-checked against supported EMR instances
  # an arbitrary instance type supported by the 
  master_instance_types = local.allowed_outpost_instance_types
  core_instance_types   = local.allowed_outpost_instance_types
  core_instance_count   = 1

  # Ensure the local gateway attachment succeeds before deploying clusters
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}


# -----------------------------------------------------------------------------
# RDS clusters
# -----------------------------------------------------------------------------
module "rds_mysql_instance" {
  source = "./modules/rds"
  count  = var.mysql ? 1 : 0

  username = var.username
  tags     = local.tags

  subnet_ids = [aws_subnet.outpost_private.id]

  engine               = "mysql"
  engine_version       = "8.0.39"
  parameter_group_name = "default.mysql8.0"
  instance_class       = "db.${coalesce(local.allowed_outpost_instance_types...)}"
  allocated_storage    = 20

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

module "rds_postgres_instance" {
  source = "./modules/rds"
  count  = var.postgres ? 1 : 0

  username = var.username
  tags     = local.tags

  subnet_ids = [aws_subnet.outpost_private.id]

  engine               = "postgres"
  engine_version       = "16.4"
  parameter_group_name = "default.postgres16"
  instance_class       = "db.${coalesce(local.allowed_outpost_instance_types...)}"
  allocated_storage    = 20

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

# -----------------------------------------------------------------------------
# On-premises VPC
# -----------------------------------------------------------------------------
module "on_prem_vpc" {
  source = "./modules/on_prem_vpc"
  count  = var.on_prem_vpc ? 1 : 0

  username = var.username
  tags     = local.tags

  on_prem_vpc_cidr        = var.on_prem_vpc_cidr
  outpost_coip_pool_cidrs = local.coip_pool_cidrs

  # Ensure the local gateway attachment succeeds before configuring the on-premises VPC
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

# -----------------------------------------------------------------------------
# Storage Gateway
# -----------------------------------------------------------------------------
module "file_gateway" {
  source = "./modules/storagegateway"
  count  = var.file_gateway ? 1 : 0

  username = var.username
  tags     = local.tags

  main_vpc_id = aws_vpc.main_vpc.id
  subnet_id   = aws_subnet.outpost_public.id
  op_id       = data.aws_outposts_outpost.selected.id
  region      = var.region

  gateway_name  = "file-gateway"
  gateway_type  = "FILE_S3"
  instance_type = coalesce(local.allowed_outpost_instance_types...)

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

module "volume_gateway" {
  source = "./modules/storagegateway"
  count  = var.volume_gateway ? 1 : 0

  username = var.username
  tags     = local.tags

  main_vpc_id = aws_vpc.main_vpc.id
  subnet_id   = aws_subnet.outpost_public.id
  op_id       = data.aws_outposts_outpost.selected.id
  region      = var.region

  gateway_name  = "volume-gateway"
  gateway_type  = "CACHED"
  instance_type = coalesce(local.allowed_outpost_instance_types...)

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

module "tape_gateway" {
  source = "./modules/storagegateway"
  count  = var.tape_gateway ? 1 : 0

  username = var.username
  tags     = local.tags

  main_vpc_id = aws_vpc.main_vpc.id
  subnet_id   = aws_subnet.outpost_public.id
  op_id       = data.aws_outposts_outpost.selected.id
  region      = var.region

  gateway_name  = "tape-gateway"
  gateway_type  = "VTL"
  instance_type = coalesce(local.allowed_outpost_instance_types...)

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}
