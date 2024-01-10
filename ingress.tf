resource "azurerm_public_ip" "public_ip" {
  name                = "${var.resources_prefix}privateip"
  resource_group_name = "${var.resources_prefix}${var.resource_group_name}"
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  depends_on          = [azurerm_resource_group.ref_arc]
}

resource "azurerm_role_assignment" "network_contributor" {
  principal_id                     = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name             = "Network Contributor"
  scope                            = azurerm_resource_group.ref_arc.id
  skip_service_principal_aad_check = true
  depends_on                       = [azurerm_public_ip.public_ip]
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"

  chart   = "ingress-nginx"
  version = "4.8.2"
  wait    = true
  timeout = 600


  set {
    type  = "string"
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    type  = "string"
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.public_ip.ip_address
  }

  set {
    name    = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-ipv4"
    value   = azurerm_public_ip.public_ip.ip_address
  }

  set {
    type  = "string"
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
    value = azurerm_resource_group.ref_arc.name
  }

  set {
    name    = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
    value   = "/healthz"
  }

  set {
    type  = "string"
    name  = "controller.replicaCount"
    value = 2
  }

  set {
    type  = "string"
    name  = "controller.minAvailable"
    value = 1
  }

  depends_on = [azurerm_kubernetes_cluster.aks, azurerm_public_ip.public_ip]
}
