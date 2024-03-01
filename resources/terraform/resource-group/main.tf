resource "random_string" "rg_name" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  name     = random_string.rg_name.result
  location = "West Europe"
}