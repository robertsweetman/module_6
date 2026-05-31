output "smi_role_assignments" {
  description = "RBAC roles assigned to the managed identity"
  value = {
    storage_contributor = azurerm_role_assignment.smi_storage_contributor.role_definition_name
    contributor         = azurerm_role_assignment.smi_contributor.role_definition_name
    user_access_admin   = azurerm_role_assignment.smi_user_access_admin.role_definition_name
  }
}

output "smi_client_id" {
  description = "Client ID of the managed identity — paste this into the Azure DevOps service connection wizard"
  value       = azurerm_user_assigned_identity.smi.client_id
}

output "smi_principal_id" {
  description = "Principal (object) ID of the managed identity"
  value       = azurerm_user_assigned_identity.smi.principal_id
}

output "smi_tenant_id" {
  description = "Tenant ID associated with the managed identity"
  value       = azurerm_user_assigned_identity.smi.tenant_id
}
