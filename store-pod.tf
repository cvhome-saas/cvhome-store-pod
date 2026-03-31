locals {
  simple_module_name = "store-pod-${var.pod.shorten_pod_id}"
  pod_domain         = "${var.pod.pod_record_prefix}.${var.domain_zone_name}"
}
