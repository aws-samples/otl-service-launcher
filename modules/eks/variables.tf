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
# EKS variables
# -----------------------------------------------------------------------------
variable "region_public_subnet_ids" {
  type = list(string)
}

variable "outpost_private_subnet_ids" {
  type = list(string)
}

variable "kubernetes_version" {
  type = string
}

variable "service_ipv4_cidr" {
  type = string
}

variable "instance_types" {
  type = list(string)
}

variable "node_count" {
  type = number
}
