terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

resource "aws_db_subnet_group" "rds_subnets" {
  name       = join("-",[var.name, "rds-subnets"])
  subnet_ids = [aws_subnet.op_private.id]
  tags = {
    Name = join("-",[var.name, "rds-subnets"])
  }
}

resource "aws_db_instance" "mysql_instance" {
  allocated_storage    = 20
  storage_type         = "gp2"
  storage_encrypted    = "true"
  engine               = "mysql"
  engine_version       = "8.0.17"
  instance_class       = "db.r5.xlarge"
  name                 = join("",["mysql", var.name])
  username             = var.name
  password             = join("-",[var.name, "password"])
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.rds_subnets.name
}

resource "aws_db_instance" "postgres_instance" {
  allocated_storage    = 20
  storage_type         = "gp2"
  storage_encrypted    = "true"
  engine               = "postgres"
  engine_version       = "12.2"
  instance_class       = "db.r5.xlarge"
  name                 = join("",["postgres", var.name])
  username             = var.name
  password             = join("-",[var.name, "password"])
  parameter_group_name = "default.postgres12"
  db_subnet_group_name = aws_db_subnet_group.rds_subnets.name
}
