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

module "ec2" {
  source = "./modules/ec2"

  env_name         = var.env_name
  
  # 🎯 [조립 포인트] VPC 모듈이 출구로 뱉어낸 퍼블릭 서브넷 첫 번째 방(0번 index)과 보안 그룹 ID를 직통으로 꽂아줍니다!
  subnet_id        = module.vpc.public_subnet_ids[0]
  public_web_sg_id = module.vpc.public_web_sg_id
}