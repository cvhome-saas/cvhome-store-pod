locals {
  module_name        = "sp-${var.pod.id}"
  shorten_module     = substr(local.module_name, 0, 15)
  module_hash        = substr(md5(local.module_name), 0, 3)
  simple_module_name = "${local.shorten_module}-${local.module_hash}"
}
