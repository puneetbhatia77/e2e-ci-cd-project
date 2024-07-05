variable "resource_group_name" {
    type = string
    description = "RG in azure"
}

variable "virtual_network_name" {
    type = string
    description = "VG in azure"
}
variable "subnet_name" {
    type = string
    description = "subnet in azure"
}
variable "network_interface_name" {
    type = string
    description = "network interface name in azure"
}
variable "public_ip_name" {
    type = string
    description = "Public IP in azure"
}
variable "virtual_machine_name" {
    type = string
    description = "Virtual machine in azure"
}
variable "admin_username" {
 type    = string
 default = "azureuser"
}

variable "admin_password" {
 type = string
 default = "Password1234!"
}

