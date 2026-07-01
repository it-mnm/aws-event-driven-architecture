# modules/ec2/variables.tf

variable "env_name" {
  type        = string
  description = "환경 명칭 (dev / prd)"
}

variable "ami_id" {
  type        = string
  default     = "ami-0bc151a94289adb52" # Ubuntu 22.04 LTS 등의 기본 AMI ID (상위 main.tf에서 주입 시 생략 가능)
  description = "EC2 가동을 위한 우분투 이미지 ID"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro" # 가성비 좋은 t3.micro를 기본값으로 세팅
  description = "EC2 인스턴스 스펙 유형"
}

variable "public_security_group_id" {
  type        = string
  description = "VPC 모듈에서 생성된 퍼블릭 보안 그룹 ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "서버들을 분산 배치할 퍼블릭 서브넷 ID 리스트"
}

variable "target_group_arn" {
  type        = string
  description = "서버들을 바인딩할 ALB 타깃 그룹의 ARN"
}