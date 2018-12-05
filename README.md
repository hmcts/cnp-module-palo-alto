# Automated Palo Alto

This module deploys a Palo Alto cluster attached to two subnets - an incoming 'untrusted' subnet and outgoing 'trusted' subnet, with traffic passing between the two via the Palo Alto appliances. This traffic is scanned for any malware, with any malicious traffic being dropped prior to reaching the trusted subnet.

Below is some example Terraform for consuming:

```
locals {
  trusted_vnet_name           = "core-infra-vnet-${var.env}"
  trusted_vnet_resource_group = "core-infra-${var.env}"
  trusted_vnet_subnet_name    = "palo-trusted"
}

module "palo_alto" {
  source       = "git@github.com:hmcts/cnp-module-palo-alto.git"
  subscription = "${var.subscription}"
  env          = "${var.env}"
  product      = "${var.product}"
  common_tags  = "${var.common_tags}"

  untrusted_vnet_name           = "core-infra-vnet-${var.env}"
  untrusted_vnet_resource_group = "core-infra-${var.env}"
  untrusted_vnet_subnet_name    = "palo-untrusted"
  trusted_vnet_name             = "core-infra-vnet-${var.env}"
  trusted_vnet_resource_group   = "core-infra-${var.env}"
  trusted_vnet_subnet_name      = "${local.trusted_vnet_subnet_name}"
  trusted_destination_host      = "${azurerm_storage_account.storage_account.name}.blob.core.windows.net"
}
```

Most of the required variables should already be defined (`env`,`product` etc). The only other variable needed will be the `trusted_destination_host`, which should be the hostname or IP of the destination to where you wish to forward the traffic on to - in the above example, it is being forwarded to a Storage Account that is defined as another resource in Terraform.

For any networking questions regarding your deployment, please speak to Joseph Ball. For anything relating to this Terraform module, speak to James Johnson.
