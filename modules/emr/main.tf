resource "aws_emr_cluster" "outpost_cluster" {
  name          = "${var.username}-emr-cluster"
  release_label = var.release_label
  applications  = ["Spark"]

  ec2_attributes {
    subnet_id                         = var.subnet_id
    emr_managed_master_security_group = aws_security_group.emr_master.id
    emr_managed_slave_security_group  = aws_security_group.emr_core.id
    service_access_security_group     = aws_security_group.emr_service_access.id
    instance_profile                  = aws_iam_instance_profile.emr_profile.arn
  }

  master_instance_group {
    instance_type = local.master_instance_type
  }

  core_instance_group {
    instance_type  = local.core_instance_type
    instance_count = var.core_instance_count
  }

  tags = merge(var.tags, {
    Name = "${var.username}-emr-cluster"
  })

  bootstrap_action {
    path = "s3://elasticmapreduce/bootstrap-actions/run-if"
    name = "runif"
    args = ["instance.isMaster=true", "echo running on master node"]
  }

  configurations_json = file("${path.module}/emr_cluster_configurations.json")

  service_role = aws_iam_role.iam_emr_service_role.arn
}


# -----------------------------------------------------------------------------
# Security groups
# -----------------------------------------------------------------------------

# EMR Master security group
# Configure the security group rules as separate resources to breck the circular references
resource "aws_security_group" "emr_master" {
  name        = "${var.username}-emr-master-sg"
  description = "Amazon EMR-Managed Security Group for the Master Instance (Private Subnets)"
  vpc_id      = var.main_vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "emr_master_self" {
  security_group_id = aws_security_group.emr_master.id
  type              = "ingress"

  description = "Allow all traffic from the EMR Master (this) security group"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  self        = true
}

resource "aws_security_group_rule" "emr_master_service_access" {
  security_group_id = aws_security_group.emr_master.id
  type              = "ingress"

  description              = "Allow HTTPS traffic on port 8443 from the EMR Service Access security group"
  protocol                 = "tcp"
  from_port                = 8443
  to_port                  = 8443
  source_security_group_id = aws_security_group.emr_service_access.id
}

resource "aws_security_group_rule" "emr_master_outbound" {
  security_group_id = aws_security_group.emr_master.id
  type              = "egress"

  description = "Allow all outbound traffic"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}

# EMR Core security group
resource "aws_security_group" "emr_core" {
  name        = "${var.username}-emr-core-sg"
  description = "Amazon EMR-Managed Security Group for Core and Task Instances (Private Subnets)"
  vpc_id      = var.main_vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "emr_core_self" {
  security_group_id = aws_security_group.emr_core.id
  type              = "ingress"

  description = "Allow all traffic from the EMR Core (this) security group"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  self        = true
}

resource "aws_security_group_rule" "emr_core_master" {
  security_group_id = aws_security_group.emr_core.id
  type              = "ingress"

  description              = "Allow all traffic from the EMR Master security group"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_security_group.emr_master.id
}

resource "aws_security_group_rule" "emr_core_service_access" {
  security_group_id = aws_security_group.emr_core.id
  type              = "ingress"

  description              = "Allow HTTPS traffic on port 8443 from the EMR Service Access security group"
  protocol                 = "tcp"
  from_port                = 8443
  to_port                  = 8443
  source_security_group_id = aws_security_group.emr_service_access.id
}

resource "aws_security_group_rule" "emr_core_allow_egress" {
  security_group_id = aws_security_group.emr_core.id
  type              = "egress"
  description              = "Allow all outbound traffic"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  cidr_blocks = ["0.0.0.0/0"]
}

# EMR Service Access security group
resource "aws_security_group" "emr_service_access" {
  name        = "${var.username}-emr-service-access-sg"
  description = "Allow all traffic from the main and on-premises VPCs."
  vpc_id      = var.main_vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "emr_service_access_9443" {
  security_group_id = aws_security_group.emr_service_access.id
  type              = "ingress"
  description              = "Allow HTTPS traffic on port 9443 from the EMR Master security group"
  protocol                 = "tcp"
  from_port                = 9443
  to_port                  = 9443
  source_security_group_id = aws_security_group.emr_master.id
}

resource "aws_security_group_rule" "emr_service_access_allow_egress" {
  security_group_id = aws_security_group.emr_service_access.id
  type              = "egress"
  description              = "Allow all outbound traffic"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  cidr_blocks = ["0.0.0.0/0"]
}

# -----------------------------------------------------------------------------
# IAM roles and policies
# -----------------------------------------------------------------------------

# IAM role for the EMR Service
resource "aws_iam_role" "iam_emr_service_role" {
  name               = "${var.username}_iam_emr_service_role"
  assume_role_policy = file("${path.module}/iam_emr_assume_role_policy.json")

  tags = var.tags
}

resource "aws_iam_role_policy" "iam_emr_service_role_policy" {
  name   = "iam_emr_service_policy"
  role   = aws_iam_role.iam_emr_service_role.id
  policy = file("${path.module}/iam_emr_service_role_policy.json")
}


# IAM Role for the EC2 instance profile
resource "aws_iam_instance_profile" "emr_profile" {
  name = "${var.username}_emr_profile"
  role = aws_iam_role.iam_emr_profile_role.name
}

resource "aws_iam_role" "iam_emr_profile_role" {
  name               = "${var.username}_iam_emr_profile_role"
  assume_role_policy = file("${path.module}/iam_ec2_assume_role_policy.json")

  tags = var.tags
}

resource "aws_iam_role_policy" "iam_emr_profile_role_policy" {
  name   = "iam_emr_profile_policy"
  role   = aws_iam_role.iam_emr_profile_role.id
  policy = file("${path.module}/iam_emr_profile_role_policy.json")
}
