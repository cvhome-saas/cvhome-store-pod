locals {
  shorten_pod_id      = substr(var.pod.id, 0, 15)
  shorten_pod_id_hash = substr(md5(var.pod.id), 0, 3)
  shorten_pod         = "${local.shorten_pod_id}-${local.shorten_pod_id_hash}"
  simple_module_name  = "pod-${local.shorten_pod}"
  pod_record_prefix   = "store-pod-saas-gateway-${var.pod.id}"
  pod_record          = "${local.pod_record_prefix}.${var.domain_zone_name}"
}
