terraform {
  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}
}

module "network" {
  source = "../../modules/network"

  location            = var.location
  environment         = var.environment
  resource_group_name = "rg-network-dev"

    admin_username = var.admin_username
  ssh_public_key = var.ssh_public_key
}