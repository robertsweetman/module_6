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

variable "project_name" {
  description = "The name of the project. Used to derive resource names."
  type        = string
  default     = "adodashboard"
}

variable "azdo_federation_issuer" {
  description = "The Issuer URL from the Azure DevOps Workload Identity Federation service connection wizard."
  type        = string
  default     = "https://login.microsoftonline.com/244a3dcc-ae95-4959-a5ea-4b91a7c7e291/v2.0"
}

variable "azdo_federation_subject" {
  description = "The Subject Identifier from the Azure DevOps Workload Identity Federation service connection wizard."
  type        = string
  default     = "/eid1/c/pub/t/zD1KJJWuWUml6kuRp8fikQ/a/rISbSSETf0KqFyZ8ppdXmA/sc/04dd6204-1462-4379-b082-6c1c837b2d77/e733f732-190d-426a-8b2e-598df6004e58"
}
