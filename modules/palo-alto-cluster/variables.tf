variable "product" {
  type = "string"
}

variable "env" {
  type = "string"
}

# variable "vnet_address_space" {
#   type = "string"
# }

# variable "mgmt_subnet_address_prefix" {
#   type = "string"
# }

# variable "trusted_subnet_address_prefix" {
#   type = "string"
# }

# variable "untrusted_subnet_address_prefix" {
#   type = "string"
# }

# variable "appgw_subnet_address_prefix" {
#   type = "string"
# }

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

variable "marketplace_sku" {
  default = "bundle2"
}

variable "marketplace_offer" {
  default = "vmseries1"
}

variable "marketplace_publisher" {
  default = "paloaltonetworks"
}
