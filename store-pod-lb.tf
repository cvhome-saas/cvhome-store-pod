locals {
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr_block
    }
  }
}

module "cluster-nlb" {
  source = "terraform-aws-modules/alb/aws"

  name                       = "${local.module_name}-${var.project}-${var.env}"
  vpc_id                     = var.vpc_id
  subnets                    = var.public_subnets
  enable_deletion_protection = false

  load_balancer_type = "network"

  # Security Group
  enforce_security_group_inbound_rules_on_private_link_traffic = "on"
  security_group_ingress_rules                                 = local.security_group_ingress_rules
  security_group_egress_rules                                  = local.security_group_egress_rules

  access_logs = {
    bucket = var.log_s3_bucket_id
    prefix = "${var.pod.id}-nlb-access-logs"
  }

  listeners = {
    ex-tcp-80 = {
      port     = 80
      protocol = "TCP"
      forward = {
        target_group_key = "gateway-tg-80"
      }
    }
    ex-tcp-443 = {
      port     = 443
      protocol = "TCP"
      forward = {
        target_group_key = "gateway-tg-443"
      }
    }
  }

  target_groups = {
    gateway-tg-80 = {
      create_attachment = false
      name_prefix       = "p-s"
      protocol          = "TCP"
      port              = 80
      target_type       = "ip"
      health_check = {
        enabled             = true
        interval            = 45
        path                = "/config/"
        port                = 2019
        healthy_threshold   = 3
        unhealthy_threshold = 2
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
    gateway-tg-443 = {
      create_attachment = false
      name_prefix       = "s-g"
      protocol          = "TCP"
      port              = 443
      target_type       = "ip"
      health_check = {
        enabled             = true
        interval            = 45
        path                = "/config/"
        port                = 2019
        healthy_threshold   = 3
        unhealthy_threshold = 2
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  }

  tags = var.tags
}

module "store-pod-saas-gateway-record" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_name = var.domain_zone_name

  records = [
    {
      name = "store-pod-saas-gateway-${var.pod.id}"
      type = "A"
      alias = {
        name    = module.cluster-nlb.dns_name
        zone_id = module.cluster-nlb.zone_id
      }
    }
  ]
}

module "wildcard-store-pod-saas-gateway-record" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_name = var.domain_zone_name

  records = [
    {
      name = "*.store-pod-saas-gateway-${var.pod.id}"
      type = "A"
      alias = {
        name    = module.cluster-nlb.dns_name
        zone_id = module.cluster-nlb.zone_id
      }
    }
  ]
}
