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
# EMR variables
# -----------------------------------------------------------------------------
variable "release_label" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "master_instance_type" {
  type = string
}

variable "core_instance_type" {
  type = string
}

variable "core_instance_count" {
  type = number
}
