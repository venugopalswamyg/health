provider "azurerm" {
  features {}
}

# Generated at plan/apply time and stored only in Key Vault + state (never in git).
resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%*-_=+"
}

locals {
  # Sensitive: composed from the generated password and the private Postgres FQDN.
  db_connection_string = "postgresql://${var.postgres_admin_user}:${random_password.db.result}@${module.postgres.fqdn}:5432/${var.postgres_database_name}?sslmode=require"
}

module "network" {
  source               = "../modules/azure_network"
  resource_group_name  = var.resource_group_name
  location             = var.location
  vnet_name            = var.vnet_name
  vnet_cidr            = var.vnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  postgres_subnet_cidr = var.postgres_subnet_cidr
}

module "acr" {
  source              = "../modules/azure_acr"
  acr_name            = var.acr_name
  resource_group_name = module.network.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
}

module "postgres" {
  source              = "../modules/azure_postgres"
  server_name         = var.postgres_server_name
  resource_group_name = module.network.resource_group_name
  location            = var.location
  admin_user          = var.postgres_admin_user
  admin_password      = random_password.db.result
  sku_name            = var.postgres_sku
  storage_gb          = var.postgres_storage_gb
  subnet_id           = module.network.postgres_subnet_id
  private_dns_zone_id = module.network.postgres_private_dns_zone_id
  database_name       = var.postgres_database_name
}

module "keyvault" {
  source              = "../modules/azure_keyvault"
  vault_name          = var.keyvault_name
  location            = var.location
  resource_group_name = module.network.resource_group_name
  tenant_id           = var.tenant_id
  secret_name         = var.keyvault_secret_name
  secret_value        = local.db_connection_string
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law-${var.environment}"
  location            = var.location
  resource_group_name = module.network.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

module "aks" {
  source                     = "../modules/azure_aks"
  cluster_name               = var.aks_cluster_name
  location                   = var.location
  resource_group_name        = module.network.resource_group_name
  node_count                 = var.aks_node_count
  node_vm_size               = var.aks_node_vm_size
  min_count                  = var.aks_min_count
  max_count                  = var.aks_max_count
  subnet_id                  = module.network.aks_subnet_id
  availability_zones         = var.availability_zones
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}
