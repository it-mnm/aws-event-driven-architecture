# modules/vpc/outputs.tf

# 1. VPC 본체 ID 내보내기
output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC 본체 ID"
}

# 2. 퍼블릭 서브넷 ID 리스트 내보내기
output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "퍼블릭 서브넷 ID 리스트"
}

# 3. 프라이빗 서브넷 ID 리스트 내보내기
output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "프라이빗 서브넷 ID 리스트"
}

# 🎯 [핵심] 방금 만든 웹 퍼블릭 보안 그룹 ID를 바깥세상으로 던져줍니다.
output "public_web_sg_id" {
  value       = aws_security_group.public_web.id
  description = "퍼블릭 웹 보안 그룹 ID"
}