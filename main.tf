module "palo_alto_infrastructure" {
  source       = "./modules/palo-alto-infrastructure"
  env          = "${var.env}"
  product      = "${var.product}"
  cluster_size = "${var.cluster_size}"
}

module "palo_alto_settings" {
  source                   = "./modules/palo-alto-config"
  mgmt_address_prefix      = "${module.palo_alto_infrastructure.mgmt_address_prefix}"
  trusted_address_prefix   = "${module.palo_alto_infrastructure.trusted_address_prefix}"
  untrusted_address_prefix = "${module.palo_alto_infrastructure.untrusted_address_prefix}"
  mgmt_ips                 = "${module.palo_alto_infrastructure.mgmt_ips}"
  trusted_ips              = "${module.palo_alto_infrastructure.trusted_ips}"
  untrusted_ips            = "${module.palo_alto_infrastructure.untrusted_ips}"
  cluster_size             = "${module.palo_alto_infrastructure.cluster_size}"
  username                 = "${module.palo_alto_infrastructure.admin_username}"
  password                 = "${module.palo_alto_infrastructure.admin_password}"
  vm_ids                   = "${module.palo_alto_infrastructure.vm_ids}"
  availability_set_id      = "${module.palo_alto_infrastructure.availability_set_id}"
}
