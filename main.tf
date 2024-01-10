resource "azurerm_resource_group" "ref_arc" {
  location = var.location
  name     = "${var.resources_prefix}${var.resource_group_name}"
}

resource "azurerm_virtual_network" "ref_arc" {
  address_space       = ["10.52.0.0/16"]
  location            = var.location
  name                = "${var.resources_prefix}vn"
  resource_group_name = azurerm_resource_group.ref_arc.name
}

resource "azurerm_subnet" "ref_arc" {
  address_prefixes                               = ["10.52.0.0/24"]
  name                                           = "${var.resources_prefix}sn"
  resource_group_name                            = azurerm_resource_group.ref_arc.name
  virtual_network_name                           = azurerm_virtual_network.ref_arc.name
  enforce_private_link_endpoint_network_policies = true
}

resource "random_string" "unique_name_random_string" {
  length  = 6
  special = false
}

resource "azurerm_container_registry" "ref_arc" {
  location            = var.location
  name                = replace("${var.resources_prefix}acr${random_string.unique_name_random_string.result}", "-", "")
  resource_group_name = azurerm_resource_group.ref_arc.name
  sku                 = "Basic"
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.ref_arc.id
  skip_service_principal_aad_check = true
  depends_on                       = [azurerm_kubernetes_cluster.aks, azurerm_container_registry.ref_arc]
}

data "azuread_client_config" "current" {}

resource "azuread_application" "application" {
  display_name = " ${var.resources_prefix}app"
  depends_on = [ data.azuread_client_config.current ]
}

resource "azuread_service_principal" "principal" {
  application_id = azuread_application.application.application_id
  depends_on = [ azuread_application.application ]
}

resource "azuread_service_principal_password" "password" {
  service_principal_id = azuread_service_principal.principal.id
  depends_on = [ azuread_service_principal.principal]
}

resource "azurerm_role_assignment" "aks_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = azuread_service_principal.principal.id
  depends_on           = [azurerm_kubernetes_cluster.aks, azuread_service_principal.principal]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.resources_prefix}aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.ref_arc.name
  dns_prefix          = "${var.resources_prefix}aks"

  default_node_pool {
    name       = "default"
    node_count = var.aks_node_count
    vm_size    = var.aks_node_size
  }

  identity {
    type = "SystemAssigned"
  }
}
