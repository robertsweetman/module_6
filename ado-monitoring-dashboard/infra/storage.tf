# ============================================================================
# Storage — Function App internals + Table Storage for pipeline events
# ============================================================================

resource "azurerm_storage_account" "function" {
  name                            = local.func_storage_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = var.function_location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = local.common_tags
}

# Table that stores one row per ADO pipeline run event
resource "azurerm_storage_table" "pipeline_events" {
  name                 = "pipelineevents"
  storage_account_name = azurerm_storage_account.function.name
}
