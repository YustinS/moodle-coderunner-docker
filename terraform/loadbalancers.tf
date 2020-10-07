resource "aws_alb" "ecs-load-balancer" {
  name            = "${local.app_name}-public-lb"
  security_groups = [aws_security_group.loadbalancer_sg.id]
  subnets         = var.public_subnets
  internal        = false
  /*
  access_logs {
    bucket  = "uoa-security-loadbalancer-access-logs"
    prefix  = "science-prod/iNZight-ECS"
    enabled = true
  }
  */

  tags = local.common_tags
}

# We leave port 80 available, however it just redirects
resource "aws_alb_listener" "alb-listener-insecure" {
  load_balancer_arn = aws_alb.ecs-load-balancer.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  depends_on = [aws_alb.ecs-load-balancer]
}

# Process the request, however by default nothing should happen unless a rule is matched
resource "aws_alb_listener" "alb-listener" {
  load_balancer_arn = aws_alb.ecs-load-balancer.id
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.amazon_issued.arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Nothing to see here."
      status_code  = "200"
    }
  }

  depends_on = [aws_alb.ecs-load-balancer]
}

resource "aws_route53_record" "general_purpose" {
  zone_id = data.aws_route53_zone.host_zone.id
  name    = var.dns_name
  type    = "A"

  alias {
    name                   = aws_alb.ecs-load-balancer.dns_name
    zone_id                = aws_alb.ecs-load-balancer.zone_id
    evaluate_target_health = false
  }
}

data "aws_route53_zone" "host_zone" {
  name         = var.hosted_zone
  private_zone = false
}

data "aws_acm_certificate" "amazon_issued" {
  domain      = var.acm_domain
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

################ JOBE INTERNAL LB ##############################

resource "aws_alb" "jobe-load-balancer" {
  name            = "${local.app_name}-jobe-lb"
  security_groups = [aws_security_group.jobe_lb_sg.id]
  subnets         = var.private_subnets
  internal        = true
  /*
  access_logs {
    bucket  = "uoa-security-loadbalancer-access-logs"
    prefix  = "science-prod/iNZight-ECS"
    enabled = true
  }
  */

  tags = local.common_tags
}

# We leave port 80 available, however it just redirects
resource "aws_alb_listener" "jobe-listener-insecure" {
  load_balancer_arn = aws_alb.jobe-load-balancer.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  depends_on = [aws_alb.jobe-load-balancer]
}

# Process the request, however by default nothing should happen unless a rule is matched
resource "aws_alb_listener" "jobe-listener" {
  load_balancer_arn = aws_alb.jobe-load-balancer.id
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.jobe_cert.arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Nothing to see here."
      status_code  = "200"
    }
  }

  depends_on = [aws_alb.jobe-load-balancer]
}

resource "aws_route53_record" "jobe" {
  zone_id = data.aws_route53_zone.jobe_host_zone.id
  name    = var.jobe_dns_name
  type    = "A"

  alias {
    name                   = aws_alb.jobe-load-balancer.dns_name
    zone_id                = aws_alb.jobe-load-balancer.zone_id
    evaluate_target_health = false
  }
}

data "aws_route53_zone" "jobe_host_zone" {
  name         = var.jobe_hosted_zone
  private_zone = var.jobe_host_zone_private
}

data "aws_acm_certificate" "jobe_cert" {
  domain      = var.acm_domain_jobe
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}