module "palo_alto_infrastructure" {
  source                          = "./modules/palo-alto-cluster"
  env                             = "${var.env}"
  product                         = "${var.product}"
}

module "palo_alto_configuration" {
  source      = "./modules/palo-alto-config"
  inventory = "${module.palo_alto_infrastructure.vm0_mgmt_ip},${module.palo_alto_infrastructure.vm1_mgmt_ip},"
  username    = "${module.palo_alto_infrastructure.admin_username}"
  password    = "${module.palo_alto_infrastructure.admin_password}"
}