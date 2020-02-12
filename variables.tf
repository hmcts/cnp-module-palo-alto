variable "product" {}

variable "env" {}
variable "subscription" {}

variable "trusted_destination_ip" {
  default = ""
}

variable "trusted_destination_host" {
  default = ""
}

variable "trusted_vnet_name" {}

variable "trusted_vnet_resource_group" {}

variable "trusted_vnet_subnet_name" {}

variable "untrusted_vnet_name" {}

variable "untrusted_vnet_resource_group" {}

variable "untrusted_vnet_subnet_name" {}

variable "infra_vault_name" {
  default = ""
}

variable "infra_vault_resource_group" {
  default = ""
}

variable "mgmt_vnet_subnet_name" {
  default = "palo-mgmt"
}

variable "cluster_size" {
  default = "2"
}

variable "resource_group_location" {
  default = "UK South"
}

variable "vm_size" {
  default = "Standard_D3_v2"
}

variable "vm_offer" {
  default = "vmseries1"
}

variable "allowed_external_ip" {
  type    = "string"
  default = "0.0.0.0/0"
}

variable "marketplace_sku" {
  default = "bundle2"
}

variable "marketplace_offer" {
  default = "vmseries1"
}

variable "marketplace_publisher" {
  default = "paloaltonetworks"
}

variable "marketplace_version" {
  default = "latest"
}

variable "common_tags" {
  type = "map"
}

variable "pip_ansible_version" {
  default = "2.6.4"
}

variable "pip_netaddr_version" {
  default = "0.7.19"
}
