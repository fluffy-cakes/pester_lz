function namingStd {

    param (
        [string]$environment,
        [string]$location,
        [string]$reference,
        [string]$subscription
    )

    $env                              = $environment.ToLower()
    $locationLower                    = $location.ToLower()
    $subId                            = $subscription.Substring(30)
    $subId24                          = $subscription.Substring(24)
    $subId32                          = $subscription.Substring(32)


    $locationMap                      = @{
        'uk south'                    = 'uks'
        'uk west'                     = 'ukw'
        'uksouth'                     = 'uks'
        'ukwest'                      = 'ukw'
    }

    $locationOut                      = $locationMap.$locationLower


    $output                           = @{
        "afw_rule"                    = "afwrule-$env-$locationOut-$subId"
        "afw_rule_collection"         = "afwrulecol-$env-$locationOut-$subId"
        "automation-account"          = "auto-$env-$locationOut-$subId"
        "availability-set"            = "avs-$env-$locationOut-$subId"
        "azure-firewall"              = "azfw-$env-$locationOut-$subId"
        "backend-pool"                = "bep-$env-$locationOut-$subId"
        "connection"                  = "con-$env-$locationOut-$subId"
        "ddos-protection-plan"        = "ddos-$env-$locationOut-$subId"
        "event-hub"                   = "evh-$env-$locationOut-$subId"
        "event-hub-consumer-group"    = "evcg-$env-$locationOut-$subId"
        "event-hub-namespace"         = "evn-$env-$locationOut-$subId"
        "eventhub_authorization_rule" = "ehar-$env-$locationOut-$subId"
        "external-load-balancer"      = "elb-$env-$locationOut-$subId"
        "function-app"                = "fnapp-$env-$locationOut-$subId"
        "internal-load-balancer"      = "ilb-$env-$locationOut-$subId"
        "ip-config"                   = "ipcfg-$env-$locationOut-$subId"
        "key-vault"                   = "kv-$env-$locationOut-$subId"
        "local-network-gateway"       = "lng-$env-$locationOut-$subId"
        "log-analytics-workspace"     = "log-$env-$locationOut-$subId"
        "network-interface"           = "$env-$locationOut-$subId"
        "network-security-group"      = "nsg-$env-$locationOut-$subId"
        "public-ip-address"           = "pip-$env-$locationOut-$subId"
        "public-ip-dns"               = "$env$locationOut$subId"
        "resource-group"              = "rg-$env-$locationOut-$subId"
        "route-table"                 = "rt-$env-$locationOut-$subId"
        "sql-database"                = "sqldb$env$locationOut$subId"
        "sql-server"                  = "sql$env$locationOut$subId"
        "standard-output"             = "$env-$locationOut-$subId"
        "storage-account"             = "st$env$locationOut$subId32 " # only alpha numerics allowed in storage accounts
        "storage-account-provisioner" = "st$env$locationOut$subId24 " # only alpha numerics allowed in storage accounts
        "storage-alerts"              = "stalert$env$locationOut$subId"
        "storage-boot-diags"          = "stdiag$env$locationOut$subId"
        "storage-flow-logs"           = "stflow$env$locationOut$subId"
        "storage-os-disk"             = "osdisk-$env-$locationOut-$subId"
        "storage-splunk"              = "stsplunk$env$locationOut$subId"
        "subnet"                      = "sn-$env-$locationOut-$subId"
        "virtual-machine"             = "$env-$locationOut-$subId"
        "virtual-machine-scaleset"    = "vmss-$env-$locationOut-$subId"
        "virtual-machine-windows"     = "$env$locationOut$subId32"
        "virtual-network"             = "vnet-$env-$locationOut-$subId"
        "vnet-gateway"                = "gwy-$env-$locationOut-$subId"
        "vnet-peering"                = "peer-$env-$locationOut-$subId"
    }
    return $output[$reference]
}