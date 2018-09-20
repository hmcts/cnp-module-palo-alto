output "vault_uri" {
  value = "${azurerm_key_vault.key_vault.vault_uri}"
}

output "admin_username" {
  value = "${var.admin_username}"
  sensitive = true
}

output "admin_password" {
  value = "${random_string.admin_password.result}"
  sensitive = true
}

output "vm0_mgmt_ip" {
  value = "${element(azurerm_network_interface.mgmt_nic.*.private_ip_address, 0)}"
}

output "vm1_mgmt_ip" {
  value = "${element(azurerm_network_interface.mgmt_nic.*.private_ip_address, 1)}"
}