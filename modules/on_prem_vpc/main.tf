# -----------------------------------------------------------------------------
# On-Premises VPC - Addressing
# -----------------------------------------------------------------------------
# Generate a random number for the default VPC CIDR to help avoid conflicts
resource "random_integer" "on_prem_vpc_cidr" {
  min = 0
  max = 127
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  on_prem_vpc_cidr = coalesce(var.on_prem_vpc_cidr, cidrsubnet("172.16.0.0/12", 7, random_integer.on_prem_vpc_cidr.result))

  on_prem_az_1 = data.aws_availability_zones.available.names[0]
  on_prem_az_2 = data.aws_availability_zones.available.names[1]

  # Generate AZ CIDR allocations
  az_cidr_allocation = cidrsubnets(local.on_prem_vpc_cidr, 1, 1)
  on_prem_az_1_cidr  = local.az_cidr_allocation[0]
  on_prem_az_2_cidr  = local.az_cidr_allocation[1]

  # Generate subnet CIDR allocactions
  # Allocation Use: [public, available, available, available, private]
  on_prem_az_1_subnets        = cidrsubnets(local.on_prem_az_1_cidr, 3, 3, 3, 3, 1)
  on_prem_az_1_public_subnet  = local.on_prem_az_1_subnets[0]
  on_prem_az_1_private_subnet = local.on_prem_az_1_subnets[4]

  on_prem_az_2_subnets        = cidrsubnets(local.on_prem_az_2_cidr, 3, 3, 3, 3, 1)
  on_prem_az_2_public_subnet  = local.on_prem_az_2_subnets[0]
  on_prem_az_2_private_subnet = local.on_prem_az_2_subnets[4]
}


# -----------------------------------------------------------------------------
# Main VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "on_prem_vpc" {
  cidr_block           = local.on_prem_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.username}-on-prem-vpc"
  })
}

resource "aws_subnet" "on_prem_az_1_public" {
  vpc_id            = aws_vpc.on_prem_vpc.id
  availability_zone = local.on_prem_az_1
  cidr_block        = local.on_prem_az_1_public_subnet

  tags = merge(var.tags, {
    Name = "${var.username}-on-prem-public-subnet-1"
  })
}

resource "aws_subnet" "on_prem_az_2_public" {
  vpc_id            = aws_vpc.on_prem_vpc.id
  availability_zone = local.on_prem_az_2
  cidr_block        = local.on_prem_az_2_public_subnet

  tags = merge(var.tags, {
    Name = "${var.username}-on-prem-public-subnet-2"
  })
}

resource "aws_subnet" "on_prem_az_1_private" {
  vpc_id            = aws_vpc.on_prem_vpc.id
  availability_zone = local.on_prem_az_1
  cidr_block        = local.on_prem_az_1_private_subnet

  tags = merge(var.tags, {
    Name = "${var.username}-on-prem-private-subnet-1"
  })
}

resource "aws_subnet" "on_prem_az_2_private" {
  vpc_id            = aws_vpc.on_prem_vpc.id
  availability_zone = local.on_prem_az_2
  cidr_block        = local.on_prem_az_2_private_subnet

  tags = merge(var.tags, {
    Name = "${var.username}-on-prem-private-subnet-2"
  })
}


# -----------------------------------------------------------------------------
# Internet Gateway (igw)
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "on_prem_vpc_igw" {
  vpc_id = aws_vpc.on_prem_vpc.id

  tags = merge(var.tags, {
    Name = "${var.username}-on-prem-vpc-igw"
  })
}


# -----------------------------------------------------------------------------
# NAT Gateway
# -----------------------------------------------------------------------------
resource "aws_eip" "on_prem_vpc_nat_gw_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.on_prem_vpc_igw]

  tags = merge(var.tags, {
    Name = "${var.username}-on-prem-vpc-nat-gw-eip"
  })
}

resource "aws_nat_gateway" "on_prem_vpc_nat_gw" {
  allocation_id = aws_eip.on_prem_vpc_nat_gw_eip.id
  subnet_id     = aws_subnet.on_prem_az_1_public.id
  depends_on    = [aws_internet_gateway.on_prem_vpc_igw]

  tags = merge(var.tags, {
    Name = "${var.username}-on-prem-vpc-nat-gw"
  })
}


# -----------------------------------------------------------------------------
# VPN Gateway (vgw)
# -----------------------------------------------------------------------------
resource "aws_vpn_gateway" "on_prem_vpc_vgw" {
  vpc_id = aws_vpc.on_prem_vpc.id

  tags = merge(var.tags, {
    Name = "${var.username}-on-prem-vpc-vgw"
  })
}


# -----------------------------------------------------------------------------
# Route tables
# -----------------------------------------------------------------------------
resource "aws_route_table" "on_prem_public_routes" {
  vpc_id = aws_vpc.on_prem_vpc.id

  tags = merge(var.tags, {
    Name = "${var.username}-on-prem-public-route-table"
  })
}

resource "aws_route_table_association" "on_prem_az_1_public_subnet" {
  subnet_id      = aws_subnet.on_prem_az_1_public.id
  route_table_id = aws_route_table.on_prem_public_routes.id
}

resource "aws_route_table_association" "on_prem_az_2_public_subnet" {
  subnet_id      = aws_subnet.on_prem_az_2_public.id
  route_table_id = aws_route_table.on_prem_public_routes.id
}


resource "aws_route_table" "on_prem_private_routes" {
  vpc_id = aws_vpc.on_prem_vpc.id

  tags = merge(var.tags, {
    Name = "${var.username}-on-prem-private-route-table"
  })
}

resource "aws_route_table_association" "on_prem_az_1_private_subnet" {
  subnet_id      = aws_subnet.on_prem_az_1_private.id
  route_table_id = aws_route_table.on_prem_private_routes.id
}

resource "aws_route_table_association" "on_prem_az_2_private_subnet" {
  subnet_id      = aws_subnet.on_prem_az_2_private.id
  route_table_id = aws_route_table.on_prem_private_routes.id
}


# Routes
resource "aws_route" "on_prem_igw_route" {
  route_table_id         = aws_route_table.on_prem_public_routes.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.on_prem_vpc_igw.id
}

resource "aws_route" "on_prem_nat_gw_route" {
  route_table_id         = aws_route_table.on_prem_private_routes.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.on_prem_vpc_nat_gw.id
}

resource "aws_route" "on_prem_vgw_public_route" {
  for_each = var.outpost_coip_pool_cidrs

  route_table_id         = aws_route_table.on_prem_public_routes.id
  destination_cidr_block = each.value
  gateway_id             = aws_vpn_gateway.on_prem_vpc_vgw.id
}

resource "aws_route" "on_prem_vgw_private_route" {
  for_each = var.outpost_coip_pool_cidrs

  route_table_id         = aws_route_table.on_prem_private_routes.id
  destination_cidr_block = each.value
  gateway_id             = aws_vpn_gateway.on_prem_vpc_vgw.id
}
