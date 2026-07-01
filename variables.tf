# -----------------------------------------------------------------------------
# Required configuration variables
# -----------------------------------------------------------------------------
variable "username" {
  type        = string
  description = "Your username - will be prepended to most resource names to track what's yours."
  default     = "thjared"
}

variable "profile" {
  type        = string
  description = "The AWS CLI profile to use for Terraform API calls. Leave empty to use environment variables or instance profile."
  default     = ""
}


# -----------------------------------------------------------------------------
# Optional configuration variables
# -----------------------------------------------------------------------------

variable "region" {
  type        = string
  description = "The parent region of the Outposts Test Lab (OTL) rack. The main VPC will be deployed in this region and the VPC extended to the Outpost."
  default     = "us-east-1"
}

variable "main_vpc_cidr" {
  type        = string
  description = "A /16 CIDR block for the main VPC (extended to the Outpost). By default, the module will generate a random 10.x.0.0/16 VPC CIDR block."
  default     = ""
}

variable "eks_cluster_on_outpost_instance_type" {
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
  description = "Enable EKS Extended Cluster: control plane in the Region, self-managed worker nodes on the Outpost. The cluster API endpoint is in the Region."
}

variable "eks_cluster" {
  type        = bool
  default     = true
  description = "Deploy the EKS Extended Cluster control plane in the Region (requires eks = true)."
}

variable "eks_cluster_on_outposts" {
  type        = bool
  default     = false
  description = "Deploy an EKS Local Cluster on Outposts: both control plane AND data plane run on the Outpost. Operates independently during network disconnects."
}


variable "eks_outpost_node_group" {
  type        = bool
  default     = true
  description = "Deploy a self-managed EKS node group on the Outpost (attaches to the Extended Cluster or Local Cluster depending on which is enabled)."
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
  description = "Known OTL Outpost IDs across all regions. The module auto-detects which outpost is shared to the deploying account. NOTE: You must set the 'region' variable to match the region where your Outpost is located — the AWS API only returns outposts visible in the queried region."
  type = set(string)
  default = [
    "op-0026df29a81fb280f",
    "op-00934a250e2d56300",
    "op-00d1c0eafad460113",
    "op-011dc3d717dabd79d",
    "op-012a64d7a1e3d5e08",
    "op-0145b7ef2d61c4182",
    "op-01959d4727998a00f",
    "op-01f1d0e443019b65f",
    "op-025c9736ba04e9a51",
    "op-0268f76782a30c66a",
    "op-02abdd7f5cf465e30",
    "op-02c4c84ad0699dee2",
    "op-034903a5762810701",
    "op-0352c5544fa067bd2",
    "op-038c57b8f5d09dfa1",
    "op-039f5eea8007fd18e",
    "op-03a6827b6dac9579f",
    "op-03a6cb1dc83c0fa32",
    "op-03c36a2fe3b1d1b09",
    "op-0433fd3a9adcf40e1",
    "op-045c7f4bd92d46621",
    "op-04db6e67e9859c93a",
    "op-05cb517a2ecf9b5f6",
    "op-0663daef268ef9183",
    "op-06bc2de99ffbee257",
    "op-06c48ce1ad3fe2d6b",
    "op-06ca40befcfd25787",
    "op-06d594d204174c310",
    "op-0787f05bdad8d2fd8",
    "op-07b4f96f3dd22adfd",
    "op-07d9c91d86a49bb5a",
    "op-07ea713617990f28d",
    "op-07f6f537e0607d3f1",
    "op-0800860ae74d9949f",
    "op-08167c1a9cb224511",
    "op-082ab5afd45fcdc9f",
    "op-08607141738b8e4c0",
    "op-089766f4c28d06646",
    "op-0898f25660525df39",
    "op-08c07b64b5012e102",
    "op-093c3548a8517c114",
    "op-0954274a591bb158c",
    "op-097705e3b2105fb5c",
    "op-0a0935d605cfcfd28",
    "op-0a4aeaeea67670f50",
    "op-0a8c1ab53b023a5a4",
    "op-0ad505fedd56c43fb",
    "op-0b037a1af7a46eea4",
    "op-0b056e179d931973c",
    "op-0bc294da55e3d90ba",
    "op-0c21bfcc948a576d1",
    "op-0c74f70820f79907c",
    "op-0cb063b193fc73e4c",
    "op-0cd13c7ec21b132c9",
    "op-0deeb1939df1439dd",
    "op-0e249248bdcf952a0",
    "op-0e532e26b9a150b8d",
    "op-0ebf0663890064ba5",
    "op-0f87c2c6671975b1e",
    "op-0f96fca2343d62dbd"
  ]
}
