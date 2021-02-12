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

variable "main_vpc_id" {
  type = string
}

# -----------------------------------------------------------------------------
# Storage Gateway variables
# -----------------------------------------------------------------------------

variable "region_prefixlist_mapping" {
  description = "mapping for finding correct prefix list for amazon corp"
  default = {
    "us-east-1" = "pl-60b85b09",
    "us-west-2" = "pl-f8a64391"
  }
}

variable "subnet_id" {
  type = string
}
