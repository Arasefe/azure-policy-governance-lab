output "id" {
  description = "Resource ID of the policy assignment."
  value       = azurerm_subscription_policy_assignment.this.id
}

output "name" {
  description = "Name of the policy assignment."
  value       = azurerm_subscription_policy_assignment.this.name
}

output "parameters" {
  description = "The rendered parameters map actually sent to the assignment (pre-jsonencode) — exposed so tests can assert on it without depending on provider-computed state."
  value       = local.parameters_map
}
