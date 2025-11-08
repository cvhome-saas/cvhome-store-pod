resource "aws_service_discovery_private_dns_namespace" "cluster_namespace" {
  name = "${local.module_name}-${var.project}.${var.project}.lcl"
  vpc  = var.vpc_id
  tags = var.tags
}