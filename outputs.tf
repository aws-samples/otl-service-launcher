# -----------------------------------------------------------------------------
# Main VPC
# -----------------------------------------------------------------------------
output "main_vpc_id" {
  value = aws_vpc.main_vpc.id
}


# -----------------------------------------------------------------------------
# Outpost
# -----------------------------------------------------------------------------
output "outpost_public_subnet_id" {
  value = aws_subnet.outpost_public.id
}

output "outpost_private_subnet_id" {
  value = aws_subnet.outpost_private.id
}

# -----------------------------------------------------------------------------
# On-Premises VPC
# -----------------------------------------------------------------------------
output "on_prem_vpc_id" {
  value = concat(module.on_prem_vpc[*].on_prem_vpc_id, [""])[0]
}


# -----------------------------------------------------------------------------
# EKS
# -----------------------------------------------------------------------------
output "eks_cluster_endpoint" {
  value = concat(module.eks_cluster[*].cluster_endpoint, [""])[0]
}

output "eks_cluster_ca_cert" {
  value     = concat(module.eks_cluster[*].cluster_ca_cert, [""])[0]
  sensitive = true
}

# -----------------------------------------------------------------------------
# EKS Local Cluster
# -----------------------------------------------------------------------------
output "eks_local_cluster_endpoint" {
  value = concat(module.eks_local_cluster[*].local_cluster_endpoint, [""])[0]
}

output "eks_local_cluster_ca_cert" {
  value     = concat(module.eks_local_cluster[*].local_cluster_ca_cert, [""])[0]
  sensitive = true
}


# -----------------------------------------------------------------------------
# EMR
# -----------------------------------------------------------------------------
output "emr_cluster_id" {
  value = concat(module.emr_cluster[*].id, [""])[0]
}


# -----------------------------------------------------------------------------
# ElastiCache Memcached
# -----------------------------------------------------------------------------
output "memcached_cluster_id" {
  value = concat(module.elasticache_memcached_instance[*].id, [""])[0]
}

output "memcached_cluster_address" {
  value = concat(module.elasticache_memcached_instance[*].cluster_address, [""])[0]
}

output "memcached_port" {
  value = concat(module.elasticache_memcached_instance[*].port, [""])[0]
}


# -----------------------------------------------------------------------------
# ElastiCache Redis
# -----------------------------------------------------------------------------
output "redis_cluster_id" {
  value = concat(module.elasticache_redis_instance[*].id, [""])[0]
}

output "redis_cluster_address" {
  value = concat(module.elasticache_redis_instance[*].cluster_address, [""])[0]
}

output "redis_port" {
  value = concat(module.elasticache_redis_instance[*].port, [""])[0]
}


# -----------------------------------------------------------------------------
# RDS MySQL
# -----------------------------------------------------------------------------
output "mysql_instance_id" {
  value = concat(module.rds_mysql_instance[*].id, [""])[0]
}

output "mysql_endpoint" {
  value = concat(module.rds_mysql_instance[*].endpoint, [""])[0]
}

output "mysql_port" {
  value = concat(module.rds_mysql_instance[*].port, [""])[0]
}

output "mysql_database_name" {
  value = concat(module.rds_mysql_instance[*].database_name, [""])[0]
}

output "mysql_username" {
  value = concat(module.rds_mysql_instance[*].username, [""])[0]
}

output "mysql_password" {
  value     = concat(module.rds_mysql_instance[*].password, [""])[0]
  sensitive = true
}


# -----------------------------------------------------------------------------
# RDS PostgreSQL
# -----------------------------------------------------------------------------
output "postgres_instance_id" {
  value = concat(module.rds_postgres_instance[*].id, [""])[0]
}

output "postgres_endpoint" {
  value = concat(module.rds_postgres_instance[*].endpoint, [""])[0]
}

output "postgres_port" {
  value = concat(module.rds_postgres_instance[*].port, [""])[0]
}

output "postgres_database_name" {
  value = concat(module.rds_postgres_instance[*].database_name, [""])[0]
}

output "postgres_username" {
  value = concat(module.rds_postgres_instance[*].username, [""])[0]
}

output "postgres_password" {
  value     = concat(module.rds_postgres_instance[*].password, [""])[0]
  sensitive = true
}
