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
# ElastiCache variables
# -----------------------------------------------------------------------------
variable "subnet_ids" {
  type = list(string)
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "parameter_group_name" {
  type = string
}

variable "node_type" {
  type = string
}

variable "num_cache_nodes" {
  type = number
}
