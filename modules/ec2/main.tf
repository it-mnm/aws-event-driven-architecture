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
/*resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id # 위에서 검색한 최신 OS 이미지 ID 적용
  instance_type = var.instance_type

  subnet_id              = var.subnet_id       # 던져준 퍼블릭 서브넷 방에 배치
  vpc_security_group_ids = [var.public_web_sg_id] # 던져준 경비실(보안그룹) 채우기

  # 퍼블릭 서브넷에 들어갈 컴퓨터이므로 외부 IP(Public IP)를 자동으로 할당받도록 설정
  associate_public_ip_address = true 

    # 🎯 [11일차 핵심 포인트] 컴퓨터가 켜지자마자 실행할 쉘 스크립트를 주입합니다.

  user_data_replace_on_change = true
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install nginx -y
              sudo systemctl start nginx
              sudo systemctl enable nginx
              
              # 잘 작동하는지 확인용 홈페이지만들기
              echo "<h1>Hello from MyeongHyeon's DevOps World! via Terraform</h1>" | sudo tee /var/www/html/index.html
              
              # 1. Node Exporter 설치 (서버 자원 수집기)
              cd /opt
              wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
              tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz
              ./node_exporter-1.6.1.linux-amd64/node_exporter &

              # 2. Prometheus 설치 및 설정 자동화
              wget https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
              tar -xvf prometheus-2.47.0.linux-amd64.tar.gz
              cd prometheus-2.47.0.linux-amd64

              # 🎯 테라폼 내부 이스케이프 설정을 피해 안전하게 yaml 파일 한 줄로 덮어쓰기
              echo -e "global:\n  scrape_interval: 15s\n\nscrape_configs:\n  - job_name: 'prometheus'\n    static_configs:\n      - targets: ['localhost:9090', 'localhost:9100']" > prometheus.yml

              # 프로메테우스 엔진 가동
              ./prometheus --config.file=prometheus.yml &

              # 3. Grafana 설치 및 가동
              sudo apt-get install -y apt-transport-https software-properties-common wget
              sudo mkdir -p /etc/apt/keyrings/
              wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
              echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

              sudo apt-get update
              sudo apt-get install -y grafana
              sudo systemctl daemon-reload
              sudo systemctl start grafana-server
              sudo systemctl enable grafana-server            
              EOF
  tags = {
    Name = "mh-web-server-${var.env_name}"
  }
}*/

# modules/ec2/main.tf

# EC2 서버를 찍어낼 틀 (Launch Template)
resource "aws_launch_template" "app" {
  name_prefix   = "mh-app-template-${var.env_name}-"
  image_id      = var.ami_id          # 기존에 쓰던 Ubuntu AMI ID
  instance_type = var.instance_type   # 기존에 쓰던 t2.micro 등

  # 보안 그룹 연결 (VPC 모듈에서 넘어온 ID)
  vpc_security_group_ids = [var.public_security_group_id]

  # 모니터링+Nginx 자동 설치 스크립트
  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install nginx -y
              sudo systemctl start nginx
              sudo systemctl enable nginx
              
              echo "<h1>Hello from MyeongHyeon's DevOps World! via Auto Scaling</h1>" | sudo tee /var/www/html/index.html
              
              # 1. Node Exporter 설치
              cd /opt
              wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
              tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz
              ./node_exporter-1.6.1.linux-amd64/node_exporter &

              # 2. Prometheus 설치 및 설정 자동화
              wget https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
              tar -xvf prometheus-2.47.0.linux-amd64.tar.gz
              cd prometheus-2.47.0.linux-amd64

              echo -e "global:\n  scrape_interval: 15s\n\nscrape_configs:\n  - job_name: 'prometheus'\n    static_configs:\n      - targets: ['localhost:9090', 'localhost:9100']" > prometheus.yml

              ./prometheus --config.file=prometheus.yml &

              # 3. Grafana 설치 및 가동
              sudo apt-get install -y apt-transport-https software-properties-common wget
              sudo mkdir -p /etc/apt/keyrings/
              wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
              echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

              sudo apt-get update
              sudo apt-get install -y grafana
              sudo systemctl daemon-reload
              sudo systemctl start grafana-server
              sudo systemctl enable grafana-server            
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# 서버 개수를 자동으로 조절(Auto Scaling Group)
resource "aws_autoscaling_group" "app" {
  name_prefix         = "mh-asg-${var.env_name}-"
  desired_capacity    = 2  # 평시에 유지할 서버 개수 (2대)
  min_size            = 2  # 최소 유지 2대
  max_size            = 4  # 최대 4대까지 스케일링
  
  # 퍼블릭 서브넷 레이어에 분산 배치 (VPC 모듈에서 받아온 서브넷 ID 배열)
  vpc_zone_identifier = var.public_subnet_ids

  # launch template 지정
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # ALB(로드 밸런서)의 타깃 그룹에 이 서버들을 자동으로 바인딩
  target_group_arns = [var.target_group_arn]

  # 헬스 체크 설정: 로드 밸런서가 검사
  health_check_type         = "ELB"
  health_check_grace_period = 300 # 서버가 켜지고 세팅되는 5분 동안은 판단하지 않기

  tag {
    key                 = "Name"
    value               = "mh-asg-instance-${var.env_name}"
    propagate_at_launch = true # 서버가 새로 켜질 때 이 태그를 자동으로 주입
  }
}