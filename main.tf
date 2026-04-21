terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.65.0"

    }
  }
}
provider "azurerm" {
  features {

  }
  subscription_id = "7e279a1f-92f9-40ed-af16-0d4119fce195"
}
resource "azurerm_resource_group" "prodrg" {
  name     = "prod_rg"
  location = "japaneast"
}

resource "azurerm_virtual_network" "prodvn" {
  name                = "prod_vn"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.prodrg.location
  resource_group_name = azurerm_resource_group.prodrg.name
}

resource "azurerm_subnet" "prodsn" {
  name                 = "prod_sn"
  resource_group_name  = azurerm_resource_group.prodrg.name
  virtual_network_name = azurerm_virtual_network.prodvn.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_network_interface" "prodni" {
  name                = "prod_ni"
  resource_group_name = azurerm_resource_group.prodrg.name
  location            = azurerm_resource_group.prodrg.location

  depends_on = [
    azurerm_subnet.prodsn
  ]

  ip_configuration {
    name                          = "prod_ipconfig"
    subnet_id                     = azurerm_subnet.prodsn.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_security_group" "prodnsg" {
  name                = "prod_nsg"
  resource_group_name = azurerm_resource_group.prodrg.name
  location            = azurerm_resource_group.prodrg.location
}
resource "azurerm_public_ip" "prodpi" {
  name                = "prod_pi"
  resource_group_name = azurerm_resource_group.prodrg.name
  location            = azurerm_resource_group.prodrg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_linux_virtual_machine" "prodvm" {
  name                            = "prodvm"
  resource_group_name             = azurerm_resource_group.prodrg.name
  location                        = azurerm_resource_group.prodrg.location
  size                            = "Basic"
  admin_username                  = "myvm"
  admin_password                  = "Dockervm@123"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.prodni.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
data "azurerm_network_interface" "prodni_data" {
  name                = azurerm_network_interface.prodni.name
  resource_group_name = azurerm_resource_group.prodrg.name
}
