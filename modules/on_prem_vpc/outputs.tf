# -----------------------------------------------------------------------------
# On-Premises VPC
# -----------------------------------------------------------------------------
output "on_prem_vpc_id" {
  value = aws_vpc.on_prem_vpc.id
}

output "on_prem_vpc_cidr" {
  value = aws_vpc.on_prem_vpc.cidr_block
}
