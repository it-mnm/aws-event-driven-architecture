# modules/lambda/variables.tf

variable "env_name" {
  type        = string
  description = "환경 명칭 (dev / prd)"
}

variable "queue_arn" {
  type        = string
  description = "트리거로 연결할 SQS 큐의 ARN"
}