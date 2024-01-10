variable "azure_subscription_id" {
  type = string
}
variable "azure_subscription_tenant_id" {
  type = string
}
variable "service_principal_id" {
  type = string
}
variable "service_principal_password" {
  type = string
}
variable "resources_prefix" {
  type    = string
  default = "az-ref-arc-"
}
variable "resource_group_name" {
  type    = string
  default = "rg"
}
variable "location" {
  type    = string
  default = "westeurope"
}
variable "aks_node_size" {
  type    = string
  default = "Standard_D2_v2"
}
variable "aks_node_count" {
  type    = number
  default = 1
}
variable "github_org_id" {
  type = string
}
variable "humanitec_org_id" {
  type = string
}
