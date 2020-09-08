module "names" {
    source                                         = "../../naming-standard"
    env                                            = var.ARM_ENVIRONMENT
    location                                       = var.ARM_LOCATION
    subId                                          = var.ARM_SUBSCRIPTION_ID
}



resource "azurerm_subnet" "subnet" {
    for_each                                       = var.subnets

    name                                           = each.value.name == "AzureFirewallSubnet" || each.value.name == "GatewaySubnet" ? each.value.name : "${module.names.standard["subnet"]}-${each.value.name}"
    resource_group_name                            = var.resource_group
    virtual_network_name                           = var.virtual_network_name
    address_prefix                                 = each.value.cidr
    service_endpoints                              = lookup(each.value, "service_endpoints", [])
    enforce_private_link_endpoint_network_policies = lookup(each.value, "enforce_private_link_endpoint_network_policies", null )
    enforce_private_link_service_network_policies  = lookup(each.value, "enforce_private_link_service_network_policies", null)

    dynamic "delegation" {
        for_each                                   = lookup(each.value, "delegation", {}) != {} ? [1] : []

        content {
            name                                   = lookup(each.value.delegation, "name", null)
            service_delegation {
                name                               = lookup(each.value.delegation.service_delegation, "name", null)
                actions                            = lookup(each.value.delegation.service_delegation, "actions", null)
            }
        }
    }
}