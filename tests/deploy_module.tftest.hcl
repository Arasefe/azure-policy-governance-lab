# Unit tests for modules/policy-assignment-deploy. Both providers are mocked,
# so `command = apply` here still touches zero real Azure resources — the
# mock provider fabricates computed values (identity principal_id, etc.)
# instead of calling out to Azure.

mock_provider "azurerm" {
  # The remediation resource parses policy_assignment_id as a strongly-typed
  # ARM resource ID, and the mock provider's default random-8-char string for
  # computed attributes doesn't satisfy that format — override it with a
  # realistically-shaped ID so `command = apply` gets past ID parsing.
  mock_resource "azurerm_subscription_policy_assignment" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/mock-assignment"
    }
  }
}
mock_provider "time" {}

variables {
  name                  = "deploy-ama-windows"
  display_name          = "Auto-deploy AMA on Windows VMs"
  policy_definition_id  = "/providers/Microsoft.Authorization/policyDefinitions/ca817e41-e85a-4783-bc7f-dc532d36235e"
  subscription_id       = "/subscriptions/00000000-0000-0000-0000-000000000000"
  location              = "eastus"
  role_definition_names = ["Virtual Machine Contributor"]
  remediation_name      = "remediate-ama-windows"
}

# Plan-only: confirms the shape of the config (identity type, one role
# assignment, default discovery mode) without needing any computed values.
run "plan_wires_identity_role_and_remediation" {
  command = plan

  module {
    source = "./modules/policy-assignment-deploy"
  }

  assert {
    condition     = azurerm_subscription_policy_assignment.this.identity[0].type == "SystemAssigned"
    error_message = "AMA assignments must use a system-assigned identity, not user-assigned"
  }

  assert {
    condition     = length(azurerm_role_assignment.this) == 1
    error_message = "Expected exactly one role assignment for a single-role definition"
  }

  assert {
    condition     = azurerm_subscription_policy_remediation.this.resource_discovery_mode == "ExistingNonCompliant"
    error_message = "Default resource_discovery_mode should be ExistingNonCompliant unless overridden"
  }

  assert {
    condition     = time_sleep.wait_for_role_propagation.create_duration == "30s"
    error_message = "Default role_propagation_wait should be 30s"
  }
}

# Full mock apply: exercises the module end-to-end, including the outputs
# that E5's Ask-Claude verification step and the root outputs.tf depend on.
run "apply_produces_usable_outputs" {
  command = apply

  module {
    source = "./modules/policy-assignment-deploy"
  }

  assert {
    condition     = output.principal_id != ""
    error_message = "principal_id output should be populated after apply"
  }

  assert {
    condition     = length(output.role_assignment_ids) == 1
    error_message = "role_assignment_ids should contain exactly one entry, keyed by role name"
  }

  assert {
    condition     = contains(keys(output.role_assignment_ids), "Virtual Machine Contributor")
    error_message = "role_assignment_ids should be keyed by role_definition_name"
  }
}

# Guardrail: a DeployIfNotExists assignment with no granted role can only
# audit, never actually deploy — the module should refuse this at plan time
# rather than silently producing a policy that can't remediate anything.
run "empty_role_list_is_rejected" {
  command = plan

  module {
    source = "./modules/policy-assignment-deploy"
  }

  variables {
    role_definition_names = []
  }

  expect_failures = [
    var.role_definition_names,
  ]
}
