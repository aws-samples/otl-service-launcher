terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }

    null = {
      source  = "hashicorp/null"
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
  profile = var.profile != "" ? var.profile : null
}

# Verify provider connectivity and collect caller information
data "aws_caller_identity" "current" {}


# -----------------------------------------------------------------------------
# Kubernetes Provider
# -----------------------------------------------------------------------------

# Configure the root provider
provider "kubernetes" {
  host                   = concat(module.eks_cluster[*].cluster_endpoint, [""])[0]
  cluster_ca_certificate = base64decode(concat(module.eks_cluster[*].cluster_ca_cert, [""])[0])
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", local.eks_cluster_name]
    command     = "aws"
  }
}

# Note: EKS Local Cluster aws-auth is managed via null_resource with kubectl
# in the node group module. A kubernetes provider cannot be used because providers
# are evaluated at plan time — if eks_cluster_on_outposts=false, the endpoint
# resolves to empty and Terraform connects to localhost:80.
