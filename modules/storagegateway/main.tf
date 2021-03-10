# -----------------------------------------------------------------------------
# Storage Gateway - EC2 Setup
# -----------------------------------------------------------------------------
# Creates EC2 instance that will host the gateway and required resources

data "aws_outposts_outpost" "op" {
  id = var.op_id
}

# create RDS key for AWS key pair
resource "tls_private_key" "sgw_tls" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# create AWS key pair
resource "aws_key_pair" "storagegateway" {
  key_name = join("-",[var.username, "storage-gateway-key"])
  public_key = tls_private_key.sgw_tls.public_key_openssh
}

# get the most recent storage gateway AMI
data "aws_ami" "sg_ami" {
  most_recent      = true
  owners           = ["amazon"]
  filter {
    name   = "name"
    values = ["aws-storage-gateway*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# create the instance
resource "aws_instance" "storage_gateway_server" {
  ami = data.aws_ami.sg_ami.image_id
  instance_type = var.instance_type
  associate_public_ip_address = true
  key_name = aws_key_pair.storagegateway.key_name
  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_security_group.storage_gateway_sg.id]
  root_block_device {
            volume_size = 80
            volume_type = "gp2"
  }
  tags = {
    Name = join("-",[var.username, "storage-gateway"])
  }
}

# this security group will allow all traffic from amazon corpnet 
resource "aws_security_group" "storage_gateway_sg" {
  name = join("-",[var.username, "storage-gateway-activation-sg"])
  vpc_id = var.main_vpc_id
  ingress {
    prefix_list_ids = [lookup(var.region_prefixlist_mapping, var.region)]
    protocol = "-1"
    from_port = 0
    to_port = 0
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### create two EBS volumes and attach them to the storage gateway

resource "aws_ebs_volume" "storage_gateway_server_cache_disk" {
    availability_zone = data.aws_outposts_outpost.op.availability_zone
    outpost_arn = data.aws_outposts_outpost.op.arn
    size = 150
    encrypted = true
    type = "gp2"
}

resource "aws_volume_attachment" "storage_gateway_attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.storage_gateway_server_cache_disk.id
  instance_id = aws_instance.storage_gateway_server.id
}

resource "aws_ebs_volume" "storage_gateway_server_buffer_disk" {
    availability_zone = data.aws_outposts_outpost.op.availability_zone
    outpost_arn = data.aws_outposts_outpost.op.arn
    size = 150
    encrypted = true
    type = "gp2"
}

resource "aws_volume_attachment" "storage_gateway_attach_buffer" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.storage_gateway_server_buffer_disk.id
  instance_id = aws_instance.storage_gateway_server.id
}

### create the storage gateway
resource "aws_storagegateway_gateway" "storage_gateway" {
  gateway_ip_address = aws_instance.storage_gateway_server.public_ip
  gateway_name       = var.gateway_name
  gateway_timezone   = "GMT"
  gateway_type       = var.gateway_type
}

data "aws_storagegateway_local_disk" "storage_gateway_data" {
  disk_node = aws_volume_attachment.storage_gateway_attach.device_name
  gateway_arn = aws_storagegateway_gateway.storage_gateway.arn
}

resource "aws_storagegateway_cache" "storage_gateway_cache" {
  disk_id     = data.aws_storagegateway_local_disk.storage_gateway_data.id
  gateway_arn = aws_storagegateway_gateway.storage_gateway.arn
}

data "aws_storagegateway_local_disk" "storage_gateway_buffer" {
  disk_node   = aws_volume_attachment.storage_gateway_attach_buffer.device_name
  gateway_arn = aws_storagegateway_gateway.storage_gateway.arn
}

resource "aws_storagegateway_upload_buffer" "buffer" {
  disk_id = data.aws_storagegateway_local_disk.storage_gateway_buffer.id
  gateway_arn = aws_storagegateway_gateway.storage_gateway.arn

  depends_on = [aws_volume_attachment.storage_gateway_attach_buffer]
}

resource "aws_storagegateway_cached_iscsi_volume" "example" {
  count = var.gateway_type == "CACHED" ? 1 : 0
  gateway_arn          = aws_storagegateway_cache.storage_gateway_cache.gateway_arn
  network_interface_id = aws_instance.storage_gateway_server.private_ip
  target_name          = join("-",[var.username, "target-volume"])
  volume_size_in_bytes = 5368709120 # 5 GB
}

resource "aws_iam_role" "transfer_role" { 
  name = join("-",[var.username, var.gateway_name, "role"])
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "storagegateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "transfer_policy_sg" {
  name = join("-",[var.username, var.gateway_name, "policy"])
  description = "Allows access to storage gateway"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Action": [
      "s3:GetAccelerateConfiguration",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:ListBucketMultipartUploads"
    ],
    "Resource": "arn:aws:s3:::${aws_s3_bucket.backup_test_bucket.bucket}",
    "Effect": "Allow"
  },
  {
    "Action": [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectVersion",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ],
    "Resource": "arn:aws:s3:::${aws_s3_bucket.backup_test_bucket.bucket}/*",
    "Effect": "Allow"
  } ]
}
EOF
}

resource "aws_iam_policy_attachment" "transfer_attach" {
  name = join("-",[var.username, var.gateway_name, "attach"])
  roles = [aws_iam_role.transfer_role.name]
  policy_arn = aws_iam_policy.transfer_policy_sg.arn
}

resource "aws_s3_bucket" "backup_test_bucket" {
  acl    = "private"
  tags = {
    Name = join("-",[var.username, var.gateway_name, "bucket"])
    Environment = "Dev"
  }
}
