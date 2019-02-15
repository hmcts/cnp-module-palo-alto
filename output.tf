output "admin_username" {
  value     = "${data.azurerm_key_vault_secret.pan_admin_username.value}"
  sensitive = true
}

output "admin_password" {
  value     = "${data.azurerm_key_vault_secret.pan_admin_password.value}"
  sensitive = true
}

output "mgmt_address_prefix" {
  value = "${data.azurerm_subnet.mgmt_subnet.address_prefix}"
}

output "trusted_address_prefix" {
  value = "${data.azurerm_subnet.trusted_subnet.address_prefix}"
}

output "untrusted_address_prefix" {
  value = "${data.azurerm_subnet.untrusted_subnet.address_prefix}"
}

output "mgmt_ips" {
  value = "${azurerm_network_interface.mgmt_nic.*.private_ip_address}"
}

output "trusted_ips" {
  value = "${azurerm_network_interface.trusted_nic.*.private_ip_address}"
}

output "trusted_ips_fqdn" {
  value = "${null_resource.trusted_ips_fqdn.*.triggers}"
}

output "untrusted_ips" {
  value = "${azurerm_network_interface.untrusted_nic.*.private_ip_address}"
}

output "untrusted_ips_fqdn" {
  value = "${null_resource.untrusted_ips_fqdn.*.triggers}"
}

output "untrusted_ips_ip_address" {
  value = "${null_resource.untrusted_ips_ip_address.*.triggers}"
}

output "cluster_size" {
  value = "${var.cluster_size}"
}
