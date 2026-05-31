variable "subscription_id" {
  description = "The Azure Subscription ID to deploy resources into."
  type        = string
  default     = "d576283e-72e4-4cfd-8310-4f182b07dd00"
}

variable "tenant_id" {
  description = "The Azure Tenant ID."
  type        = string
  default     = "244a3dcc-ae95-4959-a5ea-4b91a7c7e291"
}

variable "location" {
  description = "The Azure region to deploy resources into."
  type        = string
  default     = "UK South"
}

variable "function_location" {
  description = "Azure region for the Function App and its supporting resources (storage, Key Vault). Separate from var.location to allow deploying into a region with available quota."
  type        = string
  default     = "UK West"
}

variable "project_name" {
  description = "Short name used to derive resource names."
  type        = string
  default     = "ado-dashboard"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, test, prod)."
  type        = string
  default     = "dev"
}
