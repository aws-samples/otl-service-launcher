terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.39.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0.2"
      configuration_aliases = [ kubernetes.eks_cluster, kubernetes.local_cluster ]
    }
  }
}


# -----------------------------------------------------------------------------
# AWS Provider
# -----------------------------------------------------------------------------

# Configure the root provider
provider "aws" {
  region = var.region
  # profile = var.profile
  # profile = terraform.workspace
}

# Verify provider connectivity and collect caller information
data "aws_caller_identity" "current" {}


# -----------------------------------------------------------------------------
# Kubernetes Provider
# -----------------------------------------------------------------------------

# Configure the root provider
provider "kubernetes" {
  host                   = concat(module.eks_cluster[*].cluster_endpoint, [""])[0]
  #host                   = concat(module.eks_on_outposts[*].cluster_endpoint, [""])[0]
  cluster_ca_certificate = base64decode(concat(module.eks_cluster[*].cluster_ca_cert, [""])[0])
  #cluster_ca_certificate = base64decode(concat(module.eks_on_outposts[*].cluster_ca_cert, [""])[0])
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", local.eks_cluster_name]
    command     = "aws"
  }
  alias = "eks_cluster"
}

# Configure the root provider for local cluster
provider "kubernetes" {
  host                   = concat(module.eks_local_cluster[*].local_cluster_endpoint, [""])[0]
  cluster_ca_certificate = base64decode(concat(module.eks_local_cluster[*].local_cluster_ca_cert, [""])[0])
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", local.eks_local_cluster_name]
    command     = "aws"
  }
  #config_context_auth_info = "ops2"
  #config_context_cluster   = "local_cluster"
  alias = "local_cluster"
}
