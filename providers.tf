terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.29.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}


# -----------------------------------------------------------------------------
# AWS Provider
# -----------------------------------------------------------------------------

# Configure the root provider
provider "aws" {
  region  = var.region
  profile = var.profile
  # profile = terraform.workspace
}

# Verify provider connectivity and collect caller information
data "aws_caller_identity" "current" {}
