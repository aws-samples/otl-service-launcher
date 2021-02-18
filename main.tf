# -----------------------------------------------------------------------------
# Cloud9 bastions
# -----------------------------------------------------------------------------
module "region_cloud9_bastion" {
  source = "./modules/cloud9"
  count  = var.region_cloud9 ? 1 : 0

  username = var.username
  tags     = local.tags

  location      = "region"
  subnet_id     = aws_subnet.region_az_1_public.id
  instance_type = "m5.xlarge"

  automatic_stop_time_minutes = 240
  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

module "outpost_cloud9_bastion" {
  source = "./modules/cloud9"
  count  = var.outpost_cloud9 ? 1 : 0

  username = var.username
  tags     = local.tags

  location      = "outpost"
  subnet_id     = aws_subnet.outpost_public.id
  instance_type = "m5.xlarge"

  automatic_stop_time_minutes = 240
  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}


# -----------------------------------------------------------------------------
# EKS cluster
# -----------------------------------------------------------------------------
module "eks_cluster" {
  source = "./modules/eks"
  count  = var.eks ? 1 : 0

  username = var.username
  tags     = local.tags

  region_public_subnet_ids = [
    aws_subnet.region_az_1_public.id,
    aws_subnet.region_az_2_public.id,
  ]
  outpost_private_subnet_ids = [aws_subnet.outpost_private.id]

  kubernetes_version = "1.18"
  service_ipv4_cidr  = "192.168.0.0/16"

  instance_types = ["m5.xlarge"]
  node_count     = 1
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
  engine_version       = "1.6.6"
  parameter_group_name = "default.memcached1.6"
  node_type            = "cache.r5.xlarge"
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
  engine_version       = "5.0.6"
  parameter_group_name = "default.redis5.0"
  node_type            = "cache.r5.xlarge"
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

  release_label        = "emr-5.32.0"
  master_instance_type = "m5.xlarge"
  core_instance_type   = "m5.xlarge"
  core_instance_count  = 1

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
  engine_version       = "8.0.17"
  parameter_group_name = "default.mysql8.0"
  instance_class       = "db.r5.xlarge"
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
  engine_version       = "12.2"
  parameter_group_name = "default.postgres12"
  instance_class       = "db.r5.xlarge"
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
  outpost_coip_pool_cidrs = data.aws_ec2_coip_pool.outpost_coip_pool.pool_cidrs

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
  subnet_id = aws_subnet.outpost_public.id
  op_id = data.aws_outposts_outpost.selected.id
  region = var.region

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

module "volume_gateway" {
  source = "./modules/storagegateway"
  count  = var.volume_gateway ? 1 : 0

  username = var.username
  tags     = local.tags

  main_vpc_id = aws_vpc.main_vpc.id
  subnet_id = aws_subnet.outpost_public.id
  op_id = data.aws_outposts_outpost.selected.id
  region = var.region

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

module "tape_gateway" {
  source = "./modules/storagegateway"
  count  = var.tape_gateway ? 1 : 0

  username = var.username
  tags     = local.tags  

  main_vpc_id = aws_vpc.main_vpc.id
  subnet_id = aws_subnet.outpost_public.id
  op_id = data.aws_outposts_outpost.selected.id
  region = var.region

  # Ensure the local gateway attachment succeeds before deploying instances
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}
