# -----------------------------------------------------------------------------
# Common module variables
# -----------------------------------------------------------------------------
variable "username" {
  type        = string
  description = "Your username - will be prepended to most resource names to track what's yours."
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Common tags to apply to all taggable resources."
}


# -----------------------------------------------------------------------------
# On-premises VPC variables
# -----------------------------------------------------------------------------
variable "on_prem_vpc_cidr" {
  type = string
}

variable "outpost_coip_pool_cidrs" {
  type = set(string)
}
