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
# Storage Gateway variables
# -----------------------------------------------------------------------------
variable "subnet_ids" {
  type = list(string)
}

