# -------------------------
# Provider
# -------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# -------------------------
# VPC
# -------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "private-vpc"
  }
}

# -------------------------
# Private Subnets (multi-AZ)
# -------------------------
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1a"

  tags = { Name = "private-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1b"

  tags = { Name = "private-subnet-2" }
}

# -------------------------
# NAT Gateway
# -------------------------

resource "aws_subnet" "nat_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.100.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1a"
}

# Internet Gateway pour NAT
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Elastic IP pour NAT
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.gw]
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.nat_subnet.id
  tags = { Name = "private-nat" }
}

# -------------------------
# Route Table privée
# -------------------------
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "private-rt" }
}

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}

# -------------------------
# Security Group privé
# -------------------------
resource "aws_security_group" "private_sg" {
  name   = "private-sg"
  vpc_id = aws_vpc.main.id

  # accès interne seulement
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # NAT permet sortie Internet
  }
}

# -------------------------
# IAM User pour Terraform
# -------------------------
resource "aws_iam_user" "terraform" {
  name = "terraform-user-1"
}

resource "aws_iam_access_key" "terraform_key" {
  user = aws_iam_user.terraform.name
}

resource "aws_iam_user_policy_attachment" "terraform_attach" {
  user       = aws_iam_user.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

