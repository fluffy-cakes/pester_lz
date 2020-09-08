data "azurerm_client_config" "current-user" {}


resource "azurerm_resource_group" "keyvault" {
    name                            = "${module.names.standard["resource-group"]}-keyvault"
    location                        = var.ARM_LOCATION

    tags                            = var.global_settings.tags
}


resource "azurerm_key_vault" "keyvault" {
    name                            = "${module.names.standard["key-vault"]}-ss"
    enabled_for_deployment          = true
    enabled_for_template_deployment = true
    location                        = azurerm_resource_group.keyvault.location
    resource_group_name             = azurerm_resource_group.keyvault.name
    sku_name                        = "standard"
    tenant_id                       = var.ARM_TENANT_ID

    access_policy {
        object_id                   = data.azurerm_client_config.current-user.object_id
        tenant_id                   = data.azurerm_client_config.current-user.tenant_id

        secret_permissions          = [
            "backup",
            "delete",
            "get",
            "list",
            "purge",
            "recover",
            "restore",
            "set"
            ]
    }

    lifecycle {
        ignore_changes              = [
            access_policy
        ]
    }

    tags                            = var.global_settings.tags
}