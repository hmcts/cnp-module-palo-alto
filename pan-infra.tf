resource "azurerm_resource_group" "resource_group" {
  name     = "${var.product}-pan-${var.env}"
  location = "${var.resource_group_location}"

  tags = "${var.common_tags}"
}

locals {
  infraVaultName = "infra-vault-${var.subscription}"
  infraVaultUri  = "https://${local.infraVaultName}.vault.azure.net/"
  cluster_size = "${var.env == "prod" ? 2 : 1}"
}

data "azurerm_key_vault" "infra_vault" {
  name                = "infra-vault-${var.subscription}"
  resource_group_name = "${var.subscription == "prod" ? "core-infra-prod" : "cnp-core-infra"}"
}

data "azurerm_key_vault_secret" "pan_admin_username" {
  name      = "pan-admin-username"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "pan_admin_password" {
  name      = "pan-admin-password"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "pan_log_username" {
  name      = "pan-log-username"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "pan_log_password" {
  name      = "pan-log-password"
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

resource "azurerm_storage_account" "storage_account" {
  name                     = "${join("", list("panvm", substr(md5(azurerm_resource_group.resource_group.id), 0, 8)))}"
  resource_group_name      = "${azurerm_resource_group.resource_group.name}"
  location                 = "${var.resource_group_location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
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
  name                 = "palo-mgmt"
  virtual_network_name = "core-infra-vnet-${var.env}"
  resource_group_name  = "core-infra-${var.env}"
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

resource "azurerm_public_ip" "pip_untrusted" {
  name                = "${var.product}-pip-${count.index}-${var.env}"
  location            = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  allocation_method   = "Static"
  tags                = "${var.common_tags}"
  count               = "${var.cluster_size}"
  sku                 = "Standard"
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
    public_ip_address_id          = "${element(azurerm_public_ip.pip_untrusted.*.id, count.index)}"
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
    name                          = "${var.product}-pan-trusted"
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
    version   = "latest"
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

resource "azurerm_lb" "palo_ilb" {
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  name                = "${var.product}-pan-ilb"
  location            = "${var.resource_group_location}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "LoadBalancerFrontEnd"
    subnet_id                     = "${data.azurerm_subnet.trusted_subnet.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  loadbalancer_id     = "${azurerm_lb.palo_ilb.id}"
  name                = "PaloTrustBackendPool"
}

resource "azurerm_lb_rule" "all" {
  resource_group_name             = "${azurerm_resource_group.resource_group.name}"
  loadbalancer_id                 = "${azurerm_lb.palo_ilb.id}"
  name                            = "ALL"
  protocol                        = "All"
  frontend_port                   = 0
  backend_port                    = 0
  frontend_ip_configuration_name  = "LoadBalancerFrontEnd"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.backend_pool.id}"
  probe_id                       = "${azurerm_lb_probe.HTTPS.id}"
}

resource "azurerm_lb_probe" "HTTPS" {
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  loadbalancer_id     = "${azurerm_lb.palo_ilb.id}"
  name                = "HTTPS"
  port                = 443
  interval_in_seconds = 5
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_trust_lb" {
  network_interface_id    = "${element(azurerm_network_interface.trusted_nic.*.id, count.index)}"
  ip_configuration_name   = "${var.product}-pan-trusted"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.backend_pool.id}"
  count                   = "2"
}