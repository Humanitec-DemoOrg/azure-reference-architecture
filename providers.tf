terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    azuread = {
      source = "hashicorp/azuread"
    }
    helm = {
      source = "hashicorp/helm"
    }
    humanitec = {
      source = "humanitec/humanitec"
    }
    github = {
      source = "integrations/github"
    }
  }
  required_version = ">= 1.3.0"
}

provider "humanitec" {
  org_id = var.humanitec_org_id
}

provider "github" {
  owner = var.github_org_id
}

provider "azurerm" {
  features {}
  ### Uncomment the following lines to use a service principal
  ### instead of the Azure CLI for Terraform authentication
  ### (https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
  ### Be aware, that you need to provide the SP with the right permissions to not only create resources
  ### but also to create application registrations in the corresponding Azure AD tenant.
  # subscription_id            = var.azure_subscription_id
  # tenant_id                  = var.azure_subscription_tenant_id
  # client_id                  = var.service_principal_id
  # client_secret              = var.service_principal_password
}

provider "azuread" {
  ### Uncomment the following lines to use a service principal
  ### instead of the Azure CLI for Terraform authentication against Azure AD
  # tenant_id     = var.azure_subscription_tenant_id
  # client_id     = var.service_principal_id
  # client_secret = var.service_principal_password
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}
