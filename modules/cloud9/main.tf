resource "aws_cloud9_environment_ec2" "bastion" {
  name          = "${var.username}-${var.location}-cloud9-bastion"
  subnet_id     = var.subnet_id
  instance_type = var.instance_type

  automatic_stop_time_minutes = var.automatic_stop_time_minutes

  tags = var.tags
}
