resource "azurerm_resource_group" "resource_group" {
  name     = "${var.product}-pan-${var.env}"
  location = "${var.resource_group_location}"

  tags {
    environment = "${var.env}"
  }
}

resource "random_string" "admin_password" {
  length           = 16
  special          = true
  override_special = "!@?&"
}

resource "azurerm_key_vault" "key_vault" {
  name                = "pan-creds-vault-${var.env}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"

  sku {
    name = "standard"
  }

  tenant_id = "531ff96d-0ae9-462a-8d2d-bec7c0b42082"

  access_policy {
    tenant_id = "531ff96d-0ae9-462a-8d2d-bec7c0b42082"
    object_id = "300e771f-856c-45cc-b899-40d78281e9c1"

    key_permissions = [
      "get",
      "create",
      "list",
      "delete",
    ]

    secret_permissions = [
      "get",
      "set",
      "list",
      "delete",
    ]
  }

  enabled_for_disk_encryption = true

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_key_vault_secret" "pan_admin_username" {
  name      = "pan-admin-username"
  value     = "${var.admin_username}"
  vault_uri = "${azurerm_key_vault.key_vault.vault_uri}"

  depends_on = ["azurerm_key_vault.key_vault"]

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_key_vault_secret" "pan_admin_password" {
  name      = "pan-admin-password"
  value     = "${random_string.admin_password.result}"
  vault_uri = "${azurerm_key_vault.key_vault.vault_uri}"

  depends_on = ["azurerm_key_vault.key_vault"]

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_lb" "load_balancer" {
  name                = "${var.product}-pan-load-balancer-${var.env}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  location            = "${var.resource_group_location}"

  frontend_ip_configuration {
    name                          = "${var.product}-pan-load-balancer-frontend-ip-config-${var.env}"
    subnet_id                     = "${data.azurerm_subnet.untrusted_subnet.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name                = "${var.product}-pan-backend-pool-${var.env}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  loadbalancer_id     = "${azurerm_lb.load_balancer.id}"
}

resource "azurerm_lb_rule" "http_lb_rule" {
  name                           = "http_rule"
  resource_group_name            = "${azurerm_resource_group.resource_group.name}"
  loadbalancer_id                = "${azurerm_lb.load_balancer.id}"
  frontend_ip_configuration_name = "${var.product}-pan-load-balancer-frontend-ip-config-${var.env}"
  protocol                       = "Tcp"
  frontend_port                  = "80"
  backend_port                   = "80"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.backend_pool.id}"
  probe_id                       = "${azurerm_lb_probe.http_lb_probe.id}"
}

resource "azurerm_lb_probe" "http_lb_probe" {
  name                = "http_probe"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  loadbalancer_id     = "${azurerm_lb.load_balancer.id}"
  port                = "80"
  protocol            = "Tcp"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.product}-pan-nsg-${var.env}"
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

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "${join("", list("panvm", substr(md5(azurerm_resource_group.resource_group.id), 0, 8)))}"
  resource_group_name      = "${azurerm_resource_group.resource_group.name}"
  location                 = "${var.resource_group_location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_availability_set" "availability_set" {
  name                         = "${var.product}-pan-availability-set-${var.env}"
  resource_group_name          = "${azurerm_resource_group.resource_group.name}"
  location                     = "${var.resource_group_location}"
  managed                      = true
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2

  tags {
    environment = "${var.env}"
  }
}

data "azurerm_subnet" "mgmt_subnet" {
  name                 = "palo-mgmt-${var.env}"
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
  name                = "${var.product}-pan-mgmt-nic-${count.index}-${var.env}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  count               = "${var.cluster_size}"

  ip_configuration {
    name                          = "${join("", list("ipconfig", "0"))}"
    subnet_id                     = "${data.azurerm_subnet.mgmt_subnet.id}"
    private_ip_address_allocation = "dynamic"
  }

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_network_interface" "untrusted_nic" {
  name                = "${var.product}-pan-untrusted-nic-${count.index}-${var.env}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  count               = "${var.cluster_size}"

  enable_ip_forwarding = true

  ip_configuration {
    name                                    = "${join("", list("ipconfig", "1"))}"
    subnet_id                               = "${data.azurerm_subnet.untrusted_subnet.id}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.backend_pool.id}"]
  }

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_network_interface" "trusted_nic" {
  name                = "${var.product}-pan-trusted-nic-${count.index}-${var.env}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  count               = "${var.cluster_size}"

  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${join("", list("ipconfig", "2"))}"
    subnet_id                     = "${data.azurerm_subnet.trusted_subnet.id}"
    private_ip_address_allocation = "dynamic"
  }

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_virtual_machine" "pan_vm" {
  name                = "${var.product}-pan-vm-${count.index}-${var.env}"
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
    name              = "${var.product}-pan-vm-os-disk-${count.index}-${var.env}"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "${var.product}-pan-vm-${count.index}-${var.env}"
    admin_username = "${var.admin_username}"
    admin_password = "${random_string.admin_password.result}"
  }

  primary_network_interface_id = "${element(azurerm_network_interface.mgmt_nic.*.id, count.index)}"
  network_interface_ids        = ["${element(azurerm_network_interface.mgmt_nic.*.id, count.index)}", "${element(azurerm_network_interface.untrusted_nic.*.id, count.index)}", "${element(azurerm_network_interface.trusted_nic.*.id, count.index)}"]

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
