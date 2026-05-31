# Subscription-level RBAC for the managed identity
# Scoped to this subscription only — no management group required

# Allows the SMI to read/write state blobs in the bootstrap storage account
resource "azurerm_role_assignment" "smi_storage_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.smi.principal_id
}

# Allows the SMI to deploy any resource type within the subscription
resource "azurerm_role_assignment" "smi_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.smi.principal_id
}

# Allows the SMI to assign roles to resources it creates (needed for infra deployments)
resource "azurerm_role_assignment" "smi_user_access_admin" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "User Access Administrator"
  principal_id         = azurerm_user_assigned_identity.smi.principal_id
}
