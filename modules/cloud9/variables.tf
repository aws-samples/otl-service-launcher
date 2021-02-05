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
# Cloud9 variables
# -----------------------------------------------------------------------------
variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "automatic_stop_time_minutes" {
  type = number
}
