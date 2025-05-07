resource "aws_ecs_cluster" "fargate-cluster" {
  provider = aws.region
  name     = "${var.name}-cluster"
}

resource "aws_ecs_service" "fargate-ecs" {
  provider             = aws.region
  name                 = "${var.name}-service"
  cluster              = aws_ecs_cluster.fargate-cluster.id
  task_definition      = aws_ecs_task_definition.fargate-task.arn
  desired_count        = var.desired_count
  launch_type          = "FARGATE"
  force_new_deployment = true

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.fargate-sg.id]
    subnets          = tolist(var.private_subnet_ids)
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fargate-targetgroup.arn
    container_name   = "${var.name}-container"
    container_port   = "${var.container_port}"
  }
}

resource "aws_cloudwatch_log_group" "fargate-cloudwatch" {
  provider = aws.region
  name     = "/ecs/${var.name}-service"
}

locals {
  name  = "${var.name}-container"
  image = "${local.docker_image}:latest@${data.aws_ecr_image.fargate.image_digest}"
  secrets = [
    for key in keys(var.container_secrets) :
    {
      name      = key
      valueFrom = "${lookup(var.container_secrets, key)}"
    }
  ]
  ulimits = [
    for limit in var.ulimits :
    {
      name      = limit.name
      hardLimit = tonumber(limit.hardLimit)
      softLimit = tonumber(limit.softLimit)
    }
  ]
  portMappings = [
    {
      "containerPort" : ${var.container_port}
    }
  ]
  logConfiguration = {
    "logDriver" : "awslogs",
    "options" : {
      "awslogs-region" : "${var.region}",
      "awslogs-group" : "/ecs/${var.name}-service",
      "awslogs-stream-prefix" : "ecs"
    }
  }

  container_definition = {
    name             = local.name
    image            = local.image
    secrets          = local.secrets
    ulimits          = local.ulimits
    portMappings     = local.portMappings
    logConfiguration = local.logConfiguration
  }

  container_definition_json = format("[%s]", jsonencode(local.container_definition))
}

resource "aws_ecs_task_definition" "fargate-task" {
  provider                 = aws.region
  family                   = "${var.name}-taskdef"
  execution_role_arn       = aws_iam_role.fargate-execution-role.arn
  task_role_arn            = aws_iam_role.fargate-task-role.arn
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 1024
  requires_compatibilities = ["FARGATE"]
  container_definitions    = local.container_definition_json
}

resource "aws_iam_role" "fargate-execution-role" {
  name                 = "${var.name}-execRole"
  assume_role_policy   = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [{
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Effect": "Allow"
        }]
    }
  EOF
}

resource "aws_iam_role_policy_attachment" "fargate-execution-policy1" {
  role       = aws_iam_role.fargate-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "fargate-execution-policy2" {
  role       = aws_iam_role.fargate-execution-role.name
  policy_arn = aws_iam_policy.fargate-execution-policy.arn
}

resource "aws_iam_policy" "fargate-execution-policy" {
  name        = "${var.name}-execPolicy"
  path        = "/"
  description = "Fargate execution policy for ${var.name}"
  policy = <<-EOF
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*",
            "Effect": "Allow"
          },
          {
            "Effect": "Allow",
            "Action": [
              "ssm:GetParameters",
              "ssm:GetParameter",
              "secretsmanager:GetSecretValue"
            ],
            "Resource": "*"
          } 
        ]
      }
    EOF
}


resource "aws_iam_role" "fargate-task-role" {
  name                 = "${var.name}-Role"
  assume_role_policy   = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [{
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Effect": "Allow"
        }]
    }
  EOF
}

resource "aws_iam_role_policy_attachment" "fargate-task-policy1" {
  role       = aws_iam_role.fargate-task-role.name
  policy_arn = aws_iam_policy.fargate-task-policy.arn
}

resource "aws_iam_policy" "fargate-task-policy" {
  name        = "${var.name}-Policy"
  path        = "/"
  description = "Fargate task policy for ${var.name}"
  policy = <<-EOF
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*",
            "Effect": "Allow"
          },
          {
            "Effect": "Allow",
            "Action": [
              "ssm:GetParameters",
              "ssm:GetParameter",
              "secretsmanager:GetSecretValue"
            ],
            "Resource": "*"
          },
          {
            "Effect": "Allow",
            "Action": [
              "ecs:GetTaskProtection",
              "ecs:UpdateTaskProtection"
            ],
            "Resource": "*"
          } 
        ]
      }
    EOF
}

resource "aws_security_group" "fargate-sg" {
  provider    = aws.region
  name        = "${var.name}-fargate"
  description = "${var.name}-fargate"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = ${var.container_port}
    to_port     = ${var.container_port}
    protocol    = "TCP"
    cidr_blocks = var.cidr_blocks
    description = "${var.container_port} Ingress - Managed by Terraform"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
