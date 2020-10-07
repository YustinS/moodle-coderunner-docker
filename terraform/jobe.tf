#### LOADBALANCER CHANGES ####
resource "aws_lb_listener_rule" "jobe-routing" {
  listener_arn = aws_alb_listener.jobe-listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.jobe-Service.id
  }

  condition {
    host_header {
      values = ["${var.jobe_dns_name}"]
    }
  }
}

resource "aws_alb_target_group" "jobe-Service" {
  name        = "${local.app_name}-jobe"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/jobe/index.php/restapi/languages"
    timeout             = "10"
    interval            = "30"
    matcher             = "200"
    unhealthy_threshold = 10
  }
}

#### ECS SERVICE DEFINITIONS ####
resource "aws_ecs_service" "jobe-Service" {
  name                    = "${local.app_name}-jobe"
  cluster                 = aws_ecs_cluster.containers.id
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"
  platform_version        = "1.4.0"
  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.app_name}-jobe-Service"
    }
  )
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 0
    base              = 1
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
    base              = 0
  }
  task_definition = "${aws_ecs_task_definition.jobe.family}:${max(
    aws_ecs_task_definition.jobe.revision,
    data.aws_ecs_task_definition.jobe.revision,
  )}"

  desired_count = 1

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.jobe_internal_sg.id]
  }
  # LB needs to be disabled on first run due to 
  # how long the initial run takes to complete.
  # Conditional block?
  load_balancer {
    target_group_arn = aws_alb_target_group.jobe-Service.id
    container_name   = "${local.app_name}-jobe"
    container_port   = 80
  }

  lifecycle {
    # create_before_destroy = true
    ignore_changes = [desired_count]
  }
}

#### ECS TASK DEFINITIONS ####
data "aws_ecs_task_definition" "jobe" {
  task_definition = aws_ecs_task_definition.jobe.family
  depends_on      = [aws_ecs_task_definition.jobe]
}

resource "aws_ecs_task_definition" "jobe" {
  family                   = "${local.app_name}-jobe"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.jobe_task_assume.arn
  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.app_name}-jobe-task-definition"
    },
  )

  container_definitions = <<DEFINITION
[
  {
    "essential": true,
    "networkMode": "awsvpc",
    "image": "${var.jobe_image}",
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${local.cw_log_group}",
          "awslogs-region": "ap-southeast-2",
          "awslogs-stream-prefix": "${local.app_name}-jobe"
        }
    },
    "name": "${local.app_name}-jobe",
    "portMappings": [
        {
            "hostPort": 80,
            "containerPort": 80
        }
    ]
  }
]
DEFINITION

}