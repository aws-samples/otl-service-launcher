terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster_module.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster_module.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

module "eks_cluster_module" {
  source  = "terraform-aws-modules/eks/aws"
  version = "14.0.0"
  vpc_id = aws_vpc.main_vpc.id
  subnets = [aws_subnet.region_public.id, aws_subnet.region_public_2.id, aws_subnet.op_private.id, aws_subnet.op_private_2.id]
  cluster_name = join("-",[var.name, "eks-cluster"])
  cluster_version = "1.18"
  worker_groups = [
    {
      instance_type = "m5.xlarge"
      asg_max_size  = 2
    }
  ]
}
