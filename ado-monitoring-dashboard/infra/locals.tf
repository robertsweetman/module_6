resource "random_string" "resource_suffix" {
  length  = 6
  upper   = false
  special = false
  keepers = {
    location     = var.location
    project_name = var.project_name
    environment  = var.environment
  }
}

locals {
  common_tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }

  # Compact (alphanumeric-only) project name for resources with tight naming rules
  project_compact = replace(lower(var.project_name), "-", "")

  # Globally-unique resource names derived from the shared random suffix
  func_storage_name = "sa${local.project_compact}fn${random_string.resource_suffix.result}"
  keyvault_name     = "kv-${var.project_name}-${random_string.resource_suffix.result}"
  function_app_name = "func-${var.project_name}-${var.environment}-${random_string.resource_suffix.result}"

  # Predictable hostname (used by the Entra App Registration redirect URI)
  function_app_hostname = "${local.function_app_name}.azurewebsites.net"
}
