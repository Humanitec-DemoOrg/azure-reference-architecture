resource "humanitec_resource_definition" "aks" {
  id          = "aks"
  name        = "aks"
  type        = "k8s-cluster"
  driver_type = "humanitec/k8s-cluster-aks"

  driver_inputs = {
    values_string = jsonencode({
      "loadbalancer" : "${azurerm_public_ip.public_ip.ip_address}"
      "name" : "${azurerm_kubernetes_cluster.aks.name}"
      "resource_group" : "${resource.azurerm_resource_group.ref_arc.name}"
      "subscription_id" : "${var.azure_subscription_id}"
    })
    secrets_string = jsonencode({
      "credentials" = {
        "appId" : "${azuread_application.application.application_id}",
        "displayName" : "${azuread_application.application.display_name}",
        "password" : "${azuread_service_principal_password.password.value}",
        "tenant" : "${azuread_service_principal.principal.application_tenant_id}"
      }
    })
  }
  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "humanitec_resource_definition_criteria" "aks" {
  resource_definition_id = humanitec_resource_definition.aks.id
  env_id                 = "azure"
}

resource "humanitec_resource_definition" "k8s_logging" {
  driver_type = "humanitec/logging-k8s"
  id          = "azure-logging"
  name        = "azure-logging"
  type        = "logging"

  driver_inputs = {}
}

resource "humanitec_resource_definition_criteria" "k8s_logging" {
  resource_definition_id = humanitec_resource_definition.k8s_logging.id
  env_id = "azure"
}

resource "humanitec_resource_definition" "k8s_namespace" {
  driver_type = "humanitec/static"
  id          = "azure-namespace"
  name        = "azure-namespace"
  type        = "k8s-namespace"

  driver_inputs = {
    values_string = jsonencode({
      "namespace" = "$${context.app.id}-$${context.env.id}"
    })
  }
}

resource "humanitec_resource_definition_criteria" "k8s_namespace" {
  resource_definition_id = humanitec_resource_definition.k8s_namespace.id
  env_id = "azure"
}
