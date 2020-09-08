module "names" {
    source                                         = "../../naming-standard"
    env                                            = var.ARM_ENVIRONMENT
    location                                       = var.ARM_LOCATION
    subId                                          = var.ARM_SUBSCRIPTION_ID
}




locals {
    checkifconfigpresent      = lookup(var.nw_config, "create", {}) != {} ? true : false
    checkifcreateconfig       = lookup(var.nw_config, "create", {}) != {} ? var.nw_config.create : false
    nsg                       = local.checkifconfigpresent == true ? var.nsg : {}
}

resource "azurerm_network_watcher" "netwatcher" {
    count                     = local.checkifcreateconfig && local.checkifconfigpresent ? 1 : 0

    name                      = var.nw_config.name
    location                  = var.location
    resource_group_name       = var.resource_group
    tags                      = var.tags
}

resource "azurerm_network_watcher_flow_log" "nw_flow" {
    for_each                  = local.nsg

# if we havent created the azurerm_network_watcher.netwatcher
# then we take the value given (optional)
    network_watcher_name      = local.checkifcreateconfig ? azurerm_network_watcher.netwatcher[0].name : var.netwatcher.name
    resource_group_name       = local.checkifcreateconfig ? var.resource_group : "${module.names.standard["resource-group"]}-vnet-${var.netwatcher.rg}"

    network_security_group_id = each.value.id
    storage_account_id        = var.diagnostics_map.storage_account_id
    enabled                   = lookup(var.nw_config, "flow_logs_settings", {}) != {} ? var.nw_config.flow_logs_settings.enabled : false

    retention_policy {
        enabled               = lookup(var.nw_config, "flow_logs_settings", {}) != {} ? var.nw_config.flow_logs_settings.retention : false
        days                  = lookup(var.nw_config, "flow_logs_settings", {}) != {} ? var.nw_config.flow_logs_settings.period : 7
    }

    traffic_analytics {
        enabled               = lookup(var.nw_config, "traffic_analytics_settings", {}) != {} ? var.nw_config.traffic_analytics_settings.enabled : false
        workspace_id          = var.diagnostics_map.workspace_id
        workspace_region      = var.location
        workspace_resource_id = var.diagnostics_map.workspace_resource_id
    }
}