resource "aws_service_discovery_private_dns_namespace" "cluster_namespace" {
  name = "${local.simple_module_name}.${var.project}.lcl"
  vpc  = var.vpc_id
  tags = var.tags
}