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
  description = "Full resource ID of the built-in (or custom) policy definition to assign, e.g. /providers/Microsoft.Authorization/policyDefinitions/<guid>."
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

variable "effect" {
  description = "Value for this definition's built-in Effect parameter. Set to null for definitions that have no Effect parameter at all (e.g. Allowed virtual machine size SKUs, which is hard-coded Deny) — passing null omits the effect key from parameters entirely instead of sending an invalid value."
  type        = string
  default     = null

  validation {
    condition     = var.effect == null || contains(["Audit", "Deny", "Disabled"], var.effect)
    error_message = "effect must be one of Audit, Deny, Disabled, or null (to omit it for definitions with no Effect parameter)."
  }
}

variable "extra_parameters" {
  description = "Additional policy parameters beyond effect, keyed by parameter name, each as {value = ...} matching the assignment parameters JSON shape. Example: {listOfAllowedLocations = {value = [\"eastus\"]}}."
  type        = any
  default     = {}
}

variable "not_scopes" {
  description = "Resource scopes excluded from this assignment."
  type        = list(string)
  default     = []
}
