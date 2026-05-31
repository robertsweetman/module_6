# ============================================================================
# Azure Function App — event ingest + dashboard
# ============================================================================

resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.function_location
  os_type             = "Linux"
  sku_name            = "B1" # Basic plan — avoids VM quota issues on personal subscriptions
                             # (~£10/mo). Switch to Y1 (Consumption) if quota is raised.

  tags = local.common_tags
}

resource "azurerm_linux_function_app" "main" {
  name                       = local.function_app_name
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.function_location
  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key
  functions_extension_version = "~4"
  https_only                 = true

  site_config {
    always_on = true

    application_stack {
      python_version = "3.11"
    }

    cors {
      allowed_origins     = ["https://${local.function_app_hostname}"]
      support_credentials = true
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"           = "python"
    "AzureWebJobsFeatureFlags"           = "EnableWorkerIndexing"
    "ENABLE_ORYX_BUILD"                  = "true"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"     = "true"
    "PYTHON_ENABLE_DEBUG_LOGGING"         = "1"

    # Ingest API key — resolved from Key Vault at runtime
    "INGEST_API_KEY" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.ingest_api_key.id})"

    # Easy Auth client secret — resolved from Key Vault at runtime
    "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.app_client_secret.id})"

    # Table Storage (same account as function internals)
    "TABLE_STORAGE_CONNECTION_STRING" = azurerm_storage_account.function.primary_connection_string
    "TABLE_NAME"                      = azurerm_storage_table.pipeline_events.name
  }

  # System-assigned identity needed for Key Vault secret references
  identity {
    type = "SystemAssigned"
  }

  # ── Easy Auth v2 — Entra ID, this tenant only ──────────────────────────
  # unauthenticated_action = AllowAnonymous so that:
  #   • ADO pipeline can POST /events using the x-api-key header (no Entra token)
  #   • The function code redirects unauthenticated browser sessions to AAD login
  #   • /.auth/login/aad and /.auth/me are served by the App Service platform
  auth_settings_v2 {
    auth_enabled           = true
    unauthenticated_action = "AllowAnonymous"
    default_provider       = "azureactivedirectory"

    active_directory_v2 {
      client_id                  = azuread_application.dashboard.client_id
      tenant_auth_endpoint       = "https://login.microsoftonline.com/${var.tenant_id}/v2.0"
      client_secret_setting_name = "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"
      allowed_audiences          = ["api://${azuread_application.dashboard.client_id}"]
    }

    login {
      token_store_enabled = true
    }
  }

  tags = local.common_tags
}
