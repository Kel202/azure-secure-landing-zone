resource "azurerm_resource_group" "network_rg" {
  name     = var.resource_group_name
  location = var.location
}

#Hub VNet
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "hub-vnet-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
  address_space       = ["10.0.0.0/16"]
}

#Hub Subnets
resource "azurerm_subnet" "jump_subnet" {
  name                 = "JumpSubnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.0.0/26"]
}


#Spoke VNET
resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "spoke-vnet-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
  address_space       = ["10.1.0.0/16"]
}

#Spoke Subnets
resource "azurerm_subnet" "app_subnet" {
  name                 = "AppSubnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "DbSubnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["10.1.2.0/24"]
}

#VNet Peering
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-spoke"
  resource_group_name       = azurerm_resource_group.network_rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_vnet.id
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-to-hub"
  resource_group_name       = azurerm_resource_group.network_rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
}


#Jump Subnet NSG
resource "azurerm_network_security_group" "jump_nsg" {
  name                = "jump-nsg-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
}

#App Subnet NSG
resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
}

#DB Subnet NSG
resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-nsg-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
}

#Security rules
#Allow SSh to Jump VM
resource "azurerm_network_security_rule" "allow_ssh_jump" {
  name                        = "Allow-SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"

  resource_group_name         = azurerm_resource_group.network_rg.name
  network_security_group_name = azurerm_network_security_group.jump_nsg.name
}

#Allow App Subnet Access from Jumpstart
resource "azurerm_network_security_rule" "allow_jump_to_app" {
  name                        = "Allow-Jump-To-App"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "10.0.1.0/24"
  destination_address_prefix  = "*"

  resource_group_name         = azurerm_resource_group.network_rg.name
  network_security_group_name = azurerm_network_security_group.app_nsg.name
}

#Allow inbound traffic from App subnet to SQL Server on port 1433
resource "azurerm_network_security_rule" "allow_app_to_db" {
  name                        = "Allow-App-To-DB"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "10.1.1.0/24"
  destination_address_prefix  = "*"

  resource_group_name         = azurerm_resource_group.network_rg.name
  network_security_group_name = azurerm_network_security_group.db_nsg.name
}

#Attaching the NSGs to their subnets
resource "azurerm_subnet_network_security_group_association" "jump_assoc" {
  subnet_id                 = azurerm_subnet.jump_subnet.id
  network_security_group_id = azurerm_network_security_group.jump_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "app_assoc" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "db_assoc" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

#log analytics workplace for storing all logs
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-security-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

#Enabling diagnostics for NSGs
resource "azurerm_monitor_diagnostic_setting" "jump_nsg_logs" {
  name                       = "jump-nsg-diagnostics"
  target_resource_id         = azurerm_network_security_group.jump_nsg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "app_nsg_logs" {
  name                       = "app-nsg-diagnostics"
  target_resource_id         = azurerm_network_security_group.app_nsg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "db_nsg_logs" {
  name                       = "db-nsg-diagnostics"
  target_resource_id         = azurerm_network_security_group.db_nsg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_public_ip" "jump_public_ip" {
  name                = "jump-pip-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

#Network interface for jump VM
resource "azurerm_network_interface" "jump_nic" {
  name                = "jump-nic-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jump_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jump_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "jump_vm" {
  name                = "jump-vm-${var.environment}"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.jump_nic.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}


resource "azurerm_network_interface" "app_nic" {
  name                = "app-nic-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "app-vm-${var.environment}"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.app_nic.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

