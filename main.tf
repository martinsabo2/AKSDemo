# Specify the Azure provider and authentication details
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "aksdemo-rg"
  location = "West Europe"
}