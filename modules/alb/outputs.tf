# modules/alb/outputs.tf

output "alb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "ALB의 외부 접속용 도메인 주소"
}

output "target_group_arn" {
  value       = aws_lb_target_group.this.arn
  description = "ALB 목적지 그룹(Target Group)의 ARN 주소"
}