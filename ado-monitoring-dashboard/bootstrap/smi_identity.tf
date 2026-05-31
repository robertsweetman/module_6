# User-assigned managed identity used by Azure DevOps pipelines to deploy infra
resource "azurerm_user_assigned_identity" "smi" {
  name                = "id-smi-${var.project_name}-terraform"
  resource_group_name = azurerm_resource_group.bootstrap.name
  location            = azurerm_resource_group.bootstrap.location
  tags                = local.common_tags
}
