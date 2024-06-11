output "local_cluster_endpoint" {
  value = aws_eks_cluster.eks_local_cluster.endpoint
}

output "local_cluster_ca_cert" {
  value     = aws_eks_cluster.eks_local_cluster.certificate_authority[0].data
  sensitive = true
}

output "local_cluster_security_group_id" {
  value = aws_eks_cluster.eks_local_cluster.vpc_config[0].cluster_security_group_id
}
