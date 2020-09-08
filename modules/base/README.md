# landing_zone

Output Examples

```json
diagnostics_map               = {
  "storage_account_id"        = "/subscriptions/my-super-secret-subscription-id/resourceGroups/rg-dev-uks-3c78b8-logging/providers/Microsoft.Storage/storageAccounts/stdevuks78b8diaglogs"
  "workspace_id"              = "1bdb6ac7-asdf-asdf-asdf-6582e8b2677f"
  "workspace_resource_id"     = "/subscriptions/my-super-secret-subscription-id/resourcegroups/rg-dev-uks-3c78b8-logging/providers/microsoft.operationalinsights/workspaces/log-dev-uks-3c78b8-test"
}
subnet_map                    = {
  "sn-dev-uks-3c78b8-test1"   = "/subscriptions/my-super-secret-subscription-id/resourceGroups/rg-dev-uks-3c78b8-vnet-transit/providers/Microsoft.Network/virtualNetworks/vnet-dev-uks-3c78b8-vnet1/subnets/sn-dev-uks-3c78b8-test1"
  "sn-dev-uks-3c78b8-test2"   = "/subscriptions/my-super-secret-subscription-id/resourceGroups/rg-dev-uks-3c78b8-vnet-transit/providers/Microsoft.Network/virtualNetworks/vnet-dev-uks-3c78b8-vnet1/subnets/sn-dev-uks-3c78b8-test2"
  "sn-dev-uks-3c78b8-test3"   = "/subscriptions/my-super-secret-subscription-id/resourceGroups/rg-dev-uks-3c78b8-vnet-shared/providers/Microsoft.Network/virtualNetworks/vnet-dev-uks-3c78b8-vnet2/subnets/sn-dev-uks-3c78b8-test3"
}
subnet_routes                 = [
  {
    "name"                    = "test1"
    "route"                   = "Route1"
  },
  {
    "name"                    = "test2"
    "route"                   = "Route2"
  },
]
subnets_list                  = {
  "shared"                    = {
    "sn-dev-uks-3c78b8-test3" = "/subscriptions/my-super-secret-subscription-id/resourceGroups/rg-dev-uks-3c78b8-vnet-shared/providers/Microsoft.Network/virtualNetworks/vnet-dev-uks-3c78b8-vnet2/subnets/sn-dev-uks-3c78b8-test3"
  }
  "transit"                   = {
    "sn-dev-uks-3c78b8-test1" = "/subscriptions/my-super-secret-subscription-id/resourceGroups/rg-dev-uks-3c78b8-vnet-transit/providers/Microsoft.Network/virtualNetworks/vnet-dev-uks-3c78b8-vnet1/subnets/sn-dev-uks-3c78b8-test1"
    "sn-dev-uks-3c78b8-test2" = "/subscriptions/my-super-secret-subscription-id/resourceGroups/rg-dev-uks-3c78b8-vnet-transit/providers/Microsoft.Network/virtualNetworks/vnet-dev-uks-3c78b8-vnet1/subnets/sn-dev-uks-3c78b8-test2"
  }
}
```

