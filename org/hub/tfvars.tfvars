global_settings                                                = {
    tags                                                       = {
        application_id                                         = "myApp"
        business_owner                                         = "theDude"
        project_code                                           = "fluffy"
    }
}

vnet_list                                                      = {
    transit                                                    = {
        vnet                                                   = {
            name                                               = "vnet1"
            address_space                                      = ["10.0.1.0/24"]
            # dns                                              = []
            enable_ddos_std                                    = false
            ddos_id                                            = "placeholder"
            resource_group_name                                = "transit"
        }
        subnets                                                = {
            test1                                              = {
                name                                           = "test1"
                cidr                                           = "10.0.1.0/25"
                enforce_private_link_endpoint_network_policies = false
                enforce_private_link_service_network_policies  = false
                nsg_creation                                   = true
                nsg_inbound                                    = [
                    # {"Name", "Description", "Priority", "Direction", "Action", "Protocol", "source_port_range", "destination_port_range", "source_address_prefix", "destination_address_prefix" }
                ]
                nsg_outbound                                   = []
                route                                          = "Route1"
                service_endpoints                              = []
            }
            test2                                              = {
                name                                           = "test2"
                cidr                                           = "10.0.1.128/25"
                enforce_private_link_endpoint_network_policies = false
                enforce_private_link_service_network_policies  = false
                nsg_creation                                   = true
                nsg_inbound                                    = [
                    # {"Name", "Description", "Priority", "Direction", "Action", "Protocol", "source_port_range", "destination_port_range", "source_address_prefix", "destination_address_prefix" }
                ]
                nsg_outbound                                   = []
                route                                          = "Route2"
                service_endpoints                              = ["Microsoft.EventHub"]
            }
        }
        netwatcher                                             = {
            # create the network watcher for a subscription and for the location of the vnet
            create                                             = true
            # name of the network watcher to be created
            name                                               = "NetworkWatcher"
            rg                                                 = null
            flow_logs_settings                                 = {
                enabled                                        = true
                period                                         = 7
                retention                                      = true
            }
            # enabling this sends to Log Analytics
            traffic_analytics_settings                         = {
                enabled                                        = true
            }
        }
    }
    shared                                                     = {
        vnet                                                   = {
            name                                               = "vnet2"
            address_space                                      = ["10.0.2.0/24"]
            # dns                                              = []
            enable_ddos_std                                    = false
            ddos_id                                            = "placeholder"
            resource_group_name                                = "shared"
        }
        subnets                                                = {
            test3                                              = {
                name                                           = "test3"
                cidr                                           = "10.0.2.0/24"
                enforce_private_link_endpoint_network_policies = false
                enforce_private_link_service_network_policies  = false
                nsg_creation                                   = true
                nsg_inbound                                    = [
                    # {"Name", "Description", "Priority", "Direction", "Action", "Protocol", "source_port_range", "destination_port_range", "source_address_prefix", "destination_address_prefix" }
                ]
                nsg_outbound                                   = []
                route                                          = null
                service_endpoints                              = ["Microsoft.EventHub"]
            }
        }
        netwatcher                                             = {
            # create the network watcher for a subscription and for the location of the vnet
            create                                             = false
            # name of the network watcher to be created
            name                                               = "NetworkWatcher"
            rg                                                 = "transit"
            flow_logs_settings                                 = {
                enabled                                        = true
                period                                         = 7
                retention                                      = true
            }
            # enabling this sends to Log Analytics
            traffic_analytics_settings                         = {
                enabled                                        = true
            }
        }
    }
}

route_tables                                                   = {
    Route1                                                     = {
        name                                                   = "test1"
        disable_bgp_route_propagation                          = true
        resource_group                                         = "transit"
        route_entries                                          = {
            rt-default                                         = {
                name                                           = "rt-default"
                prefix                                         = "0.0.0.0/0"
                next_hop_type                                  = "Internet"
            },
            r1                                                 = {
                name                                           = "rt-rfc-10-8"
                prefix                                         = "192.168.0.0/24"
                next_hop_type                                  = "VirtualAppliance"
                next_hop_in_ip_address                         = "10.1.1.1"
            }
        }
    }

    Route2                                                     = {
        name                                                   = "test2"
        disable_bgp_route_propagation                          = true
        resource_group                                         = "shared"
        route_entries                                          = {
            rt-default                                         = {
                name                                           = "rt-default"
                prefix                                         = "0.0.0.0/0"
                next_hop_type                                  = "Internet"
            },
            r1                                                 = {
                name                                           = "rt-rfc-10-8"
                prefix                                         = "192.168.0.0/24"
                next_hop_type                                  = "VirtualAppliance"
                next_hop_in_ip_address                         = "10.1.1.1"
            }
        }
    }
}

# list of subnets that are allowed to access event hub
eventhub_list                                                  = [
    "test3"
]

logging_settings                                               = {
    activity_logs                                              = {
        name                                                   = "default"
        categories                                             = ["Action", "Write", "Delete"]
        locations                                              = ["uksouth", "ukwest", "global"]
        retention_policy                                       = {
            enabled                                            = true
            days                                               = 30
        }
    }
    enable_event_hub                                           = true
    diagnostics_storage_account                                = {
        name                                                   = "diaglogs"
        account_kind                                           = "StorageV2"
        account_tier                                           = "Standard"
        replication_type                                       = "GRS"
        access_tier                                            = "Hot"
    }
    log_analytics                                              = {
        workspace_name                                         = "diag"
        retention_in_days                                      = "30"
        solution_plan_map                                      = {
            NetworkMonitoring                                  = {
                "publisher"                                    = "Microsoft"
                "product"                                      = "OMSGallery/NetworkMonitoring"
            },
            ADAssessment                                       = {
                "publisher"                                    = "Microsoft"
                "product"                                      = "OMSGallery/ADAssessment"
            },
            ADReplication                                      = {
                "publisher"                                    = "Microsoft"
                "product"                                      = "OMSGallery/ADReplication"
            },
            AgentHealthAssessment                              = {
                "publisher"                                    = "Microsoft"
                "product"                                      = "OMSGallery/AgentHealthAssessment"
            },
            DnsAnalytics                                       = {
                "publisher"                                    = "Microsoft"
                "product"                                      = "OMSGallery/DnsAnalytics"
            },
            ContainerInsights                                  = {
                "publisher"                                    = "Microsoft"
                "product"                                      = "OMSGallery/ContainerInsights"
            },
            KeyVaultAnalytics                                  = {
                "publisher"                                    = "Microsoft"
                "product"                                      = "OMSGallery/KeyVaultAnalytics"
            }
        }
    }
    logging_event_hub                                          = {
        logging_event_hub_name                                 = "test"
        activity_log_event_hub_name                            = "insights-operational-logs"
        namespace_name                                         = "test"
        sku                                                    = "Standard"
        capacity                                               = 2
        logging_event_hub_partition_count                      = 2
        logging_event_hub_message_retention                    = 7
        activity_log_event_hub_partition_count                 = 2
        activity_log_event_hub_message_retention               = 7

        elastic_logs_consumer_group_name                       = "logs-elastic"
        elastic_activity_consumer_group_name                   = "activity-elastic"
    }

    ip_rules                                                   = {
        test1                                                  = "1.1.1.1"
        test2                                                  = "1.1.1.1"
    }
}