locals {
  # Merge the optional effect parameter with any definition-specific parameters
  # (e.g. listOfAllowedLocations, listOfAllowedSKUs). When effect is null — the
  # Allowed VM SKUs case, which has no Effect parameter on the definition at all —
  # this key is omitted entirely rather than sent as an invalid/empty value.
  parameters_map = merge(
    var.extra_parameters,
    var.effect == null ? {} : { effect = { value = var.effect } }
  )
}

resource "azurerm_subscription_policy_assignment" "this" {
  name                 = var.name
  display_name         = var.display_name
  policy_definition_id = var.policy_definition_id
  subscription_id      = var.subscription_id
  not_scopes           = var.not_scopes

  parameters = length(local.parameters_map) > 0 ? jsonencode(local.parameters_map) : null
}
