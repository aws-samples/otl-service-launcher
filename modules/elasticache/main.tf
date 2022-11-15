resource "random_string" "cluster_id_suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = false
  special = false
}


resource "aws_elasticache_subnet_group" "elasticache_subnets" {
  name       = "${var.username}-elasticache-${var.engine}-subnets"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_cluster" "elasticache_cluster" {
  subnet_group_name = aws_elasticache_subnet_group.elasticache_subnets.name

  cluster_id = "${var.username}-rds-${var.engine}-${random_string.cluster_id_suffix.result}"

  engine               = var.engine
  engine_version       = var.engine_version
  parameter_group_name = var.parameter_group_name
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes

  tags = merge(var.tags, {
    Name = "${var.username}-elasticache-${var.engine}-instance"
  })
}
