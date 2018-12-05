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

Most of the required variables should already be defined (`env`,`product` etc). The only other variable needed will be either `trusted_destination_ip` OR `trusted_destination_host`, which should be the IP or hostname of the destination to where you wish to forward the traffic on to - in the above example, it is being forwarded to a Storage Account host that is defined as another resource in Terraform.

Obviously, you will need to send traffic to the Palo Altos in the first place, thus you will need to configure something like an Application Gateway (to handle SSL termination), with the backend pool being configured to point to the Palo Alto untrusted IPs, which are exposed as an output called `untrusted_ips_fqdn`. 
```
module "appGw" {
  source            = "git@github.com:hmcts/cnp-module-waf?ref=stripDownWf"
  env               = "${var.env}"
  ...
  ...
  ...
  # Backend address Pools
  backendAddressPools = [
    {
      name = "${var.product}-${var.env}"

      backendAddresses = "${module.palo_alto.untrusted_ips_fqdn}"
    },
  ]
  ...
  ...
  ...
}  
  ```

Below are some configurable variables for the module that you may wish to override. Please see `variables.tf` for them all:


`vm_offer` : The VM type to host. Defaults to `vmseries1`.

`cluster_size` : The number of VMs to have in the cluster. Defaults to `2`.

`allowed_external_ip` : The allowed IPs on the NSG applied to the Palos. Defaults to `0.0.0.0/0` (allow all)

For any networking questions regarding your deployment, please speak to Joseph Ball. For anything relating to this Terraform module, speak to James Johnson.
