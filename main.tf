# Specify the Azure provider and authentication details
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "demo" {
  name     = "aksdemo-rg"
  location = "West Europe"
}

# Define the Virtual Network
resource "azurerm_virtual_network" "demo" {
  name                = "spoke1"
  address_space       = ["10.0.0.0/16"]  # Specify your desired address space
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}

# Define the first subnet within the VNet
resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.1.0/24"]  # Specify your desired subnet address range
}

# Define the second subnet within the VNet
resource "azurerm_subnet" "db" {
  name                 = "db"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.2.0/24"]  # Specify your desired subnet address range
}
