# modules/ec2/outputs.tf

output "instance_id" {
  value       = aws_instance.web.id
  description = "생성된 EC2 인스턴스의 ID"
}