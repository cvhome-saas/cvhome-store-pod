locals {
  shorten_pod_id_hash = substr(md5(var.pod.id), 0, 3)
  shorten_pod         = "${var.shorten_pod_id}-${local.shorten_pod_id_hash}"
  simple_module_name  = "pod-${local.shorten_pod}"
  pod_record          = "${var.pod_record_prefix}.${var.domain_zone_name}"
}
