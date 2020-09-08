resource "azurerm_resource_group" "logging" {
    name                                                           = "${module.names.standard["resource-group"]}-logging"
    location                                                       = var.ARM_LOCATION
}


resource "azurerm_log_analytics_workspace" "logging" {
    name                                                           = "${module.names.standard["log-analytics-workspace"]}-test"
    location                                                       = var.ARM_LOCATION
    resource_group_name                                            = azurerm_resource_group.logging.name
    sku                                                            = "PerGB2018"
    tags                                                           = var.global_settings.tags
    retention_in_days                                              = var.logging_settings.log_analytics.retention_in_days != "" ? var.logging_settings.log_analytics.retention_in_days : null
}


resource "azurerm_log_analytics_solution" "logging" {
    for_each                                                       = var.logging_settings.log_analytics.solution_plan_map

    solution_name                                                  = each.key
    location                                                       = var.ARM_LOCATION
    resource_group_name                                            = azurerm_resource_group.logging.name
    workspace_resource_id                                          = azurerm_log_analytics_workspace.logging.id
    workspace_name                                                 = azurerm_log_analytics_workspace.logging.name

    plan {
        product                                                    = each.value.product
        publisher                                                  = each.value.publisher
    }
}


resource "azurerm_storage_account" "logging" {
    name                                                           = "${module.names.standard["storage-account"]}${var.logging_settings.diagnostics_storage_account.name}"
    resource_group_name                                            = azurerm_resource_group.logging.name
    location                                                       = azurerm_resource_group.logging.location
    tags                                                           = var.global_settings.tags

    account_kind                                                   = var.logging_settings.diagnostics_storage_account.account_kind
    account_tier                                                   = var.logging_settings.diagnostics_storage_account.account_tier
    account_replication_type                                       = var.logging_settings.diagnostics_storage_account.replication_type
    access_tier                                                    = var.logging_settings.diagnostics_storage_account.access_tier
    enable_https_traffic_only                                      = true
}


resource "azurerm_eventhub_namespace" "logging" {
    count                                                       = var.logging_settings.enable_event_hub ? 1 : 0

    name                                                        = "${module.names.standard["event-hub-namespace"]}-${var.logging_settings.logging_event_hub.namespace_name}1"
    resource_group_name                                         = azurerm_resource_group.logging.name
    location                                                    = azurerm_resource_group.logging.location
    tags                                                        = var.global_settings.tags
    sku                                                         = var.logging_settings.logging_event_hub.sku
    capacity                                                    = var.logging_settings.logging_event_hub.capacity
    auto_inflate_enabled                                        = false
    network_rulesets {
        default_action                                          = "Deny"

        virtual_network_rule                                    = [
            for subnet in var.eventhub_list: {
                subnet_id                                       = lookup(
                    local.subnet_map,
                    "${module.names.standard["subnet"]}-${subnet}",
                    null
                )
                ignore_missing_virtual_network_service_endpoint = false
            }
        ]

        ip_rule                                                 = [
            for ip in var.logging_settings.ip_rules: {
                ip_mask                                         = ip
                action                                          = "Allow"
            }
        ]
    }
}


resource "azurerm_eventhub" "logging" {
    count                                                          = var.logging_settings.enable_event_hub ? 1 : 0

    name                                                           = "${module.names.standard["event-hub"]}-${var.logging_settings.logging_event_hub.logging_event_hub_name}"
    resource_group_name                                            = azurerm_resource_group.logging.name

    namespace_name                                                 = azurerm_eventhub_namespace.logging[0].name
    partition_count                                                = var.logging_settings.logging_event_hub.logging_event_hub_partition_count
    message_retention                                              = var.logging_settings.logging_event_hub.logging_event_hub_message_retention
}


resource "azurerm_eventhub_consumer_group" "logging" {
    count                                                          = var.logging_settings.enable_event_hub ? 1 : 0

    name                                                           = "${module.names.standard["event-hub-consumer-group"]}-${var.logging_settings.logging_event_hub.elastic_logs_consumer_group_name}"
    resource_group_name                                            = azurerm_resource_group.logging.name

    namespace_name                                                 = azurerm_eventhub_namespace.logging[0].name
    eventhub_name                                                  = azurerm_eventhub.logging[0].name
}