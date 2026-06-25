# modules/alb/main.tf

# 1. 외부 트래픽을 받아줄 로드밸런서 본체 생성
resource "aws_lb" "this" {
  name               = "mh-alb-${var.env_name}"
  internal           = false # 외부 인터넷 유저들을 받을 것이므로 false
  load_balancer_type = "application"
  security_groups    = [var.public_web_sg_id]
  subnets            = var.public_subnet_ids # 두 개 이상의 가용영역 서브넷이 필요합니다.

  tags = {
    Name = "mh-alb-${var.env_name}"
  }
}

# 2. 로드밸런서가 트래픽을 쏴줄 '목적지 그룹(Target Group)' 생성
resource "aws_lb_target_group" "this" {
  name        = "mh-tg-${var.env_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  # 컴퓨터들이 잘 살아있는지 주기적으로 체크하는 헬스 체크 규칙
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "mh-tg-${var.env_name}"
  }
}

# 3. 80번(HTTP) 문을 열고 대기하다가 트래픽이 오면 위 목적지 그룹으로 넘겨주는 '리스너(Listener)'
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}