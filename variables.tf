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


# -----------------------------------------------------------------------------
# Optional configuration variables
# -----------------------------------------------------------------------------

variable "region" {
  type        = string
  description = "The parent region of the Outposts Test Lab (OTL) rack. The main VPC will be deployed in this region and the VPC extended to the Outpost."
  default     = "eu-central-1"
}

variable "main_vpc_cidr" {
  type        = string
  description = "A /16 CIDR block for the main VPC (extended to the Outpost). By default, the module will generate a random 10.x.0.0/16 VPC CIDR block."
  default     = ""
}

variable "eks_local_cluster_instance_type" {
  type    = string
  default = "c5.xlarge"
}

variable "allowed_instance_types" {
  description = "Set this list to the instance size(s), in priority order, that you would like to use as the default size for instances created by the OTL service launcher."
  # so that this script doesn't eat your large instance capacity by default
  type = list(string)
  default = [
    "c5.large",
    "c5d.2xlarge",
    "m5.large",
    "m5d.large",
    "r5.large",
    "r5d.large",
    "c5.xlarge",
    "c5d.xlarge",
    "m5.xlarge",
    "m5d.xlarge",
    "r5.xlarge",
    "r5d.xlarge",
    "c5.2xlarge",
    "c5d.2xlarge",
    "m5.2xlarge",
    "m5d.2xlarge",
    "r5.2xlarge",
    "r5d.2xlarge"
  ]
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
    OutpostARN  = data.aws_outposts_outpost.selected.arn
  })
}


# -----------------------------------------------------------------------------
# Service deployment flags
# -----------------------------------------------------------------------------
variable "region_cloud9" {
  type        = bool
  default     = false
  description = "Deploy a Cloud9 bastion in the main VPC in the Region."
}

variable "outpost_cloud9" {
  type        = bool
  default     = false
  description = "Deploy a Cloud9 bastion in on the Outpost."
}

variable "emr" {
  type        = bool
  default     = false
  description = "Deploy an EMR cluster on the Outpost."
}

variable "memcached" {
  type        = bool
  default     = false
  description = "Deploy an ElastiCache Memcached instance on the Outpost."
}

variable "redis" {
  type        = bool
  default     = false
  description = "Deploy an ElastiCache Redis instance on the Outpost."
}

variable "eks" {
  type        = bool
  default     = false
  description = "Deploy an EKS cluster in the main VPC in the Region with a worker node on the Outpost."
}

variable "eks_cluster" {
  type        = bool
  default     = true
  description = "Deploy an EKS cluster in the main VPC."
}

variable "eks_local_cluster" {
  type        = bool
  default     = false
  description = "Deploy an EKS local cluster on Outposts in the main VPC."
}


variable "eks_outpost_node_group" {
  type        = bool
  default     = true
  description = "Deploy a self-managed EKS node group on the Outpost."
}

variable "eks_local_cluster_node_group" {
  type        = bool
  default     = true
  description = "Deploy a self-managed EKS node group for local cluster on the Outpost."
}

variable "mysql" {
  type        = bool
  default     = false
  description = "Deploy an RDS MySQL instance on the Outpost."
}

variable "postgres" {
  type        = bool
  default     = false
  description = "Deploy an RDS PostgreSQL instance on the Outpost."
}

variable "on_prem_vpc" {
  type        = bool
  default     = false
  description = "Deploy a VPC to simulate an on-premises network in the region and to enable connectivity to on-premises networks."
}

variable "file_gateway" {
  type        = bool
  default     = false
  description = "Set this to true if you want to deploy a file gateway."
}

variable "volume_gateway" {
  type        = bool
  default     = false
  description = "Set this to true if you want to deploy a volume gateway."
}

variable "tape_gateway" {
  type        = bool
  default     = false
  description = "Set this to true if you want to deploy a tape gateway."
}

# -----------------------------------------------------------------------------
# Simulated on-premises network variables
# -----------------------------------------------------------------------------
variable "on_prem_vpc_cidr" {
  type        = string
  description = "A /19 (minimum) CIDR block for the simulated on-premises VPC. By default, the module will generate a random CIDR block in the 172.16.0.0/12 range."
  default     = ""
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
    "op-0cc27b83880c7d8e9",
    "op-00d1c0eafad460113",
    "op-0663daef268ef9183",
    "op-045c7f4bd92d46621",
    "op-0bc294da55e3d90ba",
    "op-01959d4727998a00f",
    "op-039f5eea8007fd18e",
    "op-0ebf0663890064ba5",
    "op-07d9c91d86a49bb5a"
  ]
}
