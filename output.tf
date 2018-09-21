output "vault_uri" {
  value = "${azurerm_key_vault.key_vault.vault_uri}"
}

output "admin_username" {
  value     = "${var.admin_username}"
  sensitive = true
}

output "admin_password" {
  value     = "${random_string.admin_password.result}"
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

output "untrusted_ips" {
  value = "${azurerm_network_interface.untrusted_nic.*.private_ip_address}"
}

output "cluster_size" {
  value = "${var.cluster_size}"
}
