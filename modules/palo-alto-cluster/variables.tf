variable "product" {
  type = "string"
}

variable "env" {
  type = "string"
}

variable "resource_group_location" {
  type    = "string"
  default = "UK South"
}

variable "vm_size" {
  default = "Standard_D3_v2"
}

variable "vm_offer" {
  default = "vmseries1"
}

variable "admin_username" {
  default = "reform-pan-admin"
  type    = "string"
}

variable "allowed_external_ip" {
  type    = "string"
  default = "0.0.0.0/0"
}

variable "vnet_address_space" {
  type    = "string"
  default = "10.0.0.0/16"
}

variable "mgmt_subnet_address_prefix" {
  type    = "string"
  default = "10.0.40.0/24"
}

variable "mgmt_ip" {
  type    = "string"
  default = "10.0.40.4"
}

variable "trusted_subnet_address_prefix" {
  type    = "string"
  default = "10.0.20.0/24"
}

variable "trusted_ip" {
  type    = "string"
  default = "10.0.20.4"
}

variable "untrusted_subnet_address_prefix" {
  type    = "string"
  default = "10.0.10.0/24"
}

variable "untrusted_ip" {
  type    = "string"
  default = "10.0.10.4"
}

variable "appgw_subnet_address_prefix" {
  type    = "string"
  default = "10.0.0.0/24"
}

variable "appgw_ip" {
  type    = "string"
  default = "10.0.0.4"
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
