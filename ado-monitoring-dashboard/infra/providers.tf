terraform {
  required_version = ">= 1.13.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    storage_account_name = "saadodashboardz238iouv"
    resource_group_name  = "rg-ado-dashboard-bootstrap"
    container_name       = "ado-dashboard-infra-tfstate"
    key                  = "infra.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "core"
}

provider "azuread" {
  tenant_id = var.tenant_id
  # Uses the same OIDC/CLI auth as azurerm.
  # The Terraform identity needs Application.ReadWrite.OwnedBy in MS Graph — see entra.tf.
}

provider "random" {}
