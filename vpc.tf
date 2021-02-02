resource "aws_vpc" "main_vpc" {
  cidr_block = var.op_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = join("-",[var.name, "op-vpc"])
  }
}

resource "aws_vpc" "on_prem_vpc" {
  cidr_block = var.on_prem_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = join("-",[var.name, "on-prem-vpc"])
  }
}

resource "aws_subnet" "on_prem_public" {
    vpc_id = aws_vpc.on_prem_vpc.id
    cidr_block = cidrsubnet(var.on_prem_cidr, 2, 0)
    tags = {
      Name = join("-",[var.name, "on-prem-public"])
    }
}

resource "aws_subnet" "on_prem_private" {
    vpc_id = aws_vpc.on_prem_vpc.id
    cidr_block = cidrsubnet(var.on_prem_cidr, 2, 1)
    tags = {
      Name = join("-",[var.name, "on-prem-private"])
    }
}

resource "aws_internet_gateway" "on_prem_igw" {
  vpc_id = aws_vpc.on_prem_vpc.id
  tags = {
    Name = join("-",[var.name, "on-prem-igw"])
  }
}

resource "aws_vpn_gateway" "on_prem_vgw" {
  vpc_id = aws_vpc.on_prem_vpc.id
  tags = {
    Name = join("-",[var.name, "on-prem-vgw"])
  }
}

resource "aws_route_table" "on_prem_public_routes" {
  vpc_id = aws_vpc.on_prem_vpc.id
  tags = {
    Name = join("-",[var.name, "on-prem-public-routes"])
  }
}

resource "aws_route" "igw_route_on_prem" {
  route_table_id = aws_route_table.on_prem_public_routes.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.on_prem_igw.id
}

resource "aws_route" "vgw_route_on_prem" {
  route_table_id = aws_route_table.on_prem_public_routes.id
  destination_cidr_block = sort(data.aws_ec2_coip_pool.op_coip_pool.pool_cidrs)[0]
  gateway_id = aws_vpn_gateway.on_prem_vgw.id
}

resource "aws_route" "vgw_route_on_prem_private" {
  route_table_id = aws_route_table.on_prem_private_routes.id
  destination_cidr_block = sort(data.aws_ec2_coip_pool.op_coip_pool.pool_cidrs)[0]
  gateway_id = aws_vpn_gateway.on_prem_vgw.id
}

resource "aws_route_table_association" "on_prem_public_association" {
  subnet_id      = aws_subnet.on_prem_public.id
  route_table_id = aws_route_table.on_prem_public_routes.id
}

resource "aws_eip" "on_prem_nat_eip" {
  vpc = true
  depends_on = [aws_internet_gateway.on_prem_igw]
  tags = {
    Name = join("-",[var.name, "on-prem-nat-eip"])
  }
}

resource "aws_nat_gateway" "on_prem_nat_gw" {
  allocation_id = aws_eip.on_prem_nat_eip.id
  subnet_id = aws_subnet.on_prem_public.id
  depends_on = [aws_internet_gateway.on_prem_igw]
  tags = {
    Name = join("-",[var.name, "on-prem-nat-gw"])
  }
}

resource "aws_route_table" "on_prem_private_routes" {
  vpc_id = aws_vpc.on_prem_vpc.id
  tags = {
    Name = join("-",[var.name, "on-prem-private-routes"])
  }
}

resource "aws_route_table_association" "on_prem_private_association" {
  subnet_id      = aws_subnet.on_prem_private.id
  route_table_id = aws_route_table.on_prem_private_routes.id
}

resource "aws_route" "nat_route_on_prem" {
  route_table_id = aws_route_table.on_prem_private_routes.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.on_prem_nat_gw.id
}

resource "aws_subnet" "region_public" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = cidrsubnet(var.op_cidr, 4, 0)
    availability_zone = data.aws_outposts_outpost.op.availability_zone
    tags = {
      Name = join("-",[var.name, "region-public-subnet"])
    }
}

resource "aws_subnet" "region_public_2" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = cidrsubnet(var.op_cidr, 4, 5)
    availability_zone = data.aws_availability_zones.available.names[0] != data.aws_outposts_outpost.op.availability_zone ? data.aws_availability_zones.available.names[0] : data.aws_availability_zones.available.names[1]
    tags = {
      Name = join("-",[var.name, "region-public-subnet-2"])
    }
}

resource "aws_subnet" "region_private" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = cidrsubnet(var.op_cidr, 4, 1)
    tags = {
      Name = join("-",[var.name, "region-private-subnet"])
    }
}

resource "aws_subnet" "op_public" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = cidrsubnet(var.op_cidr, 4, 2)
    outpost_arn = data.aws_outposts_outpost.op.arn
    availability_zone = data.aws_outposts_outpost.op.availability_zone
    tags = {
      Name = join("-",[var.name, "op-public-subnet"])
    }
}

resource "aws_subnet" "op_private" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = cidrsubnet(var.op_cidr, 4, 3)
    outpost_arn = data.aws_outposts_outpost.op.arn
    availability_zone = data.aws_outposts_outpost.op.availability_zone
    tags = {
      Name = join("-",[var.name, "op-private-subnet-1"])
    }
}

resource "aws_subnet" "op_private_2" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = cidrsubnet(var.op_cidr, 4, 4)
    outpost_arn = data.aws_outposts_outpost.op.arn
    availability_zone = data.aws_outposts_outpost.op.availability_zone
    tags = {
      Name = join("-",[var.name, "op-private-subnet-2"])
    }
}

resource "aws_internet_gateway" "op_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = join("-",[var.name, "op-igw"])
  }
}

resource "aws_route_table" "region_public_routes" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = join("-",[var.name, "region-public-route-table"])
  }
}

resource "aws_route_table_association" "region_public_association" {
  subnet_id      = aws_subnet.region_public.id
  route_table_id = aws_route_table.region_public_routes.id
}

resource "aws_route_table_association" "region_public_association_2" {
  subnet_id      = aws_subnet.region_public_2.id
  route_table_id = aws_route_table.region_public_routes.id
}

resource "aws_route_table" "region_private_routes" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = join("-",[var.name, "region-private-routes"])
  }
}

resource "aws_route_table_association" "region_private_association" {
  subnet_id      = aws_subnet.region_private.id
  route_table_id = aws_route_table.region_private_routes.id
}

resource "aws_route_table" "op_public_routes" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = join("-",[var.name, "op-public-routes"])
  }
}

resource "aws_route_table_association" "op_public_association" {
  subnet_id      = aws_subnet.op_public.id
  route_table_id = aws_route_table.op_public_routes.id
}

resource "aws_route_table" "op_private_routes" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = join("-",[var.name, "op-private-routes"])
  }
}

resource "aws_route_table_association" "op_private_association" {
  subnet_id      = aws_subnet.op_private.id
  route_table_id = aws_route_table.op_private_routes.id
}

resource "aws_route_table_association" "op_private_2_association" {
  subnet_id = aws_subnet.op_private_2.id
  route_table_id = aws_route_table.op_private_routes.id
}

resource "aws_route" "igw_route_region" {
  route_table_id = aws_route_table.region_public_routes.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.op_igw.id
}

resource "aws_route" "igw_route_op" {
  route_table_id = aws_route_table.op_public_routes.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.op_igw.id
}

resource "aws_route" "lgw_route_op" {
  route_table_id = aws_route_table.op_public_routes.id
  destination_cidr_block = var.on_prem_cidr
  local_gateway_id = data.aws_ec2_local_gateway_route_table.lgw_rtb.local_gateway_id
  depends_on = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

resource "aws_eip" "op_nat_eip" {
  vpc = true
  depends_on = [aws_internet_gateway.op_igw]
  tags = {
    Name = join("-",[var.name, "op-nat-eip"])
  }
}

resource "aws_nat_gateway" "op_nat_gw" {
  allocation_id = aws_eip.op_nat_eip.id
  subnet_id = aws_subnet.region_public.id
  depends_on = [aws_internet_gateway.op_igw]
  tags = {
    Name = join("-",[var.name, "op-nat-gw"])
  }
}

resource "aws_route" "nat_route_op" {
  route_table_id = aws_route_table.op_private_routes.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.op_nat_gw.id
}

resource "aws_ec2_local_gateway_route_table_vpc_association" "lgw_association" {
  local_gateway_route_table_id = data.aws_ec2_local_gateway_route_table.lgw_rtb.id
  vpc_id                       = aws_vpc.main_vpc.id
}

resource "aws_cloud9_environment_ec2" "op_region_bastion" {
  instance_type = "m5.xlarge"
  name = join("-",[var.name, "region-c9-bastion"])
  automatic_stop_time_minutes = 240
  subnet_id = aws_subnet.region_public.id
}

resource "aws_cloud9_environment_ec2" "on_prem_bastion" {
  instance_type = "m5.xlarge"
  name = join("-",[var.name, "on-prem-c9-bastion"])
  automatic_stop_time_minutes = 240
  subnet_id = aws_subnet.on_prem_public.id
}

resource "aws_security_group" "on_prem_beta_sg" {
  name = join("-",[var.name, "on-prem-beta-sg"])
  description = "allow traffic from itself"
  vpc_id      = aws_vpc.on_prem_vpc.id
  ingress {
    description = "all traffic from itself"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "on_prem_lgw_sg" {
  name = join("-",[var.name, "on-prem-lgw-sg"])
  description = "allow traffic from the outpost"
  vpc_id      = aws_vpc.on_prem_vpc.id
  ingress {
    description = "all traffic from the outpost vpc range"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.op_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "op_alpha_sg" {
  name = join("-",[var.name, "op-alpha-sg"])
  description = "allow traffic from itself"
  vpc_id      = aws_vpc.main_vpc.id
  ingress {
    description = "all traffic from itself"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "op_lgw_sg" {
  name = join("-",[var.name, "op-lgw-sg"])
  description = "allow traffic from on-prem cidr"
  vpc_id      = aws_vpc.main_vpc.id
  ingress {
    description = "all traffic from on-prem cidr"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.on_prem_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

