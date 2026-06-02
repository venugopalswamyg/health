output "acr_login_server" {
  value = module.acr.login_server
}

output "key_vault_id" {
  value = module.keyvault.key_vault_id
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "postgres_fqdn" {
  value     = module.postgres.fqdn
  sensitive = true
}

output "database_connection_string" {
  value     = local.db_connection_string
  sensitive = true
}

output "service_url" {
  value = "https://healthcare-app.${var.environment}.example.com"
}

output "aks_oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}

output "aks_kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}
