resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name

  # Hardening: private API server, OIDC issuer + Workload Identity (federated, no SP secrets).
  private_cluster_enabled           = var.private_cluster_enabled
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  role_based_access_control_enabled = true
  local_account_disabled            = false
  sku_tier                          = "Free"

  default_node_pool {
    name                = "agentpool"
    vm_size             = var.node_vm_size
    enable_auto_scaling = true
    node_count          = var.node_count
    min_count           = var.min_count
    max_count           = var.max_count
    zones               = var.availability_zones
    vnet_subnet_id      = var.subnet_id

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
  }

  # Audit logging / Container Insights into Log Analytics.
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # Secrets Store CSI driver + Azure Key Vault provider (with rotation).
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive = true
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}
