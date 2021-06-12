#done
#the required terraform version
terraform {
  required_version = ">= 0.13"
}

#aws provider, will give us the ability to deploy aws infrastructure, and aws authentications
provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
  access_key = var.my-access-key
  secret_key = var.my-secret-key
}


#these data sources will give help us to parse data outside of the terraform to different modules
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_availability_zones" "available" {
}


#creates a security group for our self managed nodes
resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8", "172.31.32.0/20"
    ]
  }
}

#creates a vpc to run in our cluster
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name                 = "SelaTask-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
#creates subnets in the vpc (not all of them will be used they are just available)
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
#we need to enable these three options in order that our auto scaling worker nodes will be able to connect
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

}

#creates the eks cluster
module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.20"
  subnets         = module.vpc.private_subnets
  version = "12.2.0"
  cluster_create_timeout = "1h"
  cluster_endpoint_private_access = true

  vpc_id = module.vpc.vpc_id

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 1
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    },
  ]

}


#module to create ECR
resource "aws_ecr_repository" "SelaTaskECR" {
  name                 = "selataskecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

#module to create pods not yet relevant
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  version                = "~> 1.11"
}
