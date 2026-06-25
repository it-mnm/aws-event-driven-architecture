# modules/ec2/variables.tf

variable "env_name" {
  type        = string
  description = "환경 명칭 (dev / prd)"
}

variable "subnet_id" {
  type        = string
  description = "EC2가 위치할 서브넷 ID"
}

variable "public_web_sg_id" {
  type        = string
  description = "적용할 퍼블릭 웹 보안 그룹 ID"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro" # 가성비 좋은 t3.micro를 기본값으로 세팅
  description = "EC2 인스턴스 스펙 유형"
}