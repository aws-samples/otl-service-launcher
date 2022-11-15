# -----------------------------------------------------------------------------
# Common module variables
# -----------------------------------------------------------------------------
variable "tags" {
  type        = map(any)
  default     = {}
  description = "Common tags to apply to all taggable resources."
}


# -----------------------------------------------------------------------------
# EKS variables
# -----------------------------------------------------------------------------
variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "service_ipv4_cidr" {
  type = string
}

variable "cluster_subnet_ids" {
  type = list(string)
}

variable "instance_type" {
  type = string
}

variable "outpost_arn" {
  type = set(string)

}
