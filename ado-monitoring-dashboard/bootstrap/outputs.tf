output "storage_account_name" {
  description = "Name of the Storage Account holding Terraform state — needed for backend.tf after migration"
  value       = azurerm_storage_account.bootstrap.name
}

output "resource_group_name" {
  description = "Name of the bootstrap Resource Group"
  value       = azurerm_resource_group.bootstrap.name
}

output "container_name" {
  description = "Name of the Blob Container for Terraform state"
  value       = azurerm_storage_container.bootstrap.name
}

output "project_name" {
  description = "Project name used to derive all resource names"
  value       = var.project_name
}

output "subscription_id" {
  description = "Target subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}
