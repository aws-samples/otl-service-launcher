terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

resource "aws_elasticache_subnet_group" "elasticache_subnets" {
  name       = join("-",[var.name, "elasticache-subnets"])
  subnet_ids = [aws_subnet.op_private.id]
}

resource "aws_elasticache_cluster" "memcached_cluster" {
  cluster_id           = "memcached-cluster"
  engine               = "memcached"
  node_type            = "cache.r5.xlarge"
  num_cache_nodes      = 2
  parameter_group_name = "default.memcached1.6"
  port                 = 11211
  subnet_group_name    = aws_elasticache_subnet_group.elasticache_subnets.name
  tags = {
      Name = join("-",[var.name, "memcached-cluster"])
    }
}

resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = "redis-cluster"
  engine               = "redis"
  node_type            = "cache.r5.xlarge"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.elasticache_subnets.name
  tags = {
      Name = join("-",[var.name, "redis-cluster"])
    }
}
