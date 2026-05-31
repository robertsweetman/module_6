# ============================================================================
# Entra ID App Registration — used by Easy Auth on the Function App
# ============================================================================
# PREREQUISITE: The identity running Terraform must have the
# Application.ReadWrite.OwnedBy (or Application.ReadWrite.All) application
# permission in Microsoft Graph.
#
# For the ADO pipeline UAMI: grant it in the Azure portal under
#   Entra ID → Enterprise applications → <UAMI display name> → Permissions
#   → Grant admin consent for Application.ReadWrite.OwnedBy
#
# For local CLI runs: your signed-in user needs Application Administrator
# (or Global Administrator) role in Entra ID.
# ============================================================================

resource "azuread_application" "dashboard" {
  display_name     = "app-${var.project_name}-${var.environment}-dashboard"
  sign_in_audience = "AzureADMyOrg" # This tenant only

  web {
    # Redirect URI is deterministic because we compute the hostname in locals.tf
    redirect_uris = [
      "https://${local.function_app_hostname}/.auth/login/aad/callback",
    ]

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }

  # Request User.Read so Easy Auth can populate the identity principal
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read (delegated)
      type = "Scope"
    }
  }
}

# Client secret used by Easy Auth to exchange the auth code for tokens
resource "azuread_application_password" "dashboard" {
  application_id = azuread_application.dashboard.id
  display_name   = "terraform-managed"
  end_date       = "2099-01-01T00:00:00Z"
}

# Service principal — needed for tenant-level consent and sign-in
resource "azuread_service_principal" "dashboard" {
  client_id = azuread_application.dashboard.client_id
}
