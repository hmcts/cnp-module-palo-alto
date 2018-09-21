variable "username" {
  type = "string"
}

variable "password" {
  type = "string"
}

variable "mgmt_address_prefix" {
  type = "string"
}

variable "trusted_address_prefix" {
  type = "string"
}

variable "untrusted_address_prefix" {
  type = "string"
}

variable "mgmt_ips" {
  type = "list"
}

variable "trusted_ips" {
  type = "list"
}

variable "untrusted_ips" {
  type = "list"
}

variable "cluster_size" {
  type = "string"
}

variable "vm_ids" {
  type = "list"
}

variable "availability_set_id" {
  type = "string"
}
