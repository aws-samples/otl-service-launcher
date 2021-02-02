variable "name" {
  type = string
  description = "Your username. Will be prepended to most resource names to track what's yours."
}

variable "region" {
  type = string
  description = "The region where you would like to deploy this infrastructure."
  default = "us-west-2"
}

variable "on_prem_cidr" {
  type = string
  description = "CIDR range for the 'on-prem' VPC that will be connected to the outside of the LGW."
  default = "10.40.0.0/16"
}

variable "op_cidr" {
  type = string
  description = "CIDR range for the VPC that will have subnets on the Outpost."
  default = "10.20.0.0/16"
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "region_number" {
  # Arbitrary mapping of region name to number to use in
  # a VPC's CIDR prefix.
  default = {
    us-east-1      = 1
    us-west-2      = 2
  }
}

variable "az_number" {
  # Assign a number to each AZ letter used in our configuration
  default = {
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
    f = 6
  }
}

variable "do_eks" {
  type = bool
  default = false
  description = "Set this to true if you want to stand up an EKS cluster."
}

variable "do_emr" {
  type = bool
  default = false
  description = "Set this to true if you want to stand up an EMR cluster."
}

variable "do_elasticache" {
  type = bool
  default = false
  description = "Set this to true if you want to stand up ElastiCache Redis and Memcached clusters."
}

variable "do_rds" {
  type = bool
  default = false
  description = "Set this to true if you want to stand up an RDS instance."
}
