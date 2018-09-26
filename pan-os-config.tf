data "template_file" "host_vars_template" {
  template = "${file("${path.module}/templates/host_vars.yml.template")}"
  count    = "${var.cluster_size}"

  vars {
    mgmt_ip                  = "${element(azurerm_network_interface.mgmt_nic.*.private_ip_address, count.index)}"
    trusted_ip               = "${element(azurerm_network_interface.trusted_nic.*.private_ip_address, count.index)}"
    untrusted_ip             = "${element(azurerm_network_interface.untrusted_nic.*.private_ip_address, count.index)}"
    mgmt_address_prefix      = "${data.azurerm_subnet.mgmt_subnet.address_prefix}"
    trusted_address_prefix   = "${data.azurerm_subnet.trusted_subnet.address_prefix}"
    untrusted_address_prefix = "${data.azurerm_subnet.untrusted_subnet.address_prefix}"
    username                 = "${data.azurerm_key_vault_secret.pan_admin_username.value}"
    password                 = "${data.azurerm_key_vault_secret.pan_admin_password.value}"
    trusted_destination_ip   = "${var.trusted_destination_ip}"
  }
}

resource "null_resource" "ansible_hosts" {
  count = "${var.cluster_size}"

  triggers {
    output = "vm${count.index} ip_address=127.0.0.1"
  }
}

locals {
  ansible_hosts_list = "${join("\n", null_resource.ansible_hosts.*.triggers.output)}"
}

data "template_file" "inventory_template" {
  template = "${file("${path.module}/templates/inventory.ini.template")}"

  vars {
    hosts = "${local.ansible_hosts_list}"
  }
}

resource "local_file" "host_vars_file" {
  content  = "${element(data.template_file.host_vars_template.*.rendered, count.index)}"
  filename = "${path.module}/pan-os-ansible/host_vars/vm${count.index}.yml"
  count    = "${var.cluster_size}"
}

resource "local_file" "inventory_file" {
  content  = "${data.template_file.inventory_template.rendered}"
  filename = "${path.module}/pan-os-ansible/inventory.ini"
}

resource "null_resource" "panos_settings" {
  provisioner "local-exec" {
    command = <<EOF
                PATH=$(pwd)/venv/bin:/usr/local/bin:$PATH
                if [ ! -d "venv" ]; then
                    virtualenv venv
                fi
                . venv/bin/activate
                pip install ansible
                set +x
                ansible-playbook -i pan-os-ansible/inventory.ini -e 'ansible_python_interpreter=venv/bin/python' pan-os-ansible/playbook.yml
              EOF
  }

  triggers = {
    ansible_playbook = "${sha1(file("${path.module}/pan-os-ansible/playbook.yml"))}"
  }

  depends_on = ["local_file.host_vars_file", "local_file.inventory_file", "azurerm_virtual_machine.pan_vm"]
}
