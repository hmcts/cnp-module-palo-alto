resource "azurerm_resource_group" "resource_group" {
  name     = "${var.product}-pan-${var.env}"
  location = "${var.resource_group_location}"

  tags = "${var.common_tags}"
}

locals {
  infra_vault_name_default                = "infra-vault-${var.subscription}"
  infra_vault_resource_group_name_default = "${var.subscription == "prod" ? "core-infra-prod" : "cnp-core-infra"}"

  infra_vault_name                = "${var.infra_vault_name == "" ? local.infra_vault_name_default : var.infra_vault_name}"
  infra_vault_resource_group_name = "${var.infra_vault_resource_group == "" ? local.infra_vault_resource_group_name_default : var.infra_vault_resource_group}"

  cluster_size = "${var.env == "prod" ? 2 : 1}"
}

data "azurerm_key_vault" "infra_vault" {
  name                = "${local.infra_vault_name}"
  resource_group_name = "${local.infra_vault_resource_group_name}"
}

data "azurerm_key_vault_secret" "pan_admin_username" {
  name         = "pan-admin-username"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "pan_admin_password" {
  name         = "pan-admin-password"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "pan_log_username" {
  name         = "pan-log-username"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "pan_log_password" {
  name         = "pan-log-password"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.product}-pan-${var.env}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"

  security_rule {
    name                       = "Allow-Outside-From-IP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "${var.allowed_external_ip}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Default-Deny"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowVnetOutbound"
    priority                   = 4000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.5.0.0/16"
    destination_address_prefix = "10.5.0.0/16"
  }

  security_rule {
    name                       = "AllowInternetOutbound"
    priority                   = 4001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "0.0.0.0/0"
  }

  security_rule {
    name                       = "DenyAllOutbound"
    priority                   = 4095
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = "${var.common_tags}"
}

resource "azurerm_availability_set" "availability_set" {
  name                         = "${var.product}-pan-${var.env}"
  resource_group_name          = "${azurerm_resource_group.resource_group.name}"
  location                     = "${var.resource_group_location}"
  managed                      = true
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2

  tags = "${var.common_tags}"
}

data "azurerm_subnet" "mgmt_subnet" {
  name = "${var.mgmt_vnet_subnet_name}"

  # using trusted to not make a breaking change to the module, really should just have one vnet var
  virtual_network_name = "${var.trusted_vnet_name}"
  resource_group_name  = "${var.trusted_vnet_resource_group}"
}

data "azurerm_subnet" "trusted_subnet" {
  name                 = "${var.trusted_vnet_subnet_name}"
  virtual_network_name = "${var.trusted_vnet_name}"
  resource_group_name  = "${var.trusted_vnet_resource_group}"
}

data "azurerm_subnet" "untrusted_subnet" {
  name                 = "${var.untrusted_vnet_subnet_name}"
  virtual_network_name = "${var.untrusted_vnet_name}"
  resource_group_name  = "${var.untrusted_vnet_resource_group}"
}

resource "azurerm_network_interface" "mgmt_nic" {
  name                = "${var.product}-pan-mgmt-${count.index}-${var.env}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  count               = "${var.cluster_size}"

  ip_configuration {
    name                          = "${join("", list("ipconfig", "0"))}"
    subnet_id                     = "${data.azurerm_subnet.mgmt_subnet.id}"
    private_ip_address_allocation = "dynamic"
  }

  tags = "${var.common_tags}"
}

resource "azurerm_network_interface" "untrusted_nic" {
  name                = "${var.product}-pan-untrusted-${count.index}-${var.env}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  count               = "${var.cluster_size}"

  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${join("", list("ipconfig", "1"))}"
    subnet_id                     = "${data.azurerm_subnet.untrusted_subnet.id}"
    private_ip_address_allocation = "dynamic"
  }

  tags = "${var.common_tags}"
}

resource "azurerm_network_interface" "trusted_nic" {
  name                = "${var.product}-pan-trusted-${count.index}-${var.env}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  count               = "${var.cluster_size}"

  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${join("", list("ipconfig", "2"))}"
    subnet_id                     = "${data.azurerm_subnet.trusted_subnet.id}"
    private_ip_address_allocation = "dynamic"
  }

  tags = "${var.common_tags}"
}

resource "azurerm_virtual_machine" "pan_vm" {
  name                = "${var.product}-pan-${count.index}-${var.env}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  availability_set_id = "${azurerm_availability_set.availability_set.id}"
  vm_size             = "${var.vm_size}"
  count               = "${var.cluster_size}"

  plan {
    name      = "${var.marketplace_sku}"
    publisher = "${var.marketplace_publisher}"
    product   = "${var.marketplace_offer}"
  }

  storage_image_reference {
    publisher = "${var.marketplace_publisher}"
    offer     = "${var.marketplace_offer}"
    sku       = "${var.marketplace_sku}"
    version   = "${var.marketplace_version}"
  }

  storage_os_disk {
    name              = "${var.product}-pan-${count.index}-${var.env}"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "${var.product}-pan-${count.index}-${var.env}"
    admin_username = "${data.azurerm_key_vault_secret.pan_admin_username.value}"
    admin_password = "${data.azurerm_key_vault_secret.pan_admin_password.value}"
  }

  primary_network_interface_id = "${element(azurerm_network_interface.mgmt_nic.*.id, count.index)}"
  network_interface_ids        = ["${element(azurerm_network_interface.mgmt_nic.*.id, count.index)}", "${element(azurerm_network_interface.untrusted_nic.*.id, count.index)}", "${element(azurerm_network_interface.trusted_nic.*.id, count.index)}"]

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = "${var.common_tags}"
}
