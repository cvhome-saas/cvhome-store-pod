output "domain" {
  value = "store-pod-saas-gateway-${var.pod.id}.${var.domain_zone_name}"
}