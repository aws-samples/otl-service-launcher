# -----------------------------------------------------------------------------
# Common module variables
# -----------------------------------------------------------------------------
variable "tags" {
  type        = map(any)
  default     = {}
  description = "Common tags to apply to all taggable resources."
}


# -----------------------------------------------------------------------------
# EKS on Outposts node group variables
# -----------------------------------------------------------------------------

# Required
variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "outpost_subnet_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "security_group" {
  type = string
}

# Optional
variable "node_group_name" {
  type    = string
  default = "outpost"
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 1
}

variable "virtualization_type" {
  type    = string
  default = "hvm"
}

variable "architecture" {
  type    = string
  default = "x86_64"
}

variable "root_device_type" {
  type    = string
  default = "ebs"
}

variable "volume_type" {
  type    = string
  default = "gp2"
}

variable "volume_device_name" {
  type    = string
  default = "/dev/xvda"
}

variable "volume_size" {
  type    = number
  default = 20
}
