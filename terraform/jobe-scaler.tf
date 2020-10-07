#### AUTO-SCALING DEFINITIONS ####
resource "aws_appautoscaling_target" "jobe-service" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${local.ecs_cluster_name}/${aws_ecs_service.jobe-Service.name}"
  role_arn           = data.aws_iam_role.ecs-service-role.arn
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.jobe-Service]
}

resource "aws_appautoscaling_policy" "jobe_scaledown" {
  name               = "${local.app_name}-jobe-scale-down"
  policy_type        = "StepScaling"
  resource_id        = "service/${local.ecs_cluster_name}/${aws_ecs_service.jobe-Service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [
    aws_ecs_service.jobe-Service,
    aws_appautoscaling_target.jobe-service,
  ]
}

resource "aws_cloudwatch_metric_alarm" "jobe_CPU_utilization_low" {
  alarm_name          = "${local.app_name}-jobe-CPU-utilization-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "20"

  dimensions = {
    ClusterName = local.ecs_cluster_name
    ServiceName = aws_ecs_service.jobe-Service.name
  }

  alarm_description = "This metric monitors ECS CPU utilization for ${local.app_name}-jobe for scale down"
  alarm_actions     = [aws_appautoscaling_policy.jobe_scaledown.arn]
  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.app_name}-Jobe-ScaleDown-Metrics"
    }
  )

  depends_on = [aws_ecs_service.jobe-Service]
}

resource "aws_appautoscaling_policy" "jobe_scaleup" {
  name               = "${local.app_name}-jobe-scale-up"
  policy_type        = "StepScaling"
  resource_id        = "service/${local.ecs_cluster_name}/${aws_ecs_service.jobe-Service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [
    aws_ecs_service.jobe-Service,
    aws_appautoscaling_target.jobe-service,
  ]
}

resource "aws_cloudwatch_metric_alarm" "jobe_CPU_utilization_high" {
  alarm_name          = "${local.app_name}-jobe-CPU-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "80"

  dimensions = {
    ClusterName = local.ecs_cluster_name
    ServiceName = aws_ecs_service.jobe-Service.name
  }

  alarm_description = "This metric monitors ECS CPU utilization for ${local.app_name}-jobe for scale up"
  alarm_actions     = [aws_appautoscaling_policy.jobe_scaleup.arn]

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.app_name}-Jobe-ScaleUp-Metrics"
    }
  )

  depends_on = [aws_ecs_service.jobe-Service]
}