terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.2"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }

  # Remote state is intentionally NOT configured here. This lab project is meant
  # to be planned/applied ad hoc against a training subscription, and a remote
  # backend requires a real Storage Account + container to already exist. If you
  # promote this to a team-owned project, uncomment and point it at one:
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "sttfstatecavalry77"
  #   container_name       = "policy-governance-lab"
  #   key                  = "terraform.tfstate"
  # }
}
