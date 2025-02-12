provider "azurerm" {
  features {}
  subscription_id = "3b471ebb-ad2d-4a9e-b525-0567fab0e51f"
}

# Generate a random string to append to resource names
resource "random_string" "suffix" {
  length  = 8  
  special = false
  upper   = false
}

# Generate a secure random password for PostgreSQL
resource "random_password" "db_password" {
  length  = 16
  special = true
  upper   = true
  numeric = true
}

resource "azurerm_resource_group" "rg" {
  name     = "kaicyber-rg-${random_string.suffix.result}"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "kaicyber-vnet-${random_string.suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "public" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "kaicyber-nsg-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "public_nsg_assoc" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "kaicyber-aks-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "kaicyber-aks-${random_string.suffix.result}"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.private.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    service_cidr       = "10.2.0.0/16"   
    dns_service_ip     = "10.2.0.10"     
  }
}

resource "azurerm_postgresql_server" "db" {
  name                = "kaicyber-db-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = "adminuser"
  administrator_login_password = random_password.db_password.result  # <-- FIXED

  version                 = "11"
  ssl_enforcement_enabled = true
}

resource "azurerm_storage_account" "storage" {
  name                     = "kaicyberstorage${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
