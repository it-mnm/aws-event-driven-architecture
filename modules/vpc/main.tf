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


# 외부 소통을 위한 인터넷 게이트웨이(IGW)
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id  # 우리 VPC 본체 ID를 동적으로 참조합니다.

  tags = {
    Name = "mh-igw-${var.env_name}"
  }
}

# 1. 퍼블릭 서브넷 전용 이정표 지도(라우팅 테이블) 생성
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  # 0.0.0.0/0 (모든 외부 인터넷 목적지)은 위에서 만든 대문으로 향하라는 규칙
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "mh-public-rt-${var.env_name}"
  }
}

# 2. 이 지도를 퍼블릭 서브넷들(2개)에 각각 손에 쥐어주기 (연결)
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets) # 퍼블릭 서브넷 개수만큼 반복(2번)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}