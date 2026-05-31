# ============================================================
# BOOTSTRAP PHASE 1 — local state (first run)
# ============================================================
# Leave this file as-is on the first run. Terraform will use
# a local state file in this directory.
#
# After `terraform apply` succeeds, retrieve the storage
# account name that was created:
#
#   terraform output storage_account_name
#
# Then:
#   1. Uncomment the backend block below and fill in the
#      storage account name from the output above.
#   2. Run: terraform init -migrate-state
#      to move local state into the new remote backend.
# ============================================================

terraform {
  backend "azurerm" {
    storage_account_name = "saadodashboardz238iouv"
    resource_group_name  = "rg-ado-dashboard-bootstrap"
    container_name       = "ado-dashboard-bootstrap-tfstate"
    key                  = "bootstrap.tfstate"
  }
}
