variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "vnet_name" { type = string }
variable "vnet_cidr" { type = string }
variable "private_subnet_cidr" { type = string }
variable "public_subnet_cidr" { type = string }

variable "postgres_subnet_cidr" {
  type    = string
  default = "10.20.3.0/24"
}
