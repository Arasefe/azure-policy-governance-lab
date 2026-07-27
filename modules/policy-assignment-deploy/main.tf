resource "azurerm_subscription_policy_assignment" "this" {
  name                 = var.name
  display_name         = var.display_name
  policy_definition_id = var.policy_definition_id
  subscription_id      = var.subscription_id
  location             = var.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_definition_names

  scope                = var.subscription_id
  role_definition_name = each.value
  principal_id         = azurerm_subscription_policy_assignment.this.identity[0].principal_id

  # The identity is a brand-new service principal created moments ago by the
  # policy assignment above — the AAD replication check on a fresh principal
  # can fail transiently, so skip it rather than retrying on apply.
  skip_service_principal_aad_check = true
}

# Azure RBAC role assignments themselves replicate asynchronously across
# regions. Starting remediation immediately after granting the role can fail
# with an authorization error even though the assignment already exists —
# this buffer absorbs that lag before the remediation task's first attempt.
resource "time_sleep" "wait_for_role_propagation" {
  depends_on      = [azurerm_role_assignment.this]
  create_duration = var.role_propagation_wait
}

resource "azurerm_subscription_policy_remediation" "this" {
  name                    = var.remediation_name
  subscription_id         = var.subscription_id
  policy_assignment_id    = azurerm_subscription_policy_assignment.this.id
  resource_discovery_mode = var.resource_discovery_mode

  depends_on = [time_sleep.wait_for_role_propagation]
}
