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
      "10.0.0.0/8",
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

#gives us the option to use tags in order to refer a subnet
/*  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }*/
}

#creates the eks cluster
module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.17"
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
  name                 = "SelaTaskECR"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}
//#Get AWS account id
//data "aws_caller_identity" "current" {
//
//}
//
//#Create IAM User
//resource "aws_iam_user" "ST_ecr" {
//  name = "ci-ST_ecr"
//
//}
//
//#Create Key
//resource "aws_iam_access_key" "aws_access_key" {
//  user = aws_iam_user.ST_ecr.name
//
//  depends_on = [
//    aws_iam_user.ST_ecr
//  ]
//}
//
//data "aws_iam_policy_document" "user_policy" {
//  statement {
//    effect = "Allow"
//    actions = [
//      "ecr:PutLifecyclePolicy",
//      "ecr:PutImageTagMutability",
//      "ecr:DescribeImageScanFindings",
//      "ecr:StartImageScan",
//      "ecr:GetLifecyclePolicyPreview",
//      "ecr:GetDownloadUrlForLayer",
//      "ecr:ListTagsForResource",
//      "ecr:UploadLayerPart",
//      "ecr:ListImages",
//      "ecr:PutImage",
//      "ecr:UntagResource",
//      "ecr:BatchGetImage",
//      "ecr:DescribeImages",
//      "ecr:TagResource",
//      "ecr:DescribeRepositories",
//      "ecr:StartLifecyclePolicyPreview",
//      "ecr:InitiateLayerUpload",
//      "ecr:BatchCheckLayerAvailability",
//      "ecr:GetRepositoryPolicy",
//      "ecr:GetLifecyclePolicy",
//      "ecr:GetAuthorizationToken",
//      "ecr:CompleteLayerUpload"
//    ]
//
//    resources = [aws_ecr_repository.SelaTaskECR.arn]
//  }
//  statement {
//    effect = "Allow"
//    actions = [
//      "ecr:GetAuthorizationToken",
//      "ecr:GetDownloadUrlForLayer",
//      "ecr:BatchGetImage",
//      "ecr:BatchCheckLayerAvailability"
//    ]
//
//    resources = ["*"]
//  }
//}

//#module to create pods not yet relevant
//provider "kubernetes" {
//  host                   = data.aws_eks_cluster.cluster.endpoint
//  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
//  token                  = data.aws_eks_cluster_auth.cluster.token
//  load_config_file       = false
//  version                = "~> 1.11"
//}
//
//resource "kubernetes_deployment" "example" {
//  metadata {
//    name = "terraform-example"
//    labels = {
//      test = "MyExampleApp"
//    }
//  }
//
//  spec {
//    replicas = 2
//
//    selector {
//      match_labels = {
//        test = "MyExampleApp"
//      }
//    }
//
//    template {
//      metadata {
//        labels = {
//          test = "MyExampleApp"
//        }
//      }
//
//      spec {
//        container {
//          image = "nginx:1.7.8"
//          name  = "example"
//
//          resources {
//            limits {
//              cpu    = "0.5"
//              memory = "512Mi"
//            }
//            requests {
//              cpu    = "250m"
//              memory = "50Mi"
//            }
//          }
//        }
//      }
//    }
//  }
//}
//
//resource "kubernetes_service" "example" {
//  metadata {
//    name = "terraform-example"
//  }
//  spec {
//    selector = {
//      test = "MyExampleApp"
//    }
//    port {
//      port        = 80
//      target_port = 80
//    }
//
//    type = "LoadBalancer"
//  }
//}
