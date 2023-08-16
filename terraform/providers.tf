terraform {
  required_providers {
    humanitec = {
      source = "humanitec/humanitec"
      version = "0.11.0"
    }
  }
}

provider "humanitec" {
  org_id = var.humanitec_credentials.organization
  token  = var.humanitec_credentials.token
}