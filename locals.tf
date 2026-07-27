locals {
  # ------------------------------------------------------------------
  # Deny/fixed-effect assignments (lab exercises E1, E2, E3, E4, E6).
  # Each entry drives one instance of modules/policy-assignment-deny.
  # effect = null is deliberate for allowed_vm_skus — that definition has
  # no Effect parameter at all (see the HTML lab's E3 note); passing null
  # tells the module to omit the key rather than send an invalid value.
  # ------------------------------------------------------------------
  deny_effect_policies = {
    allowed_locations = {
      name                 = "deny-non-eastus-regions"
      display_name         = "Deny non-eastus deployments"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
      effect               = "Deny"
      extra_parameters = {
        listOfAllowedLocations = { value = [var.approved_location] }
      }
    }

    storage_no_public_access = {
      name                 = "deny-storage-public-access"
      display_name         = "Deny public storage accounts"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b2982f36-99f2-4db5-8eff-283140c09693"
      effect               = "Deny"
      extra_parameters     = {}
    }

    allowed_vm_skus = {
      name                 = "deny-oversized-vm-skus"
      display_name         = "Deny non-approved VM size SKUs"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cccc23c7-8427-4f53-ad12-b6a63eb452b3"
      effect               = null
      extra_parameters = {
        listOfAllowedSKUs = { value = var.approved_vm_skus }
      }
    }

    disks_no_public_access = {
      name                 = "deny-disk-public-access"
      display_name         = "Deny public managed disks"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/8405fdab-1faf-48aa-b702-999c9c172094"
      effect               = "Deny"
      extra_parameters     = {}
    }

    appservice_https_only = {
      name                 = "deny-appservice-http"
      display_name         = "Deny unencrypted App Service traffic"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a4af4a39-4135-47fb-b175-47fbdf85311d"
      effect               = "Deny"
      extra_parameters     = {}
    }
  }

  # ------------------------------------------------------------------
  # DeployIfNotExists assignments (lab exercise E5 — Windows + Linux AMA).
  # Both definitions already default Effect to DeployIfNotExists, so there's
  # no effect override here; what they need instead is an identity, a role
  # grant, and a remediation task, which modules/policy-assignment-deploy
  # wires up as one unit.
  # ------------------------------------------------------------------
  deploy_effect_policies = {
    ama_windows = {
      name                  = "deploy-ama-windows"
      display_name          = "Auto-deploy AMA on Windows VMs"
      policy_definition_id  = "/providers/Microsoft.Authorization/policyDefinitions/ca817e41-e85a-4783-bc7f-dc532d36235e"
      role_definition_names = ["Virtual Machine Contributor"]
      remediation_name      = "remediate-ama-windows"
    }

    ama_linux = {
      name                  = "deploy-ama-linux"
      display_name          = "Auto-deploy AMA on Linux VMs"
      policy_definition_id  = "/providers/Microsoft.Authorization/policyDefinitions/a4034bc6-ae50-406d-bf76-50f4ee5a7811"
      role_definition_names = ["Virtual Machine Contributor"]
      remediation_name      = "remediate-ama-linux"
    }
  }
}
