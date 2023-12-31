terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id             =  var.credentials.azure_subscription_id
  tenant_id                   =  var.credentials.azure_subscription_tenant_id
  client_id                   =  var.credentials.service_principal_id
  client_secret               =  var.credentials.service_principal_password
  skip_provider_registration  = true
}