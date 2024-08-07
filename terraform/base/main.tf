module "vpc" {
  source  = "punkerside/vpc/aws"
  version = "0.0.6"

  name           = var.service
  cidr_block_vpc = "10.0.0.0/16"
  cidr_block_pri = ["10.0.0.0/18", "10.0.64.0/18"]
  cidr_block_pub = ["10.0.128.0/18", "10.0.192.0/18"]
}

resource "aws_ecs_cluster" "main" {
  name = var.service

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
	Name = var.service
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_security_group" "main" {
  name   = var.service
  vpc_id = module.vpc.vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.service
  }
}

resource "aws_lb" "main" {
  name               = var.service
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main.id]
  subnets            = module.vpc.subnet_public_ids[*].id

  enable_deletion_protection = false

  tags = {
    Environment = "${var.project}-${var.env}-${var.service}"
  }
}

resource "aws_iam_role" "main" {
  name = "${var.project}-${var.env}-${var.service}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = [ "ec2.amazonaws.com", "ecs.amazonaws.com", "ecs-tasks.amazonaws.com" ]
        }
      },
    ]
  })

  tags = {
    Name = "${var.project}-${var.env}-${var.service}"
  }
}

resource "aws_iam_role_policy" "main" {
  name = "${var.project}-${var.env}-${var.service}"
  role = aws_iam_role.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:*",
          "ecr:*",
          "ecs:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "main" {
  name = "${var.project}-${var.env}-${var.service}"
}

resource "aws_lb_target_group" "main" {
  name        = "${var.project}-${var.env}-${var.service}"
  port        = 8070
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc.id
  target_type = "ip"
}

resource "aws_ecs_task_definition" "main" {
  family = "${var.project}-${var.env}-${var.service}"

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 4096
  execution_role_arn       = aws_iam_role.main.arn

  container_definitions = jsonencode([
    {
      name      = "main"
      image     = "${data.aws_caller_identity.main.account_id}.dkr.ecr.${data.aws_region.main.name}.amazonaws.com/${var.project}-${var.env}-${var.service}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8070
          hostPort      = 8070
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.main.name
          awslogs-region        = data.aws_region.main.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "main" {
  name                              = "${var.project}-${var.env}-${var.service}"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.main.arn
  desired_count                     = 1
  health_check_grace_period_seconds = 0
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  iam_role                          = "arn:aws:iam::${data.aws_caller_identity.main.account_id}:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"
  depends_on                        = [aws_iam_role_policy.main]

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "main"
    container_port   = 8070
  }

  network_configuration {
    subnets         = module.vpc.subnet_private_ids[*].id
    security_groups = [aws_security_group.main.id]
  }

  capacity_provider_strategy {
    base              = 1
    capacity_provider = "FARGATE"
    weight            = 100
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }
}

resource "aws_acm_certificate" "main" {
  domain_name       = "${var.service}.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name = "${var.project}-${var.env}-${var.service}"
  }
}

resource "aws_route53_record" "main" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.main.zone_id
  ttl             = 60
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}