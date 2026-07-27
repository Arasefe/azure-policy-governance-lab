variable "name" {
  description = "Name of the policy assignment. Cannot exceed 64 characters."
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 64
    error_message = "name must be between 1 and 64 characters."
  }
}

variable "display_name" {
  description = "Human-readable display name shown in the Azure portal."
  type        = string
}

variable "policy_definition_id" {
  description = "Full resource ID of the built-in DeployIfNotExists policy definition to assign."
  type        = string

  validation {
    condition     = can(regex("^/providers/Microsoft\\.Authorization/policyDefinitions/.+$", var.policy_definition_id))
    error_message = "policy_definition_id must be a full ARM resource ID under /providers/Microsoft.Authorization/policyDefinitions/."
  }
}

variable "subscription_id" {
  description = "Full ARM resource ID of the subscription to assign the policy to (e.g. data.azurerm_subscription.x.id), not the bare GUID."
  type        = string
}

variable "location" {
  description = "Azure region for the assignment's system-assigned identity. Required by the provider whenever a policy assignment has an identity block."
  type        = string
}

variable "role_definition_names" {
  description = "Built-in role(s) the assignment's managed identity needs in order to actually remediate — read from the definition's roleDefinitionIds (e.g. Virtual Machine Contributor for the AMA policies). Almost always a single role, but kept as a set in case a definition needs more than one."
  type        = set(string)

  validation {
    condition     = length(var.role_definition_names) > 0
    error_message = "role_definition_names must contain at least one role — a DeployIfNotExists assignment with no granted role can only audit, never deploy."
  }
}

variable "remediation_name" {
  description = "Name of the remediation task that backfills existing non-compliant resources."
  type        = string
}

variable "resource_discovery_mode" {
  description = "How remediation discovers resources to fix. ExistingNonCompliant (default) only touches resources already known to be non-compliant; ReEvaluateCompliance re-runs compliance evaluation first."
  type        = string
  default     = "ExistingNonCompliant"

  validation {
    condition     = contains(["ExistingNonCompliant", "ReEvaluateCompliance"], var.resource_discovery_mode)
    error_message = "resource_discovery_mode must be ExistingNonCompliant or ReEvaluateCompliance."
  }
}

variable "role_propagation_wait" {
  description = "How long to wait after granting the role assignment before starting remediation, to absorb Azure AD/RBAC replication lag. Real-world assignments have been observed to fail remediation when it starts immediately after the role assignment is created."
  type        = string
  default     = "30s"
}
