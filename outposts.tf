# Get all AWS Outposts visible to the caller
data "aws_outposts_outposts" "all" {}

locals {
  # Select the first OTL Outpost ID that is visible to the caller account
  outpost_id = coalesce(setintersection(data.aws_outposts_outposts.all.ids, var.otl_outpost_ids)...)
}

data "aws_outposts_outpost" "selected" {
  id = local.outpost_id
}

data "aws_ec2_local_gateway_route_table" "lgw_rtb" {
  outpost_arn = data.aws_outposts_outpost.selected.arn
}

data "aws_ec2_coip_pool" "outpost_coip_pool" {}
