output "assignment_id" {
  description = "Resource ID of the policy assignment."
  value       = azurerm_subscription_policy_assignment.this.id
}

output "principal_id" {
  description = "Object ID of the assignment's system-assigned managed identity."
  value       = azurerm_subscription_policy_assignment.this.identity[0].principal_id
}

output "role_assignment_ids" {
  description = "Resource IDs of every role assignment granted to the identity, keyed by role name."
  value       = { for role, ra in azurerm_role_assignment.this : role => ra.id }
}

output "remediation_id" {
  description = "Resource ID of the remediation task."
  value       = azurerm_subscription_policy_remediation.this.id
}
