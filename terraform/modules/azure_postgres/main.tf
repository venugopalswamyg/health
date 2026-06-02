resource "azurerm_postgresql_flexible_server" "pg" {
  name                = var.server_name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = "14"

  administrator_login    = var.admin_user
  administrator_password = var.admin_password

  sku_name              = var.sku_name
  storage_mb            = var.storage_gb * 1024
  backup_retention_days = 7
  zone                  = "1"

  # Private networking only: no public endpoint, injected into the delegated subnet.
  delegated_subnet_id           = var.subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = false
}

# Enforce TLS for all client connections.
resource "azurerm_postgresql_flexible_server_configuration" "require_ssl" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.pg.id
  value     = "ON"
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.pg.id
}

output "fqdn" {
  value     = azurerm_postgresql_flexible_server.pg.fqdn
  sensitive = true
}

output "server_name" {
  value = azurerm_postgresql_flexible_server.pg.name
}
