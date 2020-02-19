provider "azurerm" {
    version = "~>1.44.0"
}

# Create a resource group
resource "azurerm_resource_group" "production" {
  name     = "production"
  location = "eastus"
}

resource "azurerm_virtual_network" "production_network" {
  name                = "production-network"
  resource_group_name = azurerm_resource_group.production.name
  location            = azurerm_resource_group.production.location
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "netbox-subnet"
  resource_group_name  = azurerm_resource_group.production.name
  virtual_network_name = azurerm_virtual_network.production_network.name
  address_prefix       = "10.255.255.0/24"
}

resource "azurerm_public_ip" "production_publicip" {
    name                         = "netbox-publicIP"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.production.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Netbox"
    }
}

resource "azurerm_network_security_group" "production_nsg" {
    name                = "productionGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.production.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Netbox"
    }
}

resource "azurerm_network_interface" "production_netbox_nic" {
    name                        = "netboxNIC"
    location                    = "eastus"
    resource_group_name         = azurerm_resource_group.production.name
    network_security_group_id   = azurerm_network_security_group.production_nsg.id

    ip_configuration {
        name                          = "netbox_NIC_config"
        subnet_id                     = azurerm_subnet.subnet1.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.production_publicip.id
    }

    tags = {
        environment = "Netbox"
    }
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.production.name
    }
    
    byte_length = 8
}

resource "azurerm_storage_account" "production_netbox_storageAccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.production.name
    location                    = "eastus"
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        environment = "Netbox"
    }
}

resource "azurerm_virtual_machine" "netboxvm" {
    name                  = "netboxVM"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.production.name
    network_interface_ids = [azurerm_network_interface.production_netbox_nic.id]
    vm_size               = "Standard_B1ms"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "netbox"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzsZRo51FOFtcr8/ZWP8B5/970tzAeHZNuHhtqFjdFgWqpwOfh8bWzjNh9Lp/0O4kHfgl5e/BOkBc6HnzUasR8vGE8ki+g24NjRCNAXTBU12wJx7OFzX1C0a45Lm6MzhkG0N6Pe3Vlp9jk0ntxzpRgI+kDoZDk7BTq0jI/nN5eXg9v6a+jy1z2SKqnXILFIQf0WYtHAOJIdyh16lCDlA37fhQ1l5Qls7JxKz2KtcG38ecS4b5H3Q4Zhp1YY/T19sSLSVyBOz0GJIXN/4YHK0q6VYBImrKk/xFUYdO/0QjU0VvkdvUdDZkrKLn2TYBXI52Ffa/43rMBecGotm3CboDh "
        }
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = azurerm_storage_account.production_netbox_storageAccount.primary_blob_endpoint
    }

    tags = {
        environment = "Netbox"
    }
}

data "azurerm_public_ip" "netbox_public_ip" {
  name                = azurerm_public_ip.production_publicip.name
  resource_group_name = azurerm_virtual_machine.netboxvm.resource_group_name
}

output "public_ip_address" {
  value = data.azurerm_public_ip.netbox_public_ip.ip_address
}