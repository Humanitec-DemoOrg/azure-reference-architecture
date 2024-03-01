variable "azure_subscription_id" {
  type        = string
}

variable "azure_tenant_id" {
  type        = string
}

variable "service_principal_id" {
  type        = string
  sensitive   = true
}

variable "service_principal_password" {
  type        = string
  sensitive   = true
}

variable "location" {
  type        = string
  default     = "eastus"
}