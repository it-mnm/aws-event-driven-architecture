# modules/vpc/main.tf
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "mh-vpc-${var.env_name}"
  }
}

# Public 서브넷 생성 (ALB 관문용 - 외부 통신용)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "mh-public-subnet-${count.index + 1}-${var.env_name}"
  }
}

# Private 서브넷 생성 (APP 백엔드 격리 영역 - 보안용)
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "mh-private-subnet-${count.index + 1}-${var.env_name}"
  }
}