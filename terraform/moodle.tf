resource "aws_ecs_cluster" "containers" {
  name               = local.ecs_cluster_name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
    base              = 1
  }
  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.app_name}-ECS-Cluster"
    }
  )
}

#### LOADBALANCER CHANGES ####
resource "aws_lb_listener_rule" "moodle-routing" {
  listener_arn = aws_alb_listener.alb-listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.Moodle-Service.id
  }

  condition {
    host_header {
      values = ["${var.dns_name}"]
    }
  }
}

resource "aws_alb_target_group" "Moodle-Service" {
  name        = "${local.app_name}-Moodle"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  slow_start  = 60

  stickiness {
    type            = "lb_cookie"
    cookie_duration = "86400"
    enabled         = "true"
  }
  # WARNING. First Boot is long
  # Recommend either setting these very high
  # or disabling the LB connection until completed
  health_check {
    path                = "/login/index.php"
    timeout             = "60"
    interval            = "120"
    matcher             = "200"
    unhealthy_threshold = 10
  }
}

#### ECS SERVICE DEFINITIONS ####
resource "aws_ecs_service" "Moodle-Service" {
  name                    = "${local.app_name}-Moodle"
  cluster                 = aws_ecs_cluster.containers.id
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"
  platform_version        = "1.4.0"
  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.app_name}-Moodle-Service"
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
  task_definition = "${aws_ecs_task_definition.moodle.family}:${max(
    aws_ecs_task_definition.moodle.revision,
    data.aws_ecs_task_definition.moodle.revision,
  )}"

  desired_count = 1

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.moodle_internal_sg.id]
  }
  # LB needs to be disabled on first run due to 
  # how long the initial run takes to complete.
  # Conditional block?
  load_balancer {
    target_group_arn = aws_alb_target_group.Moodle-Service.id
    container_name   = "${local.app_name}-Moodle"
    container_port   = 8080
  }

  lifecycle {
    # create_before_destroy = true
    ignore_changes = [desired_count]
  }
}

#### ECS TASK DEFINITIONS ####
data "aws_ecs_task_definition" "moodle" {
  task_definition = aws_ecs_task_definition.moodle.family
  depends_on      = [aws_ecs_task_definition.moodle]
}

resource "aws_ecs_task_definition" "moodle" {
  family                   = "${local.app_name}-Moodle"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_assume.arn
  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.app_name}-Moodle-task-definition"
    },
  )

  volume {
    name = "Moodle-Core"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.this.id
      transit_encryption = "ENABLED"
    }
  }

  volume {
    name = "Moodle-Data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.that.id
      transit_encryption = "ENABLED"
    }
  }

  container_definitions = <<DEFINITION
[
  {
    "essential": true,
    "networkMode": "awsvpc",
    "image": "${var.moodle_image}",
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${local.cw_log_group}",
          "awslogs-region": "ap-southeast-2",
          "awslogs-stream-prefix": "${local.app_name}-Moodle"
        }
    },
    "name": "${local.app_name}-Moodle",
    "portMappings": [
        {
            "hostPort": 8080,
            "containerPort": 8080
        },
        {
            "hostPort": 8443,
            "containerPort": 8443
        }
    ],
    "mountPoints": [
        {
            "sourceVolume": "Moodle-Core",
            "containerPath": "/bitnami/moodle"
        },
        {
            "sourceVolume": "Moodle-Data",
            "containerPath": "/bitnami/moodledata"
        }
    ],
    "environment": [
        {
            "name": "MOODLE_DATABASE_HOST",
            "value": "${aws_db_instance.moodle.address}"
        },
        {
            "name": "MOODLE_DATABASE_PORT_NUMBER",
            "value": "3306"
        },
        {
            "name": "MOODLE_DATABASE_TYPE",
            "value": "mariadb"
        },
        {
            "name": "MOODLE_DATABASE_USER",
            "value": "${local.db_user}"
        },
        {
            "name": "MOODLE_DATABASE_PASSWORD",
            "value": "${local.db_password}"
        },
        {
            "name": "MOODLE_DATABASE_NAME",
            "value": "${local.db_name}"
        },
        {
            "name": "MOODLE_SKIP_BOOTSTRAP",
            "value": "${var.moodle_skip_bootstrap}"
        },
        {
            "name": "MOODLE_SITE_NAME",
            "value": "${var.moodle_sitename}"
        },
        {
            "name": "MOODLE_USERNAME",
            "value": "${local.moodle_user}"
        },
        {
            "name": "MOODLE_PASSWORD",
            "value": "${local.moodle_pwd}"
        }
    ]
  }
]
DEFINITION

}