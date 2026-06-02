// Azure backend (blob storage). Set `storage_account_name` and `container_name` via vars.
terraform {
  backend "azurerm" {
    resource_group_name  = var.backend_resource_group
    storage_account_name = var.backend_storage_account
    container_name       = var.backend_container
    key                  = var.backend_key
  }
}
