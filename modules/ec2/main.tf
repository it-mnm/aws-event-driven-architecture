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

# 2. EC2 서버를 찍어낼 틀 (Launch Template)
resource "aws_launch_template" "app" {
  name_prefix   = "mh-app-template-${var.env_name}-"
  image_id      = var.ami_id          # 기존에 쓰던 Ubuntu AMI ID
  instance_type = var.instance_type   # 기존에 쓰던 t2.micro 등

  # 🎯 [수정] 최상단의 vpc_security_group_ids를 지우고 아래 network_interfaces 안으로 통합합니다.

  # 🎯 [핵심 버그 수정] device_index를 명시하고 보안 그룹을 결합하여 완벽한 퍼블릭 인터페이스 구성
  network_interfaces {
    device_index                = 0
    associate_public_ip_address = true
    security_groups             = [var.public_security_group_id]
  }

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

# 3. 서버 개수를 자동으로 조절(Auto Scaling Group)
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

# ==========================================================================
# [지능형 오토 스케일링] 단계별 순차 확장(Scale-out) 및 축소(Scale-in) 설정
# ==========================================================================

# --------------------------------------------------------------------------
# [1단계 확장] CPU 30% 돌파 시 ➡️ 1대 추가 (2대 ➡️ 3대)
# --------------------------------------------------------------------------
resource "aws_autoscaling_policy" "scale_out_step1" {
  name                   = "mh-asg-scale-out-step1-${var.env_name}"
  scaling_adjustment     = 1  # 1대 추가
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180 # 3분 동안 상태 주시
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high_step1" {
  alarm_name          = "mh-cpu-high-step1-${var.env_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "30" # 🎯 30% 넘으면 실행

  dimensions = { AutoScalingGroupName = aws_autoscaling_group.app.name }
  alarm_actions     = [aws_autoscaling_policy.scale_out_step1.arn]
}

# --------------------------------------------------------------------------
# [2단계 추가 확장] CPU 50%마저 돌파 시 ➡️ 남은 1대 더 추가 (3대 ➡️ 4대)
# --------------------------------------------------------------------------
resource "aws_autoscaling_policy" "scale_out_step2" {
  name                   = "mh-asg-scale-out-step2-${var.env_name}"
  scaling_adjustment     = 1  # 또 1대 추가
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high_step2" {
  alarm_name          = "mh-cpu-high-step2-${var.env_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "50" # 🎯 50%마저 넘으면 실행

  dimensions = { AutoScalingGroupName = aws_autoscaling_group.app.name }
  alarm_actions     = [aws_autoscaling_policy.scale_out_step2.arn]
}

# --------------------------------------------------------------------------
# [안전 축소] CPU가 15% 이하로 떨어지면 ➡️ 순차적으로 1대씩 감소 (4대 ➡️ 3대 ➡️ 2대)
# --------------------------------------------------------------------------
resource "aws_autoscaling_policy" "scale_in_step" {
  name                   = "mh-asg-scale-in-${var.env_name}"
  scaling_adjustment     = -1 # 🎯 조건 만족 시 1대씩 제거
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180 # 서버가 꺼진 후 안전하게 안정화될 때까지 기다리는 시간
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_low_step" {
  alarm_name          = "mh-cpu-low-${var.env_name}"
  comparison_operator = "LessThanThreshold" # 기준치보다 낮아질 때
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "15" # 🎯 CPU 평균이 15% 미만으로 평온해지면

  dimensions = { AutoScalingGroupName = aws_autoscaling_group.app.name }
  alarm_actions     = [aws_autoscaling_policy.scale_in_step.arn]
}