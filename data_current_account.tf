data "aws_caller_identity" "current" {
	
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "caller_user" {
  value = data.aws_caller_identity.current.user_id
}

data "aws_outposts_outposts" "all_ops" {

}

data "aws_outposts_outpost" "op" {
  id = [for op_id in data.aws_outposts_outposts.all_ops.ids : op_id if contains([
      "op-0d4579457ff2dc345",
      "op-06d8ac52958c596a7",
      "op-0a8c1ab53b023a5a4",
      "op-0268f76782a30c66a",
      "op-02c4c84ad0699dee2",
      "op-0e532e26b9a150b8d",
      "op-0c74f70820f79907c",
      "op-0e32dade1930682b8",
      "op-06d594d204174c310",
      "op-09d4c743ed7a5780b",
      "op-0cc27b83880c7d8e9"
    ], op_id)][0]
}

data "aws_ec2_local_gateway_route_table" "lgw_rtb" {
  outpost_arn = data.aws_outposts_outpost.op.arn
}

data "aws_ec2_coip_pool" "op_coip_pool" {

}
