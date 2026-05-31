# Bootstrap resources: remote state backend (storage account) and its prerequisites

resource "azurerm_resource_group" "bootstrap" {
  name     = "rg-ado-dashboard-bootstrap"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "bootstrap" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.bootstrap.name
  location                 = azurerm_resource_group.bootstrap.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }

  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = length(local.storage_account_name) >= 3 && length(local.storage_account_name) <= 24
      error_message = "Storage account name must be between 3 and 24 characters. Current name '${local.storage_account_name}' is ${length(local.storage_account_name)} characters."
    }
  }
}

resource "azurerm_storage_container" "bootstrap" {
  name                  = "ado-dashboard-bootstrap-tfstate"
  storage_account_id    = azurerm_storage_account.bootstrap.id
  container_access_type = "private"
}

resource "random_string" "storage_account_suffix" {
  length  = 8
  upper   = false
  special = false

  # Keepers prevent regeneration unless these values change
  keepers = {
    location     = var.location
    project_name = var.project_name
  }
}
