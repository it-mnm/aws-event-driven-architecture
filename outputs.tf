# outputs.tf (최상위 루트 폴더용)

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

# 🎯 공장(module.vpc)에서 흘러나온 보안 그룹 ID를 최종 출력
output "public_web_sg_id" {
  value = module.vpc.public_web_sg_id
}

output "alb_dns_name" {
    value = module.alb.alb_dns_name
    description = "Application Load Balancer 도메인 주소"
}

output "sqs_queue_url" {
  value       = module.sqs.queue_url
  description = "메인 SQS 큐의 URL 주소"
}