# modules/sqs/main.tf

# 1. 처리 실패한 메시지들이 모이는 '반송 우편함 (Dead Letter Queue)'
resource "aws_sqs_queue" "dlq" {
  name = "mh-event-dlq-${var.env_name}"
  
  # 오류 메시지는 분석을 위해 조금 더 길게(4일) 보관합니다.
  message_retention_seconds = 345600 

  tags = {
    Name = "mh-event-dlq-${var.env_name}"
  }
}

# 2. 서비스 이벤트를 수신할 '메인 우편함 (Main Queue)'
resource "aws_sqs_queue" "main" {
  name                      = "mh-event-queue-${var.env_name}"
  message_retention_seconds = var.message_retention_seconds
  
  # 🎯 [핵심 설정] 3번 이상 가져갔는데도 처리에 실패하면 자동으로 위의 DLQ(반송함)로 던집니다.
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "mh-event-queue-${var.env_name}"
  }
}