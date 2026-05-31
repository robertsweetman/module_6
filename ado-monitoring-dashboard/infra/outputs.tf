output "resource_group_name" {
  description = "Name of the main resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the main resource group"
  value       = azurerm_resource_group.main.id
}

output "dashboard_url" {
  description = "URL of the ADO monitoring dashboard"
  value       = "https://${azurerm_linux_function_app.main.default_hostname}/"
}

output "function_app_name" {
  description = "Name of the Function App (needed for code deployment)"
  value       = azurerm_linux_function_app.main.name
}

output "ingest_api_key_secret_uri" {
  description = "Key Vault secret URI for the ingest API key — copy the value into ADO as DashboardIngestKey"
  value       = azurerm_key_vault_secret.ingest_api_key.id
  sensitive   = true
}

output "key_vault_name" {
  description = "Key Vault name — use this to retrieve the ingest API key"
  value       = azurerm_key_vault.main.name
}
