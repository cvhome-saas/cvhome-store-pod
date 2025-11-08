resource "aws_service_discovery_private_dns_namespace" "cluster_namespace" {
  name = "store-pod-${var.pod.id}.${var.project}.lcl"
  vpc  = var.vpc_id
  tags = var.tags
}