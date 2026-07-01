# Get all AWS Outposts visible to the caller
data "aws_outposts_outposts" "all" {}

locals {
  # Select the first OTL Outpost ID that is visible to the caller account
  _outpost_intersection = setintersection(data.aws_outposts_outposts.all.ids, var.otl_outpost_ids)
  outpost_id = length(local._outpost_intersection) > 0 ? tolist(local._outpost_intersection)[0] : tolist(data.aws_outposts_outposts.all.ids)[0]
  # get the set of instance types that are allowed by the stack and launchable on the Outpost
  # this does NOT check for capacity, so you may get ICE'd during launches
  allowed_outpost_instance_types = setintersection(var.allowed_instance_types, data.aws_outposts_outpost_instance_types.slots.instance_types)
}

data "aws_outposts_outpost" "selected" {
  id = local.outpost_id
}

data "aws_ec2_local_gateway_route_tables" "all" {
  filter {
    name   = "outpost-arn"
    values = [data.aws_outposts_outpost.selected.arn]
  }
}

locals {
  # Use the first LGW route table (active or not — it becomes active when a VPC is attached)
  lgw_rtb_ids = data.aws_ec2_local_gateway_route_tables.all.ids
  lgw_rtb_id  = tolist(local.lgw_rtb_ids)[0]
}

data "aws_ec2_local_gateway_route_table" "selected" {
  local_gateway_route_table_id = local.lgw_rtb_id
}

data "aws_ec2_coip_pools" "available" {
  filter {
    name   = "coip-pool.local-gateway-route-table-id"
    values = [local.lgw_rtb_id]
  }
}

locals {
  has_coip      = length(data.aws_ec2_coip_pools.available.pool_ids) > 0
  coip_pool_id  = local.has_coip ? tolist(data.aws_ec2_coip_pools.available.pool_ids)[0] : ""
}

data "aws_ec2_coip_pool" "outpost_coip_pool" {
  count   = local.has_coip ? 1 : 0
  pool_id = local.coip_pool_id
}

locals {
  coip_pool_cidrs = local.has_coip ? data.aws_ec2_coip_pool.outpost_coip_pool[0].pool_cidrs : []
}
data "aws_outposts_outpost_instance_types" "slots" {
  arn = data.aws_outposts_outpost.selected.arn
}

output "outpost_ids" {
  value = data.aws_outposts_outposts.all.ids
}
