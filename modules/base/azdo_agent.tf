resource "azurerm_resource_group" "azdo" {
    name                              = "${module.names.standard["resource-group"]}-azdo"
    location                          = var.ARM_LOCATION

    tags                              = var.global_settings.tags
}


resource "azurerm_network_interface" "azdo" {
    count                             = var.azdo_agent_count
    name                              = "${module.names.standard["virtual-machine"]}-${lower(var.azdo_hostname)}-${format("%02d",count.index)}-nic-01"
    location                          = azurerm_resource_group.azdo.location
    resource_group_name               = azurerm_resource_group.azdo.name
    enable_ip_forwarding              = false

    ip_configuration {
        name                          = "${module.names.standard["virtual-machine"]}-${lower(var.azdo_hostname)}-${format("%02d",count.index)}-ipconfig"
        subnet_id                     = lookup(
            local.subnet_map,
            "${module.names.standard["subnet"]}-test3",
            null
        )
        private_ip_address_allocation = "Dynamic"
        primary                       = true
    }

    tags                              = var.global_settings.tags
}


resource "azurerm_storage_account" "azdo" {
    name                              = "${module.names.standard["storage-account"]}azdo"
    resource_group_name               = azurerm_resource_group.azdo.name
    location                          = azurerm_resource_group.azdo.location
    account_tier                      = "standard"
    account_replication_type          = "GRS"
    enable_https_traffic_only         = true

    tags                              = var.global_settings.tags
}


resource "random_password" "azdo" {
    length                            = 16
    special                           = true
    override_special                  = "!@#$%*()-_+[]{}<>?"
}


resource "azurerm_key_vault_secret" "azdo" {
    name                              = "AZDOAGENT"
    value                             = random_password.azdo.result
    key_vault_id                      = azurerm_key_vault.keyvault.id
}


data "template_file" "azdo" {
    template                          = file("${path.module}/scripts/azdo.sh")
    vars                              = {
        azdo_agent_pool               = var.azdo_agent_pool
        azdo_organisation_name        = var.azdo_organisation_name
        azdo_pat                      = var.azdo_pat
    }
}


resource "azurerm_linux_virtual_machine" "azdo" {
    name                              = "${module.names.standard["virtual-machine"]}-${lower(var.azdo_hostname)}-${format("%02d",count.index)}"
    location                          = azurerm_resource_group.azdo.location
    resource_group_name               = azurerm_resource_group.azdo.name
    admin_password                    = random_password.azdo.result
    admin_username                    = "azdo"
    count                             = var.azdo_agent_count
    custom_data                       = base64encode(data.template_file.azdo.rendered)
    disable_password_authentication   = false
    size                              = "Standard_B2ms"

    boot_diagnostics {
        storage_account_uri           = azurerm_storage_account.azdo.primary_blob_endpoint
    }

    network_interface_ids             = [
        "${element(azurerm_network_interface.azdo.*.id, count.index)}"
    ]

    os_disk {
        caching                       = "ReadWrite"
        storage_account_type          = "StandardSSD_LRS"
    }

    source_image_reference {
        publisher                     = "Canonical"
        offer                         = "UbuntuServer"
        sku                           = "18.04-LTS"
        version                       = "latest"
    }

    tags                              = var.global_settings.tags
}