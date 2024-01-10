output "aks_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "aks_loadbalancer" {
  value = azurerm_public_ip.public_ip.ip_address
}
