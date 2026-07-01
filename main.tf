# VPC 인프라 모듈 호출 및 변수 매핑
module "vpc" {
  source = "./modules/vpc"

  env_name           = var.env_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

# EC2 Auto Scaling 인프라 모듈 호출 및 변수 매핑
module "ec2" {
  source = "./modules/ec2"

  env_name                 = var.env_name
  instance_type            = "t3.micro"
  public_security_group_id = module.vpc.public_web_sg_id
  public_subnet_ids        = module.vpc.public_subnet_ids
  target_group_arn         = module.alb.target_group_arn
}

# Application Load Balancer 모듈 호출
module "alb" {
  source = "./modules/alb"

  env_name          = var.env_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  public_web_sg_id  = module.vpc.public_web_sg_id
}

# SQS 메시지 큐 모듈 호출
module "sqs" {
  source = "./modules/sqs"

  env_name = var.env_name
}

# Lambda 서버리스 컴퓨팅 모듈 호출
module "lambda" {
  source = "./modules/lambda"

  env_name  = var.env_name
  queue_arn = module.sqs.queue_arn 
}