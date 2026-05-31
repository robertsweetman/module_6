# Federated identity credential — links the UAMI to an Azure DevOps service connection
# via Workload Identity Federation (no secrets required).
#
# How to populate the issuer and subject:
#   1. In Azure DevOps, go to Project Settings > Service connections > New service connection
#      > Azure Resource Manager > Workload identity federation (manual).
#   2. Copy the "Issuer" and "Subject identifier" values shown in the wizard.
#   3. Paste them into the variables below and run terraform apply again.
#
# Reference: https://learn.microsoft.com/azure/devops/pipelines/library/connect-to-azure

resource "azurerm_federated_identity_credential" "azdo" {
  name                      = "azdo-federation-${var.project_name}"
  user_assigned_identity_id = azurerm_user_assigned_identity.smi.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer = var.azdo_federation_issuer
  subject = var.azdo_federation_subject
}
