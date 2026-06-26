# modules/sqs/outputs.tf

output "queue_url" {
  value       = aws_sqs_queue.main.id
  description = "메인 SQS 큐의 URL 주소"
}

output "queue_arn" {
  value       = aws_sqs_queue.main.arn
  description = "메인 SQS 큐의 고유 ARN 고유 식별자"
}