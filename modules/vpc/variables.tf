# modules/vpc/variables.tf
variable "vpc_cidr" {
  type        = string
  description = "VPC의 메인 CIDR 블록 대역"
}

variable "env_name" {
  type        = string
  description = "인프라 환경 명칭 (dev / prd)"
}


variable "public_subnets" {
  type        = list(string)
  description = "퍼블릭 서브넷 CIDR 리스트 (2개 가용영역용)"
}

variable "private_subnets" {
  type        = list(string)
  description = "프라이빗 서브넷 CIDR 리스트 (2개 가용영역용)"
}

variable "availability_zones" {
  type        = list(string)
  description = "서브넷을 배치할 가용영역 리스트"
}