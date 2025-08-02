terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Change as needed
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
  }
}

# Create Subnets
resource "aws_subnet" "public" {
  count = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 18.0"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.33"

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  # Optional: enable inline managed node groups
  # For simplicity, you'll create separate node groups below.
}

# Create a Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "default-ng"
  node_role_arn   = "arn:aws:iam::379196643514:user/terraform"  # Replace with your IAM role ARN
  subnet_ids      = aws_subnet.public[*].id
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  instance_types = ["t3.medium"]
}
