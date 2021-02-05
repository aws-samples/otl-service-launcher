output "id" {
  value = aws_db_instance.rds_instance.id
}

output "endpoint" {
  value = aws_db_instance.rds_instance.endpoint
}

output "port" {
  value = aws_db_instance.rds_instance.port
}

output "database_name" {
  value = aws_db_instance.rds_instance.name
}

output "username" {
  value = aws_db_instance.rds_instance.username
}

output "password" {
  value     = aws_db_instance.rds_instance.password
  sensitive = true
}
