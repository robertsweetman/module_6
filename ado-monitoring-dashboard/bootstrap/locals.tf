locals {
  # Strip non-alphanumeric characters and cap at 15 chars to leave room for the 8-char random suffix
  storage_name_base    = substr(replace(lower(var.project_name), "/[^a-z0-9]/", ""), 0, 15)
  storage_account_name = "sa${local.storage_name_base}${random_string.storage_account_suffix.result}"

  common_tags = {
    project     = var.project_name
    environment = "bootstrap"
    managed_by  = "terraform"
  }
}
