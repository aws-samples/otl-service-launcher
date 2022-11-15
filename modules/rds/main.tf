resource "aws_db_subnet_group" "rds_subnets" {
  name       = "${var.username}-rds-${var.engine}-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.username}-rds-${var.engine}-subnets"
  })
}

resource "random_string" "db_identifier_suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = false
  special = false
}

resource "aws_db_instance" "rds_instance" {
  db_subnet_group_name = aws_db_subnet_group.rds_subnets.name

  identifier = "${var.username}-rds-${var.engine}-${random_string.db_identifier_suffix.result}"

  engine               = var.engine
  engine_version       = var.engine_version
  parameter_group_name = var.parameter_group_name
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  storage_type         = "gp2"
  storage_encrypted    = true
  skip_final_snapshot  = true

  name     = var.username
  username = var.username
  password = "${var.username}-password"

  tags = merge(var.tags, {
    Name = "${var.username}-rds-${var.engine}-instance"
  })
}
