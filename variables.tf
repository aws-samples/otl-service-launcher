# -----------------------------------------------------------------------------
# Required configuration variables
# -----------------------------------------------------------------------------
variable "username" {
  type        = string
  description = "Your username - will be prepended to most resource names to track what's yours."
}

variable "profile" {
  type        = string
  description = "The AWS CLI profile to use for Terraform API calls."
  default     = "default"
}

variable "region" {
  type        = string
  description = "The region to which the Outposts Test Lab (OTL) rack is attached."
  default     = "us-west-2"
}

variable "main_vpc_cidr" {
  type        = string
  description = "A /16 CIDR block for the main VPC (extended to the Outpost). By default, the module will generate a random 10.x.0.0/16 VPC CIDR block."
  default     = ""
}


# -----------------------------------------------------------------------------
# Common Tags
# -----------------------------------------------------------------------------
variable "tags" {
  type        = map(any)
  default     = {}
  description = "Common tags to apply to all taggable resources."
}

locals {
  tags = merge(var.tags, {
    Username    = var.username
    CallerARN   = data.aws_caller_identity.current.arn
    OutpostName = data.aws_outposts_outpost.selected.name
    OurpostARN  = data.aws_outposts_outpost.selected.arn
  })
}


# -----------------------------------------------------------------------------
# Service deployment flags
# -----------------------------------------------------------------------------
variable "region_cloud9" {
  type        = bool
  default     = false
  description = "Set this to true if you want to deploy a Cloud9 bastion in the Region."
}

variable "outpost_cloud9" {
  type        = bool
  default     = false
  description = "Set this to true if you want to deploy a Cloud9 bastion in the Outpost"
}

variable "eks" {
  type        = bool
  default     = false
  description = "Set this to true if you want to deploy an EKS cluster."
}

variable "emr" {
  type        = bool
  default     = false
  description = "Set this to true if you want to deploy an EMR cluster."
}

variable "memcached" {
  type        = bool
  default     = false
  description = "Set this to true if you want to deploy an ElastiCache Memcached instance."
}

variable "redis" {
  type        = bool
  default     = false
  description = "Set this to true if you want to deploy an ElastiCache Redis instance."
}

variable "mysql" {
  type        = bool
  default     = false
  description = "Set this to true if you want to deploy an RDS MySQL instance."
}

variable "postgres" {
  type        = bool
  default     = false
  description = "Set this to true if you want to deploy an RDS PostgreSQL instance."
}

variable "on_prem_vpc" {
  type        = bool
  default     = false
  description = "Set this to true if you want to deploy a VPC to simulate an on-premises network."
}


# -----------------------------------------------------------------------------
# Outposts Test Labs (OTL) variables
# -----------------------------------------------------------------------------
variable "otl_outpost_ids" {
  type = set(string)
  default = [
    "op-0d4579457ff2dc345",
    "op-06d8ac52958c596a7",
    "op-0a8c1ab53b023a5a4",
    "op-0268f76782a30c66a",
    "op-02c4c84ad0699dee2",
    "op-0e532e26b9a150b8d",
    "op-0c74f70820f79907c",
    "op-0e32dade1930682b8",
    "op-06d594d204174c310",
    "op-09d4c743ed7a5780b",
    "op-0cc27b83880c7d8e9"
  ]
}


# -----------------------------------------------------------------------------
# Simulated on-premises network variables
# -----------------------------------------------------------------------------
variable "on_prem_vpc_cidr" {
  type        = string
  description = "A /19 (minimum) CIDR block for the simulated on-premises VPC. By default, the module will generate a random CIDR block in the 172.16.0.0/12 range."
  default     = ""
}
