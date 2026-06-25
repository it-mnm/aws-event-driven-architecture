# modules/alb/variables.tf

variable "env_name" {
  type        = string
  description = "환경 명칭 (dev / prd)"
}

variable "vpc_id" {
  type        = string
  description = "VPC 본체 ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "ALB가 위치할 퍼블릭 서브넷 ID 리스트"
}

variable "public_web_sg_id" {
  type        = string
  description = "ALB에 적용할 퍼블릭 웹 보안 그룹 ID"
}