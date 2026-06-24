# 1단계 기존 변수
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR 대역폭"
}

variable "env_name" {
  type        = string
  description = "환경 명칭 (dev / prd)"
}

# 🎯 [에러 해결 포인트] 루트 주문서에 서브넷 변수 3개를 정식 등록합니다.
variable "availability_zones" {
  type        = list(string)
  description = "가용영역 리스트"
}

variable "public_subnets" {
  type        = list(string)
  description = "퍼블릭 서브넷 CIDR 리스트"
}

variable "private_subnets" {
  type        = list(string)
  description = "프라이빗 서브넷 CIDR 리스트"
}