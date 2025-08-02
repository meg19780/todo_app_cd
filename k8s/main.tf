terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create VPC and subnets
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "eks-vpc" }
}

resource "aws_subnet" "public" {
  count = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "public-subnet-${count.index}" }
}

data "aws_availability_zones" "available" {}

# Create EKS cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 18.0"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.33"
  vpc_id          = aws_vpc.main.id
  subnet_ids      = aws_subnet.public[*].id
}

# Load EKS cluster info (depends on module)
data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
}

# Load cluster auth (depends on module)
data "aws_eks_cluster_auth" "cluster" {

  name       = module.eks.cluster_name
}

# Configure Kubernetes provider (depends on data sources)
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

}

# Configure Helm provider (depends on data sources)
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  }

}

# Create namespace for Argo
resource "kubernetes_namespace" "argo" {
  metadata {
    name = "argo"
  }

}

# Helm release to install Argo
resource "helm_release" "argo" {
  name             = "argo"
  namespace        = kubernetes_namespace.argo.metadata[0].name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo"
  version          = "3.3.4"
  create_namespace = false
}
