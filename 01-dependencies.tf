resource "null_resource" "dependency_getter" {
  provisioner "local-exec" {
      command = "echo ${length(var.dependencies)}"
  }
}

resource "null_resource" "dependency_setter" {
  depends_on = [
      "azurerm_resource_group.resource_group"
  ]
}

variable "dependencies" {
  type    = "list"
    default = []
}

output "depended_on" {
  value = "${null_resource.dependency_setter.id}"
}
