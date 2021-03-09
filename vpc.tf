# -----------------------------------------------------------------------------
# Main VPC - Addressing
# -----------------------------------------------------------------------------
# Generate a random number for the default VPC CIDR to help avoid conflicts
resource "random_integer" "main_vpc_cidr" {
  min = 0
  max = 254
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  main_vpc_cidr = coalesce(var.main_vpc_cidr, cidrsubnet("10.0.0.0/8", 8, random_integer.main_vpc_cidr.result))

  # region_az_1 is the AZ that provides connectivity to the Outpost
  region_az_1 = data.aws_outposts_outpost.selected.availability_zone

  # region_az_2 is selected from the other available AZs - not servicing the
  # Outpost. This AZ is used by services (like EKS) that require two in-region
  # autonomous zones.
  region_az_2 = coalesce(setsubtract(data.aws_availability_zones.available.names, [local.region_az_1])...)

  # Generate AZ/Outpost CIDR allocations
  az_cidr_allocation = cidrsubnets(local.main_vpc_cidr, 4, 4, 4)
  region_az_1_cidr   = local.az_cidr_allocation[0]
  region_az_2_cidr   = local.az_cidr_allocation[1]
  outpost_cidr       = local.az_cidr_allocation[2]

  # Generate subnet CIDR allocactions
  # Allocation Use: [public, available, available, available, private]
  region_az_1_subnets        = cidrsubnets(local.region_az_1_cidr, 3, 3, 3, 3, 1)
  region_az_1_public_subnet  = local.region_az_1_subnets[0]
  region_az_1_private_subnet = local.region_az_1_subnets[4]

  region_az_2_subnets        = cidrsubnets(local.region_az_2_cidr, 3, 3, 3, 3, 1)
  region_az_2_public_subnet  = local.region_az_2_subnets[0]
  region_az_2_private_subnet = local.region_az_2_subnets[4]

  outpost_subnets        = cidrsubnets(local.outpost_cidr, 3, 3, 3, 3, 1)
  outpost_public_subnet  = local.outpost_subnets[0]
  outpost_private_subnet = local.outpost_subnets[4]
}

# -----------------------------------------------------------------------------
# Main VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "main_vpc" {
  cidr_block           = local.main_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "${var.username}-main-vpc"
  })
}


# Subnets
resource "aws_subnet" "region_az_1_public" {
  vpc_id                  = aws_vpc.main_vpc.id
  availability_zone       = local.region_az_1
  cidr_block              = local.region_az_1_public_subnet
  map_public_ip_on_launch = true

  tags = merge(local.tags, map(
    "Name", "${var.username}-region-public-subnet-1",
    "kubernetes.io/cluster/${local.eks_cluster_name}", "shared",
    "kubernetes.io/role/elb", "1",
  ))
}

resource "aws_subnet" "region_az_2_public" {
  vpc_id                  = aws_vpc.main_vpc.id
  availability_zone       = local.region_az_2
  cidr_block              = local.region_az_2_public_subnet
  map_public_ip_on_launch = true

  tags = merge(local.tags, map(
    "Name", "${var.username}-region-public-subnet-2",
    "kubernetes.io/cluster/${local.eks_cluster_name}", "shared",
    "kubernetes.io/role/elb", "1",
  ))
}

resource "aws_subnet" "region_az_1_private" {
  vpc_id            = aws_vpc.main_vpc.id
  availability_zone = local.region_az_1
  cidr_block        = local.region_az_1_private_subnet

  tags = merge(local.tags, map(
    "Name", "${var.username}-region-private-subnet-1",
    "kubernetes.io/cluster/${local.eks_cluster_name}", "shared",
    "kubernetes.io/role/internal-elb", "1",
  ))
}

resource "aws_subnet" "region_az_2_private" {
  vpc_id            = aws_vpc.main_vpc.id
  availability_zone = local.region_az_2
  cidr_block        = local.region_az_2_private_subnet

  tags = merge(local.tags, map(
    "Name", "${var.username}-region-private-subnet-2",
    "kubernetes.io/cluster/${local.eks_cluster_name}", "shared",
    "kubernetes.io/role/internal-elb", "1",
  ))
}


# -----------------------------------------------------------------------------
# Internet Gateway (igw)
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main_vpc_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(local.tags, {
    Name = "${var.username}-main-vpc-igw"
  })
}


# -----------------------------------------------------------------------------
# NAT Gateway
# -----------------------------------------------------------------------------
resource "aws_eip" "main_vpc_nat_gw_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.main_vpc_igw]

  tags = merge(local.tags, {
    Name = "${var.username}-main-vpc-nat-gw-eip"
  })
}

resource "aws_nat_gateway" "main_vpc_nat_gw" {
  allocation_id = aws_eip.main_vpc_nat_gw_eip.id
  subnet_id     = aws_subnet.region_az_1_public.id
  depends_on    = [aws_internet_gateway.main_vpc_igw]

  tags = merge(local.tags, {
    Name = "${var.username}-main-vpc-nat-gw"
  })
}


# -----------------------------------------------------------------------------
# Region route tables
# -----------------------------------------------------------------------------
resource "aws_route_table" "region_public_routes" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(local.tags, {
    Name = "${var.username}-region-public-route-table"
  })
}

resource "aws_route_table_association" "region_az_1_public_subnet" {
  subnet_id      = aws_subnet.region_az_1_public.id
  route_table_id = aws_route_table.region_public_routes.id
}

resource "aws_route_table_association" "region_az_2_public_subnet" {
  subnet_id      = aws_subnet.region_az_2_public.id
  route_table_id = aws_route_table.region_public_routes.id
}


resource "aws_route_table" "region_private_routes" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(local.tags, {
    Name = "${var.username}-region-private-route-table"
  })
}

resource "aws_route_table_association" "region_az_1_private_subnet" {
  subnet_id      = aws_subnet.region_az_1_private.id
  route_table_id = aws_route_table.region_private_routes.id
}

resource "aws_route_table_association" "region_az_2_private_subnet" {
  subnet_id      = aws_subnet.region_az_2_private.id
  route_table_id = aws_route_table.region_private_routes.id
}


# Routes
resource "aws_route" "region_igw_route" {
  route_table_id         = aws_route_table.region_public_routes.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_vpc_igw.id
}

resource "aws_route" "region_nat_gw_route" {
  route_table_id         = aws_route_table.region_private_routes.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main_vpc_nat_gw.id
}


# -----------------------------------------------------------------------------
# Main VPC - Outpost resources
# -----------------------------------------------------------------------------
resource "aws_subnet" "outpost_public" {
  vpc_id                  = aws_vpc.main_vpc.id
  availability_zone       = data.aws_outposts_outpost.selected.availability_zone
  outpost_arn             = data.aws_outposts_outpost.selected.arn
  cidr_block              = local.outpost_public_subnet
  map_public_ip_on_launch = true

  tags = merge(local.tags, map(
    "Name", "${var.username}-outpost-public-subnet",
    "kubernetes.io/cluster/${local.eks_cluster_name}", "shared",
    "kubernetes.io/role/elb", "1",
  ))
}

resource "aws_subnet" "outpost_private" {
  vpc_id                          = aws_vpc.main_vpc.id
  availability_zone               = data.aws_outposts_outpost.selected.availability_zone
  outpost_arn                     = data.aws_outposts_outpost.selected.arn
  cidr_block                      = local.outpost_private_subnet
  customer_owned_ipv4_pool        = data.aws_ec2_coip_pool.outpost_coip_pool.pool_id
  map_customer_owned_ip_on_launch = true

  tags = merge(local.tags, map(
    "Name", "${var.username}-outpost-private-subnet",
    "kubernetes.io/cluster/${local.eks_cluster_name}", "shared",
    "kubernetes.io/role/internal-elb", "1",
  ))
}


# -----------------------------------------------------------------------------
# Outpost route tables
# -----------------------------------------------------------------------------
resource "aws_route_table" "outpost_public_routes" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(local.tags, {
    Name = "${var.username}-outpost-public-route-table"
  })
}

resource "aws_route_table_association" "outpost_public_subnet" {
  subnet_id      = aws_subnet.outpost_public.id
  route_table_id = aws_route_table.outpost_public_routes.id
}


resource "aws_route_table" "outpost_private_routes" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(local.tags, {
    Name = "${var.username}-outpost-private-routes"
  })
}

resource "aws_route_table_association" "outpost_private_subnet" {
  subnet_id      = aws_subnet.outpost_private.id
  route_table_id = aws_route_table.outpost_private_routes.id
}

# Local gateway (lgw) route table association
resource "aws_ec2_local_gateway_route_table_vpc_association" "lgw_association" {
  vpc_id                       = aws_vpc.main_vpc.id
  local_gateway_route_table_id = data.aws_ec2_local_gateway_route_table.lgw_rtb.id
}


# Routes
resource "aws_route" "outpost_igw_route" {
  route_table_id         = aws_route_table.outpost_public_routes.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_vpc_igw.id
}

resource "aws_route" "outpost_nat_gw_route" {
  route_table_id         = aws_route_table.outpost_private_routes.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main_vpc_nat_gw.id
}

resource "aws_route" "outpost_public_lgw_route" {
  count = var.on_prem_vpc ? 1 : 0

  route_table_id         = aws_route_table.outpost_public_routes.id
  destination_cidr_block = module.on_prem_vpc[0].on_prem_vpc_cidr
  local_gateway_id       = data.aws_ec2_local_gateway_route_table.lgw_rtb.local_gateway_id
  depends_on             = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}

resource "aws_route" "outpost_private_lgw_route" {
  count = var.on_prem_vpc ? 1 : 0

  route_table_id         = aws_route_table.outpost_private_routes.id
  destination_cidr_block = module.on_prem_vpc[0].on_prem_vpc_cidr
  local_gateway_id       = data.aws_ec2_local_gateway_route_table.lgw_rtb.local_gateway_id
  depends_on             = [aws_ec2_local_gateway_route_table_vpc_association.lgw_association]
}


# -----------------------------------------------------------------------------
# Security groups
# -----------------------------------------------------------------------------
resource "aws_security_group" "alpha" {
  name        = "${var.username}-alpha-sg"
  description = "Allow all communication within the alpha security group"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow all traffic sourced from this security group"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    self        = true
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "beta" {
  name        = "${var.username}-beta-sg"
  description = "Allow all communication within the beta security group"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow all traffic sourced from this security group"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    self        = true
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "outpost" {
  name        = "${var.username}-outpost-sg"
  description = "Allow traffic from the Outpost"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "All traffic from the outpost CIDR range"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.outpost_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
