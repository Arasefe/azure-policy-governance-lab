# Six governance policies from
# "Enforcing Cloud Governance and Security Posture via Azure Policy"
# (E1, E2, E4, E6 = deny-effect; E3 = fixed-Deny, no effect param;
#  E5 = DeployIfNotExists Windows + Linux AMA), each wired through a
# reusable local module instead of six copy-pasted resource blocks.

module "deny_effect" {
  source   = "./modules/policy-assignment-deny"
  for_each = local.deny_effect_policies

  name                 = each.value.name
  display_name         = each.value.display_name
  policy_definition_id = each.value.policy_definition_id
  subscription_id      = data.azurerm_subscription.cavalry_prod.id
  effect               = each.value.effect
  extra_parameters     = each.value.extra_parameters
}

module "deploy_effect" {
  source   = "./modules/policy-assignment-deploy"
  for_each = local.deploy_effect_policies

  name                  = each.value.name
  display_name          = each.value.display_name
  policy_definition_id  = each.value.policy_definition_id
  subscription_id       = data.azurerm_subscription.cavalry_prod.id
  location              = var.identity_location
  role_definition_names = each.value.role_definition_names
  remediation_name      = each.value.remediation_name
  role_propagation_wait = var.ama_role_propagation_wait
}
