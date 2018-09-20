resource "null_resource" "pan_configuration" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${var.inventory}  --extra-vars 'username=${var.username} password=${var.password}' modules/palo-alto-config/pan-os-ansible/playbook.yml"
  }
  triggers = {
        inventory = "${var.inventory}"
        username = "${var.username}"
        password = "${var.password}"
        ansible_playbook = "${sha1(file("${path.module}/pan-os-ansible/playbook.yml"))}"
    }
}