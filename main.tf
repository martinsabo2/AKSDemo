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
  address_space       = ["10.1.0.0/16"]  # Specify your desired address space
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}

# Define the first subnet within the VNet
resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.1.0.0/24"]  # Specify your desired subnet address range
}

# Define the second subnet within the VNet
resource "azurerm_subnet" "db" {
  name                 = "db"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.1.1.0/24"]  # Specify your desired subnet address range
  service_endpoints = ["Microsoft.Sql"]
}

# Create the Azure Kubernetes Service (AKS) cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "myAKSCluster"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  dns_prefix          = "myaksdns"  # Change to your desired DNS prefix

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2s_v3"  # Change to your desired VM size
    vnet_subnet_id = azurerm_subnet.backend.id  # Use the existing backend subnet
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    environment = "dev"
  }
}

# Create an Azure SQL Server
resource "azurerm_mssql_server" "sql-server" {
  name                         = "demo-sql-server-ms12"
  resource_group_name          = azurerm_resource_group.demo.name
  location                     = azurerm_resource_group.demo.location
  version                      = "12.0" # Choose your desired version
  administrator_login          = var.db_username
  administrator_login_password = var.db_password
  minimum_tls_version          = "1.2"
}

# Create an Azure SQL Database
resource "azurerm_mssql_database" "sql-db" {
  name           = "demo-database"
  server_id      = azurerm_mssql_server.sql-server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  sku_name       = "S0"
  zone_redundant = false
}

resource "azurerm_mssql_virtual_network_rule" "vnet-rule" {
  name      = "sql-vnet-rule"
  server_id = azurerm_mssql_server.sql-server.id
  subnet_id = azurerm_subnet.db.id
}

resource "azurerm_network_security_group" "nsg-backend" {
  name                = "backend-nsg"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  
  security_rule {
    name                       = "DenyInternetAll"
    priority                   = 1010
    direction                  = "Outbound"
    access                     = "Deny"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "Internet"
    destination_port_range     = "*"
    protocol                   = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-backend" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.nsg-backend.id
}

resource "azurerm_network_security_group" "nsg-db" {
  name                = "db-nsg"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  security_rule {
    name                       = "AllowTagMSSQLOutbound"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "Sql"
    destination_port_range     = "1433"
    protocol                   = "Tcp"   
  }

  security_rule {
    name                       = "DenyInternetAll"
    priority                   = 1010
    direction                  = "Outbound"
    access                     = "Deny"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "Internet"
    destination_port_range     = "*"
    protocol                   = "*"   
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-db" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.nsg-db.id
}
