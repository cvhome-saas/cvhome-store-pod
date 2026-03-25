locals {
  module_name         = "store-pod-${var.pod.id}"
  short_service       = substr(local.module_name, 0, 20)
  hash                = substr(md5(local.module_name), 0, 6)
  simple_service_name = local.short_service + "-" + local.hash
}
