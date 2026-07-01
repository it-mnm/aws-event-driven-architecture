# Auto Scaling Group 명칭 출력
output "asg_name" {
  value       = aws_autoscaling_group.app.name
  description = "생성된 Auto Scaling Group의 이름"
}