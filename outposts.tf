# Get all AWS Outposts visible to the caller
data "aws_outposts_outposts" "all" {}

locals {
  # Select the first OTL Outpost ID that is visible to the caller account
  outpost_id = coalesce(setintersection(data.aws_outposts_outposts.all.ids, var.otl_outpost_ids)...)
  # get the set of instance types that are allowed by the stack and launchable on the Outpost
  # this does NOT check for capacity, so you may get ICE'd during launches
  allowed_outpost_instance_types = setintersection(var.allowed_instance_types, data.aws_outposts_outpost_instance_types.slots.instance_types)
}

data "aws_outposts_outpost" "selected" {
  id = local.outpost_id
}

data "aws_ec2_local_gateway_route_table" "lgw_rtb" {
  outpost_arn = data.aws_outposts_outpost.selected.arn
}

data "aws_outposts_outpost_instance_types" "slots" {
  arn = data.aws_outposts_outpost.selected.arn
}

data "aws_ec2_coip_pool" "outpost_coip_pool" {}
