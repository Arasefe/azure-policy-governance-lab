# Integration test for the root module: no `module { source = ... }`
# override, so this exercises main.tf/locals.tf/variables.tf exactly as a
# real `terraform plan` would, just against mocked providers instead of a
# real subscription.

mock_provider "azurerm" {
  # data.azurerm_subscription.cavalry_prod.id feeds every module's
  # subscription_id below — give it a properly-shaped subscription resource
  # ID instead of the mock default's random 8-char string.
  mock_data "azurerm_subscription" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }

  # Same reasoning as deploy_module.tftest.hcl: the remediation resource
  # parses policy_assignment_id as a strongly-typed ARM ID.
  mock_resource "azurerm_subscription_policy_assignment" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/mock-assignment"
    }
  }
}
mock_provider "time" {}

run "plans_all_seven_policy_assignments" {
  command = plan

  assert {
    condition     = length(module.deny_effect) == 5
    error_message = "Expected 5 deny/fixed-effect assignments: allowed_locations, storage_no_public_access, allowed_vm_skus, disks_no_public_access, appservice_https_only"
  }

  assert {
    condition     = length(module.deploy_effect) == 2
    error_message = "Expected 2 DeployIfNotExists assignments: ama_windows, ama_linux"
  }
}

run "e3_allowed_vm_skus_has_no_effect_parameter" {
  command = plan

  assert {
    condition     = !contains(keys(module.deny_effect["allowed_vm_skus"].parameters), "effect")
    error_message = "allowed_vm_skus (E3) must not carry an effect parameter — the real definition has none"
  }
}

run "e1_e2_e4_e6_all_default_to_deny" {
  command = plan

  assert {
    condition = alltrue([
      for k in ["allowed_locations", "storage_no_public_access", "disks_no_public_access", "appservice_https_only"] :
      module.deny_effect[k].parameters.effect.value == "Deny"
    ])
    error_message = "E1, E2, E4, E6 must all render effect = Deny by default"
  }
}

run "ama_policies_use_virtual_machine_contributor" {
  command = apply

  assert {
    condition = alltrue([
      for k, m in module.deploy_effect :
      contains(keys(m.role_assignment_ids), "Virtual Machine Contributor")
    ])
    error_message = "Both AMA assignments must grant Virtual Machine Contributor to their identity"
  }

  assert {
    condition     = length(output.ama_principal_ids) == 2
    error_message = "Root output should expose a principal ID for both AMA assignments"
  }
}
