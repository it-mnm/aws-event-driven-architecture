# modules/sqs/variables.tf

variable "env_name" {
  type        = string
  description = "환경 명칭 (dev / prd)"
}

variable "message_retention_seconds" {
  type        = number
  default     = 86400 # 메시지 보관 주기 (기본 1일 = 86400초)
  description = "SQS 큐에 메시지를 보관할 시간"
}