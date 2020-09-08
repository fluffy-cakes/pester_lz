resource "azurerm_resource_group" "vnet" {
    for_each                                  = var.vnet_list

    name                                      = "${module.names.standard["resource-group"]}-vnet-${each.value.vnet.resource_group_name}"
    location                                  = var.ARM_LOCATION
}


locals {
    diagnostics_map                           = {
        workspace_id                          = azurerm_log_analytics_workspace.logging.workspace_id
        workspace_resource_id                 = azurerm_log_analytics_workspace.logging.id
        storage_account_id                    = azurerm_storage_account.logging.id
    }
}


output diagnostics_map {
    value                                     = local.diagnostics_map
}


module "vnets" {
    source                                    = "../vnet"
    for_each                                  = var.vnet_list

    ARM_ENVIRONMENT                           = var.ARM_ENVIRONMENT
    ARM_LOCATION                              = var.ARM_LOCATION
    ARM_SUBSCRIPTION_ID                       = var.ARM_SUBSCRIPTION_ID
    diagnostics_map                           = local.diagnostics_map
    netwatcher                                = each.value.netwatcher
    networking_object                         = each.value
    tags                                      = var.global_settings.tags
    virtual_network_rg                        = azurerm_resource_group.vnet[each.key].name
}


locals {
    subnet_list                               = {
        for key, value in module.vnets:
            key => value.vnet_subnets
    }
    subnet_map                                = merge(values(local.subnet_list)...)

    subnet_routes                             = flatten(
        [
            for key, vnet in var.vnet_list: [
                for key, value in vnet.subnets: {
                    name                      = value.name
                    route                     = value.route
                }
                if value.route != null
            ]
        ]
    )
}


output subnets_list {
    value                                     = local.subnet_list
}


output subnet_map {
    value                                     = local.subnet_map
}


output subnet_routes {
    value                                     = local.subnet_routes
}


resource "azurerm_route_table" "vnet" {
    for_each                                  = var.route_tables

    name                                      = "${module.names.standard["route-table"]}-${each.value.name}"
    location                                  = var.ARM_LOCATION
    resource_group_name                       = azurerm_resource_group.vnet[each.value.resource_group].name
    disable_bgp_route_propagation             = each.value.disable_bgp_route_propagation

    dynamic "route" {
        for_each                              = each.value.route_entries
        content {
            name                              = route.value.name
            address_prefix                    = route.value.prefix
            next_hop_type                     = route.value.next_hop_type
            next_hop_in_ip_address            = contains(
                keys(route.value),
                "next_hop_in_ip_address"
            ) ? route.value.next_hop_in_ip_address: null
        }
    }
}


resource "azurerm_subnet_route_table_association" "route_tables_association" {
    for_each                                  = {
        for subnet in local.subnet_routes:
            "${subnet.name}" => subnet.route
    }

    subnet_id                                 = lookup(
        local.subnet_map,
        "${module.names.standard["subnet"]}-${each.key}",
        null
    )
    route_table_id                            = azurerm_route_table.vnet[each.value].id
}