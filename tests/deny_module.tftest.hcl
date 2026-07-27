# Unit tests for modules/policy-assignment-deny, run in isolation from the
# root config via `module { source = ... }`. Everything here uses a mocked
# azurerm provider — no real Azure credentials, network calls, or resources
# are involved, so `terraform test` is safe to run offline/in CI.

mock_provider "azurerm" {}

variables {
  name                 = "deny-storage-public-access"
  display_name         = "Deny public storage accounts"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b2982f36-99f2-4db5-8eff-283140c09693"
  subscription_id      = "/subscriptions/00000000-0000-0000-0000-000000000000"
}

# E2-shaped case: an explicit effect plus no extra parameters.
run "effect_only_renders_effect_key" {
  command = plan

  module {
    source = "./modules/policy-assignment-deny"
  }

  variables {
    effect           = "Deny"
    extra_parameters = {}
  }

  assert {
    condition     = output.parameters.effect.value == "Deny"
    error_message = "effect=Deny should render as parameters.effect.value == \"Deny\""
  }

  assert {
    condition     = length(keys(output.parameters)) == 1
    error_message = "With no extra_parameters, effect should be the only rendered key"
  }
}

# E1-shaped case: effect plus a definition-specific parameter merged in.
run "effect_merges_with_extra_parameters" {
  command = plan

  module {
    source = "./modules/policy-assignment-deny"
  }

  variables {
    effect = "Deny"
    extra_parameters = {
      listOfAllowedLocations = { value = ["eastus"] }
    }
  }

  assert {
    condition     = output.parameters.effect.value == "Deny"
    error_message = "effect should still be set alongside extra_parameters"
  }

  assert {
    condition     = output.parameters.listOfAllowedLocations.value == ["eastus"]
    error_message = "extra_parameters entries should pass through unchanged"
  }
}

# E3-shaped case: this is the one that was wrong in the original HTML lab —
# a definition with NO Effect parameter must not have an effect key at all.
run "null_effect_omits_effect_key" {
  command = plan

  module {
    source = "./modules/policy-assignment-deny"
  }

  variables {
    effect = null
    extra_parameters = {
      listOfAllowedSKUs = { value = ["Standard_B1s", "Standard_B2s"] }
    }
  }

  assert {
    condition     = !contains(keys(output.parameters), "effect")
    error_message = "effect = null must omit the effect key entirely, not send an empty/invalid value"
  }

  assert {
    condition     = output.parameters.listOfAllowedSKUs.value == ["Standard_B1s", "Standard_B2s"]
    error_message = "listOfAllowedSKUs should still render correctly with no effect present"
  }
}

# Guardrail: an effect value outside the three real Azure Policy effects
# should never reach the provider — the module's own validation block should
# catch it at plan time.
run "invalid_effect_value_is_rejected" {
  command = plan

  module {
    source = "./modules/policy-assignment-deny"
  }

  variables {
    effect           = "Remediate" # not a real effect — Deny/Audit/Disabled only
    extra_parameters = {}
  }

  expect_failures = [
    var.effect,
  ]
}
