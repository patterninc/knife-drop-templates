
resource "aws_lb" "fargate-alb" {
  provider           = aws.region
  name               = "fargate-alb-${var.region}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.fargate-alb-sg.id]
  subnets            = tolist(var.public_subnet_ids)
}

resource "aws_lb_target_group" "fargate-targetgroup" {
  provider    = aws.region
  name        = "fargate-tg-${var.region}"
  port        = "8080"
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "fargate-listener" {
  provider          = aws.region
  load_balancer_arn = aws_lb.fargate-alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargate-targetgroup.arn
  }
}

resource "aws_security_group" "fargate-alb-sg" {
  provider    = aws.region
  name        = "fargate-alb-sg-${var.region}"
  description = "fargate-alb-sg-${var.region}"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH Ingress - Managed by Terraform"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}