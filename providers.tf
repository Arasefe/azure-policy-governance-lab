provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "time" {}

data "azurerm_subscription" "cavalry_prod" {}
