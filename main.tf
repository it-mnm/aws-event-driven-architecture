module "vpc" {
  source   = "./modules/vpc"
  env_name = var.env_name
  vpc_cidr = var.vpc_cidr
}