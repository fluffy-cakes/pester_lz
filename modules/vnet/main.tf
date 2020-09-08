module "names" {
    source                                             = "../naming-standard"
    env                                                = var.ARM_ENVIRONMENT
    location                                           = var.ARM_LOCATION
    subId                                              = var.ARM_SUBSCRIPTION_ID
}




resource "azurerm_virtual_network" "vnet" {
    name                                               = "${module.names.standard["virtual-network"]}-${var.networking_object.vnet.name}"
    location                                           = var.ARM_LOCATION
    resource_group_name                                = var.virtual_network_rg
    address_space                                      = var.networking_object.vnet.address_space
    dns_servers                                        = lookup(var.networking_object.vnet, "dns", null)
    tags                                               = var.tags

    dynamic "ddos_protection_plan" {
        for_each                                       = lookup(var.networking_object.vnet, "enable_ddos_std", false) == true ? [1] : []

        content {
            id                                         = var.networking_object.vnet.ddos_id
            enable                                     = var.networking_object.vnet.enable_ddos_std
        }
    }
}


module "subnets" {
    source                                             = "./subnet"

    ARM_ENVIRONMENT                                    = var.ARM_ENVIRONMENT
    ARM_LOCATION                                       = var.ARM_LOCATION
    ARM_SUBSCRIPTION_ID                                = var.ARM_SUBSCRIPTION_ID
    resource_group                                     = var.virtual_network_rg
    subnets                                            = var.networking_object.subnets
    tags                                               = var.tags
    virtual_network_name                               = azurerm_virtual_network.vnet.name
}


module "nsg" {
    source                                             = "./nsg"

    ARM_ENVIRONMENT                                    = var.ARM_ENVIRONMENT
    ARM_LOCATION                                       = var.ARM_LOCATION
    ARM_SUBSCRIPTION_ID                                = var.ARM_SUBSCRIPTION_ID
    resource_group                                     = var.virtual_network_rg
    subnets                                            = var.networking_object.subnets
    tags                                               = var.tags
    virtual_network_name                               = azurerm_virtual_network.vnet.name
}


resource "azurerm_subnet_network_security_group_association" "nsg_vnet_association" {
    for_each = {
        for key, value in var.networking_object.subnets:
            key => value
            if value.nsg_creation != false
    }

    subnet_id                                          = module.subnets.subnet_ids_map[each.key].id
    network_security_group_id                          = module.nsg.nsg_obj[each.key].id
}


module "traffic_analytics" {
    source                                             = "./traffic_analytics"

    ARM_ENVIRONMENT                                    = var.ARM_ENVIRONMENT
    ARM_LOCATION                                       = var.ARM_LOCATION
    ARM_SUBSCRIPTION_ID                                = var.ARM_SUBSCRIPTION_ID
    diagnostics_map                                    = var.diagnostics_map
    location                                           = var.ARM_LOCATION
    netwatcher                                         = var.netwatcher
    nsg                                                = module.nsg.nsg_obj
    nw_config                                          = lookup(var.networking_object, "netwatcher", {})
    resource_group                                     = var.virtual_network_rg
    tags                                               = var.tags
}