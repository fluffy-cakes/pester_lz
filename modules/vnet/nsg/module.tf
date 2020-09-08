module "names" {
    source                             = "../../naming-standard"
    env                                = var.ARM_ENVIRONMENT
    location                           = var.ARM_LOCATION
    subId                              = var.ARM_SUBSCRIPTION_ID
}

resource "azurerm_network_security_group" "nsg_obj" {
    for_each = {
        for key, value in var.subnets:
            key => value
            if value.nsg_creation != false
    }

    name                               = "${module.names.standard["network-security-group"]}-${each.value.name}"
    resource_group_name                = var.resource_group
    location                           = var.ARM_LOCATION
    tags                               = var.tags

    dynamic "security_rule" {
        for_each                       = concat(each.value.nsg_inbound, each.value.nsg_outbound)
        content {
            name                       = security_rule.value[0]
            description                = security_rule.value[1]
            priority                   = security_rule.value[2]
            direction                  = security_rule.value[3]
            access                     = security_rule.value[4]
            protocol                   = security_rule.value[5]
            source_port_range          = security_rule.value[6]
            destination_port_range     = security_rule.value[7]
            source_address_prefix      = security_rule.value[8]
            destination_address_prefix = security_rule.value[9]
        }
    }
}
