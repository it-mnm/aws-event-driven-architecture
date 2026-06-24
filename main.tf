module "vpc" {
  source = "./modules/vpc"

  # 1단계 변수 토스
  env_name           = var.env_name
  vpc_cidr           = var.vpc_cidr

  # 🎯 [에러 해결 포인트] 부품 공장으로 서브넷 핵심 재료들을 밀어 넣어줍니다.
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}