# Configure the AWS Provider
provider "aws" {
  version = "~> 3.0"
  region  = var.region
  profile = terraform.workspace
}

module "eks_mod" {
  source = "./modules/eks"
  count = var.do_eks ? 1 : 0
  name = var.name
  providers = provider.aws
}

module "elasticache_mod" {
  source = "./modules/elasticache"
  count = var.do_elasticache ? 1 : 0
  name = var.name
}

module "emr_mod" {
  source = "./modules/emr"
  count = var.do_emr ? 1 : 0
  name = var.name
}

module "rds_mod" {
  source = "./modules/rds"
  count = var.do_rds ? 1 : 0
  name = var.name
}
