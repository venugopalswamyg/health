variable "backend_resource_group" { type = string }
variable "backend_storage_account" { type = string }
variable "backend_container" { type = string }
variable "backend_key" { type = string }

variable "location" { type = string }
variable "environment" { type = string }
variable "prefix" { type = string }

variable "resource_group_name" { type = string }
variable "vnet_name" { type = string }
variable "vnet_cidr" { type = string }
variable "private_subnet_cidr" { type = string }
variable "public_subnet_cidr" { type = string }

variable "postgres_subnet_cidr" {
  type    = string
  default = "10.20.3.0/24"
}

variable "availability_zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "acr_name" { type = string }
variable "acr_sku" { type = string }

variable "keyvault_name" { type = string }
variable "tenant_id" { type = string }
variable "keyvault_secret_name" { type = string }

variable "postgres_server_name" { type = string }
variable "postgres_admin_user" { type = string }
variable "postgres_sku" { type = string }
variable "postgres_storage_gb" { type = number }
variable "postgres_database_name" { type = string }

variable "aks_cluster_name" { type = string }
variable "aks_node_count" { type = number }
variable "aks_node_vm_size" { type = string }
variable "aks_min_count" { type = number }
variable "aks_max_count" { type = number }
