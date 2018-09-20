
# resource "null_resource" "pan_configuration" {
#   provisioner "local-exec" {
#     command = "ansible-playbook pan-os-ansible/playbook.yml -i ${var.inventory}  --extra-vars 'username=${var.username} password=${var.password}' "
#   }
# }


provider "panos" {
  alias = "0"
  hostname = "${var.vm0_mgmt_ip}"
  username = "${var.username}"
  password = "${var.password}"
}

provider "panos" {
  alias = "1"
  hostname = "${var.vm1_mgmt_ip}"
  username = "${var.username}"
  password = "${var.password}"
}

resource "panos_ethernet_interface" "ethernet_1_1" {
  name                      = "ethernet1/1"
  provider = "panos.0"
  mode                      = "layer3"
  vsys                      = "vsys1"
  enable_dhcp               = true
  create_dhcp_default_route = true
  count = 2
}

resource "panos_ethernet_interface" "ethernet_1_2" {
  name                      = "ethernet1/2"
  provider = "panos.0"
  mode                      = "layer3"
  vsys                      = "vsys1"
  enable_dhcp               = true
  create_dhcp_default_route = false
}

resource "panos_virtual_router" "default_vr" {
  name       = "default"
  provider = "panos.0"
  interfaces = ["ethernet1/1", "ethernet1/2"]
  depends_on = ["panos_ethernet_interface.ethernet_1_1", "panos_ethernet_interface.ethernet_1_2"]
}