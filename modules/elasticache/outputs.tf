output "id" {
  value = aws_elasticache_cluster.elasticache_cluster.id
}

output "cluster_address" {
  value = aws_elasticache_cluster.elasticache_cluster.cluster_address
}

output "port" {
  value = aws_elasticache_cluster.elasticache_cluster.port
}
