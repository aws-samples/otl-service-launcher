# -----------------------------------------------------------------------------
# Storage Gateway
# -----------------------------------------------------------------------------
outpost "gateway_key_pair_name" {
  value = aws_key_pair.storagegateway.key_name
}
