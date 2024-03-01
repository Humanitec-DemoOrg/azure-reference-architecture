terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }

    random = {
      source  = "hashicorp/random"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id             =  var.azure_subscription_id
  tenant_id                   =  var.azure_tenant_id
  client_id                   =  var.service_principal_id
  client_secret               =  var.service_principal_password
  skip_provider_registration  = true
}