variable "subscription_id" {
  description = "Subscription to assign all six governance policies to. Replace the placeholder default with your own subscription's GUID (or set it via terraform.tfvars / -var)."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a bare GUID (e.g. 00000000-0000-0000-0000-000000000000), not a full resource ID."
  }
}

variable "approved_location" {
  description = "Only region deployments are allowed into (E1)."
  type        = string
  default     = "eastus"
}

variable "approved_vm_skus" {
  description = "Only VM sizes deployments are allowed to use (E3)."
  type        = list(string)
  default     = ["Standard_B1s", "Standard_B2s"]

  validation {
    condition     = length(var.approved_vm_skus) > 0
    error_message = "approved_vm_skus must contain at least one SKU — an empty allowlist blocks every VM size, including the ones this lab needs."
  }
}

variable "identity_location" {
  description = "Region for the system-assigned identities on the two DeployIfNotExists (AMA) assignments. Required by azurerm whenever a policy assignment has an identity block."
  type        = string
  default     = "eastus"
}

variable "ama_role_propagation_wait" {
  description = "How long the AMA deploy modules wait after granting Virtual Machine Contributor before starting remediation, to absorb RBAC replication lag."
  type        = string
  default     = "30s"
}
