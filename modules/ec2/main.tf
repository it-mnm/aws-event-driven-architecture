# modules/ec2/main.tf

# 1. 최신 Ubuntu 24.04 LTS 가상 머신 이미지(AMI) 자동 검색하기
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical (Ubuntu 공식 배포처 ID)
}

# 2. 실물 EC2 인스턴스 컴퓨터 생성
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id # 위에서 검색한 최신 OS 이미지 ID 적용
  instance_type = var.instance_type

  subnet_id              = var.subnet_id       # 던져준 퍼블릭 서브넷 방에 배치
  vpc_security_group_ids = [var.public_web_sg_id] # 던져준 경비실(보안그룹) 채우기

  # 퍼블릭 서브넷에 들어갈 컴퓨터이므로 외부 IP(Public IP)를 자동으로 할당받도록 설정
  associate_public_ip_address = true 

  tags = {
    Name = "mh-web-server-${var.env_name}"
  }
}